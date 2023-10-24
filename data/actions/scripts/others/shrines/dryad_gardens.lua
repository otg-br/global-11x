local shrines = {
	[1] = {itemPos = Position(33264, 32014, 7), toPosition = Position(33202, 32012, 11)},
	[2] = {itemPos = Position(33198, 32010, 11), toPosition = Position(33265, 32012, 7)}
}
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for _, p in pairs(shrines) do
		if item:getPosition() == p.itemPos then
			player:teleportTo(p.toPosition)
			player:getPosition():sendMagicEffect(CONST_ME_WATERSPLASH)
		end
	end
	return true
end
