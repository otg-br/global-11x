local onItemMoved = Event()
onItemMoved.onItemMoved = function(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
    -- Loot Analyser only for version 11.x+
    local t = Tile(fromCylinder:getPosition())
    if t then
        local corpse = t:getTopDownItem()
        if corpse then
            local itemType = corpse:getType()
            if itemType:isCorpse() and toPosition.x == CONTAINER_POSITION then
                self:sendLootStats(item)
            end
        end
    end

    local containerIdTo = toPosition.y - 64
    if containerIdTo >= 0 then
        local containerTo = self:getContainerById(containerIdTo)
        if containerTo and isDepot(containerTo:getId()) then
            self:onManageLocker(item, false)
        elseif containerTo and containerTo:getTopParent() and containerTo:getTopParent():getId() == self:getId() then
            local fromContainerId = fromPosition.y - 64
            if fromContainerId >= 0 and isDepot(fromContainerId) then
                self:onManageLocker(item, true)
            end
        end
    end
end
onItemMoved:register()