function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local itemId = item:getId()
	if table.contains(questDoors, itemId) then
		if player:getStorageValue(item.actionid) ~= -1 then
			item:transform(itemId + 1)
			player:teleportTo(toPosition, true)
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR, "The door seems to be sealed against unwanted intruders.")
		end
		return true
	elseif table.contains(levelDoors, itemId) then
		if item.actionid > 0 and player:getLevel() >= item.actionid - 1000 then
			item:transform(itemId + 1)
			player:teleportTo(toPosition, true)
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Only the worthy may pass.")
		end
		return true
	elseif table.contains(keys, itemId) then
		if target.actionid > 0 then
			if item.actionid == target.actionid and doors[target.itemid] then
				target:transform(doors[target.itemid])
				return true
			end
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "The key does not match.")
			return true
		end
		return false
	end

	if table.contains(horizontalOpenDoors, itemId) or table.contains(verticalOpenDoors, itemId) then
		local doorCreature = Tile(toPosition):getTopCreature()
		if doorCreature then
			-- checando vertical doors
			local query = RETURNVALUE_NOTENOUGHROOM
			local teleportPosition = toPosition
			if table.contains(verticalOpenDoors, itemId) then
				local possiveisLocais = {
					{x = toPosition.x + 1, y = toPosition.y, z = toPosition.z},
					-- {x = toPosition.x + 1, y = toPosition.y - 1, z = toPosition.z},
					-- {x = toPosition.x + 1, y = toPosition.y + 1, z = toPosition.z},
					{x = toPosition.x - 1, y = toPosition.y, z = toPosition.z},
				}
				for i = 1, #possiveisLocais do
					query = Tile(Position(possiveisLocais[i])):queryAdd(doorCreature, bit.bor(FLAG_IGNOREBLOCKCREATURE, FLAG_PATHFINDING))
					if query == RETURNVALUE_NOERROR then
						toPosition = Position(possiveisLocais[i])
						break
					end
				end
			end

			if table.contains(horizontalOpenDoors, itemId) then
				local possiveisLocais = {
					{x = toPosition.x, y = toPosition.y + 1, z = toPosition.z},
					-- {x = toPosition.x - 1, y = toPosition.y + 1, z = toPosition.z},
					-- {x = toPosition.x + 1, y = toPosition.y + 1, z = toPosition.z},
					{x = toPosition.x, y = toPosition.y -1, z = toPosition.z},
				}
				for i = 1, #possiveisLocais do
					query = Tile(Position(possiveisLocais[i])):queryAdd(doorCreature, bit.bor(FLAG_IGNOREBLOCKCREATURE, FLAG_PATHFINDING))
					if query == RETURNVALUE_NOERROR then
						toPosition = Position(possiveisLocais[i])
						break
					end
				end
			end


			if query ~= RETURNVALUE_NOERROR then
				player:sendTextMessage(MESSAGE_STATUS_SMALL, Game.getReturnMessage(query))
				return true
			end

			doorCreature:teleportTo(toPosition, true)
		end

		if not table.contains(openSpecialDoors, itemId) then
			item:transform(itemId - 1)
			local removable = {1497, 1499}
			for i = 1, #removable do
				local willRemove = Tile(item:getPosition()):getItemById(removable[i])
				if willRemove then
					willRemove:remove(1)
				end
			end
		end

		return true
	end

	if doors[itemId] then
		if item.actionid == 0 then
			item:transform(doors[itemId])
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR, "It is locked.")
		end
		return true
	end
	return false
end
