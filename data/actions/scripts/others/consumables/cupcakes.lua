function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.itemid == 31719 then
		if player:getStorageValue(item.itemid) < os.stime() then
			player:addMana(math.max(1, player:getMaxMana() - player:getMana()))
			player:say("Hmmmmm!", TALKTYPE_MONSTER_SAY)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your mana was refilled completely.")
			player:sendWaste(item:getId())
			item:remove(1)
			player:setStorageValue(item.itemid, os.stime() + 15*60)
		else
			player:sendCancelMessage("You are exhausted.")
		end
	elseif item.itemid == 31720 then
		if	player:getStorageValue(item.itemid) < os.stime() then
			player:addHealth(math.max(1, player:getMaxHealth() - player:getHealth()))
			player:say("Hmmmmm!", TALKTYPE_MONSTER_SAY)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your health was refilled completely.")
			player:setStorageValue(item.itemid, os.stime() + 15*60)
			item:remove(1)
		else
			player:sendCancelMessage("You are exhausted.")
		end
	end
	return true
end
