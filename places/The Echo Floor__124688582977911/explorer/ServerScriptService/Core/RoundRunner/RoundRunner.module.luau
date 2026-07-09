-- RoundRunner.luau (ModuleScript)
-- Exports: Start(players) — runs the endless-floor solo-survival lifecycle

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local FloorCloner = require(script.Parent.FloorCloner)
local AnomalySwapper = require(script.Parent.AnomalySwapper)
local LeaderboardService = require(script.Parent.LeaderboardService)
local LeaderboardDisplays = require(script.Parent.LeaderboardDisplays)
local GameState = require(script.Parent.GameState)
local AnomalyConfig = require(ReplicatedStorage.Shared.AnomalySwapConfig)
local Remotes = ReplicatedStorage.Remotes

local GOING_UP_TIME = 3
local EXPLORE_TIME = 3
local INTERMISSION_TIME = 3
local REVEAL_TIME = 4
local BOARDING_TIME = 3

local scores = {}
local allOriginalPlayers = {}
local currentAnomalyName = nil
local isSearchPhase = false
local isPanicFloor = false

local function findElevator()
	return Workspace:FindFirstChild("Elevator")
end

local doorClosedL, doorClosedR

local function cacheDoorPositions()
	local elevator = findElevator()
	if not elevator then return end
	local dl = elevator:FindFirstChild("Door_Left")
	local dr = elevator:FindFirstChild("Door_Right")
	if dl and dr then
		doorClosedL = dl.CFrame
		doorClosedR = dr.CFrame
	end
end

local function getOrCreateMusic(elevator)
	local m = elevator:FindFirstChild("ElevatorMusic")
	if not m then
		m = Instance.new("Sound")
		m.Name = "ElevatorMusic"
		m.SoundId = "rbxassetid://1837198630"
		m.Volume = 0.4
		m.Looped = true
		m.Parent = elevator
	end
	return m
end

local function startElevatorMusic()
	local elevator = findElevator()
	if not elevator then return end
	getOrCreateMusic(elevator):Play()
end

local function stopElevatorMusic()
	local elevator = findElevator()
	if elevator then
		local m = elevator:FindFirstChild("ElevatorMusic")
		if m then m:Stop() end
	end
end

local function playDing()
	local elevator = findElevator()
	if not elevator then return end
	stopElevatorMusic()
	local s = elevator:FindFirstChild("Ding")
	if s and s:IsA("Sound") then
		s:Play()
		task.delay(0.9, function() s:Stop() end)
	end
end

local function setDoors(open)
	if not doorClosedL or not doorClosedR then
		cacheDoorPositions()
	end
	if not doorClosedL or not doorClosedR then return end

	local elevator = findElevator()
	local doorL = elevator and elevator:FindFirstChild("Door_Left")
	local doorR = elevator and elevator:FindFirstChild("Door_Right")
	if not doorL or not doorR then return end

	local offset = doorL.Size.Z
	local duration = 0.5
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	if open then
		local goalL = { CFrame = doorClosedL * CFrame.new(0, 0, -offset) }
		local goalR = { CFrame = doorClosedR * CFrame.new(0, 0, offset) }
		TweenService:Create(doorL, tweenInfo, goalL):Play()
		TweenService:Create(doorR, tweenInfo, goalR):Play()
	else
		local goalL = { CFrame = doorClosedL }
		local goalR = { CFrame = doorClosedR }
		TweenService:Create(doorL, tweenInfo, goalL):Play()
		TweenService:Create(doorR, tweenInfo, goalR):Play()
	end

	local elevator = findElevator()
	if elevator then
		local name = open and "DoorOpen" or "DoorClose"
		local s = elevator:FindFirstChild(name)
		if s and s:IsA("Sound") then
			s:Play()
			task.delay(0.6, function() s:Stop() end)
		end
	end
end

