local config = {
	items = {
	[1] = {id = 2687, countMax = 5, name = "cookie"},
	[2] = {id = 24844, countMax = 1, name = "ogre ear stud"}, 
	[3] = {id = 24827, countMax = 1, name = "ogre klubba"}, 
	[4] = {id = 24845, countMax = 1, name = "ogre nose ring"},
	[5] = {id = 24849, countMax = 3, name = "onyx chip"}, 
	[6] = {id = 24841, countMax = 4, name = "prickly pear"}, 
	[7] = {id = 24842, countMax = 2, name = "raw meat"}, 
	[8] = {id = 24843, countMax = 5, name = "roasted meat"}, 
	[9] = {id = 24848, countMax = 1, name = "shamanic mask"}, 
	[10] = {id = 24840, countMax = 1, name = "shamanic talisman"}, 
	[11] = {id = 24847, countMax = 1, name = "skull fetish"}, 
	[12] = {id = 3967, countMax = 1, name = "tribal mask"}, 
	[13] = {id = 3970, countMax = 1, name = "feather headdress"},
	[14] = {id = 24839, countMax = 1, name = "ogre scepta"}, 
	[15] = {id = 7413, countMax = 1, name = "titan axe"},
	[16] = {id = 24828, countMax = 1, name = "ogre choppa"},
	[17] = {id = 3983, countMax = 1, name = "bast skirt"},
	[18] = {id = 24850, countMax = 2, name = "opal"},
	}
}

function onUse(player, item, isHotkey)
	math.randomseed(os.stime())
	
	
	local itemsTable = config.items
	local r = math.random(1, 18)
	
	itemsTable = itemsTable[r]
	local name = itemsTable.name:lower()
	local countMaxTable = itemsTable.countMax
	local count = math.random(1, countMaxTable)
	
	player:addItem(itemsTable.id, count)
	item:remove(1)
	if count > 1 then
	name = name .. "s"
	end
	player:say('Using a shaggy ogre bag...', TALKTYPE_MONSTER_SAY, false, player)
	player:sendTextMessage(MESSAGE_STATUS_SMALL, 'You got ' .. count .. ' ' .. name .. '.')
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
	
	return true
end
