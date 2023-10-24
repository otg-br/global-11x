local vortexId = 26140
local actionId = 4951

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	creature:addHealth(primaryDamage or secondaryDamage)
	primaryDamage = 0
	secondaryDamage = 0	
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

function onDeath(creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	local cPos = creature:getPosition()
	if creature:getName():lower() == "wild knowledge" then
		local vortex = Game.createItem(vortexId, 1, cPos)
		if vortex then
			vortex:setActionId(actionId)
			addEvent(function(cPos)
				local item = Tile(cPos):getItemById(vortexId)
				if item then
					item:remove()
				end
			end, 1*1000*60, cPos)
		end
	end
end