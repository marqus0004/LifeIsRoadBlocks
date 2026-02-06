--[[
	GameManager.server.lua
	Bootstraps the multiplayer shooter core systems.
	Creates RemoteEvents and wires server modules.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponService = require(script.Parent.Weapons.WeaponService)
local PlayerController = require(script.Parent.PlayerController)

local function getOrCreateRemoteFolder()
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if folder and folder:IsA("Folder") then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = ReplicatedStorage
	return folder
end

local function getOrCreateRemote(folder, name)
	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

local remoteFolder = getOrCreateRemoteFolder()
local remotes = {
	FireWeapon = getOrCreateRemote(remoteFolder, "FireWeapon"),
	ReloadWeapon = getOrCreateRemote(remoteFolder, "ReloadWeapon"),
	AmmoUpdated = getOrCreateRemote(remoteFolder, "AmmoUpdated"),
	ShotFired = getOrCreateRemote(remoteFolder, "ShotFired"),
	MovementState = getOrCreateRemote(remoteFolder, "MovementState"),
	RequestAmmo = getOrCreateRemote(remoteFolder, "RequestAmmo"),
}

local weaponService = WeaponService.new(remotes)
local playerController = PlayerController.new(remotes)

Players.PlayerAdded:Connect(function(player)
	playerController:BindPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	weaponService:RemovePlayer(player)
end)

remotes.FireWeapon.OnServerEvent:Connect(function(player, payload)
	weaponService:HandleFire(player, payload)
end)

remotes.ReloadWeapon.OnServerEvent:Connect(function(player, weaponName)
	weaponService:HandleReload(player, weaponName)
end)

remotes.RequestAmmo.OnServerEvent:Connect(function(player, weaponName)
	local ammoInMag, reserveAmmo = weaponService:GetAmmoState(player, weaponName)
	remotes.AmmoUpdated:FireClient(player, weaponName, ammoInMag, reserveAmmo)
end)

print("GameManager initialized.")
