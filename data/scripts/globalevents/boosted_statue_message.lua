local interval = 30000 -- set to 30 seconds

local globalevent = GlobalEvent("BoostedStatueMessage")
function globalevent.onThink(...)
    if not BoostedCreature or not BoostedCreature.current.monster or BoostedCreature.current.monster:isRemoved() then
        return true
    end

    local expBonus = math.max(getGlobalStorageValueDB(GlobalStorage.BoostedExpBonus), 0)
    local lootBonus = math.max(getGlobalStorageValueDB(GlobalStorage.BoostedLootBonus), 0)

    BoostedCreature.current.monster:say(string.format(
        BoostedCreature.messages.statue,
        expBonus,
        lootBonus
    ), TALKTYPE_MONSTER_SAY)

    return true
 end
globalevent:interval(interval)
globalevent:register()