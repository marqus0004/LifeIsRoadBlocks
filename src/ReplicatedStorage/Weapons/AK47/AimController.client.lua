local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local aimEvent = remoteEvents:WaitForChild("AimEvent")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local ironSight = handle:WaitForChild("IronSight")

local DEFAULT_FOV = 70
local ADS_FOV = 62
local CAMERA_LERP_ALPHA = 0.2
local FOV_LERP_ALPHA = 0.18

local equipped = false
local isAiming = false
local renderConnection: RBXScriptConnection? = nil

local function setAimingState(nextState: boolean)
	if isAiming == nextState then
		return
	end

	isAiming = nextState
	aimEvent:FireServer(nextState)
end

local function updateADS()
	if not equipped then
		return
	end

	if isAiming then
		camera.FieldOfView = camera.FieldOfView + (ADS_FOV - camera.FieldOfView) * FOV_LERP_ALPHA
		local targetCFrame = ironSight.WorldCFrame
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, CAMERA_LERP_ALPHA)
	else
		camera.FieldOfView = camera.FieldOfView + (DEFAULT_FOV - camera.FieldOfView) * FOV_LERP_ALPHA
	end
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed or not equipped then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		setAimingState(true)
	end
end

local function onInputEnded(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		setAimingState(false)
	end
end

tool.Equipped:Connect(function()
	equipped = true
	if not renderConnection then
		renderConnection = RunService.RenderStepped:Connect(updateADS)
	end
end)

tool.Unequipped:Connect(function()
	equipped = false
	setAimingState(false)
	camera.FieldOfView = DEFAULT_FOV
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end)

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

aimEvent.OnClientEvent:Connect(function(sourcePlayer: Player, aiming: boolean)
	if sourcePlayer == player then
		return
	end

	local character = sourcePlayer.Character
	if character then
		character:SetAttribute("IsAiming", aiming)
	end
end)
