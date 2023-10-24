local positions = {
	Position(33100, 32379, 10),
	Position(33100, 32375, 10),
	Position(33102, 32375, 10),
	Position(33102, 32379, 10)
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not isInArray(positions, target:getPosition()) then return true end
	if player:getStorageValue(Storage.GravediggerOfDrefia.Mission17) == 1 and player:getStorageValue(Storage.GravediggerOfDrefia.Mission19) < 1 then
		player:setStorageValue(Storage.GravediggerOfDrefia.Mission19, 1)
		player:addItem(21406, 1)
		item:remove()
	end
	return true
end
