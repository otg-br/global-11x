function onStepIn(creature, item, position, fromPosition)
	if item.itemid == 27718 or item.itemid == 27717 then
		--black vixen
		if item:getPosition().x == 33446 and item:getPosition().y == 32040 and item:getPosition().z == 9 then
			creature:teleportTo(Position(33442, 32052, 9), true)
			creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		--shadowpelt
		elseif item:getPosition().x == 33395 and item:getPosition().y == 32111 and item:getPosition().z == 9 then
			creature:teleportTo(Position(33403, 32097, 9), true)
			creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		--sharpclaw
		elseif item:getPosition().x == 33120 and item:getPosition().y == 31996 and item:getPosition().z == 9 then
			creature:teleportTo(Position(33128, 31972, 9), true)
			creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		--darkfang
		elseif item:getPosition().x == 33055 and item:getPosition().y == 31888 and item:getPosition().z == 9 then
			creature:teleportTo(Position(33055, 31911, 9), true)
			creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		--bloodback
		elseif item:getPosition().x == 33180 and item:getPosition().y == 32011 and item:getPosition().z == 8 then
			creature:teleportTo(Position(33167, 31978, 8), true)
			creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		end
	elseif item.itemid == 27715 or item.itemid == 27716 then
		if creature:getStorageValue(Storage.CurseSpreads.roteiroquest) >= 17 then
			if item:getPosition().x == 33429 and item:getPosition().y == 32083 and item:getPosition().z == 9 then
				creature:teleportTo(Position(33065, 31977, 9), true)
				creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			elseif item:getPosition().x == 33064 and item:getPosition().y == 31977 and item:getPosition().z == 9 then
				creature:teleportTo(Position(33429, 32082, 9), true)
				creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			end
		else
			creature:sendTextMessage(MESSAGE_STATUS_SMALL, "You're not ready to access this portal.")
			creature:teleportTo(fromPosition, true)
		end
	end
	
	return true
end
