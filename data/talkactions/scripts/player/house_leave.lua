function onSay(player, words, param)
	local checkItems = 1


	local position = player:getPosition()
	local tile = Tile(position)
	local house = tile and tile:getHouse()
	if house == nil then
		player:sendCancelMessage("You are not inside a house.")
		position:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	if house:getOwnerGuid() ~= player:getGuid() then
		player:sendCancelMessage("You are not the owner of this house.")
		position:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	if checkItems == 1 then
		local itemMax = 2000
		local tiles = house:getTiles()
		local itens = 0
		for _, h_tile in pairs(tiles) do
			if h_tile then
				local items = h_tile:getItems()
				for x, item in pairs(items) do
					local itemType = ItemType(item:getId())
					if itemType and (itemType:isMovable() or itemType:isStackable()) then
						itens = itens + 1
						if item:isContainer() then
							-- backpack
							itens = itens + Container(item.uid):getItemHoldingCount()
						end
					end
				end
			end
		end

		if itens >= itemMax then
			player:sendCancelMessage("For safety reasons, remove your items first before leaving the house.")
			position:sendMagicEffect(CONST_ME_POFF)
			return false
		end
	end

	house:setOwnerGuid(0)
	player:sendTextMessage(MESSAGE_INFO_DESCR, "You have successfully left your house.")
	position:sendMagicEffect(CONST_ME_POFF)
	return false
end
