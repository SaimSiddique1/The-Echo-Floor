-- FloorGenerator.luau
-- Paste into Script in ServerScriptService, add require(script)() at bottom, Play then Stop
-- Generates floor shell: walls, floor, ceiling per room
-- Red = archway (delete wall behind), Blue = door marker (add door part there)

local H = 15
local T = 1
local WC = Color3.fromRGB(245, 240, 230)
local FC = Color3.fromRGB(210, 195, 170)
local CC = Color3.fromRGB(255, 255, 255)
local DC = Color3.fromRGB(160, 120, 80) -- door color

local function newPart(name, size, cf, color, mat, trans)
	local o = Instance.new("Part")
	o.Name = name
	o.Size = size
	o.CFrame = cf
	o.Color = color
	o.Material = mat or Enum.Material.Plastic
	o.Anchored = true
	o.Locked = true
	o.Transparency = trans or 0
	return o
end

-- Rooms: {name, xMin, xMax, zMin, zMax}
-- All coords scaled ~3x from original for spacious feel
-- x=right, z=down
local rooms = {
	{ "Hallway", 0, 72, 0, 24 },
	{ "ElevatorLobby", 0, 30, 24, 60 },
	{ "LivingRoom", 12, 72, 24, 84 },
	{ "Kitchen", 12, 60, 84, 132 },
	{ "Bedroom", 0, 36, -30, 0 },
	{ "Bathroom", 42, 72, -24, 0 },
}

-- Markers: {room, wallSide, gapStart, gapEnd, color}
local markers = {
	-- Archways (red)
	{ "ElevatorLobby", "zMin", 6, 24, Color3.new(1, 0, 0) },
	{ "Hallway", "zMax", 24, 48, Color3.new(1, 0, 0) },
	{ "LivingRoom", "zMax", 24, 48, Color3.new(1, 0, 0) },
	-- Doors (blue) - gap where a door part goes
	{ "Hallway", "zMin", 12, 24, Color3.new(0, 0.5, 1) },
	{ "Hallway", "zMin", 48, 60, Color3.new(0, 0.5, 1) },
}

local floorModel = Instance.new("Model")
floorModel.Name = "CurrentFloor"
floorModel.Parent = workspace

-- Generate floors and ceilings per room
for _, r in ipairs(rooms) do
	local name, xMin, xMax, zMin, zMax = unpack(r)
	local w = xMax - xMin
	local d = zMax - zMin
	local cx = (xMin + xMax) / 2
	local cz = (zMin + zMax) / 2

	local fl = newPart(name.."_Floor", Vector3.new(w, 1, d),
		CFrame.new(cx, 0, cz), FC, Enum.Material.Wood)
	fl.Parent = floorModel

	local cl = newPart(name.."_Ceiling", Vector3.new(w, 1, d),
		CFrame.new(cx, H, cz), CC)
	cl.Parent = floorModel
end

-- Generate 4 walls per room. NO ROTATIONS — Size determines axis.
for _, r in ipairs(rooms) do
	local name, xMin, xMax, zMin, zMax = unpack(r)
	local w = xMax - xMin
	local d = zMax - zMin
	local cx = (xMin + xMax) / 2
	local cz = (zMin + zMax) / 2

	-- xMin wall: runs along Z, thin in X
	local w1 = newPart(name.."_W_xMin", Vector3.new(T, H, d),
		CFrame.new(xMin, H/2, cz), WC, Enum.Material.SmoothPlastic)
	w1.Parent = floorModel

	-- xMax wall: runs along Z, thin in X
	local w2 = newPart(name.."_W_xMax", Vector3.new(T, H, d),
		CFrame.new(xMax, H/2, cz), WC, Enum.Material.SmoothPlastic)
	w2.Parent = floorModel

	-- zMin wall: runs along X, thin in Z
	local w3 = newPart(name.."_W_zMin", Vector3.new(w, H, T),
		CFrame.new(cx, H/2, zMin), WC, Enum.Material.SmoothPlastic)
	w3.Parent = floorModel

	-- zMax wall: runs along X, thin in Z
	local w4 = newPart(name.."_W_zMax", Vector3.new(w, H, T),
		CFrame.new(cx, H/2, zMax), WC, Enum.Material.SmoothPlastic)
	w4.Parent = floorModel
end

-- Door part at the bedroom entrance (Hallway zMin, gap 12-24)
local door = newPart("BedroomDoor", Vector3.new(12, 13, 1.5),
	CFrame.new(18, 6.5, 0), DC, Enum.Material.Wood)
door.Parent = floorModel

-- Place markers
local function findRoom(name)
	for _, r in ipairs(rooms) do
		if r[1] == name then return r end
	end
	return nil
end

for _, m in ipairs(markers) do
	local roomName, side, gapStart, gapEnd, color = unpack(m)
	local room = findRoom(roomName)
	if not room then continue end

	local _, xMin, xMax, zMin, zMax = unpack(room)
	local gapSize = gapEnd - gapStart
	local gapCenter = (gapStart + gapEnd) / 2

	local marker
	if side == "zMin" then
		marker = newPart("Mark_"..roomName.."_zMin",
			Vector3.new(gapSize, H, T + 0.2),
			CFrame.new(gapCenter, H/2, zMin),
			color, Enum.Material.SmoothPlastic, 0.6)
	elseif side == "zMax" then
		marker = newPart("Mark_"..roomName.."_zMax",
			Vector3.new(gapSize, H, T + 0.2),
			CFrame.new(gapCenter, H/2, zMax),
			color, Enum.Material.SmoothPlastic, 0.6)
	elseif side == "xMin" then
		marker = newPart("Mark_"..roomName.."_xMin",
			Vector3.new(T + 0.2, H, gapSize),
			CFrame.new(xMin, H/2, gapCenter),
			color, Enum.Material.SmoothPlastic, 0.6)
	elseif side == "xMax" then
		marker = newPart("Mark_"..roomName.."_xMax",
			Vector3.new(T + 0.2, H, gapSize),
			CFrame.new(xMax, H/2, gapCenter),
			color, Enum.Material.SmoothPlastic, 0.6)
	end
	if marker then
		marker.Parent = floorModel
	end
end

-- Center the whole floor around origin
local cf = floorModel:GetBoundingBox()
floorModel:PivotTo(CFrame.new(-cf.Position.X, 0, -cf.Position.Z))

print("Floor generated! " .. #rooms .. " rooms, 1 door.")
print("RED = archway opening. BLUE = door opening.")
print("Delete duplicate walls where rooms share a face (pick one to keep).")
print("Delete the red/blue markers after cutting openings.")
