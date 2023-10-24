local hasFood = 172382
local itemId = 34914
local backpackId = 16007
local shieldId = 25545
local crownId = 24809

local messages = {
	deuFood = {
	"AI!!",
	"DEVOLVA MEUS ITENS!!!",
	"EU PRECISO DISSO!!",
	"PAREM DE ME ROUBAR!!"
	},
}

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not creature:isMonster() then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	if attacker and attacker:isPlayer() then
		if attacker:getLevel() >= 100 then
			if attacker:getStorageValue(hasFood) ~= 1 then
				creature:say(messages.deuFood[math.random(1, #messages.deuFood)], TALKTYPE_MONSTER_SAY)
				attacker:addItem(itemId, 1)
				attacker:addItem(backpackId, 1)
				local r1 = math.random(100)
				local r2 = math.random(100)
				if r1 <= 10 then
					attacker:addItem(shieldId, 1)
				end
				if r2 <= 10 then
					attacker:addItem(crownId, 1)
				end
				attacker:setStorageValue(hasFood, 1)
			end
		else
			creature:say("Que jogador fraco... Talvez level 100.", TALKTYPE_MONSTER_SAY)
		end
	end
	primaryDamage = 0
	secondaryDamage = 0
    return primaryDamage, primaryType, secondaryDamage, secondaryType
end