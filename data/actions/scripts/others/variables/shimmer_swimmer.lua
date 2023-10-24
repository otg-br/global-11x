local weapons = {
	[13943] = 13871,
	[13881] = 13872,
	[13877] = 13880,
	[13870] = 13875,
	[13942] = 13873
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local weapon = weapons[target.itemid]
	if not weapon then return true end
	player:removeItem(item.itemid, 1)
	player:removeItem(target.itemid, 1)
	player:addItem(weapon, 1)
	return true
end
