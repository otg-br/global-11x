local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ENERGYDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_ENERGYHIT)
combat:setArea(createCombatArea(AREA_BEAM5, AREADIAGONAL_BEAM5))

function onGetFormulaValues(player, level, maglevel)
	local min = (level / 5) + (maglevel * 1.8) + 11
	local max = (level / 5) + (maglevel * 3) + 19
	return player:getSpellDamage(-min, -max)
end

combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "onGetFormulaValues")

function onCastSpell(creature, var)
	local player = Player(creature:getId())
	if player then
		if not player:isWarAllowed(CONST_WAR_BEAM) then
			player:sendCancelMessage("This action is not allowed here.")
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
			return false
		end
	end
	return combat:execute(creature, var)
end
