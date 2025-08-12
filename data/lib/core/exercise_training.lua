ExerciseWeaponsTable = {
	-- KNIGHT
	[33082] = { skill = SKILL_SWORD, allowFarUse = true },
	[33083] = { skill = SKILL_AXE, allowFarUse = true },
	[33084] = { skill = SKILL_CLUB, allowFarUse = true },
	-- PALADIN
	[33085] = { skill = SKILL_DISTANCE, effect = CONST_ANI_SIMPLEARROW, allowFarUse = true },
	-- DRUID
	[33086] = { skill = SKILL_MAGLEVEL, effect = CONST_ANI_SMALLICE, allowFarUse = true },
	-- SORCERER
	[33087] = { skill = SKILL_MAGLEVEL, effect = CONST_ANI_FIRE, allowFarUse = true },
	-- KNIGHT (Free)
	[32124] = { skill = SKILL_SWORD, allowFarUse = true },
	[32125] = { skill = SKILL_AXE, allowFarUse = true },
	[32126] = { skill = SKILL_CLUB, allowFarUse = true },
	-- PALADIN (Free)
	[32127] = { skill = SKILL_DISTANCE, effect = CONST_ANI_SIMPLEARROW, allowFarUse = true },
	-- DRUID (Free)
	[32128] = { skill = SKILL_MAGLEVEL, effect = CONST_ANI_SMALLICE, allowFarUse = true },
	-- SORCERER (Free)
	[32129] = { skill = SKILL_MAGLEVEL, effect = CONST_ANI_FIRE, allowFarUse = true }
}

FreeDummies = {32142, 32143, 32144, 32145, 32146, 32147, 32148, 32149}
HouseDummies = {32143, 32144, 32145, 32146, 32147, 32148}
MaxAllowedOnADummy = configManager.getNumber(configKeys.MAX_ALLOWED_ON_A_DUMMY)

local magicLevelRate = configManager.getNumber(configKeys.RATE_MAGIC)
local skillLevelRate = configManager.getNumber(configKeys.RATE_SKILL)

function LeaveTraining(playerId)
	if onExerciseTraining[playerId] then
		stopEvent(onExerciseTraining[playerId].event)
		onExerciseTraining[playerId] = nil
	end

	local player = Player(playerId)
	if player then
		player:setStorageValue(Storage.isTrainingStorage, -1)
	end
	return
end

function findExerciseWeaponInStoreInbox(player, weaponId)
	for i = 0, 15 do 
		local container = player:getContainerById(i)
		if container and container:getId() == ITEM_STORE_INBOX then
			for j = 0, container:getSize() - 1 do
				local item = container:getItem(j)
				if item and item:getId() == weaponId and item:hasAttribute(ITEM_ATTRIBUTE_CHARGES) then
					local charges = item:getAttribute(ITEM_ATTRIBUTE_CHARGES)
					if charges and charges > 0 then
						return item
					end
				end
			end
			break
		end
	end
	return nil
end

function getExerciseWeapon(player, weaponId)
	local weapon = player:getItemById(weaponId, true)
	if weapon and weapon:isItem() and weapon:hasAttribute(ITEM_ATTRIBUTE_CHARGES) then
		local charges = weapon:getAttribute(ITEM_ATTRIBUTE_CHARGES)
		if charges and charges > 0 then
			return weapon
		end
	end
	
	if player:getVipDays() > os.time() then
		return findExerciseWeaponInStoreInbox(player, weaponId)
	end
	
	return nil
end

function ExerciseEvent(playerId, tilePosition, weaponId, dummyId)
	local player = Player(playerId)
	if not player then
		return LeaveTraining(playerId)
	end

	if not Tile(tilePosition):getItemById(dummyId) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Someone has moved the dummy, the training has stopped.")
		LeaveTraining(playerId)
		return false
	end

	local playerPosition = player:getPosition()
	if not player:getTile():hasFlag(TILESTATE_PROTECTIONZONE) and not staminaEvents[playerId] then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are no longer in a protection zone, the training has stopped.")
		LeaveTraining(playerId)
        return true
    end

	local weapon = getExerciseWeapon(player, weaponId)
	if not weapon then
		if player:getVipDays() > os.time() then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need the training weapon in your backpack or store inbox, the training has stopped.")
		else
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need the training weapon in the backpack, the training has stopped.")
		end
		LeaveTraining(playerId)
		return false
	end

	local weaponCharges = weapon:getAttribute(ITEM_ATTRIBUTE_CHARGES)
	if not weaponCharges or weaponCharges <= 0 then
		weapon:remove(1)
		
		local nextWeapon = getExerciseWeapon(player, weaponId)
		if nextWeapon then
			if player:getVipDays() > os.time() then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared. Automatically using another one! [VIP Feature]")
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared. Using another one from your backpack.")
			end
			local vocation = player:getVocation()
			onExerciseTraining[playerId].event = addEvent(ExerciseEvent, vocation:getAttackSpeed() / configManager.getNumber(configKeys.RATE_EXERCISE_TRAINING_SPEED), playerId, tilePosition, weaponId, dummyId)
			return true
		else
			if player:getVipDays() > os.time() then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared. No more exercise weapons found in backpack or store inbox.")
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared. You need to equip another one to continue training.")
			end
			LeaveTraining(playerId)
			return false
		end
	end

	local isMagic = ExerciseWeaponsTable[weaponId].skill == SKILL_MAGLEVEL
	local bonusDummy = 1

	if table.contains(HouseDummies, dummyId) then
		bonusDummy = 1.5 -- 50%
	elseif table.contains(FreeDummies, dummyId) then
		bonusDummy = 1
	end

	if isMagic then
		player:addManaSpent(500 * bonusDummy)
	else
		player:addSkillTries(ExerciseWeaponsTable[weaponId].skill, 7 * bonusDummy)
	end

	weapon:setAttribute(ITEM_ATTRIBUTE_CHARGES, (weaponCharges - 1))
	tilePosition:sendMagicEffect(CONST_ME_HITAREA)

	if ExerciseWeaponsTable[weaponId].effect then
		playerPosition:sendDistanceEffect(tilePosition, ExerciseWeaponsTable[weaponId].effect)
	end

	if weapon:getAttribute(ITEM_ATTRIBUTE_CHARGES) <= 0 then
		weapon:remove(1)
		
		local nextWeapon = getExerciseWeapon(player, weaponId)
		if nextWeapon then
			if player:getVipDays() > os.time() then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared. Automatically using another one! [VIP Feature]")
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared. Using another one from your backpack.")
			end
			local vocation = player:getVocation()
			onExerciseTraining[playerId].event = addEvent(ExerciseEvent, vocation:getAttackSpeed() / configManager.getNumber(configKeys.RATE_EXERCISE_TRAINING_SPEED), playerId, tilePosition, weaponId, dummyId)
			return true
		else
			if player:getVipDays() > os.time() then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared. No more exercise weapons found in backpack or store inbox.")
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared. You need to equip another one to continue training.")
			end
			LeaveTraining(playerId)
			return false
		end
	end

	local vocation = player:getVocation()
	onExerciseTraining[playerId].event = addEvent(ExerciseEvent, vocation:getAttackSpeed() / configManager.getNumber(configKeys.RATE_EXERCISE_TRAINING_SPEED), playerId, tilePosition, weaponId, dummyId)
	return true
end

if onExerciseTraining == nil then
	onExerciseTraining = {}
end