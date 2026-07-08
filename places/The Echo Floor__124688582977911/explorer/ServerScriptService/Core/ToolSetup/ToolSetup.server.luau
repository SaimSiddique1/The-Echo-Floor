-- ToolSetup.server.luau
-- Creates anomaly tools in StarterPack so they appear in the hotbar on mobile

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local CosmeticConfig = require(ReplicatedStorage.Shared.CosmeticConfig)

local function toolPart(name, size, cf, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Anchored = false
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function buildAnomalyTool()
	local scanner = Instance.new("Tool")
	scanner.Name = "Anomaly Tool"
	scanner.ToolTip = "Investigate objects for anomalies"

	local handle = toolPart("Handle", Vector3.new(0.2, 0.42, 0.2),
		CFrame.new(0, 0, 0), Color3.fromRGB(200, 200, 200), scanner)

	local body = toolPart("Body", Vector3.new(0.65, 0.28, 0.45),
		CFrame.new(0, 0.35, 0), Color3.fromRGB(200, 200, 200), scanner)

	local sensorHousing = toolPart("SensorHousing", Vector3.new(0.4, 0.12, 0.12),
		CFrame.new(0, 0.52, 0.28), Color3.fromRGB(200, 200, 200), scanner)

	local sensorTip = toolPart("SensorTip", Vector3.new(0.2, 0.1, 0.1),
		CFrame.new(0, 0.58, 0.34), Color3.fromRGB(80, 200, 255), scanner)

	local screen = toolPart("Screen", Vector3.new(0.45, 0.04, 0.25),
		CFrame.new(0, 0.5, -0.05), Color3.fromRGB(40, 50, 60), scanner)

	local screenGlow = toolPart("ScreenGlow", Vector3.new(0.35, 0.01, 0.15),
		CFrame.new(0, 0.51, -0.05), Color3.fromRGB(80, 200, 255), scanner)
	screenGlow.Material = Enum.Material.Neon

	local gripLeft = toolPart("GripLeft", Vector3.new(0.04, 0.18, 0.08),
		CFrame.new(-0.12, -0.18, -0.06), Color3.fromRGB(40, 40, 45), scanner)
	gripLeft.Material = Enum.Material.Neon

	local gripRight = toolPart("GripRight", Vector3.new(0.04, 0.18, 0.08),
		CFrame.new(0.12, -0.18, -0.06), Color3.fromRGB(40, 40, 45), scanner)
	gripRight.Material = Enum.Material.Neon

	local toolParts = { handle, body, sensorHousing, sensorTip, screen, screenGlow, gripLeft, gripRight }

	for _, p in ipairs(toolParts) do
		if p == handle then continue end
		local w = Instance.new("Weld")
		w.Name = p.Name .. "Weld"
		w.Part0 = handle
		w.Part1 = p
		w.C0 = handle.CFrame:Inverse() * p.CFrame
		w.Parent = handle
	end

	local cosmetic = CosmeticConfig.getById("classic") or CosmeticConfig.list[1]
	for _, p in ipairs(toolParts) do
		if p.Name ~= "ScreenGlow" and p.Name ~= "SensorTip" and p.Name ~= "GripLeft" and p.Name ~= "GripRight" then
			p.Color = cosmetic.color
			p.Material = cosmetic.material
		end
	end

	return scanner
end

local scanner = buildAnomalyTool()
scanner.Parent = StarterPack

local noAnomaly = Instance.new("Tool")
noAnomaly.Name = "No Anomaly"
noAnomaly.RequiresHandle = false
noAnomaly.ToolTip = "Nothing seems wrong"
noAnomaly.Parent = StarterPack

-- Echo Ping tool
local function buildEchoPingTool()
	local tool = Instance.new("Tool")
	tool.Name = "Echo Ping"
	tool.ToolTip = "Highlights anomaly room on radar"
	tool.RequiresHandle = true

	local handle = toolPart("Handle", Vector3.new(0.3, 0.55, 0.3),
		CFrame.new(0, 0, 0), Color3.fromRGB(35, 35, 42), tool)

	local body = toolPart("Body", Vector3.new(0.75, 0.32, 0.55),
		CFrame.new(0, 0.42, 0), Color3.fromRGB(25, 25, 33), tool)

	local screen = toolPart("Screen", Vector3.new(0.5, 0.04, 0.3),
		CFrame.new(0, 0.56, -0.08), Color3.fromRGB(60, 60, 78), tool)
	screen.Material = Enum.Material.Neon

	local antenna = toolPart("Antenna", Vector3.new(0.1, 0.2, 0.1),
		CFrame.new(0, 0.7, 0.12), Color3.fromRGB(180, 35, 35), tool)

	local tip = toolPart("Tip", Vector3.new(0.14, 0.08, 0.14),
		CFrame.new(0, 0.84, 0.12), Color3.fromRGB(220, 50, 50), tool)
	tip.Material = Enum.Material.Neon

	local ring = toolPart("Ring", Vector3.new(0.8, 0.04, 0.6),
		CFrame.new(0, 0.44, 0), Color3.fromRGB(160, 30, 30), tool)
	ring.Material = Enum.Material.Neon

	local echoParts = { body, screen, antenna, tip, ring }
	for _, p in ipairs(echoParts) do
		local w = Instance.new("Weld")
		w.Name = p.Name .. "Weld"
		w.Part0 = handle
		w.Part1 = p
		w.C0 = handle.CFrame:Inverse() * p.CFrame
		w.Parent = handle
	end

	return tool
end

local echoPingTool = buildEchoPingTool()
echoPingTool.Parent = StarterPack

print("Tools added to StarterPack")
