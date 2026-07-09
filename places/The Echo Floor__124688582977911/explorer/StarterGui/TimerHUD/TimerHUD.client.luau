local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Remotes = ReplicatedStorage.Remotes
local RunService = game:GetService("RunService")
local rs = ReplicatedStorage
local AnomalyConfig = require(ReplicatedStorage.Shared.AnomalySwapConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TimerHUD"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.DisplayOrder = 10
screenGui.IgnoreGuiInset = not isMobile
screenGui.Parent = playerGui

local topOffset = 10
if isMobile then
	local tl, _ = GuiService:GetGuiInset()
	topOffset = tl.Y + 10
end

if isMobile then
	local uiscale = Instance.new("UIScale")
	uiscale.Parent = screenGui
end

local timerBox = Instance.new("Frame")
timerBox.Name = "TimerBox"
timerBox.Size = UDim2.new(0, 100, 0, 40)
timerBox.Position = UDim2.new(0, 10, 0, topOffset)
timerBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerBox.BackgroundTransparency = 0.4
timerBox.BorderSizePixel = 0
timerBox.Parent = screenGui

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 1, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
timerLabel.TextScaled = true
timerLabel.TextXAlignment = Enum.TextXAlignment.Center
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = ""
timerLabel.Parent = timerBox

local MAP_SCALE = isMobile and 2.6 or 1.2
local MAP_W = isMobile and 440 or 205
local MAP_H = isMobile and 260 or 115
local MAP_RX = MAP_W / 2
local MAP_RY = MAP_H / 2

local minimap = Instance.new("Frame")
minimap.Name = "Minimap"
minimap.Size = UDim2.new(0, MAP_W, 0, MAP_H)
minimap.Position = UDim2.new(0, 10, 0, topOffset + (isMobile and 80 or 44))
minimap.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
minimap.BackgroundTransparency = 0.25
minimap.BorderSizePixel = 0
minimap.ClipsDescendants = true
minimap.Visible = false
minimap.Parent = screenGui

local mapClip = Instance.new("UICorner")
mapClip.CornerRadius = UDim.new(0, 10)
mapClip.Parent = minimap

local roomColors = {
	Hallway = Color3.fromRGB(220, 200, 170),
	ElevatorLobby = Color3.fromRGB(100, 150, 255),
	LivingRoom = Color3.fromRGB(255, 180, 80),
	Kitchen = Color3.fromRGB(255, 220, 80),
	Bedroom = Color3.fromRGB(180, 100, 220),
	Bathroom = Color3.fromRGB(80, 200, 200),
}

local roomNames = {
	ElevatorLobby = "Lobby",
	LivingRoom = "Living",
	Hallway = "Hall",
	Bedroom = "Bed",
	Bathroom = "Bath",
	Kitchen = "Kitch",
}

local roomDefs = {
	{ name = "Kitchen",       x = 12,   z = 57,   w = 36, h = 48 },
	{ name = "LivingRoom",    x = 15,   z = 3,    w = 42, h = 60 },
	{ name = "ElevatorLobby", x = -21,  z = -9,   w = 30, h = 36 },
	{ name = "Hallway",       x = 0,    z = -39,  w = 72, h = 24 },
	{ name = "Bedroom",       x = -18,  z = -66,  w = 36, h = 30 },
	{ name = "Bathroom",      x = 21,   z = -63,  w = 30, h = 24 },
}

for _, def in ipairs(roomDefs) do
	local sw = def.h * MAP_SCALE
	local sh = def.w * MAP_SCALE
	local cx = MAP_RX + def.z * MAP_SCALE
	local cy = MAP_RY - def.x * MAP_SCALE

	local cell = Instance.new("Frame")
	cell.Name = def.name
	cell.Size = UDim2.new(0, sw, 0, sh)
	cell.Position = UDim2.new(0, cx - sw/2, 0, cy - sh/2)
	cell.BackgroundColor3 = roomColors[def.name]
	cell.BackgroundTransparency = 0.35
	cell.BorderSizePixel = 1
	cell.BorderColor3 = Color3.fromRGB(35, 35, 40)
	cell.Parent = minimap

	local lb = Instance.new("TextLabel")
	lb.Name = "Label"
	lb.Size = UDim2.new(1, -4, 1, -4)
	lb.Position = UDim2.new(0, 2, 0, 2)
	lb.BackgroundTransparency = 1
	lb.Text = roomNames[def.name] or def.name
	lb.TextColor3 = Color3.fromRGB(255, 255, 255)
	lb.TextScaled = true
	lb.Font = Enum.Font.GothamBold
	lb.TextXAlignment = Enum.TextXAlignment.Center
	lb.Parent = cell
end

local playerDot = Instance.new("Frame")
playerDot.Name = "PlayerDot"
playerDot.Size = UDim2.new(0, 6, 0, 6)
playerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
playerDot.BorderSizePixel = 0
playerDot.ZIndex = 10
playerDot.Parent = minimap

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = playerDot

local dirArrow = Instance.new("Frame")
dirArrow.Name = "DirArrow"
dirArrow.Size = UDim2.new(0, 6, 0, 10)
dirArrow.Position = UDim2.new(0.5, -3, 0, -10)
dirArrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dirArrow.BorderSizePixel = 0
dirArrow.ZIndex = 11
dirArrow.Parent = playerDot

local arrowCorner = Instance.new("UICorner")
arrowCorner.CornerRadius = UDim.new(0, 2)
arrowCorner.Parent = dirArrow

local currentPhase = "explore"

local function updateMinimap()
	local char = player.Character
	if not char then minimap.Visible = false; return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then minimap.Visible = false; return end

	local px = root.Position.X
	local pz = root.Position.Z
	local lv = root.CFrame.LookVector

	local dx = pz * MAP_SCALE
	local dy = -px * MAP_SCALE
	playerDot.Position = UDim2.new(0, MAP_RX + dx - 3, 0, MAP_RY + dy - 3)

	local yaw = math.atan2(-lv.X, -lv.Z)
	dirArrow.Rotation = math.deg(yaw) - 90

	local current = nil
	for name, bounds in pairs(AnomalyConfig.roomBounds) do
		if px >= bounds.xMin and px <= bounds.xMax and pz >= bounds.zMin and pz <= bounds.zMax then
			current = name
			break
		end
	end

	local pingActive = pingTargetRoom and os.clock() < pingEndTime
	if not pingActive then pingTargetRoom = nil end

	for _, child in ipairs(minimap:GetChildren()) do
		if child:IsA("Frame") and child ~= playerDot and roomColors[child.Name] then
			if pingActive and child.Name == pingTargetRoom then
				child.BackgroundTransparency = 0
				child.BorderColor3 = Color3.fromRGB(255, 0, 0)
				child.BorderSizePixel = 3
			elseif not pingActive and child.Name == current then
				child.BackgroundTransparency = 0
				child.BorderColor3 = Color3.fromRGB(255, 220, 50)
				child.BorderSizePixel = 2
			else
				child.BackgroundTransparency = 0.35
				child.BorderColor3 = Color3.fromRGB(35, 35, 40)
				child.BorderSizePixel = 1
			end
		end
	end

	minimap.Visible = true
end

RunService.RenderStepped:Connect(updateMinimap)

local pingTargetRoom = nil
local pingEndTime = 0

rs.EchoPingEvent.Event:Connect(function(roomName, duration)
	pingTargetRoom = roomName
	pingEndTime = os.clock() + (duration or 5)
end)

-- Phase box
local phaseBox = Instance.new("Frame")
phaseBox.Name = "PhaseBox"
phaseBox.Size = UDim2.new(0, 300, 0, 40)
phaseBox.Position = UDim2.new(0.5, -150, 0, topOffset)
phaseBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
phaseBox.BackgroundTransparency = 0.3
phaseBox.BorderSizePixel = 0
phaseBox.Parent = screenGui

local phaseBoxCorner = Instance.new("UICorner")
phaseBoxCorner.CornerRadius = UDim.new(0, 8)
phaseBoxCorner.Parent = phaseBox

local phaseLabel = Instance.new("TextLabel")
phaseLabel.Name = "PhaseLabel"
phaseLabel.Size = UDim2.new(1, 0, 1, 0)
phaseLabel.BackgroundTransparency = 1
phaseLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
phaseLabel.TextScaled = true
phaseLabel.Font = Enum.Font.GothamBold
phaseLabel.TextXAlignment = Enum.TextXAlignment.Center
phaseLabel.Text = ""
phaseLabel.Parent = phaseBox

-- Coin HUD
local coinHUD = Instance.new("Frame")
coinHUD.Name = "CoinHUD"
coinHUD.Size = UDim2.new(0, 150, 0, 40)
coinHUD.Position = UDim2.new(1, -160, 0, topOffset)
coinHUD.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
coinHUD.BackgroundTransparency = 0.3
coinHUD.BorderSizePixel = 0
coinHUD.Parent = screenGui

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 8)
coinCorner.Parent = coinHUD

