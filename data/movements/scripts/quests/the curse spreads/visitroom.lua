local t = {
	Position(33346, 32073, 10), -- stone position
	Position(33349, 32073, 10), -- teleport creation position
	Position(33352, 32073, 10) -- where the teleport takes you
}

function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 8 then
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 9)
		local fromPos = {x = 33344, y = 32071, z = 10}
		local toPos = 	{x = 33354, y = 32075, z = 10}
		local x, y, z
		for z = fromPos.z, toPos.z do
			for x = fromPos.x, toPos.x do
				for y = fromPos.y, toPos.y do
					local item2 = Position(x,y,z):getTile():getItemById(11030)
					local stone = Position(x,y,z):getTile():getItemById(31952)
					
					if stone then
						stone:transform(31948)
					end
					
					if item2 then
						item2:transform(11450)
					end
					
				end
			end
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The clean water changes as soon as it flows into the basin. Obviously this is the spot where Cormaya's water gets tainted.")
		
	elseif player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 13 then
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 14)
		local fromPos = {x = 33344, y = 32071, z = 10}
		local toPos = 	{x = 33354, y = 32075, z = 10}
		local x, y, z
		for z = fromPos.z, toPos.z do
			for x = fromPos.x, toPos.x do
				for y = fromPos.y, toPos.y do
					local item = Position(x,y,z):getTile():getItemById(11450)
					local statue = Position(x,y,z):getTile():getItemById(31948)
					
					if statue then
						statue:transform(31952)
					end
					
					if item then
						item:transform(11030)
					end
					
				end
			end
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The water that flows into the basin stays fresh and clean now. Obviously the curse is lifted.")
	end
	return true
end