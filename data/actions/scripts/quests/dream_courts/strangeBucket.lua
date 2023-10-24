local function revertEgg(position, normalEgg, mutatedEgg)
	local activeStone = Tile(position):getItemById(normalEgg)
	if activeStone then
		activeStone:transform(mutatedEgg)
	end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return true
	end
	local tPos = target:getPosition()
	local tId = target:getId()
	local r = math.random(0, 10)
	
	-- workin ids
	local mutatedEgg = 33798
	local normalEgg = 7585
	local emptyBucket = 33803
	local lessBucket = 33800
	local mediumBucket = 33801
	local fullBucket = 33802
	
	local filled = false
	local slimeCondition = createConditionObject(CONDITION_OUTFIT)
	setConditionParam(slimeCondition, CONDITION_PARAM_TICKS, 2*60*1000)
	addOutfitCondition(slimeCondition, {lookType = 19}) 
	
	local isInQuest = player:getStorageValue(Storage.DreamCourts.HauntedHouse.Questline)
	if isInQuest >= 1 then
		if tId == mutatedEgg then
			if item.itemid == emptyBucket then
				if r >= 5 then
					filled = true
					item:transform(lessBucket)
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is not enough ectoplasm left to fill it in the bucket.")
				end
			elseif item.itemid == lessBucket then
				if r >= 5 then
					filled = true
					item:transform(mediumBucket)
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is not enough ectoplasm left to fill it in the bucket.")
				end
			elseif item.itemid == mediumBucket then
				if r >= 5 then
					filled = true
					item:transform(fullBucket)
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The ectoplasm all over this egg was already seeping inside the cocoon itself. You manage to fill soem of it into the bucket.")
				end				
			end
			if filled then
				player:getPosition():sendMagicEffect(CONST_ME_POISONAREA)
			else
				target:getPosition():sendMagicEffect(CONST_ME_POFF)
			end
			target:transform(normalEgg)
			addEvent(revertEgg, r*1000*60, tPos, mutatedEgg, normalEgg)			
		end	
		if item.itemid == fullBucket then
			if target:isPlayer() then
				if target:getId() ~= player:getId() then
					return true
				else
					item:transform(emptyBucket)
					doAddCondition(player, slimeCondition)
					player:getPosition():sendMagicEffect(CONST_ME_POFF)
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You pour all of the ectoplasm over yourself. Without the bucket you cannot stabilise it, you need to hurry until it dissolves!")
				end
			end
		end			
	end
	return true
end
