function onSay(player, words, param)
	if player:getStorageValue(Storage.CastDelay) > os.stime() then
		player:sendCancelMessage("You are exhausted.")
		return false
	end

	player:setStorageValue(Storage.CastDelay, os.stime() + 10)
	
	local password = ""
	local command = string.lower(param)
	
	if command == "on" or command == "off" then
		password = ""
	elseif string.find(command, "on ") then
		password = string.sub(param, 4)
	elseif string.find(command, "off ") then
		password = string.sub(param, 5)
	else
		password = param
	end
	
	if player:startLiveCast(password) then
		player:say("CAST ON", TALKTYPE_MONSTER_SAY)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		player:sendTextMessage(MESSAGE_INFO_DESCR, "You have started casting your gameplay.")
		
		player:sendTextMessage(MESSAGE_STATUS_DEFAULT, 
			"[Cast System] Cast opened! Permanent 5% XP bonus activated!")
		
		player:sendChannelMessage("", "[CAST SYSTEM] Cast opened! Permanent 5% XP bonus activated!", 
			TALKTYPE_CHANNEL_O, 0xFFFE)
	elseif player:stopLiveCast(password) then
		player:say("CAST OFF", TALKTYPE_MONSTER_SAY)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:sendTextMessage(MESSAGE_INFO_DESCR, "You have stopped casting your gameplay.")
		
		local playerId = player:getId()
		if CAST_BONUS_STATUS and CAST_BONUS_STATUS[playerId] then
			CAST_BONUS_STATUS[playerId] = nil
			player:sendTextMessage(MESSAGE_STATUS_DEFAULT, 
				"[Cast System] Cast closed! 5% XP bonus deactivated!")
			
			player:sendChannelMessage("", "[CAST SYSTEM] Cast closed! XP bonus deactivated!", 
				TALKTYPE_CHANNEL_O, 0xFFFE)
		end
	end
	return false
end