-- lib/customlib/monsters_boosts.lua
BoostedCreature = {
    position = Position(32367, 32232, 7),
    messages = {
        prefix = "[Boosted Creature] ",
        chosen = "The chosen creature is %s. When killed, you receive +%d%% experience and +%d%% loot.",
        statue = "I am today's boosted creature! Hunt me for +%d%% experience and +%d%% loot bonus!"
    },
    current = {
        monster = nil,
        expBonus = 0,
        lootBonus = 0
    },
    messageInterval = 30 -- 30 second intervals
}

function BoostedCreature:start()
    if self.current.monster and not self.current.monster:isRemoved() then
        self.current.monster:remove()
    end
    
    local boostedName = Game.getBoostMonster()
    if boostedName:lower() == "none" then
        return false
    end
    
    self.current.expBonus = math.max(getGlobalStorageValueDB(GlobalStorage.BoostedExpBonus), 0)
    self.current.lootBonus = math.max(getGlobalStorageValueDB(GlobalStorage.BoostedLootBonus), 0)
    
    local monster = Game.createMonster(boostedName, self.position, false, true)
    if not monster then
        return false
    end
    
    -- Set monster direction
    monster:setDirection(SOUTH)
    self.current.monster = monster
    
    Game.broadcastMessage(self.messages.prefix .. string.format(
        self.messages.chosen, 
        boostedName, 
        self.current.expBonus, 
        self.current.lootBonus
    ), MESSAGE_STATUS_WARNING)
    
    return true
end