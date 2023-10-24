local wallIds = {1025, 1026, 1027, 1028, 1029}

function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local fromPos = Position(32760, 32288, 14)
	local toPos = Position(32764, 32292, 14)
	
	local nextPosition = Position(32852, 32287, 14)
	
	local blockTeleport = false
	
	

	for x = fromPos.x, toPos.x do
		for y = fromPos.y, toPos.y do
			local tile = Tile(Position(x, y, 14))
			for i = 1, #wallIds do
				local wall = tile:getItemById(wallIds[i])
				if wall then
					blockTeleport = true
				end
			end
		end
	end

	if not blockTeleport then
		player:teleportTo(nextPosition)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	end
	
	return true
end