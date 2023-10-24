local position = Position(32751, 32689, 10)
local fPos = Position(32748, 32686, 10)
local tPos = Position(32754, 32692, 10)

local function callPlayers(cid)
	for x = fPos.x + 1, fPos.x + 5 do
		Game.createMonster('Force Field', Position(x, fPos.y, fPos.z), false, true)
	end
	for y = fPos.y + 1, fPos.y + 5 do
		Game.createMonster('Force Field', Position(fPos.x, y, fPos.z), false, true)
	end
	for x = tPos.x - 5, tPos.x - 1 do
		Game.createMonster('Force Field', Position(x, tPos.y, tPos.z), false, true)
	end
	for y = tPos.y - 5, tPos.y - 1 do
		Game.createMonster('Force Field', Position(tPos.x, y, tPos.z), false, true)
	end
	local spectators = Game.getSpectators(position, false, false, 9, 9, 9, 9)
	for _, p in pairs(spectators) do
		if p and (p:isPlayer() or p:getMaster()) then
			p:teleportTo(Position(32750, 32688, 10), false)
		end
	end
	local book = Game.createMonster('Dark Knowledge', Position(32751, 32684, 10))
	if book then
		book:registerEvent('lokathmorDeath')
	end
end

function onCastSpell(creature, var)
	local cHealth = creature:getHealth()
	local monster = Game.createMonster('Lokathmor Stuck', position, true)
	creature:remove()
	if monster then
		monster:addHealth(-(monster:getHealth() - cHealth))
		callPlayers()
	end			
	return true
end