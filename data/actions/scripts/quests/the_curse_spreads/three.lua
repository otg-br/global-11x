function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(50730) == -1 then
		player:setStorageValue(50730, 1)
		player:addItem(30695, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You pluck a tuft of shadow bite.")
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "At the moment you canot pluck shadow bite here.")
	end
	return true
end
