local lastUpdate = "29/08/2019"

local MESSAGE_ERROR_NO_HEALTH_SPELLS = "You do not have any healing spells."
local MESSAGE_ERROR_NO_MANA_ITEMS = "Your vocation is not allowed to use mana recover items."
local MESSAGE_ERROR_NO_HEALTH_ITEMS = "Your vocation is not allowed to use health recover items."

local spellTable = {
	Knight = {
		["exura ico"] = {id = 3},
		["exura gran ico"] = {id = 7}
	},
	Paladin = {
		["exura"] = {id = 1},
		["exura san"] = {id = 4},
		["exura gran san"] = {id = 6},
	},
	Sorcerer = {
		["exura"] = {id = 1},
		["exura gran"] = {id = 2},	
		["exura vita"] = {id = 5},
	},	
	Druid = {
		["exura"] = {id = 1},
		["exura gran"] = {id = 2},	
		["exura vita"] = {id = 5},
		["exura gran mas res"] = {id = 8},
		["exura sio"] = {id = 9}
	}
}

local itemTable = {
	Health = {
		Knight = {
			[1] = {itemid = 7618, itemname = "health potion"},
			[2] = {itemid = 7588, itemname= "strong health potion"},
			[3] = {itemid = 7591, itemname= "great health potion"},
			[4] = {itemid = 8473, itemname= "ultimate health potion"},
			[5] = {itemid = 26031, itemname= "supreme health potion"},
		},
		Paladin = {
			[1] = {itemid = 7618, itemname = "health potion"},
			[2] = {itemid = 7588, itemname= "strong health potion"},
			[3] = {itemid = 8472, itemname= "great spirit potion"},
			[4] = {itemid = 26030, itemname= "ultimate spirit potion"}
		},
		Mage = {
			[1] = {itemid = 7618, itemname = "health potion"},
		},
		None = {
			[1] = {itemid = 7618, itemname = "health potion"},
		}
	},
	Mana = {
		Mage = {
			[1] = {itemid = 7620, itemname = "mana potion"},
			[2] = {itemid = 7589, itemname= "strong mana potion"},
			[3] = {itemid = 7590, itemname= "great mana potion"},
			[4] = {itemid = 26029, itemname= "ultimate mana potion"}
		},
		Paladin = {
			[1] = {itemid = 7620, itemname = "mana potion"},
			[2] = {itemid = 7590, itemname= "great mana potion"},
		},
		Knight = {
			[1] = {itemid = 7620, itemname = "mana potion"},
		},
		None = {
			[1] = {itemid = 7620, itemname = "mana potion"},
		}
	}
}

local options = {
	[1] = "Health",
	[2] = "Mana",
	[3] = "About"
}

local healthOptions = {
	[1] = "Spell List",
	[2] = "Item List"
}

local j = {}
local choiceCount

