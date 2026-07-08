local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Remotes = ReplicatedStorage.Remotes
local CosmeticConfig = require(ReplicatedStorage.Shared.CosmeticConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled

local ECHO_PING_PRICE = 35

local COLORS = {
	bg = Color3.fromRGB(13, 13, 18),
	surface = Color3.fromRGB(22, 22, 30),
	card = Color3.fromRGB(26, 26, 36),
	cardHover = Color3.fromRGB(32, 32, 44),
	border = Color3.fromRGB(38, 38, 48),
	text = Color3.fromRGB(210, 210, 220),
	textDim = Color3.fromRGB(130, 130, 145),
	accent = Color3.fromRGB(59, 130, 246),
	green = Color3.fromRGB(34, 197, 94),
	greenBg = Color3.fromRGB(34, 197, 94),
	gold = Color3.fromRGB(255, 200, 50),
	red = Color3.fromRGB(220, 50, 50),
}

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

-- UIScale for mobile
if isMobile then
	screenGui.IgnoreGuiInset = true
	local uiscale = Instance.new("UIScale")
	uiscale.Parent = screenGui
	local function updateScale()
		local camera = Workspace.CurrentCamera
		if camera then
			local sz = camera.ViewportSize
			local s = math.min(sz.X / 1920, sz.Y / 1080)
			uiscale.Scale = math.clamp(s, 0.35, 1.8)
		end
	end
	updateScale()
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		updateScale()
		local cam = Workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		end
	end)
end

-- Overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.55
overlay.BorderSizePixel = 0
overlay.Parent = screenGui

overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		screenGui.Enabled = false
	end
end)

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 480, 0, 560)
panel.Position = UDim2.new(0.5, -240, 0.5, -280)
panel.BackgroundColor3 = COLORS.bg
panel.BorderSizePixel = 0
panel.Parent = screenGui

local function updatePanelSize()
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local sz = camera.ViewportSize
	local maxW = math.min(480, sz.X * (isMobile and 0.92 or 0.85))
	local maxH = math.min(560, sz.Y * (isMobile and 0.88 or 0.85))
	panel.Size = UDim2.new(0, maxW, 0, maxH)
	panel.Position = UDim2.new(0.5, -maxW / 2, 0.44, -maxH / 2)
end

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundColor3 = COLORS.surface
titleBar.BorderSizePixel = 0
titleBar.Parent = panel

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 14)
titleBarCorner.Parent = titleBar

local titleMask = Instance.new("Frame")
titleMask.Size = UDim2.new(1, 0, 0, 14)
titleMask.Position = UDim2.new(0, 0, 1, -14)
titleMask.BackgroundColor3 = COLORS.bg
titleMask.BorderSizePixel = 0
titleMask.Parent = titleBar

-- Title icon + text
local titleIcon = Instance.new("Frame")
titleIcon.Size = UDim2.new(0, 24, 0, 24)
titleIcon.Position = UDim2.new(0, 16, 0.5, -12)
titleIcon.BackgroundColor3 = COLORS.gold
titleIcon.BackgroundTransparency = 0.6
titleIcon.BorderSizePixel = 0
titleIcon.Parent = titleBar

local titleIconCorner = Instance.new("UICorner")
titleIconCorner.CornerRadius = UDim.new(0, 4)
titleIconCorner.Parent = titleIcon

