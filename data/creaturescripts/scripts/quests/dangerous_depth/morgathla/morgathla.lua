local info = {
    [1] = {stage = 1, health = 70, position = Position(33729, 32365, 15), toPosition = Position(33725, 32355, 15), message = "THE SPAWN RETREATS TO ANOTHER AREA IN THE NORTH-EAST"},
    [2] = {stage = 2, health = 50, position = Position(33737, 32339, 15), toPosition = Position(33744, 32346, 15), message = "THE SPAWN RETREATS TO ANOTHER AREA IN THE NORTH-EAST"},
    [3] = {stage = 3, health = 30, position = Position(33770, 32357, 15), toPosition = Position(33774, 32346, 15), message = "THE SPAWN RETREATS TO ANOTHER AREA IN THE SOUTH-EAST"},
}
function onThink(creature, interval)
    if not creature or not creature:isMonster() then
        return true
    end
    local vida, position, toPosition, message
    local cName = creature:getName():lower()
    local pHealth = creature:getHealth()*100/creature:getMaxHealth()
    if Game.getStorageValue("morgathlaStage") >= 4 then
        creature:registerEvent('beetleRevive')
        creature:unregisterEvent('morgathlaThink')
        return true
    end
    if cName == "ancient spawn of morgathla" then
        for _, k in pairs(info) do
            if Game.getStorageValue("morgathlaStage") == k.stage then
                vida = k.health
                position = k.position
                toPosition = k.toPosition
                message = k.message
            end
        end
    end
    if pHealth <= vida then
        creature:say(message, TALKTYPE_MONSTER_SAY)
        creature:remove()
        local portal = Game.createItem(1387, 1, position)
        Game.setStorageValue("morgathlaStage", Game.getStorageValue("morgathlaStage") + 1)
        if portal then
            portal:setDestination(toPosition)
            addEvent(function(i, p)
                local j = Tile(p):getItemById(i)
                if j then
                    j:remove()
                end
            end, 3*60*1000, 1387, position)
        end
    end
    return true
end
