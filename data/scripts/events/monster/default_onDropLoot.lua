local event = Event()
event.onDropLoot = function(self, corpse)
    if configManager.getNumber(configKeys.RATE_LOOT) == 0 then
        return
    end
    
    local mType = self:getType()
    if mType:isRewardBoss() then
        corpse:registerReward()
        return
    end
    
    local player = Player(corpse:getCorpseOwner())
    local percent = 1.5
    
    local bonusPrey = 0
    local hasCharm = false
    
    -- Guild Level System
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
        
        -- charm
        local currentCharm = player:getMonsterCharm(mType:raceId())
        if currentCharm == 14 then
            percent = percent * 1.10
            hasCharm = true
        end
        
        if player:getVipDays() > os.stime() then
            percent = percent * 1.05
        end
    end
    
    if not player or player:getStamina() > 840 then
        local monsterLoot = mType:getLoot()
        for i = 1, #monsterLoot do
            corpse:createLootItem(monsterLoot[i], percent, self:isRaid())
        end
        
        if player then
            local party = player:getParty()
            local lootMessage = corpse:getLoot(mType:getNameDescription(), player:getClient().version, bonusPrey, hasCharm)
            
            if party then
                party:broadcastPartyLoot(corpse, mType:getNameDescription(), bonusPrey, hasCharm)
                party:broadcastPartyLootTracker(self, corpse)
            else
                player:sendTextMessage(MESSAGE_LOOT, lootMessage)
                player:sendKillTracker(self, corpse)
                player:sendChannelMessage("", lootMessage, TALKTYPE_CHANNEL_O, 10)
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