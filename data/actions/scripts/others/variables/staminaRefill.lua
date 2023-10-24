local fullStamina = 42*60

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.actionid < 100 then
		-- função comum do item (caso forem adicionar o evento dele)
	else
		if (player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT) or player:isPzLocked()) 
		and not (Tile(player:getPosition()):hasFlag(TILESTATE_PROTECTIONZONE)) then
			player:sendCancelMessage("You can't use this when you're in a fight.")
			return true
		end
		if player:getStamina() >= fullStamina then
			player:sendCancelMessage("Your stamina is already full.")
		elseif player:getStorageValue(STAMINA_REFILL_TIME) > os.stime() then
			player:sendCancelMessage("You must wait 20 hours to fully refill your stamina again.")
		else
			player:setStamina(fullStamina)
			player:say("Your stamina has been fully refilled.", TALKTYPE_MONSTER_SAY)	
			player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
			player:setStorageValue(STAMINA_REFILL_TIME, os.stime() + 20 * 60 * 60)
			item:remove(1)
		end
	end
	return true
end
