local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_HITBYFIRE)

combat:setArea(createCombatArea({
{1},
{1},
{1},
{1},
{3},
}))

function spellCallbackRavennousWave2(param)
local tile = Tile(Position(param.pos))
	if tile then
		local creature = tile:getTopCreature()
		if creature and creature:isMonster() then
			if isInArray({'lost gnome', 'gnome pack crawler'}, creature:getName():lower()) then
				local min, max = -1*99, -1000*99
				doTargetCombat(0, creature, COMBAT_FIREDAMAGE, min, max, CONST_ME_HITBYFIRE)
			end
		end
	end
end

function onTargetTile(cid, pos)
	local param = {}
	param.cid = cid
	param.pos = pos
	param.count = 0
	spellCallbackRavennousWave2(param)
end

setCombatCallback(combat, CALLBACK_PARAM_TARGETTILE, "onTargetTile")

function onCastSpell(creature, var)
	return combat:execute(creature, var)
end
