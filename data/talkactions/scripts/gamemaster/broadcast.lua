function onSay(player, words, param)
	if(not player:getGroup():getAccess()) or player:getAccountType() < ACCOUNT_TYPE_GOD then
		return true
	end
	
	if player:getGroup():getId() < 4 then return true end
	
	if(param == "") then
		player:sendCancelMessage("Command param required.")
		return false
	end

	Game.sendConsoleMessage("> " .. player:getName() .. " broadcasted: \"" .. param .. "\".", CONSOLEMESSAGE_TYPE_INFO)
	for _, targetPlayer in ipairs(Game.getPlayers()) do
		targetPlayer:sendPrivateMessage(player, param, TALKTYPE_BROADCAST)
	end
	return false
end
