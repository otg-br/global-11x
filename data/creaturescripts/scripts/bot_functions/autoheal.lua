--[[
AUTOHEAL_STORAGE_PERCENTAGE_HEALTH = 182730
AUTOHEAL_STORAGE_SAY = 182731
AUTOHEAL_STORAGE_ISHEALING = 182732
]]

local spellTable = {
	["exura"] = {id = 1},
	["exura gran"] = {id = 2},
	["exura ico"] = {id = 3},
	["exura san"] = {id = 4},
	["exura vita"] = {id = 5},
	["exura gran san"] = {id = 6},
	["exura gran ico"] = {id = 7},
	["exura gran mas res"] = {id = 8}
}

function onThink(creature, interval)
	local player = Player(creature)
	if not player then
		return true
	end

	local percentageHealth = player:getStorageValue(AUTOHEAL_STORAGE_PERCENTAGE_HEALTH)
	local spellHealth = player:getStorageValue(AUTOHEAL_STORAGE_SAY)
	if not (percentageHealth < 0 or spellHealth < 0) then
		local spell
		for w, k in pairs(spellTable) do
			if k.id == spellHealth then
				spell = w
			end
		end
		local health = (player:getHealth()*100)/player:getMaxHealth()		
		if health <= percentageHealth then
			player:castSpell(spell, TALKTYPE_SAY)
		end
	end

	local percentageMana = player:getStorageValue(AUTOHEAL_STORAGE_PERCENTAGE_MANA)
	local itemMana = player:getStorageValue(AUTOHEAL_STORAGE_ITEM_MANA)
	if not (percentageMana < 0 or itemMana < 0) then
		local mana = (player:getMana()*100)/player:getMaxMana()	
		if mana <= percentageMana then
			if player:getItemCount(itemMana) >= 1 then
				broadcastMessage('usa pocao')
			else
			--	player:sendCancelMessage("You do not have enough"..ItemType(itemMana):getName():lower().."s.")
			end
		end
	end
	
    return true
end