local Count = Storage.DreamCourts.TheSevenKeys.Count
local Storage = Storage.DreamCourts.TheSevenKeys.doorInvisible
local lanternId = 26406

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local iPos = item:getPosition()
	if player:getStorageValue(Storage) < 1 then
		if player:getItemCount(lanternId) >= 1 then
			player:setStorageValue(Storage, 1)
			player:setStorageValue(Count, player:getStorageValue(Count) + 1)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door opens.")
		end
	else
		if iPos.x < player:getPosition().x then -- Teleport to right!
			player:teleportTo(Position(iPos.x - 3, iPos.y, iPos.z))
		else
			player:teleportTo(Position(iPos.x + 3, iPos.y, iPos.z))
		end
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	end
	return true
end



