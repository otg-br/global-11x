function onSay(player, word, param)

	local item = player:getSlotItem(CONST_SLOT_LEFT)
	-- item:addImbuement(0, item:getImbuement(0):getId(), 60)
	item:addImbuement(1, item:getImbuement(1):getId(), 60)
	return true
end