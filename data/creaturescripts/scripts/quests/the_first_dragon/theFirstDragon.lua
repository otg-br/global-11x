local bosslocal = {
    ["fallen challanger"] = {destiny = {x = 33605, y = 31023, z = 14}, time = 50, portalid = 8058}
}

function removePortal(creaturename, pos, portalid)
	local b = bosslocal[creaturename]
	local tile = Tile(Position(pos))
    tile:getItemById(portalid):remove()
    return true
end

function onDeath(creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	if not creature:isMonster() or creature:getMaster() then
		return false
	end
    local base = bosslocal[creature:getName():lower()]
	local pos = creature:getPosition()
    if base then
        doSendMagicEffect(pos, CONST_ME_TELEPORT)
        doCreateTeleport(base.portalid, base.destiny, pos)
        addEvent(removePortal, base.time*1000, creature:getName():lower(),pos, base.portalid)
        doCreatureSay(creature, "You have "..base.time.." seconds before the teleport disappear. Be faster as you can.", TALKTYPE_ORANGE_1)
		return true
    end
	local tabelaKill = {
		["angry plant"] = {action = "setAction", actionid = 14000},
		["somewhat beatable"] = {action = "checkMonster", fromPos = Position(33593, 31019,14), toPos = Position(33614, 31034, 14), nextMonster = "dragon essence", ammount = 5, shared= true},
		["dragon essence"] = {action = "boss", fromPos = Position(33593, 31019,14), toPos = Position(33614, 31034, 14), ammount = 1, nextMonster = "The First Dragon"},
		["the first dragon"] = {action = "teleportTo", fromPos = Position(33593, 31019,14), toPos = Position(33614, 31034, 14), toposition = Position(33603, 31069, 14)},
	}
	local killed = tabelaKill[creature:getName():lower()]
	if (killed) then
		if(killed.action == "setAction")then
			if not corpse then
				return true
			end
			local mtype = MonsterType(creature:getName())
			if not mtype then
				return false
			end
			local corpoid = mtype:getCorpseId()
			addEvent(function(corpoid, pos)
				local tile = Tile(pos)
				if not tile then
					return false
				end
				local corpo = tile:getItemById(corpoid)
				if not corpo then
					local it = Game.createItem(corpoid, 1, pos)
					it:setActionId(killed.actionid)
				else
					corpo:setActionId(killed.actionid)
				end
			end, 500, corpoid, pos)
		elseif (killed.action == "checkMonster") then
			local monsters =  getMonstersInArea(killed.fromPos, killed.toPos, creature:getName(), creature:getId())
			local monsters2 =  getMonstersInArea(killed.fromPos, killed.toPos, "Unbeatable Dragon")
			
			if #monsters <= 0 and #monsters2 <= 0 then
				placeSpawnRandom(killed.fromPos, killed.toPos, killed.nextMonster, 5, true, "portal_boss", 1, false, (killed.shared and true or false), "salaBoss")
			end
		elseif (killed.action == "teleportTo") then
			for _x = killed.fromPos.x, killed.toPos.x do
				for _y = killed.fromPos.y, killed.toPos.y do
					for _z = killed.fromPos.z, killed.toPos.z do
						local tile = Tile(Position(_x, _y, _z))
						if tile and tile:getCreatures() then
							for _, pid in pairs(tile:getCreatures()) do
								local tmpPlayer = Player(pid)
								if tmpPlayer then
									tmpPlayer:teleportTo(killed.toposition, true)
									tmpPlayer:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
									if tmpPlayer:getStorageValue(Storage.TheFirstDragon.theFirstDragonKilled) < 1 then
										tmpPlayer:setStorageValue(Storage.TheFirstDragon.theFirstDragonKilled,1)
									end
								end
							end
						end
					end
				end
			end
		elseif killed.action == "boss" then
			if Game.getStorageValue("pass") < os.stime() then
				creature:say("BE WARE! THE FIRST DRAGON APROACHES!", TALKTYPE_MONSTER_SAY, false, false, Position(33604, 31022, 14))
				Game.setStorageValue("pass", os.stime() + 2)			
				addEvent(placeSpawnRandom, 10000, killed.fromPos, killed.toPos, killed.nextMonster, 1, true, "portal_boss", 1, false, false, "salaBoss")
			end
		end
	end
    return true
end