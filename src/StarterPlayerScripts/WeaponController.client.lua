--[[
	WeaponController.client.lua
	Client weapon handling:
	- Fire input and fire modes (single/burst/auto)
	- Local recoil + spread simulation
	- ADS / iron-sight camera behavior
	- Reload requests and ammo sync
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local WeaponsConfig = require(ReplicatedStorage:WaitForChild("WeaponsConfig"))
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")

local remotes = {
	FireWeapon = remoteFolder:WaitForChild("FireWeapon"),
	ReloadWeapon = remoteFolder:WaitForChild("ReloadWeapon"),
	AmmoUpdated = remoteFolder:WaitForChild("AmmoUpdated"),
	ShotFired = remoteFolder:WaitForChild("ShotFired"),
	RequestAmmo = remoteFolder:WaitForChild("RequestAmmo"),
}

local currentWeapon = "Rifle"
local config = WeaponsConfig[currentWeapon]

local ammoInMag = config.MagazineSize
local reserveAmmo = config.ReserveAmmo
local currentFireMode = config.FireMode

local isAiming = false
local isFiring = false
local isReloading = false
local burstShotsLeft = 0
local lastShotTime = 0

-- Placeholder animation hooks. Attach Animator tracks once assets exist.
local animations = {
	Shoot = nil,
	Reload = nil,
	Aim = nil,
}

local function updateCrosshairAndHud()
	-- Placeholder for HUD integration.
	-- Example: AmmoLabel.Text = string.format("%d / %d [%s]", ammoInMag, reserveAmmo, currentFireMode)
end

local function setAimState(newState)
	if isAiming == newState then
		return
	end

	isAiming = newState
	local targetFov = isAiming and config.AimFov or 70

	-- Iron-sight mechanic: tighten FOV while aiming down sights.
	TweenService:Create(camera, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = targetFov,
	}):Play()

	if animations.Aim then
		if isAiming then
			animations.Aim:Play()
		else
			animations.Aim:Stop()
		end
	end
end

local function applyRecoil()
	local pitch = math.rad(config.Recoil.Pitch)
	local yaw = math.rad((math.random() - 0.5) * 2 * config.Recoil.Yaw)
	camera.CFrame *= CFrame.Angles(-pitch, yaw, 0)
end

local function getShotDirection()
	local mousePos = UserInputService:GetMouseLocation()
	local baseRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local spreadDegrees = isAiming and config.AimSpread or config.HipSpread
	local spreadRadians = math.rad(spreadDegrees)
	local xSpread = (math.random() - 0.5) * spreadRadians
	local ySpread = (math.random() - 0.5) * spreadRadians

	local spreadFrame = CFrame.lookAt(Vector3.zero, baseRay.Direction) * CFrame.Angles(ySpread, xSpread, 0)
	return baseRay.Origin, spreadFrame.LookVector.Unit
end

local function canShoot()
	if isReloading then
		return false
	end
	if ammoInMag <= 0 then
		return false
	end

	local minInterval = 60 / config.FireRate
	if os.clock() - lastShotTime < minInterval then
		return false
	end

	return true
end

local function fireOneShot()
	if not canShoot() then
		if ammoInMag <= 0 then
			remotes.ReloadWeapon:FireServer(currentWeapon)
		end
		return
	end

	lastShotTime = os.clock()
	ammoInMag -= 1
	updateCrosshairAndHud()

	local origin, direction = getShotDirection()
	remotes.FireWeapon:FireServer({
		WeaponName = currentWeapon,
		Origin = origin,
		Direction = direction,
		IsAiming = isAiming,
	})

	applyRecoil()
	if animations.Shoot then
		animations.Shoot:Play()
	end
end

local function startReload()
	if isReloading then
		return
	end
	if ammoInMag >= config.MagazineSize or reserveAmmo <= 0 then
		return
	end

	isReloading = true
	if animations.Reload then
		animations.Reload:Play()
	end

	remotes.ReloadWeapon:FireServer(currentWeapon)
	-- Client lock for UX while server reload timer runs.
	task.delay(config.ReloadTime, function()
		isReloading = false
	end)
end

local function cycleFireMode()
	if currentFireMode == "Single" then
		currentFireMode = "Burst"
	elseif currentFireMode == "Burst" then
		currentFireMode = "Auto"
	else
		currentFireMode = "Single"
	end
	updateCrosshairAndHud()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isFiring = true
		if currentFireMode == "Single" then
			fireOneShot()
		elseif currentFireMode == "Burst" then
			burstShotsLeft = config.BurstCount
		else
			fireOneShot()
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		startReload()
	elseif input.KeyCode == Enum.KeyCode.B then
		cycleFireMode()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		setAimState(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isFiring = false
		burstShotsLeft = 0
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		setAimState(false)
	end
end)

RunService.RenderStepped:Connect(function()
	if not isFiring then
		return
	end

	if currentFireMode == "Auto" then
		fireOneShot()
	elseif currentFireMode == "Burst" and burstShotsLeft > 0 and canShoot() then
		fireOneShot()
		burstShotsLeft -= 1
	end
end)

remotes.AmmoUpdated.OnClientEvent:Connect(function(weaponName, newAmmoInMag, newReserveAmmo)
	if weaponName ~= currentWeapon then
		return
	end

	ammoInMag = newAmmoInMag
	reserveAmmo = newReserveAmmo
	if ammoInMag > 0 then
		isReloading = false
	end
	updateCrosshairAndHud()
end)

remotes.ShotFired.OnClientEvent:Connect(function(shooter, weaponName)
	if shooter == player or weaponName ~= currentWeapon then
		return
	end
	-- Placeholder for replication VFX/SFX (muzzle flash, tracers, sounds).
end)

remotes.RequestAmmo:FireServer(currentWeapon)
updateCrosshairAndHud()
