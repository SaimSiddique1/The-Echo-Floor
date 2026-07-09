local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local AnomalyConfig = require(script.Parent.AnomalySwapConfig)

local function roomCenter(roomName)
	local bounds = AnomalyConfig.roomBounds[roomName]
	if not bounds then return Vector3.new(0, 3, 0) end
	return Vector3.new((bounds.xMin + bounds.xMax) / 2, 3, (bounds.zMin + bounds.zMax) / 2)
end

local function makeSpatialSound(floor, roomName, soundId, volume, looped, playbackType)
	local part = Instance.new("Part")
	part.Name = "AnomalyAudioSource_" .. roomName
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Position = roomCenter(roomName)
	part.Parent = floor

	local s = Instance.new("Sound")
	s.Name = "AnomalyAudio"
	s.SoundId = soundId
	s.Volume = volume
	s.Looped = looped
	s.RollOffMode = Enum.RollOffMode.Linear
	s.RollOffMaxDistance = 30
	s.EmitterSize = 12
	s.Parent = part
	return s, part
end

local function removeSpatialSound(floor, roomName)
	local part = floor:FindFirstChild("AnomalyAudioSource_" .. roomName)
	if part then part:Destroy() end
end

local flipState = {}
local flickerState = {}

local behaviors = {
	-- ========= LIGHTING =========
	KitchenLights = {
		name = "KitchenLights",
		region = "Kitchen",
		type = "Lighting",
		apply = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("PointLight") and v.Parent and v.Parent.Parent == floor then
					local pn = v.Parent.Name or ""
					if pn:find("Light") and pn:find("Kitchen") then
						v.Color = Color3.fromRGB(255, 50, 50)
						v.Brightness = 0.3
					end
				end
			end
		end,
		revert = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("PointLight") then
					v.Color = Color3.fromRGB(255, 240, 210)
					v.Brightness = 0.8
				end
			end
		end,
	},
	HallwayFlicker = {
		name = "HallwayFlicker",
		region = "Hallway",
		type = "Lighting",
		apply = function(floor)
			local fixtures = {}
			for _, v in floor:GetDescendants() do
				if v:IsA("BasePart") and v.Name:find("Hallway") and v.Name:find("_Light") then
					table.insert(fixtures, { part = v, pointLight = v:FindFirstChildOfClass("PointLight") })
				end
			end

			local state = { running = true }
			flickerState[floor] = state

			task.spawn(function()
				local pattern = {
					{ false, 0.08 }, { true, 0.15 }, { false, 0.06 }, { true, 0.1 },
					{ false, 0.12 }, { true, 0.2 }, { false, 0.04 }, { true, 0.08 },
					{ false, 0.1 }, { true, 0.25 }, { false, 0.15 }, { true, 0.3 },
				}
				while state.running do
					for _, step in ipairs(pattern) do
						if not state.running then break end
						local on = step[1]
						local color = on and Color3.fromRGB(255, 245, 230) or Color3.fromRGB(30, 25, 20)
						for _, f in ipairs(fixtures) do
							f.part.Color = color
							if f.pointLight then
								f.pointLight.Enabled = on
							end
						end
						task.wait(step[2])
					end
					if state.running then
						task.wait(0.5)
					end
				end

				for _, f in ipairs(fixtures) do
					if f.part and f.part.Parent then
						if f.pointLight then
							f.pointLight.Enabled = true
						end
					end
				end
			end)
		end,
		revert = function(floor)
			local state = flickerState[floor]
			if state then
				state.running = false
				flickerState[floor] = nil
			end
			for _, v in floor:GetDescendants() do
				if v:IsA("BasePart") and v.Name:find("_Light") then
					v.Color = Color3.fromRGB(255, 245, 230)
				end
				if v:IsA("PointLight") then
					v.Enabled = true
					v.Color = Color3.fromRGB(255, 240, 210)
					v.Brightness = 0.8
				end
			end
		end,
	},
	BedroomDim = {
		name = "BedroomDim",
		region = "Bedroom",
		type = "Lighting",
		apply = function(floor)
			local bounds = AnomalyConfig.roomBounds["Bedroom"]
			for _, v in floor:GetDescendants() do
				if v:IsA("PointLight") and v.Parent and v.Parent:IsA("BasePart") then
					local pos = v.Parent.Position
					if pos.X >= bounds.xMin and pos.X <= bounds.xMax and pos.Z >= bounds.zMin and pos.Z <= bounds.zMax then
						v.Brightness = 0.02
						v.Color = Color3.fromRGB(200, 120, 50)
					end
				end
			end
		end,
		revert = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("PointLight") then
					v.Color = Color3.fromRGB(255, 240, 210)
					v.Brightness = 0.8
				end
			end
		end,
	},
	LivingRoomPulse = {
		name = "LivingRoomPulse",
		region = "LivingRoom",
		type = "Lighting",
		apply = function(floor)
			local lights = {}
			for _, v in floor:GetDescendants() do
				if v:IsA("PointLight") and v.Parent and v.Parent.Parent == floor then
					local pn = v.Parent.Name or ""
					if pn:find("Light") and pn:find("LivingRoom") then
						table.insert(lights, v)
					end
				end
			end
			task.spawn(function()
				local t = 0
				while lights[1] and lights[1].Parent do
					local pulse = 0.4 + 0.4 * math.sin(t * 3)
					for _, l in ipairs(lights) do
						l.Brightness = pulse
					end
					t += task.wait(0.1)
				end
			end)
		end,
		revert = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("PointLight") then
					v.Color = Color3.fromRGB(255, 240, 210)
					v.Brightness = 0.8
				end
			end
		end,
	},
	BathroomGlow = {
		name = "BathroomGlow",
		region = "Bathroom",
		type = "Lighting",
		apply = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("PointLight") and v.Parent and v.Parent.Parent == floor then
					local pn = v.Parent.Name or ""
					if pn:find("Light") and pn:find("Bathroom") then
						v.Color = Color3.fromRGB(100, 220, 180)
						v.Brightness = 0.5
					end
				end
			end
		end,
		revert = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("PointLight") then
					v.Color = Color3.fromRGB(255, 240, 210)
					v.Brightness = 0.8
				end
			end
		end,
	},

	-- ========= AUDIO =========
	HallwayFootsteps = {
		name = "HallwayFootsteps",
		region = "Hallway",
		type = "Audio",
		apply = function(floor)
			local s, part = makeSpatialSound(floor, "Hallway", "rbxassetid://177940988", 0.4, false)
			task.spawn(function()
				while part.Parent do
					s:Play()
					task.wait(0.12)
					s:Stop()
					task.wait(1.5)
				end
			end)
		end,
		revert = function(floor)
			removeSpatialSound(floor, "Hallway")
		end,
	},
	LivingRoomStatic = {
		name = "LivingRoomStatic",
		region = "LivingRoom",
		type = "Audio",
		apply = function(floor)
			local s, _ = makeSpatialSound(floor, "LivingRoom", "rbxassetid://172906410", 0.3, true)
			s:Play()
		end,
		revert = function(floor)
			removeSpatialSound(floor, "LivingRoom")
		end,
	},
	KitchenDrip = {
		name = "KitchenDrip",
		region = "Kitchen",
		type = "Audio",
		apply = function(floor)
			local s, part = makeSpatialSound(floor, "Kitchen", "rbxasset://sounds/button.wav", 0.5, false)
			task.spawn(function()
				while part.Parent do
					s:Play()
					task.wait(1.5)
				end
			end)
		end,
		revert = function(floor)
			removeSpatialSound(floor, "Kitchen")
		end,
	},
	BedroomWhispers = {
		name = "BedroomWhispers",
		region = "Bedroom",
		type = "Audio",
		apply = function(floor)
			local s, _ = makeSpatialSound(floor, "Bedroom", "rbxassetid://9126213743", 0.2, true)
			s:Play()
		end,
		revert = function(floor)
			removeSpatialSound(floor, "Bedroom")
		end,
	},
	BathroomEcho = {
		name = "BathroomEcho",
		region = "Bathroom",
		type = "Audio",
		apply = function(floor)
			local s, part = makeSpatialSound(floor, "Bathroom", "rbxassetid://13061802", 0.25, false)
			task.spawn(function()
				while part.Parent do
					s:Play()
					task.wait(3)
				end
			end)
		end,
		revert = function(floor)
			removeSpatialSound(floor, "Bathroom")
		end,
	},

	-- ========= ARCHITECTURE =========
	HallwayWallShift = {
		name = "HallwayWallShift",
		region = "Hallway",
		type = "Architecture",
		apply = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("BasePart") and v.Name:find("Hallway") and v.Name:find("_W_") then
					if math.random() > 0.7 then
						v.Transparency = 0.75
						v.Color = Color3.fromRGB(180, 160, 140)
					end
				end
			end
		end,
		revert = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("BasePart") and v.Name:find("Hallway") and v.Name:find("_W_") then
					v.Transparency = 0
					v.Color = Color3.fromRGB(240, 235, 225)
				end
			end
		end,
	},
	LivingRoomWallOpen = {
		name = "LivingRoomWallOpen",
		region = "LivingRoom",
		type = "Architecture",
		apply = function(floor)
			local walls = {}
			for _, v in floor:GetDescendants() do
				if v:IsA("BasePart") and v.Name:find("LivingRoom") and v.Name:find("_W_") then
					table.insert(walls, v)
				end
			end
			if #walls > 0 then
				local target = walls[1]
				target.Transparency = 1
				target.CanCollide = false
			end
		end,
		revert = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("BasePart") and v.Name:find("LivingRoom") and v.Name:find("_W_") then
					v.Transparency = 0
					v.CanCollide = true
				end
			end
		end,
	},
	BedroomCeilingOpen = {
		name = "BedroomCeilingOpen",
		region = "Bedroom",
		type = "Architecture",
		apply = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("BasePart") and v.Name == "Bedroom_Ceiling" then
					v.Transparency = 0.9
				end
			end
		end,
		revert = function(floor)
			for _, v in floor:GetDescendants() do
				if v:IsA("BasePart") and v.Name == "Bedroom_Ceiling" then
					v.Transparency = 0
				end
			end
		end,
	},

	-- ========= PARANORMAL =========
	LivingRoomFloat = {
		name = "LivingRoomFloat",
		region = "LivingRoom",
		type = "Paranormal",
		apply = function(floor)
			local bounds = AnomalyConfig.roomBounds["LivingRoom"]
			local ceilingY = 15
			local parts = {}
			for _, v in floor:GetDescendants() do
				if v:IsA("BasePart") and v.Transparency < 0.8 then
					local pos = v.Position
					if pos.X >= bounds.xMin and pos.X <= bounds.xMax and pos.Z >= bounds.zMin and pos.Z <= bounds.zMax then
						local n = v.Name
						if not (n:find("_Floor") or n:find("_W_") or n:find("_Ceiling") or n:find("_Base") or n:find("_Crown") or n:find("_Light")) then
							table.insert(parts, { part = v, origin = v.CFrame })
							local cf = v.CFrame
							local halfHeight = v.Size.Y / 2
							v.Anchored = true
							v.CFrame = CFrame.new(cf.X, ceilingY - halfHeight, cf.Z) * CFrame.Angles(math.rad(180), 0, 0)
						end
					end
				end
			end
			if #parts == 0 then warn("LivingRoomFloat: no parts found") return end
			flipState[floor] = parts
		end,
		revert = function(floor)
			local parts = flipState[floor]
			if parts then
				for _, entry in ipairs(parts) do
					if entry.part and entry.part.Parent then
						entry.part.Anchored = false
						entry.part.CFrame = entry.origin
					end
				end
				flipState[floor] = nil
			end
		end,
	},

}

return behaviors
