function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(Storage.secretLibrary.Asuras.Questline) < 2 then
		if item.itemid == 33043 then
			if target.itemid == 33041 then
				item:remove(1)
				target:remove(1)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You attach the ebony wood to the skull. This should meet the requirements of a fingerboard.')
				player:addItem(33044)
			end
		elseif item.itemid == 33044 then
			if target.itemid == 33042 then
				item:remove(1)
				target:remove(1)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You tack the hair to the ebony fingerboard. The strands should be adquate to serve as strings.')
				player:addItem(33045)
				player:setStorageValue(Storage.secretLibrary.Asuras.Questline, 2)
			end
		end
	end
	if item.itemid == 33045 then
		if player:getStorageValue(Storage.secretLibrary.Asuras.Questline) == 2 then
			if player:getPosition():isInRange(Position(32807, 32762, 10), Position(32809, 32768, 10)) then
				player:setStorageValue(Storage.secretLibrary.Asuras.Questline, 3)
			end 
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, '*There was once a maiden fair, with dark eyes and silken hair. Far away from home she died. No grave, no wake, no mourning.*')
			player:getPosition():sendMagicEffect(CONST_ME_SOUND_PURPLE)
		elseif player:getStorageValue(Storage.secretLibrary.Asuras.Questline) == 4 then
			if player:getPosition():isInRange(Position(32807, 32762, 10), Position(32809, 32768, 10)) then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You are playing the Peacock Ballad and the portal opens.')
				player:setStorageValue(Storage.secretLibrary.Asuras.Questline, 5)
				player:getPosition():sendMagicEffect(CONST_ME_SOUND_WHITE)
				return true
			end
		elseif player:getStorageValue(Storage.secretLibrary.Asuras.Questline) >= 5 then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You are playing the bone fiddle.')
			player:getPosition():sendMagicEffect(CONST_ME_SOUND_WHITE)			
		end
	end
	return true
end