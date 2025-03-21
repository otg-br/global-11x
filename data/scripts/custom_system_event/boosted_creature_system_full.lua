local config = {
    normal_actionid = 4004,
    second_actionid = 4005,
    third_actionid = 4006,
    boss_actionid = 4007,


    interval = 10800000, -- 3 horas cada exibir mensagem info do boostada

    talk_boosted = {"!boostcreature", "/boostcreature"}
}

local BoostCreature = GlobalEvent("BoostCreature")
function BoostCreature.onStartup()
    print("[INFO] Iniciando sistema Boosted Creature")
    BoostedCreature:start()
    
    if BoostedCreature.db then
        print("[INFO] Banco de dados habilitado, iniciando atualização de registros")
        
        if not boostCreature or #boostCreature == 0 then
            print("[ERRO] Tabela boostCreature está vazia ou não existe")
            return true
        end
        
        print("[INFO] Encontrado " .. #boostCreature .. " criaturas para atualizar no banco")
        
        db.query("DELETE FROM `boost_creature`")
        print("[INFO] Tabela boost_creature limpa com sucesso")
        
        for index, boosted in ipairs(boostCreature) do
            if not boosted.name or not boosted.exp or not boosted.loot or not boosted.category then
                print("[ERRO] Dados incompletos para a criatura #" .. index)
                goto continue
            end
            
            local query = string.format(
                "INSERT INTO `boost_creature` (`category`, `name`, `exp`, `loot`) VALUES ('%s', '%s', %d, %d)",
                boosted.category, firstToUpper(boosted.name), boosted.exp, boosted.loot
            )
            
            print("[DEBUG] Query #" .. index .. ": " .. query)
            
            local status, error = pcall(function()
                db.query(query)
            end)
            
            if not status then
                print("[ERRO] Falha ao executar query #" .. index .. ": " .. (error or "erro desconhecido"))
            else
                print("[INFO] Criatura #" .. index .. " (" .. boosted.name .. ") inserida com sucesso")
            end
            
            ::continue::
        end
        
        print("[INFO] Processo de atualização do banco de dados concluído")
    else
        print("[INFO] Banco de dados desabilitado, ignorando atualizações")
    end
    
    return true
end
BoostCreature:register()

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
BoostCreatureThink:interval(config.interval)
BoostCreatureThink:register()

for _, talk_command in ipairs(config.talk_boosted) do
    local boost = TalkAction(talk_command)
    
    function boost.onSay(player, words, param)
        if not boostCreature or #boostCreature == 0 then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[DEBUG] No boosted creature available.")
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
                string.format("[DEBUG] No boosted creature found for category: %s", param))
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

        -- Debug information
        print(string.format("[DEBUG] Boosted Creature Info: Name: %s, Experience: +%d%%, Loot: +%d%%", 
            selectedCreature.name, selectedCreature.exp, selectedCreature.loot))
        
        return false
    end
    
    boost:separator(" ")
    boost:register()
end

local BoostedCreatureEvent = MoveEvent()
function BoostedCreatureEvent.onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return false
    end

    local boostedType = ""
    if item:getActionId() == config.normal_actionid then
        boostedType = "normal"
    elseif item:getActionId() == config.second_actionid then
        boostedType = "second"
    elseif item:getActionId() == config.third_actionid then
        boostedType = "third"
    elseif item:getActionId() == config.boss_actionid then
        boostedType = "boss"
    end

    local selectedCreature
    for _, boosted in ipairs(boostCreature) do
        if boosted.category == boostedType then
            selectedCreature = boosted
            break
        end
    end

    if not selectedCreature then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[DEBUG] No boosted creature found for type: " .. boostedType)
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

    -- Debug information
    print(string.format("[DEBUG] Boosted Creature Info: Name: %s, Experience: +%d%%, Loot: +%d%%", 
        selectedCreature.name, selectedCreature.exp, selectedCreature.loot))

    return true
end
BoostedCreatureEvent:type("stepin")
for _, actionid in pairs(config) do
    BoostedCreatureEvent:aid(actionid)
end
BoostedCreatureEvent:register()