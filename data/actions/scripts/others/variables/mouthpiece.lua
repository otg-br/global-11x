local items = {
	[22389] = {targetId = 22391},
	[22391] = {targetId = 22389}
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local j = items[item.itemid]
	if not j then return true end
	if target.itemid == j.targetId then
		player:removeItem(item.itemid, 1)
		player:removeItem(target.itemid, 1)
		player:addItem(22390, 1)
	end
	return true
end
