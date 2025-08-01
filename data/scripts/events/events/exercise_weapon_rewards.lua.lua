local configs = {
    basic = {
        items = {
            {name = "exercise sword", itemId = 33082, charges = 8000, storage = 998000},
            {name = "exercise axe", itemId = 33083, charges = 8000, storage = 998001},
            {name = "exercise club", itemId = 33084, charges = 8000, storage = 998002},
            {name = "exercise bow", itemId = 33085, charges = 8000, storage = 998003},
            {name = "exercise rod", itemId = 33086, charges = 8000, storage = 998004},
            {name = "exercise wand", itemId = 33087, charges = 8000, storage = 998005}
        }
    },
    
    time = {
        items = {
            {name = "exercise sword", itemId = 33082, charges = 8000},
            {name = "exercise axe", itemId = 33083, charges = 8000},
            {name = "exercise club", itemId = 33084, charges = 8000},
            {name = "exercise bow", itemId = 33085, charges = 8000},
            {name = "exercise rod", itemId = 33086, charges = 8000},
            {name = "exercise wand", itemId = 33087, charges = 8000}
        },
        cooldown = 7 * 24 * 60 * 60 -- 7 dias em segundos
    },
    
    prey_wildcard = {
        items = {
            {name = "exercise sword", itemId = 33082, charges = 8000, storage = 998010},
            {name = "exercise axe", itemId = 33083, charges = 8000, storage = 998011},
            {name = "exercise club", itemId = 33084, charges = 8000, storage = 998012},
            {name = "exercise bow", itemId = 33085, charges = 8000, storage = 998013},
            {name = "exercise rod", itemId = 33086, charges = 8000, storage = 998014},
            {name = "exercise wand", itemId = 33087, charges = 8000, storage = 998015}
        },
        prey_wildcard_amount = 10,
        prey_wildcard_limit = 50
    },
    
    prey_wildcard_time = {
        items = {
            {name = "exercise sword", itemId = 33082, charges = 8000, storage = 998020},
            {name = "exercise axe", itemId = 33083, charges = 8000, storage = 998021},
            {name = "exercise club", itemId = 33084, charges = 8000, storage = 998022},
            {name = "exercise bow", itemId = 33085, charges = 8000, storage = 998023},
            {name = "exercise rod", itemId = 33086, charges = 8000, storage = 998024},
            {name = "exercise wand", itemId = 33087, charges = 8000, storage = 998025}
        },
        prey_wildcard_amount = 10,
        prey_wildcard_limit = 50
    },
    
    daily = {
        items = {
            { id = 33087 },
            { id = 33082 },
            { id = 33084 },
            { id = 33086 },
            { id = 33085 },
            { id = 33083 },
            { id = 44066 },
        },
        storage = 998030, -- Storage para daily reward
        cooldown = 24 * 60 * 60, -- 24 horas em segundos
        charges = 64400
    }
}

local function sendBasicRewardModal(player)
    local window = ModalWindow {
        title = "Exercise Reward",
        message = "Choose an item"
    }
    
    for _, it in pairs(configs.basic.items) do
        local iType = ItemType(it.itemId)
        if iType then
            local choice = window:addChoice(iType:getName())
            choice.itemId = it.itemId
            choice.itemName = it.name
            choice.storage = it.storage
            choice.charges = it.charges
        end
    end
    
    window:addButton("Select", function(button, choice)
        if not choice then
            return
        end
        
        if player:getStorageValue(choice.storage) > 0 then
            player:sendTextMessage(MESSAGE_INFO_DESCR, "You already received your exercise weapon reward!")
            return
        end
        
        local inbox = player:getSlotItem(CONST_SLOT_STORE_INBOX)
        if inbox and inbox:getEmptySlots() > 0 then
            local item = inbox:addItem(choice.itemId, choice.charges)
            if item then
                item:setActionId(IMMOVABLE_ACTION_ID)
                player:sendTextMessage(MESSAGE_INFO_DESCR, "Congratulations, you just received a [".. choice.itemName .."].")
                player:setStorageValue(choice.storage, 1)
            end
        else
            player:sendTextMessage(MESSAGE_INFO_DESCR, "You need to have capacity and empty slots to receive.")
        end
    end)
    
    window:addButton("Close")
    window:setDefaultEnterButton("Select")
    window:setDefaultEscapeButton("Close")
    window:sendToPlayer(player)
end

