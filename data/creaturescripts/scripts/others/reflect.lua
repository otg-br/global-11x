local monsters = {
	-- Carnivors
	["menacing carnivor"] = {type = COMBAT_PHYSICALDAMAGE, value = 0.5}, -- nome em minúsculo, tipo de dano, valor refletido em %
	["spiky carnivor"] = {type = COMBAT_PHYSICALDAMAGE, value = 0.5},

	-- Spectros
	["burster spectre"] = {type = COMBAT_ICEDAMAGE, value = 1.33},
	["faceless bane"] = {type = COMBAT_DEATHDAMAGE, value = 2}, 
	["gazer spectre"] = {type = COMBAT_FIREDAMAGE, value = 1.33}, 
	["ripper spectre"] = {type = COMBAT_EARTHDAMAGE, value = 1.33}, 
	
	["burning gladiator"] = {type = COMBAT_FIREDAMAGE, value = 0.33},

	-- Elfos
	["crazed summer rearguard"] = {type = COMBAT_FIREDAMAGE, value = 0.7},
	["crazed summer vanguard"] = {type = COMBAT_FIREDAMAGE, value = 0.7},
	["insane siren"] = {type = COMBAT_FIREDAMAGE, value = 0.7},
	["soul-broken harbinger"] = {type = COMBAT_ICEDAMAGE, value = 0.7},
	["crazed winter rearguard"] = {type = COMBAT_ICEDAMAGE, value = 0.7},
	["crazed winter vanguard"] = {type = COMBAT_ICEDAMAGE, value = 0.7},
}

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	local monster = monsters[creature:getName():lower()]
	if not monster or not attacker then 
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	if creature and (attacker:isPlayer() or attacker:getMaster()) then
		if primaryType == monster.type then
			local newDamage = primaryDamage + (primaryDamage*monster.value)
			doTargetCombat(0, attacker, primaryType, - newDamage, - newDamage, secondaryType, ORIGIN_NONE)
		end
	end
    return primaryDamage, primaryType, secondaryDamage, secondaryType
end
