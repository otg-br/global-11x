if not AutoLootList then
    AutoLootList = { players = { } }
end

AutoLootList.stop = function(self, playerId, playerGuid)
    if self.players[playerId] ~= nil then
        local lootList = self.players[playerId].lootList
        if lootList then
			db.query(string.format("DELETE FROM `auto_loot_list` WHERE `player_id` = %d", playerGuid))

            for i = 1, #lootList do
                local itemId = lootList[i].item_id
                db.query(string.format("INSERT INTO `auto_loot_list` (`player_id`, `item_id`) VALUES (%d, %d)", playerGuid, itemId))
            end
        end

        self.players[playerId] = nil
    end
end

AutoLootList.countList = function(self, playerId)
    if self.players[playerId] ~= nil then
        return #self.players[playerId].lootList
    end

    return 0
end

AutoLootList.init = function(self, playerId)
    local player = Player(playerId)
    if not player then
        return
    end

    if not self.players[playerId] then
        self.players[playerId] = { lootList = { } }
    end

    local resultId = db.storeQuery(string.format('SELECT `item_id` FROM `auto_loot_list` WHERE `player_id` = %d', player:getGuid()))
    if resultId then
        local itemTable = queryToTable(resultId, {'item_id:number'})
        self.players[playerId].lootList = itemTable
        result.free(resultId)
    end
end

AutoLootList.getItemList = function(self, playerId)
    local player = Player(playerId)
    if not player then
        return nil
    end

    if not self.players[playerId] then
        return nil
    end

    return self.players[playerId].lootList
end

AutoLootList.itemInList = function(self, playerId, itemId)
    local player = Player(playerId)
    if not player then
        return false
    end

    if not self.players[playerId] then
        return false
    end

    local lootList = self.players[playerId].lootList
    if lootList then
        for i = 1, #lootList do
            if lootList[i].item_id == itemId then
                return true
            end
        end
    end

    return false
end

AutoLootList.addItem = function(self, playerId, itemId)
    if not self.players[playerId] then
        return false
    end

    if self:itemInList(playerId, itemId) then
        return false
    end

    table.insert(self.players[playerId].lootList, {item_id = itemId})
    return true
end

AutoLootList.removeItem = function(self, playerId, itemId)
    if not self.players[playerId] then
        return false
    end

    if not self:itemInList(playerId, itemId) then
        return false
    end

    local lootList = self.players[playerId].lootList
    if lootList then
        for i = 1, #lootList do
            if lootList[i].item_id == itemId then
                table.remove(lootList, i)
                break
            end
        end
    end

    return true
end

AutoLootList.getLootItem = function(self, playerId, position)
    local player = Player(playerId)
    if not player then
        return
    end

    if self.players[playerId] ~= nil then
        local corpse = Tile(position):getTopDownItem()
        if not corpse or not corpse:isContainer() then
            return
        end

        local strLoot = ''
        local lootList = self.players[playerId].lootList
		if lootList then
            for a = corpse:getSize() - 1, 0, -1 do
                local containerItem = corpse:getItem(a)
                if containerItem then
                    local containerItemId = containerItem:getId()
                    for i = 1, #lootList do
                        if lootList[i].item_id == containerItemId then
                            local itemCount = containerItem:getCount()
                            local itemName = containerItem:getName()

                            local moveItem = containerItem:moveTo(player)
                            if moveItem then
                                strLoot = string.format('%s%dx %s, ', strLoot, itemCount, itemName)
                            end
                        end
                    end
                end
            end

            if strLoot ~= '' then
                strLoot = strLoot:sub(1, #strLoot-2)
                if strLoot:len() >= 250 then
                    strLoot:sub(1, 250)
                    strLoot = strLoot .. " ..."
                end
                
                player:sendTextMessage(MESSAGE_STATUS_SMALL, string.format('Loot recolhido: %s', strLoot))
            end
        end
    end
end

AutoLootList.onLogin = function(self, playerId) self:init(playerId) end
AutoLootList.onLogout = function(self, playerId, playerGuid) self:stop(playerId, playerGuid) end
AutoLootList.onDeath = function(self, playerId, playerGuid) self:stop(playerId, playerGuid) end