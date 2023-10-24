function onSay(player, words, param)
	if player:getGroup():getId() < 4 then return true end

	player:teleportTo(Position(32316, 31942, 7), true)

	return false
end
