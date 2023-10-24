local delay = 3

local function doRegen(playerid, isBlock)
	local regen = addEvent(function(pid)
		local c = Creature(pid)
		if c and c:isPlayer() then
			if not isBlock then
				if Tile(c:getPosition()):getGround():getActionId() == 4505 then
					c:addMana(c:getVocation():getManaGainAmount())
					c:addHealth(c:getVocation():getHealthGainAmount())
					doRegen(c:getId(), false)
				else
					stopEvent(regen)
				end
			else
				stopEvent(regen)
			end
		end
	end, delay*1000, playerid)
end
			
function onStepIn(creature, item, position, fromPosition)
	if not creature:isPlayer() then
		return true
	end
	if position == CASTLE_INFO.THRONE_POSITION then
		Castle:onStepIn(creature)
	else
		doRegen(creature:getId(), false)
	end
	return true
end

function onStepOut(creature, item, position, fromPosition)
	if not creature:isPlayer() then
		return true
	end
	if position == CASTLE_INFO.THRONE_POSITION then
		Castle:onStepOut(creature)
	else
		doRegen(creature:getId(), true)
	end
	return true
end