local function sendTimeRewardModal(player)
    local window = ModalWindow {
        title = "Exercise Reward",
        message = "Choose an item"
    }
    
    for _, it in pairs(configs.time.items) do
        local iType = ItemType(it.itemId)
        if iType then
            local choice = window:addChoice(iType:getName())
            choice.itemId = it.itemId
            choice.itemName = it.name
            choice.charges = it.charges
        end
    end
    
    window:addButton("Select", function(button, choice)
        if not choice then
            return
        end

        local lastRewardTime = player:getStorageValue("last_exercise_reward") or 0
        local timeSinceLastReward = os.time() - lastRewardTime
        if timeSinceLastReward >= configs.time.cooldown then
            local inbox = player:getSlotItem(CONST_SLOT_STORE_INBOX)
            if inbox and inbox:getEmptySlots() > 0 then
                local item = inbox:addItem(choice.itemId, choice.charges)
                if item then
                    item:setActionId(IMMOVABLE_ACTION_ID)
                    player:setStorageValue("last_exercise_reward", os.time())
                    player:sendTextMessage(MESSAGE_INFO_DESCR, "Congratulations, you just received a [".. choice.itemName .."].")
                end
            else
                player:sendTextMessage(MESSAGE_INFO_DESCR, "You need to have capacity and empty slots to receive.")
            end
        else
            local timeLeft = configs.time.cooldown - timeSinceLastReward
            local daysLeft = math.floor(timeLeft / (60 * 60 * 24))
            timeLeft = timeLeft - daysLeft * 60 * 60 * 24
            local hoursLeft = math.floor(timeLeft / (60 * 60))
            timeLeft = timeLeft - hoursLeft * 60 * 60
            local minutesLeft = math.floor(timeLeft / 60)
            local secondsLeft = timeLeft % 60
            local message = string.format("You must wait %d days, %d hours, %d minutes and %d seconds before claiming your next reward.", daysLeft, hoursLeft, minutesLeft, secondsLeft)
            player:sendTextMessage(MESSAGE_INFO_DESCR, message)
        end
    end)
    
    window:addButton("Close")
    window:setDefaultEnterButton("Select")
    window:setDefaultEscapeButton("Close")
    window:sendToPlayer(player)
end

local function sendPreyWildcardRewardModal(player)
    local window = ModalWindow {
        title = "Exercise Reward",
        message = "Choose an item"
    }
    
    for _, it in pairs(configs.prey_wildcard.items) do
        local iType = ItemType(it.itemId)
        if iType then
            local choice = window:addChoice(iType:getName())
            choice.itemId = it.itemId
            choice.itemName = it.name
            choice.storage = it.storage
            choice.charges = it.charges
        end
    end
    
    window:addButton("Select", function(button, choice)
        if not choice then
            return
        end

        if player:getStorageValue(choice.storage) > 0 then
            player:sendTextMessage(MESSAGE_LOOK, "You already received your exercise weapon reward!")
            return
        end
        
        local inbox = player:getSlotItem(CONST_SLOT_STORE_INBOX)
        if inbox and inbox:getEmptySlots() > 0 then
            local item = inbox:addItem(choice.itemId, choice.charges)
            if item then
                item:setActionId(IMMOVABLE_ACTION_ID)
                player:sendTextMessage(MESSAGE_LOOK, "Congratulations, you just received a [".. choice.itemName .."].")
                player:setStorageValue(choice.storage, 1)

                local currentBonusRerolls = player:getBonusRerollCount()
                local cardsToAdd = math.min(configs.prey_wildcard.prey_wildcard_amount, configs.prey_wildcard.prey_wildcard_limit - currentBonusRerolls)

                if cardsToAdd > 0 then
                    player:setBonusRerollCount(currentBonusRerolls + cardsToAdd)
                    player:sendTextMessage(MESSAGE_LOOK, "You also received [" .. cardsToAdd .. "] Prey Wildcards.")
                else
                    player:sendTextMessage(MESSAGE_LOOK, "You already have the maximum amount of Prey Wildcards.")
                end
            end
        else
            player:sendTextMessage(MESSAGE_LOOK, "You need to have capacity and empty slots to receive.")
        end
    end)
    
    window:addButton("Close")
    window:setDefaultEnterButton("Select")
    window:setDefaultEscapeButton("Close")
    window:sendToPlayer(player)
end

