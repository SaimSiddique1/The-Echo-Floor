-- FloorGenerator.luau
-- Run from Command Bar: loadstring(game.ReplicatedStorage.Tools.FloorGenerator.Source)()

local H = 15
local T = 1
local BH = 1.5
local CC = Color3.fromRGB(255, 255, 255)
local BC = Color3.fromRGB(200, 190, 175)
local DC = Color3.fromRGB(160, 120, 80)
local LC = Color3.fromRGB(255, 245, 230)

local function part(name, size, cf, color, mat, trans)
	local o = Instance.new("Part")
	o.Name = name
	o.Size = size
	o.CFrame = cf
	o.Color = color
	o.Material = mat or Enum.Material.Plastic
	o.Anchored = true
	o.Locked = false
	o.Transparency = trans or 0
	return o
end

local function addRoomLabel(ceiling, roomName)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Bottom
	sg.AlwaysOnTop = true
	sg.ResetOnSpawn = false
	sg.Parent = ceiling
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = roomName
	label.Parent = sg
end

-- Rooms: {name, xMin, xMax, zMin, zMax, floorColor, floorMat, wallColor, wallMat}
local WALL_TINTS = {
	Hallway = Color3.fromRGB(240, 235, 225),
	ElevatorLobby = Color3.fromRGB(235, 230, 220),
	LivingRoom = Color3.fromRGB(245, 235, 220),
	Kitchen = Color3.fromRGB(240, 240, 235),
	Bedroom = Color3.fromRGB(235, 230, 225),
	Bathroom = Color3.fromRGB(230, 235, 240),
}

local rooms = {
	{ "Hallway", 0, 72, 0, 24, Color3.fromRGB(180, 140, 100), Enum.Material.Wood },
	{ "ElevatorLobby", 0, 30, 24, 60, Color3.fromRGB(200, 190, 175), Enum.Material.Slate },
	{ "LivingRoom", 30, 72, 24, 84, Color3.fromRGB(170, 130, 85), Enum.Material.Wood },
	{ "Kitchen", 30, 66, 84, 132, Color3.fromRGB(210, 200, 190), Enum.Material.Granite },
	{ "Bedroom", 0, 36, -30, 0, Color3.fromRGB(155, 145, 140), Enum.Material.Carpet },
	{ "Bathroom", 42, 72, -24, 0, Color3.fromRGB(215, 210, 205), Enum.Material.Slate },
}

local cutouts = {
	{ "ElevatorLobby", "zMin", 6, 24 },
	{ "Hallway", "zMax", 6, 24 },
	{ "Hallway", "zMax", 32, 50 },
	{ "LivingRoom", "zMin", 32, 50 },
	{ "LivingRoom", "zMax", 32, 50 },
	{ "Kitchen", "zMin", 32, 50 },
	{ "Hallway", "zMin", 12, 24 },
	{ "Bedroom", "zMax", 12, 24 },
	{ "Hallway", "zMin", 48, 60 },
	{ "Bathroom", "zMax", 48, 60 },
	{ "ElevatorLobby", "xMin", 32, 52 },
}

local cutoutsByRoom = {}
for _, r in ipairs(rooms) do
	cutoutsByRoom[r[1]] = {}
end
for _, c in ipairs(cutouts) do
	local roomName, side, a, b = unpack(c)
	if not cutoutsByRoom[roomName] then cutoutsByRoom[roomName] = {} end
	if not cutoutsByRoom[roomName][side] then cutoutsByRoom[roomName][side] = {} end
	table.insert(cutoutsByRoom[roomName][side], { a, b })
end

local floorModel = Instance.new("Folder")
floorModel.Name = "CurrentFloor"
floorModel.Parent = workspace

-- Regions folder (invisible detection parts for room detection)
local regionsFolder = Instance.new("Folder")
regionsFolder.Name = "Regions"
regionsFolder.Parent = floorModel

-- Floors and ceilings
for _, r in ipairs(rooms) do
	local name, xMin, xMax, zMin, zMax, flColor, flMat = unpack(r)
	local w = xMax - xMin
	local d = zMax - zMin
	local cx = (xMin + xMax) / 2
	local cz = (zMin + zMax) / 2

	local fl = part(name.."_Floor", Vector3.new(w, 1, d),
		CFrame.new(cx, 0, cz), flColor, flMat)
	fl.Parent = floorModel

	local cl = part(name.."_Ceiling", Vector3.new(w, 1, d),
		CFrame.new(cx, H, cz), CC)
	cl.Parent = floorModel
	addRoomLabel(cl, name)
