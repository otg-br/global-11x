function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	
	--Banuta
	if player:getPosition().x > 32805 and player:getPosition().x < 32813 then
		if player:getPosition().y > 32579 and player:getPosition().y < 32587 and player:getPosition().z == 7 then
			if player:getStorageValue(50736) == -1 then
				player:getPosition():sendMagicEffect(50)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You remove the curse that was put on this statue.")
				player:setStorageValue(Storage.CurseSpreads.roteiroquest, player:getStorageValue(Storage.CurseSpreads.roteiroquest) + 1)
				player:setStorageValue(50736, 1)
			end
		end
	end
	
	--Vengoth
	if player:getPosition().x > 32947 and player:getPosition().x < 32951 then
		if player:getPosition().y > 31486 and player:getPosition().y < 31490 and player:getPosition().z == 6 then
			if player:getStorageValue(50737) == -1 then
				player:getPosition():sendMagicEffect(50)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You remove the curse that was put on this statue.")
				player:setStorageValue(Storage.CurseSpreads.roteiroquest, player:getStorageValue(Storage.CurseSpreads.roteiroquest) + 1)
				player:setStorageValue(50737, 1)
			end
		end
	end
	
	--Krailos
	if player:getPosition().x > 33673 and player:getPosition().x < 33677 then
		if player:getPosition().y > 31623 and player:getPosition().y < 31627 and player:getPosition().z == 7 then
			if player:getStorageValue(50738) == -1 then
				player:getPosition():sendMagicEffect(50)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You remove the curse that was put on this statue.")
				player:setStorageValue(Storage.CurseSpreads.roteiroquest, player:getStorageValue(Storage.CurseSpreads.roteiroquest) + 1)
				player:setStorageValue(50738, 1)
			end
		end
	end
	
	return true
end