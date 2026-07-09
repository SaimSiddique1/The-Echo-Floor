local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Remotes = ReplicatedStorage.Remotes
local AnomalyConfig = require(ReplicatedStorage.Shared.AnomalySwapConfig)

local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TimerHUD"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.DisplayOrder = 10
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local topOffset = 10
local safeAreaTop = 0
if isMobile then
	local ok, safe = pcall(function()
		return GuiService:GetSafeAreaInsets()
	end)
	if ok and safe then
		safeAreaTop = safe.Top
		topOffset = safeAreaTop + 10
	end
end

if isMobile then
	local uiscale = Instance.new("UIScale")
	uiscale.Parent = screenGui
end

-- Timer box (top-left)
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

-- Fixed minimap — stationary rooms, player dot moves around
local MAP_SCALE = isMobile and 2.2 or 1.2
local MAP_W = isMobile and 380 or 205
local MAP_H = isMobile and 220 or 115
local MAP_RX = MAP_W / 2
local MAP_RY = MAP_H / 2

local minimap = Instance.new("Frame")
minimap.Name = "Minimap"
minimap.Size = UDim2.new(0, MAP_W, 0, MAP_H)
minimap.Position = UDim2.new(0, 10, 0, topOffset + 44)
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

-- Static room cells, offset so minimap center ≈ world (0,0)
-- Room (wx, wz) → minimap pos: 90° clockwise (cx = R + z*S, cy = R - x*S)
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

-- Moving player dot
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

-- Direction indicator (rotates with player)
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

	-- Position dot: 90° CW mapping (z→x, -x→y)
	local dx = pz * MAP_SCALE
	local dy = -px * MAP_SCALE
	playerDot.Position = UDim2.new(0, MAP_RX + dx - 3, 0, MAP_RY + dy - 3)

	-- Rotate arrow: facing direction adjusted for 90° CW
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

_G.setAnomalyPing = function(roomName, duration)
	pingTargetRoom = roomName
	pingEndTime = os.clock() + (duration or 5)
end

-- Phase box (top-center)
local phaseBox = Instance.new("Frame")
phaseBox.Name = "PhaseBox"
phaseBox.Size = UDim2.new(0, 300, 0, 40)
phaseBox.Position = UDim2.new(0.5, -150, 0, topOffset)
phaseBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
phaseBox.BackgroundTransparency = 0.4
phaseBox.BorderSizePixel = 0
phaseBox.Parent = screenGui

local phaseLabel = Instance.new("TextLabel")
phaseLabel.Name = "PhaseLabel"
phaseLabel.Size = UDim2.new(1, 0, 1, 0)
phaseLabel.BackgroundTransparency = 1
phaseLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
phaseLabel.TextScaled = true
phaseLabel.TextXAlignment = Enum.TextXAlignment.Center
phaseLabel.Font = Enum.Font.Gotham
phaseLabel.Text = ""
phaseLabel.Parent = phaseBox

-- Coin HUD (separate always-on ScreenGui, visible in lobby and rounds)
local coinGui = Instance.new("ScreenGui")
coinGui.Name = "CoinHUD"
coinGui.ResetOnSpawn = false
coinGui.DisplayOrder = 10
coinGui.Parent = playerGui

if isMobile then
	coinGui.IgnoreGuiInset = true
end

local coinHUD = Instance.new("Frame")
coinHUD.Name = "CoinHUD"
coinHUD.Size = UDim2.new(0, 150, 0, 34)
coinHUD.Position = UDim2.new(1, -160, 0, topOffset)
coinHUD.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
coinHUD.BackgroundTransparency = 0.4
coinHUD.BorderSizePixel = 0
coinHUD.Parent = coinGui

local coinIcon = Instance.new("Frame")
coinIcon.Name = "CoinIcon"
coinIcon.Size = UDim2.new(0, 22, 0, 22)
coinIcon.Position = UDim2.new(0, 6, 0.5, -11)
coinIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
coinIcon.BorderSizePixel = 0
coinIcon.Parent = coinHUD

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(1, 0)
coinCorner.Parent = coinIcon

local coinSymbol = Instance.new("TextLabel")
coinSymbol.Name = "CoinSymbol"
coinSymbol.Size = UDim2.new(1, 0, 1, 0)
coinSymbol.BackgroundTransparency = 1
coinSymbol.Text = "$"
coinSymbol.TextColor3 = Color3.fromRGB(180, 120, 30)
coinSymbol.TextScaled = true
coinSymbol.Font = Enum.Font.GothamBold
coinSymbol.Parent = coinIcon

