local onMoveCreature = Event()
onMoveCreature.onMoveCreature = function(self, creature, fromPosition, toPosition)
    if self:getGroup():getId() < 4 then
        if Game.getWorldType() == WORLD_TYPE_RETRO_OPEN_PVP then
            if creature:isMonster() and creature:getType() and not creature:getType():isPet() then
                return false
            end
        end
        if creature:isPlayer() and creature:getStorageValue(Storage.isTrainingStorage) > 0 then
            self:sendCancelMessage("You cannot push a player while they are training.")
            return false
        end
    end
    return true
end
onMoveCreature:register()