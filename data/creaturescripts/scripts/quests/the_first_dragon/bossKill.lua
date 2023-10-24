local bossesConfig = {
	['tazhadur'] = 0,
	['kalyassa'] = 1,
	['zorvorax'] = 2,
	['gelidrazah the frozen'] = 3,
}
-- Storage.TheFirstDragon.quatroDragoes
function onKill(player, creature)
	if not player:isPlayer() then
		return true
	end
	if not creature:isMonster() or creature:getMaster() then
		return true
	end
	local monsterName = creature:getName()
	local tbBit = bossesConfig[monsterName:lower()]
	if not tbBit then
		return true
	end
	
	for pid, damagea in pairs(creature:getDamageMap()) do
		local p = Player(pid)
		if p then
			local stgBase = (p:getStorageValue(Storage.TheFirstDragon.quatroDragoes) < 0 and 0 or p:getStorageValue(Storage.TheFirstDragon.quatroDragoes))
			local bossBit = NewBit(stgBase)
			local base = bit.lshift(1, tbBit)
			if(bossBit:hasFlag(base))then
				return true
			end
			bossBit:updateFlag(base)
			player:setStorageValue(Storage.TheFirstDragon.quatroDragoes, bossBit:getNumber())			
		end
	end
	
	return true
end