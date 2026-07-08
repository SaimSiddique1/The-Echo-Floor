local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Remotes = ReplicatedStorage.Remotes

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isMobile = UserInputService.TouchEnabled

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QueueUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
if isMobile then
	screenGui.IgnoreGuiInset = true
end
screenGui.Parent = playerGui

if isMobile then
	local uiscale = Instance.new("UIScale")
	uiscale.Parent = screenGui
	local function updateScale()
		local camera = workspace.CurrentCamera
		if camera then
			local sz = camera.ViewportSize
			local s = math.min(sz.X / 1920, sz.Y / 1080)
			uiscale.Scale = math.clamp(s, 0.35, 2)
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
end

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Timer"
timerLabel.Size = UDim2.fromOffset(300, 80)
timerLabel.Position = UDim2.new(0.5, 0, 0, 30)
timerLabel.AnchorPoint = Vector2.new(0.5, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = ""
timerLabel.ZIndex = 10
timerLabel.Parent = screenGui

local subText = Instance.new("TextLabel")
subText.Name = "SubText"
subText.Size = UDim2.fromOffset(400, 40)
subText.Position = UDim2.new(0.5, 0, 0, 110)
subText.AnchorPoint = Vector2.new(0.5, 0)
subText.BackgroundTransparency = 1
subText.TextColor3 = Color3.fromRGB(200, 200, 200)
subText.TextScaled = true
subText.Font = Enum.Font.Gotham
subText.Text = ""
subText.ZIndex = 10
subText.Parent = screenGui

local countLabel = Instance.new("TextLabel")
countLabel.Name = "PlayerCount"
countLabel.Size = UDim2.fromOffset(300, 40)
countLabel.Position = UDim2.new(0.5, 0, 0, 160)
countLabel.AnchorPoint = Vector2.new(0.5, 0)
countLabel.BackgroundTransparency = 1
countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countLabel.TextScaled = true
countLabel.Font = Enum.Font.Gotham
countLabel.Text = ""
countLabel.ZIndex = 10
countLabel.Parent = screenGui

local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.fromOffset(200, 60)
exitButton.Position = UDim2.new(0.5, 0, 1, -80)
exitButton.AnchorPoint = Vector2.new(0.5, 1)
exitButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
exitButton.BackgroundTransparency = 0.3
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.TextScaled = true
exitButton.Font = Enum.Font.GothamBold
exitButton.Text = "LEAVE QUEUE"
exitButton.ZIndex = 10
exitButton.Parent = screenGui

exitButton.MouseButton1Click:Connect(function()
	Remotes.QueueExit:FireServer()
end)

Remotes.QueueUpdate.OnClientEvent:Connect(function(data)
	screenGui.Enabled = data.show
	if data.show then
		if data.seconds == -1 then
			timerLabel.Text = "SPECTATING"
			timerLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
			subText.Text = "A game is in progress"
			countLabel.Text = ""
		else
			timerLabel.Text = tostring(data.seconds)
			countLabel.Text = data.count .. "/8 players"
			if data.seconds <= 5 then
				timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				subText.Text = "Departing..."
			else
				timerLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
				subText.Text = "Searching for players..."
			end
		end
	end
end)

Remotes.RoundStart.OnClientEvent:Connect(function()
	screenGui.Enabled = false
end)
