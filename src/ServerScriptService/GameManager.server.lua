local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STARTING_WEAPON_NAME = "AK47"

local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons")

local function giveStartingWeapon(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack")
	local starterTool = weaponsFolder:FindFirstChild(STARTING_WEAPON_NAME)
	if not starterTool or not starterTool:IsA("Tool") then
		warn("Missing starting weapon template:", STARTING_WEAPON_NAME)
		return
	end

	local existingInBackpack = backpack:FindFirstChild(STARTING_WEAPON_NAME)
	local character = player.Character
	local existingInCharacter = character and character:FindFirstChild(STARTING_WEAPON_NAME)
	if existingInBackpack or existingInCharacter then
		return
	end

	local clone = starterTool:Clone()
	clone.Parent = backpack
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:SetAttribute("IsAiming", false)
		giveStartingWeapon(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		player.Character:SetAttribute("IsAiming", false)
		giveStartingWeapon(player)
	end
	player.CharacterAdded:Connect(function(character)
		character:SetAttribute("IsAiming", false)
		giveStartingWeapon(player)
	end)
end
