local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local currentPhase = ""

local ROOMS = { "Panic", "Hallway", "LivingRoom", "Kitchen", "Bedroom", "Bathroom" }
local CATEGORIES = { "Object", "Lighting", "Architecture", "Audio", "Paranormal" }

local guessGui
local selectionGui
local typeLabel
local roomSelectLabel
local hasGuessed = false
local currentGuess = ""
local toolConnections = {}
local selectionEnabled = false

local function addUIScale(gui)
	local uiscale = Instance.new("UIScale")
	uiscale.Name = "UIScale"
	uiscale.Parent = gui
end

local function detectRegion(target, hitPoint)
	local floor = workspace:FindFirstChild("Floor")
	if not floor then return nil end
	local regions = floor:FindFirstChild("Regions")
	if regions then
		for _, v in regions:GetChildren() do
			if v:IsA("BasePart") and v.CFrame:PointToObjectSpace(hitPoint or target.Position).Y >= 0 then
				local inside = false
				if v.Size.X > 0 and v.Size.Z > 0 then
					local rel = v.CFrame:PointToObjectSpace(hitPoint or target.Position)
					if math.abs(rel.X) <= v.Size.X / 2 and math.abs(rel.Z) <= v.Size.Z / 2 then
						inside = true
					end
				end
				if inside then
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

local function resetCategorySelection()
	selectedCategory = nil
	if lockInBtn then lockInBtn.Visible = false end
	if panicLabel then panicLabel.Visible = false end
	if categoryButtons then
		for _, ob in ipairs(categoryButtons) do
			ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
			ob.BorderSizePixel = 0
			ob:SetAttribute("Selected", false)
			ob.Visible = true
		end
	end
end

local function closeSelection()
	selectionGui.Enabled = false
	selectedRoom = nil
	selectedCategory = nil
	if lockInBtn then lockInBtn.Visible = false end
	if panicLabel then panicLabel.Visible = false end
	if roomButtons then
		for _, ob in ipairs(roomButtons) do
			ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
			ob.BorderSizePixel = 0
			ob:SetAttribute("Selected", false)
		end
	end
	if categoryButtons then
		for _, ob in ipairs(categoryButtons) do
			ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
			ob.BorderSizePixel = 0
			ob:SetAttribute("Selected", false)
			ob.Visible = true
		end
	end
end

local function submitGuess()
	if not selectedRoom or not selectedCategory then return end
	hasGuessed = true
	currentGuess = selectedRoom .. " · " .. selectedCategory
	Remotes.LogGuess:FireServer({ region = selectedRoom, category = selectedCategory })
	closeSelection()
	clickSound:Play()
end

