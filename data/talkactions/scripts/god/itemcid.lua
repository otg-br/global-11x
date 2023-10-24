function onSay(player, word, param)
	local group = player:getGroup():getId()
	if group < 5 then
		return true
	end
	if player:getGroup():getId() < 6 then
		return true
	end
	
	local split = param:split(",")
	local id = tonumber(split[1])
	if not id then
		player:sendCancelMessage("ID não existe")
		return false
	end
	local it = Game.getItemIdByClientId(id)
	if split[2] then
		Game.createItem(it:getId(), 1, player:getPosition())
	end
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("O item com client id %d tem o server id: %d", id, it:getId()))

	return false
end