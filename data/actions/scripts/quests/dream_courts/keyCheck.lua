local storage = Storage.DreamCourts.HauntedHouse.Questline
local pilar = {Position(33069, 32317, 8), Position(33070, 32317, 8), Position(33068, 32308, 8)}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return true
	end
	local iPos = item:getPosition()
	local isInQuest = player:getStorageValue(Storage.DreamCourts.HauntedHouse.Tomb)
	if player:getStorageValue(storage) == 1 and isInQuest < 1 then
		if iPos == pilar[1] or iPos == pilar[2] then
			if player:getItemCount(33844) >= 2 then
				player:removeItem(33844, 2)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "As soon as you turn the second key a mechanism retracts the locks and swallows the keys, opening a small passage beyond.")
				player:teleportTo(Position(33069, 32310, 8))
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need to use the mechanism of the pillar itself to turn both keys at once.")
				return true
			end
		elseif iPos == pilar[3] then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You reach for the onyx and trigger and enormous discharge of raw energy. It is now possible to traverse the portal in this tomb.")
			player:teleportTo(Position(33068, 32320, 8))
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			player:setStorageValue(Storage.DreamCourts.HauntedHouse.Tomb, 1)
			if player:getStorageValue(Storage.DreamCourts.HauntedHouse.Tomb) == 1 and player:getStorageValue(Storage.DreamCourts.HauntedHouse.Cellar) == 1 
			and player:getStorageValue(Storage.DreamCourts.HauntedHouse.Temple) == 1 then
				player:setStorageValue(Storage.DreamCourts.HauntedHouse.Questline, 2)
			end
		end
	end
	return true
end
