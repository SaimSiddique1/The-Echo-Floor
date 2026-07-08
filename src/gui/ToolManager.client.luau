local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local UserInputService = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local currentPhase = ""
local searchResetDone = false

local ROOMS = { "Panic", "Hallway", "LivingRoom", "Kitchen", "Bedroom", "Bathroom" }
local CATEGORIES = { "Object", "Lighting", "Architecture", "Audio", "Paranormal" }

local barGui
local selGui
local hasGuessed = false
local selectedRoom = nil
local selectedCategory = nil
local toolConnections = {}

local roomSelectionLabel
local typeSelectionLabel

local function detectRegion(target, hitPoint)
	local floor = workspace:FindFirstChild("Floor")
	if not floor then return nil end
	local regions = floor:FindFirstChild("Regions")
	if regions then
		for _, v in regions:GetChildren() do
			if v:IsA("BasePart") then
				local rel = v.CFrame:PointToObjectSpace(hitPoint or target.Position)
				if math.abs(rel.X) <= v.Size.X / 2 and math.abs(rel.Z) <= v.Size.Z / 2 then
					return v.Name
				end
			end
		end
	end
	local roomBounds = require(ReplicatedStorage.Shared.AnomalySwapConfig).roomBounds
	local pos = hitPoint or target.Position
	for name, b in pairs(roomBounds) do
		if pos.X >= b.xMin and pos.X <= b.xMax and pos.Z >= b.zMin and pos.Z <= b.zMax then
			return name
		end
	end
	return nil
end

local function updateSelectionLabels()
	if roomSelectionLabel then
		roomSelectionLabel.Text = selectedRoom and ("Room: " .. selectedRoom) or "Room: None"
	end
	if typeSelectionLabel then
		typeSelectionLabel.Text = selectedCategory and ("Type: " .. selectedCategory) or "Type: None"
	end
	if barGui then
		local combo = barGui:FindFirstChild("SelectionCombo")
		if combo then
			local room = selectedRoom
			local cat = selectedCategory
			if not room and not cat then
				combo.Text = ""
			elseif room == "Panic" then
				combo.Text = "Panic  —  All is Wrong"
			else
				combo.Text = (room or "—") .. "  |  " .. (cat or "—")
			end
		end
	end
end

local function closeBar()
	if barGui then barGui.Enabled = false end
	selectedRoom = nil
	selectedCategory = nil
	updateSelectionLabels()
end

local function submitGuess()
	if not selectedRoom or not selectedCategory then return end
	hasGuessed = true
	Remotes.LogGuess:FireServer({ region = selectedRoom, category = selectedCategory })
	closeBar()
end