local function sendPreyWildcardTimeRewardModal(player)
    local window = ModalWindow {
        title = "Exercise Reward",
        message = "Choose an item"
    }
    
    for _, it in pairs(configs.prey_wildcard_time.items) do
        local iType = ItemType(it.itemId)
        if iType then
            local choice = window:addChoice(iType:getName())
            choice.itemId = it.itemId
            choice.itemName = it.name
            choice.storage = it.storage
            choice.charges = it.charges
        end
    end
    
    window:addButton("Select", function(button, choice)
        if not choice then
            return
        end

        if player:getStorageValue(choice.storage) > 0 then
            player:sendTextMessage(MESSAGE_LOOK, "You already received your exercise weapon reward!")
            return
        end
        
        local inbox = player:getSlotItem(CONST_SLOT_STORE_INBOX)
        if inbox and inbox:getEmptySlots() > 0 then
            local item = inbox:addItem(choice.itemId, choice.charges)
            if item then
                item:setActionId(IMMOVABLE_ACTION_ID)
                player:sendTextMessage(MESSAGE_LOOK, "Congratulations, you just received a [".. choice.itemName .."].")
                player:setStorageValue(choice.storage, 1)

                local currentBonusRerolls = player:getBonusRerollCount()
                local cardsToAdd = math.min(configs.prey_wildcard_time.prey_wildcard_amount, configs.prey_wildcard_time.prey_wildcard_limit - currentBonusRerolls)

                if cardsToAdd > 0 then
                    player:setBonusRerollCount(currentBonusRerolls + cardsToAdd)
                    player:sendTextMessage(MESSAGE_LOOK, "You also received [" .. cardsToAdd .. "] Prey Wildcards.")
                else
                    player:sendTextMessage(MESSAGE_LOOK, "You already have the maximum amount of Prey Wildcards.")
                end
            end
        else
            player:sendTextMessage(MESSAGE_LOOK, "You need to have capacity and empty slots to receive.")
        end
    end)
    
    window:addButton("Close")
    window:setDefaultEnterButton("Select")
    window:setDefaultEscapeButton("Close")
    window:sendToPlayer(player)
end

local function sendDailyRewardModal(player)
    local window = ModalWindow {
        title = "Exercise Reward",
        message = "Choose an item"
    }
    
    for _, it in pairs(configs.daily.items) do
        local iType = ItemType(it.id)
        if iType then
            local choice = window:addChoice(iType:getName())
            choice.itemId = it.id
            choice.itemName = iType:getName()
        end
    end
    
    window:addButton("Select", function(button, choice)
        if not choice then
            return
        end

        local itemType = ItemType(choice.itemId)
        if not itemType then
            player:sendTextMessage(MESSAGE_LOOK, "Invalid item type.")
            return
        end

        local inbox = player:getSlotItem(CONST_SLOT_STORE_INBOX)
        if inbox and inbox:getEmptySlots() > 0 then
            local item = inbox:addItem(choice.itemId, configs.daily.charges)
            if item then
                item:setActionId(IMMOVABLE_ACTION_ID)
                player:sendTextMessage(MESSAGE_LOOK, string.format("Congratulations, you received a %s with %i charges in your store inbox.", choice.itemName, configs.daily.charges))
                player:setStorageValue(configs.daily.storage, os.time())
            else
                player:sendTextMessage(MESSAGE_LOOK, "You need to have capacity and empty slots to receive.")
            end
        else
            player:sendTextMessage(MESSAGE_LOOK, "You need to have capacity and empty slots to receive.")
        end
    end)
    
    window:addButton("Close")
    window:setDefaultEnterButton("Select")
    window:setDefaultEscapeButton("Close")
    window:sendToPlayer(player)
end

local basicRewardModal = TalkAction("!reward")
function basicRewardModal.onSay(player, words, param)
    sendBasicRewardModal(player)
    return false
end
basicRewardModal:separator(" ")
basicRewardModal:register()

local timeRewardModal = TalkAction("!rewardtime")
function timeRewardModal.onSay(player, words, param)
    sendTimeRewardModal(player)
    return false
end
timeRewardModal:separator(" ")
timeRewardModal:register()

local preyWildcardRewardModal = TalkAction("!rewardprey")
function preyWildcardRewardModal.onSay(player, words, param)
    sendPreyWildcardRewardModal(player)
    return false
end
preyWildcardRewardModal:separator(" ")
preyWildcardRewardModal:register()

local preyWildcardTimeRewardModal = TalkAction("!rewardpreytime")
function preyWildcardTimeRewardModal.onSay(player, words, param)
    sendPreyWildcardTimeRewardModal(player)
    return false
end
preyWildcardTimeRewardModal:separator(" ")
preyWildcardTimeRewardModal:register()

local dailyRewardModal = TalkAction("!rewarddaily")
function dailyRewardModal.onSay(player, words, param)
    local lastRewardTime = player:getStorageValue(configs.daily.storage)
    if lastRewardTime > 0 then
        local timeSinceLastReward = os.time() - lastRewardTime
        if timeSinceLastReward < configs.daily.cooldown then
            local hoursRemaining = math.ceil((configs.daily.cooldown - timeSinceLastReward) / 3600)
            player:sendTextMessage(MESSAGE_LOOK, "You need to wait another " .. hoursRemaining .. " hour(s) to use this command again.")
            return true
        end
    end

    sendDailyRewardModal(player)
    return false
end
dailyRewardModal:separator(" ")
dailyRewardModal:register()