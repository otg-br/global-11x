local Nadar = 
	createConditionObject(CONDITION_OUTFIT)
	setConditionParam(Nadar, CONDITION_PARAM_TICKS, - 1)
	addOutfitCondition(Nadar, {lookTypeEx = 29323})

function onStepIn(creature, position, fromPosition, toPosition)
	if not creature:isPlayer() then
	return false
	end
	
	creature:getPosition():sendMagicEffect(54)
	creature:addCondition(Nadar)
	creature:sendCancelMessage("You entered the bath tube.")
	return true
end

function onStepOut(creature, position, fromPosition, toPosition)
	if not creature:isPlayer() then
	return false
	end
	
	creature:sendCancelMessage("You left the bath tube.")
	creature:getPosition():sendMagicEffect(54)
	creature:removeCondition(CONDITION_OUTFIT)
return true
end