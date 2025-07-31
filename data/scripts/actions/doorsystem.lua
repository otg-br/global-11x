local doorSystem = Action()
local doorIds = {}
local ClosedIds = {}

for _, v in ipairs(globalDoors) do
	if not table.contains(doorIds, v) then
		table.insert(doorIds, v)
	end
	local door = Door(v)
	if not table.contains(ClosedIds, v) and door and door:isSpecial() and door:isOpened() then
		table.insert(ClosedIds, v)
	end

end

for _, v in ipairs(keysDoor) do
	if not table.contains(doorIds, v) then
		table.insert(doorIds, v)
	end
end

function doorSystem.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local itemid = item:getId()
	local door = Door(itemid)
	-- keys
	if table.contains(keysDoor, itemid) then
		if target.actionid > 0 then
			door = Door(target.itemid)
			if item.actionid == target.actionid and door then
				target:transform(door:use())
				return true
			end
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "The key does not match.")
			return true
		end
		return false
	end

	-- others system
	if not door then
		Game.sendConsoleMessage(">> Door not found ".. itemid, CONSOLEMESSAGE_TYPE_WARNING)
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "Its locked.")
		return false
	end

	local opened = door:isOpened()
	local usedDoor = door:use()
	if not opened then
		if door:isQuest() then
			if player:getStorageValue(item.actionid) ~= -1 then
				item:transform(usedDoor)
				player:teleportTo(toPosition, true)
			else
				player:sendTextMessage(MESSAGE_INFO_DESCR, "The door seems to be sealed against unwanted intruders.")
			end
			return true
		elseif door:isLevel() then
			if item.actionid > 0 and player:getLevel() >= item.actionid - 1000 then
				item:transform(usedDoor)
				player:teleportTo(toPosition, true)
			else
				player:sendTextMessage(MESSAGE_INFO_DESCR, "Only the worthy may pass.")
			end
			return true
		end
	else
		local doorCreature = Tile(toPosition):getTopCreature()
		if doorCreature then
			-- checando vertical doors
			local query = RETURNVALUE_NOTENOUGHROOM
			local teleportPosition = toPosition
			if door:isVertical() then
				local possiveisLocais = {
					{x = toPosition.x + 1, y = toPosition.y, z = toPosition.z},
					{x = toPosition.x - 1, y = toPosition.y, z = toPosition.z},
				}
				for i = 1, #possiveisLocais do
					query = Tile(Position(possiveisLocais[i])):queryAdd(doorCreature, bit.bor(FLAG_IGNOREBLOCKCREATURE, FLAG_PATHFINDING))
					if query == RETURNVALUE_NOERROR then
						toPosition = Position(possiveisLocais[i])
						break
					end
				end
			else
				local possiveisLocais = {
					{x = toPosition.x, y = toPosition.y + 1, z = toPosition.z},
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

		if not door:isSpecial() then
			item:transform(usedDoor)
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

	if door then
		if item.actionid == 0 then
			item:transform(usedDoor)
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR, "It is locked.")
		end
		return true
	end

	return true
end

for _, door in ipairs(doorIds) do
	doorSystem:id(door)
end

doorSystem:register()


local doorMovements = MoveEvent()
doorMovements:type("stepout")

function doorMovements.onStepOut(creature, item, position, fromPosition)
	local tile = position:getTile()
	if tile:getCreatureCount() > 0 then
		return true
	end

	local newPosition = {x = position.x + 1, y = position.y, z = position.z}
	local query = Tile(newPosition):queryAdd(creature)
	if query ~= RETURNVALUE_NOERROR or query == RETURNVALUE_NOTENOUGHROOM then
		newPosition.x = newPosition.x - 1
		newPosition.y = newPosition.y + 1
		query = Tile(newPosition):queryAdd(creature)
	end

	if query == RETURNVALUE_NOERROR or query ~= RETURNVALUE_NOTENOUGHROOM then
		tile:relocateTo(newPosition)
	end

	local i, tileItem, tileCount = 1, true, tile:getThingCount()
	while tileItem and i < tileCount do
		tileItem = tile:getThing(i)
		if tileItem and tileItem.uid ~= item.uid and tileItem:getType():isMovable() then
			tileItem:remove()
		else
			i = i + 1
		end
	end

	local door = Door(item.itemid)

	item:transform(door and door:use(item.itemid) or item.itemid - 1)
	return true
end

for _, door in ipairs(ClosedIds) do
	doorMovements:id(door)
end

doorMovements:register()
