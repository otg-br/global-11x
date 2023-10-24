function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getGroup():getId() < 6 then
		return true
	end

	local position = player:getPosition()
	local monstername = tonumber(param) and tonumber(param) or param
	local monster = Game.createMonster(monstername, position)
	if monster ~= nil then
		if monster:getType():isRewardBoss() then
			monster:setReward(true)
		end
		monster:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		position:sendMagicEffect(CONST_ME_MAGIC_RED)
	else
		player:sendCancelMessage("There is not enough room.")
		position:sendMagicEffect(CONST_ME_POFF)
	end
	return false
end
