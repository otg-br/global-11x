

local function teleportMonster(creature, centerPos, fromPos, toPos)
	local	position = {x =math.random(fromPos.x, toPos.x), y= math.random(fromPos.y, toPos.y), z = centerPos.z }
	local	tile = Tile(Position(position))
	local count = 1
	while( not tile or tile:getItemByType(ITEM_TYPE_TELEPORT) or not tile:getGround() or tile:hasFlag(TILESTATE_BLOCKPATH) or tile:hasFlag(TILESTATE_PROTECTIONZONE) or tile:hasFlag(TILESTATE_BLOCKSOLID) or count < 5) do 
		position = Position(math.random(fromPos.x, toPos.x), math.random(fromPos.y, toPos.y), centerPos.z )
		tile = Tile(position)
		count = count + 1
	end
	if tile then
		creature:getPosition():sendMagicEffect(CONST_ME_POFF)
		creature:teleportTo(position)
		Position(position):sendMagicEffect(CONST_ME_TELEPORT)
	end
end

function onCastSpell(creature, var)
	if not creature:isMonster() then
		return false
	end
	local centerPos = creature:getPosition() -- x, y, z
	local fromPos = {x = centerPos.x - 7, y = centerPos.y - 5, z = centerPos.z} -- x - 7, y - 5, z
	local toPos = {x = centerPos.x + 7, y = centerPos.y + 5, z = centerPos.z}  -- x + 7, y + 5, z
	teleportMonster(creature, centerPos, fromPos, toPos)
	return true
end