function onModalWindow(player, modalWindowId, buttonId, choiceId)
	local vNumber = player:getVocation():getId()
	local spellName = ""
	

	if modalWindowId == Modal.autoHealOptions and buttonId == 100 and choiceId == 1 then
		player:unregisterEvent("autoHeal_modal")
		local title = "Choose a method"
		local desc = "Choose the way that you want to be healed"
		local window = ModalWindow(Modal.autoHealHealthOptions, title, desc)
		for i = 1, #healthOptions do
			window:addChoice(i, healthOptions[i])
		end
		window:addButton(110, 'Next')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Back')
		window:setDefaultEscapeButton(111)
		window:sendToPlayer(player)
		return true
	elseif modalWindowId == Modal.autoHealHealthOptions and buttonId == 110 and choiceId == 1 then
		player:unregisterEvent("autoHeal_modal")
		local title = "Healing Spells"
		local desc = "Choose a spell to heal yourself"
		local window = ModalWindow(Modal.autoHealSpellList, title, desc)
		if isInArray({1, 5}, vNumber) then
			for w, spell in pairs(spellTable.Sorcerer) do
				window:addChoice(spell.id, w)
			end
		elseif isInArray({2, 6}, vNumber) then
			for w, spell in pairs(spellTable.Druid) do
				window:addChoice(spell.id, w)
			end
		elseif isInArray({3, 7}, vNumber) then
			for w, spell in pairs(spellTable.Knight) do
				window:addChoice(spell.id, w)
			end
		elseif isInArray({4, 8}, vNumber) then
			for w, spell in pairs(spellTable.Paladin) do
				window:addChoice(spell.id, w)
			end
		else
			player:sendCancelMessage('You don\'t have any healing spell.')
			return true
		end
		choiceCount = window:getChoiceCount()
		window:addButton(110, 'Next')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Back')
		window:setDefaultEscapeButton(111)
		window:sendToPlayer(player)
		return true
	elseif modalWindowId == Modal.autoHealSpellList and buttonId == 110 then
		if choiceCount < 1 then
			player:sendCancelMessage(MESSAGE_ERROR_NO_HEALTH_SPELLS)
			return true
		end
		player:sendCancelMessage("Type the amount of health.")
		player:registerEvent('autoHeal_textEdit')
		player:setStorageValue(AUTOHEAL_STORAGE_SAY, choiceId)
		local itemVirt = Game.createItem(1947, 1)
		itemVirt:setActionId(19000)
		player:showTextDialog(itemVirt, "" , true, 2)
		return true
	elseif modalWindowId == Modal.autoHealHealthOptions and buttonId == 110 and choiceId == 2 then
		player:unregisterEvent("autoHeal_modal")
		local title = "Healing Items"
		local desc = "Choose an item to heal yourself"
		local window = ModalWindow(Modal.autoHealItemList, title, desc)
		if isInArray({2, 6, 1, 5}, vNumber) then
			for i = 1, #itemTable.Health.Mage do
				window:addChoice(i, itemTable.Health.Mage[i].itemname)
				j[i] = itemTable.Health.Mage[i].itemid
			end
		elseif isInArray({3, 7}, vNumber) then
			for i = 1, #itemTable.Health.Knight do
				window:addChoice(i, itemTable.Health.Knight[i].itemname)
				j[i] = itemTable.Health.Knight[i].itemid
			end
		elseif isInArray({4, 8}, vNumber) then
			for i = 1, #itemTable.Health.Paladin do
				window:addChoice(i, itemTable.Health.Paladin[i].itemname)
				j[i] = itemTable.Health.Paladin[i].itemid
			end
		else
			for i = 1, #itemTable.Health.None do
				window:addChoice(i, itemTable.Health.None[i].itemname)
				j[i] = itemTable.Health.None[i].itemid
			end
		end
		choiceCount = window:getChoiceCount()
		window:addButton(110, 'Next')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Back')
		window:setDefaultEscapeButton(111)
		window:sendToPlayer(player)
		return true
	elseif modalWindowId == Modal.autoHealOptions and buttonId == 100 and choiceId == 2 then
		player:unregisterEvent("autoHeal_modal")
		local title = "Mana Recover"
		local desc = "Choose an item to recover your mana"
		local window = ModalWindow(Modal.autoHealManaItems, title, desc)
		if isInArray({2, 6, 1, 5}, vNumber) then
			for i = 1, #itemTable.Mana.Mage do
				window:addChoice(i, itemTable.Mana.Mage[i].itemname)
				j[i] = itemTable.Mana.Mage[i].itemid
			end
		elseif isInArray({3, 7}, vNumber) then
			for i = 1, #itemTable.Mana.Knight do
				window:addChoice(i, itemTable.Mana.Knight[i].itemname)
				j[i] = itemTable.Mana.Knight[i].itemid
			end
		elseif isInArray({4, 8}, vNumber) then
			for i = 1, #itemTable.Mana.Paladin do
				window:addChoice(i, itemTable.Mana.Paladin[i].itemname)
				j[i] = itemTable.Mana.Paladin[i].itemid
			end
		else
			for i = 1, #itemTable.Mana.None do
				window:addChoice(i, itemTable.Mana.None[i].itemname)
				j[i] = itemTable.Mana.Paladin[i].itemid
			end
		end
		choiceCount = window:getChoiceCount()
		window:addButton(110, 'Next')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Back')
		window:setDefaultEscapeButton(111)
		window:sendToPlayer(player)
		return true
	elseif modalWindowId == Modal.autoHealManaItems and buttonId == 110 then
		if choiceCount < 1 then
			player:sendCancelMessage(MESSAGE_ERROR_NO_MANA_ITEMS)
			return true
		end
		player:sendCancelMessage("Type the amount of mana.")
		player:registerEvent('autoHeal_textEdit')
		player:setStorageValue(AUTOHEAL_STORAGE_ITEM_MANA, j[choiceId])
		local itemVirt = Game.createItem(1947, 1)
		itemVirt:setActionId(19001)
		player:showTextDialog(itemVirt, "" , true, 2)
		return true
	elseif modalWindowId == Modal.autoHealOptions and buttonId == 100 and choiceId == 3 then
		player:unregisterEvent("autoHeal_modal")
		local title = "About"
		local desc = "System made by: worthdavi\nVersion: 0.1\nLast update: "..lastUpdate
		local window = ModalWindow(Modal.autoHealAbout, title, desc)
		window:addButton(110, 'Back')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Close')
		window:setDefaultEscapeButton(111)
		window:sendToPlayer(player)
		return true
	-- Coming back to healing methods
	elseif (modalWindowId == Modal.autoHealSpellList or modalWindowId == Modal.autoHealItemList) and buttonId == 111 then
		player:unregisterEvent("autoHeal_modal")
		local title = "Choose a method"
		local desc = "Choose the way that you want to be healed"
		local window = ModalWindow(Modal.autoHealHealthOptions, title, desc)
		for i = 1, #healthOptions do
			window:addChoice(i, healthOptions[i])
		end
		window:addButton(110, 'Next')
		window:setDefaultEnterButton(110)
		window:addButton(111, 'Back')
		window:setDefaultEscapeButton(111)
		window:sendToPlayer(player)
		return true
	-- Coming back to main menu
	elseif (modalWindowId == Modal.autoHealAbout and buttonId == 110) or (modalWindowId == Modal.autoHealHealthOptions and buttonId == 111)
	or (modalWindowId == Modal.autoHealManaItems and buttonId == 111) then
		player:registerEvent("ModalWindow_autoHeal")
		local title = "-- Auto Heal --"
		local message = "Choose an option below:"	
		local window = ModalWindow(Modal.autoHealOptions, title, message)	
		for i = 1, #options do
			window:addChoice(i, options[i])
		end	
		window:addButton(100, 'Next')
		window:setDefaultEnterButton(100)
		window:addButton(101, 'Close')
		window:setDefaultEscapeButton(101)		
		window:sendToPlayer(player)
		return true
	end
	return true
end