local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = ReplicatedStorage.Remotes
local CosmeticConfig = require(ReplicatedStorage.Shared.CosmeticConfig)
local LeaderboardService = require(script.Parent.LeaderboardService)

Remotes.BuyCosmetic.OnServerEvent:Connect(function(player, cosmeticId)
	if not player or type(cosmeticId) ~= "string" then return end
	if not CosmeticConfig.getById(cosmeticId) then return end

	local success, msg = LeaderboardService.buyCosmetic(player, cosmeticId)
	Remotes.BuyCosmetic:FireClient(player, success, msg)
end)

Remotes.EquipCosmetic.OnServerEvent:Connect(function(player, cosmeticId)
	if not player or type(cosmeticId) ~= "string" then return end

	local success, msg = LeaderboardService.equipCosmetic(player, cosmeticId)
	Remotes.EquipCosmetic:FireClient(player, success, cosmeticId)
end)

Remotes.BuyEchoPing.OnServerEvent:Connect(function(player)
	if not player then return end

	local success, msg = LeaderboardService.buyEchoPing(player)
	Remotes.BuyEchoPing:FireClient(player, success, msg)
end)

Remotes.GetShopData.OnServerInvoke = function(player)
	if not player then return {} end

	local data = LeaderboardService.getPlayerData(player)
	return {
		coins = data.coins or 0,
		ownedCosmetics = data.ownedCosmetics or {"classic"},
		equippedCosmetic = data.equippedCosmetic or "classic",
		echoPings = data.echoPings or 0,
	}
end

return true
