local doors = {
	[1] = {doorPosition = Position(32761, 32630, 7), storage = Storage.DreamCourts.UnsafeRelease.Questline, value = 1},
	[2] = {doorPosition = Position(32700, 32244, 9), storage = Storage.DreamCourts.HauntedHouse.Questline, value = 1},
	[3] = {doorPosition = Position(32700, 32255, 9), storage = Storage.DreamCourts.HauntedHouse.Questline, value = 1},
	[4] = {doorPosition = Position(32700, 32275, 8), storage = Storage.DreamCourts.HauntedHouse.Questline, value = 1},
	[5] = {doorPosition = Position(32719, 32264, 8), storage = Storage.DreamCourts.HauntedHouse.Cellar, value = -1}, -- Correto é 1, mas liberei o acesso!!
	[6] = {doorPosition = Position(33088, 32388, 8), storage = Storage.DreamCourts.HauntedHouse.Questline, value = 1},
	[7] = {doorPosition = Position(32606, 32629, 9), storage = Storage.DreamCourts.HauntedHouse.Temple, value = -1, help = "Tomb"},
	[8] = {doorPosition = Position(32671, 32652, 7), storage = Storage.DreamCourts.HauntedHouse.Questline, value = 1},
	[9] = {doorPosition = Position(33625, 32525, 14), storage = Storage.DreamCourts.BurriedCatedral.wordCount, value = 3},
	[10] = {doorPosition = Position(33640, 32551, 14), storage = Storage.DreamCourts.BurriedCatedral.wordCount, value = 3},
	[11] = {doorPosition = Position(33657, 32551, 14), storage = Storage.DreamCourts.BurriedCatedral.wordCount, value = 3},
	[12] = {doorPosition = Position(31983, 31960, 14), storage = Storage.DreamCourts.TheSevenKeys.doorMedusa, value = 1, help = "Medusa"},
	[13] = {doorPosition = Position(32051, 31998, 14), storage = Storage.DreamCourts.TheSevenKeys.Mushroom, value = 2},
	[14] = {doorPosition = Position(32074, 31974, 14), storage = Storage.DreamCourts.TheSevenKeys.sequenceSkulls, value = 3},
	[15] = {doorPosition = Position(32091, 31970, 14), storage = Storage.DreamCourts.TheSevenKeys.Questline, value = 2, help = "Lock"},
	[16] = {doorPosition = Position(31983, 32000, 14), storage = Storage.DreamCourts.TheSevenKeys.Questline, value = 2, help = "Open/Close"},
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local door = Door(item.itemid)
	local usedDoor = item.itemid + 1
	if door then
		usedDoor = door:use()
	end
	local iPos = item:getPosition()
	for _, p in pairs(doors) do
		if (iPos == p.doorPosition) and not(player:getPosition() == p.doorPosition) then
			if p.help == "Tomb" then
				if player:getStorageValue(p.storage) < p.value then
					player:teleportTo(toPosition, true)
					item:transform(usedDoor)
				else
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door seems to be sealed against unwanted intruders.")	
				end
			elseif p.help == "Medusa" then
				if player:getStorageValue(p.storage) < 1 then
					player:setStorageValue(p.storage, 1)
					player:setStorageValue(Storage.DreamCourts.TheSevenKeys.Count, player:getStorageValue(Storage.DreamCourts.TheSevenKeys.Count) + 1)
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "As Medusas's Ointment takes effect the door is unpetrified again. You can use it now.")
				end
				if iPos.y < player:getPosition().y then -- Teleport to the north!
					player:teleportTo(Position(iPos.x, iPos.y - 3, iPos.z))
				else
					player:teleportTo(Position(iPos.x, iPos.y + 3, iPos.z))
				end
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			elseif p.help == "Lock" then
				if player:getStorageValue(p.storage) >= p.value then
					if iPos.y < player:getPosition().y then -- Teleport to the north!
						player:teleportTo(Position(iPos.x, iPos.y - 1, iPos.z))
					else
						player:teleportTo(Position(iPos.x, iPos.y + 1, iPos.z))
					end
					player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				else
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The lock in this door is missing. Mysteriously, the door is locked nonetheless. Perhaps you can find a matching lock somewhere?")
					return true
				end
			elseif p.help == "Open/Close" then
				if player:getStorageValue(p.storage) >= p.value then
					if item.itemid == 34526 then
						item:transform(34528)
					elseif item.itemid == 34528 then
						item:transform(34526)
					end
				end
			else
				if player:getStorageValue(p.storage) >= p.value then
					player:teleportTo(toPosition, true)
					item:transform(usedDoor)
				else
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door seems to be sealed against unwanted intruders.")	
				end	
			end
		end
	end
	return true
end



