local invalidIds = {
	1, 2, 3, 4, 5, 6, 7, 10, 11, 13, 14, 15, 19, 21, 26, 27, 28, 35, 43, 1094
}

function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getGroup():getId() < 6 then
		return true
	end

	local split = param:splitTrimmed(",")

	local itemType = ItemType(split[1])
	if itemType:getId() == 0 then
		itemType = ItemType(tonumber(split[1]))
		if tonumber(split[1]) == nil or itemType:getId() == 0 then
			player:sendCancelMessage("There is no item with that id or name.")
			return false
		end
	end

	if table.contains(invalidIds, itemType:getId()) then
		return false
	end

	local count = tonumber(split[2])
	if count then
		if itemType:isStackable() then
			count = math.min(10000, math.max(1, count))
		elseif not itemType:isFluidContainer() then
			count = math.min(100, math.max(1, count))
		else
			count = math.max(0, count)
		end
	else
		if not itemType:isFluidContainer() then
			count = 1
		else
			count = 0
		end
	end

	local success = true
	local charges = itemType:getCharges()
	if charges < 1 or count == 0 then
		local result = player:addItem(itemType:getId(), count)
		if result then
			if not itemType:isStackable() then
				if type(result) == "table" then
					for _, item in ipairs(result) do
						item:decay()
					end
				else
					result:decay()
				end
			end
		else
			player:sendCancelMessage("Sorry")
			success = false
		end
	else
		for i = 1, count do
			local result = player:addItem(itemType:getId(), count)
			if result then
				if not itemType:isStackable() then
					if type(result) == "table" then
						for _, item in ipairs(result) do
							item:decay()
						end
					else
						result:decay()
					end
				end
			else
				player:sendCancelMessage("Sorry")
				success = false
				break
			end
		end
	end

	if player:isInGhostMode() then
		player:getPosition():sendMagicEffect(success and CONST_ME_MAGIC_GREEN or CONST_ME_POFF)
	end
	return false
end
