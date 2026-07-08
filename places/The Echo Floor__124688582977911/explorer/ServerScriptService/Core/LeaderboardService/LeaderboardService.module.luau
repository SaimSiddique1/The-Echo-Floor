local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local CosmeticConfig = require(game:GetService("ReplicatedStorage").Shared.CosmeticConfig)

local statsStore = DataStoreService:GetDataStore("PlayerStats")
local leaderStore = DataStoreService:GetOrderedDataStore("Leaderboard")

local ECHO_PING_PRICE = 35

local function defaultStats()
	return {
		points = 0,
		correct = 0,
		wrong = 0,
		abstained = 0,
		gamesPlayed = 0,
		coins = 1000,
		ownedCosmetics = {"classic"},
		equippedCosmetic = "classic",
		echoPings = 0,
	}
end

local function createLeaderstats(player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.coins
	coins.Parent = ls

	local gameScore = Instance.new("IntValue")
	gameScore.Name = "GameScore"
	gameScore.Value = 0
	gameScore.Parent = ls

	local rounds = Instance.new("IntValue")
	rounds.Name = "Rounds"
	rounds.Value = data.gamesPlayed
	rounds.Parent = ls

	local echoPings = Instance.new("IntValue")
	echoPings.Name = "EchoPings"
	echoPings.Value = data.echoPings or 0
	echoPings.Parent = ls

	ls.Parent = player
end

local function loadStats(userId)
	local success, data = pcall(function()
		return statsStore:GetAsync(tostring(userId))
	end)
	if success and data then
		if not data.ownedCosmetics then data.ownedCosmetics = {"classic"} end
		if not data.equippedCosmetic then data.equippedCosmetic = "classic" end
		if not data.coins then data.coins = 0 end
		if not data.echoPings then data.echoPings = 0 end
		return data
	end
	return defaultStats()
end

local function saveStats(userId, data)
	pcall(function()
		statsStore:SetAsync(tostring(userId), data)
	end)
	pcall(function()
		leaderStore:SetAsync(tostring(userId), data.points)
	end)
end

local function updateStats(player, points, abstained, isCorrect)
	local data = loadStats(player.UserId)
	if isCorrect then
		data.correct += 1
	elseif abstained then
		data.abstained += 1
	else
		data.wrong += 1
	end
	data.points += points
	data.gamesPlayed += 1
	saveStats(player.UserId, data)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local r = ls:FindFirstChild("Rounds")
		if r then r.Value = data.gamesPlayed end
	end
end

local function updateGameScore(player, score)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local gs = ls:FindFirstChild("GameScore")
		if gs then gs.Value = score end
	end
end

local function addCoins(player, amount)
	local data = loadStats(player.UserId)
	data.coins += amount
	saveStats(player.UserId, data)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Coins")
		if c then c.Value = data.coins end
	end
end

local function getPlayerData(player)
	return loadStats(player.UserId)
end

local function addEchoPings(player, amount)
	local data = loadStats(player.UserId)
	data.echoPings = (data.echoPings or 0) + amount
	saveStats(player.UserId, data)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local ep = ls:FindFirstChild("EchoPings")
		if ep then ep.Value = data.echoPings end
	end
end

local function useEchoPing(player)
	local data = loadStats(player.UserId)
	if (data.echoPings or 0) < 1 then return false end
	data.echoPings -= 1
	saveStats(player.UserId, data)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local ep = ls:FindFirstChild("EchoPings")
		if ep then ep.Value = data.echoPings end
	end
	return true
end

local function buyEchoPing(player)
	local data = loadStats(player.UserId)
	if (data.coins or 0) < ECHO_PING_PRICE then return false, "Not enough coins" end
	data.coins -= ECHO_PING_PRICE
	data.echoPings = (data.echoPings or 0) + 1
	saveStats(player.UserId, data)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Coins")
		if c then c.Value = data.coins end
		local ep = ls:FindFirstChild("EchoPings")
		if ep then ep.Value = data.echoPings end
	end
	return true, "Purchased"
end

local function buyCosmetic(player, cosmeticId)
	local data = loadStats(player.UserId)
	local cosmetic = CosmeticConfig.getById(cosmeticId)
	if not cosmetic then return false, "Invalid cosmetic" end
	if data.coins < cosmetic.price then return false, "Not enough coins" end
	for _, owned in ipairs(data.ownedCosmetics) do
		if owned == cosmeticId then return false, "Already owned" end
	end
	data.coins -= cosmetic.price
	table.insert(data.ownedCosmetics, cosmeticId)
	saveStats(player.UserId, data)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Coins")
		if c then c.Value = data.coins end
	end
	return true, "Purchased"
end

local function equipCosmetic(player, cosmeticId)
	local data = loadStats(player.UserId)
	local owned = false
	for _, ownedId in ipairs(data.ownedCosmetics) do
		if ownedId == cosmeticId then owned = true; break end
	end
	if not owned then return false, "Not owned" end
	data.equippedCosmetic = cosmeticId
	saveStats(player.UserId, data)
	return true, "Equipped"
end

local function init()
	Players.PlayerAdded:Connect(function(player)
		local data = loadStats(player.UserId)
		data.coins = 1000
		data.echoPings = 5
		createLeaderstats(player, data)
		saveStats(player.UserId, data)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local data = loadStats(player.UserId)
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local p = ls:FindFirstChild("Points")
			if p then data.points = p.Value end
			local c = ls:FindFirstChild("Correct")
			if c then data.correct = c.Value end
			local r = ls:FindFirstChild("Rounds")
			if r then data.gamesPlayed = r.Value end
			local coins = ls:FindFirstChild("Coins")
			if coins then data.coins = coins.Value end
		end
		saveStats(player.UserId, data)
	end)
end

local function getTopPlayers(callback)
	local ok, pages = pcall(function()
		return leaderStore:GetSortedAsync(false, 10)
	end)
	if not ok then
		callback({})
		return
	end
	local entries = pages:GetCurrentPage()
	if #entries == 0 then
		callback({})
		return
	end

	local results = {}
	for i, entry in ipairs(entries) do
		local userId = tonumber(entry.key)
		local name = "Player"
		local p = Players:GetPlayerByUserId(userId)
		if p then
			name = p.Name
		end
		table.insert(results, {
			rank = i,
			name = name,
			userId = userId,
			points = entry.value,
		})
	end
	callback(results)
end

return {
	init = init,
	updateStats = updateStats,
	updateGameScore = updateGameScore,
	getTopPlayers = getTopPlayers,
	addCoins = addCoins,
	getPlayerData = getPlayerData,
	buyCosmetic = buyCosmetic,
	equipCosmetic = equipCosmetic,
	addEchoPings = addEchoPings,
	useEchoPing = useEchoPing,
	buyEchoPing = buyEchoPing,
	ECHO_PING_PRICE = ECHO_PING_PRICE,
}
