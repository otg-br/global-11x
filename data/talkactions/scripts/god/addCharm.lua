function onSay(player, word, param)
	if player:getGroup():getId() < 3 then
		return true
	end
	
	if player:getGroup():getId() < 6 then
		return true
	end

	local split = param:splitTrimmed(",")
	if split[2] == nil or not tonumber(split[2]) then
		player:sendCancelMessage("Insufficient parameters.")
		return false
	end

	local target = Player(split[1])
	if target == nil then
		player:sendCancelMessage("A player with that name is not online.")
		return false
	end


	local points = target:getCharmPoints() + tonumber(split[2])
	target:setCharmPoints(points)
	player:sendTextMessage(MESSAGE_EVENT_DEFAULT, string.format("Você adicionou charm points para o jogador %s", target:getName()))
	return false
end