local coinIcon = Instance.new("Frame")
coinIcon.Size = UDim2.new(0, 20, 0, 20)
coinIcon.Position = UDim2.new(0, 10, 0.5, -10)
coinIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
coinIcon.BorderSizePixel = 0
coinIcon.Parent = coinHUD

local coinIconCorner = Instance.new("UICorner")
coinIconCorner.CornerRadius = UDim.new(1, 0)
coinIconCorner.Parent = coinIcon

local coinIconLabel = Instance.new("TextLabel")
coinIconLabel.Size = UDim2.new(1, 0, 1, 0)
coinIconLabel.BackgroundTransparency = 1
coinIconLabel.Text = "$"
coinIconLabel.TextColor3 = Color3.fromRGB(150, 110, 30)
coinIconLabel.TextScaled = true
coinIconLabel.Font = Enum.Font.GothamBold
coinIconLabel.Parent = coinIcon

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(1, -35, 1, 0)
coinLabel.Position = UDim2.new(0, 35, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
coinLabel.TextScaled = true
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Text = "0"
coinLabel.Parent = coinHUD

-- Result box
local resultBox = Instance.new("Frame")
resultBox.Name = "ResultBox"
resultBox.Size = UDim2.new(0, 400, 0, 70)
resultBox.Position = UDim2.new(0.5, -200, 0, topOffset + 55)
resultBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
resultBox.BackgroundTransparency = 0.4
resultBox.BorderSizePixel = 0
resultBox.Visible = false
resultBox.Parent = screenGui

if isMobile then
	local function updateScale()
		local camera = workspace.CurrentCamera
		if camera then
			local sz = camera.ViewportSize
			local s = math.min(sz.X / 1920, sz.Y / 1080)
			local scale = screenGui:FindFirstChildOfClass("UIScale")
			if scale then
				scale.Scale = math.clamp(s, 0.35, 2)
			end
		end
	end
	updateScale()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		updateScale()
		local cam = workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		end
	end)

	local function updateSafeArea()
		local tl, _ = GuiService:GetGuiInset()
		topOffset = tl.Y + 10
		timerBox.Position = UDim2.new(0, 10, 0, topOffset)
		minimap.Position = UDim2.new(0, 10, 0, topOffset + (isMobile and 80 or 44))
		phaseBox.Position = UDim2.new(0.5, -150, 0, topOffset)
		coinHUD.Position = UDim2.new(1, -160, 0, topOffset)
		resultBox.Position = UDim2.new(0.5, -200, 0, topOffset + 55)
	end

	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateSafeArea)
	end
