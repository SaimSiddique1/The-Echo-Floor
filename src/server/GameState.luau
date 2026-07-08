local bindable = Instance.new("BindableEvent")

local state = {
	gameInProgress = false,
	spectators = {},
	currentGamePlayers = {},
	gameEnded = bindable.Event,
	fireGameEnded = function(...) bindable:Fire(...) end,
}

return state