local titleIconLabel = Instance.new("TextLabel")
titleIconLabel.Size = UDim2.new(1, 0, 1, 0)
titleIconLabel.BackgroundTransparency = 1
titleIconLabel.Text = "$"
titleIconLabel.TextColor3 = COLORS.gold
titleIconLabel.TextScaled = true
titleIconLabel.Font = Enum.Font.GothamBold
titleIconLabel.Parent = titleIcon

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 120, 1, 0)
titleLabel.Position = UDim2.new(0, 48, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "Shop"
titleLabel.Parent = titleBar

-- Coin pill in title bar
local coinPill = Instance.new("Frame")
coinPill.Size = UDim2.new(0, isMobile and 120 or 130, 0, 30)
coinPill.Position = UDim2.new(1, isMobile and -130 or -142, 0.5, -15)
coinPill.BackgroundColor3 = Color3.fromRGB(30, 25, 15)
coinPill.BorderSizePixel = 0
coinPill.Parent = titleBar

local coinPillCorner = Instance.new("UICorner")
coinPillCorner.CornerRadius = UDim.new(0, 8)
coinPillCorner.Parent = coinPill

local coinPillBorder = Instance.new("Frame")
coinPillBorder.Size = UDim2.new(1, 0, 1, 0)
coinPillBorder.BackgroundTransparency = 1
coinPillBorder.BorderSizePixel = 1
coinPillBorder.BorderColor3 = Color3.fromRGB(50, 40, 20)
coinPillBorder.Parent = coinPill

local coinPillBorderCorner = Instance.new("UICorner")
coinPillBorderCorner.CornerRadius = UDim.new(0, 8)
coinPillBorderCorner.Parent = coinPillBorder

local coinIcon = Instance.new("Frame")
coinIcon.Size = UDim2.new(0, 16, 0, 16)
coinIcon.Position = UDim2.new(0, 10, 0.5, -8)
coinIcon.BackgroundColor3 = COLORS.gold
coinIcon.BorderSizePixel = 0
coinIcon.Parent = coinPill

local coinIconCorner = Instance.new("UICorner")
coinIconCorner.CornerRadius = UDim.new(1, 0)
coinIconCorner.Parent = coinIcon

local coinSymbolLabel = Instance.new("TextLabel")
coinSymbolLabel.Size = UDim2.new(1, 0, 1, 0)
coinSymbolLabel.BackgroundTransparency = 1
coinSymbolLabel.Text = "$"
coinSymbolLabel.TextColor3 = Color3.fromRGB(150, 110, 30)
coinSymbolLabel.TextScaled = true
coinSymbolLabel.Font = Enum.Font.GothamBold
coinSymbolLabel.Parent = coinIcon

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -34, 1, 0)
coinLabel.Position = UDim2.new(0, 34, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.TextColor3 = COLORS.gold
coinLabel.TextScaled = true
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Text = "0"
coinLabel.Parent = coinPill

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -44, 0.5, -18)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
closeBtn.TextColor3 = Color3.fromRGB(140, 140, 155)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.Gotham
closeBtn.Text = "X"
closeBtn.Parent = titleBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 44)
tabBar.Position = UDim2.new(0, 12, 0, 52)
tabBar.BackgroundColor3 = COLORS.surface
tabBar.BorderSizePixel = 0
tabBar.Parent = panel

local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 10)
tabBarCorner.Parent = tabBar

local tabs = {}
local activeTab = "cosmetics"
local cosmeticsPage = nil
local consumablesPage = nil

local function createTab(name, label)
	local btn = Instance.new("TextButton")
	btn.Name = name .. "Tab"
	btn.Size = UDim2.new(0.5, -4, 1, -8)
	btn.Position = UDim2.new(name == "cosmetics" and 0 or 0.5, 4, 0, 4)
	btn.BackgroundColor3 = COLORS.accent
	btn.BackgroundTransparency = 1
	btn.Text = label
	btn.TextColor3 = COLORS.textDim
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = tabBar

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0.6, 0, 0, 3)
	indicator.Position = UDim2.new(0.2, 0, 1, -1)
	indicator.BackgroundColor3 = COLORS.accent
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel = 0
	indicator.Parent = btn

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0, 2)
	indicatorCorner.Parent = indicator

	tabs[name] = { btn = btn, indicator = indicator }
	return btn
end

local cosmeticsTab = createTab("cosmetics", "Cosmetics")
local consumablesTab = createTab("consumables", "Consumables")

local tabTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setActiveTab(name)
	activeTab = name
	for tabName, tabData in pairs(tabs) do
		local active = (tabName == name)
		TweenService:Create(tabData.btn, tabTweenInfo, {
			BackgroundTransparency = active and 0.85 or 1,
			TextColor3 = active and Color3.fromRGB(255, 255, 255) or COLORS.textDim,
		}):Play()
		TweenService:Create(tabData.indicator, tabTweenInfo, {
			BackgroundTransparency = active and 0 or 1,
		}):Play()
	end
	-- Show/hide content pages
	cosmeticsPage.Visible = (name == "cosmetics")
	consumablesPage.Visible = (name == "consumables")
end

-- Content area (below tab bar)
local contentBg = Instance.new("Frame")
contentBg.Size = UDim2.new(1, -24, 1, -108)
contentBg.Position = UDim2.new(0, 12, 0, 104)
contentBg.BackgroundColor3 = COLORS.bg
contentBg.BorderSizePixel = 0
contentBg.ClipsDescendants = true
contentBg.Parent = panel

-- COSMETICS PAGE
cosmeticsPage = Instance.new("ScrollingFrame")
cosmeticsPage.Size = UDim2.new(1, 0, 1, 0)
cosmeticsPage.BackgroundTransparency = 1
cosmeticsPage.BorderSizePixel = 0
cosmeticsPage.ScrollBarThickness = 3
cosmeticsPage.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 58)
cosmeticsPage.CanvasSize = UDim2.new(1, 0, 0, 0)
cosmeticsPage.Parent = contentBg

local itemCards = {}
local cosmeticRows = {}

-- Shared action handler
local function handleAction(id, state, coins)
	if state == "buy" then
		local cosmetic = CosmeticConfig.getById(id)
		if not cosmetic then return end
		if coins < cosmetic.price then return end
		Remotes.BuyCosmetic:FireServer(id)
	elseif state == "equip" then
		Remotes.EquipCosmetic:FireServer(id)
	end
end

-- Build cosmetic cards in manual 2-column rows
local COLS = 2
local ROW_H = 100
local PAD = 10
local cellW = UDim.new(0.5, -PAD / 2)

local function buildCosmeticCard(cosmetic, parent, xIdx)
	local card = Instance.new("Frame")
	if xIdx == 0 then
		card.Size = UDim2.new(0.5, -PAD / 2, 1, 0)
		card.Position = UDim2.new(0, 0, 0, 0)
	else
		card.Size = UDim2.new(0.5, -PAD / 2, 1, 0)
		card.Position = UDim2.new(0.5, PAD / 2, 0, 0)
	end
	card.BackgroundColor3 = COLORS.card
	card.BorderSizePixel = 0
	card.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local cardBorder = Instance.new("Frame")
	cardBorder.Size = UDim2.new(1, 0, 1, 0)
	cardBorder.BackgroundTransparency = 1
	cardBorder.BorderSizePixel = 1
	cardBorder.BorderColor3 = COLORS.border
	cardBorder.Parent = card

	local cardBorderCorner = Instance.new("UICorner")
	cardBorderCorner.CornerRadius = UDim.new(0, 10)
	cardBorderCorner.Parent = cardBorder

	-- Color swatch
	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(0, 44, 0, 44)
	swatch.Position = UDim2.new(0, 10, 0, 10)
	swatch.BackgroundColor3 = cosmetic.color
	swatch.BorderSizePixel = 0
	swatch.Parent = card

	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(0, 8)
	swatchCorner.Parent = swatch

	-- Material dot
	local matDot = Instance.new("Frame")
	matDot.Size = UDim2.new(0, 10, 0, 10)
	matDot.Position = UDim2.new(1, -5, 1, -5)
	matDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	matDot.BackgroundTransparency = 0.5
	matDot.BorderSizePixel = 0
	matDot.Parent = swatch

	local matDotCorner = Instance.new("UICorner")
	matDotCorner.CornerRadius = UDim.new(1, 0)
	matDotCorner.Parent = matDot

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -62, 0, 22)
	nameLabel.Position = UDim2.new(0, 62, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Text = cosmetic.name
	nameLabel.Parent = card

	-- Status
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -62, 0, 18)
	statusLabel.Position = UDim2.new(0, 62, 0, 36)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center
	statusLabel.Text = ""
	statusLabel.Parent = card

	-- Button
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(1, -14, 0, 28)
	actionBtn.Position = UDim2.new(0, 7, 1, -34)
	actionBtn.TextScaled = true
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.BorderSizePixel = 0
	actionBtn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 7)
	btnCorner.Parent = actionBtn

	actionBtn.MouseButton1Click:Connect(function()
		if not actionBtn.Active then return end
		local state = actionBtn:GetAttribute("State")
		if not state then return end
		local coins = tonumber(coinLabel.Text) or 0
		handleAction(cosmetic.id, state, coins)
		task.delay(0.2, refreshShop)
	end)

	itemCards[cosmetic.id] = {
		cosmetic = cosmetic,
		card = card,
		swatch = swatch,
		name = nameLabel,
		status = statusLabel,
		button = actionBtn,
	}
	return card
