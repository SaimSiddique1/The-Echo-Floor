-- MatchmakingService.server.luau
-- Queue: walk into bay → countdown on screen → exit button → teleport at 0

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Remotes = ReplicatedStorage.Remotes
local GameState = require(script.Parent.GameState)

local BAY_TIMER = 5
local MAX_PLAYERS = 8
local LOBBY_NAME = "Lobby"
local BAY_DETECTOR_NAME = "BayDetector"

local bayPlayers = {}
local countdownActive = false
local currentTimer = BAY_TIMER
local bayCenter, bayRadius

-- Find parts
local function findLobby()
	return Workspace:FindFirstChild(LOBBY_NAME)
end

local function findDetector()
	local lobby = findLobby()
	if lobby then
		return lobby:FindFirstChild(BAY_DETECTOR_NAME)
	end
	return nil
end

local function findSpawnPoint()
	local lobby = findLobby()
	if lobby then
		local spawn = lobby:FindFirstChildOfClass("SpawnLocation")
		if spawn then
			return spawn.CFrame + Vector3.new(0, 3, 0)
		end
	end
	return CFrame.new(0, 1003, 0)
end

local function findGameTeleport()
	local elevator = Workspace:FindFirstChild("Elevator")
	if elevator then
		local target = elevator:FindFirstChild("TeleportTarget")
		if target then
			return target.CFrame + Vector3.new(0, 3, 0)
		end
	end
	return CFrame.new(0, 3, 0)
end

-- Send queue UI state to a player
local function sendUI(player, show, seconds, count)
	Remotes.QueueUpdate:FireClient(player, {
		show = show,
		seconds = seconds or 0,
		count = count or 0,
	})
end

-- Update UI for all bay players
local function broadcastUI(show, seconds)
	local count = #bayPlayers
	for _, player in ipairs(bayPlayers) do
		sendUI(player, show, seconds, count)
	end
end

-- Lobby music
local lobbyMusic = Instance.new("Sound")
lobbyMusic.Name = "LobbyMusic"
lobbyMusic.SoundId = "rbxassetid://1848354536"
lobbyMusic.Volume = 0.4
lobbyMusic.Looped = true
lobbyMusic.Parent = game:GetService("SoundService")

local function startLobbyMusic()
	if not lobbyMusic.Playing then
		lobbyMusic:Play()
	end
end

local function stopLobbyMusic()
	lobbyMusic:Stop()
end

-- Teleport player to game
local function teleportToGame(player)
	local cf = findGameTeleport()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = cf
	end
end

-- Teleport player back to lobby
local function teleportToLobby(player)
	local cf = findSpawnPoint()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = cf
	end
end

-- Start the round
local function startRound()
	if #bayPlayers == 0 then return end

	local players = {}
	for _, p in ipairs(bayPlayers) do
		table.insert(players, p)
	end

	-- Clear queue before teleporting
	local toTeleport = {}
	for _, p in ipairs(bayPlayers) do
		table.insert(toTeleport, p)
	end
	bayPlayers = {}
	countdownActive = false
	stopLobbyMusic()

	for _, player in ipairs(toTeleport) do
		sendUI(player, false, 0, 0)
		teleportToGame(player)
	end

	task.wait(0.5)

	local RoundRunner = require(script.Parent:FindFirstChild("RoundRunner"))
	if RoundRunner and RoundRunner.Start then
		RoundRunner.Start(toTeleport)
	end
end

-- Check if a player is still inside the bay (distance check)
local function isInBay(player)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return false
	end
	return (player.Character.HumanoidRootPart.Position - bayCenter).Magnitude <= bayRadius
end

-- Remove players who left the bay
local function purgeLeavers()
	for i = #bayPlayers, 1, -1 do
		local player = bayPlayers[i]
		if not isInBay(player) then
			sendUI(player, false, 0, 0)
			table.remove(bayPlayers, i)
		end
	end
end

