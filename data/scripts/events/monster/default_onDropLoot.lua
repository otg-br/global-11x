
local event = Event()
event.onDropLoot = function(self, corpse)
    if configManager.getNumber(configKeys.RATE_LOOT) == 0 then
        return
    end

    if not self then
        return
    end

    local mType = self:getType()
    if not mType then
        return
    end
    if mType:isRewardBoss() then
        corpse:registerReward()
        return
    end

    local player = Player(corpse:getCorpseOwner())
    local percent = 1.5

    local bonusPrey = 0
    local hasCharm = false

    if player then
        local random = (player:getPreyBonusLoot(mType) >= math.random(100))
        if player:getPreyBonusLoot(mType) > 0 and random then
            bonusPrey = player:getPreyBonusLoot(mType)
            percent = (bonusPrey / 100) + percent
        end

        if player:getClient().version >= 1200 then
            percent = percent + 0.05
        end

        local g = player:getGuild()
        if g then
            local rewards = getReward(player:getId()) or {}
            for i = 1, #rewards do
                if rewards[i].type == GUILD_LEVEL_BONUS_LOOT then
                    percent = percent + rewards[i].quantity
                    break
                end
            end
        end

        local currentCharm = player:getMonsterCharm(mType:raceId())
        if currentCharm == 14 then
            percent = percent * 1.10
            hasCharm = true
        end

        if player:getPremiumEndsAt() > os.time() then
            percent = percent * 1.05
        end
    end

    if not player or player:getStamina() > 840 then
        local monsterLoot = mType:getLoot()
        if monsterLoot then
            for i = 1, #monsterLoot do
                corpse:createLootItem(monsterLoot[i], percent, self:isRaid())
            end
        end

        local lootText = {}
        local itemCounts = {}

        for slot = 0, corpse:getSize() - 1 do
            local item = corpse:getItem(slot)
            if item then
                local itemId = item:getId()
                if not itemCounts[itemId] then
                    itemCounts[itemId] = {count = 0, name = item:getName()}
                end
                itemCounts[itemId].count = itemCounts[itemId].count + item:getCount()
                
                -- Se for um container, verificar itens dentro dele
                if item:isContainer() then
                    local containerItems = getAllItemsInContainer(item)
                    for _, subItem in ipairs(containerItems) do
                        local subItemId = subItem:getId()
                        if not itemCounts[subItemId] then
                            itemCounts[subItemId] = {count = 0, name = subItem:getName()}
                        end
                        itemCounts[subItemId].count = itemCounts[subItemId].count + subItem:getCount()
                    end
                end
            end
        end

        local chanceMap = {}
        if monsterLoot then
            for _, loot in ipairs(monsterLoot) do
                chanceMap[loot.itemId] = loot.chance
            end
        end

        for itemId, data in pairs(itemCounts) do
            local marketValue = getMarketValueForColor(itemId)
            local color = getLootColorByValue(marketValue)
            local amount = data.count > 1 and (" x" .. data.count) or ""
            table.insert(lootText, colorize(data.name .. amount, color))
        end

        local fullLine = string.format("Loot of %s: %s", mType:getNameDescription(), #lootText > 0 and table.concat(lootText, ", ") or "nothing")

        if player then
            local party = player:getParty()
            if party then
                party:broadcastPartyLoot(fullLine)
                party:broadcastPartyLootTracker(self, corpse)
            else
                player:sendTextMessage(MESSAGE_LOOT, fullLine)
                player:sendKillTracker(self, corpse)
                player:sendChannelMessage("", fullLine, TALKTYPE_CHANNEL_O, 10)
            end
        end
    else
        local text = ("Loot of %s: nothing (due to low stamina)"):format(mType:getNameDescription())
        local party = player:getParty()
        if party then
            party:broadcastPartyLoot(text)
        else
            player:sendTextMessage(MESSAGE_LOOT, text)
            player:sendChannelMessage("", text, TALKTYPE_CHANNEL_O, 10)
        end
    end
end
event:register()