end

local function buildRow(items)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, ROW_H)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = cosmeticsPage
	table.insert(cosmeticRows, row)

	for i, c in ipairs(items) do
		buildCosmeticCard(c, row, i - 1)
	end
end

-- Build rows from cosmetic list
local list = CosmeticConfig.list
for i = 1, #list, COLS do
	local chunk = { table.unpack(list, i, math.min(i + COLS - 1, #list)) }
	buildRow(chunk)
end

-- UIListLayout + padding to stack rows vertically
local rowLayout = Instance.new("UIListLayout")
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Padding = UDim.new(0, PAD)
rowLayout.Parent = cosmeticsPage

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 4)
padding.Parent = cosmeticsPage

-- CONSUMABLES PAGE
consumablesPage = Instance.new("ScrollingFrame")
consumablesPage.Size = UDim2.new(1, 0, 1, 0)
consumablesPage.BackgroundTransparency = 1
consumablesPage.BorderSizePixel = 0
consumablesPage.ScrollBarThickness = 3
consumablesPage.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 58)
consumablesPage.CanvasSize = UDim2.new(1, 0, 0, 0)
consumablesPage.Visible = false
consumablesPage.Parent = contentBg

-- Tab click connections (pages must exist first)
cosmeticsTab.MouseButton1Click:Connect(function() setActiveTab("cosmetics") end)
consumablesTab.MouseButton1Click:Connect(function() setActiveTab("consumables") end)

local consumablesList = Instance.new("UIListLayout")
consumablesList.SortOrder = Enum.SortOrder.LayoutOrder
consumablesList.Padding = UDim.new(0, 10)
consumablesList.Parent = consumablesPage

-- Echo Ping card
local echoCard = Instance.new("Frame")
echoCard.Name = "EchoPingCard"
echoCard.Size = UDim2.new(1, 0, 0, 90)
echoCard.BackgroundColor3 = COLORS.card
echoCard.BorderSizePixel = 0
echoCard.Parent = consumablesPage

local echoCardCorner = Instance.new("UICorner")
echoCardCorner.CornerRadius = UDim.new(0, 10)
echoCardCorner.Parent = echoCard

local echoCardBorder = Instance.new("Frame")
echoCardBorder.Size = UDim2.new(1, 0, 1, 0)
echoCardBorder.BackgroundTransparency = 1
echoCardBorder.BorderSizePixel = 1
echoCardBorder.BorderColor3 = COLORS.border
echoCardBorder.Parent = echoCard

local echoCardBorderCorner = Instance.new("UICorner")
echoCardBorderCorner.CornerRadius = UDim.new(0, 10)
echoCardBorderCorner.Parent = echoCardBorder

-- Echo icon
local echoIcon = Instance.new("Frame")
echoIcon.Size = UDim2.new(0, 52, 0, 52)
echoIcon.Position = UDim2.new(0, 14, 0.5, -26)
echoIcon.BackgroundColor3 = Color3.fromRGB(180, 35, 35)
echoIcon.BorderSizePixel = 0
echoIcon.Parent = echoCard

local echoIconCorner = Instance.new("UICorner")
echoIconCorner.CornerRadius = UDim.new(0, 10)
echoIconCorner.Parent = echoIcon

local echoIconLabel = Instance.new("TextLabel")
echoIconLabel.Size = UDim2.new(1, 0, 1, 0)
echoIconLabel.BackgroundTransparency = 1
echoIconLabel.Text = "EP"
echoIconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
echoIconLabel.TextScaled = true
echoIconLabel.Font = Enum.Font.GothamBold
echoIconLabel.Parent = echoIcon

-- Name + description
local echoName = Instance.new("TextLabel")
echoName.Size = UDim2.new(1, -84, 0, 22)
echoName.Position = UDim2.new(0, 76, 0, 12)
echoName.BackgroundTransparency = 1
echoName.TextColor3 = Color3.fromRGB(230, 230, 240)
echoName.TextScaled = true
echoName.Font = Enum.Font.GothamBold
echoName.TextXAlignment = Enum.TextXAlignment.Left
echoName.TextYAlignment = Enum.TextYAlignment.Center
echoName.Text = "Echo Ping"
echoName.Parent = echoCard

local echoDesc = Instance.new("TextLabel")
echoDesc.Size = UDim2.new(1, -84, 0, 16)
echoDesc.Position = UDim2.new(0, 76, 0, 34)
echoDesc.BackgroundTransparency = 1
echoDesc.TextColor3 = COLORS.textDim
echoDesc.TextScaled = true
echoDesc.Font = Enum.Font.Gotham
echoDesc.TextXAlignment = Enum.TextXAlignment.Left
echoDesc.TextYAlignment = Enum.TextYAlignment.Center
echoDesc.Text = "Highlights anomaly room on radar"
echoDesc.Parent = echoCard

local echoStatus = Instance.new("TextLabel")
echoStatus.Size = UDim2.new(1, -84, 0, 18)
echoStatus.Position = UDim2.new(0, 76, 0, 54)
echoStatus.BackgroundTransparency = 1
echoStatus.TextScaled = true
echoStatus.Font = Enum.Font.Gotham
echoStatus.TextXAlignment = Enum.TextXAlignment.Left
echoStatus.TextYAlignment = Enum.TextYAlignment.Center
echoStatus.Text = "0 owned"
echoStatus.Parent = echoCard

local echoBtn = Instance.new("TextButton")
echoBtn.Name = "EchoBuyBtn"
echoBtn.Size = UDim2.new(0, isMobile and 130 or 110, 0, 34)
echoBtn.Position = UDim2.new(1, isMobile and -140 or -120, 0.5, -17)
echoBtn.Text = "Buy"
echoBtn.TextScaled = true
echoBtn.Font = Enum.Font.GothamBold
echoBtn.BorderSizePixel = 0
echoBtn.Parent = echoCard

local echoBtnCorner = Instance.new("UICorner")
echoBtnCorner.CornerRadius = UDim.new(0, 8)
echoBtnCorner.Parent = echoBtn

echoBtn.MouseButton1Click:Connect(function()
	if not echoBtn.Active then return end
	Remotes.BuyEchoPing:FireServer()
	task.delay(0.2, refreshShop)
end)

-- Update canvas sizes
local function updateCanvas()
	local rows = #cosmeticRows
	cosmeticsPage.CanvasSize = UDim2.new(1, 0, 0, rows * (ROW_H + PAD) + 4)
	consumablesPage.CanvasSize = UDim2.new(1, 0, 0, 100)
end

-- Refresh UI state from server
function refreshShop()
	local ok, data = pcall(function()
		return Remotes.GetShopData:InvokeServer()
	end)
	if not ok or not data then return end

	coinLabel.Text = tostring(data.coins or 0)
	local ownedList = data.ownedCosmetics or {"classic"}
	local equipped = data.equippedCosmetic or "classic"
	local echoPings = data.echoPings or 0

	-- Echo Ping card
	echoStatus.Text = "Owned: " .. tostring(echoPings)
	local canAffordEcho = (data.coins or 0) >= ECHO_PING_PRICE
	echoBtn.Text = tostring(ECHO_PING_PRICE) .. " coins"
	if canAffordEcho then
		echoBtn.BackgroundColor3 = COLORS.green
		echoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		echoBtn.Active = true
	else
		echoBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 35)
		echoBtn.TextColor3 = Color3.fromRGB(140, 100, 100)
		echoBtn.Active = false
	end

	-- Cosmetics
	for _, item in pairs(itemCards) do
		local id = item.cosmetic.id
		local card = item.card
		local price = item.cosmetic.price
		local btn = item.button
		local owned = (id == "classic")

		if not owned then
			for _, oid in ipairs(ownedList) do
				if oid == id then owned = true; break end
			end
		end

		card.BackgroundColor3 = COLORS.card

		if id == equipped then
			item.status.Text = "Equipped"
			item.status.TextColor3 = Color3.fromRGB(80, 255, 120)
			btn.Text = "Equipped"
			btn.BackgroundColor3 = Color3.fromRGB(40, 50, 42)
			btn.TextColor3 = Color3.fromRGB(80, 200, 100)
			btn.Active = false
			btn:SetAttribute("State", nil)
		elseif owned then
			item.status.Text = "Owned"
			item.status.TextColor3 = COLORS.textDim
			btn.Text = "Equip"
			btn.BackgroundColor3 = COLORS.accent
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Active = true
			btn:SetAttribute("State", "equip")
		else
			item.status.TextColor3 = COLORS.gold
			local canAfford = (data.coins or 0) >= price
			btn.Text = tostring(price) .. " coins"
			if canAfford then
				btn.BackgroundColor3 = COLORS.green
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				btn.BackgroundColor3 = Color3.fromRGB(40, 35, 35)
				btn.TextColor3 = Color3.fromRGB(140, 100, 100)
			end
			btn.Active = canAfford
			btn:SetAttribute("State", canAfford and "buy" or nil)
			if canAfford then
				item.status.Text = tostring(price) .. " coins"
			else
				item.status.Text = tostring(price) .. " coins"
			end
		end
	end
	updateCanvas()
