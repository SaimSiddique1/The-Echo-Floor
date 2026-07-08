local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LeaderboardService = require(script.Parent.LeaderboardService)

local ROW_COUNT = 10

local TOP3_COLORS = {
	Color3.fromRGB(255, 200, 50),
	Color3.fromRGB(200, 200, 210),
	Color3.fromRGB(200, 150, 80),
}

local function findLobby()
	return Workspace:FindFirstChild("Lobby")
end

local function getBoard(name)
	local lobby = findLobby()
	if not lobby then return nil end
	local part = lobby:FindFirstChild(name)
	if not part then return nil end
	return part
end

local function fillBoard(part, entries)
	if not part then return end

	local sg = part:FindFirstChildOfClass("SurfaceGui")
	if not sg then return end

	local bg = sg:FindFirstChildOfClass("Frame")
	if not bg then return end

	local empty = bg:FindFirstChild("EmptyLabel")
	local rows = {}
	for i = 1, ROW_COUNT do
		local row = bg:FindFirstChild("Row" .. i)
		if row then
			rows[i] = {
				frame = row,
				rank = row:FindFirstChild("Rank"),
				name = row:FindFirstChild("Name"),
				score = row:FindFirstChild("Score"),
			}
		end
	end

	if not entries or #entries == 0 then
		if empty then empty.Visible = true end
		for i = 1, ROW_COUNT do
			if rows[i] then rows[i].frame.Visible = false end
		end
		return
	end

	if empty then empty.Visible = false end

	for i = 1, ROW_COUNT do
		local row = rows[i]
		if not row then continue end

		if i <= #entries then
			local entry = entries[i]
			row.frame.Visible = true
			row.frame.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(22, 22, 27) or Color3.fromRGB(18, 18, 22)

			-- Rank
			if i <= 3 then
				row.rank.TextColor3 = TOP3_COLORS[i]
				row.rank.Text = "#" .. i
			else
				row.rank.TextColor3 = Color3.fromRGB(160, 160, 160)
				row.rank.Text = tostring(i)
			end

			-- Name
			row.name.Text = entry.name

			-- Score
			local pts = entry.score or entry.points or 0
			row.score.Text = tostring(pts)
		else
			row.frame.Visible = false
		end
	end
end

local function updatePreviousGame(scores, players)
	local part = getBoard("PrevGameBoard")
	if not part then return end

	if not scores or not players or #players == 0 then
		fillBoard(part, {})
		return
	end

	local sorted = {}
	for _, p in ipairs(players) do
		table.insert(sorted, {
			name = p.Name,
			score = scores[p.UserId] or 0,
		})
	end
	table.sort(sorted, function(a, b) return a.score > b.score end)

	fillBoard(part, sorted)
end

local function refreshAllTime()
	local part = getBoard("AllTimeBoard")
	if not part then return end

	LeaderboardService.getTopPlayers(function(top)
		if #top == 0 then
			fillBoard(part, {})
			return
		end
		fillBoard(part, top)
	end)
end

return {
	updatePreviousGame = updatePreviousGame,
	refreshAllTime = refreshAllTime,
}
