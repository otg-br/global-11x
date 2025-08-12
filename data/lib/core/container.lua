function Container.isContainer(self)
	return true
end

--[[
	return values for loot creation
	0 = Did not drop the item. No error
	-1 = For some reason, the item can not be created.
	> 0 = UID
]]
function Container.createLootItem(self, item, percent, raid)
	if self:getEmptySlots() == 0 then
		return false
	end

	if not percent then
		percent = 1.0
	end

	local itemCount = 0
	local randvalue = getLootRandom()
	if randvalue < item.chance * percent then
		if ItemType(item.itemId):isStackable() then
			itemCount = randvalue % item.maxCount + 1
		else
			itemCount = 1
		end
	end

	local tmpItem = false
	if itemCount > 0 then
		if item.raid and not raid then
			return false
		end

		tmpItem = self:addItem(item.itemId, math.min(itemCount, 100))
		if not tmpItem then
			return false
		end

		if tmpItem:isContainer() then
			for i = 1, #item.childLoot do
				if not tmpItem:createLootItem(item.childLoot[i], percent, raid) then
					tmpItem:remove()
					return false
				end
			end
		end

		if item.subType ~= -1 then
			tmpItem:setAttribute(ITEM_ATTRIBUTE_CHARGES, item.subType)
		end

		if item.actionId ~= -1 then
			tmpItem:setActionId(item.actionId)
		end

		if item.text and item.text ~= "" then
			tmpItem:setText(item.text)
		end

	end

	return tmpItem
end

function Container.getLootDescription(self, monsterName, version, bonusPrey, hasCharm)
	if not bonusPrey then
		bonusPrey = 0
	end
	local hasParent = false
	local txt = ''
	if bonusPrey > 0 then
		txt = ' (prey bonus active'
		hasParent = true
	end

	if hasCharm then
		if not hasParent then
			txt = txt .. ' ('
			hasParent = true
		else
			txt = txt .. ' and '
		end
		txt = txt .. 'active charm \'Gut\''
	end

	if hasParent then
		txt = txt .. ')'
	end

	local str = {("Loot of %s%s: "):format(monsterName, txt)}
	local firstitem = true
	for i = self:getSize() - 1, 0, -1 do
		local containerItem = self:getItem(i)
		if containerItem then
			local str1 = ''
			if (firstitem) then
				firstitem = false
			else
				str1 = string.format(", ")
			end

			table.insert(str, string.format("%s%s", str1, containerItem:getNameLoot(version)))
		end
	end

	if (firstitem) then
		table.insert(str, string.format("nothing"))
	end

	return str
end

function Container.getLoot(self, mname, version, bonusPrey, hasCharm)
	local text = table.concat(self:getLootDescription(mname, version, bonusPrey, hasCharm))
	return text
end