local function buildBars()
	if barGui then barGui:Destroy() end

	barGui = Instance.new("ScreenGui")
	barGui.Name = "AnomalyBar"
	barGui.ResetOnSpawn = false
	barGui.Enabled = false
	barGui.Parent = playerGui
	if isMobile then barGui.IgnoreGuiInset = true end

	-- click sound removed

	local bottomInset = 0
	if isMobile then
		local safe = UserInputService:GetSafeAreaInsets()
		bottomInset = safe.Bottom
	end

	local BTN_W = isMobile and 120 or 88
	local BTN_H = isMobile and 44 or 34
	local LABEL_W = 44
	local GAP = 4
	local BAR_PAD = 8
	local BAR_H = isMobile and 50 or 40

	local roomButtons = {}
	local categoryButtons = {}
	local lockInBtn
	local panicLabel

	local leftBar = Instance.new("Frame")
	leftBar.Name = "LeftBar"
	leftBar.Size = UDim2.new(0, LABEL_W + GAP + #ROOMS * (BTN_W + GAP), 0, BAR_H)
	leftBar.Position = UDim2.new(0, 8, 1, -(bottomInset + BAR_H + 30))
	leftBar.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	leftBar.BackgroundTransparency = 0.08
	leftBar.BorderSizePixel = 0
	leftBar.Parent = barGui

	local leftBarCorner = Instance.new("UICorner")
	leftBarCorner.CornerRadius = UDim.new(0, 8)
	leftBarCorner.Parent = leftBar

	local roomLabel = Instance.new("TextLabel")
	roomLabel.Size = UDim2.new(0, LABEL_W, 0, BTN_H)
	roomLabel.Position = UDim2.new(0, BAR_PAD, 0.5, -BTN_H / 2)
	roomLabel.BackgroundTransparency = 1
	roomLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	roomLabel.TextScaled = true
	roomLabel.Font = Enum.Font.GothamBold
	roomLabel.TextXAlignment = Enum.TextXAlignment.Center
	roomLabel.Text = "ROOM"
	roomLabel.Parent = leftBar

	local roomStartX = BAR_PAD + LABEL_W + GAP
	for i, r in ipairs(ROOMS) do
		local pb = Instance.new("TextButton")
		pb.Name = "RoomBtn_" .. r
		pb.Size = UDim2.new(0, BTN_W, 0, BTN_H)
		pb.Position = UDim2.new(0, roomStartX + (i - 1) * (BTN_W + GAP), 0.5, -BTN_H / 2)
		pb.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
		pb.BackgroundTransparency = 0.3
		pb.BorderSizePixel = 0
		pb.TextColor3 = Color3.fromRGB(200, 200, 200)
		pb.TextScaled = true
		pb.Font = Enum.Font.Gotham
		pb.Text = r
		pb.Parent = leftBar

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = pb

		pb.MouseButton1Click:Connect(function()
			if selectedRoom == r then return end
			for _, ob in ipairs(roomButtons) do
				ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
				ob.BorderSizePixel = 0
			end
			pb.BackgroundColor3 = Color3.fromRGB(50, 80, 160)
			pb.BorderSizePixel = 1
			pb.BorderColor3 = Color3.fromRGB(80, 140, 255)
			selectedRoom = r

			if r == "Panic" then
				selectedCategory = "Panic"
				lockInBtn.Visible = true
				panicLabel.Visible = true
				for _, ob in ipairs(categoryButtons) do
					ob.Visible = false
				end
			else
				selectedCategory = nil
				lockInBtn.Visible = false
				panicLabel.Visible = false
				for _, ob in ipairs(categoryButtons) do
					ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
					ob.BorderSizePixel = 0
					ob.Visible = true
				end
			end
			updateSelectionLabels()
		end)
		table.insert(roomButtons, pb)
	end

	local totalCatW = LABEL_W + GAP + #CATEGORIES * (BTN_W + GAP)

	local rightBar = Instance.new("Frame")
	rightBar.Name = "RightBar"
	rightBar.Size = UDim2.new(0, totalCatW, 0, BAR_H)
	rightBar.Position = UDim2.new(1, -(8 + totalCatW), 1, -(bottomInset + BAR_H + 30))
	rightBar.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	rightBar.BackgroundTransparency = 0.08
	rightBar.BorderSizePixel = 0
	rightBar.Parent = barGui

	local rightBarCorner = Instance.new("UICorner")
	rightBarCorner.CornerRadius = UDim.new(0, 8)
	rightBarCorner.Parent = rightBar

	local catLabel = Instance.new("TextLabel")
	catLabel.Size = UDim2.new(0, LABEL_W, 0, BTN_H)
	catLabel.Position = UDim2.new(0, BAR_PAD, 0.5, -BTN_H / 2)
	catLabel.BackgroundTransparency = 1
	catLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	catLabel.TextScaled = true
	catLabel.Font = Enum.Font.GothamBold
	catLabel.TextXAlignment = Enum.TextXAlignment.Center
	catLabel.Text = "TYPE"
	catLabel.Parent = rightBar

	local typeStartX = BAR_PAD + LABEL_W + GAP

	panicLabel = Instance.new("TextLabel")
	panicLabel.Name = "PanicLabel"
	panicLabel.Size = UDim2.new(0, totalCatW - LABEL_W - GAP - BAR_PAD, 0, BTN_H)
	panicLabel.Position = UDim2.new(0, typeStartX, 0.5, -BTN_H / 2)
	panicLabel.BackgroundTransparency = 1
	panicLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	panicLabel.TextScaled = true
	panicLabel.Font = Enum.Font.GothamBold
	panicLabel.Text = "All is Wrong"
	panicLabel.Visible = false
	panicLabel.Parent = rightBar

	for i, c in ipairs(CATEGORIES) do
		local pb = Instance.new("TextButton")
		pb.Name = "CatBtn_" .. c
		pb.Size = UDim2.new(0, BTN_W, 0, BTN_H)
		pb.Position = UDim2.new(0, typeStartX + (i - 1) * (BTN_W + GAP), 0.5, -BTN_H / 2)
		pb.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
		pb.BackgroundTransparency = 0.3
		pb.BorderSizePixel = 0
		pb.TextColor3 = Color3.fromRGB(200, 200, 200)
		pb.TextScaled = true
		pb.Font = Enum.Font.Gotham
		pb.Text = c
		pb.Parent = rightBar

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = pb

		pb.MouseButton1Click:Connect(function()
			if selectedCategory == c then return end
			for _, ob in ipairs(categoryButtons) do
				ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
				ob.BorderSizePixel = 0
			end
			pb.BackgroundColor3 = Color3.fromRGB(50, 130, 50)
			pb.BorderSizePixel = 1
			pb.BorderColor3 = Color3.fromRGB(80, 255, 80)
			selectedCategory = c
			lockInBtn.Visible = selectedRoom ~= nil
			updateSelectionLabels()
		end)
		table.insert(categoryButtons, pb)
	end

	local LOCK_W = isMobile and 140 or 100
	local LOCK_H = isMobile and 44 or 34
	lockInBtn = Instance.new("TextButton")
	lockInBtn.Name = "LockInBtn"
	lockInBtn.Size = UDim2.new(0, LOCK_W, 0, LOCK_H)
	lockInBtn.Position = UDim2.new(0.5, -LOCK_W / 2, 1, -(bottomInset + BAR_H + 60 + 8 + LOCK_H))
	lockInBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
	lockInBtn.BorderSizePixel = 0
	lockInBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockInBtn.TextScaled = true
	lockInBtn.Font = Enum.Font.GothamBold
	lockInBtn.Text = "Lock In"
	lockInBtn.Visible = false
	lockInBtn.Parent = barGui

	local lockCorner = Instance.new("UICorner")
	lockCorner.CornerRadius = UDim.new(0, 6)
	lockCorner.Parent = lockInBtn

	lockInBtn.MouseButton1Click:Connect(submitGuess)

	local combo = Instance.new("TextLabel")
	combo.Name = "SelectionCombo"
	combo.Size = UDim2.new(0, 300, 0, isMobile and 22 or 16)
	combo.Position = UDim2.new(0.5, -150, 1, -(bottomInset + BAR_H + 30 + 8 + LOCK_H + 4 + (isMobile and 22 or 16)))
	combo.BackgroundTransparency = 1
	combo.TextColor3 = Color3.fromRGB(200, 200, 200)
	combo.TextScaled = true
	combo.Font = Enum.Font.GothamBold
	combo.TextXAlignment = Enum.TextXAlignment.Center
	combo.Text = ""
	combo.Parent = barGui

end

local function showBars()
	if not barGui then buildBars() end
	barGui.Enabled = true
	selectedRoom = nil
	selectedCategory = nil
	hasGuessed = false
	if barGui.LeftBar then
		for _, ob in ipairs(barGui.LeftBar:GetChildren()) do
			if ob:IsA("TextButton") then
				ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
				ob.BorderSizePixel = 0
			end
		end
	end
	if barGui.RightBar then
		for _, ob in ipairs(barGui.RightBar:GetChildren()) do
			if ob:IsA("TextButton") then
				ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
				ob.BorderSizePixel = 0
			end
		end
		local pl = barGui.RightBar:FindFirstChild("PanicLabel")
		if pl then pl.Visible = false end
	end
	updateSelectionLabels()
end

local function handleTool(tool)
	if not tool then return end
	if tool.Name ~= "Anomaly Tool" then return end

	local con
	con = tool.Equipped:Connect(function()
		if currentPhase ~= "search" then return end
		if hasGuessed then return end
		showBars()
	end)
	table.insert(toolConnections, con)

	local decon
	decon = tool.Deactivated:Connect(function()
		if barGui then barGui.Enabled = false end
	end)
	table.insert(toolConnections, decon)
end

player.Backpack.ChildAdded:Connect(function(tool)
	task.spawn(handleTool, tool)
end)
for _, v in player.Backpack:GetChildren() do
	if v:IsA("Tool") then
		task.spawn(handleTool, v)
	end
end

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
	if barGui and barGui.Enabled then
		local char = player.Character
		local hasTool = false
		if char then
			local tool = char:FindFirstChildOfClass("Tool")
			if tool and tool.Name == "Anomaly Tool" then
				hasTool = true
			end
		end
		if not hasTool then
			barGui.Enabled = false
		end
	end
end)

