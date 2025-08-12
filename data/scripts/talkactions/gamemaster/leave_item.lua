local leaveLoot = TalkAction("!leaveloot")
function leaveLoot.onSay(player, words, param, type)
    if not player:getGroup():getAccess() then
        return true
    end
    
    if player:getGroup():getId() < 4 then
        player:sendCancelMessage("You need to be at least a Gamemaster to use this command.")
        return true
    end
    
    local targetPlayer = nil
    
    if param and param:trim() ~= "" then
        local targetName = param:trim()
        targetPlayer = Player(targetName)
        
        if not targetPlayer then
            player:sendTextMessage(MESSAGE_STATUS_WARNING, string.format("Player '%s' is not online.", targetName))
            return true
        end
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: !leaveloot <player_name>")
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Example: !leaveloot PlayerName")
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "This command removes all items from the target player's Gold Pouch.")
        return true
    end
    
    local removedItems = 0
    local removedTypes = {}
    local GOLD_POUCH_ID = 26377
    
    local goldPouch = targetPlayer:getItemById(GOLD_POUCH_ID, true)
    if goldPouch and goldPouch:isContainer() then
        for i = goldPouch:getSize() - 1, 0, -1 do
            local item = goldPouch:getItem(i)
            if item then
                local itemType = ItemType(item:getId())
                local itemName = itemType:getName()
                local count = item:getCount()
                
                if targetPlayer:removeItem(item:getId(), count) then
                    removedItems = removedItems + count
                    if not removedTypes[itemName] then
                        removedTypes[itemName] = 0
                    end
                    removedTypes[itemName] = removedTypes[itemName] + count
                end
            end
        end
    end
    
    if removedItems > 0 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Successfully cleared %s's Gold Pouch! Removed %d items:", targetPlayer:getName(), removedItems))
        
        targetPlayer:sendTextMessage(MESSAGE_STATUS_WARNING, string.format("A Gamemaster (%s) has cleared your Gold Pouch.", player:getName()))
        
        local details = {}
        for itemName, count in pairs(removedTypes) do
            table.insert(details, string.format("%d x %s", count, itemName))
        end
        
        local message = ""
        for i, detail in ipairs(details) do
            if #message + #detail > 200 then
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, message)
                message = detail
            else
                if message ~= "" then
                    message = message .. ", " .. detail
                else
                    message = detail
                end
            end
        end
        
        if message ~= "" then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, message)
        end
        
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        targetPlayer:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
        
    elseif not goldPouch then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, string.format("%s doesn't have a Gold Pouch in their inventory.", targetPlayer:getName()))
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    else
        player:sendTextMessage(MESSAGE_STATUS_WARNING, string.format("No items found in %s's Gold Pouch to remove.", targetPlayer:getName()))
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    end
    
    return true
end
leaveLoot:separator(" ")
leaveLoot:register()