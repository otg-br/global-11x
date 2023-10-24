local doors = {
	[1] = {doorPosition = Position(32963, 32319, 9), storage = Storage.secretLibrary.Darashia.puzzleSqm, nivel = 40},
	[2] = {doorPosition = Position(32955, 32304, 9), storage = Storage.secretLibrary.Darashia.puzzleSqm, nivel = 40},
	[3] = {doorPosition = Position(32984, 32314, 9), storage = Storage.secretLibrary.Darashia.secondChest, nivel = 1},
	[4] = {doorPosition = Position(32968, 32324, 9), storage = Storage.secretLibrary.Darashia.secondChest, nivel = 1},
	[5] = {doorPosition = Position(32978, 32290, 10), storage = Storage.secretLibrary.Darashia.eatenFood, nivel = 1},	
	[6] = {doorPosition = Position(32963, 32297, 8), storage = Storage.secretLibrary.Darashia.Questline, nivel = 7},
	[7] = {doorPosition = Position(32963, 32299, 8), storage = Storage.secretLibrary.Darashia.Questline, nivel = 7},
	[8] = {doorPosition = Position(32963, 32301, 8), storage = Storage.secretLibrary.Darashia.Questline, nivel = 7},
	[9] = {doorPosition = Position(32963, 32303, 8), storage = Storage.secretLibrary.Darashia.Questline, nivel = 7},
	
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for _, p in pairs(doors) do
		if (item:getPosition() == p.doorPosition) and not(Tile(item:getPosition()):getTopCreature()) 
			and isInArray({9277, 9279, 22821}, item.itemid)then
			if player:getStorageValue(p.storage) >= p.nivel then
				player:teleportTo(toPosition, true)
				item:transform(item.itemid + 1)
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'The door seems to be sealed against unwanted intruders.')
			end	
		end
	end
	return true
end