local function updateDisplay(text)
	local elevator = findElevator()
	if not elevator then return end
	local textSurface = elevator:FindFirstChild("FloorTextSurface")
	if not textSurface then return end
	local sg = textSurface:FindFirstChildOfClass("SurfaceGui")
	if not sg then return end
	local label = sg:FindFirstChild("FloorNumber")
	if label then
		label.Text = text
	end
end

local function addResultsScreen(floor)
	local screen = Instance.new("Part")
	screen.Name = "ResultsScreen"
	screen.Size = Vector3.new(26, 14, 0.3)
	screen.CFrame = CFrame.new(-21, 7.5, 8.3)
	screen.Anchored = true
	screen.Locked = false
	screen.Color = Color3.fromRGB(8, 8, 12)
	screen.Material = Enum.Material.SmoothPlastic
	screen.Parent = floor

	local sg = Instance.new("SurfaceGui")
	sg.Name = "ResultsGui"
	sg.Face = Enum.NormalId.Front
	sg.AlwaysOnTop = false
	sg.ResetOnSpawn = false
	sg.CanvasSize = Vector2.new(600, 340)
	sg.Parent = screen

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 34)
	title.Position = UDim2.new(0, 20, 0, 12)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 220, 100)
	title.Text = ""
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Font = Enum.Font.GothamBold
	title.Parent = sg

	local sub = Instance.new("TextLabel")
	sub.Name = "Subtitle"
	sub.Size = UDim2.new(1, -40, 0, 18)
	sub.Position = UDim2.new(0, 20, 0, 50)
	sub.BackgroundTransparency = 1
	sub.TextColor3 = Color3.fromRGB(180, 180, 200)
	sub.Text = ""
	sub.TextScaled = true
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Font = Enum.Font.GothamBold
	sub.Visible = false
	sub.Parent = sg

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -40, 0, 90)
	body.Position = UDim2.new(0, 20, 0, 72)
	body.BackgroundTransparency = 1
	body.TextColor3 = Color3.fromRGB(200, 200, 210)
	body.Text = ""
	body.TextScaled = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Font = Enum.Font.Gotham
	body.Visible = false
	body.Parent = sg

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.Size = UDim2.new(0, 70, 0, 44)
	timer.Position = UDim2.new(0.5, -35, 1, -56)
	timer.BackgroundTransparency = 1
	timer.TextColor3 = Color3.fromRGB(255, 255, 255)
	timer.Text = ""
	timer.TextScaled = true
	timer.TextXAlignment = Enum.TextXAlignment.Center
	timer.TextYAlignment = Enum.TextYAlignment.Center
	timer.Font = Enum.Font.GothamBlack
	timer.Visible = false
	timer.Parent = sg

	local resBody = Instance.new("TextLabel")
	resBody.Name = "ResultsBody"
	resBody.Size = UDim2.new(1, -40, 1, -55)
	resBody.Position = UDim2.new(0, 20, 0, 50)
	resBody.BackgroundTransparency = 1
	resBody.TextColor3 = Color3.fromRGB(200, 200, 210)
	resBody.Text = ""
	resBody.TextScaled = true
	resBody.TextXAlignment = Enum.TextXAlignment.Left
	resBody.TextYAlignment = Enum.TextYAlignment.Top
	resBody.Font = Enum.Font.Gotham
	resBody.Visible = false
	resBody.Parent = sg

	return screen
end

local function showPhase(screen, title, subtitle, body, timerSeconds)
	local sg = screen:FindFirstChild("ResultsGui")
	if not sg then return end

	local tl = sg:FindFirstChild("Title")
	local st = sg:FindFirstChild("Subtitle")
	local bd = sg:FindFirstChild("Body")
	local tm = sg:FindFirstChild("Timer")
	local rb = sg:FindFirstChild("ResultsBody")

	local podium = sg:FindFirstChild("PodiumFrame")
	if podium then podium:Destroy() end

	if tl then tl.Text = title end
	if st then st.Text = subtitle or ""; st.Visible = subtitle ~= nil end
	if bd then bd.Text = body or ""; bd.Visible = body ~= nil end
	if tm then tm.Text = timerSeconds and tostring(timerSeconds) or ""; tm.Visible = timerSeconds ~= nil end
	if rb then rb.Visible = false end
