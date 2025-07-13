-- Global Event to initialize auto-loot variables on server startup
local autoLootStartup = GlobalEvent("AutoLootStartup")
function autoLootStartup.onStartup()
    lootBlockListm = {}  -- Table to store blocked loot items (category m)
    lootBlockListn = {}  -- Table to store blocked loot items (category n)
    lastItem = {}        -- Table to track the last item processed
    autolootBP = 1       -- Enable (1) or disable (0) auto-loot to backpack (requires autolootmode = 2 in config.lua)
    return true
end
autoLootStartup:register()

-- Configuration settings
local config = {
    premiumMaxItems = 25,        -- Maximum items in the auto-loot list for premium players
    freeMaxItems = 15,           -- Maximum items in the auto-loot list for free players
    exhaustTime = 2,             -- Cooldown time in seconds for using the autoloot command
    rewardBossMessage = "[AUTO LOOT] - You cannot view the loot of Reward Chest bosses.",
    GOLD_POUCH = 26377,          -- ID of the Gold Pouch
    blockedIds = {2393, 2152, 2148} -- IDs of items that cannot be added to the auto-loot list (e.g., Crystal Coin, Platinum Coin, Gold Coin)
}

local AUTO_LOOT_COOLDOWN_STORAGE = 10001

function trim(s)
    return s:match("^%s*(.-)%s*$")
end

function isInArray(array, value)
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

-- Event triggered when a creature is killed
local system_autoloot_onKill = CreatureEvent("AutoLoot")
function system_autoloot_onKill.onKill(creature, target)
    if not target:isMonster() then
        return true
    end

    addEvent(AutoLootList.getLootItem, 100, AutoLootList, creature:getId(), target:getPosition())
    return true
end
system_autoloot_onKill:register()

-- Add an item to the player's auto-loot list
local function addQuickItem(playerId, itemId, itemName)
    local player = Player(playerId)
    if not player then
        return false
    end

    local itemType = ItemType(itemId)
    if not itemType or itemType:getId() == 0 then
        return false
    end

    -- Check if the item is blocked
    if isInArray(config.blockedIds, itemId) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, string.format("[AUTO LOOT] - The item %s is blocked and cannot be added to your loot list.", itemName))
        return false
    end

    -- Check if the player has reached the maximum number of items in their list
    local maxItems = player:getPremiumDays() > 0 and config.premiumMaxItems or config.freeMaxItems
    if AutoLootList:itemInList(playerId, itemId) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, string.format("[AUTO LOOT] - The item %s is already in your loot list.", itemName))
        return false
    end

    local count = AutoLootList:countList(playerId)
    if count >= maxItems then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "[AUTO LOOT] - Your loot list is full. Please remove an item to add a new one.")
        return false
    end

    -- Add the item to the player's auto-loot list
    local itemAdded = AutoLootList:addItem(playerId, itemId)
    if itemAdded then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, string.format("[AUTO LOOT] - The item %s has been added to your loot list.", itemName))
    end

    return true
end

-- Remove an item from the player's auto-loot list
local function removeQuickItem(playerId, itemId, itemName)
    local player = Player(playerId)
    if not player then
        return false
    end

    if not AutoLootList:itemInList(playerId, itemId) then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, string.format("[AUTO LOOT] - The item %s is not in your loot list.", itemName))
        return false
    end

    -- Remove the item from the player's auto-loot list
    local itemRemoved = AutoLootList:removeItem(playerId, itemId)
    if itemRemoved then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, string.format("[AUTO LOOT] - The item %s has been removed from your loot list.", itemName))
    end

    return true
end

-- Validate an item by name or ID
local function validateItem(itemInput)
    local itemType = ItemType(itemInput)
    local itemId = itemType:getId()
    if itemId == 0 then
        itemType = ItemType(tonumber(itemInput))
        itemId = itemType:getId()
    end

    if itemId == 0 then
        return nil, nil
    end

    local itemName = tonumber(itemInput) and itemType:getName() or itemInput
    return itemId, itemName
end

-- Display a modal window with the loot of a specific monster
local function showMonsterLootModal(playerId, monsterName)
    local player = Player(playerId)
    if not player then
        return false
    end

    local monsterType = MonsterType(monsterName)
    if not monsterType then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - This monster does not exist or is not on the map.")
        return false
    end

    if monsterType:isRewardBoss() then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, config.rewardBossMessage)
        return false
    end

    local formattedMonsterName = monsterName:lower()
    local window = ModalWindow {
        title = string.format("Loot of the Monster %s", formattedMonsterName),
        message = "Add or remove items from this monster to your auto-loot list.",
    }

    local windowCount = 0
    local uniqueItems = {}
    local monsterLoot = monsterType:getLoot()
    if monsterLoot then
        if #monsterLoot == 0 then
            player:sendTextMessage(MESSAGE_INFO_DESCR, "This monster has no available loot.")
            return false
        end
        
        for _, v in pairs(monsterLoot) do
            if windowCount < 255 then
                local itemId = v.itemId
                if not isInArray(uniqueItems, itemId) and not isInArray(config.blockedIds, itemId) then
                    local itemType = ItemType(itemId)
                    if itemType then
                        local itemName = itemType:getName()

                        local itemStatus = AutoLootList:itemInList(playerId, itemId) and ' - Added!' or ''
                        local choice = window:addChoice(itemName .. itemStatus)
                        windowCount = windowCount + 1

                        choice.itemId = itemId
                        choice.itemName = itemName
                        table.insert(uniqueItems, itemId)
                    end
                end
            end
        end
    end

    -- Warn the player if the loot list exceeds the modal window limit
    if windowCount >= 255 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Warning: Some items may not be displayed due to modal window limitations.")
    end

    window:addButton("Remove",
        function(button, choice)
            if player and choice then
                removeQuickItem(player:getId(), choice.itemId, choice.itemName)
                showMonsterLootModal(playerId, formattedMonsterName)
            end
        end
    )

    window:addButton("Add",
        function(button, choice)
            if player and choice then
                addQuickItem(player:getId(), choice.itemId, choice.itemName)
                showMonsterLootModal(playerId, formattedMonsterName)
            end
        end
    )
    window:setDefaultEnterButton("Add")

    window:addButton("Close")
    window:setDefaultEscapeButton("Close")
    window:sendToPlayer(player)
