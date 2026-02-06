local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureFolder(parent: Instance, name: string): Folder
	local folder = parent:FindFirstChild(name)
	if folder and folder:IsA("Folder") then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function ensureRemoteEvent(parent: Instance, name: string): RemoteEvent
	local remote = parent:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function ensureAK47Template(weaponsFolder: Folder): Tool
	local existing = weaponsFolder:FindFirstChild("AK47")
	if existing and existing:IsA("Tool") then
		local existingHandle = existing:FindFirstChild("Handle")
		if existingHandle and existingHandle:IsA("BasePart") then
			if not existingHandle:FindFirstChild("Muzzle") then
				local muzzle = Instance.new("Attachment")
				muzzle.Name = "Muzzle"
				muzzle.Position = Vector3.new(0, 0, -1.9)
				muzzle.Parent = existingHandle
			end
			if not existingHandle:FindFirstChild("IronSight") then
				local ironSight = Instance.new("Attachment")
				ironSight.Name = "IronSight"
				ironSight.Position = Vector3.new(0, 0.18, -0.6)
				ironSight.Parent = existingHandle
			end
		end
		return existing
	end

	local tool = Instance.new("Tool")
	tool.Name = "AK47"
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 3.2)
	handle.Material = Enum.Material.Metal
	handle.Color = Color3.fromRGB(45, 45, 45)
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0, 0, -1.9)
	muzzle.Parent = handle

	local ironSight = Instance.new("Attachment")
	ironSight.Name = "IronSight"
	ironSight.Position = Vector3.new(0, 0.18, -0.6)
	ironSight.Parent = handle

	tool.Parent = weaponsFolder
	return tool
end

local remoteEvents = ensureFolder(ReplicatedStorage, "RemoteEvents")
ensureRemoteEvent(remoteEvents, "ShootEvent")
ensureRemoteEvent(remoteEvents, "ReloadEvent")
ensureRemoteEvent(remoteEvents, "AimEvent")

local weaponsFolder = ensureFolder(ReplicatedStorage, "Weapons")
ensureAK47Template(weaponsFolder)
