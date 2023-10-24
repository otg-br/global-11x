local info = {
	individual = {
		{name = "Black Vixen", stgTime = 50739}, 
		{name = "Shadowpelt", stgTime = 50740},
		{name = "Sharpclaw", stgTime = 50741},
		{name = "Darkfang", stgTime = 50742},
		{name = "Bloodback", stgTime = 50743},
		{name = "Lady Tenebris", stgTime = Storage.ForgottenKnowledge.LadyTenebrisTimer},
		{name = "Lloyd", stgTime = Storage.ForgottenKnowledge.LloydTimer},
		{name = "Dragonking Zyrtach", stgTime = Storage.ForgottenKnowledge.DragonkingTimer},
		{name = "Thorn Knight", stgTime = Storage.ForgottenKnowledge.ThornKnightTimer},
		{name = "Melting Frozen Horror", stgTime = Storage.ForgottenKnowledge.HorrorTimer},
		{name = "Time Guardian", stgTime = Storage.ForgottenKnowledge.TimeGuardianTimer},
		{name = "Last Lore Keeper", stgTime = Storage.ForgottenKnowledge.LastLoreTimer},
		{name = "Mazzinor", stgTime = Storage.secretLibrary.Library.mazzinorTimer},
		{name = "Lokathmor", stgTime = Storage.secretLibrary.Library.lokathmorTime},
		{name = "Ghulosh", stgTime = Storage.secretLibrary.Library.ghuloshTime},
		{name = "Gorzindel", stgTime = Storage.secretLibrary.Library.gorzindelTime},	
		{name = "Scarlett Etzel", stgTime = Storage.GraveDanger.CobraBastion.ScarlettTimer},
		{name = "The Nightmare Beast", stgTime = Storage.DreamCourts.DreamScar.nightmareTimer},
		{name = "Anomaly", stgTime = 14321},
		{name = "Rupture", stgTime = 14323},
		{name = "Realityquake", stgTime = 14325},
		{name = "Eradicator", stgTime = 14329},
		{name = "Outburst", stgTime = 14331},
		{name = "World Devourer", stgTime = 14333},
		{name = "Grand Master Oberon", stgTime = Storage.secretLibrary.FalconBastion.oberonTimer},		
		{name = "The Blazing Rose", stgTime = Storage.secretLibrary.Asuras.blazingTimer},
		{name = "The Diamond Blossom", stgTime = Storage.secretLibrary.Asuras.diamondTimer},
		{name = "The Lily Of Night", stgTime = Storage.secretLibrary.Asuras.darkTimer},
		{name = "The Count of The Core", stgTime = Storage.DangerousDepths.Bosses.theCountOfTheCore},
		{name = "The Baron From Below", stgTime = Storage.DangerousDepths.Bosses.theBaronFromBelow},
		{name = "The Duke of The Depths", stgTime = Storage.DangerousDepths.Bosses.theDukeOfTheDepths},
		{name = "Gnomevil", stgTime = 790014},
		{name = "Abyssador", stgTime = 790016},
		{name = "Deathstrike", stgTime = 790015},
		{name = "The False God", stgTime = Storage.CultsOfTibia.Minotaurs.bossTimer},
		{name = "Leiden", stgTime = Storage.CultsOfTibia.Barkless.bossTimer},
		{name = "Essence of Malice", stgTime = Storage.CultsOfTibia.Humans.bossTimer},
		{name = "The Sandking", stgTime = Storage.CultsOfTibia.Life.bossTimer},
		{name = "The Souldespoiler", stgTime = Storage.CultsOfTibia.Misguided.bossTimer},
		{name = "The Unarmored Voidborn", stgTime = Storage.CultsOfTibia.Orcs.bossTimer},
		{name = "The Source of Corruption", stgTime = Storage.CultsOfTibia.finalBoss.bossTimer},
		{name = "Zorvorax", stgTime = Storage.TheFirstDragon.zorvoraxTime},
		{name = "Kalyassa", stgTime = Storage.TheFirstDragon.kalyassaTime},
		{name = "Tazhadur", stgTime = Storage.TheFirstDragon.tazhadurTime},
		{name = "Gelidrazah The Frozen", stgTime = Storage.TheFirstDragon.gelidrazahTime},
		{name = "The First Dragon", stgTime = Storage.TheFirstDragon.theFirstDragonTime},
		{name = "Kroazur", stgTime = Storage.ThreatenedDreams.Dream.KroazurTimer},
		{name = "Alptramun", stgTime = Storage.DreamCourts.DreamScar.alptramunTimer},
		{name = "Izcandar the Banished", stgTime = Storage.DreamCourts.DreamScar.izcandarTimer},
		{name = "Malofur Mangrinder", stgTime = Storage.DreamCourts.DreamScar.malofurTimer},
		{name = "Maxxenius", stgTime = Storage.DreamCourts.DreamScar.maxxeniusTimer},
		{name = "Plagueroot", stgTime = Storage.DreamCourts.DreamScar.plaguerootTimer},
		{name = "Faceless Bane", stgTime = Storage.DreamCourts.BurriedCatedral.facelessTimer}
	},
	global = {
		{name = "Warzone VI", stgTime = GlobalStorage.DangerousDepths.Geodes.WarzoneVI},
		{name = "Warzone V", stgTime = GlobalStorage.DangerousDepths.Geodes.WarzoneV},
		{name = "Warzone IV", stgTime = GlobalStorage.DangerousDepths.Geodes.WarzoneIV},
	}
}

local function sendModal(pid, msg)
	local player = Player(pid)
	if not player then return true end
	local window = ModalWindow(Modal.bossesList, "The bosses eye says:", msg)
	window:addButton(111, 'Close')
	window:setDefaultEscapeButton(111)
	window:sendToPlayer(player)
	return true
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local msg = "------- Individual Bosses -------\n"
	local c_, d_ = 0, 0
	for _, p in pairs(info.individual) do
		if player:getStorageValue(p.stgTime) > os.stime() then
			c_ = 1
			msg = msg .. p.name .. " - disponivel em: " .. os.sdate ("%d/%m/%Y, as %X", player:getStorageValue(p.stgTime)) .. "\n"
		end
	end
	if c_ < 1 then
		msg = msg .. "Todos os bosses individuais estao disponiveis.\n"
	end
	msg = msg .. "------- Global Bosses -------\n"
	for _, p in pairs(info.global) do
		if Game.getStorageValue(p.stgTime) > os.stime() then
			d_ = 1
			msg = msg .. p.name .. " - disponivel em: " .. os.sdate ("%d/%m/%Y, as %X", Game.getStorageValue(p.stgTime)) .. "\n"
		end
	end
	if d_ < 1 then
		msg = msg .. "Todos os bosses globais estao disponiveis.\n"
	end

	player:say("*checking bosses time list*", TALKTYPE_MONSTER_SAY)
	player:getPosition():sendMagicEffect(CONST_ME_TUTORIALSQUARE)
	sendModal(player:getId(), msg)
	return true
end
