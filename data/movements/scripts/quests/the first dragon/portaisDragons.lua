local action_id = {

	-- Zorvorax
	[14001] = {position = {x = 32007, y = 32395, z = 8}, monsterName = "Zorvorax", monsterPosition = Position(32017, 32396, 8), fromPosition = Position(32001, 32387, 8), toPosition = Position(32030, 32406, 8), storage = Storage.TheFirstDragon.tamorilTasksLife, value = 3, teleportPos = Position(33001, 31594, 11) , stgTime = Storage.TheFirstDragon.zorvoraxTime},  -- Entrada OK
	-- Kalyassa
	[14002] = {position = {x = 32077, y = 32457, z = 8}, monsterName = "Kalyassa", monsterPosition = Position(32080, 32457, 8), fromPosition = Position(32069, 32448, 8), toPosition = Position(32091, 32470, 8), storage = Storage.TheFirstDragon.tamorilTasksTreasure, value = 5, teleportPos = Position(33160, 31321, 5), stgTime = Storage.TheFirstDragon.kalyassaTime},  -- Entrada OK
	-- Tazhadur
	[14003] = {position = {x = 32014, y = 32467, z = 8}, monsterName = "Tazhadur", monsterPosition = Position(32019, 32467, 8), fromPosition = Position(32002, 32455, 8), toPosition = Position(32032, 32475, 8), storage = Storage.TheFirstDragon.tamorilTasksPower, value = 1, teleportPos = Position( 33234, 32274, 12), stgTime = Storage.TheFirstDragon.tazhadurTime},  -- Entrada OK
	-- Gelidrazah the Frozen
	[14004] = {position = {x = 32077, y = 32403, z = 8}, monsterName = "Gelidrazah the Frozen", monsterPosition = Position(32077, 32400, 8), fromPosition = Position(32067, 32389, 8), toPosition = Position(32092, 32409, 8), storage = Storage.TheFirstDragon.tamorilTasksKnowledge, value = 3, teleportPos = Position(32277, 31366, 4), stgTime = Storage.TheFirstDragon.gelidrazahTime},  -- Entrada OK
	
}

-- ENTRANDO zorvoraxTime = 14011, kalyassaTime = 14012, tazhadurTime = 14013, gelidrazahTime = 14014,

function onStepIn(creature, item, position, fromPosition)

	local action = action_id[item.actionid]
	if action then
		local player = creature:getPlayer()
		if player == nil then
			return false
		end

		if(player:getStorageValue(action.storage) < action.value) then
				player:teleportTo(fromPosition)
				player:sendCancelMessage("You are not allowed to enter yet.") 
			return false
		end
		if(isPlayerInArea(action.fromPosition, action.toPosition)) then
				player:teleportTo(fromPosition)
				player:sendCancelMessage('It looks like someone else is already inside.')
			return false
		end
		if(player:getStorageValue(action.stgTime) > os.stime())then
			player:teleportTo(fromPosition)
			player:sendCancelMessage('You need to wait for 20 hours to face this monster again.')
			return false
		end

		local fromPos = action.fromPosition
		local toPos = action.toPosition
		for _x = fromPos.x, toPos.x do
			for _y = fromPos.y, toPos.y do
				for _z = fromPos.z, toPos.z do
					local tile = Tile(Position(_x,_y,_z))
					if tile and tile:getTopCreature() then
						for _, pid in pairs(tile:getCreatures()) do
							local mt = Monster(pid)
							if(mt and mt:isMonster() and mt:getName():lower() == action.monsterName:lower() and not mt:getMaster() )then
								mt:remove()
							end
						end
					end
				end
			end
		end			
		if(action.monsterName ~= "") then
			-- broadcastMessage(""..item.actionid)
			local monster = Game.createMonster(action.monsterName, action.monsterPosition)
			if monster then
				monster:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				monster:setStorageValue("playername", player:getName())
			else
				player:sendCancelMessage('Monster not found, report to gamemaster. E01')
				return false
			end
		else
			player:sendCancelMessage('Monster not found, report to gamemaster. E02')
			return false
		end	
		player:setStorageValue(action.stgTime, os.stime() + 20*60*60)
		player:teleportTo(action.position)
		kickerPlayerRoomAfferMin(player:getName(), action.fromPosition, action.toPosition, action.teleportPos, "You are kicked.", action.monsterName, 10, true)
		player:say("You have ten minutes to kill and loot this boss, else you will lose that chance and will be kicked out.", TALKTYPE_MONSTER_SAY)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end
end