end

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.new(1, -20, 0.5, 0)
resultLabel.Position = UDim2.new(0, 10, 0, 2)
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.TextScaled = true
resultLabel.TextXAlignment = Enum.TextXAlignment.Center
resultLabel.Font = Enum.Font.GothamBold
resultLabel.Parent = resultBox

local coinResult = Instance.new("TextLabel")
coinResult.Name = "CoinResult"
coinResult.Size = UDim2.new(1, -20, 0.5, 0)
coinResult.Position = UDim2.new(0, 10, 0.5, 0)
coinResult.BackgroundTransparency = 1
coinResult.TextColor3 = Color3.fromRGB(255, 200, 50)
coinResult.TextScaled = true
coinResult.TextXAlignment = Enum.TextXAlignment.Center
coinResult.Font = Enum.Font.GothamBold
coinResult.Text = ""
coinResult.Parent = resultBox

Remotes.RoundTimerTick.OnClientEvent:Connect(function(seconds, phase)
	screenGui.Enabled = true
	resultBox.Visible = false

	currentPhase = phase
	if phase == "search" then
		timerLabel.Text = seconds
	elseif phase == "goingUp" then
		timerLabel.Text = seconds
	elseif phase == "explore" then
		timerLabel.Text = seconds
	elseif phase == "intermission" then
		timerLabel.Text = seconds
	elseif phase == "reveal" then
		timerLabel.Text = seconds
	elseif phase == "boarding" then
		timerLabel.Text = seconds
	else
		timerLabel.Text = ""
	end
end)

Remotes.RoundStart.OnClientEvent:Connect(function()
	screenGui.Enabled = false
end)

Remotes.RevealResults.OnClientEvent:Connect(function(results)
	resultBox.Visible = true
	if results and #results > 0 then
		local r = results[1]
		resultLabel.Text = r.name .. ": " .. r.points .. " pts"
		if r.coins and r.coins > 0 then
			coinResult.Text = "+" .. r.coins .. " coins"
		else
			coinResult.Text = ""
		end
	end
end)

-- Live coin display from leaderstats
local function updateCoinFromLeaderstats()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Coins")
		if c then
			coinLabel.Text = tostring(c.Value)
		end
	end
end
local function watchLeaderstats()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.ChildAdded:Connect(function(child)
			if child.Name == "Coins" then
				child:GetPropertyChangedSignal("Value"):Connect(updateCoinFromLeaderstats)
				updateCoinFromLeaderstats()
			end
		end)
		local c = ls:FindFirstChild("Coins")
		if c then
			c:GetPropertyChangedSignal("Value"):Connect(updateCoinFromLeaderstats)
			updateCoinFromLeaderstats()
		end
	end
end
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		watchLeaderstats()
	end
end)
watchLeaderstats()

-- End game
Remotes.RoundEnd.OnClientEvent:Connect(function()
	screenGui.Enabled = false
end)