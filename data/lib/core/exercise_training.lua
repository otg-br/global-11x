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
	return
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

	if player:getItemCount(weaponId) <= 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need the training weapon in the backpack, the training has stopped.")
		LeaveTraining(playerId)
		return false
	end

	local weapon = player:getItemById(weaponId, true)
	if not weapon:isItem() or not weapon:hasAttribute(ITEM_ATTRIBUTE_CHARGES) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The selected item is not a training weapon, the training has stopped.")
		LeaveTraining(playerId)
		return false
	end

	local weaponCharges = weapon:getAttribute(ITEM_ATTRIBUTE_CHARGES)
	if not weaponCharges or weaponCharges <= 0 then
		weapon:remove(1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared.")
		LeaveTraining(playerId)
		return false
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
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your training weapon has disappeared.")
		LeaveTraining(playerId)
		return false
	end

	local vocation = player:getVocation()
	onExerciseTraining[playerId].event = addEvent(ExerciseEvent, vocation:getAttackSpeed() / configManager.getNumber(configKeys.RATE_EXERCISE_TRAINING_SPEED), playerId, tilePosition, weaponId, dummyId)
	return true
end

if onExerciseTraining == nil then
	onExerciseTraining = {}
end 