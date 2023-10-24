function onStepIn(player, item, position, fromPosition)
	if not player:isPlayer() then return true end
	if player then
		player:teleportTo(Position(33458, 31715, 9), true)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		player:say("Slrrp!", TALKTYPE_MONSTER_SAY)
	end
	return true
end
