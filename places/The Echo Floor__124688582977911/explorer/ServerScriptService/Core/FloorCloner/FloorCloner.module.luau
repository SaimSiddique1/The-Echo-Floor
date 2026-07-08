-- FloorCloner.luau (ModuleScript)
-- Exports: spawnFloor() — clones floor template into Workspace, destroys previous

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local TEMPLATES = ServerStorage.Templates

local function destroyScripts(inst)
	for _, child in inst:GetDescendants() do
		if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") or child:IsA("PackageLink") then
			child:Destroy()
		end
	end
	-- Also catch anything named "PoseTexture" or "Package"
	for _, child in inst:GetDescendants() do
		if child.Name == "PoseTexture" or child.Name == "Package" then
			child:Destroy()
		end
	end
end

local function anchorAll(inst)
	for _, child in inst:GetDescendants() do
		if child:IsA("BasePart") then
			child.Anchored = true
		end
	end
end

local function spawnFloor()
	local existing = Workspace:FindFirstChild("Floor")
	if existing then
		existing:Destroy()
	end

	local template = TEMPLATES:FindFirstChild("Floor")
	if not template then
		warn("Floor not found in ServerStorage.Templates")
		return nil
	end

	local floor = template:Clone()
	destroyScripts(floor)
	anchorAll(floor)
	floor.Parent = Workspace
	print("Floor spawned into Workspace")
	return floor
end

return { spawnFloor = spawnFloor }
