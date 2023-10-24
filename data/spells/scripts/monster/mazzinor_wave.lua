local lookType = 1065
local lockSpell = false
local chance = 30 -- %
local fromPos = Position(32715, 32712, 10)
local toPos = Position(32733, 32729, 10)

local function sendSpell(cid)
	local creature = Creature(cid)
	if creature then
		for x = fromPos.x, toPos.x do
			for y = fromPos.y, toPos.y do
				for z = fromPos.z, toPos.z do
					if Tile(Position(x, y, z)) then
						Position(x, y, z):sendMagicEffect(CONST_ME_BIGCLOUDS)
						local p = Tile(Position(x, y, z)):getTopCreature()
						if p and (p:isPlayer() or p:getMaster()) then
							doTargetCombatHealth(creature, p, COMBAT_ENERGYDAMAGE, -99999, -999999, CONST_ME_NONE)
						end
					end
				end
			end
		end	
		local cPos = creature:getPosition()
		local cHealth = creature:getHealth()
		local monster = Game.createMonster('Mazzinor', cPos, true)
		creature:remove()
		lockSpell = false
	end
end

function onCastSpell(creature, var)
	if not lockSpell then
		local r = math.random(1, 100)
		if r <= chance then
			lockSpell = true
			local cPos = creature:getPosition()
			local cHealth = creature:getHealth()
			local monster = Game.createMonster('Supercharged Mazzinor', cPos, true)
			creature:remove()
			if monster then
				monster:addHealth(-(monster:getHealth() - cHealth))
				monster:say('MAZZINOR PREPARES TO ELECTROCTUTE THE WHOLE ROOM!', TALKTYPE_MONSTER_SAY)
				monster:registerEvent('mazzinorHealth')
				addEvent(sendSpell, 8*1000, monster:getId())
			end			
		end
	end
	return true
end