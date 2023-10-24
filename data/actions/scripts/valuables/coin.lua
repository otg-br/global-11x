function onUse(player, item, position, target, postarget, ishotkey)
	if item:getId() == 2148 then
		if item:getCount() >= 100 then
			item:remove()
			player:addItem(2152, 1)
		end
	elseif item:getId() == 2152 then
		if item:getCount() < 100 then
			item:remove(1)
			player:addItem(2148, 100)
		else
			item:remove()
			player:addItem(2160, 1)
		end
	elseif item:getId() == 2160 then
		item:remove(1)
		player:addItem(2152, 100)
	end

	return true
end