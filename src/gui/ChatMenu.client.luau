-- ChatMenu.client.luau (DEPRECATED)
-- Chat phase has been replaced by silent 5s intermission.
-- This script remains for compatibility only — does nothing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes

Remotes.RoundChatStart.OnClientEvent:Connect(function() end)
Remotes.RevealResults.OnClientEvent:Connect(function() end)
Remotes.RoundStart.OnClientEvent:Connect(function() end)
Remotes.FloorReset.OnClientEvent:Connect(function() end)
