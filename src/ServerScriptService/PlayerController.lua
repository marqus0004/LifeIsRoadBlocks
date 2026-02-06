--[[
	PlayerController.lua
	Server-side movement state synchronization.
	Keeps sprint/crouch/aim attributes on each player for other systems.
]]

local PlayerController = {}
PlayerController.__index = PlayerController

function PlayerController.new(remotes)
	local self = setmetatable({}, PlayerController)
	self.Remotes = remotes
	self._boundPlayers = {}
	self:_bindRemoteListener()
	return self
end

function PlayerController:_bindRemoteListener()
	self.Remotes.MovementState.OnServerEvent:Connect(function(player, movementState)
		if not self._boundPlayers[player] then
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

function PlayerController:BindPlayer(player)
	self._boundPlayers[player] = true
	player:SetAttribute("IsSprinting", false)
	player:SetAttribute("IsCrouching", false)
	player:SetAttribute("IsAiming", false)
end

function PlayerController:UnbindPlayer(player)
	self._boundPlayers[player] = nil
end

return PlayerController
