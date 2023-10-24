function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getGroup():getId() < 6 then
		return true
	end

	local position = player:getPosition()
	local monster = Game.createMonster(param, position)
	if monster ~= nil then
		player:addSummon(monster)
		position:sendMagicEffect(CONST_ME_MAGIC_RED)
	else
		player:sendCancelMessage("There is not enough room.")
		position:sendMagicEffect(CONST_ME_POFF)
	end
	return false
end
