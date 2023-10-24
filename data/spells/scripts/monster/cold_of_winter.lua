local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ICEDAMAGE)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_SNOWBALL)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_ICEATTACK)

combat:setArea(createCombatArea({
{0, 1, 0},
{1, 3, 1},
{0, 1, 0}
}))

function spellCallbackColdOfWinter(param)
	local tile = Tile(Position(param.pos))
	if tile then
		if tile:getTopCreature() and tile:getTopCreature():isMonster() then
			if tile:getTopCreature():getName():lower():find("izcandar") then
				tile:getTopCreature():addHealth(math.random(0, 1500))
			end
		end
	end
end

function onTargetTileColdOfWinter(cid, pos)
	local param = {}
	param.cid = cid
	param.pos = pos
	param.count = 0
	spellCallbackColdOfWinter(param)
end

setCombatCallback(combat, CALLBACK_PARAM_TARGETTILE, "onTargetTileColdOfWinter")

function onCastSpell(creature, var)
	return combat:execute(creature, var)
end
