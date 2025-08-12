local exerciseTraining = Action()
function exerciseTraining.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local playerId = player:getId()
	local targetId = target:getId()
	
	local ownerId = item:getCustomAttribute("OwnerWeapon")
    if ownerId and ownerId ~= player:getGuid() then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are not the owner of this weapon.")
        return true
    end

	if target:isItem() and (table.contains(HouseDummies, targetId) or table.contains(FreeDummies, targetId)) then
		if onExerciseTraining[playerId] then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Training stopped manually.")
			LeaveTraining(playerId)
			return true
		end

		local playerPos = player:getPosition()
		if not ExerciseWeaponsTable[item.itemid].allowFarUse and (playerPos:getDistance(target:getPosition()) > 1) then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Get closer to the dummy.")
			return true
		end
		
		if not player:getTile():hasFlag(TILESTATE_PROTECTIONZONE) and not staminaEvents[playerId] then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need to be in a protection zone.")
			return true
		end
		
		local playerHouse = player:getTile():getHouse()
		local targetPos = target:getPosition()
		local targetHouse = Tile(targetPos):getHouse()

		if table.contains(HouseDummies, targetId) then
			if playerHouse ~= targetHouse then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You must be inside the house to use this dummy.")
				return true
			end
			local playersOnDummy = 0
			for _, playerTraining in pairs(onExerciseTraining) do
				if playerTraining.dummyPos == targetPos then
					playersOnDummy = playersOnDummy + 1
				end

				if playersOnDummy == MaxAllowedOnADummy then
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "That exercise dummy is busy.")
					return true
				end
			end
		end

		if player:getStorageValue(Storage.ExerciseDummyExhaust) > os.time() then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This exercise dummy can only be used after a 30 seconds cooldown.")
			return true
		end

		onExerciseTraining[playerId] = {}
		if not onExerciseTraining[playerId].event then
			onExerciseTraining[playerId].event = addEvent(ExerciseEvent, 0, playerId, targetPos, item.itemid, targetId)
			onExerciseTraining[playerId].dummyPos = targetPos
			player:setStorageValue(Storage.ExerciseDummyExhaust, os.time() + 30)
			player:setStorageValue(Storage.isTrainingStorage, 1)
			
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are training with the exercise dummy, good luck!")
		end
		return true
	end
	return false
end

for weaponId, weapon in pairs(ExerciseWeaponsTable) do
	exerciseTraining:id(weaponId)
	if weapon.allowFarUse then
		exerciseTraining:allowFarUse(true)
	end
end
exerciseTraining:register()

local exerciseTraining_Login = CreatureEvent("ExerciseTraining_Login")
function exerciseTraining_Login.onLogin(player)

	if onExerciseTraining[player:getId()] then -- onLogin & onLogout
		stopEvent(onExerciseTraining[player:getId()].event)
		onExerciseTraining[player:getId()] = nil
	end
	
	player:setStorageValue(Storage.isTrainingStorage, -1)

	return true
end
exerciseTraining_Login:register()

local exerciseTraining_Logout = CreatureEvent("ExerciseTraining_Logout")
function exerciseTraining_Logout.onLogout(player)
	local playerId = player:getId()
	if onExerciseTraining[playerId] then
		stopEvent(onExerciseTraining[playerId].event)
		onExerciseTraining[playerId] = nil
	end
	return true
end
exerciseTraining_Logout:register()