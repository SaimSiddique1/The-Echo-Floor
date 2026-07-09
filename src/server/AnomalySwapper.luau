-- AnomalySwapper.luau (ModuleScript)
-- Exports: swapAnomaly() — picks one anomaly (swap or behavior), returns name
--          applyPanic(panicType, floor) — applies a panic floor type
--          rollPanicType() — returns a random panic floor type name
--          revertAll() — reverts all anomalies
--          hideAllReplacements() — hides all replacement parts
--          resetUsed() — resets used anomalies pool

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local AnomalyConfig = require(ReplicatedStorage.Shared.AnomalySwapConfig)
local SwapConfig = AnomalyConfig.swapConfig
local Behaviors = require(ReplicatedStorage.Shared.AnomalyBehavior)

local FLOOR_SURFACE_Y = 0.5
local usedAnomalies = {}
local activeBehaviorName = nil
local multiSwapGroups = {
	AllPlates = { "Plate1", "Plate2", "Plate3", "Plate4", "Plate5", "Plate6" },
}

-- PANIC FLOOR SYSTEM
local PANIC_CHANCE = 0.1

-- panicFloors and rollPanicType are defined after all helper functions, just before the return

local function liftAboveFloor(inst)
	local parts = {}
	if inst:IsA("BasePart") then
		parts = { inst }
	elseif inst:IsA("Model") then
		for _, v in inst:GetDescendants() do
			if v:IsA("BasePart") then
				table.insert(parts, v)
			end
		end
	end
	for _, p in ipairs(parts) do
		local top = p.Position.Y + p.Size.Y / 2
		if top <= FLOOR_SURFACE_Y then
			p.CFrame = p.CFrame + Vector3.new(0, FLOOR_SURFACE_Y - top + 0.05, 0)
		end
	end
end

local function moveTo(obj, cf)
	if obj:IsA("BasePart") then
		obj.CFrame = cf
	elseif obj:IsA("Model") then
		local parts = {}
		for _, v in obj:GetDescendants() do
			if v:IsA("BasePart") then
				table.insert(parts, v)
			end
		end
		if #parts > 0 then
			local saved = {}
			local min, max = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
			for _, p in ipairs(parts) do
				saved[p] = p.CFrame
				local pos = p.Position
				min = Vector3.new(math.min(min.X, pos.X), math.min(min.Y, pos.Y), math.min(min.Z, pos.Z))
				max = Vector3.new(math.max(max.X, pos.X), math.max(max.Y, pos.Y), math.max(max.Z, pos.Z))
				p.CanQuery = true
			end
			local center = (min + max) / 2
			local oldCenterCF = CFrame.new(center)
			for _, p in ipairs(parts) do
				local relCF = oldCenterCF:ToObjectSpace(saved[p])
				p.CFrame = cf * relCF
			end
		end
	end
	if cf.Position.Y > -50 then
		liftAboveFloor(obj)
		if obj:IsA("BasePart") then
			print("lifted", obj.Name, "to", obj.Position.Y)
		end
	end
end

local function makeVisible(obj)
	local parts = {}
	if obj:IsA("BasePart") then
		parts = { obj }
	elseif obj:IsA("Model") then
		for _, v in obj:GetDescendants() do
			if v:IsA("BasePart") then table.insert(parts, v) end
		end
	end
	for _, p in ipairs(parts) do
		p.Transparency = 0
	end
end

local function getTargets()
	local floor = workspace:FindFirstChild("Floor")
	if not floor then return {} end
	local anomalyFolder = floor:FindFirstChild("Anomaly")
	local targets = {}
	for _, v in floor:GetDescendants() do
		if v:GetAttribute("AnomalyTarget") then
			if not (anomalyFolder and v:IsDescendantOf(anomalyFolder)) then
				table.insert(targets, v)
			end
		end
	end
	return targets
end

local function findTarget(targets, name)
	for _, t in ipairs(targets) do
		if t.Name == name then return t end
	end
	return nil
end

