function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if toPosition == Position(32177, 31925, 7) then
		if player:getLevel() >= 250 then
		--if player:getStorageValue(Storage.secretLibrary.libraryPermission) == 1 then
			player:teleportTo(Position(32517, 32537, 12))
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		--end
		end
	end
	return onUseScythe(player, item, fromPosition, target, toPosition, isHotkey)
end
