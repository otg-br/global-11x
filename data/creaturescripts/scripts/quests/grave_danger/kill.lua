local defaultTime = 20

function onKill(player, creature)
	if not player:isPlayer() then
		return true
	end
	if not creature:isMonster() or creature:getMaster() then
		return true
	end
	local monsterStorages = {
		["gaffir"] = {stg = Storage.GraveDanger.CobraBastion.Questline, value = 2},
	}

	local monsterName = creature:getName():lower()
	local monsterStorage = monsterStorages[monsterName]
	
	if monsterStorage then
		for playerid, damage in pairs(creature:getDamageMap()) do
			local p = Player(playerid)
			if p then
				if p:getStorageValue(monsterStorage.stg) < monsterStorage.value then
					p:setStorageValue(monsterStorage.stg, monsterStorage.value)				
				end
			end
		end
	end
	return true
end