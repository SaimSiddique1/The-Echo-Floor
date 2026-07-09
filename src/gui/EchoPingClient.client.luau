local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Remotes = ReplicatedStorage.Remotes
local isMobile = UserInputService.TouchEnabled

local gui = nil
local countLabel = nil
local useBtn = nil
local cooldown = false

local function updateCount()
	local ls = player:FindFirstChild("leaderstats")
	local pings = 0
	if ls then
		local ep = ls:FindFirstChild("EchoPings")
		if ep then pings = ep.Value end
	end
	if countLabel then
		countLabel.Text = "Echo Ping x" .. tostring(pings)
	end
	if useBtn then
		useBtn.Visible = pings > 0
	end
end

local function destroyGUI()
	if gui then
		gui:Destroy()
		gui = nil
	end
	countLabel = nil
	useBtn = nil
end

local function createGUI()
	destroyGUI()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EchoPingUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = not isMobile
	screenGui.DisplayOrder = 15
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 50)
	frame.Position = UDim2.new(0.5, -100, 1, isMobile and -80 or -140)
	frame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local border = Instance.new("Frame")
	border.Size = UDim2.new(1, 0, 1, 0)
	border.BackgroundTransparency = 1
	border.BorderSizePixel = 1
	border.BorderColor3 = Color3.fromRGB(180, 35, 35)
	border.Parent = frame

	local borderCorner = Instance.new("UICorner")
	borderCorner.CornerRadius = UDim.new(0, 10)
	borderCorner.Parent = border

	countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(0, 110, 1, 0)
	countLabel.Position = UDim2.new(0, 12, 0, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	countLabel.Text = "Echo Ping x0"
	countLabel.Parent = frame

	useBtn = Instance.new("TextButton")
	useBtn.Size = UDim2.new(0, isMobile and 80 or 70, 0, isMobile and 36 or 30)
	useBtn.Position = UDim2.new(1, isMobile and -88 or -78, 0.5, isMobile and -18 or -15)
	useBtn.BackgroundColor3 = Color3.fromRGB(180, 35, 35)
	useBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	useBtn.TextScaled = true
	useBtn.Font = Enum.Font.GothamBold
	useBtn.Text = "USE"
	useBtn.BorderSizePixel = 0
	useBtn.Parent = frame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = useBtn

	updateCount()

	useBtn.MouseButton1Click:Connect(function()
		if cooldown then return end
		cooldown = true
		task.delay(8, function() cooldown = false end)

		useBtn.Text = "SCANING"
		local ok, result = pcall(function()
			return Remotes.UseEchoPing:InvokeServer()
		end)
		if ok and result and result.room then
			if _G.setAnomalyPing then
				_G.setAnomalyPing(result.room, 5)
			end
			updateCount()
		end
		useBtn.Text = "USE"
	end)

	gui = screenGui
end

-- Watch EchoPings value changes to auto-update count
local function watchEchoPings()
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		player.ChildAdded:Connect(function(child)
			if child.Name == "leaderstats" then watchEchoPings() end
		end)
		return
	end
	local function onPingChanged()
		if gui then updateCount() end
	end
	local ep = ls:FindFirstChild("EchoPings")
	if ep then
		ep:GetPropertyChangedSignal("Value"):Connect(onPingChanged)
	else
		ls.ChildAdded:Connect(function(child)
			if child.Name == "EchoPings" then
				child:GetPropertyChangedSignal("Value"):Connect(onPingChanged)
				if gui then updateCount() end
			end
		end)
	end
end

local function onEquipped()
	createGUI()
end

local function onUnequipped()
	destroyGUI()
end

local function watchTool()
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	local function connectTool(tool)
		if tool:IsA("Tool") then
			tool.Equipped:Connect(onEquipped)
			tool.Unequipped:Connect(onUnequipped)
		end
	end

	local tool = backpack:FindFirstChild("Echo Ping")
	if tool then connectTool(tool) end

	backpack.ChildAdded:Connect(function(child)
		if child.Name == "Echo Ping" then
			connectTool(child)
		end
	end)
end

watchEchoPings()

if player:FindFirstChild("Backpack") then
	watchTool()
end
player.ChildAdded:Connect(function(child)
	if child.Name == "Backpack" then
		watchTool()
	end
end)