end

-- Walls + baseboards + crown molding
local function makeWalls(name, xMin, xMax, zMin, zMax, side)
	local totalStart, totalEnd, fixedPos, isHorizontal
	if side == "zMin" or side == "zMax" then
		totalStart = xMin; totalEnd = xMax
		fixedPos = (side == "zMin") and zMin or zMax
		isHorizontal = true
	else
		totalStart = zMin; totalEnd = zMax
		fixedPos = (side == "xMin") and xMin or xMax
		isHorizontal = false
	end

	local openings = {}
	if cutoutsByRoom[name] and cutoutsByRoom[name][side] then
		openings = cutoutsByRoom[name][side]
	end
	table.sort(openings, function(a, b) return a[1] < b[1] end)

	local segments = {}
	local cursor = totalStart
	for _, gap in ipairs(openings) do
		local gs, ge = gap[1], gap[2]
		if cursor < gs then
			table.insert(segments, { cursor, gs })
		end
		cursor = math.max(cursor, ge)
	end
	if cursor < totalEnd then
		table.insert(segments, { cursor, totalEnd })
	end

	local wallColor = WALL_TINTS[name] or WC

	for _, seg in ipairs(segments) do
		local segStart, segEnd = seg[1], seg[2]
		local segSize = segEnd - segStart
		local segCenter = (segStart + segEnd) / 2

		local wallPart
		if isHorizontal then
			wallPart = part(name.."_W_"..side.."_"..segStart,
				Vector3.new(segSize, H, T),
				CFrame.new(segCenter, H/2, fixedPos), wallColor, Enum.Material.SmoothPlastic)
		else
			wallPart = part(name.."_W_"..side.."_"..segStart,
				Vector3.new(T, H, segSize),
				CFrame.new(fixedPos, H/2, segCenter), wallColor, Enum.Material.SmoothPlastic)
		end
		wallPart.Parent = floorModel

		-- Baseboard at bottom
		local basePart
		if isHorizontal then
			basePart = part(name.."_Base_"..side.."_"..segStart,
				Vector3.new(segSize, BH, T + 0.3),
				CFrame.new(segCenter, BH/2, fixedPos), BC, Enum.Material.Wood)
		else
			basePart = part(name.."_Base_"..side.."_"..segStart,
				Vector3.new(T + 0.3, BH, segSize),
				CFrame.new(fixedPos, BH/2, segCenter), BC, Enum.Material.Wood)
		end
		basePart.Parent = floorModel

		-- Crown molding at top
		local crownPart
		if isHorizontal then
			crownPart = part(name.."_Crown_"..side.."_"..segStart,
				Vector3.new(segSize, BH, T + 0.3),
				CFrame.new(segCenter, H - BH/2, fixedPos), BC, Enum.Material.Wood)
		else
			crownPart = part(name.."_Crown_"..side.."_"..segStart,
				Vector3.new(T + 0.3, BH, segSize),
				CFrame.new(fixedPos, H - BH/2, segCenter), BC, Enum.Material.Wood)
		end
		crownPart.Parent = floorModel
	end
end

for _, r in ipairs(rooms) do
	local name, xMin, xMax, zMin, zMax = unpack(r)
	makeWalls(name, xMin, xMax, zMin, zMax, "xMin")
	makeWalls(name, xMin, xMax, zMin, zMax, "xMax")
	makeWalls(name, xMin, xMax, zMin, zMax, "zMin")
	makeWalls(name, xMin, xMax, zMin, zMax, "zMax")
end


-- Ceiling light fixtures per room
for _, r in ipairs(rooms) do
	local name, xMin, xMax, zMin, zMax = unpack(r)
	local cx = (xMin + xMax) / 2
	local cz = (zMin + zMax) / 2

	local lightFixture = part(name.."_Light", Vector3.new(2, 0.3, 2),
		CFrame.new(cx, H - 0.5, cz), LC, Enum.Material.Plastic)
	lightFixture.Parent = floorModel

	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 240, 210)
	pointLight.Brightness = 0.8
	pointLight.Range = 40
	pointLight.Shadows = false
	pointLight.Parent = lightFixture

	-- Region part (invisible, non-collidable, used for client-side room detection)
	local rw = xMax - xMin
	local rd = zMax - zMin
	local rp = part(name, Vector3.new(rw, 1, rd),
		CFrame.new(cx, 0.5, cz), Color3.fromRGB(255, 255, 255), Enum.Material.Plastic, 1)
	rp.CanCollide = false
	rp.Parent = regionsFolder
