function entregarQuests(pid)
	local missions = {
		[1] = {
			[1] = {stg = Storage.WrathoftheEmperor.Questline, value = 28},
			[2] = {stg = Storage.WrathoftheEmperor.Mission01, value = 3},
			[3] = {stg = Storage.WrathoftheEmperor.Mission02, value = 3},
			[4] = {stg = Storage.WrathoftheEmperor.Mission03, value = 3},
			[5] = {stg = Storage.WrathoftheEmperor.Mission04, value = 3},
			[6] = {stg = Storage.WrathoftheEmperor.Mission05, value = 3},
			[7] = {stg = Storage.WrathoftheEmperor.Mission06, value = 4},
			[8] = {stg = Storage.WrathoftheEmperor.Mission07, value = 6},
			[9] = {stg = Storage.WrathoftheEmperor.Mission08, value = 2},
			[10] = {stg = Storage.WrathoftheEmperor.Mission09, value = 2},
		},
		[2] = {
			[1] = {stg = Storage.InServiceofYalahar.Questline, value = 48},
			[2] = {stg = Storage.InServiceofYalahar.Mission01, value = 6},
			[3] = {stg = Storage.InServiceofYalahar.Mission02, value = 8},
			[4] = {stg = Storage.InServiceofYalahar.Mission03, value = 6},
			[5] = {stg = Storage.InServiceofYalahar.Mission04, value = 6},
			[6] = {stg = Storage.InServiceofYalahar.Mission05, value = 8},
			[7] = {stg = Storage.InServiceofYalahar.Mission06, value = 5},
			[8] = {stg = Storage.InServiceofYalahar.Mission07, value = 5},
			[9] = {stg = Storage.InServiceofYalahar.Mission08, value = 4},
			[10] = {stg = Storage.InServiceofYalahar.Mission09, value = 2},
			[11] = {stg = Storage.InServiceofYalahar.Mission10, value = 2},
			[12] = {stg = Storage.InServiceofYalahar.DoorToLastFight, value = 1},
		},	
		[3] = {
			[1] = {stg = Storage.BigfootBurden.QuestLine, value = 30},
			[2] = {stg = Storage.BigfootBurden.Rank, value = 30},
			[3] = {stg = Storage.BigfootBurden.Warzone1Access, value = 2},
			[4] = {stg = Storage.BigfootBurden.Warzone2Access, value = 2},
			[5] = {stg = Storage.BigfootBurden.Warzone3Access, value = 2},
			[6] = {stg = Storage.BigfootBurden.WarzoneStatus, value = 1},
		},
		[4] = {
			[1] = {stg = Storage.TheNewFrontier.Questline, value = 24},
			[2] = {stg = Storage.TheNewFrontier.Mission01, value = 3},
			[3] = {stg = Storage.TheNewFrontier.Mission02, value = 6},
			[4] = {stg = Storage.TheNewFrontier.Mission03, value = 3},
			[5] = {stg = Storage.TheNewFrontier.Mission04, value = 2},
			[6] = {stg = Storage.TheNewFrontier.Mission05, value = 7},
			[7] = {stg = Storage.TheNewFrontier.Mission06, value = 3},
			[8] = {stg = Storage.TheNewFrontier.Mission07, value = 3},
			[9] = {stg = Storage.TheNewFrontier.Mission08, value = 2},
			[10] = {stg = Storage.TheNewFrontier.Mission09, value = 3},
			[11] = {stg = Storage.TheNewFrontier.Mission10, value = 1}
		},
		[5] = {
			[1] = {stg = Storage.TheInquisition.Questline, value = 18},
			[2] = {stg = Storage.TheInquisition.Mission01, value = 7},
			[3] = {stg = Storage.TheInquisition.Mission02, value = 3},
			[4] = {stg = Storage.TheInquisition.Mission03, value = 6},
			[5] = {stg = Storage.TheInquisition.Mission04, value = 3},
			[6] = {stg = Storage.TheInquisition.Mission05, value = 3},
			[7] = {stg = Storage.TheInquisition.Mission06, value = 3},
			[8] = {stg = Storage.TheInquisition.Mission07, value = 1},
			[9] = {stg = Storage.PitsOfInferno.ThronePumin, value = 1} -- Just for let them pass trought the portal
		},
		[6] = {
			[1] = {stg = Storage.TravellingTrader.Questline, value = 1},
			[2] = {stg = Storage.TravellingTrader.Mission01, value = 2},
			[3] = {stg = Storage.TravellingTrader.Mission02, value = 5},
			[4] = {stg = Storage.TravellingTrader.Mission03, value = 3},
			[5] = {stg = Storage.TravellingTrader.Mission04, value = 3},
			[6] = {stg = Storage.TravellingTrader.Mission05, value = 3},
			[7] = {stg = Storage.TravellingTrader.Mission06, value = 2},
			[8] = {stg = Storage.TravellingTrader.Mission07, value = 1},
		},
		[7] = {
			[1] = {stg = Storage.ExplorerSociety.QuestLine, value = 1},
			[2] = {stg = Storage.ExplorerSociety.Mission01, value = 4},
			[3] = {stg = Storage.ExplorerSociety.Mission02, value = 3},
			[4] = {stg = Storage.ExplorerSociety.Mission03, value = 9},
			[5] = {stg = Storage.ExplorerSociety.Mission04, value = 10},
			[6] = {stg = Storage.ExplorerSociety.Mission05, value = 3},
			[7] = {stg = Storage.ExplorerSociety.Mission06, value = 3},
			[8] = {stg = Storage.ExplorerSociety.Mission07, value = 3},
			[9] = {stg = Storage.ExplorerSociety.Mission08, value = 3},
			[10] = {stg = Storage.ExplorerSociety.Mission09, value = 3},
			[11] = {stg = Storage.ExplorerSociety.Mission10, value = 3},
			[12] = {stg = Storage.ExplorerSociety.Mission11, value = 3},			
			[13] = {stg = Storage.ExplorerSociety.Mission12, value = 3},
			[14] = {stg = Storage.ExplorerSociety.Mission13, value = 5},
			[15] = {stg = Storage.ExplorerSociety.Mission14, value = 1},
			[16] = {stg = Storage.ExplorerSociety.Mission15, value = 3},
			[17] = {stg = Storage.ExplorerSociety.Mission16, value = 3},
			[18] = {stg = Storage.ExplorerSociety.Mission17, value = 3}
		},
		[8] = {
			[1] = {stg = Storage.SearoutesAroundYalahar.TownsCounter, value = 8},
			[2] = {stg = Storage.SearoutesAroundYalahar.AbDendriel, value = 1},
			[3] = {stg = Storage.SearoutesAroundYalahar.Darashia, value = 1},
			[4] = {stg = Storage.SearoutesAroundYalahar.Venore, value = 1},
			[5] = {stg = Storage.SearoutesAroundYalahar.Ankrahmun, value = 1},
			[6] = {stg = Storage.SearoutesAroundYalahar.PortHope, value = 1},
			[7] = {stg = Storage.SearoutesAroundYalahar.Thais, value = 1},
			[8] = {stg = Storage.SearoutesAroundYalahar.LibertyBay, value = 1},
			[9] = {stg = Storage.SearoutesAroundYalahar.Carlin, value = 1},
		},
		[9] = {
			[1] = {stg = Storage.TheApeCity.Started, value = 1},
			[2] = {stg = Storage.TheApeCity.Questline, value = 18},
			[3] = {stg = Storage.TheApeCity.ShamanOufit, value = 1},
			[4] = {stg = Storage.DeeperBanutaShortcut, value = 1}
		},
		[10] = {
			[1] = {stg = Storage.secretLibrary.Questlog, value = 1},
			[2] = {stg = Storage.secretLibrary.SmallIslands.Questline, value = 1},
			[3] = {stg = Storage.secretLibrary.LiquidDeath.Questline, value = 2},
			[4] = {stg = Storage.secretLibrary.Asuras.Questline, value = 1},
			[5] = {stg = Storage.secretLibrary.FalconBastion.Questline, value = 1},
			[6] = {stg = Storage.secretLibrary.Darashia.Questline, value = 1},
			[7] = {stg = Storage.secretLibrary.MoTA.Questline, value = 2},
			[8] = {stg = Storage.secretLibrary.Asuras.flammingOrchid, value = 1}		
		},
		[11] = {
			[1] = {stg = Storage.DreamCourts.Main.Questline, value = 1},
			[2] = {stg = Storage.DreamCourts.WardStones.Questline, value = 2},
			[3] = {stg = Storage.DreamCourts.UnsafeRelease.Questline, value = 3},
			[4] = {stg = Storage.DreamCourts.HauntedHouse.Questline, value = 6},
			[5] = {stg = Storage.DreamCourts.TheSevenKeys.Questline, value = 2},
			[6] = {stg = Storage.DreamCourts.WardStones.Count, value = 8},
			[7] = {stg = Storage.DreamCourts.TheSevenKeys.Count, value = 7},
			[8] = {stg = Storage.DreamCourts.TheSevenKeys.doorMedusa, value = 1},
			[9] = {stg = Storage.DreamCourts.DreamScar.Permission, value = 1}
		},
		[12] = {
			[1] = {stg = Storage.BarbarianTest.Questline, value = 8},
			[2] = {stg = Storage.BarbarianTest.Mission01, value = 3},
			[3] = {stg = Storage.BarbarianTest.Mission02, value = 3},
			[4] = {stg = Storage.BarbarianTest.Mission03, value = 3}
		},
		[13] = {
			[1] = {stg = Storage.TheIceIslands.Questline, value = 1},
			[2] = {stg = Storage.TheIceIslands.Mission01, value = 3},
			[3] = {stg = Storage.TheIceIslands.Mission02, value = 5},
			[4] = {stg = Storage.TheIceIslands.Mission03, value = 3},
			[5] = {stg = Storage.TheIceIslands.Mission04, value = 2},
			[6] = {stg = Storage.TheIceIslands.Mission05, value = 6},
			[7] = {stg = Storage.TheIceIslands.Mission06, value = 8},
			[8] = {stg = Storage.TheIceIslands.Mission07, value = 3},
			[9] = {stg = Storage.TheIceIslands.Mission08, value = 4},
			[10] = {stg = Storage.TheIceIslands.Mission09, value = 2},
			[11] = {stg = Storage.TheIceIslands.Mission10, value = 2},
			[12] = {stg = Storage.TheIceIslands.Mission11, value = 2},
			[13] = {stg = Storage.TheIceIslands.Mission12, value = 6}
		},
		[14] = {
			[1] = {stg = Storage.DangerousDepths.Questline, value = 1},
			[2] = {stg = Storage.DangerousDepths.Acessos.LavaPumpWarzoneVI, value = 1},
			[3] = {stg = Storage.DangerousDepths.Acessos.LavaPumpWarzoneV, value = 1},
			[4] = {stg = Storage.DangerousDepths.Acessos.LavaPumpWarzoneIV, value = 1}
		},
		[15] = {
			[1] = {stg = Storage.ForgottenKnowledge.Tomes, value = 1},
			[2] = {stg = Storage.ForgottenKnowledge.AccessIce, value = 1},
			[3] = {stg = Storage.ForgottenKnowledge.AccessGolden, value = 1},
			[4] = {stg = Storage.ForgottenKnowledge.AccessViolet, value = 1},
			[5] = {stg = Storage.ForgottenKnowledge.AccessEarth, value = 1},
			[6] = {stg = Storage.ForgottenKnowledge.AccessDeath, value = 1},
			[7] = {stg = Storage.ForgottenKnowledge.AccessFire, value = 1}
		},
		[16] = {
			[1] = {stg = Storage.TheFirstDragon.tamorilTasks, value = 1},
			[2] = {stg = Storage.TheFirstDragon.tamorilTasksPower, value = 0},
			[3] = {stg = Storage.TheFirstDragon.tamorilTasksKnowledge, value = 0},
			[4] = {stg = Storage.TheFirstDragon.tamorilTasksLife, value = 0},
			[5] = {stg = Storage.TheFirstDragon.tamorilTasksTreasure, value = 0},
			[6] = {stg = Storage.TheFirstDragon.tamorilTasksTreasure, value = 0}
		},
		[17] = {
			[1] = {stg = Storage.CultsOfTibia.Questline, value = 1},
			[2] = {stg = Storage.CultsOfTibia.Minotaurs.Mission, value = 1},
			[3] = {stg = Storage.CultsOfTibia.MotA.Mission, value = 1},
			[4] = {stg = Storage.CultsOfTibia.Barkless.Mission, value = 1},
			[5] = {stg = Storage.CultsOfTibia.Misguided.Mission, value = 1},
			[6] = {stg = Storage.CultsOfTibia.Orcs.Mission, value = 1},
			[7] = {stg = Storage.CultsOfTibia.Life.Mission, value = 1},
			[8] = {stg = Storage.CultsOfTibia.Humans.Mission, value = 1}
		},
		[18] = {
			[1] = {stg = Storage.TheShatteredIsles.DefaultStart, value = 1},
			[2] = {stg = Storage.TheShatteredIsles.ADjinnInLove, value = 5},
			[3] = {stg = Storage.TheShatteredIsles.APoemForTheMermaid, value = 3},
			[4] = {stg = Storage.TheShatteredIsles.AccessToGoroma, value = 1},
			[5] = {stg = Storage.TheShatteredIsles.AccessToLagunaIsland, value = 1},
			[6] = {stg = Storage.TheShatteredIsles.AccessToMeriana, value = 1},
			[7] = {stg = Storage.TheShatteredIsles.TheCounterspell, value = 4},
			[8] = {stg = Storage.TheShatteredIsles.TheErrand, value = 2},
			[9] = {stg = Storage.TheShatteredIsles.TheGovernorDaughter, value = 3}
		}
	}
	-- Achievements que são ganhos nas quests acima
	local achievements = {
		[1] = 'Recognised Trader',
		[2] = 'Explorer',
		[3] = 'Sea Scout',
		[4] = 'Friend of the Apes'
	}
	local outfits = {
		[1] = {m = 335, f = 336},
		[2] = {m = 288, f = 289},
		[3] = {m = 154, f = 158},
		[4] = {m = 251, f = 252},
		[5] = {m = 151, f = 155}
	}
	local player = Player(pid)
	if player then
		for i = 1, #missions do
			for j = 1, #missions[i] do
				player:setStorageValue(missions[i][j].stg, missions[i][j].value or -1)
			end
		end
		for k = 1, #achievements do
			player:addAchievement(achievements[k])
		end
		for _, outfit in pairs(outfits) do
			player:addOutfit(outfit.m)
			player:addOutfit(outfit.f)
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A few missions was added to your questlog. Have a nice game!")
	end