end

local function showResultsOnScreen(screen, results, anomalyName, panicLabel)
	local sg = screen:FindFirstChild("ResultsGui")
	if not sg then return end

	local oldBox = sg:FindFirstChild("RevealHeadshotBox")
	if oldBox then oldBox:Destroy() end
	local oldPodium = sg:FindFirstChild("PodiumFrame")
	if oldPodium then oldPodium:Destroy() end

	if panicLabel then
		sg:FindFirstChild("Title").Text = "⚠ " .. panicLabel .. " ⚠"
	else
		sg:FindFirstChild("Title").Text = "ROUND RESULTS"
	end
	sg:FindFirstChild("Subtitle").Visible = false
	sg:FindFirstChild("Body").Visible = false
	sg:FindFirstChild("Timer").Visible = false

	local rb = sg:FindFirstChild("ResultsBody")
	rb.Visible = false

	local sorted = {}
	for _, r in ipairs(results) do
		table.insert(sorted, r)
	end
	table.sort(sorted, function(a, b) return (a.total or 0) > (b.total or 0) end)

	local podiumFrame = Instance.new("Frame")
	podiumFrame.Name = "PodiumFrame"
	podiumFrame.Size = UDim2.new(1, -40, 0, 110)
	podiumFrame.Position = UDim2.new(0, 20, 0, 78)
	podiumFrame.BackgroundTransparency = 1
	podiumFrame.Parent = sg

	local podiumColors = {
		Color3.fromRGB(255, 215, 0),
		Color3.fromRGB(192, 192, 192),
		Color3.fromRGB(205, 127, 50),
	}

	for i = 1, math.min(3, #sorted) do
		local r = sorted[i]
		local heights = { 0.75, 0.5, 0.35 }
		local h = heights[i]
		local col = podiumColors[i]

		local block = Instance.new("Frame")
		block.Size = UDim2.new(0, 70, 0, 40 + 40 * h)
		block.Position = UDim2.new(0.5, -105 + (i - 1) * 105, 1, -10 - 40 * h)
		block.AnchorPoint = Vector2.new(0, 1)
		block.BackgroundColor3 = col
		block.BackgroundTransparency = 0.3
		block.BorderSizePixel = 0
		block.Parent = podiumFrame

		local medal = Instance.new("TextLabel")
		medal.Size = UDim2.new(1, 0, 0, 18)
		medal.Position = UDim2.new(0, 0, 0, 4)
		medal.BackgroundTransparency = 1
		medal.TextColor3 = Color3.fromRGB(255, 255, 255)
		medal.TextScaled = true
		medal.Font = Enum.Font.GothamBold
		medal.TextXAlignment = Enum.TextXAlignment.Center
		if i == 1 then medal.Text = "#1"
		elseif i == 2 then medal.Text = "#2"
		else medal.Text = "#3" end
		medal.Parent = block

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -8, 0, 18)
		nameLabel.Position = UDim2.new(0, 4, 0, 22)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.Text = r.name
		nameLabel.Parent = block

		local scoreLabel = Instance.new("TextLabel")
		scoreLabel.Size = UDim2.new(1, -8, 0, 16)
		scoreLabel.Position = UDim2.new(0, 4, 0, 42)
		scoreLabel.BackgroundTransparency = 1
		scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
		scoreLabel.TextScaled = true
		scoreLabel.Font = Enum.Font.Gotham
		scoreLabel.TextXAlignment = Enum.TextXAlignment.Center
		scoreLabel.Text = tostring(r.total) .. " pts"
		scoreLabel.Parent = block
	end

	local anomalyLabel = sg:FindFirstChild("AnomalyLabel")
	if not anomalyLabel then
		anomalyLabel = Instance.new("TextLabel")
		anomalyLabel.Name = "AnomalyLabel"
		anomalyLabel.Size = UDim2.new(1, -40, 0, 24)
		anomalyLabel.Position = UDim2.new(0, 20, 0, 50)
		anomalyLabel.BackgroundTransparency = 1
		anomalyLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
		anomalyLabel.TextScaled = true
		anomalyLabel.TextXAlignment = Enum.TextXAlignment.Center
		anomalyLabel.Font = Enum.Font.GothamBold
		anomalyLabel.Parent = sg
	end
	local anomalyMeta = anomalyName and AnomalyConfig.catalog[anomalyName]
	anomalyLabel.Visible = true
	if panicLabel then
		anomalyLabel.Text = "⚠ " .. panicLabel .. " ⚠"
	elseif anomalyMeta then
		anomalyLabel.Text = "ANOMALY: " .. anomalyName .. "  —  " .. anomalyMeta.region .. " · " .. anomalyMeta.type
	else
		anomalyLabel.Text = "ANOMALY: " .. (anomalyName or "None")
	end

	local box = Instance.new("Frame")
	box.Name = "RevealHeadshotBox"
	box.Size = UDim2.new(1, -20, 0, 100)
	box.Position = UDim2.new(0, 10, 1, -115)
	box.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	box.BackgroundTransparency = 0.25
	box.BorderSizePixel = 0
	box.Parent = sg

	local cellSize = 60
	local totalW = #results * (cellSize + 8) - 8
	local startX = math.max(0, (600 - 20 - totalW) / 2)

	for i, r in ipairs(results) do
		local x = startX + (i - 1) * (cellSize + 8)

		local borderColor
		if r.correct then
			borderColor = Color3.fromRGB(80, 255, 80)
		elseif r.noAnomaly then
			borderColor = Color3.fromRGB(255, 220, 100)
		elseif r.abstained then
			borderColor = Color3.fromRGB(140, 140, 140)
		else
			borderColor = Color3.fromRGB(255, 60, 60)
		end

		local border = Instance.new("Frame")
		border.Size = UDim2.new(0, cellSize, 0, cellSize)
		border.Position = UDim2.new(0, x, 0, 6)
		border.BackgroundColor3 = borderColor
		border.BorderSizePixel = 0
		border.Parent = box

		local img = Instance.new("ImageLabel")
		img.Size = UDim2.new(1, -4, 1, -4)
		img.Position = UDim2.new(0, 2, 0, 2)
		img.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		img.BorderSizePixel = 0
		img.Parent = border

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0, cellSize + 8, 0, 14)
		nameLabel.Position = UDim2.new(0, -4, 0, cellSize + 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		nameLabel.TextScaled = true
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.Text = r.name
		nameLabel.Parent = border

		local ptsLabel = Instance.new("TextLabel")
		ptsLabel.Size = UDim2.new(0, cellSize + 8, 0, 12)
		ptsLabel.Position = UDim2.new(0, -4, 0, cellSize + 16)
		ptsLabel.BackgroundTransparency = 1
		ptsLabel.TextColor3 = borderColor
		ptsLabel.TextScaled = true
		ptsLabel.TextXAlignment = Enum.TextXAlignment.Center
		ptsLabel.Font = Enum.Font.GothamBold
		if r.correct then
			local bonusStr = r.bonus and r.bonus > 0 and " (+" .. r.bonus .. " speed)" or ""
			ptsLabel.Text = "+" .. r.points .. bonusStr .. " (" .. r.total .. ")"
		elseif r.noAnomaly then
			ptsLabel.Text = "+" .. r.points .. " (" .. r.total .. ")"
		elseif r.abstained then
			ptsLabel.Text = "—"
		else
			ptsLabel.Text = r.points .. " (" .. r.total .. ")"
		end
		ptsLabel.Parent = border

		task.spawn(function()
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(r.userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
			end)
			if ok then
				img.Image = url
			end
		end)
	end
end

local function findSpawnPoint()
	local lobby = Workspace:FindFirstChild("Lobby")
	if lobby then
		local spawn = lobby:FindFirstChildOfClass("SpawnLocation")
		if spawn then
			return spawn.CFrame + Vector3.new(0, 3, 0)
		end
	end
	return CFrame.new(0, 1003, 0)
end

local function findSpectatorSeat()
	local lobby = Workspace:FindFirstChild("Lobby")
	if lobby then
		local seating = lobby:FindFirstChild("SpectatorSeating")
		if seating then
			local seats = seating:GetChildren()
			if #seats > 0 then
				return seats[math.random(1, #seats)].CFrame + Vector3.new(0, 3, 0)
			end
		end
	end
	return findSpawnPoint()
end

local function teleportToElevator(player)
	local elevator = findElevator()
	if not elevator then return end
	local target = elevator:FindFirstChild("TeleportTarget")
	if not target then return end
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 3, 0)
	end
end

local function teleportToLobby(player)
	local cf = findSpawnPoint()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = cf
	end
end

local function teleportToSpectator(player)
	local cf = findSpectatorSeat()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = cf
	end
end

local function teleportToElevatorLobby(player)
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = CFrame.lookAt(
			Vector3.new(-21, 3, 2),
			Vector3.new(-21, 3, 9)
		)
	end
end

local function returnAllPlayers()
	for _, player in ipairs(allOriginalPlayers) do
		teleportToLobby(player)
	end
	GameState.gameInProgress = false
	GameState.currentGamePlayers = {}
	GameState.fireGameEnded()
end

local function getSearchTime(floorNum)
	return 50
end



local function runIntermissionPhase(players, screen, floorNum)
	setDoors(false)

	for _, player in ipairs(players) do
		teleportToElevatorLobby(player)
	end

	local floor = Workspace:FindFirstChild("Floor")
	local barrier = nil
	if floor then
		barrier = Instance.new("Part")
		barrier.Name = "IntermissionBarrier"
		barrier.Size = Vector3.new(18, 15, 1)
		barrier.CFrame = CFrame.new(-21, 7.5, -27)
		barrier.Anchored = true
		barrier.Locked = false
		barrier.CanCollide = true
		barrier.Transparency = 0.6
		barrier.Color = Color3.fromRGB(60, 60, 70)
		barrier.Material = Enum.Material.Metal
		barrier.Parent = floor
	end

	for i = INTERMISSION_TIME, 1, -1 do
		Remotes.RoundTimerTick:FireAllClients(i, "intermission")
		showPhase(screen, "FLOOR " .. floorNum, "PENDING", "Waiting for results...\nNo discussion. No changing your guess.", i)
		task.wait(1)
	end

	if barrier then
		barrier:Destroy()
	end
end

local function runSearchPhase(players, screen, floorNum, anomalyName, panicLabel)
	local guesses = {}
	local guessNames = {}
	local guessTimes = {}
	local guessCount = 0
	local totalPlayers = #players
	isSearchPhase = true
	local remaining = getSearchTime(floorNum)

	for _, player in ipairs(players) do
		guesses[player.UserId] = nil
	end

	local activeSet = {}
	for _, p in ipairs(players) do activeSet[p] = true end

	local connection
	connection = Remotes.LogGuess.OnServerEvent:Connect(function(player, data)
		if not isSearchPhase then return end
		if not activeSet[player] then return end
		if guesses[player.UserId] ~= nil then return end

		if data == nil then
			guesses[player.UserId] = { isNoAnomaly = true }
			guessNames[player.UserId] = "NoAnomaly"
			guessTimes[player.UserId] = remaining
			guessCount += 1
			Remotes.LogGuess:FireClient(player, "logged")
			return
		end

		if type(data) ~= "table" or not data.region or not data.category then return end

		if panicLabel then
			-- Panic floor: every room and every category is affected
			guesses[player.UserId] = { region = data.region, category = data.category, regionCorrect = true, categoryCorrect = true }
		elseif anomalyName then
			local meta = AnomalyConfig.catalog[anomalyName]
			local regionCorrect = meta and (data.region == meta.region) or false
			local categoryCorrect = meta and (data.category == meta.type) or false
			guesses[player.UserId] = { region = data.region, category = data.category, regionCorrect = regionCorrect, categoryCorrect = categoryCorrect }
		else
			guesses[player.UserId] = { region = data.region, category = data.category, regionCorrect = false, categoryCorrect = false }
		end
		guessNames[player.UserId] = data.region .. " · " .. data.category
		guessTimes[player.UserId] = remaining
		guessCount += 1
		Remotes.LogGuess:FireClient(player, "logged")
	end)

	while remaining > 0 and guessCount < totalPlayers do
		Remotes.RoundTimerTick:FireAllClients(remaining, "search")
		if panicLabel then
			showPhase(screen, "⚠ " .. panicLabel .. " ⚠",
				"EVERYTHING IS WRONG",
				"Every room has an anomaly!\nPick any room and type — or trust your gut with Panic.",
				remaining)
		else
			showPhase(screen, "FLOOR " .. floorNum,
				"FIND THE ANOMALY",
				"Use your anomaly scanner to investigate.\nPick a room and type, then press Lock In.",
				remaining)
		end
		task.wait(1)
		remaining -= 1
	end

	isSearchPhase = false
	connection:Disconnect()

	return guesses, guessNames, guessTimes
end

local function scoreAndReveal(players, guesses, guessNames, guessTimes, anomalyName, floorNum, screen, panicLabel)
	local correctEntries = {}
	for _, player in ipairs(players) do
		local guess = guesses[player.UserId]
		if type(guess) == "table" and guess.regionCorrect and guess.categoryCorrect then
			table.insert(correctEntries, { player = player, time = guessTimes[player.UserId] or 999 })
		end
	end
	table.sort(correctEntries, function(a, b) return a.time < b.time end)

	local bonusMap = {}
	for i, entry in ipairs(correctEntries) do
		if i == 1 then bonusMap[entry.player.UserId] = 5
		elseif i == 2 then bonusMap[entry.player.UserId] = 3
		elseif i == 3 then bonusMap[entry.player.UserId] = 1
		else bonusMap[entry.player.UserId] = 0 end
	end

	local results = {}
	local survivors = {}
	local eliminated = {}

	for _, player in ipairs(players) do
		local guess = guesses[player.UserId]
		local regionCorrect = type(guess) == "table" and guess.regionCorrect or false
		local categoryCorrect = type(guess) == "table" and guess.categoryCorrect or false
		local correct = regionCorrect and categoryCorrect
		local abstained = (guess == nil)
		local noAnomaly = (type(guess) == "table" and guess.isNoAnomaly) and (anomalyName == nil) and not panicLabel
		local time = guessTimes[player.UserId]
		local bonus = bonusMap[player.UserId] or 0

		local points = 0
		if correct then
			points = 10 + bonus
		elseif regionCorrect then
			points = 5
		elseif categoryCorrect then
			points = 3
		elseif noAnomaly then
			points = 5
		elseif not abstained then
			points = -3
		end

		scores[player.UserId] = (scores[player.UserId] or 0) + points
		LeaderboardService.updateGameScore(player, scores[player.UserId])
		LeaderboardService.updateStats(player, points, abstained, correct)
		local coinReward = 0
		if correct then
			coinReward = 5 + (bonus or 0)
		elseif regionCorrect then
			coinReward = 3
		elseif categoryCorrect then
			coinReward = 2
		elseif noAnomaly then
			coinReward = 3
		elseif not abstained then
			coinReward = 1
		end
		if coinReward > 0 then
			LeaderboardService.addCoins(player, coinReward)
		end

		table.insert(results, {
			name = player.Name,
			userId = player.UserId,
			correct = correct,
			regionCorrect = regionCorrect,
			categoryCorrect = categoryCorrect,
			abstained = abstained,
			noAnomaly = noAnomaly,
			points = points,
			coins = coinReward,
			bonus = bonus,
			total = scores[player.UserId],
			time = time,
		})

		-- Elimination: wrong guess = out. Abstain is fine (0 pts, survives).
		if not abstained and not correct and not noAnomaly then
			table.insert(eliminated, player)
		else
			table.insert(survivors, player)
		end
	end

	showResultsOnScreen(screen, results, anomalyName, panicLabel)
	Remotes.RevealResults:FireAllClients(results)

	if anomalyName then
		local floor = Workspace:FindFirstChild("Floor")
		local anomalyFolder = floor and floor:FindFirstChild("Anomaly")
		local anomalyObj = anomalyFolder and anomalyFolder:FindFirstChild(anomalyName)
		if anomalyObj then
			local highlight = Instance.new("Highlight")
			highlight.Adornee = anomalyObj
			highlight.FillColor = Color3.fromRGB(255, 220, 50)
			highlight.FillTransparency = 0.6
			highlight.OutlineColor = Color3.fromRGB(255, 200, 0)
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = anomalyObj
		end
	end

	task.wait(REVEAL_TIME)

	for _, r in ipairs(results) do
		print(r.name .. ": " .. r.points .. " (" .. r.total .. " total)")
	end

	return survivors, eliminated
end

local function runBoardingPhase(survivors, eliminated, screen)
	updateDisplay("▲")
	setDoors(true)

	-- Eliminated players get left behind when doors open
	for _, player in ipairs(eliminated) do
		teleportToSpectator(player)
		table.insert(GameState.spectators, player)
		print(player.Name .. " eliminated")
	end

	startElevatorMusic()
	for i = BOARDING_TIME, 1, -1 do
		Remotes.RoundTimerTick:FireAllClients(i, "boarding")
		showPhase(screen, "BOARDING", nil, "Elevator doors are open.\nStep inside for the next floor.", i)
		task.wait(1)
	end

	for _, player in ipairs(survivors) do
		teleportToElevator(player)
	end
	setDoors(false)
end

local function runExplorePhase(players, screen)
	for i = EXPLORE_TIME, 1, -1 do
		Remotes.RoundTimerTick:FireAllClients(i, "explore")
		showPhase(screen, "FLOOR 0",
			"EXPLORE",
			"Learn the environment.\nEverything is normal... for now.\nNo anomaly on this floor.",
			i)
		task.wait(1)
	end
end

local function goingUpSequence(floorNum, doAnomalySwap, screen, panicLabel)
	local anomalyName = nil
	currentAnomalyName = nil
	setDoors(false)
	updateDisplay("▲\nto Floor " .. floorNum)
	local phaseLabel = panicLabel and "PANIC: " .. panicLabel or "GOING UP"
	for i = GOING_UP_TIME, 1, -1 do
		Remotes.RoundTimerTick:FireAllClients(i, "goingUp")
		if screen then
			if panicLabel then
				showPhase(screen, "⚠ " .. panicLabel .. " ⚠", nil, "Every anomaly is active!\nSomething is wrong in every room.", i)
			else
				showPhase(screen, phaseLabel, nil, "Something changed while you weren't looking...", i)
			end
		end
		if i == GOING_UP_TIME and doAnomalySwap then
			anomalyName = AnomalySwapper.swapAnomaly()
		end
		if i == 1 then
			playDing()
		end
		task.wait(1)
	end
	currentAnomalyName = anomalyName
	return anomalyName
end

local function Start(players)
	print("Round started with " .. #players .. " players")
	scores = {}
	allOriginalPlayers = players
	for _, p in ipairs(players) do
		scores[p.UserId] = 0
		LeaderboardService.updateGameScore(p, 0)
	end
	GameState.gameInProgress = true
	GameState.spectators = {}
	GameState.currentGamePlayers = players
	AnomalySwapper.resetUsed()
	cacheDoorPositions()
	Remotes.RoundStart:FireAllClients()

	Remotes.UseEchoPing.OnServerInvoke = function(player)
		if not player then return nil end
		if not isSearchPhase then return nil end
		if isPanicFloor then return { room = "any", type = "any" } end
		if not currentAnomalyName then return nil end
		local meta = AnomalyConfig.catalog[currentAnomalyName]
		if not meta then return nil end

		local ok = LeaderboardService.useEchoPing(player)
		if not ok then return nil end

		return { room = meta.region, type = meta.type }
	end

	Remotes.DevGrantCoins.OnServerEvent:Connect(function(player)
		if not player then return end
		LeaderboardService.addCoins(player, 1000)
	end)

	local survivingPlayers = {}
	for _, p in ipairs(players) do
		table.insert(survivingPlayers, p)
	end

	-- Teleport all to elevator
	for _, player in ipairs(survivingPlayers) do
		teleportToElevator(player)
	end
	setDoors(false)

	-- === FLOOR 0: Explore (no anomaly) ===
	local floor = FloorCloner.spawnFloor()
	AnomalySwapper.hideAllReplacements()
	local screen = addResultsScreen(floor)

	-- Arrive at Ground Floor — no going up label
	updateDisplay("Ground Floor")
	showPhase(screen, "GROUND FLOOR", nil, "Arriving...", nil)
	task.wait(1.5)
	playDing()
	task.wait(0.3)
	setDoors(true)

	runExplorePhase(survivingPlayers, screen)

	-- Board back to elevator after explore — doors stay open until Going Up
	startElevatorMusic()
	for i = 1, 1, -1 do
		Remotes.RoundTimerTick:FireAllClients(i, "boarding")
		showPhase(screen, "BOARDING", nil, "Back to the elevator...", i)
		task.wait(1)
	end
	for _, player in ipairs(survivingPlayers) do
		teleportToElevator(player)
	end

	AnomalySwapper.revertAll()
	floor:Destroy()
	Remotes.FloorReset:FireAllClients()

	-- === FLOORS 1, 2, 3, ... N: Search loop ===
	local floorNum = 0
	while #survivingPlayers > 0 do
		floorNum += 1

		-- Roll for panic floor
		isPanicFloor = math.random() < AnomalySwapper.PANIC_CHANCE
		local panicType = isPanicFloor and AnomalySwapper.rollPanicType() or nil
		local panicLabel = panicType and AnomalySwapper.panicFloors[panicType] and AnomalySwapper.panicFloors[panicType].label or nil

		floor = FloorCloner.spawnFloor()
		AnomalySwapper.hideAllReplacements()
		screen = addResultsScreen(floor)

		local anomalyName = goingUpSequence(floorNum, not isPanicFloor, screen, panicLabel)

		-- Apply panic floor after going up (replaces single anomaly)
		if isPanicFloor and panicType then
			AnomalySwapper.applyPanic(panicType, floor)
			anomalyName = nil
		end

		setDoors(true)
		updateDisplay(isPanicFloor and "⚠" or tostring(floorNum))

		local guesses, guessNames, guessTimes = runSearchPhase(survivingPlayers, screen, floorNum, anomalyName, panicLabel)

		runIntermissionPhase(survivingPlayers, screen, floorNum)

		survivingPlayers, eliminated = scoreAndReveal(survivingPlayers, guesses, guessNames, guessTimes, anomalyName, floorNum, screen, panicLabel)

		if #survivingPlayers == 0 then
			AnomalySwapper.revertAll()
			floor:Destroy()
			Remotes.FloorReset:FireAllClients()
			break
		end

		runBoardingPhase(survivingPlayers, eliminated, screen)

		AnomalySwapper.revertAll()
		floor:Destroy()
		Remotes.FloorReset:FireAllClients()
	end

	updateDisplay("0")
	returnAllPlayers()
	task.spawn(function()
		LeaderboardDisplays.updatePreviousGame(scores, allOriginalPlayers)
		LeaderboardDisplays.refreshAllTime()
	end)
	print("Game over. All players eliminated. " .. tostring(#allOriginalPlayers) .. " players returned to lobby.")
end

return { Start = Start }
