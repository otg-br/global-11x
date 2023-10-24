--[[
BOOM! BOOOM! BOOOOM! BOOOOOM! BOOOOOOM!
]]

local BOOOM = Combat()
BOOOM:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
BOOOM:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_GROUNDSHAKER)
BOOOM:setFormula(COMBAT_PHYSICALDAMAGE, -200, -600, -10000, -20000)
BOOOM:setArea(createCombatArea({
	{0, 1, 1, 1, 0},
	{0, 1, 3, 1, 0},
	{0, 1, 1, 1, 0},
}))

local BOOOOM = Combat()
BOOOOM:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
BOOOOM:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_GROUNDSHAKER)
BOOOOM:setFormula(COMBAT_PHYSICALDAMAGE, -200, -600, -10000, -20000)
BOOOOM:setArea(createCombatArea({
	{0, 0, 0, 0, 0, 0, 0},
	{0, 0, 1, 1, 1, 0, 0},
	{0, 1, 1, 1, 1, 1, 0},
	{0, 1, 1, 3, 1, 1, 0},
	{0, 1, 1, 1, 1, 1, 0},
	{0, 0, 1, 1, 1, 0, 0},
	{0, 0, 0, 0, 0, 0, 0},
}))

local BOOOOOM = Combat()
BOOOOOM:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
BOOOOOM:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_GROUNDSHAKER)
BOOOOOM:setFormula(COMBAT_PHYSICALDAMAGE, -200, -600, -10000, -20000)
BOOOOOM:setArea(createCombatArea({
	{0, 0, 1, 1, 1, 0, 0},
	{0, 1, 1, 1, 1, 1, 0},
	{1, 1, 1, 1, 1, 1, 1},
	{1, 1, 1, 3, 1, 1, 1},
	{1, 1, 1, 1, 1, 1, 1},
	{0, 1, 1, 1, 1, 1, 0},
	{0, 0, 1, 1, 1, 0, 0},
}))

local BOOOOOOM = Combat()
BOOOOOOM:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
BOOOOOOM:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_GROUNDSHAKER)
BOOOOOOM:setFormula(COMBAT_PHYSICALDAMAGE, -200, -600, -10000, -20000)
BOOOOOOM:setArea(createCombatArea({
	{0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0},
	{0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0},
	{0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0},
	{0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0},
	{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
	{1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1},
	{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
	{0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0},
	{0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0},
	{0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0},
	{0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0},
}))

function onCastSpell(creature, var)
	if not creature:isMonster() then
		return false
	end
	local exaust = math.random(11, 41)
	if creature:getStorageValue("malofur") ~= 1 then
		creature:say("RAAAARGH! IM MASHING YE TO DUST!", TALKTYPE_MONSTER_SAY)	
		creature:say("BOOM!", TALKTYPE_MONSTER_SAY)
		creature:setStorageValue("malofur", 1)
		addEvent(function(cid)
			-- vai causar crash
			local c = Creature(cid)
			if c then
				var = {type = 2, pos = {x = c:getPosition().x, y = c:getPosition().y, z = c:getPosition().z}}
				BOOOM:execute(c:getId(), var)
				c:say("BOOOM!", TALKTYPE_MONSTER_SAY)
			end
		end, 3*1000, creature:getId())
		addEvent(function(cid)
			-- vai causar crash
			local c = c(cid)
			if c then
				var = {type = 2, pos = {x = c:getPosition().x, y = c:getPosition().y, z = c:getPosition().z}}
				BOOOOM:execute(c:getId(), var)
				c:say("BOOOOM!", TALKTYPE_MONSTER_SAY)
			end
		end, 5*1000, creature:getId())
		addEvent(function(cid)
			-- vai causar crash
			local c = Creature(cid)
			if c then
				var = {type = 2, pos = {x = c:getPosition().x, y = c:getPosition().y, z = c:getPosition().z}}
				BOOOOOM:execute(c:getId(), var)
				c:say("BOOOOOM!", TALKTYPE_MONSTER_SAY)
			end
		end, 7*1000, creature:getId())
		addEvent(function(cid)
			-- vai causar crash
			local c = Creature(cid)
			if c then
				var = {type = 2, pos = {x = c:getPosition().x, y = c:getPosition().y, z = c:getPosition().z}}
				BOOOOOOM:execute(c:getId(), var)
				c:say("BOOOOOOM!", TALKTYPE_MONSTER_SAY)
			end
		end, 9*1000, creature:getId())
		addEvent(function(cid)
			local c = Creature(cid)
			if c then
				c:setStorageValue("malofur", 0)
			end
		end, exaust*1000, creature:getId())
	end
	return true
end