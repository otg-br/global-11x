local AutoHealingSystem = {
	Developer = "Davi (worthdavi)",
	Version = "0.1",
	LastUpdate = "0/0/0 - 00:0 (AM)"
}

AUTOHEAL_STORAGE_PERCENTAGE = 182730
AUTOHEAL_STORAGE_SAY = 182731
AUTOHEAL_STORAGE_ISHEALING = 182732

local config = {
	minValue = 1,
	maxValue = 99
}

local spellTable = {
	[" exura"] = {id = 1},
	[" exura gran"] = {id = 2},
	[" exura ico"] = {id = 3},
	[" exura san"] = {id = 4},
	[" exura vita"] = {id = 5},
	[" exura gran san"] = {id = 6},
	[" exura gran ico"] = {id = 7},
	[" exura gran mas res"] = {id = 8}
}

function onSay(player, words, param)
	if not param or param == "" then
		player:sendCancelMessage("O comando requer parâmetros.")
		return false
	elseif param == "info" then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal]\nUse the parameter !autoheal [%], [spell] to choose the amount (in %) of health that you want to use your healing spells.\n"..
		"Use the parameter !autoheal 0 to disable the feature.")
		return true
	elseif param == "help" then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal]\nDisponible spells:\nexura, exura gran, exura ico, exura san, exura vita, exura gran san, exura gran ico, exura gran mas res\nFor more information, check our website.")
		return true
	end
	local param = string.explode(param, ",")
	if isNumber(param[1]) then 
		local percentage = tonumber(param[1])
		if percentage == 0 then
			if player:getStorageValue(AUTOHEAL_STORAGE_PERCENTAGE) ~= -1 or 
			player:getStorageValue(AUTOHEAL_STORAGE_PERCENTAGE) ~= -1 then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal]\nFeature disabled.")
				player:setStorageValue(AUTOHEAL_STORAGE_PERCENTAGE, -1)
				player:setStorageValue(AUTOHEAL_STORAGE_SAY, -1)
				player:setStorageValue(AUTOHEAL_STORAGE_ISHEALING, -1)
				player:unregisterEvent('AutoHeal')
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal]\nThis feature is already disabled.")
				return false
			end
		elseif percentage > config.minValue and percentage < config.maxValue then
			local spell = spellTable[param[2]]
			if spell then
				local id = spell.id
				player:sendCancelMessage("[Auto Heal] Feature enabled.")
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "[Auto Heal]\n"..
				"Amount of health: "..param[1].."%\n"..
				"Spell used: "..param[2].."\n"..
				"Type !autoheal [0] to disable this feature.")
				player:setStorageValue(AUTOHEAL_STORAGE_PERCENTAGE, param[1])			
				player:setStorageValue(AUTOHEAL_STORAGE_SAY, id)
				player:registerEvent('AutoHeal')
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal]\nThe second parameter must be a healing spell.\nType !autoheal help to see wich spells is disponible.")
				return false
			end
		else
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal]\nYour must use only values between 1~99%.")
			return false
		end
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Auto Heal]\nThe first parameter must be a number.")
		return false
	end
end
