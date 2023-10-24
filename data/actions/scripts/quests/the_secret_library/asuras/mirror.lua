local goPos = Position(32814, 32754, 9)

function onUse(player, item, fromPosition, itemEx, toPosition)
    if player:getStorageValue(Storage.secretLibrary.Asuras.flammingOrchid) >= 1 and player:getStorageValue(Storage.secretLibrary.Asuras.Questline) >= 1 then		
		if player:getLevel() >= 250 then					
			player:teleportTo(goPos)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		else
			player:sendCancelMessage('You do not have enough level.')
		end
	else
		player:sendCancelMessage('You do not have permission.')
	end
end
