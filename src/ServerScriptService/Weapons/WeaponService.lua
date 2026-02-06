--[[
	WeaponService.lua
	Authoritative server-side weapon logic:
	- Initializes per-player ammo state
	- Validates fire requests
	- Applies damage using raycasts
	- Handles reload requests
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponsConfig = require(ReplicatedStorage:WaitForChild("WeaponsConfig"))

local WeaponService = {}
WeaponService.__index = WeaponService

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
	if not state then
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

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local lookDot = rootPart.CFrame.LookVector:Dot(direction.Unit)
	if lookDot < 0.2 then
		return
	end

	state.LastFireTime = now
	state.AmmoInMag -= 1

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	local rayResult = workspace:Raycast(origin, direction.Unit * config.Range, raycastParams)

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
	self.Remotes.ShotFired:FireAllClients(player, weaponName, origin, direction, isAiming)
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
	if not state then
		return
	end

	if state.AmmoInMag >= config.MagazineSize or state.ReserveAmmo <= 0 then
		return
	end

	local ammoNeeded = config.MagazineSize - state.AmmoInMag
	local ammoToLoad = math.min(ammoNeeded, state.ReserveAmmo)
	state.AmmoInMag += ammoToLoad
	state.ReserveAmmo -= ammoToLoad

	self.Remotes.AmmoUpdated:FireClient(player, weaponName, state.AmmoInMag, state.ReserveAmmo)
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
