


local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_DEATHDAMAGE)
setCombatParam(combat, COMBAT_PARAM_EFFECT, CONST_ME_SLEEP)

combat:setArea(createCombatArea({
	{0, 0, 3},
    {0, 0, 1},
    {0, 0, 1},
    {0, 0, 1}
}))
 
function onCastSpell(cid, var)
    return combat:execute(cid, var)
end