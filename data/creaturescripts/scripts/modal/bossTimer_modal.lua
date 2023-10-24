local bossesTimer = {
		[1] =  {
			{id = 1, name = "Anomaly", stgTime = 14321},
			{id = 2, name = "Rupture", stgTime = 14323},
			{id = 3, name = "Realityquake", stgTime = 14325},
			{id = 4, name = "Eradicator", stgTime = 14329},
			{id = 5, name = "Outburst", stgTime = 14331},
			{id = 6, name = "World Devourer", stgTime = 14333},
		},
		[2] = {
			{id = 1, name = "Grand Master Oberon", stgTime = Storage.secretLibrary.FalconBastion.oberonTimer},		
			{id = 2, name = "The Blazing Rose", stgTime = Storage.secretLibrary.Asuras.blazingTimer},
			{id = 3, name = "The Diamond Blossom", stgTime = Storage.secretLibrary.Asuras.diamondTimer},
			{id = 4, name = "The Lily Of Night", stgTime = Storage.secretLibrary.Asuras.darkTimer},
		},
		[3] = {
			{id = 1, name = "The Count of The Core", stgTime = Storage.DangerousDepths.Bosses.theCountOfTheCore},
			{id = 2, name = "The Baron From Below", stgTime = Storage.DangerousDepths.Bosses.theBaronFromBelow},
			{id = 3, name = "The Duke of The Depths", stgTime = Storage.DangerousDepths.Bosses.theDukeOfTheDepths},
			{id = 4, name = "Gnomevil", stgTime = 790014},
			{id = 5, name = "Abyssador", stgTime = 790016},
			{id = 6, name = "Deathstrike", stgTime = 790015},
		},
		[4] = {
			{id = 1, name = "The False God", stgTime = Storage.CultsOfTibia.Minotaurs.bossTimer},
			{id = 2, name = "Leiden", stgTime = Storage.CultsOfTibia.Barkless.bossTimer},
			{id = 3, name = "Essence of Malice", stgTime = Storage.CultsOfTibia.Humans.bossTimer},
			{id = 4, name = "The Sandking", stgTime = Storage.CultsOfTibia.Life.bossTimer},
			{id = 5, name = "The Souldespoiler", stgTime = Storage.CultsOfTibia.Misguided.bossTimer},
			{id = 6, name = "The Unarmored Voidborn", stgTime = Storage.CultsOfTibia.Orcs.bossTimer},
			{id = 7, name = "The Source of Corruption", stgTime = Storage.CultsOfTibia.finalBoss.bossTimer},
		},
		[5] = {
			{id = 1, name = "Zorvorax", stgTime = Storage.TheFirstDragon.zorvoraxTime},
			{id = 2, name = "Kalyassa", stgTime = Storage.TheFirstDragon.kalyassaTime},
			{id = 3, name = "Tazhadur", stgTime = Storage.TheFirstDragon.tazhadurTime},
			{id = 4, name = "Gelidrazah The Frozen", stgTime = Storage.TheFirstDragon.gelidrazahTime},
			{id = 5, name = "The First Dragon", stgTime = Storage.TheFirstDragon.theFirstDragonTime},
		},
		[6] = {
			{id = 1, name = "Kroazur", stgTime = Storage.ThreatenedDreams.Dream.KroazurTimer},
		},
		[7] = {
			{id = 1, name = "Alptramun", stgTime = Storage.DreamCourts.DreamScar.alptramunTimer},
			{id = 2, name = "Izcandar the Banished", stgTime = Storage.DreamCourts.DreamScar.izcandarTimer},
			{id = 3, name = "Malofur Mangrinder", stgTime = Storage.DreamCourts.DreamScar.malofurTimer},
			{id = 4, name = "Maxxenius", stgTime = Storage.DreamCourts.DreamScar.maxxeniusTimer},
			{id = 5, name = "Plagueroot", stgTime = Storage.DreamCourts.DreamScar.plaguerootTimer},
		}
}

local options = {
	[1] = "Heart of Destruction",
	[2] = "The Secret Library",
	[3] = "Warzone (all)",
	[4] = "Cults of Tibia",
	[5] = "The First Dragon",
	[6] = "Threatened Dreams",
	[7] = "The Dream Courts"
}

local returnvalue = {
	[Modal.bossesList] = Modal.bossTime

}

if not __lastop then
	__lastop = {}
end

function onModalWindow(player, modalWindowId, buttonId, choiceId) 
    player:unregisterEvent("ModalWindow_bossTimer")

	if buttonId == 111 then
		__lastop[player:getId()] = nil
		return true
	end


    if modalWindowId == Modal.bossTimer or (Modal.bossesFinal == modalWindowId and buttonId == 110) then
    	player:registerEvent("ModalWindow_bossTimer")
    	-- listando outras op??es:
		-- Texto
		local title = 'Bosses from '.. options[__lastop[player:getId()] or choiceId] .. ''
		if Modal.bossesFinal ~= modalWindowId then
			__lastop[player:getId()] = choiceId
		end
		local desc = 'Choose the boss that you want to check it\'s time.'
		local window = ModalWindow(Modal.bossesList, title, desc)

		window:addButton(110, 'Okay')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Close')
		window:setDefaultEscapeButton(111)

		local choices = bossesTimer[__lastop[player:getId()] or choiceId]
		for i = 1, #choices do
			window:addChoice(i, choices[i].name)
		end

		window:sendToPlayer(player)
    	return true

    elseif modalWindowId == Modal.bossesList then
    	player:registerEvent("ModalWindow_bossTimer")
		local title = 'Time respawn'
		local info = bossesTimer[__lastop[player:getId()]][choiceId]
		local desc = ''
		local storage = info.stgTime
		local bossName = info.name
		local timeCheck = ""
		if (player:getStorageValue(storage) >= os.stime()) then
			timeCheck = timeCheck ..  os.sdate ("%d/%m/%Y, s %X", storage) .. ". "
		else
			timeCheck = timeCheck .. "já disponível."
		end	
		desc = "[" .. bossName .. "] Disponível em: " .. timeCheck


		local window = ModalWindow(Modal.bossesFinal, title, desc)

		window:addButton(110, 'Back')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Close')
		window:setDefaultEscapeButton(111)

		window:sendToPlayer(player)
	elseif modalWindowId == Modal.bossesFinal then
    	if buttonId == 110 then
			local title = "-- Choose a quest --"
			local message = "Which quest do you want to see it's bosses?"
		 
			local window = ModalWindow(Modal.bossTimer, title, message)
			
			for i = 1, #options do
				window:addChoice(i, options[i])
			end
			
			window:addButton(100, 'Okay')
			window:setDefaultEnterButton(100)
			window:addButton(101, 'Close')
			window:setDefaultEscapeButton(101)
		 
			window:sendToPlayer(player)
    		return true
    	end

    	player:registerEvent("ModalWindow_bossTimer")
    	-- listando outras op??es:
		-- Texto
		local title = 'Bosses from '.. options[__lastop[player:getId()]] .. ''
		local desc = 'Choose the boss that you want to check it\'s time.'
		local window = ModalWindow(Modal.bossesList, title, desc)

		window:addButton(110, 'Okay')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Close')
		window:setDefaultEscapeButton(111)

		local choices = bossesTimer[__lastop[player:getId()]]
		for i = 1, #choices do
			window:addChoice(i, choices[i].name)
		end

		window:sendToPlayer(player)
    	return true
    end

	return true
end
