local altares = {
	[1] = {position = Position(32591, 32629, 9)},
	[2] = {position = Position(32591, 32621, 9)},
	[3] = {position = Position(32602, 32629, 9)},
	[4] = {position = Position(32602, 32621, 9)},
}

local blockedItem = 33793

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return true
	end
	local tPos = target:getPosition()
	for _, altar in pairs(altares) do
		if tPos == altar.position then
			local checkTile = Tile(altar.position):getItemById(blockedItem)
			if not checkTile then
				item:remove(1)
				Game.createItem(blockedItem, 1, altar.position)
				tPos:sendMagicEffect(CONST_ME_POFF)
				player:say('**placing idol**', TALKTYPE_MONSTER_SAY)
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is already an idol here. Try another altar.")
			end
		end
	end
	return true
end