local function buildGuessUI()
	if guessGui then
		guessGui:Destroy()
	end
	guessGui = Instance.new("ScreenGui")
	guessGui.Name = "GuessGUI"
	guessGui.ResetOnSpawn = false
	guessGui.Enabled = false
	guessGui.Parent = playerGui
	if isMobile then
		guessGui.IgnoreGuiInset = true
	end
	addUIScale(guessGui)

	local bottomInset = 0
	if isMobile then
		local safe = UserInputService:GetSafeAreaInsets()
		bottomInset = safe.Bottom
	end

	local clickSound = Instance.new("Sound")
	clickSound.SoundId = "rbxasset://sounds/UI/click-forward.wav"
	clickSound.Volume = 0.5
	clickSound.Parent = guessGui

	-- Top label: detected region
	roomSelectLabel = Instance.new("TextLabel")
	roomSelectLabel.Name = "RoomSelectLabel"
	roomSelectLabel.Size = UDim2.new(0, 200, 0, 36)
	roomSelectLabel.Position = UDim2.new(0, 15, 1, -55)
	roomSelectLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	roomSelectLabel.BackgroundTransparency = 0.4
	roomSelectLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	roomSelectLabel.TextScaled = true
	roomSelectLabel.TextXAlignment = Enum.TextXAlignment.Center
	roomSelectLabel.Font = Enum.Font.Gotham
	roomSelectLabel.Text = "Room: None"
	roomSelectLabel.Parent = guessGui

	typeLabel = Instance.new("TextLabel")
	typeLabel.Name = "TypeLabel"
	typeLabel.Size = UDim2.new(0, 200, 0, 36)
	typeLabel.Position = UDim2.new(0, 15, 1, -90)
	typeLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	typeLabel.BackgroundTransparency = 0.4
	typeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	typeLabel.TextScaled = true
	typeLabel.TextXAlignment = Enum.TextXAlignment.Center
	typeLabel.Font = Enum.Font.Gotham
	typeLabel.Text = "Type: None"
	typeLabel.Parent = guessGui

	-- Selection HUD (horizontal bars left+right of hotbar)
	selectionGui = Instance.new("ScreenGui")
	selectionGui.Name = "SelectionHUD"
	selectionGui.ResetOnSpawn = false
	selectionGui.Enabled = false
	selectionGui.Parent = playerGui
	if isMobile then
		selectionGui.IgnoreGuiInset = true
	end
	addUIScale(selectionGui)

	local BAR_H = isMobile and 50 or 40
	local BTN_W = isMobile and 120 or 88
	local BTN_H = isMobile and 44 or 34
	local LABEL_W = 44
	local GAP = isMobile and 6 or 4
	local Y_OFFSET = BAR_H + 18

	selectedRoom = nil
	selectedCategory = nil

	local roomButtons = {}
	local categoryButtons = {}
	local lockInBtn
	local roomStartX = 8 + LABEL_W + GAP

	-- Left bar (rooms)
	local leftBar = Instance.new("Frame")
	leftBar.Name = "LeftBar"
	leftBar.Size = UDim2.new(0, 10, 0, BAR_H)
	leftBar.Position = UDim2.new(0, 8, 1, -(bottomInset + BAR_H + Y_OFFSET))
	leftBar.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	leftBar.BackgroundTransparency = 0.08
	leftBar.BorderSizePixel = 0
	leftBar.Parent = selectionGui

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 8)
	barCorner.Parent = leftBar

	local roomLabel = Instance.new("TextLabel")
	roomLabel.Name = "RoomLabel"
	roomLabel.Size = UDim2.new(0, LABEL_W, 0, BTN_H)
	roomLabel.Position = UDim2.new(0, 8, 0.5, -BTN_H / 2)
	roomLabel.BackgroundTransparency = 1
	roomLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	roomLabel.TextScaled = true
	roomLabel.Font = Enum.Font.GothamBold
	roomLabel.TextXAlignment = Enum.TextXAlignment.Center
	roomLabel.Text = "ROOM"
	roomLabel.Parent = leftBar

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
		pb.TextXAlignment = Enum.TextXAlignment.Center
		pb.Text = r
		pb.Parent = leftBar
		pb:SetAttribute("Selected", false)

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = pb

		pb.MouseButton1Click:Connect(function()
			if selectedRoom == r then return end
			for _, ob in ipairs(roomButtons) do
				ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
				ob.BorderSizePixel = 0
				ob:SetAttribute("Selected", false)
			end
			pb.BackgroundColor3 = Color3.fromRGB(50, 80, 160)
			pb.BorderSizePixel = 1
			pb.BorderColor3 = Color3.fromRGB(80, 140, 255)
			pb:SetAttribute("Selected", true)
			selectedRoom = r
			roomSelectLabel.Text = "Room: " .. r
			if r == "Panic" then
				selectedCategory = "Panic"
				typeLabel.Text = "Type: All is Wrong"
				lockInBtn.Visible = true
				if panicLabel then
					panicLabel.Visible = true
				end
				if categoryButtons then
					for _, ob in ipairs(categoryButtons) do
						ob.Visible = false
					end
				end
			else
				resetCategorySelection()
			end
		end)
		table.insert(roomButtons, pb)
	end

	-- Right bar (categories + cancel)
	local rightBar = Instance.new("Frame")
	rightBar.Name = "RightBar"
	rightBar.Size = UDim2.new(0, 10, 0, BAR_H)
	rightBar.Position = UDim2.new(1, -18, 1, -(bottomInset + BAR_H + Y_OFFSET))
	rightBar.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	rightBar.BackgroundTransparency = 0.08
	rightBar.BorderSizePixel = 0
	rightBar.Parent = selectionGui

	local barCorner2 = Instance.new("UICorner")
	barCorner2.CornerRadius = UDim.new(0, 8)
	barCorner2.Parent = rightBar

	local catLabel = Instance.new("TextLabel")
	catLabel.Name = "CatLabel"
	catLabel.Size = UDim2.new(0, LABEL_W, 0, BTN_H)
	catLabel.Position = UDim2.new(0, 8, 0.5, -BTN_H / 2)
	catLabel.BackgroundTransparency = 1
	catLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	catLabel.TextScaled = true
	catLabel.Font = Enum.Font.GothamBold
	catLabel.TextXAlignment = Enum.TextXAlignment.Center
	catLabel.Text = "TYPE"
	catLabel.Parent = rightBar

	local panicLabel = Instance.new("TextLabel")
	panicLabel.Name = "PanicLabel"
	panicLabel.Size = UDim2.new(0, 160, 0, BTN_H)
	panicLabel.Position = UDim2.new(0, 8 + LABEL_W + GAP, 0.5, -BTN_H / 2)
	panicLabel.BackgroundTransparency = 1
	panicLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	panicLabel.TextScaled = true
	panicLabel.Font = Enum.Font.GothamBold
	panicLabel.TextXAlignment = Enum.TextXAlignment.Center
	panicLabel.Text = "All is Wrong"
	panicLabel.Visible = false
	panicLabel.Parent = rightBar

	categoryButtons = {}
	local catStartX = 8 + LABEL_W + GAP

	for i, c in ipairs(CATEGORIES) do
		local pb = Instance.new("TextButton")
		pb.Name = "CatBtn_" .. c
		pb.Size = UDim2.new(0, BTN_W, 0, BTN_H)
		pb.Position = UDim2.new(0, catStartX + (i - 1) * (BTN_W + GAP), 0.5, -BTN_H / 2)
		pb.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
		pb.BackgroundTransparency = 0.3
		pb.BorderSizePixel = 0
		pb.TextColor3 = Color3.fromRGB(200, 200, 200)
		pb.TextScaled = true
		pb.Font = Enum.Font.Gotham
		pb.TextXAlignment = Enum.TextXAlignment.Center
		pb.Text = c
		pb.Parent = rightBar
		pb:SetAttribute("Selected", false)

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = pb

		pb.MouseButton1Click:Connect(function()
			if selectedCategory == c then return end
			for _, ob in ipairs(categoryButtons) do
				ob.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
				ob.BorderSizePixel = 0
				ob:SetAttribute("Selected", false)
			end
			pb.BackgroundColor3 = Color3.fromRGB(50, 130, 50)
			pb.BorderSizePixel = 1
			pb.BorderColor3 = Color3.fromRGB(80, 255, 80)
			pb:SetAttribute("Selected", true)
			selectedCategory = c
			typeLabel.Text = "Type: " .. c
			lockInBtn.Visible = selectedRoom ~= nil
		end)
		table.insert(categoryButtons, pb)
	end

	-- Lock In button (below the left bar)
	local LOCK_W = isMobile and 140 or 100
	local LOCK_H = isMobile and 44 or 34
	lockInBtn = Instance.new("TextButton")
	lockInBtn.Name = "LockInBtn"
	lockInBtn.Size = UDim2.new(0, LOCK_W, 0, LOCK_H)
	lockInBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
	lockInBtn.BorderSizePixel = 0
	lockInBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockInBtn.TextScaled = true
	lockInBtn.Font = Enum.Font.GothamBold
	lockInBtn.TextXAlignment = Enum.TextXAlignment.Center
	lockInBtn.Text = "Lock In"
	lockInBtn.Visible = false
	lockInBtn.Parent = selectionGui

	local lockCorner = Instance.new("UICorner")
	lockCorner.CornerRadius = UDim.new(0, 6)
	lockCorner.Parent = lockInBtn

	lockInBtn.MouseButton1Click:Connect(submitGuess)

	return guessGui, selectionGui
