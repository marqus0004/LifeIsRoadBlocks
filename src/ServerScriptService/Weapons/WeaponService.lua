--[[
	WeaponService.lua
	Authoritative server-side weapon logic:
	- Tracks ammo + reload timing per player
	- Validates fire requests (rate, origin, direction)
	- Raycasts and applies player damage
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponsConfig = require(ReplicatedStorage:WaitForChild("WeaponsConfig"))

local WeaponService = {}
WeaponService.__index = WeaponService

local MAX_ORIGIN_DISTANCE_FROM_ROOT = 10
local playerWeaponState = {}

local function getOrCreateState(player, weaponName)
	playerWeaponState[player] = playerWeaponState[player] or {}
	local weaponState = playerWeaponState[player]

	if not weaponState[weaponName] then
		local config = WeaponsConfig[weaponName]
		if not config then
			return nil
		end

		weaponState[weaponName] = {
			AmmoInMag = config.MagazineSize,
			ReserveAmmo = config.ReserveAmmo,
			LastFireTime = 0,
			IsReloading = false,
		}
	end

	return weaponState[weaponName]
end

function WeaponService:HandleFire(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local weaponName = payload.WeaponName
	local origin = payload.Origin
	local direction = payload.Direction
	local isAiming = payload.IsAiming == true

	if typeof(weaponName) ~= "string" or typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end

	local config = WeaponsConfig[weaponName]
	if not config then
		return
	end

	local state = getOrCreateState(player, weaponName)
	if not state or state.IsReloading then
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if (origin - rootPart.Position).Magnitude > MAX_ORIGIN_DISTANCE_FROM_ROOT then
		return
	end

	local now = os.clock()
	local minInterval = 60 / config.FireRate
	if now - state.LastFireTime < minInterval then
		return
	end

	if state.AmmoInMag <= 0 then
		return
	end

	local unitDirection = direction.Unit
	local lookDot = rootPart.CFrame.LookVector:Dot(unitDirection)
	if lookDot < 0.2 then
		return
	end

	state.LastFireTime = now
	state.AmmoInMag -= 1

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local rayResult = workspace:Raycast(origin, unitDirection * config.Range, raycastParams)
	if rayResult then
		local hitModel = rayResult.Instance:FindFirstAncestorOfClass("Model")
		local humanoid = hitModel and hitModel:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local victim = Players:GetPlayerFromCharacter(hitModel)
			if victim and victim ~= player then
				local damage = config.Damage
				if rayResult.Instance.Name == "Head" then
					damage *= config.HeadshotMultiplier
				end
				humanoid:TakeDamage(damage)
			end
		end
	end

	self.Remotes.AmmoUpdated:FireClient(player, weaponName, state.AmmoInMag, state.ReserveAmmo)
	self.Remotes.ShotFired:FireAllClients(player, weaponName, origin, unitDirection, isAiming)
end

function WeaponService:HandleReload(player, weaponName)
	if typeof(weaponName) ~= "string" then
		return
	end

	local config = WeaponsConfig[weaponName]
	if not config then
		return
	end

	local state = getOrCreateState(player, weaponName)
	if not state or state.IsReloading then
		return
	end

	if state.AmmoInMag >= config.MagazineSize or state.ReserveAmmo <= 0 then
		return
	end

	state.IsReloading = true
	task.delay(config.ReloadTime, function()
		if not player.Parent then
			return
		end

		local refreshedState = getOrCreateState(player, weaponName)
		if not refreshedState then
			return
		end

		local ammoNeeded = config.MagazineSize - refreshedState.AmmoInMag
		local ammoToLoad = math.min(ammoNeeded, refreshedState.ReserveAmmo)
		refreshedState.AmmoInMag += ammoToLoad
		refreshedState.ReserveAmmo -= ammoToLoad
		refreshedState.IsReloading = false

		self.Remotes.AmmoUpdated:FireClient(player, weaponName, refreshedState.AmmoInMag, refreshedState.ReserveAmmo)
	end)
end

function WeaponService:GetAmmoState(player, weaponName)
	local state = getOrCreateState(player, weaponName)
	if not state then
		return 0, 0
	end
	return state.AmmoInMag, state.ReserveAmmo
end

function WeaponService:RemovePlayer(player)
	playerWeaponState[player] = nil
end

function WeaponService.new(remotes)
	local self = setmetatable({}, WeaponService)
	self.Remotes = remotes
	return self
end

return WeaponService
