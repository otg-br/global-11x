function onTargetCreature(creature, target)
	local player = creature:getPlayer()
	local min = (((player:getLevel() / 5) + (player:getMagicLevel() * 10.6) + 115)) * 1.05
	local max = ((player:getLevel() / 5) + (player:getMagicLevel() * 12.6) + 130) * 0.93

	local bosses = {"leiden", "ravennous hunger", "dorokoll the mystic", "eshtaba the conjurer", "eliz the unyielding", "mezlon the defiler", "malkhar deathbringer", "containment crystal"}
	local master = target:getMaster()
	if target:isMonster() and not master or master and master:isMonster() then
		if (not isInArray(bosses, target:getName():lower())) then
			return min, max
		end
	end

	doTargetCombat(creature:getId(), target, COMBAT_HEALING, creature:getSpellDamage(min, max, true), CONST_ME_NONE, ORIGIN_NONE)
	return creature:getSpellDamage(min, max, true)
end

local combat = Combat()
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_MAGIC_BLUE)
combat:setParameter(COMBAT_PARAM_AGGRESSIVE, 0)
combat:setParameter(COMBAT_PARAM_DISPEL, CONDITION_PARALYZE)
combat:setArea(createCombatArea(AREA_CIRCLE3X3))
combat:setCallback(CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(creature, var)
	return combat:execute(creature, var)
end