end

local function enableSelection()
	if not guessGui then return end
	selectionGui.Enabled = true
	selectionEnabled = true
	hasGuessed = false
	selectedRoom = nil
	selectedCategory = nil
	roomSelectLabel.Text = "Room: None"
	typeLabel.Text = "Type: None"
	closeSelection()
	selectionGui.Enabled = true
end

local function disableSelection()
	if not guessGui then return end
	selectionGui.Enabled = false
	selectionEnabled = false
end

local function handleTool(tool)
	if not tool then return end
	if tool.Name ~= "Anomaly Scanner" then return end

	local con
	con = tool.Activated:Connect(function()
		if not selectionEnabled then return end
		if hasGuessed then return end
		if currentPhase ~= "search" then return end

		local target, hitPoint
		if isMobile then
			local camera = workspace.CurrentCamera
			local ray = camera:ScreenPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Blacklist
			params.FilterDescendantsInstances = { player.Character }
			local result = workspace:Raycast(ray.Origin, ray.Direction * 200, params)
			if result then
				target = result.Instance
				hitPoint = result.Position
			end
		else
			local mouse = player:GetMouse()
			target = mouse.Target
			hitPoint = mouse.Hit.Position
		end

		local regionName = detectRegion(target, hitPoint)
		if regionName then
			roomSelectLabel.Text = "Room: " .. regionName
		else
			roomSelectLabel.Text = "Unknown room"
		end

		if not selectionGui.Enabled then
			enableSelection()
		else
			selectionGui.Enabled = true
		end
	end)
	table.insert(toolConnections, con)
end

local function onToolAdded(tool)
	task.spawn(handleTool, tool)
end

player.Backpack.ChildAdded:Connect(onToolAdded)
for _, v in player.Backpack:GetChildren() do
	if v:IsA("Tool") then
		task.spawn(handleTool, v)
	end
end

Remotes.RoundTimerTick.OnClientEvent:Connect(function(seconds, phase)
	currentPhase = phase
	if phase == "search" then
		if not guessGui then
			buildGuessUI()
			enableSelection()
		else
			enableSelection()
		end
	elseif phase == "intermission" then
		disableSelection()
	elseif phase == "reveal" then
		disableSelection()
	else
		disableSelection()
	end
end)

Remotes.RoundStart.OnClientEvent:Connect(function()
	if not guessGui then
		buildGuessUI()
	end
	hasGuessed = false
	closeSelection()
end)

Remotes.RoundEnd.OnClientEvent:Connect(function()
	disableSelection()
	closeSelection()
end)

Remotes.FloorReset.OnClientEvent:Connect(function()
	disableSelection()
	closeSelection()
	hasGuessed = false
end)
