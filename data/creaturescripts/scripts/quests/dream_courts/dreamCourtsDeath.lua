local questlog = {
	[1] = {bossName = "Faceless Bane", storageQuestline = Storage.DreamCourts.HauntedHouse.Questline,
	storageTimer = Storage.DreamCourts.BurriedCatedral.facelessTime, middlePosition = Position(33617, 32563, 13), maxValue = 4},
	[2] = {bossName = "Maxxenius", storageQuestline = Storage.DreamCourts.DreamScar.bossCount,
	storageTimer = Storage.DreamCourts.DreamScar.maxxeniusTimer, middlePosition = Position(32208, 32048, 14), maxValue = 5},
	[3] = {bossName = "Alptramun", storageQuestline = Storage.DreamCourts.DreamScar.bossCount,
	storageTimer = Storage.DreamCourts.DreamScar.alptramunTimer, middlePosition = Position(32208, 32048, 14), maxValue = 5},
	[4] = {bossName = "Izcandar the Banished", storageQuestline = Storage.DreamCourts.DreamScar.bossCount,
	storageTimer = Storage.DreamCourts.DreamScar.izcandarTimer, middlePosition = Position(32208, 32048, 14), maxValue = 5},
	[5] = {bossName = "Izcandar Champion of Winter", storageQuestline = Storage.DreamCourts.DreamScar.bossCount,
	storageTimer = Storage.DreamCourts.DreamScar.izcandarTimer, middlePosition = Position(32208, 32048, 14), maxValue = 5},
	[6] = {bossName = "Izcandar Champion of Summer", storageQuestline = Storage.DreamCourts.DreamScar.bossCount,
	storageTimer = Storage.DreamCourts.DreamScar.izcandarTimer, middlePosition = Position(32208, 32048, 14), maxValue = 5},
	[7] = {bossName = "Plagueroot", storageQuestline = Storage.DreamCourts.DreamScar.bossCount,
	storageTimer = Storage.DreamCourts.DreamScar.plaguerootTimer, middlePosition = Position(32208, 32048, 14), maxValue = 5},
	[8] = {bossName = "Malofur Mangrinder", storageQuestline = Storage.DreamCourts.DreamScar.bossCount,
	storageTimer = Storage.DreamCourts.DreamScar.malofurTimer, middlePosition = Position(32208, 32048, 14), maxValue = 5},
	[9] = {bossName = "The Nightmare Beast", storageQuestline = Storage.DreamCourts.WardStones.Questline,
	storageTimer = Storage.DreamCourts.DreamScar.nightmareTimer, middlePosition = Position(32207, 32045, 15), maxValue = 2},
	-- nome do boss, storage da quest, storage de tempo, posição do meio da sala, valor maximo
}

local alptramunSummons = {
	[1] = {name = "unpleasant dream", minValue = 0, maxValue = 9},
	[2] = {name = "horrible dream", minValue = 9, maxValue = 18},
	[3] = {name = "nightmarish dream", minValue = 18, maxValue = 27},
	[4] = {name = "mind-wrecking dream", minValue = 27, maxValue = 36}
}

function onDeath(creature, corpse, lasthitkiller, mostdamagekiller, lasthitunjustified, mostdamageunjustified)
	local cName = creature:getName()
	if cName:lower() == "plant abomination" then
		local cPos = creature:getPosition()
		Game.createMonster("plant attendant", cPos)
	end
	for _, k in pairs(questlog) do
		if cName == k.bossName then
			for pid, _ in pairs(creature:getDamageMap()) do
				local attackerPlayer = Player(pid)				
				if attackerPlayer then
					if attackerPlayer:getStorageValue(k.storageQuestline) <= k.maxValue then
						attackerPlayer:setStorageValue(k.storageQuestline, attackerPlayer:getStorageValue(k.storageQuestline) + 1)
					end
					attackerPlayer:setStorageValue(k.storageTimer, os.stime() + 20 * 60 * 60)
				end
			end
			if cName:lower() == 'alptramun' then
				Game.setStorageValue(GlobalStorage.DreamCourts.DreamScar.alptramunSummonsKilled, 0)
			end
		end
	end
	-- Alptramun Summons [[they become stronger as you keep killing them]]
	local summonsKilled = Game.getStorageValue(GlobalStorage.DreamCourts.DreamScar.alptramunSummonsKilled)	
	for _, k in pairs(alptramunSummons) do
		if cName:lower() == k.name then
			if summonsKilled >= k.minValue  and summonsKilled <= k.maxValue then
				Game.setStorageValue(GlobalStorage.DreamCourts.DreamScar.alptramunSummonsKilled, summonsKilled + 1)
			end
		end
	end
	return true
end
