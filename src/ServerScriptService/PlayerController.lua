--[[
	PlayerController.lua
	Server-side player setup and movement state replication.
	This module keeps player attributes in sync for sprint/crouch/aim state.
]]

local PlayerController = {}
PlayerController.__index = PlayerController

function PlayerController.new(remotes)
	local self = setmetatable({}, PlayerController)
	self.Remotes = remotes
	return self
end

function PlayerController:BindPlayer(player)
	player:SetAttribute("IsSprinting", false)
	player:SetAttribute("IsCrouching", false)
	player:SetAttribute("IsAiming", false)

	self.Remotes.MovementState.OnServerEvent:Connect(function(sourcePlayer, movementState)
		if sourcePlayer ~= player then
			return
		end
		if typeof(movementState) ~= "table" then
			return
		end

		player:SetAttribute("IsSprinting", movementState.IsSprinting == true)
		player:SetAttribute("IsCrouching", movementState.IsCrouching == true)
		player:SetAttribute("IsAiming", movementState.IsAiming == true)
	end)
end

return PlayerController
