function onKill(player, target)
    if not target:isMonster() then
        return true
    end

    addEvent(AutoLootList.getLootItem, 100, AutoLootList, player:getId(), target:getPosition())
    return true
end