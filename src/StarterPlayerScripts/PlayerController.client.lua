--[[
	PlayerController.client.lua
	Handles local movement input: walk, sprint, crouch, jump and ADS state sharing.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local movementStateRemote = remoteFolder:WaitForChild("MovementState")

local NORMAL_SPEED = 16
local SPRINT_SPEED = 24
local CROUCH_SPEED = 10
local CROUCH_HIP_HEIGHT = 1
local NORMAL_HIP_HEIGHT = 2

local movementState = {
	IsSprinting = false,
	IsCrouching = false,
	IsAiming = false,
}

local humanoid

local function sendMovementState()
	movementStateRemote:FireServer(movementState)
end

local function refreshMovementValues()
	if not humanoid then
		return
	end

	if movementState.IsCrouching then
		humanoid.WalkSpeed = CROUCH_SPEED
		humanoid.HipHeight = CROUCH_HIP_HEIGHT
	elseif movementState.IsSprinting then
		humanoid.WalkSpeed = SPRINT_SPEED
		humanoid.HipHeight = NORMAL_HIP_HEIGHT
	else
		humanoid.WalkSpeed = NORMAL_SPEED
		humanoid.HipHeight = NORMAL_HIP_HEIGHT
	end
end

local function bindCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = NORMAL_SPEED
	humanoid.HipHeight = NORMAL_HIP_HEIGHT
end

if player.Character then
	bindCharacter(player.Character)
end

player.CharacterAdded:Connect(bindCharacter)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		movementState.IsSprinting = true
		movementState.IsCrouching = false
		refreshMovementValues()
		sendMovementState()
	elseif input.KeyCode == Enum.KeyCode.C then
		movementState.IsCrouching = not movementState.IsCrouching
		if movementState.IsCrouching then
			movementState.IsSprinting = false
		end
		refreshMovementValues()
		sendMovementState()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		movementState.IsAiming = true
		sendMovementState()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		movementState.IsSprinting = false
		refreshMovementValues()
		sendMovementState()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		movementState.IsAiming = false
		sendMovementState()
	end
end)
