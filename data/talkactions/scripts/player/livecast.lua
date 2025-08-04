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
	elseif player:stopLiveCast(password) then
		player:say("CAST OFF", TALKTYPE_MONSTER_SAY)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:sendTextMessage(MESSAGE_INFO_DESCR, "You have stopped casting your gameplay.")
	end
	return false
end