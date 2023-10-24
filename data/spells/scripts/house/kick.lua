function onCastSpell(player, variant)
	local targetPlayer = Player(variant:getString()) or player
	local house = targetPlayer:getTile():getHouse()
	if not house or player:getTile():getHouse():getId() ~= house:getId() then
		player:sendCancelMessage("The player isn't in the same house that you are or he isn't inside a house.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false 
	end
	if not house:canEditAccessList(GUEST_LIST, player) and player:getId() ~= targetPlayer:getId() then
		player:sendCancelMessage("You can kick only yourself.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end
	if not house:kickPlayer(player, targetPlayer) then
		player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end
	return true
end
