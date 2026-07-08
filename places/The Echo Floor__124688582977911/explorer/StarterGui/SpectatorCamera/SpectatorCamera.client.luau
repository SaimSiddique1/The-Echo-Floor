local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage.Remotes

local isMobile = UserInputService.TouchEnabled

local isSpectating = false
local targetIndex = 0
local targetPlayers = {}
local currentCamera = Workspace.CurrentCamera

local CAMERA_DISTANCE = 8
local CAMERA_HEIGHT = 5
local SMOOTH_SPEED = 6

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpectatorUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
if isMobile then
	screenGui.IgnoreGuiInset = true
	local uiscale = Instance.new("UIScale")
	uiscale.Parent = screenGui
	local function updateScale()
		local cam = Workspace.CurrentCamera
		if cam then
			local sz = cam.ViewportSize
			uiscale.Scale = math.clamp(math.min(sz.X / 1920, sz.Y / 1080), 0.35, 2)
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
screenGui.Parent = playerGui

local targetLabel = Instance.new("TextLabel")
targetLabel.Name = "TargetName"
targetLabel.Size = UDim2.new(0, 300, 0, 36)
targetLabel.Position = UDim2.new(0.5, 0, 0, 8)
targetLabel.AnchorPoint = Vector2.new(0.5, 0)
targetLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
targetLabel.BackgroundTransparency = 0.5
targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetLabel.TextScaled = true
targetLabel.Font = Enum.Font.GothamBold
targetLabel.TextXAlignment = Enum.TextXAlignment.Center
targetLabel.Text = ""
targetLabel.Parent = screenGui

local spectateLabel = Instance.new("TextLabel")
spectateLabel.Name = "SpectateLabel"
spectateLabel.Size = UDim2.new(0, 200, 0, 24)
spectateLabel.Position = UDim2.new(0.5, 0, 0, 48)
spectateLabel.AnchorPoint = Vector2.new(0.5, 0)
spectateLabel.BackgroundTransparency = 1
spectateLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
spectateLabel.TextScaled = true
spectateLabel.Font = Enum.Font.Gotham
spectateLabel.TextXAlignment = Enum.TextXAlignment.Center
spectateLabel.Text = "Spectating"
spectateLabel.Parent = screenGui

local leftArrow = Instance.new("TextButton")
leftArrow.Name = "LeftArrow"
leftArrow.Size = UDim2.new(0, 60, 0, 80)
leftArrow.Position = UDim2.new(0, 16, 0.5, 0)
leftArrow.AnchorPoint = Vector2.new(0, 0.5)
leftArrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
leftArrow.BackgroundTransparency = 0.85
leftArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
leftArrow.TextScaled = true
leftArrow.Font = Enum.Font.GothamBold
leftArrow.Text = "<"
leftArrow.Parent = screenGui

local rightArrow = Instance.new("TextButton")
rightArrow.Name = "RightArrow"
rightArrow.Size = UDim2.new(0, 60, 0, 80)
rightArrow.Position = UDim2.new(1, -76, 0.5, 0)
rightArrow.AnchorPoint = Vector2.new(0, 0.5)
rightArrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
rightArrow.BackgroundTransparency = 0.85
rightArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
rightArrow.TextScaled = true
rightArrow.Font = Enum.Font.GothamBold
rightArrow.Text = ">"
rightArrow.Parent = screenGui

local function selectTarget(index)
	if #targetPlayers == 0 then
		targetIndex = 0
		targetLabel.Text = ""
		return
	end
	targetIndex = ((index - 1) % #targetPlayers) + 1
	local t = targetPlayers[targetIndex]
	targetLabel.Text = t.Name .. "  |  " .. targetIndex .. "/" .. #targetPlayers
end

local function nextTarget()
	selectTarget(targetIndex + 1)
end

local function prevTarget()
	selectTarget(targetIndex - 1)
end

leftArrow.MouseButton1Click:Connect(prevTarget)
rightArrow.MouseButton1Click:Connect(nextTarget)

UserInputService.InputBegan:Connect(function(input, processed)
	if not isSpectating or processed then return end
	if input.KeyCode == Enum.KeyCode.Left then
		prevTarget()
	elseif input.KeyCode == Enum.KeyCode.Right then
		nextTarget()
	end
end)

local function getCameraTarget()
	if #targetPlayers == 0 or targetIndex == 0 then return nil end
	local t = targetPlayers[targetIndex]
	local p = Players:GetPlayerByUserId(t.UserId)
	if not p then return nil end
	local char = p.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	return hrp
end

local function findNewTarget(removedUserId)
	for i, t in ipairs(targetPlayers) do
		if t.UserId == removedUserId then
			table.remove(targetPlayers, i)
			if #targetPlayers == 0 then
				targetIndex = 0
			elseif targetIndex > #targetPlayers then
				targetIndex = #targetPlayers
			end
			selectTarget(targetIndex)
			return
		end
	end
end

Players.PlayerRemoving:Connect(function(p)
	if isSpectating then
		findNewTarget(p.UserId)
	end
end)

local function stopSpectating()
	isSpectating = false
	targetPlayers = {}
	targetIndex = 0
	screenGui.Enabled = false
	currentCamera.CameraType = Enum.CameraType.Custom
end

Remotes.SpectateInfo.OnClientEvent:Connect(function(data)
	isSpectating = true
	targetPlayers = data.players or {}
	screenGui.Enabled = #targetPlayers > 0
	if #targetPlayers > 0 then
		selectTarget(1)
	end
end)

Remotes.QueueUpdate.OnClientEvent:Connect(function(data)
	if data.show == false and isSpectating then
		stopSpectating()
	end
end)

currentCamera.Changed:Connect(function(prop)
	if prop == "CameraType" and currentCamera.CameraType ~= Enum.CameraType.Scriptable and isSpectating then
		currentCamera.CameraType = Enum.CameraType.Scriptable
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not isSpectating or #targetPlayers == 0 or targetIndex == 0 then return end

	currentCamera.CameraType = Enum.CameraType.Scriptable

	local hrp = getCameraTarget()
	if not hrp then return end

	local camPos = hrp.Position + hrp.CFrame.LookVector * -CAMERA_DISTANCE + Vector3.new(0, CAMERA_HEIGHT, 0)
	local lookAt = hrp.Position + Vector3.new(0, 2, 0)
	local targetCF = CFrame.lookAt(camPos, lookAt)

	currentCamera.CFrame = currentCamera.CFrame:Lerp(targetCF, math.min(SMOOTH_SPEED * dt, 1))
end)
