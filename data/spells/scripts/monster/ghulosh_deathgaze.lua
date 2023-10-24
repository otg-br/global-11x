local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_DEATHDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_MORTAREA)

combat:setArea(createCombatArea({
{1},
{1},
{1},
{1},
{1},
{1},
{1},
{1},
{1},
{1},
{3},
}))

local function spawnGhulosh(cid)
	local c = Creature(cid)
	if c then
		local position = c:getPosition()
		local cHealth = c:getHealth()
		local monster = Game.createMonster('ghulosh', position, true)
		c:remove()
		if monster then
			monster:addHealth(-(monster:getHealth() - cHealth))
			monster:say('THE DEATH GAZE IS REFLECTED AND DEPOWERS GULOSH!', TALKTYPE_MONSTER_SAY)
		end
	end	
end

function spellCallbackGhulosh(param)
	local tile = Tile(Position(param.pos))
	if tile then
		if tile:getTopCreature() and tile:getTopCreature():isMonster() then
			if tile:getTopCreature():getName():lower() == "concentrated death" then
				doTargetCombatHealth(0, tile:getTopCreature(), COMBAT_DEATHDAMAGE, -999999, -999999, CONST_ME_MORTAREA)
				spawnGhulosh(param.cid)
			end
		end
	end
end

function onTargetTile(cid, pos)
	local param = {}
	param.cid = cid
	param.pos = pos
	param.count = 0
	spellCallbackGhulosh(param)
end

setCombatCallback(combat, CALLBACK_PARAM_TARGETTILE, "onTargetTile")

function onCastSpell(creature, var)
	return combat:execute(creature, var)
end