local function isGroupMember(name)
	for _, members in pairs(multiSwapGroups) do
		for _, m in ipairs(members) do
			if m == name then return true end
		end
	end
	return false
end

local function getReplacement(targetName)
	local floor = workspace:FindFirstChild("Floor")
	if not floor then return nil end
	local anomalyFolder = floor:FindFirstChild("Anomaly")
	if not anomalyFolder then return nil end
	for _, v in anomalyFolder:GetChildren() do
		if v:GetAttribute("Replaces") == targetName then
			return v
		end
	end
	return nil
end

local function hideAllReplacements()
	local floor = workspace:FindFirstChild("Floor")
	if not floor then return end
	local anomalyFolder = floor:FindFirstChild("Anomaly")
	if not anomalyFolder then return end
	for _, v in anomalyFolder:GetChildren() do
		local replaces = v:GetAttribute("Replaces")
		if replaces and SwapConfig[replaces] then
			moveTo(v, SwapConfig[replaces].replacementHide)
		end
	end
end

local function revertAll()
	local floor = workspace:FindFirstChild("Floor")
	if not floor then return end

	for _, v in floor:GetDescendants() do
		if v:GetAttribute("AnomalyTarget") then
			local config = SwapConfig[v.Name]
			if config then
				moveTo(v, config.show)
			end
		end
	end

	hideAllReplacements()

	if activeBehaviorName and Behaviors[activeBehaviorName] then
		Behaviors[activeBehaviorName].revert(floor)
		activeBehaviorName = nil
	end
end

