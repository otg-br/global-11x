-- Script
-- 14:49 Your current position is: 33563, 30993, 14.
-- 14:49 Your current position is: 33565, 30997, 14.
function onUse(player, item, fromPosition, itemEx, toPosition)
	local fromPos = Position(33563, 30993, 14)
	local toPos = Position(33565, 30997, 14)
	local players = {}
	local frompos = Position (33537, 31005, 14)
	local topos = Position(33621, 31038, 14)
	local playersTable = {}
	if not player:getPosition():isInRange(fromPos, toPos) then
		player:sendCancelMessage("Você não esta na alavanca")
		return false
	end

	if doCheckBossRoom(player:getId(), "The First Dragon", frompos, topos) then
		for _x = fromPos.x, toPos.x do
			for _y = fromPos.y, toPos.y do
				for _z = fromPos.z, toPos.z do
					local tile = Tile(Position(_x, _y, _z))
					if tile then
						local plist = tile:getCreatures()
						for _, pid in pairs(plist) do
							local tmpPlayer = Player(pid)
							if tmpPlayer and tmpPlayer:getStorageValue(Storage.TheFirstDragon.theFirstDragonTime) < os.stime() then --tmpPlayer:getStorageValue(Storage.TheFirstDragon.portaoFinal) >= 15 then
								players[#players + 1] = tmpPlayer
							else
								player:sendCancelMessage('Some player entered the room recently')
								return true
							end
						end
					end
				end
			end
		end
		local ittable = {
			[1] = 2805,
		}
		local blockmonsters = {"dragon warden", "spirit of fertility"}
		cleanAreaQuest(frompos, topos, ittable, blockmonsters)
		local convertTable = {}
		for _, pid in pairs(players) do
			convertTable[#convertTable + 1] = pid:getId()
			table.insert(playersTable, pid:getId())
		end
		addEvent(kickPlayersAfterTime, 30*60*1000, playersTable, frompos, topos, Position(33047, 32715, 3))
		local salas ={
			[1] = Position(33572, 31012, 14),
			[2] = Position(33564, 31021, 14),
			[3] = Position(33555, 31014, 14),
			[4] = Position(33545, 31024, 14),
			[5] = Position(33554, 31031, 14),
		}
		local monsterName = "Fallen Challenger"
		local monsterPos = {
			[1] = Position(33573, 31013, 14),
			[2] = Position(33563, 31022, 14),
			[3] = Position(33554, 31013, 14),
			[4] = Position(33546, 31022, 14),
			[5] = Position(33555, 31032, 14),
		}
		local count = 0
		local passage = 1
		-- unbeatable dragon
		placeSpawnRandom(Position(33598, 31015, 14), Position(33609, 31030, 14), "Unbeatable Dragon", 5, true, "portal_boss", 1, true)
		for i = 1, 5 do 
			local monster = Game.createMonster(monsterName, monsterPos[i])
			if monster then
				monster:setStorageValue("portal_boss", 1)
			end
		end
		local salasp = {
			[30993] = salas[1],
			[30994] = salas[2],
			[30995] = salas[3],
			[30996] = salas[4],
			[30997] = salas[5],
		}
		for _, plid in pairs(players)do
			local sala = salasp[plid:getPosition().y]
			plid:teleportTo(sala, true)	
			plid:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			plid:setStorageValue(Storage.TheFirstDragon.theFirstDragonTime, os.stime() + 20*60*60) 
			-- if(count % 3 == 0)then
				-- passage = passage + 1	
			-- end
			-- if(count == (#players - 1) and (count+1) % 3 == 1) then
				-- passage = passage - 1
			-- end
		end
	end
	return true
end