end

-- Window at hallway dead end (xMax wall at x=72)
-- The window frame extrudes 0.5 studs too far into the room
local winW = 10
local winH = 8
local winY = 4
local winZ = 12

-- Wall inner face is at x=71.5, outer face at x=72.5
-- Frame sits from x=71.0 to x=72.0 (0.5 past inner face, 0.5 into wall)
local fDepth = 1.0
local fThick = 0.4

-- Glass centered at wall inner face
local glass = part("HallwayWindow_Glass", Vector3.new(0.3, winH, winW),
	CFrame.new(71.5, winY + winH/2, winZ),
	Color3.fromRGB(180, 210, 255), Enum.Material.Glass, 0.3)
glass.Parent = floorModel

-- Frame extrudes inward 0.5 past inner wall face
local frameX = 71.5
local frameLeft = part("HallwayWindow_Frame_L", Vector3.new(fDepth, winH + fThick*2, fThick),
	CFrame.new(frameX, winY + winH/2, winZ - winW/2 - fThick/2),
	Color3.fromRGB(220, 210, 190), Enum.Material.Wood)
frameLeft.Parent = floorModel

local frameRight = part("HallwayWindow_Frame_R", Vector3.new(fDepth, winH + fThick*2, fThick),
	CFrame.new(frameX, winY + winH/2, winZ + winW/2 + fThick/2),
	Color3.fromRGB(220, 210, 190), Enum.Material.Wood)
frameRight.Parent = floorModel

local frameTop = part("HallwayWindow_Frame_T", Vector3.new(fDepth, fThick, winW + fThick*2),
	CFrame.new(frameX, winY + winH + fThick/2, winZ),
	Color3.fromRGB(220, 210, 190), Enum.Material.Wood)
frameTop.Parent = floorModel

local frameBot = part("HallwayWindow_Frame_B", Vector3.new(fDepth, fThick, winW + fThick*2),
	CFrame.new(frameX, winY - fThick/2, winZ),
	Color3.fromRGB(220, 210, 190), Enum.Material.Wood)
frameBot.Parent = floorModel

-- Sill extruding past inner face
local sill = part("HallwayWindow_Sill", Vector3.new(1.3, 0.4, winW + 1.5),
	CFrame.new(frameX, winY - 0.2, winZ),
	Color3.fromRGB(200, 190, 175), Enum.Material.Wood)
sill.Parent = floorModel

-- Set warm ambient lighting so rooms aren't dark between fixtures
local lighting = game:GetService("Lighting")
lighting.Ambient = Color3.fromRGB(60, 55, 50)
lighting.Brightness = 0.5
lighting.OutdoorAmbient = Color3.fromRGB(60, 55, 50)
lighting.ClockTime = 14

-- Center the floor
local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
for _, child in floorModel:GetChildren() do
	if child:IsA("BasePart") then
		local c = child.Position
		local s = child.Size / 2
		minX = math.min(minX, c.X - s.X)
		maxX = math.max(maxX, c.X + s.X)
		minZ = math.min(minZ, c.Z - s.Z)
		maxZ = math.max(maxZ, c.Z + s.Z)
	end
end
local centerX = (minX + maxX) / 2
local centerZ = (minZ + maxZ) / 2
for _, child in floorModel:GetChildren() do
	if child:IsA("BasePart") then
		local pos = child.Position
		child.CFrame = CFrame.new(pos.X - centerX, pos.Y, pos.Z - centerZ) * child.CFrame.Rotation
	end
end

-- Clone to ServerStorage.Templates.MasterFloor (keep workspace copy)
local templates = game.ServerStorage.Templates
local existing = templates:FindFirstChild("MasterFloor")
if existing then existing:Destroy() end
local master = Instance.new("Model")
master.Name = "MasterFloor"
local saved = floorModel:Clone()
saved.Name = "Floor"
saved.Parent = master
master.Parent = templates

floorModel.Name = "Floor"

print("Floor built in Workspace and saved to ServerStorage.Templates.MasterFloor.")
return true
