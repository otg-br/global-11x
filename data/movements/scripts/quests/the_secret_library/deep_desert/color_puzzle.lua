local color = {
	[1] = {itemid = 4398, position = Position(32945, 32288, 10), value = 2, storage = Storage.secretLibrary.Darashia.redColor},
	[2] = {itemid = 5582, position = Position(32948, 32288, 10), value = 1, storage = Storage.secretLibrary.Darashia.greenColor},
	[3] = {itemid = 9611, position = Position(32951, 32288, 10), value = 3, storage = Storage.secretLibrary.Darashia.blueColor},
}

function onStepIn(creature, item, position, fromPosition)
	if not creature:isPlayer() then
		return false
	end
	local player = Player(creature:getId())
	if player then
		if player:getStorageValue(Storage.secretLibrary.Darashia.colorPuzzle) < 1 then
			for _, k in pairs(color) do
				if item.itemid == k.itemid and position == k.position then
					if player:getStorageValue(k.storage) < k.value then
						if player:getStorageValue(k.storage) < 0 then
							player:setStorageValue(k.storage, 0)
						end
						player:setStorageValue(k.storage, player:getStorageValue(k.storage) + 1)					
					else
						for i = 1, #color do
							player:setStorageValue(color[i].storage, 0)
						end
					end
				end
			end		
			if player:getStorageValue(color[1].storage) == color[1].value and player:getStorageValue(color[2].storage) == color[2].value 
			and	player:getStorageValue(color[3].storage) == color[3].value then
				player:setStorageValue(Storage.secretLibrary.Darashia.colorPuzzle, 1)
				player:say('Access granted!', TALKTYPE_MONSTER_SAY)
			end
		end
	end
	return true
end
