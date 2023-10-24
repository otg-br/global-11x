local config = {
	minValue = 1,
	maxValue = 99
}

local spellTable = {
	["exura"] = {id = 1},
	["exura gran"] = {id = 2},
	["exura ico"] = {id = 3},
	["exura san"] = {id = 4},
	["exura vita"] = {id = 5},
	["exura gran san"] = {id = 6},
	["exura gran ico"] = {id = 7},
    ["exura gran mas res"] = {id = 8},
    ["exura sio"] = {id = 9}
}

function onTextEdit(player, item, text)
    if type(item) ~= "userdata" then return true end
    if item:getActionId() == 19000 then
        local percentage = tonumber(text)
        if percentage then
            for w, k in pairs (spellTable) do
                if k.id == player:getStorageValue(AUTOHEAL_STORAGE_SAY) then
                    spell = w
                end     
            end
            player:sendCancelMessage("[Auto Heal] Feature enabled.")
            player:sendTextMessage(MESSAGE_STATUS_WARNING, "[Auto Heal]\n"..
            "Amount of health: "..percentage.."%\n"..
            "Spell used: "..spell.."\n"..
            "Type !autoheal [0] to disable this feature.")
            player:setStorageValue(AUTOHEAL_STORAGE_PERCENTAGE_HEALTH, percentage)
            player:registerEvent('AutoHeal')
        else
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal] Error:\nThe amount must be a number.")
            return true
        end
    elseif item:getActionId() == 19001 then
        local percentage = tonumber(text)
        if percentage then
            local fluid = ItemType(player:getStorageValue(AUTOHEAL_STORAGE_ITEM_MANA))
            if fluid:getId() then
                player:sendCancelMessage("[Auto Heal] Feature enabled.")
                player:sendTextMessage(MESSAGE_STATUS_WARNING, "[Auto Heal]\n"..
                "Amount of mana: "..percentage.."%\n"..
                "Item used: "..fluid:getName().."\n"..
                "Type !autoheal [0] to disable this feature.")
                player:setStorageValue(AUTOHEAL_STORAGE_PERCENTAGE_MANA, percentage)
                player:registerEvent('AutoHeal')
            else
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal] Error:\nUnkown item.")
                return true
            end
        else
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal] Error:\nThe amount must be a number.")
            return true
        end
    end
    player:unregisterEvent('autoHeal_textEdit')
    return true
end