local races = {
	[1] = "venom",
	[2] = "blood",
	[3] = "undead",
	[4] = "fire",
	[5] = "energy",
}

local monsters = {"rat", "dragon", "dragon lord", "demon"}


local function loadLoot(itemBlock)
	local loottmp = {}
	loottmp.id = itemBlock.itemId
	loottmp.chance = itemBlock.chance * 10
	if itemBlock.subType then
		loottmp.subType = itemBlock.subType
	end
	if itemBlock.maxCount then
		loottmp.maxCount = itemBlock.maxCount
	end
	if itemBlock.aid then
		loottmp.aid = itemBlock.actionId
	end
	if itemBlock.text then
		loottmp.text = itemBlock.text
	end
	if itemBlock.unique then
		loottmp.unique = itemBlock.unique
	end

	if itemBlock.childLoot then
		--loottmp.child = loadLoot(itemBlock)
	end

	return loottmp

end


for _, monster in pairs(monsters) do
	print("ok")
	local mt = MonsterType(monster)
	if mt then
		local mType = Game.createMonsterType(mt:getName() .. " Champion")
		local newMonster = {}
		newMonster.name = mt:getName() .. " Champion"
		newMonster.description = mt:getName():lower() .. " champion"
		newMonster.experience = mt:getExperience() * 10
		newMonster.outfit = mt:getOutfit()

		newMonster.health = mt:getHealth() * 10
		newMonster.maxHealth = newMonster.health
		newMonster.race = races[mt:getRace()]
		newMonster.corpse = mt:getCorpseId()
		newMonster.speed = mt:baseSpeed()
		newMonster.maxSummons = mt:getMaxSummons()

		if newMonster.maxSummons > 0 then
			newMonster.summons = mt:getSummonList()
		end

		newMonster.changeTarget = {
			interval = mt:changeTargetSpeed(),
			chance = mt:getChangeTargetChance()
		}

		newMonster.flags = {
			summonable = mt:isSummonable(),
			attackable = mt:isAttackable(),
			rewardboss = mt:isRewardBoss(),
			hostile = mt:isHostile(),
			convinceable = mt:isConvinceable(),
			illusionable = mt:isIllusionable(),
			canPushItems = mt:canPushItems(),
			canPushCreatures = mt:canPushCreatures(),
			preyable = mt:isPreyable(),
			targetDistance = mt:targetDistance(),
			staticAttackChance = mt:staticAttackChance(),
			respawnType = mt:respawnType()
		}

		newMonster.voices = mt:getVoices()
		newMonster.attacks = mt:getAttackList()
		newMonster.defenses = mt:getDefenseList()
		--newMonster.elements = mt:getElementList()
		newMonster.immunityDamage = mt:combatImmunities()
		newMonster.immunityCondition = mt:conditionImmunities()

		local loot, lootTable = mt:getLoot(), {}
		for _, itemBlock in pairs(loot) do
			local loottmp = loadLoot(itemBlock)
			table.insert(lootTable, loottmp)
		end
		newMonster.loot = lootTable

		mType:register(newMonster)
	end
end
