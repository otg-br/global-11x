function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end
	
	if player:getGroup():getId() < 4 then return true end

	local creature = Creature(param)
	if not creature then
		player:sendCancelMessage("A creature with that name could not be found.")
		return false
	end

	local oldPosition = creature:getPosition()
	local newPosition = creature:getClosestFreePosition(player:getPosition(), false)
	local tile = Tile(newPosition)
	if not tile then
		player:sendCancelMessage("You can not teleport " .. creature:getName() .. ".")
		return false
	end
	if newPosition.x == 0 then
		player:sendCancelMessage("You can not teleport " .. creature:getName() .. ".")
		return false
	elseif creature:teleportTo(newPosition) then
		if not creature:isInGhostMode() then
			oldPosition:sendMagicEffect(CONST_ME_POFF)
			newPosition:sendMagicEffect(CONST_ME_TELEPORT)
		end
	end
	return false
end
