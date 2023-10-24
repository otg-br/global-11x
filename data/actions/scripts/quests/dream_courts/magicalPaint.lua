local sapphireDust = 34497
local sunFruitJuice = 34496
local egg = 34498
local enchantedBottle = 34499
local magicalPaint = 34487

local Count = Storage.DreamCourts.TheSevenKeys.Count

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.itemid == sapphireDust and target.itemid == sunFruitJuice then
		target:remove(1)
		item:remove(1)
		player:addItem(enchantedBottle)
		return true
	elseif item.itemid == egg and target.itemid == enchantedBottle then
		target:remove(1)
		item:remove(1)
		player:addItem(magicalPaint)
		return true
	elseif item.itemid == magicalPaint and target.actionid == 23109 then
		if player:getStorageValue(Storage.DreamCourts.TheSevenKeys.Painting) < 1 then
			item:remove(1)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Carefully you paint over the picture. As you are doing so the flat paiting deepens. It looks now like a room you can enter.")
			player:setStorageValue(Storage.DreamCourts.TheSevenKeys.Painting, 1)
			player:setStorageValue(Count, player:getStorageValue(Count) + 1)
		end
	elseif item.actionid == 23109 and (item.itemid == 34489 or item.itemid == 34490) then
		if player:getStorageValue(Storage.DreamCourts.TheSevenKeys.Painting) == 2 then
			if item.getPosition() == Position(32104, 31921, 13) or item:getPosition() == Position(32103, 31921, 13) then
				player:teleportTo(Position(32114, 32014, 13))
			else
				player:teleportTo(Position(32103, 31922, 13))
			end
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		elseif player:getStorageValue(Storage.DreamCourts.TheSevenKeys.Painting) == 1 then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This isn't a normal paiting anymore. By using magical paint you transformed it into a portal and can easily pass it.")
			player:setStorageValue(Storage.DreamCourts.TheSevenKeys.Painting, 2)
		end
	end
end
