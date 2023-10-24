local gongoId = 11003
local rockId = 11536
local gongoPos = Position(33692, 32385, 15)
local rockPos = Position(33693, 32385, 15)
local toPosition = Position(33712, 32376, 15)

local function resetGongo()
    local forcefield = Tile(rockPos):getItemById(1387)
    if forcefield then
        forcefield:remove(1)
        Game.createItem(rockId, 1, rockPos)
    end
end

local function startBoss()
    local rock = Tile(rockPos):getItemById(rockId)
    if rock then
        rock:remove(1)
        local forcefield = Game.createItem(1387, 1, rockPos)
        if forcefield then
            rockPos:sendMagicEffect(CONST_ME_FIREAREA)
            forcefield:setDestination(toPosition)
        end
        addEvent(resetGongo, 3*60*1000)
        Game.setStorageValue(GlobalStorage.DangerousDepths.Morgathla.morgathlaTimer, 1)
        addEvent(clearForgotten, 1*60*60*1000, Position(33703, 32314, 15),
        Position(33794, 32390, 15), Position(33692, 32388, 15), GlobalStorage.DangerousDepths.Morgathla.morgathlaTimer)
    end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local tPos = target:getPosition()
    local rock = Tile(rockPos):getItemById(rockId)
    if (target.itemid == gongoId and tPos == gongoPos) and rock then
        if Game.getStorageValue(GlobalStorage.DangerousDepths.Morgathla.morgathlaTimer) >= 1 then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need to wait a while, recently someone challenged Ancient Spawn of Morgathla.")
            return true
        end
        local r = math.random(1, 6)
        player:say("BOOOOOOOONG!", TALKTYPE_MONSTER_SAY)
        if r <= 2 then
            item:remove(1)
            Game.setStorageValue(GlobalStorage.DangerousDepths.Morgathla.firstRoom, 0)
            Game.setStorageValue(GlobalStorage.DangerousDepths.Morgathla.secondRoom, 0)
            Game.setStorageValue(GlobalStorage.DangerousDepths.Morgathla.thirdRoom, 0)
            Game.setStorageValue(GlobalStorage.DangerousDepths.Morgathla.fourthRoom, 0)
            Game.setStorageValue("morgathlaStage", 0)
            startBoss()          
        end
        return true
    else
        return true
    end
end