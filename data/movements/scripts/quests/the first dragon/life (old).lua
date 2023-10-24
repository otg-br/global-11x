local config = {
	[14010] = {base = 0,storageKeyTemp = Storage.TheFirstDragon.tamorilTasksLifeTiles,storageKey = Storage.TheFirstDragon.tamorilTasksLife, text = 'You enter the circle of trees and flowers. By visiting this sacred site you\'re infused with the power of nature and plants.'},
	[14011] = {base = 1,storageKeyTemp = Storage.TheFirstDragon.tamorilTasksLifeTiles,storageKey = Storage.TheFirstDragon.tamorilTasksLife, text = 'You enter the beautiful oasis. By visiting this sacred site you\'re infused with the power of water bringing life to the desert.'},
	[14012] = {base = 2, storageKeyTemp = Storage.TheFirstDragon.tamorilTasksLifeTiles, storageKey = Storage.TheFirstDragon.tamorilTasksLife, text = 'You entered the suntower of Ab\'dendriel. By visiting this sacred site you\'re infused with the power of the life-giving sun.'}
}
function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local targetTile = config[item.actionid]
	if not targetTile then
		return true
	end
	local storageKeyTemp = (player:getStorageValue(targetTile.storageKeyTemp) < 1 and 0 or player:getStorageValue(targetTile.storageKeyTemp))
	local chestMeta = NewBit(storageKeyTemp)
	local base = bit.lshift(1, targetTile.base)	
	local stg = (player:getStorageValue(targetTile.storageKey) < 1 and 0 or player:getStorageValue(targetTile.storageKey))
	if(chestMeta:hasFlag(base))then
		return false
	else
		chestMeta:updateFlag(base)
		player:setStorageValue(targetTile.storageKeyTemp, chestMeta:getNumber())
		player:setStorageValue(targetTile.storageKey, stg+1)
		player:say(targetTile.text, TALKTYPE_MONSTER_SAY)		
	end
	
	
	-- if player:getStorageValue(targetTile.storageKey) < 1 then
		-- -- Adicionando +1 tile sagrado ao Quest Log
		-- -- player:setStorageValue(Storage.TheFirstDragon.tamorilTasksLife, player:getStorageValue(Storage.TheFirstDragon.tamorilTasksLife) + 1)
		-- player:setStorageValue(targetTile.storageKey, stg+1)
		-- player:say(targetTile.text, TALKTYPE_MONSTER_SAY)
	-- end
	return true
end
