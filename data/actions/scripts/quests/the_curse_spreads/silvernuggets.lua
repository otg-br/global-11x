function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 23942 then
		item:remove(1)
		player:addItem(30682)
		toPosition:sendMagicEffect(CONST_ME_POFF)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You grind the silver nuggets into fine, shimmering dust.")
	else
		return false
	end
	return true
end