-- Build persistent selection labels (separate from barGui)
local function buildSelectionLabels()
	if selGui then selGui:Destroy() end

	selGui = Instance.new("ScreenGui")
	selGui.Name = "SelectionLabels"
	selGui.ResetOnSpawn = false
	selGui.Enabled = false
	selGui.Parent = playerGui
	if isMobile then selGui.IgnoreGuiInset = true end

	local SEL_H = isMobile and 32 or 28
	local PAD = 2
	local BW = 180

	local leftBox = Instance.new("Frame")
	leftBox.Name = "LeftBox"
	leftBox.Size = UDim2.new(0, BW + PAD * 2, 0, SEL_H + PAD * 2)
	leftBox.Position = UDim2.new(0, 8, 1, -(SEL_H + PAD * 2 + 4))
	leftBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	leftBox.BackgroundTransparency = 0.5
	leftBox.BorderSizePixel = 0
	leftBox.Parent = selGui

	local leftBoxCorner = Instance.new("UICorner")
	leftBoxCorner.CornerRadius = UDim.new(0, 4)
	leftBoxCorner.Parent = leftBox

	roomSelectionLabel = Instance.new("TextLabel")
	roomSelectionLabel.Name = "RoomSelectionLabel"
	roomSelectionLabel.Size = UDim2.new(0, BW + PAD, 0, SEL_H)
	roomSelectionLabel.Position = UDim2.new(0, PAD, 0, PAD)
	roomSelectionLabel.BackgroundTransparency = 1
	roomSelectionLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	roomSelectionLabel.TextScaled = true
	roomSelectionLabel.Font = Enum.Font.GothamBold
	roomSelectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	roomSelectionLabel.Text = "Room: None"
	roomSelectionLabel.Parent = leftBox

	local rightBox = Instance.new("Frame")
	rightBox.Name = "RightBox"
	rightBox.Size = UDim2.new(0, BW + PAD * 2, 0, SEL_H + PAD * 2)
	rightBox.Position = UDim2.new(1, -(8 + BW + PAD * 2), 1, -(SEL_H + PAD * 2 + 4))
	rightBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	rightBox.BackgroundTransparency = 0.5
	rightBox.BorderSizePixel = 0
	rightBox.Parent = selGui

	local rightBoxCorner = Instance.new("UICorner")
	rightBoxCorner.CornerRadius = UDim.new(0, 4)
	rightBoxCorner.Parent = rightBox

	typeSelectionLabel = Instance.new("TextLabel")
	typeSelectionLabel.Name = "TypeSelectionLabel"
	typeSelectionLabel.Size = UDim2.new(0, BW + PAD, 0, SEL_H)
	typeSelectionLabel.Position = UDim2.new(0, 0, 0, PAD)
	typeSelectionLabel.BackgroundTransparency = 1
	typeSelectionLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	typeSelectionLabel.TextScaled = true
	typeSelectionLabel.Font = Enum.Font.GothamBold
	typeSelectionLabel.TextXAlignment = Enum.TextXAlignment.Right
	typeSelectionLabel.Text = "Type: None"
	typeSelectionLabel.Parent = rightBox
end

buildSelectionLabels()

Remotes.RoundTimerTick.OnClientEvent:Connect(function(seconds, phase)
	currentPhase = phase
	if phase == "search" then
		if selGui then
			selGui.Enabled = true
			if not searchResetDone then
				selectedRoom = nil
				selectedCategory = nil
				updateSelectionLabels()
				searchResetDone = true
			end
		end
	else
		if selGui then selGui.Enabled = false end
		if barGui then barGui.Enabled = false end
		searchResetDone = false
	end
end)

Remotes.FloorReset.OnClientEvent:Connect(function()
	if barGui then barGui.Enabled = false end
	if selGui then selGui.Enabled = false end
	hasGuessed = false
	selectedRoom = nil
	selectedCategory = nil
	searchResetDone = false
end)