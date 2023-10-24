local function ServerSave()
	Game.setGameState(GAME_STATE_CLOSED)

	setGlobalStorageValueDB(GlobalStorage.LastServerSave, os.time()) -- needed for the daily reward system

	local pc = 0
	for i, player in pairs(Game.getPlayers()) do
		player:remove()
		pc = pc + 1
	end
	print(string.format(">> %d player%s kickado%s", pc, pc > 1 and 's' or '', pc > 1 and 's' or ''))
	Game.setGameState(GAME_STATE_SHUTDOWN)

end

local function ServerSaveWarning(time)
	local remaningTime = tonumber(time) - 60000

	Game.broadcastMessage("Server is saving game in " .. (remaningTime/60000) .."  minute(s). Please logout.", MESSAGE_STATUS_WARNING)

	if remaningTime > 60000 then
		addEvent(ServerSaveWarning, 60000, remaningTime)
	else
		addEvent(ServerSave, 60000)
	end
end

function onTime(interval)
	local remaningTime = 5 * 60000

	Game.broadcastMessage("Server is saving game in " .. (remaningTime/60000) .."  minute(s). Please logout.", MESSAGE_STATUS_WARNING)

	addEvent(ServerSaveWarning, 60000, remaningTime)
	return not true
end