local function swapAnomaly()
	hideAllReplacements()
	activeBehaviorName = nil

	local floor = workspace:FindFirstChild("Floor")

	local swapPool = {}
	local targets = getTargets()
	for _, t in ipairs(targets) do
		local name = t.Name
		if not usedAnomalies[name] and not isGroupMember(name) then
			table.insert(swapPool, { name = name, type = "swap" })
		end
	end

	for groupName, members in pairs(multiSwapGroups) do
		if not usedAnomalies[groupName] then
			local allAvailable = true
			for _, m in ipairs(members) do
				if usedAnomalies[m] then
					allAvailable = false
					break
				end
			end
			if allAvailable then
				table.insert(swapPool, { name = groupName, type = "swap" })
			end
		end
	end

	local behaviorPool = {}
	for bName, _ in pairs(Behaviors) do
		if bName == "HallwayWallShift" then continue end
		if not usedAnomalies[bName] then
			table.insert(behaviorPool, { name = bName, type = "behavior" })
		end
	end

	local combined = {}
	for _, v in ipairs(swapPool) do table.insert(combined, v) end
	for _, v in ipairs(behaviorPool) do table.insert(combined, v) end

	if #combined == 0 then
		warn("All anomalies already used in this session")
		usedAnomalies = {}
		for _, t in ipairs(targets) do
			if not isGroupMember(t.Name) then
				table.insert(combined, { name = t.Name, type = "swap" })
			end
		end
		for groupName, members in pairs(multiSwapGroups) do
			local allAvailable = true
			for _, m in ipairs(members) do
				if not findTarget(targets, m) then
					allAvailable = false
					break
				end
			end
			if allAvailable then
				table.insert(combined, { name = groupName, type = "swap" })
			end
		end
		for bName, _ in pairs(Behaviors) do
			table.insert(combined, { name = bName, type = "behavior" })
		end
	end

	local chosenName = combined[math.random(1, #combined)].name
	usedAnomalies[chosenName] = true
	print("Anomaly activated: " .. chosenName)

	local behaviorDef = Behaviors[chosenName]
	if behaviorDef then
		behaviorDef.apply(floor)
		activeBehaviorName = chosenName
		print("Behavior anomaly activated: " .. chosenName)
		return chosenName
	end

	local groupEntries = multiSwapGroups[chosenName]
	if groupEntries then
		local function processEntry(entryName)
			local t = findTarget(targets, entryName)
			if not t then
				warn("Multi-target: " .. entryName .. " not found, skipping")
				return
			end
			local cfg = SwapConfig[entryName]
			if not cfg then
				warn("Multi-target: no swap config for " .. entryName)
				return
			end
			local repl = getReplacement(entryName)
			if not repl then
				warn("Multi-target: no replacement for " .. entryName)
				return
			end
			moveTo(t, cfg.hide)
			moveTo(repl, cfg.replacementShow)
			repl.Name = entryName
			local parts = {}
			if repl:IsA("BasePart") then
				parts = { repl }
			elseif repl:IsA("Model") then
				for _, v in repl:GetDescendants() do
					if v:IsA("BasePart") then table.insert(parts, v) end
				end
			end
			for _, p in ipairs(parts) do
				p.Transparency = 0
			end
			print("    swapped: " .. entryName)
		end
		for _, entryName in ipairs(groupEntries) do
			processEntry(entryName)
			usedAnomalies[entryName] = true
		end
		return chosenName
	end

	local targetObj = findTarget(targets, chosenName)
	if not targetObj then
		warn("Swap target not found in floor: " .. chosenName)
		return nil
	end
	local config = SwapConfig[chosenName]
	if not config then
		warn("No swap config for: " .. chosenName)
		return nil
	end
	local replacement = getReplacement(chosenName)
	if not replacement then
		warn("No replacement found for: " .. chosenName)
		return nil
	end
	moveTo(targetObj, config.hide)
	moveTo(replacement, config.replacementShow)
	replacement.Name = chosenName
	local parts = {}
	if replacement:IsA("BasePart") then
		parts = { replacement }
	elseif replacement:IsA("Model") then
		for _, v in replacement:GetDescendants() do
			if v:IsA("BasePart") then table.insert(parts, v) end
		end
	end
	for _, p in ipairs(parts) do
		p.Transparency = 0
	end
	print("Swap anomaly activated: " .. chosenName)
	return chosenName
end

local function resetUsed()
	usedAnomalies = {}
end

local hunterState = {}
local voidState = {}

local panicFloors = {
	all_anomalies = {
		name = "all_anomalies",
		label = "ALL ANOMALIES",
		description = "Every anomaly is active at once!",
		apply = function(floor)
			local targets = {}
			for _, v in floor:GetDescendants() do
				if v:GetAttribute("AnomalyTarget") then
					table.insert(targets, v)
				end
			end

			-- Apply all swap anomalies
			for targetName, config in pairs(SwapConfig) do
				local isGroup = multiSwapGroups[targetName]
				if isGroup then
					for _, memberName in ipairs(isGroup) do
						local targetObj = findTarget(targets, memberName)
						if targetObj then
							local memberConfig = SwapConfig[memberName]
							local replacement = getReplacement(memberName)
							if memberConfig and replacement then
								moveTo(targetObj, memberConfig.hide)
								moveTo(replacement, memberConfig.replacementShow)
								makeVisible(replacement)
							end
						end
					end
				else
					local targetObj = findTarget(targets, targetName)
					if targetObj then
						local replacement = getReplacement(targetName)
						if config and replacement then
							moveTo(targetObj, config.hide)
							moveTo(replacement, config.replacementShow)
							makeVisible(replacement)
						end
					end
				end
			end

			-- Apply all behavior anomalies
			for bName, behavior in pairs(Behaviors) do
				task.spawn(function()
					behavior.apply(floor)
				end)
			end
		end,
		revert = function(floor)
			revertAll()
		end,
	},
	the_void = {
		name = "the_void",
		label = "FLOOR 404",
		description = "The rooms don't exist...",
		apply = function(floor)
			local lighting = game:GetService("Lighting")

			for _, v in floor:GetDescendants() do
				if v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
					v.Enabled = false
				end
				if v:IsA("BasePart") and v.Transparency < 0.9 then
					local n = v.Name
					if n:find("_Floor") then
						v.Transparency = 0.35
						v.Material = Enum.Material.Glass
						v.Color = Color3.fromRGB(160, 180, 240)
					elseif not (n:find("_W_") or n:find("_Ceiling") or n:find("_Base") or n:find("_Crown") or n:find("_Light")) then
						-- furniture, skip
					else
						v.Material = Enum.Material.SmoothPlastic
						v.Color = Color3.fromRGB(0, 0, 0)
					end
				end
			end

			-- Save and kill global lighting
			local savedLighting = {
				Ambient = lighting.Ambient,
				OutdoorAmbient = lighting.OutdoorAmbient,
				Brightness = lighting.Brightness,
				ClockTime = lighting.ClockTime,
				GlobalShadows = lighting.GlobalShadows,
			}
			lighting.Ambient = Color3.fromRGB(0, 0, 0)
			lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
			lighting.Brightness = 0
			lighting.ClockTime = 0
			lighting.GlobalShadows = true

			local atmo = Instance.new("Atmosphere")
			atmo.Name = "VoidAtmo"
			atmo.Density = 0.7
			atmo.Offset = 1
			atmo.Color = Color3.fromRGB(0, 0, 0)
			atmo.Decay = Color3.fromRGB(0, 0, 0)
			atmo.Glare = 0
			atmo.Parent = floor

			voidState[floor] = savedLighting
		end,
		revert = function(floor)
			local lighting = game:GetService("Lighting")
			local saved = voidState[floor]
			if saved then
				lighting.Ambient = saved.Ambient
				lighting.OutdoorAmbient = saved.OutdoorAmbient
				lighting.Brightness = saved.Brightness
				lighting.ClockTime = saved.ClockTime
				lighting.GlobalShadows = saved.GlobalShadows
			end
			voidState[floor] = nil
			local atmo = floor:FindFirstChild("VoidAtmo")
			if atmo then atmo:Destroy() end
		end,
	},
	the_hunter = {
		name = "the_hunter",
		label = "THE HUNTER",
		description = "Something is hunting you...",
		apply = function(floor)
			local template = ServerStorage.Templates:FindFirstChild("fred")

			local monster = template:Clone()
			monster.Name = "Fred"
			monster.Parent = floor

			-- Remove built-in scripts so we control movement
			for _, v in monster:GetDescendants() do
				if v:IsA("Script") or v:IsA("LocalScript") then
					v:Destroy()
				end
			end

			-- Anchor all parts so he doesn't ragdoll
			for _, v in monster:GetDescendants() do
				if v:IsA("BasePart") then
					v.Anchored = true
				end
			end

			-- Set primary part for movement
			local torso = monster:FindFirstChild("Torso")
			local head = monster:FindFirstChild("Head")
			if torso then
				monster.PrimaryPart = torso
			end

			-- Make him look menacing
			for _, v in monster:GetDescendants() do
				if v:IsA("BasePart") then
					v.Material = Enum.Material.SmoothPlastic
					v.Color = Color3.fromRGB(8, 8, 12)
				end
			end
			if head then
				local glow = Instance.new("Highlight")
				glow.Adornee = monster
				glow.FillColor = Color3.fromRGB(120, 0, 0)
				glow.FillTransparency = 0.3
				glow.OutlineColor = Color3.fromRGB(200, 0, 0)
				glow.DepthMode = Enum.HighlightDepthMode.Occluded
				glow.Parent = monster
			end

			-- Spawn in the kitchen
			local spawnBounds = AnomalyConfig.roomBounds["Kitchen"]
			local sx = spawnBounds.xMin + math.random() * (spawnBounds.xMax - spawnBounds.xMin)
			local sz = spawnBounds.zMin + math.random() * (spawnBounds.zMax - spawnBounds.zMin)
			monster:SetPrimaryPartCFrame(CFrame.new(sx, torso.Position.Y, sz))

			local safeZone = AnomalyConfig.roomBounds["ElevatorLobby"]

			local caughtPlayers = {}
			local speed = 12
			local detectionRadius = 50
			local catchRadius = 4

			-- Wall collision setup
			local raycastFilter = RaycastParams.new()
			raycastFilter.FilterType = Enum.RaycastFilterType.Blacklist

			local conn
			conn = RunService.Heartbeat:Connect(function()
				if not monster.Parent then conn:Disconnect() return end

				local nearest, nearestDist, nearestChar = nil, math.huge, nil
				for _, player in ipairs(Players:GetPlayers()) do
					if caughtPlayers[player] then continue end
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						local root = char.HumanoidRootPart
						local dist = (root.Position - torso.Position).Magnitude
						if dist < nearestDist then
							nearest = root
							nearestDist = dist
							nearestChar = char
						end
					end
				end

				if nearest and nearestDist < detectionRadius then
					local playerInSafeZone = nearest.Position.X >= safeZone.xMin and nearest.Position.X <= safeZone.xMax and nearest.Position.Z >= safeZone.zMin and nearest.Position.Z <= safeZone.zMax

					local dir = (nearest.Position - torso.Position).Unit
					local moveDist = speed * task.wait()
					local newPos = torso.Position + dir * moveDist

					-- Raycast to avoid walking through walls
					raycastFilter.FilterDescendantsInstances = { monster }
					local wallHit = workspace:Raycast(torso.Position, dir * (moveDist + 1), raycastFilter)
					if wallHit then
						local hitDist = (wallHit.Position - torso.Position).Magnitude
						if hitDist < moveDist + 0.5 then
							-- Wall is close — slide along it
							local slideDir = wallHit.Normal:Cross(Vector3.new(0, 1, 0))
							local slidePos = torso.Position + slideDir * moveDist
							if not workspace:Raycast(torso.Position, slideDir * (moveDist + 1), raycastFilter) then
								newPos = slidePos
							else
								-- Can't slide either, try the other direction
								slideDir = -slideDir
								slidePos = torso.Position + slideDir * moveDist
								if not workspace:Raycast(torso.Position, slideDir * (moveDist + 1), raycastFilter) then
									newPos = slidePos
								else
									newPos = torso.Position -- stuck, don't move
								end
							end
						end
					end

					-- Blocked from entering ElevatorLobby (safe zone)
					if newPos.X >= safeZone.xMin and newPos.X <= safeZone.xMax and newPos.Z >= safeZone.zMin and newPos.Z <= safeZone.zMax then
						-- Don't move into safe zone — stop at the edge
					else
						monster:SetPrimaryPartCFrame(CFrame.lookAt(newPos, nearest.Position))
					end

					if not playerInSafeZone and nearestDist < catchRadius then
						caughtPlayers[nearestChar] = true
						local lobby = workspace:FindFirstChild("Lobby")
						local spawn = lobby and lobby:FindFirstChildOfClass("SpawnLocation")
						local cf = spawn and spawn.CFrame + Vector3.new(0, 3, 0) or CFrame.new(0, 1003, 0)
						nearestChar.HumanoidRootPart.CFrame = cf
					end
				else
					task.wait(0.1)
				end
			end)

			hunterState[floor] = { monster = monster, conn = conn }
		end,
		revert = function(floor)
			local state = hunterState[floor]
			if state then
				if state.conn then state.conn:Disconnect() end
				if state.monster then state.monster:Destroy() end
				hunterState[floor] = nil
			end
		end,
	},
}

local function rollPanicType()
	local names = {}
	for name, _ in pairs(panicFloors) do
		table.insert(names, name)
	end
	return names[math.random(1, #names)]
end

local function applyPanic(panicType, floor)
	local pf = panicFloors[panicType]
	if pf then
		print("Panic floor: " .. pf.label)
		pf.apply(floor)
	end
end

return { swapAnomaly = swapAnomaly, revertAll = revertAll, resetUsed = resetUsed, hideAllReplacements = hideAllReplacements, panicFloors = panicFloors, applyPanic = applyPanic, rollPanicType = rollPanicType, PANIC_CHANCE = PANIC_CHANCE }