end

-- Open shop
local function openShop()
	updatePanelSize()
	screenGui.Enabled = true
	setActiveTab("cosmetics")
	refreshShop()
end

-- Viewport resize listener (keeps panel in bounds)
local function onViewportChange()
	local cam = Workspace.CurrentCamera
	if cam then updatePanelSize() end
end
local cam = Workspace.CurrentCamera
if cam then
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(onViewportChange)
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCam = Workspace.CurrentCamera
	if newCam then
		newCam:GetPropertyChangedSignal("ViewportSize"):Connect(onViewportChange)
		onViewportChange()
	end
end)

-- Find Jeremy ATS ProximityPrompt in lobby
local function init()
	local lobby = Workspace:WaitForChild("Lobby", 30)
	if not lobby then return end

	local jeremyPrompt = lobby:WaitForChild("Jeremy_Prompt", 30)
	if not jeremyPrompt then return end

	local prompt = jeremyPrompt:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then return end

	prompt.Triggered:Connect(function(plr)
		if plr ~= player then return end
		openShop()
	end)
end

task.spawn(init)

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

-- Auto-refresh on buy/equip result
Remotes.BuyCosmetic.OnClientEvent:Connect(function(success, msg)
	if screenGui.Enabled then
		task.wait(0.15)
		refreshShop()
	end
end)

Remotes.EquipCosmetic.OnClientEvent:Connect(function(success, msg)
	if screenGui.Enabled then
		task.wait(0.15)
		refreshShop()
	end
end)

Remotes.BuyEchoPing.OnClientEvent:Connect(function(success, msg)
	if screenGui.Enabled then
		task.wait(0.15)
		refreshShop()
	end
end)

-- Close via Escape
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and screenGui.Enabled then
		screenGui.Enabled = false
	end
end)
