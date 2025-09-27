-- Requires
local Config = require('data/scripts/events/events/magic-roulette/config')
local Roulette = require('data/scripts/events/events/magic-roulette/lib/roulette')
local Strings = require('data/scripts/events/events/magic-roulette/lib/core/strings')
local DatabaseRoulettePlays = require('data/scripts/events/events/magic-roulette/lib/database/roulette_plays')
local Functions = require('data/scripts/events/events/magic-roulette/lib/core/functions')
local Constants = require('data/scripts/events/events/magic-roulette/lib/core/constants')

local rouletteAction = Action()
function rouletteAction.onUse(player, item)
    local slot = Roulette:getSlot(item.actionid)
    if not slot then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, Strings.SLOT_NOT_IMPLEMENTED_YET)
        item:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end
    
    Roulette:roll(player, slot)
    return true
end

for k in pairs(Config.slots) do
    rouletteAction:aid(k)
end
rouletteAction:register()

local rouletteLogin = CreatureEvent('Roulette Login')
function rouletteLogin.onLogin(player)
    local pendingPlayRewards = DatabaseRoulettePlays:selectPendingPlayRewardsByPlayerGuid(player:getGuid())
    
    for _, reward in ipairs(pendingPlayRewards) do
        Functions:giveReward(player, reward)
    end

    return true
end
rouletteLogin:register()


local rouletteLook = Event()
rouletteLook.onLook = function(self, thing, position, distance, description)
    if thing:getName() == Constants.ROULETTE_DUMMY_NAME then
        local item = ItemType(thing:getOutfit().lookTypeEx)

        return ('You see %s.\n%s'):format(
            item:getName(),
            item:getDescription()
        )
    end
    return description
end
rouletteLook:register(1)


local rouletteStartup = GlobalEvent('Roulette Startup')
function rouletteStartup.onStartup()
    Roulette:startup()
    return true
end
rouletteStartup:register()

local rouletteLogout = CreatureEvent('Roulette Logout Protection')
local lastLogoutMessage = {}

function rouletteLogout.onLogout(player)
    if player:getStorageValue(1000) == 1 then
        local playerId = player:getId()
        local currentTime = os.time()
        
        if not lastLogoutMessage[playerId] or (currentTime - lastLogoutMessage[playerId]) >= 2 then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "You cannot logout while the roulette is spinning!")
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            lastLogoutMessage[playerId] = currentTime
        end
        
        return false
    end
    
    return true
end
rouletteLogout:register()
