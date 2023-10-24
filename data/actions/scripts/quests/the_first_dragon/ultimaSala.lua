-- maskChestTime = 14020, -- 5 x 20hrs Item ID: 1746, Action ID: 2000, Unique ID: 14016
 -- featherChestTime = 14021, 20hrs -- tem ID: 27531, Action ID: 2000, Unique ID: 14017
 -- backpackChestTime = 14022 -1 ano -- Item ID: 27531, Action ID: 2000, Unique ID: 14017
 local itensReward = {
	[14016] = {
		storage = Storage.TheFirstDragon.maskChestTime,
		time = 5*20*60*60,
		backpack = false,
		items = {{27756, 1}},
	},
	[14018] = {
		storage = Storage.TheFirstDragon.featherChestTime,
		time = 20*60*60,
		backpack = false,
		items = {{27757, 3}},
	},
	[14017] = {
		storage = Storage.TheFirstDragon.backpackChestTime,
		-- dias*hrs*min*seg
		time = 365*24*60*60,
		backpack = true,
		items = {
		{25377, 3}, {2156, 1}, {2154, 1}, {2158, 1},
		{10577, 2}, {24170, 1}, {12614, 1}, {5954, 2},
		{27058, 1}, {10582, 2}, {11221, 2}, {15425, 2},
		{12659, 2}, {11337, 2}, {26164, 2}, {23565, 2},
		
		},
	},		
 }
 
 function onUse(player, item, position, target, targetPosition)
	local ituid = itensReward[item:getUniqueId()]
	if(ituid)then
		local str = player:getStorageValue(ituid.storage)
		if(str > os.stime())then
			player:sendCancelMessage('You can use this again on '..os.sdate("%d %B, %Y", str))
			return true
		end
		local function getCapTotal(tab)
			local cap = 0
			for _, pid in pairs(tab) do
				local it = ItemType(pid[1])
				if it then
					cap = cap + (it:getWeight() * pid[2])
				end
			end
			return cap
		end
		if ituid.backpack then
			local tcap = getCapTotal(ituid.items)
			if tcap > player:getFreeCapacity() then
				player:sendCancelMessage(string.format('You have no capacity.'))
				return true
			end
			-- if player:getFreeBackpackSlots() < 1 then
				-- player:sendCancelMessage(string.format('You do not have an empty slot.'))
				-- return true			
			-- end
			local backpack = player:addItem(1988, 1, false)
			if not backpack then
				player:sendCancelMessage(string.format('You do not have an empty slot.'))
				return true
			end
			for _, pid in pairs(ituid.items)do
				local it = ItemType(pid[1])
				if it then
					backpack:addItem(it:getId(), pid[2])
				end
			end
			player:setStorageValue(ituid.storage, ituid.time + os.stime())
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		else
			local tcap = getCapTotal(ituid.items)
			if tcap > player:getFreeCapacity() then
				player:sendCancelMessage(string.format('You have no capacity.'))
				return true
			end
			-- if player:getFreeBackpackSlots() < #ituid.items then
				-- player:sendCancelMessage(string.format('You do not have an empty slot.'))
				-- return true			
			-- end
			for _, pid in pairs(ituid.items)do
				local it = ItemType(pid[1])
				if it then
					player:addItem(it:getId(), pid[2])
				end
			end
			player:setStorageValue(ituid.storage, ituid.time + os.stime())
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		end
	end
	return true
 end
