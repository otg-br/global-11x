local blockedIds = { } -- Lista de ItemsID caso não queira que algum item apareça.

local function addQuickItem(playerId, itemId, itemName)
    local player = Player(playerId)
    if not player then
        return false
    end

    local itemType = ItemType(itemId)
    if not itemType then
        return false
    end

    -- Caso você tenha sistema de VIP // 25 é para VIP e 15 para Free.
    local maxItem = player:getVipDays() > 0 and 25 or 15
    --local maxItem = 15
    local itemId = itemType:getId()
    if AutoLootList:itemInList(playerId, itemId) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, string.format("[AUTO LOOT] - O item %s ja esta em sua lista de Loot.", itemName))
        return false
    end

    -- Check max item count
    local count = AutoLootList:countList(playerId)
    if count >= maxItem then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "[AUTO LOOT] - A sua lista ja esta completa, por favor remova algum item.")
        return false
    end

    local itemAdded = AutoLootList:addItem(playerId, itemId)
    if itemAdded then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, string.format("[AUTO LOOT] - O item %s foi adicionado em sua lista de Loot.", itemName))
    end

    return true
end

function removeQuickItem(playerId, itemId, itemName)
    local player = Player(playerId)
    if not player then
        return false
    end

    local playerGuid = player:getGuid()
    if not AutoLootList:itemInList(playerId, itemId) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, string.format("[AUTO LOOT] - O item %s nao esta em sua lista de Loot", itemName))
        return false
    end

    local itemRemoved = AutoLootList:removeItem(playerId, itemId)
    if itemRemoved then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, string.format("[AUTO LOOT] - O item %s foi removido da sua lista de Loot.", itemName))
    end

    return true
end

local function itemListMonsterModal(playerId, monsterName)
    local player = Player(playerId)
    if not player then
        return false
    end

    local monsterType = MonsterType(monsterName)
    if not monsterType then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Esse monstro nao existe ou nao esta no mapa.")
        return false
    end

   if monsterType:isRewardBoss() then
     player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Voce nao pode visualizar os Loot de Bosses de Reward Chest.")
     return false
   end
    
    -- if string.match(monsterName:lower(), "halloween") then
        -- player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Voce nao pode visualizar os Loot de monstros do Halloween.")
        -- return false
    -- end

    local monsterName = monsterType:getName()
    local window = ModalWindow {
        title = string.format('Loot do monstro %s', monsterName:lower()),
        message = 'Adiciona ou remova itens desse monstro da sua lista de loot.',
    }

    local windowCount = 0
    local t = {}
    local playerGuid = player:getGuid()
    local monsterLoot = monsterType:getLoot()
    if monsterLoot then
        if #monsterLoot == 0 then
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Esse monstro nao possui nenhum Loot disponível.")
            return false
        end
        
        for _, v in pairs(monsterLoot) do
            if windowCount < 255 then
                local itemId = v.itemId
                if not isInArray(t, itemId) and not isInArray(blockedIds, itemId) then
                    local itemType = ItemType(itemId)
                    if itemType then
                        local itemName = itemType:getName()

                        local itemIsInList = AutoLootList:itemInList(playerId, itemId) and ' - Adicionado!' or ''
                        local choice = window:addChoice(itemName .. itemIsInList)
                        windowCount = windowCount + 1

                        choice.itemId = itemId
                        choice.itemName = itemName
                        table.insert(t, itemId)
                    end
                end
            end
        end
    end

    window:addButton("Remover",
        function(button, choice)
            if player and choice then
                removeQuickItem(player:getId(), choice.itemId, choice.itemName)
                itemListMonsterModal(playerId, monsterName)
            end
        end
    )

    window:addButton("Adicionar",
        function(button, choice)
            if player and choice then
                addQuickItem(player:getId(), choice.itemId, choice.itemName)
                itemListMonsterModal(playerId, monsterName)
            end
        end
    )
    window:setDefaultEnterButton("Adicionar")

    window:addButton("Sair")
    window:setDefaultEscapeButton("Sair")
    window:sendToPlayer(player)
end

function openModalList(playerId)
    local player = Player(playerId)
    if not player then
        return false
    end

    local window = ModalWindow {
        title = "Sua lista de itens",
        message = 'Essa eh sua lista de itens!\nAssim que algum desses itens forem dropados, e ao clicar no corpo do monstro\no item sera enviado para a sua backpack!',
    }

    local lootList = AutoLootList:getItemList(playerId)
    for _, loot in pairs(lootList) do
        local itemType = ItemType(loot.item_id)
        if itemType then
            local itemName = itemType:getName()
            local choice = window:addChoice(itemName)

            choice.itemId = itemType:getId()
            choice.itemName = itemName
        end
    end

    window:addButton("Remover",
        function(button, choice)
            if player and choice then
                removeQuickItem(playerId, choice.itemId, choice.itemName)
                openModalList(playerId)
            end
        end
    )

    window:addButton("Sair")
    window:setDefaultEscapeButton("Sair")
    window:sendToPlayer(player)
end

function onSay(player, words, param)
    
	if player:getStorageValue(Storage.autoloot1) > os.time() then
		player:sendCancelMessage("You are exhausted. wait 1 seconds to take again")
		return false
	end

	player:setStorageValue(Storage.autoloot1, os.time() + 1)
	
    local split = param:split(",")
    local action = split[1]
    local playerGuid = player:getGuid()
    local playerId = player:getId()

    if action == "add" then
        if not split[2] then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Use o comando: !loot add, itemName")
            return false
        end

        local item = split[2]:gsub("%s+", "", 1)
        local itemType = ItemType(item)
        local itemId = itemType:getId()
        if itemId == 0 then
            itemType = ItemType(tonumber(item))
            if itemId == 0 then
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Nao existe nenhum item com esse nome.")
                return false
            end
        end

        -- Checar se o item já está na lista do jogador.
        local itemName = tonumber(split[2]) and itemType:getName() or item
        addQuickItem(player:getId(), itemId, itemName)
    elseif action == "remove" then
        if not split[2] then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Use o comando: !loot remove, itemName")
            return false
        end

        local item = split[2]:gsub("%s+", "", 1)
        local itemType = ItemType(item)
        local itemId = itemType:getId()
        if itemId == 0 then
            itemType = ItemType(tonumber(item))
            if itemId == 0 then
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Nao existe nenhum item com esse nome.")
                return false
            end
        end

        local itemName = tonumber(split[2]) and itemType:getName() or item
        if not AutoLootList:itemInList(playerId, itemId) then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, itemName .." nao foi encontrado em sua lista.")
            return false
        end

        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, itemName .." foi removido de sua lista.")
        removeQuickItem(player:getId(), itemId, itemName)
    elseif action == "list" or action == "show" then
        local count = AutoLootList:countList(playerId)
        if count == 0 then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Voce nao possui nenhum item em sua lista.")
            return false
        end

        openModalList(playerId)
    else
        if not split[1] then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Os itens serao movidos automaticamente para a sua Backpack:\n!autoloot list - ira listar todos os itens da sua lista.\n!autoloot monsterName - verificar o loot de um monstro (exemplo: !autoloot rat)\n!autoloot add, itemName - adicionar um item pelo o nome\n!autoloot remove, itemName - remover o item pelo o nome")
            return false
        end

        local monsterName = trim(split[1])
        itemListMonsterModal(player:getId(), monsterName)
    end

    return false
end