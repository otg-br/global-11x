function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	item:getPosition():sendMagicEffect(CONST_ME_DRAWBLOOD)
	item:remove(1)
	player:addItem(math.random(7588, 7589), 1)
	return true
end
