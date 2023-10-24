function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(Storage.ForgottenKnowledge.GirlPicture) >= 1 then
		return false
	end
	if target.actionid == 24875 then
		player:setStorageValue(Storage.ForgottenKnowledge.GirlPicture, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'Seems that an old silver key appears in the drower.')
		item:remove()
	else
		return false
	end
	return true
end
