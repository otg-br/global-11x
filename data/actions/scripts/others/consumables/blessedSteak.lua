function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:addMana(math.max(1,player:getMaxMana() - player:getMana()))
	player:say("Chomp.", TALKTYPE_MONSTER_SAY)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your mana was refilled completely.")
	player:sendWaste(item:getId())
	item:remove(1)
	return true
end
