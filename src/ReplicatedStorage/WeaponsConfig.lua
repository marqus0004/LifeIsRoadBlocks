--[[
	WeaponsConfig.lua
	Shared weapon tuning values used by both server and client.
	You can add more weapons by following the same schema.
]]

local WeaponsConfig = {
	Rifle = {
		DisplayName = "MX-9 Rifle",
		Damage = 30,
		HeadshotMultiplier = 1.5,
		FireRate = 600, -- rounds per minute
		FireMode = "Auto", -- Single, Burst, Auto
		BurstCount = 3,
		MagazineSize = 30,
		ReserveAmmo = 120,
		ReloadTime = 2.2,
		Range = 1200,
		HipSpread = 2.25,
		AimSpread = 0.8,
		Recoil = {
			Pitch = 1.6,
			Yaw = 0.7,
			Recovery = 10,
		},
		AimFov = 55,
		AimWalkSpeedMultiplier = 0.75,
		SprintWalkSpeedMultiplier = 1.45,
		AnimationIds = {
			Idle = "rbxassetid://0", -- Placeholder
			Shoot = "rbxassetid://0", -- Placeholder
			Reload = "rbxassetid://0", -- Placeholder
			Aim = "rbxassetid://0", -- Placeholder
		},
	},
}

return WeaponsConfig
