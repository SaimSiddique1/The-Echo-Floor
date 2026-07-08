-- ElevatorGenerator.luau
-- Run from Command Bar: loadstring(game.ReplicatedStorage.Tools.ElevatorGenerator.Source)()
-- Builds the elevator model in Workspace. Persistent hub, never destroyed.

local DW = 22
local DD = 18
local DH = 15
local T = 0.5

local WC = Color3.fromRGB(170, 140, 100)
local FC = Color3.fromRGB(40, 35, 30)
local CC = Color3.fromRGB(240, 240, 235)
local MC = Color3.fromRGB(200, 175, 120)
local DC = Color3.fromRGB(160, 150, 140)

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

local elevator = Instance.new("Model")
elevator.Name = "Elevator"
elevator.Parent = workspace

-- Floor
local floor = part("Floor", Vector3.new(DD, 0.5, DW),
	CFrame.new(0, 0, 0), FC, Enum.Material.Fabric)
floor.Parent = elevator

-- Teleport target (where players land when round starts)
local spawn = part("TeleportTarget", Vector3.new(4, 0.5, 4),
	CFrame.new(0, 0.5, 0), Color3.fromRGB(100, 200, 100), Enum.Material.Plastic, 0.8)
spawn.Parent = elevator

-- Ceiling
local ceiling = part("Ceiling", Vector3.new(DD, 0.3, DW),
	CFrame.new(0, DH, 0), CC)
ceiling.Parent = elevator

-- Back wall (xMin, wood paneling)
local backWall = part("BackWall", Vector3.new(T, DH, DW),
	CFrame.new(-DD/2, DH/2, 0), WC, Enum.Material.Wood)
backWall.Parent = elevator

-- Left wall (zMin, wood paneling)
local leftWall = part("LeftWall", Vector3.new(DD, DH, T),
	CFrame.new(0, DH/2, -DW/2), WC, Enum.Material.Wood)
leftWall.Parent = elevator

-- Right wall (zMax, wood paneling)
local rightWall = part("RightWall", Vector3.new(DD, DH, T),
	CFrame.new(0, DH/2, DW/2), WC, Enum.Material.Wood)
rightWall.Parent = elevator

-- Brass handrails along side walls
local railL = part("Handrail_L", Vector3.new(DD - 1, 0.15, 0.15),
	CFrame.new(0, 4.5, -DW/2 + 0.5), MC, Enum.Material.Metal)
railL.Parent = elevator

local railR = part("Handrail_R", Vector3.new(DD - 1, 0.15, 0.15),
	CFrame.new(0, 4.5, DW/2 - 0.5), MC, Enum.Material.Metal)
railR.Parent = elevator

-- Two sliding metal doors (front wall, xMax side)
-- Door opening spans 20 of 22 studs (1 stud frame each side)
-- Left door: z=-10 to 0, Right door: z=0 to 10
local doorH = 13
local doorY = 0
local doorX = DD/2
local doorHalfW = 10
local doorGap = 0.1

local doorL = part("Door_Left", Vector3.new(0.2, doorH, doorHalfW),
	CFrame.new(doorX, doorY + doorH/2, -doorHalfW/2), DC, Enum.Material.Metal)
doorL.Parent = elevator

local doorR = part("Door_Right", Vector3.new(0.2, doorH, doorHalfW),
	CFrame.new(doorX, doorY + doorH/2, doorHalfW/2), DC, Enum.Material.Metal)
doorR.Parent = elevator

-- Door frame
local frameW = DW - doorHalfW * 2
local frameThick = 0.3

local frameLeft = part("DoorFrame_L", Vector3.new(0.4, doorH, frameThick),
	CFrame.new(doorX, doorY + doorH/2, -DW/2 + frameThick/2), Color3.fromRGB(120, 110, 100), Enum.Material.Metal)
frameLeft.Parent = elevator

local frameRight = part("DoorFrame_R", Vector3.new(0.4, doorH, frameThick),
	CFrame.new(doorX, doorY + doorH/2, DW/2 - frameThick/2), Color3.fromRGB(120, 110, 100), Enum.Material.Metal)
frameRight.Parent = elevator

local frameTop = part("DoorFrame_T", Vector3.new(0.4, frameThick, DW - 1),
	CFrame.new(doorX, doorY + doorH + frameThick/2, 0), Color3.fromRGB(120, 110, 100), Enum.Material.Metal)
frameTop.Parent = elevator

-- Wall above doors
local aboveDoor = part("AboveDoor", Vector3.new(T, DH - doorY - doorH, DW),
	CFrame.new(doorX, doorY + doorH + (DH - doorY - doorH)/2, 0), WC, Enum.Material.Wood)
aboveDoor.Parent = elevator

-- Floor number display on back wall
local displayW = 7
local displayH = 5
local displayFrame = part("FloorDisplay", Vector3.new(0.1, displayH, displayW),
	CFrame.new(-DD/2 + 0.3, DH * 0.55, 0),
	Color3.fromRGB(10, 10, 10), Enum.Material.Plastic)
displayFrame.Parent = elevator

-- Invisible backing with larger surface for the text
local textSurface = part("FloorTextSurface", Vector3.new(0.1, 12, 16),
	CFrame.new(-DD/2 + 0.6, DH * 0.55, 0),
	Color3.fromRGB(0, 0, 0), Enum.Material.Plastic, 1)
textSurface.Parent = elevator

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Right
sg.AlwaysOnTop = false
sg.ResetOnSpawn = false
sg.Parent = textSurface

local label = Instance.new("TextLabel")
label.Name = "FloorNumber"
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(0, 255, 100)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "0"
label.Parent = sg

-- Dim yellow light in center of ceiling
local lightPart = part("LightFixture", Vector3.new(1, 0.2, 1),
	CFrame.new(0, DH - 0.3, 0), Color3.fromRGB(255, 240, 200))
lightPart.Parent = elevator

local pointLight = Instance.new("PointLight")
pointLight.Color = Color3.fromRGB(255, 220, 150)
pointLight.Brightness = 1.5
pointLight.Range = 20
pointLight.Shadows = true
pointLight.Parent = lightPart

-- Ambient hum placeholder (add real SoundId later)

-- Position the elevator at the elevator lobby opening on the game floor
-- Elevator lobby zMin wall is at z=-27 (after floor centering), opening x=-30..-12
-- Elevator rotated 90° so doors face +Z toward the lobby opening
local OFFSET = CFrame.new(-46.1, 0, -9)
for _, child in elevator:GetChildren() do
	if child:IsA("BasePart") then
		child.CFrame = OFFSET * child.CFrame
	end
end

-- Clone to ServerStorage.Templates.Elevator
local templates = game.ServerStorage.Templates
local existing = templates:FindFirstChild("Elevator")
if existing then existing:Destroy() end
local saved = elevator:Clone()
saved.Name = "Elevator"
saved.Parent = templates

print("Elevator built in Workspace and saved to ServerStorage.Templates.Elevator.")
return true
