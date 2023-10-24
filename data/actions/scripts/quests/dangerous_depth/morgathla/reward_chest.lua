local config = {
	left = {
		{id = 18215, q = 2},
		{id = 2114, q = 1},
		{id = 9810, q = 1}
	},
	middle = {
		{id = 18215, q = 2},
		{id = 2152, q = 50},
		{id = 2114, q = 1},
		{id = 9810, q = 1}
	},
	right = {
		{id = 18215, q = 4},
		{id = 2160, q = 2},
		{id = 2114, q = 1},
		{id = 9810, q = 1},
		{id = 9811, q = 1}
	}
}

function onUse(player, item, fromPosition, toPosition)	
	if not player:isPlayer() then
		return false
	end	
	if not player:hasAchievement('Scourge of Scarabs') then
		player:addAchievement('Scourge of Scarabs')
		local backpack = player:addItem(1987) or player:addItem(1988)
		if not backpack then
			return true
		end
		
		if item:getUniqueId() == 57370 then
			for i = 1, #config.left do
				backpack:addItem(config.left[i].id, config.left[i].q)
			end
		elseif item:getUniqueId() == 57371 then
			for i = 1, #config.middle do
				backpack:addItem(config.middle[i].id, config.middle[i].q)
			end
		elseif item:getUniqueId() == 57372 then
			for i = 1, #config.right do
				backpack:addItem(config.right[i].id, config.right[i].q)
			end
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You have found a bag.')
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'It is empty.')
		return true
	end	
	return true
end
