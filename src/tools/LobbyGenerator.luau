-- LobbyGenerator.luau
-- Builds the hotel lobby at Y=1000 with elevator bay, furniture, and decorative details.

local function part(name, size, cf, color, mat)
	local o = Instance.new("Part")
	o.Name = name
	o.Size = size
	o.CFrame = cf
	o.Color = color
	o.Material = mat or Enum.Material.Plastic
	o.Anchored = true
	o.Locked = false
	return o
end

local function wedge(name, size, cf, color, mat)
	local o = Instance.new("WedgePart")
	o.Name = name
	o.Size = size
	o.CFrame = cf
	o.Color = color
	o.Material = mat or Enum.Material.Plastic
	o.Anchored = true
	o.Locked = false
	return o
end

local function addLight(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = true
	l.Parent = parent
	return l
end

local LOBBY = workspace
local Y = 1000
local W = 60
local D = 46
local H = 15
local T = 1

local WC = Color3.fromRGB(220, 210, 195)
local FC = Color3.fromRGB(200, 185, 165)
local CC = Color3.fromRGB(245, 240, 235)
local BC = Color3.fromRGB(70, 65, 60)
local GOLD = Color3.fromRGB(200, 170, 100)
local GOLD_BRIGHT = Color3.fromRGB(230, 200, 120)
local DARK_WOOD = Color3.fromRGB(80, 55, 40)
local MED_WOOD = Color3.fromRGB(160, 120, 80)
local CRIMSON = Color3.fromRGB(140, 35, 35)
local GREEN = Color3.fromRGB(55, 110, 55)
local MARBLE = Color3.fromRGB(230, 220, 205)
local WALL_BG = Color3.fromRGB(230, 220, 210)

local lobby = Instance.new("Model")
lobby.Name = "Lobby"
lobby.Parent = LOBBY

-- === SHELL ===

-- Floor
local floor = part("Floor", Vector3.new(W, 0.5, D), CFrame.new(0, Y, 0), FC, Enum.Material.Marble)
floor.Parent = lobby

-- Floor border (darker marble trim around the edge)
local borderT = 2
local borderN = part("FloorBorder_N", Vector3.new(W, 0.15, borderT),
	CFrame.new(0, Y + 0.3, -D/2 + borderT/2), Color3.fromRGB(170, 160, 145), Enum.Material.Marble)
borderN.Parent = lobby
local borderS = part("FloorBorder_S", Vector3.new(W, 0.15, borderT),
	CFrame.new(0, Y + 0.3, D/2 - borderT/2), Color3.fromRGB(170, 160, 145), Enum.Material.Marble)
borderS.Parent = lobby
local borderW = part("FloorBorder_W", Vector3.new(borderT, 0.15, D - borderT * 2),
	CFrame.new(-W/2 + borderT/2, Y + 0.3, 0), Color3.fromRGB(170, 160, 145), Enum.Material.Marble)
borderW.Parent = lobby
local borderE = part("FloorBorder_E", Vector3.new(borderT, 0.15, D - borderT * 2),
	CFrame.new(W/2 - borderT/2, Y + 0.3, 0), Color3.fromRGB(170, 160, 145), Enum.Material.Marble)
borderE.Parent = lobby

-- Ceiling
local ceil = part("Ceiling", Vector3.new(W, 0.3, D), CFrame.new(0, Y + H, 0), CC)
ceil.Parent = lobby

-- Crown molding
local crownT = 0.4
local crownN = wedge("Crown_N", Vector3.new(W + 1, crownT, crownT),
	CFrame.Angles(0, 0, math.rad(180)) * CFrame.new(0, Y + H, -D/2 + crownT/2), CC)
crownN.Parent = lobby
local crownS = wedge("Crown_S", Vector3.new(W + 1, crownT, crownT),
	CFrame.new(0, Y + H, D/2 - crownT/2), CC)
crownS.Parent = lobby
local crownW = wedge("Crown_W", Vector3.new(crownT, crownT, D + 1),
	CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(-W/2 + crownT/2, Y + H, 0), CC)
crownW.Parent = lobby
local crownE = wedge("Crown_E", Vector3.new(crownT, crownT, D + 1),
	CFrame.Angles(0, 0, math.rad(-90)) * CFrame.new(W/2 - crownT/2, Y + H, 0), CC)
crownE.Parent = lobby

-- Back wall (zMin) — solid
local backWall = part("Wall_Back", Vector3.new(W, H, T), CFrame.new(0, Y + H/2, -D/2), WALL_BG)
backWall.Parent = lobby

-- Left wall (xMin) — solid
local leftWall = part("Wall_Left", Vector3.new(T, H, D), CFrame.new(-W/2, Y + H/2, 0), WALL_BG)
leftWall.Parent = lobby

-- Right wall (xMax) — solid
local rightWall = part("Wall_Right", Vector3.new(T, H, D), CFrame.new(W/2, Y + H/2, 0), WALL_BG)
rightWall.Parent = lobby

-- Baseboards along walls
local bbH = 0.8
local bbD = 0.3
local bbN = part("Baseboard_N", Vector3.new(W - 0.4, bbH, bbD),
	CFrame.new(0, Y + bbH/2, -D/2 + bbD/2 + 0.05), DARK_WOOD, Enum.Material.Wood)
bbN.Parent = lobby
local bbS = part("Baseboard_S", Vector3.new(W - 0.4, bbH, bbD),
	CFrame.new(0, Y + bbH/2, D/2 - bbD/2 - 0.05), DARK_WOOD, Enum.Material.Wood)
bbS.Parent = lobby
local bbW = part("Baseboard_W", Vector3.new(bbD, bbH, D - 0.4),
	CFrame.new(-W/2 + bbD/2 + 0.05, Y + bbH/2, 0), DARK_WOOD, Enum.Material.Wood)
bbW.Parent = lobby
local bbE = part("Baseboard_E", Vector3.new(bbD, bbH, D - 0.4),
	CFrame.new(W/2 - bbD/2 - 0.05, Y + bbH/2, 0), DARK_WOOD, Enum.Material.Wood)
bbE.Parent = lobby

-- Gold mid-wall trim (wainscoting accent)
local trimH = 1.2
local trimY = Y + 7.5
local trimN = part("WallTrim_N", Vector3.new(W - 0.4, trimH, 0.4),
	CFrame.new(0, trimY, -D/2 + 0.3), GOLD, Enum.Material.Metal)
trimN.Parent = lobby
local trimS = part("WallTrim_S", Vector3.new(W - 0.4, trimH, 0.4),
	CFrame.new(0, trimY, D/2 - 0.3), GOLD, Enum.Material.Metal)
trimS.Parent = lobby
local trimW = part("WallTrim_W", Vector3.new(0.4, trimH, D - 0.4),
	CFrame.new(-W/2 + 0.3, trimY, 0), GOLD, Enum.Material.Metal)
trimW.Parent = lobby
local trimE = part("WallTrim_E", Vector3.new(0.4, trimH, D - 0.4),
	CFrame.new(W/2 - 0.3, trimY, 0), GOLD, Enum.Material.Metal)
trimE.Parent = lobby

-- === RED CARPET RUNNER (center, from spawn toward desk) ===
local carpet = part("CarpetRunner", Vector3.new(12, 0.12, 32),
	CFrame.new(0, Y + 0.31, 2), CRIMSON, Enum.Material.Fabric)
carpet.Parent = lobby
local carpetBorderL = part("CarpetBorder_L", Vector3.new(0.5, 0.12, 32),
	CFrame.new(-6.25, Y + 0.31, 2), GOLD, Enum.Material.Plastic)
carpetBorderL.Parent = lobby
local carpetBorderR = part("CarpetBorder_R", Vector3.new(0.5, 0.12, 32),
	CFrame.new(6.25, Y + 0.31, 2), GOLD, Enum.Material.Plastic)
carpetBorderR.Parent = lobby

-- === RECEPTION DESK (pulled forward, NPC stands behind) ===
local deskZ = -D/2 + 7
local deskW = 16
local deskH = 4
local deskTop = part("DeskTop", Vector3.new(deskW, 0.5, 4),
	CFrame.new(0, Y + deskH, deskZ), DARK_WOOD, Enum.Material.Wood)
deskTop.Parent = lobby
local deskFront = part("DeskFront", Vector3.new(deskW, deskH, 0.3),
	CFrame.new(0, Y + deskH/2, deskZ - 2), DARK_WOOD, Enum.Material.Wood)
deskFront.Parent = lobby
local deskCounter = part("DeskCounter", Vector3.new(deskW, 0.5, 2.8),
	CFrame.new(0, Y + deskH + 0.5, deskZ + 0.5), MED_WOOD, Enum.Material.Wood)
deskCounter.Parent = lobby
-- Desk gold trim
local deskTrim = part("DeskTrim", Vector3.new(deskW + 0.5, 0.2, 4.5),
	CFrame.new(0, Y + deskH + 0.01, deskZ), GOLD, Enum.Material.Metal)
deskTrim.Parent = lobby
-- Desk front gold accent
local deskAccent = part("DeskAccent", Vector3.new(deskW - 1, 0.15, 0.4),
	CFrame.new(0, Y + deskH/2, deskZ - 1.85), GOLD_BRIGHT, Enum.Material.Metal)
deskAccent.Parent = lobby

-- Desk lamp
local deskLamp = part("DeskLamp", Vector3.new(0.5, 0.8, 0.5),
	CFrame.new(4, Y + deskH + 0.6, deskZ + 0.8), GOLD, Enum.Material.Metal)
deskLamp.Parent = lobby
addLight(deskLamp, Color3.fromRGB(255, 210, 150), 1, 10)

-- Jeremy ATS — Anomaly Tool Salesman (standing in front of back wall)
local wallZ = -D/2
local jeremyZ = wallZ + 3
local jeremyTorso = part("Jeremy_Torso", Vector3.new(2, 2.4, 1),
	CFrame.new(0, Y + 2.8, jeremyZ), Color3.fromRGB(60, 60, 70), Enum.Material.Plastic)
jeremyTorso.Parent = lobby
local jeremyHead = part("Jeremy_Head", Vector3.new(1.2, 1.2, 1.2),
	CFrame.new(0, Y + 4.6, jeremyZ), Color3.fromRGB(230, 200, 170), Enum.Material.Plastic)
jeremyHead.Parent = lobby
local jeremyArmL = part("Jeremy_ArmL", Vector3.new(0.4, 2, 0.4),
	CFrame.new(-1.2, Y + 2.8, jeremyZ), Color3.fromRGB(60, 60, 70), Enum.Material.Plastic)
jeremyArmL.Parent = lobby
local jeremyArmR = part("Jeremy_ArmR", Vector3.new(0.4, 2, 0.4),
	CFrame.new(1.2, Y + 2.8, jeremyZ), Color3.fromRGB(60, 60, 70), Enum.Material.Plastic)
jeremyArmR.Parent = lobby

-- Name tag BillboardGui
local jeremyTag = Instance.new("BillboardGui")
jeremyTag.Name = "JeremyTag"
jeremyTag.Size = UDim2.new(0, 200, 0, 60)
jeremyTag.StudsOffset = Vector3.new(0, 6, 0)
jeremyTag.AlwaysOnTop = true
jeremyTag.ResetOnSpawn = false
jeremyTag.Parent = jeremyHead
local jeremyName = Instance.new("TextLabel")
jeremyName.Name = "NameLabel"
jeremyName.Size = UDim2.new(1, 0, 0.5, 0)
jeremyName.BackgroundTransparency = 1
jeremyName.TextColor3 = Color3.fromRGB(255, 220, 100)
jeremyName.TextScaled = true
jeremyName.Font = Enum.Font.GothamBold
jeremyName.TextStrokeTransparency = 0.3
jeremyName.Text = "Jeremy ATS"
jeremyName.Parent = jeremyTag
local jeremyRole = Instance.new("TextLabel")
jeremyRole.Name = "RoleLabel"
jeremyRole.Size = UDim2.new(1, 0, 0.5, 0)
jeremyRole.Position = UDim2.new(0, 0, 0.5, 0)
jeremyRole.BackgroundTransparency = 1
jeremyRole.TextColor3 = Color3.fromRGB(200, 200, 200)
jeremyRole.TextScaled = true
jeremyRole.Font = Enum.Font.Gotham
jeremyRole.TextStrokeTransparency = 0.3
jeremyRole.Text = "Anomaly Tool Salesman"
jeremyRole.Parent = jeremyTag

-- Shelf units flanking the desk to box it in
local shelfH = 8
local shelfW = 3
local shelfD = 4
local shelfZ = deskZ
local shelfY = Y + shelfH/2
local shelfColor = Color3.fromRGB(55, 40, 30)

local function makeShelf(xPos)
	local frame = part("ShelfFrame_" .. xPos, Vector3.new(shelfW, shelfH, shelfD),
		CFrame.new(xPos, shelfY, shelfZ), shelfColor, Enum.Material.Wood)
	frame.Parent = lobby
	for i = 1, 3 do
		local board = part("ShelfBoard_" .. xPos .. "_" .. i, Vector3.new(shelfW - 0.4, 0.2, shelfD - 0.4),
			CFrame.new(xPos, Y + i * (shelfH / 4), shelfZ), MED_WOOD, Enum.Material.Wood)
		board.Parent = lobby
	end
end
makeShelf(-deskW/2 - shelfW/2 - 1)
makeShelf(deskW/2 + shelfW/2 + 1)

-- ProximityPrompt on a dedicated part in front of the desk
local jeremyPromptPart = part("Jeremy_Prompt", Vector3.new(3, 0.5, 1),
	CFrame.new(0, Y + 0.5, deskZ + 4), Color3.fromRGB(255, 255, 255))
jeremyPromptPart.Transparency = 1
jeremyPromptPart.CanCollide = false
jeremyPromptPart.Parent = lobby
local jeremyPrompt = Instance.new("ProximityPrompt")
jeremyPrompt.Name = "ShopPrompt"
jeremyPrompt.ActionText = "Browse Cosmetics"
jeremyPrompt.MaxActivationDistance = 8
jeremyPrompt.RequiresLineOfSight = false
jeremyPrompt.HoldDuration = 0
jeremyPrompt.Parent = jeremyPromptPart

-- Bay dimensions (used by columns and bay construction)
local bayW = 16
local frontZ = D/2
local bayDepth = 8
local bayHeight = 14
local bayY = Y + 1

-- === COLUMNS ===
local colSpacing = 14
local colW = 1.2
local colH = H - 1
for x = -W/2 + colSpacing, W/2 - colSpacing, colSpacing do
	if math.abs(x) < bayW/2 + 2 then continue end
	for z = -D/2 + 4, D/2 - 4, D - 8 do
		local col = part("Column_" .. math.floor(x) .. "_" .. math.floor(z),
			Vector3.new(colW, colH, colW),
			CFrame.new(x, Y + 1 + colH/2, z), MARBLE, Enum.Material.Marble)
		col.Parent = lobby
		-- Gold capital
		local cap = part("ColumnCap_" .. math.floor(x) .. "_" .. math.floor(z),
			Vector3.new(colW + 0.6, 0.3, colW + 0.6),
			CFrame.new(x, Y + 1 + colH, z), GOLD, Enum.Material.Metal)
		cap.Parent = lobby
		-- Base
		local base = part("ColumnBase_" .. math.floor(x) .. "_" .. math.floor(z),
			Vector3.new(colW + 0.8, 0.3, colW + 0.8),
			CFrame.new(x, Y + 1, z), MARBLE, Enum.Material.Marble)
		base.Parent = lobby
	end
end

-- === CENTER CHANDELIER ===
local chandelierRod = part("ChandelierRod", Vector3.new(0.2, 1.5, 0.2),
	CFrame.new(0, Y + H - 1, 0), GOLD, Enum.Material.Metal)
chandelierRod.Parent = lobby
local chandelierBody = part("ChandelierBody", Vector3.new(3, 0.5, 3),
	CFrame.new(0, Y + H - 1.75, 0), GOLD, Enum.Material.Metal)
chandelierBody.Parent = lobby
for i = 0, 3 do
	local angle = i * 90
	local arm = part("ChandelierArm_" .. i, Vector3.new(2, 0.15, 0.15),
		CFrame.Angles(0, math.rad(angle), math.rad(20)) * CFrame.new(1.5, 0, 0) * CFrame.new(0, Y + H - 1.75, 0),
		GOLD, Enum.Material.Metal)
	arm.Parent = lobby
end
addLight(chandelierBody, Color3.fromRGB(255, 220, 180), 1.2, 18)
-- Additional bulbs on chandelier
for i = 1, 4 do
	local bl = part("Bulb_" .. i, Vector3.new(0.3, 0.3, 0.3),
		CFrame.new(math.sin(math.rad(i * 90)) * 1.2, Y + H - 2, math.cos(math.rad(i * 90)) * 1.2),
		Color3.fromRGB(255, 245, 210))
	bl.Parent = lobby
end
-- Neon ring accent below chandelier
local neonRing = part("NeonRing", Vector3.new(5, 0.2, 5),
	CFrame.new(0, Y + H - 2.3, 0), GOLD_BRIGHT, Enum.Material.Neon)
neonRing.Parent = lobby

-- === WALL SCONCES ===
local sconcePositions = {
	{ -20, -2 }, { -20, 2 }, { 20, -2 }, { 20, 2 },
	{ -8, -2 }, { -8, 2 }, { 8, -2 }, { 8, 2 },
}
for _, pos in ipairs(sconcePositions) do
	local sx, sz = pos[1], pos[2]
	local sconce = part("Sconce_" .. sx .. "_" .. sz, Vector3.new(0.2, 0.6, 0.3),
		CFrame.new(sx, Y + 10, sz), GOLD, Enum.Material.Metal)
	sconce.Parent = lobby
	local ns = part("SconceGlow_" .. sx .. "_" .. sz, Vector3.new(0.3, 0.3, 0.3),
		CFrame.new(sx, Y + 10.1, sz), Color3.fromRGB(255, 230, 200))
	ns.Parent = lobby
	local sl = Instance.new("SpotLight")
	sl.Color = Color3.fromRGB(255, 220, 180)
	sl.Brightness = 0.5
	sl.Range = 12
	sl.Angle = 120
	sl.Face = Enum.NormalId.Front
	sl.Parent = ns
end

-- === SEATING AREA (center-left) ===
local seatCF = CFrame.new(-10, Y + 0.5, -5)
local sofaBack = part("Sofa_Back", Vector3.new(6, 2.5, 0.5),
	seatCF * CFrame.new(0, 1.25, -2.25), CRIMSON, Enum.Material.Fabric)
sofaBack.Parent = lobby
local sofaSeat = part("Sofa_Seat", Vector3.new(6, 0.8, 2),
	seatCF * CFrame.new(0, 0.4, 0), CRIMSON, Enum.Material.Fabric)
sofaSeat.Parent = lobby
local sofaArmL = part("Sofa_ArmL", Vector3.new(0.5, 1.5, 2.2),
	seatCF * CFrame.new(-3.25, 0.75, -0.1), DARK_WOOD, Enum.Material.Wood)
sofaArmL.Parent = lobby
local sofaArmR = part("Sofa_ArmR", Vector3.new(0.5, 1.5, 2.2),
	seatCF * CFrame.new(3.25, 0.75, -0.1), DARK_WOOD, Enum.Material.Wood)
sofaArmR.Parent = lobby

-- Coffee table in front of sofa (marble top)
local coffeeTable = part("CoffeeTable", Vector3.new(3.5, 0.5, 2),
	seatCF * CFrame.new(0, 0.25, 3.5), MARBLE, Enum.Material.Marble)
coffeeTable.Parent = lobby
-- Gold edge trim
local coffeeTrim = part("CoffeeTable_Trim", Vector3.new(3.7, 0.1, 2.2),
	seatCF * CFrame.new(0, 0.5, 3.5), GOLD, Enum.Material.Metal)
coffeeTrim.Parent = lobby

-- Small lamp on coffee table
local tableLamp = part("TableLamp", Vector3.new(0.4, 1, 0.4),
	seatCF * CFrame.new(1.2, 0.8, 3.5), GOLD, Enum.Material.Metal)
tableLamp.Parent = lobby
addLight(tableLamp, Color3.fromRGB(255, 200, 150), 0.8, 8)

-- Second sofa on the right side (matching brown)
local seatCF2 = CFrame.new(10, Y + 0.5, -5)
local sofaBack2 = part("Sofa2_Back", Vector3.new(6, 2.5, 0.5),
	seatCF2 * CFrame.new(0, 1.25, -2.25), Color3.fromRGB(65, 45, 35), Enum.Material.Fabric)
sofaBack2.Parent = lobby
local sofaSeat2 = part("Sofa2_Seat", Vector3.new(6, 0.8, 2),
	seatCF2 * CFrame.new(0, 0.4, 0), Color3.fromRGB(65, 45, 35), Enum.Material.Fabric)
sofaSeat2.Parent = lobby
local sofaArm2L = part("Sofa2_ArmL", Vector3.new(0.5, 1.5, 2.2),
	seatCF2 * CFrame.new(-3.25, 0.75, -0.1), DARK_WOOD, Enum.Material.Wood)
sofaArm2L.Parent = lobby
local sofaArm2R = part("Sofa2_ArmR", Vector3.new(0.5, 1.5, 2.2),
	seatCF2 * CFrame.new(3.25, 0.75, -0.1), DARK_WOOD, Enum.Material.Wood)
sofaArm2R.Parent = lobby

-- Coffee table for second sofa
local coffeeTable2 = part("CoffeeTable2", Vector3.new(3.5, 0.5, 2),
	seatCF2 * CFrame.new(0, 0.25, 3.5), MARBLE, Enum.Material.Marble)
coffeeTable2.Parent = lobby
local coffeeTrim2 = part("CoffeeTable2_Trim", Vector3.new(3.7, 0.1, 2.2),
	seatCF2 * CFrame.new(0, 0.5, 3.5), GOLD, Enum.Material.Metal)
coffeeTrim2.Parent = lobby

-- === POTTED PLANTS ===
local function addPlant(name, cf)
	local pot = part(name .. "_Pot", Vector3.new(1.5, 0.8, 1.5),
		cf * CFrame.new(0, 0.4, 0), Color3.fromRGB(140, 90, 60), Enum.Material.Plastic)
	pot.Parent = lobby
	local trunk = part(name .. "_Trunk", Vector3.new(0.3, 2, 0.3),
		cf * CFrame.new(0, 1.5, 0), GREEN, Enum.Material.Plastic)
	trunk.Parent = lobby
	local leaves = part(name .. "_Leaves", Vector3.new(2, 1.5, 2),
		cf * CFrame.new(0, 2.8, 0), GREEN, Enum.Material.Plastic)
	leaves.Parent = lobby
end
addPlant("Plant1", CFrame.new(-22, Y, -12))
addPlant("Plant2", CFrame.new(22, Y, 12))
addPlant("Plant3", CFrame.new(-22, Y, 12))
addPlant("Plant4", CFrame.new(22, Y, -12))

-- === FRONT WALL + BAY OPENING ===

-- Front wall (zMax) — three segments with a 16-stud opening for the bay

-- Left segment: from x=-W/2 to x=-bayW/2
local segLeft = part("Wall_Front_L", Vector3.new((W - bayW) / 2, H, T),
	CFrame.new(-(W + bayW) / 4, Y + H/2, frontZ), WALL_BG)
segLeft.Parent = lobby

-- Right segment: from x=bayW/2 to x=W/2
local segRight = part("Wall_Front_R", Vector3.new((W - bayW) / 2, H, T),
	CFrame.new((W + bayW) / 4, Y + H/2, frontZ), WALL_BG)
segRight.Parent = lobby

-- Top segment: above the bay opening
local segTop = part("Wall_Front_T", Vector3.new(bayW, H - 14, T),
	CFrame.new(0, Y + (H + 14) / 2, frontZ), WALL_BG)
segTop.Parent = lobby

-- Bay vestibule floor (slightly raised, different material to mark the zone)
local bayFloor = part("BayFloor", Vector3.new(bayW - 2, 0.2, 6),
	CFrame.new(0, Y + 0.35, frontZ - 3), Color3.fromRGB(60, 55, 50), Enum.Material.Slate)
bayFloor.Parent = lobby

-- Door frame around the bay opening (metal trim)
local frameL = part("BayFrame_L", Vector3.new(0.8, 14, 0.8),
	CFrame.new(-bayW/2, Y + 7.5, frontZ), BC, Enum.Material.Metal)
frameL.Parent = lobby

local frameR = part("BayFrame_R", Vector3.new(0.8, 14, 0.8),
	CFrame.new(bayW/2, Y + 7.5, frontZ), BC, Enum.Material.Metal)
frameR.Parent = lobby

local frameT = part("BayFrame_T", Vector3.new(bayW + 1.6, 0.8, 0.8),
	CFrame.new(0, Y + 14.4, frontZ), BC, Enum.Material.Metal)
frameT.Parent = lobby

-- Elevator bay room (extends outward from the opening)

-- Bay floor
local bayFloorOuter = part("BayFloor_Outer", Vector3.new(bayW, 0.3, bayDepth),
	CFrame.new(0, bayY, frontZ + bayDepth/2), Color3.fromRGB(40, 35, 30), Enum.Material.Fabric)
bayFloorOuter.Parent = lobby

-- Bay side walls
local bayWallL = part("BayWall_L", Vector3.new(0.5, bayHeight, bayDepth),
	CFrame.new(-bayW/2, bayY + bayHeight/2, frontZ + bayDepth/2), Color3.fromRGB(170, 140, 100), Enum.Material.Wood)
bayWallL.Parent = lobby

local bayWallR = part("BayWall_R", Vector3.new(0.5, bayHeight, bayDepth),
	CFrame.new(bayW/2, bayY + bayHeight/2, frontZ + bayDepth/2), Color3.fromRGB(170, 140, 100), Enum.Material.Wood)
bayWallR.Parent = lobby

-- Bay ceiling
local bayCeil = part("BayCeiling", Vector3.new(bayW, 0.3, bayDepth),
	CFrame.new(0, bayY + bayHeight, frontZ + bayDepth/2), CC)
bayCeil.Parent = lobby

-- Bay back wall (inner side, faces the lobby opening)
local bayBack = part("BayBack", Vector3.new(bayW - 1, bayHeight, 0.3),
	CFrame.new(0, bayY + bayHeight/2, frontZ + bayDepth), Color3.fromRGB(170, 140, 100), Enum.Material.Wood)
bayBack.Parent = lobby

-- Elevator doors (two panels with a gap)
local doorW = bayW / 2 - 0.3
local doorH = 12
local doorY = bayY + 0.5
local doorD = 0.3
local doorZ = frontZ + bayDepth - 0.2
local doorL = part("ElevatorDoor_L", Vector3.new(doorW, doorH, doorD),
	CFrame.new(-doorW/2 - 0.15, doorY + doorH/2, doorZ), Color3.fromRGB(180, 175, 165), Enum.Material.Metal)
doorL.Parent = lobby
local doorR = part("ElevatorDoor_R", Vector3.new(doorW, doorH, doorD),
	CFrame.new(doorW/2 + 0.15, doorY + doorH/2, doorZ), Color3.fromRGB(180, 175, 165), Enum.Material.Metal)
doorR.Parent = lobby

-- Door center gap trim
local doorGap = part("DoorGap", Vector3.new(0.1, doorH, doorD + 0.1),
	CFrame.new(0, doorY + doorH/2, doorZ), Color3.fromRGB(100, 95, 90), Enum.Material.Metal)
doorGap.Parent = lobby

-- Door top trim
local doorTrim = part("DoorTrim_T", Vector3.new(bayW - 0.5, 0.3, doorD + 0.2),
	CFrame.new(0, doorY + doorH + 0.15, doorZ), GOLD, Enum.Material.Metal)
doorTrim.Parent = lobby

-- Floor indicator light above doors
local floorLight = part("FloorIndicator", Vector3.new(2, 0.6, 0.2),
	CFrame.new(0, doorY + doorH + 1.5, doorZ), Color3.fromRGB(30, 30, 30))
floorLight.Parent = lobby
local flg = Instance.new("SurfaceGui")
flg.Face = Enum.NormalId.Back
flg.AlwaysOnTop = true
flg.ResetOnSpawn = false
flg.Parent = floorLight
local fll = Instance.new("TextLabel")
fll.Size = UDim2.new(1, 0, 1, 0)
fll.BackgroundTransparency = 1
fll.TextColor3 = Color3.fromRGB(255, 220, 50)
fll.TextScaled = true
fll.Font = Enum.Font.GothamBold
fll.TextStrokeTransparency = 0.3
fll.Text = "G"
fll.Parent = flg

-- Bay light
local bayLight = part("BayLight", Vector3.new(1, 0.2, 1),
	CFrame.new(0, bayY + bayHeight - 0.5, frontZ + bayDepth/2), Color3.fromRGB(255, 240, 200))
bayLight.Parent = lobby
addLight(bayLight, Color3.fromRGB(255, 220, 150), 1.5, 12)

-- Overhead sign inside the bay
local innerSign = part("BayInnerSign", Vector3.new(bayW - 2, 1.5, 0.2),
	CFrame.new(0, bayY + bayHeight - 2, frontZ + bayDepth - 0.5), Color3.fromRGB(30, 30, 30))
innerSign.Parent = lobby

local isg = Instance.new("SurfaceGui")
isg.Face = Enum.NormalId.Front
isg.AlwaysOnTop = true
isg.ResetOnSpawn = false
isg.Parent = innerSign

local ilabel = Instance.new("TextLabel")
ilabel.Size = UDim2.new(1, 0, 1, 0)
ilabel.BackgroundTransparency = 1
ilabel.TextColor3 = Color3.fromRGB(255, 220, 50)
ilabel.TextScaled = true
ilabel.Font = Enum.Font.GothamBold
ilabel.TextStrokeTransparency = 0.3
ilabel.Text = "ELEVATOR BAY"
ilabel.Parent = isg

-- Countdown sign above the bay opening (lobby side)
local sign = part("BaySign", Vector3.new(bayW, 2, 0.3),
	CFrame.new(0, Y + 15.5, frontZ - 0.5), Color3.fromRGB(30, 30, 30))
sign.Parent = lobby

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Back
sg.AlwaysOnTop = true
sg.ResetOnSpawn = false
sg.Parent = sign

local label = Instance.new("TextLabel")
label.Name = "Countdown"
label.Size = UDim2.new(1, 0, 0.6, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 220, 50)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.TextStrokeTransparency = 0.3
label.Text = "WAITING"
label.Parent = sg

local sub = Instance.new("TextLabel")
sub.Name = "SubText"
sub.Size = UDim2.new(1, 0, 0.4, 0)
sub.Position = UDim2.new(0, 0, 0.6, 0)
sub.BackgroundTransparency = 1
sub.TextColor3 = Color3.fromRGB(200, 200, 200)
sub.TextScaled = true
sub.Font = Enum.Font.Gotham
sub.TextStrokeTransparency = 0.3
sub.Text = "Max 8 Players"
sub.Parent = sg

-- BayDetector (invisible, inside the bay cab)
local detector = part("BayDetector", Vector3.new(bayW - 3, 3, bayDepth - 2),
	CFrame.new(0, Y + 1.5, frontZ + bayDepth/2), Color3.fromRGB(255, 0, 0))
detector.Transparency = 1
detector.CanCollide = false
detector.Parent = lobby

-- Spawn location (center of lobby, facing the bay)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "SpawnLocation"
spawn.Size = Vector3.new(4, 0.5, 4)
spawn.CFrame = CFrame.lookAt(Vector3.new(0, Y + 0.6, 0), Vector3.new(0, Y + 0.6, 20))
spawn.Anchored = true
spawn.Locked = false
spawn.Transparency = 0.5
spawn.BrickColor = BrickColor.new("Bright green")
spawn.Duration = 0
spawn.Parent = lobby

-- Main ceiling light (ambient fill)
local fillLight = part("FillLight", Vector3.new(1, 0.2, 1),
	CFrame.new(0, Y + H - 0.3, 0), Color3.fromRGB(255, 245, 230))
fillLight.Parent = lobby
addLight(fillLight, Color3.fromRGB(255, 230, 200), 0.6, 30)

-- Hotel name sign above reception
local hotelSign = part("HotelSign", Vector3.new(14, 2, 0.3),
	CFrame.new(0, Y + 12, -D/2 + 0.4), Color3.fromRGB(30, 30, 30))
hotelSign.Parent = lobby
local hsg = Instance.new("SurfaceGui")
hsg.Face = Enum.NormalId.Front
hsg.AlwaysOnTop = true
hsg.ResetOnSpawn = false
hsg.Parent = hotelSign
local hsl = Instance.new("TextLabel")
hsl.Size = UDim2.new(1, -10, 1, -10)
hsl.Position = UDim2.new(0, 5, 0, 5)
hsl.BackgroundTransparency = 1
hsl.TextColor3 = Color3.fromRGB(255, 220, 100)
hsl.TextScaled = true
hsl.Font = Enum.Font.GothamBold
hsl.TextStrokeTransparency = 0.3
hsl.Text = "THE ECHO FLOOR"
hsl.Parent = hsg

-- Reception directional text below sign
local dirSign = part("DirSign", Vector3.new(10, 0.8, 0.2),
	CFrame.new(0, Y + 10, -D/2 + 0.45), Color3.fromRGB(50, 50, 55))
dirSign.Parent = lobby
local dsg = Instance.new("SurfaceGui")
dsg.Face = Enum.NormalId.Front
dsg.AlwaysOnTop = true
dsg.ResetOnSpawn = false
dsg.Parent = dirSign
local dsl = Instance.new("TextLabel")
dsl.Size = UDim2.new(1, -10, 1, -10)
dsl.Position = UDim2.new(0, 5, 0, 5)
dsl.BackgroundTransparency = 1
dsl.TextColor3 = Color3.fromRGB(200, 200, 200)
dsl.TextScaled = true
dsl.Font = Enum.Font.GothamBold
dsl.TextStrokeTransparency = 0.3
dsl.Text = "Elevator Bay  ›"
dsl.Parent = dsg

-- === LEADERBOARD BOARDS ===

local ROW_COUNT = 10

local function makeBoard(name, cf, face, titleColor, titleText)
	local board = part(name, Vector3.new(0.1, 12, 20), cf, Color3.fromRGB(10, 10, 14))
	board.Parent = lobby

	local sg = Instance.new("SurfaceGui")
	sg.Name = name .. "Gui"
	sg.Face = face
	sg.ResetOnSpawn = false
	sg.PixelsPerStud = 50
	sg.Parent = board

	-- Background
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	bg.BorderSizePixel = 0
	bg.Parent = sg

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -30, 0, 60)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.BackgroundTransparency = 1
	title.TextColor3 = titleColor
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextStrokeTransparency = 0.4
	title.Text = titleText
	title.Parent = bg

	-- Divider
	local div = Instance.new("Frame")
	div.Size = UDim2.new(1, -30, 0, 2)
	div.Position = UDim2.new(0, 15, 0, 72)
	div.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	div.BorderSizePixel = 0
	div.Parent = bg

	-- Column headers
	local hdr = Instance.new("Frame")
	hdr.Size = UDim2.new(1, -30, 0, 30)
	hdr.Position = UDim2.new(0, 15, 0, 76)
	hdr.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	hdr.BorderSizePixel = 0
	hdr.Parent = bg

	local function headerLabel(text, posX, w)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(0, w, 0, 24)
		l.Position = UDim2.new(0, posX, 0, 3)
		l.BackgroundTransparency = 1
		l.TextColor3 = Color3.fromRGB(140, 140, 145)
		l.TextScaled = true
		l.Font = Enum.Font.GothamBold
		l.TextStrokeTransparency = 0.5
		l.Text = text
		l.Parent = hdr
		return l
	end
	headerLabel("RANK", 10, 80)
	headerLabel("PLAYER", 100, 500)
	headerLabel("SCORE", 640, 120)

	-- Rows
	local rows = {}
	for i = 1, ROW_COUNT do
		local y = 110 + (i - 1) * 46

		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.Size = UDim2.new(1, -30, 0, 44)
		row.Position = UDim2.new(0, 15, 0, y)
		row.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
		row.BorderSizePixel = 0
		row.Visible = false
		row.Parent = bg

		local rank = Instance.new("TextLabel")
		rank.Name = "Rank"
		rank.Size = UDim2.new(0, 80, 1, 0)
		rank.Position = UDim2.new(0, 10, 0, 0)
		rank.BackgroundTransparency = 1
		rank.TextColor3 = Color3.fromRGB(200, 200, 200)
		rank.TextScaled = true
		rank.Font = Enum.Font.GothamBold
		rank.TextStrokeTransparency = 0.3
		rank.TextXAlignment = Enum.TextXAlignment.Center
		rank.Text = tostring(i)
		rank.Parent = row

		local pname = Instance.new("TextLabel")
		pname.Name = "Name"
		pname.Size = UDim2.new(0, 500, 1, 0)
		pname.Position = UDim2.new(0, 100, 0, 0)
		pname.BackgroundTransparency = 1
		pname.TextColor3 = Color3.fromRGB(230, 230, 230)
		pname.TextScaled = true
		pname.Font = Enum.Font.Gotham
		pname.TextStrokeTransparency = 0.3
		pname.TextXAlignment = Enum.TextXAlignment.Left
		pname.Parent = row

		local score = Instance.new("TextLabel")
		score.Name = "Score"
		score.Size = UDim2.new(0, 120, 1, 0)
		score.Position = UDim2.new(0, 640, 0, 0)
		score.BackgroundTransparency = 1
		score.TextColor3 = Color3.fromRGB(255, 220, 100)
		score.TextScaled = true
		score.Font = Enum.Font.GothamBold
		score.TextStrokeTransparency = 0.3
		score.TextXAlignment = Enum.TextXAlignment.Right
		score.Parent = row

		rows[i] = { frame = row, rank = rank, name = pname, score = score }
	end

	-- Empty state label
	local empty = Instance.new("TextLabel")
	empty.Name = "EmptyLabel"
	empty.Size = UDim2.new(1, -60, 0, 40)
	empty.Position = UDim2.new(0, 30, 0, 250)
	empty.BackgroundTransparency = 1
	empty.TextColor3 = Color3.fromRGB(120, 120, 120)
	empty.TextScaled = true
	empty.Font = Enum.Font.Gotham
	empty.TextStrokeTransparency = 0.5
	empty.TextXAlignment = Enum.TextXAlignment.Center
	empty.Text = "No data"
	empty.Parent = bg

	return {
		surfaceGui = sg,
		rows = rows,
		empty = empty,
	}
end

local boardThick = 0.1
local leftWallInner = -W/2 + T/2
local rightWallInner = W/2 - T/2

local prevBoard = makeBoard("PrevGameBoard", CFrame.new(leftWallInner + boardThick/2, Y + 7, 0),
	Enum.NormalId.Right, Color3.fromRGB(255, 220, 100), "LAST GAME")
local allBoard = makeBoard("AllTimeBoard", CFrame.new(rightWallInner - boardThick/2, Y + 7, 0),
	Enum.NormalId.Left, Color3.fromRGB(100, 200, 255), "ALL TIME")

print("Lobby built at Y=" .. Y .. " with elevator bay, reception, seating, chandelier, and leaderboards.")
return true
