local chestsItems = {
	[55001] = {base = 0, reward = {id = 7632, amount = 1}}, -- Banuta (Port Hope)
	[55002] = {base = 1, reward = {id = 2157, amount = 2}}, -- Cemetery Quarter (Yalahar)
	[55003] = {base = 2, reward = {id = 18413, amount = 1}}, -- Crystal Gardens (Liberty Bay)
	[55004] = {base = 3, reward = {id = 18414, amount = 1}}, -- Ab'dendriel 
	[55005] = {base = 4, reward = {id = 18416, amount = 2}}, -- Dragon Lair (Darashia)
	[55006] = {base = 5, reward = {id = 2156, amount = 1}}, -- Dragon Lair (Port Hope)
	[55007] = {base = 6, reward = {id = 24849, amount = 3}}, -- Drefia (Darashia)
	[55008] = {base = 7, reward = {id = 2152, amount = 3}}, -- Carlin (Ghostland)
	[55009] = {base = 8, reward = {id = 18420, amount = 2}}, -- Goroma (Liberty Bay)
	[55010] = {base = 9, reward = {id = 2154, amount = 1}}, -- Hero Fortress (Edron)
	[55011] = {base = 10, reward = {id = 2151, amount = 3}}, -- Isle of Evil (Kazordoon)
	[55012] = {base = 11, reward = {id = 2143, amount = 2}}, -- Desert (Venore)
	[55013] = {base = 12, reward = {id = 9971, amount = 1}}, -- Caminho para Kazordoon
	[55014] = {base = 13, reward = {id = 24850, amount = 3}}, -- Krailos
	[55015] = {base = 14, reward = {id = 2145, amount = 2}}, -- Okolnir (Svargrond)
	[55016] = {base = 15, reward = {id = 18415, amount = 1}}, -- Shargon Hideout (Oramond)
	[55017] = {base = 16, reward = {id = 2144, amount = 3}}, -- Spider Caves (Port Hope)
	[55018] = {base = 17, reward = {id = 2127, amount = 1}}, -- Treasure Island (Liberty Bay)
	[55019] = {base = 18, reward = {id = 2155, amount = 1}}, -- Vengoth Castle (Yalahar)
	[55020] = {base = 19, reward = {id = 7633, amount = 1}}, -- Zao Steppes (Farmine)
}

function onUse(player, item, fromPosition, target, toPosition)
	local stg5 = (player:getStorageValue(Storage.TheFirstDragon.tamorilTasksTreasure) < 0 and 0 or player:getStorageValue(Storage.TheFirstDragon.tamorilTasksTreasure))
	local chest = (player:getStorageValue(Storage.TheFirstDragon.chests) < 0 and 0 or player:getStorageValue(Storage.TheFirstDragon.chests))
	local bau = chestsItems[item.actionid]
	if not bau then
		return false
	end
	if player:getStorageValue(Storage.TheFirstDragon.tamorilTasks) < 1 then
		return false
	end
	local chestMeta = NewBit(chest)
	local base = bit.lshift(1, bau.base)
	-- player:sendTextMessage(MESSAGE_STATUS_WARNING, "Base do bau: ".. bau.base ..", base da storage: ".. chestMeta:getNumber())
	if(chestMeta:hasFlag(base))then
		player:sendCancelMessage('It\'s empty')
		return true
	end
	local reward = ItemType(bau.reward.id)
	if player:getFreeCapacity() < (reward:getWeight() * bau.reward.amount)then
		player:sendCancelMessage(string.format('You have found %s weighing %.2f oz. You have no capacity.', reward:getName(), ((reward:getWeight() * bau.reward.amount) / 100)))
	else
		player:addItem(bau.reward.id, bau.reward.amount)
		player:sendCancelMessage('You got a '.. reward:getName() ..'.')
		chestMeta:updateFlag(base)
		player:setStorageValue(Storage.TheFirstDragon.chests, chestMeta:getNumber())
		player:say("You open the beautiful chest and take the precious object you find within.", TALKTYPE_MONSTER_SAY)
		if stg5 < 5 then
			player:setStorageValue(Storage.TheFirstDragon.tamorilTasksTreasure, stg5 + 1)
		end
		-- Treasure Hunter
		chestMeta:updateNumber(player:getStorageValue(Storage.TheFirstDragon.chests))
		local count = 0
		for _, pid in pairs(chestsItems)do
			base = bit.lshift(1, pid.base)			
			if(chestMeta:hasFlag(base))then
				count = count + 1
			end
		end
		if count >= 20 then
			player:addAchievement("Treasure Hunter")
		end
	end	
	return true
end