local coinCount = Instance.new("TextLabel")
coinCount.Name = "CoinCount"
coinCount.Size = UDim2.new(1, -34, 1, 0)
coinCount.Position = UDim2.new(0, 34, 0, 0)
coinCount.BackgroundTransparency = 1
coinCount.TextColor3 = Color3.fromRGB(255, 220, 50)
coinCount.TextScaled = true
coinCount.TextXAlignment = Enum.TextXAlignment.Left
coinCount.Font = Enum.Font.GothamBold
coinCount.Text = "0"
coinCount.Parent = coinHUD

-- Update coin count from leaderstats
local function updateCoinDisplay()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local coinsVal = ls:FindFirstChild("Coins")
		if coinsVal then
			coinCount.Text = tostring(coinsVal.Value)
		end
	end
end
local function setupCoinWatcher()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.ChildAdded:Connect(function(child)
			if child.Name == "Coins" then
				child:GetPropertyChangedSignal("Value"):Connect(updateCoinDisplay)
				updateCoinDisplay()
			end
		end)
		local coinsVal = ls:FindFirstChild("Coins")
		if coinsVal then
			coinsVal:GetPropertyChangedSignal("Value"):Connect(updateCoinDisplay)
			updateCoinDisplay()
		end
	end
end
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		setupCoinWatcher()
	end
end)
setupCoinWatcher()



-- Personal result label (centered below phase box, visible during reveal)
local resultBox = Instance.new("Frame")
resultBox.Name = "ResultBox"
resultBox.Size = UDim2.new(0, 400, 0, 70)
resultBox.Position = UDim2.new(0.5, -200, 0, topOffset + 55)
resultBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
resultBox.BackgroundTransparency = 0.4
resultBox.BorderSizePixel = 0
resultBox.Visible = false
resultBox.Parent = screenGui

-- Mobile: UIScale + safe area updates
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
		local ok, s = pcall(function()
			return GuiService:GetSafeAreaInsets()
		end)
		if ok and s then
			topOffset = s.Top + 10
			timerBox.Position = UDim2.new(0, 10, 0, topOffset)
			minimap.Position = UDim2.new(0, 10, 0, topOffset + 44)
		end

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
resultLabel.Text = ""
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
	if phase == "explore" then
		timerLabel.Text = tostring(seconds)
		timerLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		phaseLabel.Text = "Explore the floor"
	elseif phase == "goingUp" then
		timerLabel.Text = tostring(seconds)
		timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
		phaseLabel.Text = "GOING UP"
	elseif phase == "search" then
		timerLabel.Text = tostring(seconds)
		phaseLabel.Text = "Find the Anomaly"
		if seconds <= 10 then
			timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		else
			timerLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
		end
	elseif phase == "intermission" then
		timerLabel.Text = tostring(seconds)
		timerLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
		phaseLabel.Text = "Waiting for results"
	elseif phase == "boarding" then
		timerLabel.Text = tostring(seconds)
		timerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		phaseLabel.Text = "Board the elevator"
	end
end)

Remotes.RoundStart.OnClientEvent:Connect(function()
	timerLabel.Text = ""
	phaseLabel.Text = ""
	screenGui.Enabled = false
end)

local answerRightSound = Instance.new("Sound")
answerRightSound.Name = "AnswerRight"
answerRightSound.SoundId = "rbxassetid://3450794184"
answerRightSound.Volume = 0.5
answerRightSound.Parent = screenGui

local errorSound = Instance.new("Sound")
errorSound.Name = "ErrorSound"
errorSound.SoundId = "rbxassetid://550209561"
errorSound.Volume = 0.5
errorSound.Parent = screenGui

Remotes.RevealResults.OnClientEvent:Connect(function(results)
	screenGui.Enabled = true
	timerLabel.Text = "ROUND OVER"
	timerLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	phaseLabel.Text = "Results"

	for _, r in ipairs(results) do
		if r.name == player.Name then
			local coinStr = (r.coins and r.coins > 0) and "● +" .. r.coins or ""
			if r.correct then
				local bonusStr = r.bonus and r.bonus > 0 and " (+" .. r.bonus .. " speed)" or ""
				resultLabel.Text = "CORRECT! +" .. r.points .. bonusStr
				resultLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
				coinResult.Text = coinStr
				answerRightSound:Play()
			elseif r.noAnomaly then
				resultLabel.Text = "No Anomaly — Correct! +" .. r.points
				resultLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
				coinResult.Text = coinStr
				answerRightSound:Play()
			elseif r.abstained then
				resultLabel.Text = "You didn't guess"
				resultLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
				coinResult.Text = ""
				errorSound:Play()
			else
				resultLabel.Text = "WRONG! " .. r.points
				resultLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				coinResult.Text = coinStr
				errorSound:Play()
			end
			resultBox.Visible = true
			break
		end
	end
end)

Remotes.FloorReset.OnClientEvent:Connect(function()
	screenGui.Enabled = false
	timerLabel.Text = ""
	phaseLabel.Text = ""
	resultBox.Visible = false
	resultLabel.Text = ""
	coinResult.Text = ""
end)


