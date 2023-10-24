local stepOut = {
	[1] = {doorPosition = Position(32348, 32692, 7), backPosition = Position(32348, 32694, 7)}, -- liberty bay
	[2] = {doorPosition = Position(32680, 31719, 7), backPosition = Position(32680, 31721, 7)}, -- ab dendriel
	[3] = {doorPosition = Position(33268, 32841, 7), backPosition = Position(33266, 32841, 7)}, -- ankrahmun
	[4] = {doorPosition = Position(32263, 31848, 7), backPosition = Position(32263, 31846, 7)}, -- carlin
	[5] = {doorPosition = Position(33303, 32371, 7), backPosition = Position(33301, 32371, 7)}, -- darashia
	[6] = {doorPosition = Position(33221, 31922, 7), backPosition = Position(33221, 31920, 7)}, -- edron
	[7] = {doorPosition = Position(32574, 31982, 7), backPosition = Position(32574, 31980, 7)}, -- kazordoon
	[8] = {doorPosition = Position(32530, 32711, 7), backPosition = Position(32530, 32713, 7)}, -- port hope
	[9] = {doorPosition = Position(32264, 32164, 7), backPosition = Position(32266, 32164, 7)}, -- thais
	[10] = {doorPosition = Position(32834, 32081, 7), backPosition = Position(32833, 32083, 7)}, -- venore
}

local possibleIds = {
5064,
5065, 
5066, 
5067, 
7851, 
6116, 
7851
}

function onStepIn(player, item, position, fromPosition)
	if not player:isPlayer() then return true end
	if item.actionid == 9710 then
		player:teleportTo(Position(33290, 31787, 13))		
	elseif item.actionid == 9711 then
		for _, k in pairs(stepOut) do
			for i = 1, #possibleIds do
				local door = Tile(k.doorPosition):getItemById(possibleIds[i])
				if door then
					player:teleportTo(k.backPosition)			
				end
			end
		end
	end
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
end