end

local vocations = {
	[0] = {heal = 1.0, damage = 1.0}, -- none or monster
	[1] = {heal = 1.0, damage = 1.1}, -- sorcerer
	[2] = {heal = 1.541, damage = 1.1}, -- druid
	[3] = {heal = 1.0, damage = 1.0}, -- paladin
	[4] = {heal = 1.0, damage = 0.8}, -- knight
}

function Vocation.getSpellDamage(self, min, max, type)
	local base = vocations[self:getBase():getId()]
	if not base then
		return min, max
	end

	local mult = base.damage
	if type then
		mult = base.heal
	end

	return (min*mult), (max*mult)
end

function Creature.getSpellDamage(self, min, max, type)
	if not self:isPlayer() then
		return Vocation(0):getSpellDamage(min, max, type)
	end
	local vocation = self:getVocation()

	return vocation:getSpellDamage(min, max, type)
end

function createClass(parent)
	local newClass = {}
	function newClass:new(instance)
		local instance = instance or {}
		setmetatable(instance, {__index = newClass})
		return instance
	end

	if(parent ~= nil) then
		setmetatable(newClass, {__index = parent})
	end

	function newClass:getSelf()
		return newClass
	end

	function newClass:getParent()
		return baseClass
	end

	function newClass:isa(class)
		local tmp = newClass
		while(tmp ~= nil) do
			if(tmp == class) then
				return true
			end

			tmp = tmp:getParent()
		end

		return false
	end
	
	function newClass:setAttributes(attributes)
		for k, v in pairs(attributes) do
			newClass[k] = v
		end
	end

	return newClass
end

function doCheckBossRoom(pid, bossName, fromPos, toPos)
	local player = Player(pid)
	if player then
		-- Checa se há players
		for x = fromPos.x, toPos.x do
			for y = fromPos.y, toPos.y do
				for z = fromPos.z, toPos.z do
					local sqm = Tile(Position(x, y, z))
					if sqm then
						if sqm:getTopCreature() and sqm:getTopCreature():isPlayer() then
							player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You must wait. Someone is challenging '..bossName..' now.')
							return false
						end
					end
				end
			end
		end
		-- Limpa sala caso haja monstros sem jogadores lá dentro
		for x = fromPos.x, toPos.x do
			for y = fromPos.y, toPos.y do
				for z = fromPos.z, toPos.z do
					local sqm = Tile(Position(x, y, z))
					if sqm and sqm:getTopCreature() then
						local monster = sqm:getTopCreature()
						if monster then
							monster:remove()
						end
					end
				end
			end
		end
	end
	return true
end	

function debugAddEvent(file, ... )
	local event = addEvent(...)
	print(string.format("Event ID %d in file %s", event, file))

	return event
end
