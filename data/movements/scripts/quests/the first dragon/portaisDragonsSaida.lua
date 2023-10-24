local action_id = {

	-- Zorvorax
	[14007] = {x = 33003, y = 31594, z = 11},  -- Saída OK 
	
	-- Kalyassa
	[14006] = {x = 33160, y = 31321, z = 5},  -- Saída OK
	
	-- Tazhadur
	[14005] = {x = 33234, y = 32275, z = 12},  -- Saída OK
	
	-- Gelidrazah the Frozen
	[14008] = {x = 32277, y = 31367, z = 4},  -- Saída OK
	

}

-- SAINDO
function onStepIn(creature, item, position, fromPosition)
	
	local action = action_id[item.actionid]
	if action then
		local player = creature:getPlayer()
		if player == nil then
			return false
		end
	
		player:teleportTo(action)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end
end
