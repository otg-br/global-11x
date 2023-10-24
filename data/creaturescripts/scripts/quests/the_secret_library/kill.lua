local defaultTime = 20

function onKill(player, creature)
	if not player:isPlayer() then
		return true
	end
	if not creature:isMonster() or creature:getMaster() then
		return true
	end
	local monsterStorages = {
		["grand commander soeren"] = {stg = Storage.secretLibrary.FalconBastion.killingBosses, value = 1},
		["preceptor lazare"] = {stg = Storage.secretLibrary.FalconBastion.killingBosses, value = 2},
		["grand chaplain gaunder"] = {stg = Storage.secretLibrary.FalconBastion.killingBosses, value = 3},
		["grand canon dominus"] = {stg = Storage.secretLibrary.FalconBastion.killingBosses, value = 4},
		["dazzled leaf golem"] = {stg = Storage.secretLibrary.FalconBastion.killingBosses, value = 5},
		["grand master oberon"] = {stg = Storage.secretLibrary.FalconBastion.killingBosses, value = 6, achievements = {'Millennial Falcon', 'Master Debater'},
		lastBoss = true},
		["brokul"] = {stg = Storage.secretLibrary.LiquidDeath.Questline, value = 7},
		["the flaming orchid"] = {stg = Storage.secretLibrary.Asuras.flammingOrchid, value = 1},
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
				if monsterStorage.achievements then
					for i = 1, #monsterStorage.achievements do
						p:addAchievement(monsterStorage.achievements[i])
					end
				end
				if monsterStorage.lastBoss then
					if p:getStorageValue(Storage.secretLibrary.FalconBastion.Questline) < 2 then
						p:setStorageValue(Storage.secretLibrary.FalconBastion.Questline, 2)
					end
				end
			end
		end
	end
	return true
end

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	primaryDamage = 0
	secondaryDamage = 0
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
