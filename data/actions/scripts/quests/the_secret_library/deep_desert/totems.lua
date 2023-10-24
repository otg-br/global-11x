local totems = {
	{toPosition = Position(32945, 32292, 8), targetId = 33073, toId = 33074, itemId = 33077, storage = Storage.secretLibrary.Darashia.firstTotem},
	{toPosition = Position(32947, 32292, 8), targetId = 33069, toId = 33070, itemId = 33079, storage = Storage.secretLibrary.Darashia.secondTotem},
	{toPosition = Position(32949, 32292, 8), targetId = 33075, toId = 33076, itemId = 33080, storage = Storage.secretLibrary.Darashia.thirdTotem},
	{toPosition = Position(32951, 32292, 8), targetId = 33071, toId = 33072, itemId = 33078, storage = Storage.secretLibrary.Darashia.fourthTotem},
}

local function isQuestComplete(cid)
	local player = Player(cid)
	if player then
		for _, s in pairs(totems) do
			if player:getStorageValue(s.storage) ~= 1 then
				return false
			end
		end
	end
	return true
end

local function revert(old, new, position)
	local totem = Tile(position):getItemById(new)
	if totem then
		totem:transform(old)
	end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(Storage.secretLibrary.Darashia.Questline) == 6 then
		for _, k in pairs(totems) do
			if toPosition == k.toPosition and item.itemid == k.itemId and target.itemid == k.targetId then
				if player:getStorageValue(k.storage) < 1 then
					toPosition:sendMagicEffect(CONST_ME_HITAREA)
					target:transform(k.toId)
					item:remove(1)
					player:setStorageValue(k.storage, 1)
					addEvent(revert, 15*1000, k.targetId, k.toId, toPosition)
				end
			end
			if isQuestComplete(player:getId()) then
				player:setStorageValue(Storage.secretLibrary.Darashia.Questline, 7)
				player:say('Access granted!', TALKTYPE_MONSTER_SAY)
			end
		end
	end
	return true
end