-- Countdown loop
local function runCountdown()
	countdownActive = true
	currentTimer = BAY_TIMER

	while countdownActive and #bayPlayers > 0 do
		purgeLeavers()
		if #bayPlayers == 0 then break end

		broadcastUI(true, currentTimer)

		if currentTimer <= 0 then
			startRound()
			return
		end

		task.wait(1)
		currentTimer -= 1

		if #bayPlayers >= MAX_PLAYERS and currentTimer > 3 then
			currentTimer = 3
		end
	end

	-- No players left
	broadcastUI(false, 0)
	countdownActive = false
end

-- Player enters the bay (or spectates during active game)
local function onPlayerEntered(player)
	if GameState.gameInProgress then
		-- Already spectating?
		for _, v in ipairs(GameState.spectators) do
			if v == player then return end
		end
		table.insert(GameState.spectators, player)
		sendUI(player, true, -1, 0)
		Remotes.SpectateInfo:FireClient(player, {
			players = GameState.currentGamePlayers,
		})
		return
	end

	for _, v in ipairs(bayPlayers) do
		if v == player then return end
	end
	table.insert(bayPlayers, player)
	sendUI(player, true, currentTimer, #bayPlayers)

	if not countdownActive then
		coroutine.wrap(runCountdown)()
	end
end

-- Player leaves the bay (or spectator leaves)
local function onPlayerLeft(player)
	for i, v in ipairs(bayPlayers) do
		if v == player then
			table.remove(bayPlayers, i)
			sendUI(player, false, 0, 0)
			return
		end
	end
	for i, v in ipairs(GameState.spectators) do
		if v == player then
			table.remove(GameState.spectators, i)
			sendUI(player, false, 0, 0)
			return
		end
	end
end

-- Player leaves via exit button
Remotes.QueueExit.OnServerEvent:Connect(function(player)
	onPlayerLeft(player)
	teleportToLobby(player)
end)

-- Detect players entering the bay
local function setupDetector()
	local detector = findDetector()
	if not detector then
		warn("BayDetector not found")
		return
	end

	local cf = detector.CFrame
	local sz = detector.Size
	bayCenter = cf.Position
	bayRadius = math.max(sz.X, sz.Z) / 2 + 2

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "QueuePrompt"
	prompt.ActionText = "Join Queue"
	prompt.ObjectText = "Elevator Bay"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = detector

	prompt.Triggered:Connect(function(player)
		onPlayerEntered(player)
	end)
end

-- Player disconnected
local function onPlayerRemoved(player)
	onPlayerLeft(player)
end

-- Return players to lobby after round ends
local function returnAllPlayers(players)
	for _, player in ipairs(players) do
		teleportToLobby(player)
	end
	startLobbyMusic()
end

-- Game ended — return spectators, restart lobby music
GameState.gameEnded:Connect(function()
	for _, player in ipairs(GameState.spectators) do
		teleportToLobby(player)
		sendUI(player, false, 0, 0)
	end
	GameState.spectators = {}
	startLobbyMusic()
end)

-- Init
local function init()
	-- Build lobby if it doesn't exist yet
	if not findLobby() then
		local ok, err = pcall(function()
			local LobbyGenerator = require(ReplicatedStorage.Tools.LobbyGenerator)
			if not LobbyGenerator then
				error("LobbyGenerator returned nil")
			end
		end)
		if not ok then
			warn("Failed to build lobby:", err)
		end
	end

	setupDetector()
	Players.PlayerRemoving:Connect(onPlayerRemoved)
	local LeaderboardService = require(script.Parent.LeaderboardService)
	LeaderboardService.init()
	require(script.Parent.ShopHandler)
	startLobbyMusic()
	task.spawn(function()
		local LeaderboardDisplays = require(script.Parent.LeaderboardDisplays)
		LeaderboardDisplays.refreshAllTime()
	end)
	print("MatchmakingService ready")
end

local api = {}
api.returnAllPlayers = returnAllPlayers
api.teleportToLobby = teleportToLobby
api.teleportToGame = teleportToGame

init()
return api
