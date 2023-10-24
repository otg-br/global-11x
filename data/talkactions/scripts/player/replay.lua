function onSay(player, word, param)
	param = param:lower()
	if param == "start" then
		if not player:startReplay() then
			player:sendCancelMessage("You are already recording.")
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Your recording has started. Use '!replay stop' to stop.")
		end
	elseif param == "stop" then
		if not player:stopReplay() then
			player:sendCancelMessage("You are not recording.")
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Your recording was a success.")
		end
	end

	return false
end