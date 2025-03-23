-- Evento de inicialização do sistema boosted
local BoostCreature = GlobalEvent("BoostCreature")
function BoostCreature.onStartup()
    if BoostedCreature.db then
        db.query("DELETE FROM `boost_creature`")
    end
    
    for category, position in pairs(BoostedCreature.positions) do
        local spectators = Game.getSpectators(position, false, true, 0, 0, 0, 0)
        for _, creature in ipairs(spectators) do
            if creature:isMonster() then
                creature:remove()
            end
        end
    end
    
    boostCreature = {}

    BoostedCreature:start()
    
    if not boostCreature or #boostCreature == 0 then
        return true
    end
    
    if BoostedCreature.db then
        for index, boosted in ipairs(boostCreature) do
            if not boosted.name or not boosted.exp or not boosted.loot or not boosted.category then
                goto continue
            end
            
            local query = string.format(
                "INSERT INTO `boost_creature` (`category`, `name`, `exp`, `loot`) VALUES ('%s', '%s', %d, %d)",
                boosted.category, firstToUpper(boosted.name), boosted.exp, boosted.loot
            )
            
            pcall(function()
                db.query(query)
            end)
            
            ::continue::
        end
    end
    
    return true
end
BoostCreature:register()

-- Evento Think para mensagens periódicas
local BoostCreatureThink = GlobalEvent("BoostCreatureThink")
function BoostCreatureThink.onThink(...)
    for _, boosted in ipairs(boostCreature) do
        Game.broadcastMessage(string.format(
            BoostedCreature.messages[boosted.category], 
            firstToUpper(boosted.name), boosted.exp, boosted.loot
        ))
    end
    return true
end
BoostCreatureThink:interval(10800000) -- 3 horas
BoostCreatureThink:register()

-- TalkAction para o comando !boostcreature
local BoostCreatureTalk = TalkAction("!boostcreature")
function BoostCreatureTalk.onSay(player, words, param)
    if not boostCreature or #boostCreature == 0 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "No boosted creature available.")
        return false
    end
    
    param = param:lower()
    
    if param == "all" then
        for _, boosted in ipairs(boostCreature) do
            local message = string.format(
                "[%s] Boosted Creature: %s (Experience: +%d%%, Loot: +%d%%)",
                boosted.category:upper(),
                firstToUpper(boosted.name),
                boosted.exp,
                boosted.loot
            )
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, message)
        end
        return false
    end
    
    local selectedCreature = nil
    
    if param == "normal" or param == "second" or param == "third" or param == "boss" then
        for _, boosted in ipairs(boostCreature) do
            if boosted.category == param then
                selectedCreature = boosted
                break
            end
        end
    else
        selectedCreature = boostCreature[1]
    end
    
    if not selectedCreature then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
            string.format("No boosted creature found for category: %s", param))
        return false
    end
    
    local message = string.format([[
---------[+]----------- [Boost Creature] -----------[+]---------

   Every day, a monster is chosen to have additional experience and loot.

---------[+]-----------------------------------[+]---------
                                              Selected Creature: %s
                                                    Experience: +%d%%
                                                          Loot: +%d%%
    ]], firstToUpper(selectedCreature.name), selectedCreature.exp, selectedCreature.loot)
    
    player:popupFYI(message)
    
    return false
end
BoostCreatureTalk:separator(" ")
BoostCreatureTalk:register()

-- TalkAction para o comando alternativo /boostcreature
local BoostCreatureTalkAlt = TalkAction("/boostcreature")
function BoostCreatureTalkAlt.onSay(player, words, param)
    return BoostCreatureTalk.onSay(player, words, param)
end
BoostCreatureTalkAlt:separator(" ")
BoostCreatureTalkAlt:register()

-- MoveEvent para o sistema boosted (ActionID)
local config = {4004, 4005, 4006, 4007}

local BoostedCreatureEvent = MoveEvent()
function BoostedCreatureEvent.onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return false
    end

    local boostedType = ""
    local actionId = item:getActionId()
    
    if actionId == 4004 then
        boostedType = "normal"
    elseif actionId == 4005 then
        boostedType = "second"
    elseif actionId == 4006 then
        boostedType = "third"
    elseif actionId == 4007 then
        boostedType = "boss"
    else
        return false
    end

    local selectedCreature
    for _, boosted in ipairs(boostCreature) do
        if boosted.category == boostedType then
            selectedCreature = boosted
            break
        end
    end

    if not selectedCreature then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "No boosted creature found for type: " .. boostedType)
        return false
    end

    local message = string.format([[
---------[+]----------- [Boost Creature] -----------[+]---------

   Every day, a monster is chosen to have additional experience and loot.

---------[+]-----------------------------------[+]---------
                                              Chosen Creature: %s
                                                    Experience: +%d%%
                                                          Loot: +%d%%
    ]], firstToUpper(selectedCreature.name), selectedCreature.exp, selectedCreature.loot)

    player:popupFYI(message)
    player:teleportTo(fromPosition, true)

    return true
end
BoostedCreatureEvent:type("stepin")
for _, actionid in pairs(config) do
    BoostedCreatureEvent:aid(actionid)
end
BoostedCreatureEvent:register()

-- EventCallBack / onDropLoot para o sistema boosted
local Boosted_onDropLoot = Event()
Boosted_onDropLoot.onDropLoot = function(self, corpse)
    local mType = self:getType()
    if configManager.getNumber(configKeys.RATE_LOOT) == 0 then
        return
    end
    
    local player = Player(corpse:getCorpseOwner())
    if not player then
        return false
    end
    
    if player:getStamina() > 840 then
        local boostedBonusLoot = 0
        local boostedType = ""
        
        for _, boosted in ipairs(boostCreature) do
            if self:getName():lower() == boosted.name then
                boostedBonusLoot = boosted.loot
                boostedType = boosted.category
                break
            end
        end
        
        if boostedBonusLoot > 0 then
            player:sendTextMessage(MESSAGE_STATUS_DEFAULT, 
                string.format("[Boosted Creature] You have killed a %s with +%d%% Bonus Loot.", 
                mType:getName(), boostedBonusLoot))
            
            corpse:getPosition():sendMagicEffect(CONST_ME_TUTORIALARROW)
            corpse:getPosition():sendMagicEffect(CONST_ME_TUTORIALSQUARE)
            
            local rate = boostedBonusLoot / 10 * configManager.getNumber(configKeys.RATE_LOOT)
            local monsterLoot = mType:getLoot()
            
            for i = 1, #monsterLoot do
                local item = monsterLoot[i]
                if math.random(100) <= rate then
                    local count = item.maxCount > 1 and math.random(item.maxCount) or 1
                    corpse:addItem(item.itemId, count)
                end
            end
        end
    end
    
    return true
end
Boosted_onDropLoot:register(-1)