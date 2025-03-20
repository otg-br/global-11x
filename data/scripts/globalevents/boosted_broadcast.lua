local interval = 10800000 -- 3 horas em milissegundos (10800000ms)

local globalevent = GlobalEvent("BoostedCreatureAnnounce")

function globalevent.onThink(...)
    if not BoostedCreature then
        return true
    end
    
    local boostedName = Game.getBoostMonster()
    local expBonus = math.max(getGlobalStorageValueDB(GlobalStorage.BoostedExpBonus), 0)
    local lootBonus = math.max(getGlobalStorageValueDB(GlobalStorage.BoostedLootBonus), 0)
    
    local function firstToUpper(str)
        return str:gsub("^%l", string.upper)
    end
    
    Game.broadcastMessage(BoostedCreature.messages.prefix .. 
        BoostedCreature.messages.chosen:format(
            firstToUpper(boostedName), 
            expBonus, 
            lootBonus
        ), MESSAGE_STATUS_WARNING)
    
    return true
end

globalevent:interval(interval)
globalevent:register()