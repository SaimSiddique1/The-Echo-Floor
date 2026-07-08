-- AnomalySwapper.luau (ModuleScript)
-- Exports: swapAnomaly() — picks one anomaly (swap or behavior), returns name

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnomalyConfig = require(ReplicatedStorage.Shared.AnomalySwapConfig)
local SwapConfig = AnomalyConfig.swapConfig
local Behaviors = require(ReplicatedStorage.Shared.AnomalyBehavior)

local FLOOR_SURFACE_Y = 0.5
local usedAnomalies = {}
local activeBehaviorName = nil
local multiSwapGroups = {
	AllPlates = { "Plate1", "Plate2", "Plate3", "Plate4", "Plate5", "Plate6" },
}

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

return { swapAnomaly = swapAnomaly, revertAll = revertAll, resetUsed = resetUsed, hideAllReplacements = hideAllReplacements }
