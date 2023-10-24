local slotBits = {
	[CONST_SLOT_HEAD] = SLOTP_HEAD,
	[CONST_SLOT_NECKLACE] = SLOTP_NECKLACE,
	[CONST_SLOT_BACKPACK] = SLOTP_BACKPACK,
	[CONST_SLOT_ARMOR] = SLOTP_ARMOR,
	[CONST_SLOT_RIGHT] = SLOTP_RIGHT,
	[CONST_SLOT_LEFT] = SLOTP_LEFT,
	[CONST_SLOT_LEGS] = SLOTP_LEGS,
	[CONST_SLOT_FEET] = SLOTP_FEET,
	[CONST_SLOT_RING] = SLOTP_RING,
	[CONST_SLOT_AMMO] = SLOTP_AMMO
}

function ItemType.usesSlot(self, slot)
	return bit.band(self:getSlotPosition(), slotBits[slot] or 0) ~= 0
end

if not ItemTypeBuyValue then
	ItemTypeBuyValue = {}
end
if not ItemTypeSellValue then
	ItemTypeSellValue = {}
end

function ItemType.getSellValue(self)
	if isInArray({ITEM_CRYSTAL_COIN, ITEM_PLATINUM_COIN, ITEM_GOLD_COIN}, self:getId()) then
		local worth = {
			[2148] = 1, -- gold
			[2152] = 100, -- platinum
			[2160] = 1000, -- crystal
		}
		return worth[self:getId()]
	end

	local values = ItemTypeSellValue[self:getId()] or {}
	if #values == 0 then
		return 0
	end

	return table.mean(values)
end

function ItemType.getBuyValue(self)
	if isInArray({ITEM_CRYSTAL_COIN, ITEM_PLATINUM_COIN, ITEM_GOLD_COIN}, self:getId()) then
		local worth = {
			[2148] = 1, -- gold
			[2152] = 100, -- platinum
			[2160] = 1000, -- crystal
		}
		return worth[self:getId()]
	end

	local values = ItemTypeBuyValue[self:getId()] or {}
	if #values == 0 then
		return 0
	end

	return table.mean(values)
end

