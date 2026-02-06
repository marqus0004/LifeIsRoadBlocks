local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local aimEvent = remoteEvents:WaitForChild("AimEvent")

aimEvent.OnServerEvent:Connect(function(player: Player, aiming: boolean)
	if typeof(aiming) ~= "boolean" then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	character:SetAttribute("IsAiming", aiming)
	aimEvent:FireAllClients(player, aiming)
end)
