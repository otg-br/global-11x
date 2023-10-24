local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_MANADRAIN)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_PURPLEENERGY)
local area = createCombatArea(AREA_DIAGONALWAVE_IZCANDAR)
combat:setArea(area)

function onCastSpell(creature, var)
	return combat:execute(creature, var)
end
