function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player:getStorageValue(Storage.TheInquisition.Antiabuse) < 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Abusar de bug pode te fazer ser banido. :)")
		player:teleportTo(Position(32328, 32272, 7))
		return true
	end
	
	if not player or player:getStorageValue(Storage.TheInquisition.RewardRoomText) == 1 then
		return true
	end

	player:setStorageValue(Storage.TheInquisition.RewardRoomText, 1)
	player:say('You can choose exactly one of these chets. Choose wisely!', TALKTYPE_MONSTER_SAY, false, player)
	return true
end
