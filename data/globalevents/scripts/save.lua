local config = {
	broadcast = {30, 120},
	delay = 120,
	events = 30
}

local function executeSave(seconds)
	if isInArray(config.broadcast, seconds) then
		Game.broadcastMessage("Server save within " .. seconds .. " seconds, please mind it may freeze!")
	end

	if(seconds > 0) then
		addEvent(executeSave, config.events * 1000, seconds - config.events)
	else
		saveServer()
	end
end

function onThink(interval)
	executeSave(config.delay)
	return true
end