end

-- Display a modal window with the player's current auto-loot list
local function openLootListModal(playerId)
    local player = Player(playerId)
    if not player then
        return false
    end

    local window = ModalWindow {
        title = "Your Auto-Loot List",
        message = "This is your auto-loot list!\nWhen these items drop, clicking on the monster's corpse will send them to your Gold Pouch.",
    }

    local lootList = AutoLootList:getItemList(playerId)
    for _, loot in pairs(lootList) do
        local itemType = ItemType(loot.item_id)
        if itemType then
            local itemName = itemType:getName()
            local choice = window:addChoice(itemName .. " (Gold Pouch)")

            choice.itemId = itemType:getId()
            choice.itemName = itemName
        end
    end

    window:addButton("Remove",
        function(button, choice)
            if player and choice then
                removeQuickItem(playerId, choice.itemId, choice.itemName)
                openLootListModal(playerId)
            end
        end
    )

    window:addButton("Close")
    window:setDefaultEscapeButton("Close")
    window:sendToPlayer(player)
end

-- Move an item to the player's Gold Pouch
local function moveToGoldPouch(player, item)
    if not player or not item then
        return false
    end

    local goldPouch = player:getItemById(config.GOLD_POUCH, true)
    if not goldPouch then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - You need a Gold Pouch to use auto-loot.")
        return false
    end

    return item:moveTo(goldPouch)
end

-- Modified function to handle auto-looting items
function AutoLootList.getLootItem(self, playerId, position)
    local player = Player(playerId)
    if not player then
        return false
    end

    local tile = Tile(position)
    if not tile then
        return false
    end

    local corpse = tile:getTopDownItem()
    if not corpse or not corpse:isContainer() then
        return false
    end

    local items = {}
    for i = 0, corpse:getSize() - 1 do
        local item = corpse:getItem(i)
        if item then
            table.insert(items, item)
        end
    end

    for _, item in ipairs(items) do
        if self:itemInList(playerId, item:getId()) then
            local itemMoved = moveToGoldPouch(player, item)
            
            if itemMoved then
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[AUTO LOOT] - The item %s has been moved to your Gold Pouch.", item:getName()))
            end
        end
    end

    return true
end

-- TalkAction for auto-loot commands
local system_autoloot_talk = TalkAction("!autoloot", "/autoloot")

function system_autoloot_talk.onSay(player, words, param, type)
    -- Check cooldown for the autoloot command
    if player:getStorageValue(AUTO_LOOT_COOLDOWN_STORAGE) > os.time() then
        player:sendCancelMessage(string.format("You are on cooldown. Please wait %d seconds to use the command again.", config.exhaustTime))
        return false
    end

    player:setStorageValue(AUTO_LOOT_COOLDOWN_STORAGE, os.time() + config.exhaustTime)
    
    local split = param:split(",")
    local action = split[1] and trim(split[1]) or ""
    local playerId = player:getId()

    if action == "add" then
        if not split[2] then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Usage: !autoloot add, itemName")
            return false
        end

        local itemInput = trim(split[2])
        local itemId, itemName = validateItem(itemInput)
        if not itemId then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - No item exists with that name.")
            return false
        end

        addQuickItem(player:getId(), itemId, itemName)
    elseif action == "remove" then
        if not split[2] then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Usage: !autoloot remove, itemName")
            return false
        end

        local itemInput = trim(split[2])
        local itemId, itemName = validateItem(itemInput)
        if not itemId then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - No item exists with that name.")
            return false
        end

        if not AutoLootList:itemInList(playerId, itemId) then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("[AUTO LOOT] - The item %s is not in your loot list.", itemName))
            return false
        end

        removeQuickItem(player:getId(), itemId, itemName)
    elseif action == "list" or action == "show" then
        local count = AutoLootList:countList(playerId)
        if count == 0 then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Your loot list is empty.")
            return false
        end

        openLootListModal(playerId)
    elseif action ~= "" then
        local monsterName = action
        showMonsterLootModal(player:getId(), monsterName)
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[AUTO LOOT] - Items will be automatically moved to your Gold Pouch:\n!autoloot list - Shows all items in your loot list.\n!autoloot monsterName - View the loot of a monster (e.g., !autoloot rat).\n!autoloot add, itemName - Add an item by name.\n!autoloot remove, itemName - Remove an item by name.")
        return false
    end

    return false
end
system_autoloot_talk:separator(" ")
system_autoloot_talk:register()

-- Event to handle moving items into the Gold Pouch
local moveItemEvent = Event()
function moveItemEvent.onMoveItem(player, item, count, fromPosition, toPosition)
    if toPosition.x == CONTAINER_POSITION then
        local container = player:getSlotItem(toPosition.z)
        if container and container:getId() == config.GOLD_POUCH then
            if isInArray(config.blockedIds, item:getId()) then
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "This item cannot be moved into the Gold Pouch.")
                return false
            end
        end
    end
    return true
end
moveItemEvent:register()