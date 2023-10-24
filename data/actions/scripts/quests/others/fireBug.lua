local function revert(position, itemId, transformId)
	local item = Tile(position):getItemById(itemId)
	if item then
		item:transform(transformId)
	end
end
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.actionid == 54387 and target.itemid == 25531 then
		if player:getStorageValue(Storage.FerumbrasAscension.BasinCounter) >= 8 or player:getStorageValue(Storage.FerumbrasAscension.BoneFlute) < 1 then
			return false
		end
		if player:getStorageValue(Storage.FerumbrasAscension.BasinCounter) < 0 then
			player:setStorageValue(Storage.FerumbrasAscension.BasinCounter, 0)
		end
		if player:getStorageValue(Storage.FerumbrasAscension.BasinCounter) == 7 then
			player:say('You ascended the last basin.', TALKTYPE_MONSTER_SAY)
			item:remove()
			player:setStorageValue(Storage.FerumbrasAscension.MonsterDoor, 1)
		end
		target:transform(25532)
		player:setStorageValue(Storage.FerumbrasAscension.BasinCounter, player:getStorageValue(Storage.FerumbrasAscension.BasinCounter) + 1)
		toPosition:sendMagicEffect(CONST_ME_FIREAREA)
		addEvent(revert, 2 * 60 * 1000, toPosition, 25532, 25531)
		return true
	end
	
	if isInArray({12550, 12551}, target.actionid) then
		if player:getStorageValue(Storage.secretService.Quest) == 2 and player:getStorageValue(Storage.secretService.TBIMission01) == 1 then
			local fire = Game.createItem(1487, 1, toPosition)
			player:setStorageValue(Storage.secretService.TBIMission01, 2)
		end
	end

	if target.itemid == 5466 then
		target:transform(5465)
		-- Game.createItem(5467,1,target:getPosition())
	end

	if target.uid == 2243 and target.itemid == 2249 then
		local fromPos = Position(32847, 32230, 9)
		local toPos = Position(32850, 32233, 9)
		for x = fromPos.x, toPos.x do
			for y = fromPos.y, toPos.y do
				local tile = Tile(Position(x, y, 9))
					if tile then
					local pox = tile:getItemById(1496)
					local ashes = tile:getItemById(2249)
					if pox or ashes then
						if ashes then
							ashes:transform(1387)
							addEvent(revert, 2* 60 * 1000, toPosition, 1387, 2249)
						end
						tile:getPosition():sendMagicEffect(CONST_ME_FIREAREA)						
					end
				end
			end
		end
	end
	return true
end
