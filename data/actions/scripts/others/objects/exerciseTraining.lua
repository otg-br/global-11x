local skills = {
	[33082] = {id = SKILL_SWORD, voc = {4}}, -- KNIGHT
	[33083] = {id = SKILL_AXE, voc = {4}}, -- KNIGHT
	[33084] = {id = SKILL_CLUB, voc = {4}}, -- KNIGHT
	[33085] = {id = SKILL_DISTANCE, voc = {3}, range = CONST_ANI_SIMPLEARROW}, -- PALADIN
	[33086] = {id = SKILL_MAGLEVEL, voc = {1, 2, 3, 4}, range = CONST_ANI_SMALLICE}, -- DRUID
	[33087] = {id = SKILL_MAGLEVEL, voc = {1, 2, 3, 4}, range = CONST_ANI_FIRE}, -- SORCERER

	-- free
	[32124] = {id = SKILL_SWORD, voc = {4}}, -- KNIGHT
	[32125] = {id = SKILL_AXE, voc = {4}}, -- KNIGHT
	[32126] = {id = SKILL_CLUB, voc = {4}}, -- KNIGHT
	[32127] = {id = SKILL_DISTANCE, voc = {3}, range = CONST_ANI_SIMPLEARROW}, -- PALADIN
	[32128] = {id = SKILL_MAGLEVEL, voc = {1, 2, 3, 4}, range = CONST_ANI_SMALLICE}, -- DRUID
	[32129] = {id = SKILL_MAGLEVEL, voc = {1, 2, 3, 4}, range = CONST_ANI_FIRE} -- SORCERER
}


local dummies = {32142, 32143, 32144, 32145, 32146, 32147, 32148, 32149}
local house_dummies = {32143, 32144, 32145, 32146, 32147, 32148}
local isTraining = 37
local isTrainingEvent = 38
local isTrainingStorage = 12835

local function start_train(pid,start_pos,itemid,fpos,t_id)
	local player = Player(pid)
	if not player then
		return
	end
	
	local b_ = 1
	if isInArray(house_dummies, t_id) then
		b_ = 1.1
	end

	local skillRate = 1.666 -- vai ser o training normal
	if itemid == 32124 or itemid == 33082 then
		skillRate = Game.getSkillStage(player:getSkillLevel(SKILL_SWORD)) * skillRate
	elseif itemid == 32125 or itemid == 33083 then
		skillRate = Game.getSkillStage(player:getSkillLevel(SKILL_AXE)) * skillRate
	elseif itemid == 32126 or itemid == 33084 then
		skillRate = Game.getSkillStage(player:getSkillLevel(SKILL_CLUB)) * skillRate
	elseif itemid == 32127 or itemid == 33085 then
		skillRate = Game.getSkillStage(player:getSkillLevel(SKILL_DISTANCE)) * skillRate
	elseif itemid == 33086 or itemid == 33087 or itemid == 32128 or itemid == 32129 then
		skillRate = (Game.getMagicLevelStage(player:getMagicLevel()) * skillRate * 50)
	end

	local pos_n = player:getPosition()
	if start_pos:getDistance(pos_n) == 0 and getTilePzInfo(pos_n) then
		if player:getItemCount(itemid) >= 1 then
			local exercise = player:getItemById(itemid, true)
			if exercise and exercise:isItem() then
				if exercise:hasAttribute(ITEM_ATTRIBUTE_CHARGES) then
					local charges_n = exercise:getAttribute(ITEM_ATTRIBUTE_CHARGES)
					if charges_n >= 1 then
						exercise:setAttribute(ITEM_ATTRIBUTE_CHARGES,(charges_n-1))

						local trainingValue = 0
						local voc = player:getVocation()
						if skills[itemid].id == SKILL_MAGLEVEL then
							local gainTicks = voc:getManaGainTicks()*3
							if gainTicks < 1 then
								gainTicks = 1
							end
							trainingValue = ((skillRate/3)*(voc:getManaGainAmount()/gainTicks))*b_
							player:addOfflineTrainingTries(skills[itemid].id, trainingValue, true)
						else
							trainingValue = ((skillRate*(voc:getAttackSpeed()/1000))/5)*b_
							player:addOfflineTrainingTries(skills[itemid].id, trainingValue, true)
						end

						fpos:sendMagicEffect(CONST_ME_HITAREA)
						if skills[itemid].range then
							pos_n:sendDistanceEffect(fpos, skills[itemid].range)
						end

						if charges_n == 1 then
							player:sendCancelMessage("Your training weapon vanished.")
							if player:getStorageValue(isTrainingEvent) > 0 then
								stopEvent(player:getStorageValue(isTrainingEvent))
								player:setStorageValue(isTrainingEvent, -1)
							end
							player:setStorageValue(isTraining, 0)
							player:setStorageValue(isTrainingStorage, - 1)
							exercise:remove(1)
							return true
						end

						local training = addEvent(start_train, voc:getAttackSpeed(), player:getId(),start_pos,itemid,fpos)
						player:setStorageValue(isTraining,1)
						player:setStorageValue(isTrainingEvent, training)
						player:setStorageValue(isTrainingStorage, 1)
					end
				end
			end
		end
	else
		player:sendCancelMessage("Your training has stopped.")
		if player:getStorageValue(isTrainingEvent) > 0 then
			stopEvent(player:getStorageValue(isTrainingEvent))
			player:setStorageValue(isTrainingEvent, -1)
		end
		player:setStorageValue(isTraining,0)
		player:setStorageValue(isTrainingStorage, - 1)
	end
	return true
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local start_pos = player:getPosition()
	if target:isItem() then
		if isInArray(dummies, target:getId()) then
			if skills[item:getId()].range == nil and (start_pos:getDistance(target:getPosition()) > 1) then
				player:sendCancelMessage("Get closer to the dummy.")
				stopEvent(training)
				return true
			end

			if not isInArray(skills[item:getId()].voc, player:getVocation():getBase():getId()) then
				player:sendCancelMessage("You don't train with this weapon.")
				return true
			end

			if player:getStorageValue(isTraining) == 1 then
				player:sendCancelMessage("You are already training.")
				return true
			end

			player:sendCancelMessage("You started training.")
			start_train(player:getId(),start_pos,item:getId(),target:getPosition(),target:getId())
		end
	end
	return true
end