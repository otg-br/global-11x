local doors = {
	[1] = {doorPosition = Position(33246, 32122, 8), storage = Storage.secretLibrary.MoTA.Questline, nivel = 2},
	[2] = {doorPosition = Position(33208, 32071, 8), storage = Storage.secretLibrary.MoTA.leverPermission, nivel = 1},
	[3] = {doorPosition = Position(33208, 32074, 8), storage = Storage.secretLibrary.MoTA.leverPermission, nivel = 1},
	[4] = {doorPosition = Position(33341, 32117, 10), storage = Storage.secretLibrary.MoTA.finalBasin, nivel = 1},
	[5] = {doorPosition = Position(33344, 32120, 10), storage = Storage.secretLibrary.MoTA.skullSample, nivel = 1}
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for _, p in pairs(doors) do
		if (item:getPosition() == p.doorPosition) and not(Tile(item:getPosition()):getTopCreature()) then
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



