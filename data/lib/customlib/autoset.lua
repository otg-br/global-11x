local AUTOMAP_LOADED = false

AutomacaoMap = {
	-- { -- Comentario//Exemplo: Quest demon helmet
		-- position = Position(0, 0, 0), -- se for mais especifico, use Position({x = x, y = y, z = z, stackpos = stackpos})
		-- itemid = 0,
		-- actionid = 0, -- é obrigatorio
		-- uniqueid = 0, -- não é obrigatorio
		-- desc = '', -- não é obrigatorio
	-- },
	{
		position = Position(32720, 32773, 10),
		itemid = 33368,
		actionid = 4950, 
		uniqueid = 0, 
		desc = 'Mazzinor',
	},
	{
		position = Position(32720, 32749, 10),
		itemid = 33368,
		actionid = 4950, 
		uniqueid = 0, 
		desc = 'Lokathmor',
	},
}

-- AutomacaoNpc = {
-- 	{
-- 		name = "",
-- 		position = Position(),
-- 	},
-- }

function Game.loadAutomation(reload)
	if not reload and AUTOMAP_LOADED then
		-- evita super lotação no processo
		return true
	end

	AUTOMAP_LOADED = true
	for i, map in pairs(AutomacaoMap) do
		local tile = Tile(map.position)
		if tile then-- and thing.itemid == map.itemid then
			local item = nil
			if tile:getItemCountById(map.itemid) == 0 then
				item = Game.createItem(map.itemid, 1, map.position) 
			else
				item = tile:getItemById(map.itemid)
			end

			if item then
				local aid = map.actionid or map.aid
				if aid and aid > 0 then
					item:setActionId(aid)
				end

				local uid = map.uniqueid or map.uid
				if uid and uid > 0 then
					item:setUniqueId(uid)
				end

				if map.desc then
					item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, map.desc)
				end
			end
		end
	end
	return true
end
