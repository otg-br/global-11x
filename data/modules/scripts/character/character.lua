Character = {}

Character.S_Packets = {
	Char = 0xDA,
}

Character.C_Pachets = {
	RequestInfo = 0xE5,
	UpdateTitle = 0x81,
}

Character.Info = {
	Default = 0x00,
	Stats = 0x01,
	CombatStats = 0x02,
	BattleResult_death = 0x03,
	BattleResult_kill = 0x04,
	Achievements = 0x05,
	ItemSummary = 0x06,
	OutfitMount = 0x07,
	StoreSummary = 0x08,
	Items =  0x09,
	Titles =  0x0B,
}

if not playerTitle then
	playerTitle = {}
end

function onRecvbyte(player, msg, byte)
	if not playerTitle[player:getId()] then
		playerTitle[player:getId()] = 0
	end
	if byte == Character.C_Pachets.RequestInfo then
		msg:getU32()
		local request = msg:getByte()
		if request == Character.Info.Default then
			player:sendBasicInfo()
		elseif request == Character.Info.Items then
			player:sendCharItems()
		elseif request == Character.Info.Stats then
			player:sendCharStats()
		elseif request == Character.Info.CombatStats then
			player:sendCombatState()
		elseif request == Character.Info.BattleResult_death or request == Character.Info.BattleResult_kill then
			player:sendBattleResult(request)
		elseif request == Character.Info.Achievements then
			player:sendAchievements()
		elseif request == Character.Info.ItemSummary then
			player:sendItemSummary()
		elseif request == Character.Info.OutfitMount then
			player:sendOutfitMount()
		elseif request == Character.Info.StoreSummary then
			player:sendStoreSummary()
		elseif request == Character.Info.Titles then
			player:sendTitles()
		end
	elseif byte == Character.C_Pachets.UpdateTitle then
		local t = msg:getByte()
		if t == 0x0e then
			local title = msg:getByte()
			playerTitle[player:getId()] = title
			player:sendTitles()
		end
	end
	return
end

--== Player function
function Player.sendBasicInfo(self)
	local msg = NetworkMessage()
	msg:addByte(Character.S_Packets.Char)
	msg:addByte(Character.Info.Default)
	msg:addByte(0x0)
	msg:addString(self:getName())
	msg:addString(self:getVocation():getName())
	msg:addU16(self:getLevel())
	local outfit = self:getOutfit()
	msg:addU16(outfit.lookType > 0 and outfit.lookType or 128)
	msg:addByte(outfit.lookHead)
	msg:addByte(outfit.lookBody)
	msg:addByte(outfit.lookLegs)
	msg:addByte(outfit.lookFeet)
	msg:addByte(outfit.lookAddons)
	msg:addByte(0x0)
	msg:addByte(0x1)
	msg:addU16(0x0)
	msg:sendToPlayer(self)
	return true
end

local function MakeString(item)
	local infoTab = {}
	local it = ItemType(item:getId())
	if it:getArmor() > 0 then
		table.insert(infoTab, {"Armor", tostring(it:getArmor())})
	end

	if it:getAttack() > 0 then
		table.insert(infoTab, {"Attack", tostring(it:getAttack())})
	end

	if it:getDefense() > 0 then
		local str = tostring(it:getDefense())
		if it:getExtraDefense() ~= 0 then
			str = str .. " ".. it:getExtraDefense()
		end
		table.insert(infoTab, {"Defense", str})
	end

	if #it:getSkillString() > 0 then
		table.insert(infoTab, {"Skills", it:getSkillString()})
	end

	if it:getImbuingSlots() > 0 then
		for slot = 0, it:getImbuingSlots() - 1 do
			local duration = item:getImbuementDuration(slot)
			if duration > 0 then
				local imbue = item:getImbuement(slot)
				table.insert(infoTab, {"Imbuement Slot ".. slot+1, string.format("%s %s", imbue:getBase().name, imbue:getName())})
			else
				table.insert(infoTab, {"Imbuement Slot ".. slot+1, "Empty"})
			end
		end
	end

	

	return infoTab
end


function Player.sendCharItems(self)
	local msg = NetworkMessage()

	msg:addByte(0xda)
	msg:addByte(0x09)
	msg:addByte(0x00)
	local count = 0
	for i = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
		local item = self:getSlotItem(i)
		if item then
			count = count + 1
		end
	end
	msg:addByte(count) -- count

	if count > 0 then
		for i = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
			local item = self:getSlotItem(i)
			if item then
				msg:addByte(i)
				msg:addString(item:getName())
				msg:addItem(item, self)
				local it = ItemType(item:getId())
				msg:addByte(it:getImbuingSlots())
				if it:getImbuingSlots() > 0 then
					for slot = 0, it:getImbuingSlots() - 1 do
						local duration = item:getImbuementDuration(slot)
						if duration > 0 then
							local imbue = item:getImbuement(slot)
							msg:addU16(imbue:getId())
						else
							msg:addU16(0x00)
						end
					end
				end
				local desc = MakeString(item)
				msg:addByte(#desc)
				if #desc > 0 then
					for y = 1, #desc do
						local info = desc[y]
						msg:addString(info[1])
						msg:addString(info[2])
					end
				end
			end
		end
	end


	msg:addString(self:getName())
	local outfit = self:getOutfit()
	msg:addU16(outfit.lookType > 0 and outfit.lookType or 128)
	msg:addByte(outfit.lookHead)
	msg:addByte(outfit.lookBody)
	msg:addByte(outfit.lookLegs)
	msg:addByte(outfit.lookFeet)
	msg:addByte(outfit.lookAddons)

	msg:addByte(0x3)
	msg:addString("Level")
	msg:addString(self:getLevel())
	msg:addString("Vocation")
	msg:addString(self:getVocation():getName())
	msg:addString("Outfit")
	local GameOutfits = Game.getOutfits(self:getSex())
	local outname = "None"
	for _, out in pairs(GameOutfits) do
		if out.lookType == outfit.lookType then
			outname = out.name
			break
		end
	end
	msg:addString(outname)

	msg:sendToPlayer(self)
end

function Player.sendCharStats(self)
	local msg = NetworkMessage()
	msg:addByte(0xda)
	msg:addByte(0x01)
	msg:addByte(0x00)

	msg:addU64(self:getExperience())
	msg:addU16(self:getLevel())
	msg:addByte(0x00)

	msg:addU16(self:getBaseXpGain())
	msg:addU32(0x00)
	msg:addU16(self:getStoreXpBoost())
	msg:addU16(0x00)
	msg:addU16(self:getStaminaXpBoost()) -- xp rate

	msg:addU16(0x00)
	msg:addByte(0x01)

	msg:addU16(self:getHealth())
	msg:addU16(self:getMaxHealth())

	msg:addU16(self:getMana())
	msg:addU16(self:getMaxMana())

	msg:addByte(self:getSoul())

	msg:addU16(self:getStamina())

	local condition = self:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
	msg:addU16(condition and condition:getTicks()/1000 or 0x00)

	msg:addU16(self:getOfflineTrainingTime() / 60 / 1000)
	msg:addU16(self:getBaseSpeed()/2)
	msg:addU16(self:getBaseSpeed()/2)

	msg:addU32(self:getCapacity())
	msg:addU32(self:getCapacity())

	msg:addU32(18570)

	msg:addByte(0x08)

	msg:addByte(0x01)
	msg:addU16(self:getMagicLevel())
	msg:addU16(self:getBaseMagicLevel())
	msg:addU16(self:getBaseMagicLevel())
	msg:addU16(self:getManaSpent() * 100)

	msg:addByte(0x11)
	msg:addU16(self:getEffectiveSkillLevel(SKILL_FIST))
	msg:addU16(self:getSkillLevel(SKILL_FIST))
	msg:addU16(self:getSkillLevel(SKILL_FIST))
	msg:addU16(self:getSkillPercent(SKILL_FIST) * 100)

	msg:addByte(0x9)
	msg:addU16(self:getEffectiveSkillLevel(SKILL_CLUB))
	msg:addU16(self:getSkillLevel(SKILL_CLUB))
	msg:addU16(self:getSkillLevel(SKILL_CLUB))
	msg:addU16(self:getSkillPercent(SKILL_CLUB) * 100)

	msg:addByte(0x08)
	msg:addU16(self:getEffectiveSkillLevel(SKILL_SWORD))
	msg:addU16(self:getSkillLevel(SKILL_SWORD))
	msg:addU16(self:getSkillLevel(SKILL_SWORD))
	msg:addU16(self:getSkillPercent(SKILL_SWORD) * 100)

	msg:addByte(10)
	msg:addU16(self:getEffectiveSkillLevel(SKILL_AXE))
	msg:addU16(self:getSkillLevel(SKILL_AXE))
	msg:addU16(self:getSkillLevel(SKILL_AXE))
	msg:addU16(self:getSkillPercent(SKILL_AXE) * 100)

	msg:addByte(0x7)
	msg:addU16(self:getEffectiveSkillLevel(SKILL_DISTANCE))
	msg:addU16(self:getSkillLevel(SKILL_DISTANCE))
	msg:addU16(self:getSkillLevel(SKILL_DISTANCE))
	msg:addU16(self:getSkillPercent(SKILL_DISTANCE) * 100)

	msg:addByte(0x6)
	msg:addU16(self:getEffectiveSkillLevel(SKILL_SHIELD))
	msg:addU16(self:getSkillLevel(SKILL_SHIELD))
	msg:addU16(self:getSkillLevel(SKILL_SHIELD))
	msg:addU16(self:getSkillPercent(SKILL_SHIELD) * 100)

	msg:addByte(13)
	msg:addU16(self:getEffectiveSkillLevel(SKILL_FISHING))
	msg:addU16(self:getSkillLevel(SKILL_FISHING))
	msg:addU16(self:getSkillLevel(SKILL_FISHING))
	msg:addU16(self:getSkillPercent(SKILL_FISHING) * 100)


	msg:sendToPlayer(self)
end

function Player.sendCombatState(self)
	local msg = NetworkMessage()
	msg:addByte(0xda)
	msg:addByte(Character.Info.CombatStats)
	msg:addByte(0x00)

	msg:addU16(self:getEffectiveSkillLevel(SKILL_CRITICAL_HIT_CHANCE))
	msg:addU16(self:getSkillLevel(SKILL_CRITICAL_HIT_CHANCE))

	msg:addU16(self:getEffectiveSkillLevel(SKILL_CRITICAL_HIT_DAMAGE))
	msg:addU16(self:getSkillLevel(SKILL_CRITICAL_HIT_DAMAGE))

	msg:addU16(self:getEffectiveSkillLevel(SKILL_LIFE_LEECH_CHANCE))
	msg:addU16(self:getSkillLevel(SKILL_LIFE_LEECH_CHANCE))

	msg:addU16(self:getEffectiveSkillLevel(SKILL_LIFE_LEECH_AMOUNT))
	msg:addU16(self:getSkillLevel(SKILL_LIFE_LEECH_AMOUNT))

	msg:addU16(self:getEffectiveSkillLevel(SKILL_MANA_LEECH_CHANCE))
	msg:addU16(self:getSkillLevel(SKILL_MANA_LEECH_CHANCE))

	msg:addU16(self:getEffectiveSkillLevel(SKILL_MANA_LEECH_AMOUNT))
	msg:addU16(self:getSkillLevel(SKILL_MANA_LEECH_AMOUNT))

	local c, bless = 1, 0
	while (c < 8) do
		if (self:hasBlessing(c)) then
			bless = bless + 1
		end
		c = c + 1

	end

	msg:addByte(bless)
	msg:addByte(0x7)

	local weapon = self:getWeapon()

	if weapon then
		local it = ItemType(weapon:getId())
		msg:addU16(it:getAttack())
		msg:addByte(it:getElementType())
	else
		msg:addU16(1)
		msg:addU16(0)
	end

	msg:addByte(2) -- percent
	msg:addByte(1) -- convert type

	msg:addU16(self:getArmor()) -- armor
	msg:addU16(self:getDefense()) -- defense
	msg:addByte(0x03) -- looping

	msg:addByte(0) -- convert type
	msg:addByte(0) -- percent
	msg:addByte(1) -- convert type
	msg:addByte(0) -- percent
	msg:addByte(2) -- convert type
	msg:addByte(0) -- percent

	msg:sendToPlayer(self)
	-- body
end

function Player.sendBattleResult(self, request)
	local msg = NetworkMessage()
	msg:addByte(0xda)
	msg:addByte(request)
	msg:addByte(0x00)
	msg:addU16(0x01)
	msg:addU16(0x01)
	msg:addU16(0x00)
	msg:sendToPlayer(self)
end

function Player.sendAchievements(self)
	local msg = NetworkMessage()
	msg:addByte(0xda)
	msg:addByte(Character.Info.Achievements)
	msg:addByte(0x00) -- regular
	msg:addU16(0x00) -- secrets
	msg:addU16(186) -- secrets Achievements
	msg:addU16(0x0)
	msg:sendToPlayer(self)
end


local function getTotalItemContainer(container, items, count)
	if container and container:getSize() > 0 then
		for i = container:getSize(), 0, -1 do
			local item = container:getItem(i)
			if item then
				if not items[item:getId()] then
					items[item:getId()] = item:getCount()
					count = count + 1
				else
					items[item:getId()] = items[item:getId()] + item:getCount()
				end
				if item:isContainer() then
					local container = Container(item:getUniqueId())
					items, count = getTotalItemContainer(container, items, count)
				end
			end
		end
	end

	return items, count
end

local function getTotalItens(playerid, ltype)
	local player = Player(playerid)
	if not player then return {}, 0 end

	local items = {}
	local count = 0
	if ltype == 0 then
		for i = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
			local item = player:getSlotItem(i)
			if item then
				if not items[item:getId()] then
					items[item:getId()] = item:getCount()
					count = count + 1
				else
					items[item:getId()] = items[item:getId()] + item:getCount()
				end
				if item:isContainer() then
					local container = Container(item:getUniqueId())
					items, count = getTotalItemContainer(container, items, count)
				end
			end
		end
	elseif ltype == 1 then -- store
		local item = player:getSlotItem(CONST_SLOT_STORE_INBOX)
		if item and item:isContainer() then
			local container = Container(item:getUniqueId())
			items, count = getTotalItemContainer(container, items, count)
		end
	elseif ltype == 3 then -- store
		for id = 1, configManager.getNumber("depotBoxes") do
			local item = player:getDepotChest(id, true)
			if item and item:isContainer() then
				items, count = getTotalItemContainer(item, items, count)
			end				
		end
	elseif ltype == 4 then -- store
		local item = player:getInbox()
		if item and item:isContainer() then
			items, count = getTotalItemContainer(item, items, count)
		end
	end

	return items, count
end

function Player.sendItemSummary(self)
	local msg = NetworkMessage()
	msg:addByte(0xda)
	msg:addByte(Character.Info.ItemSummary)
	msg:addByte(0x0)

	for i = 0, 4 do
		local items, count = getTotalItens(self:getId(), i)
		msg:addU16(count)
		if count > 0 then
			for id, amount in pairs(items) do
				msg:addItemId(id)
				msg:addU32(amount)
			end
		end

	end

	msg:sendToPlayer(self)
end

function Player.sendOutfitMount(self)
	local msg = NetworkMessage()
	msg:addByte(0xda)
	msg:addByte(Character.Info.OutfitMount)
	msg:addByte(0x00)
	local outfit, ocount = self:getOutfit(), 0
	local sex = self:getSex()
	local GameOutfits = Game.getOutfits(sex)
	for _, out in pairs(GameOutfits) do
		if self:hasOutfit(out.lookType) then
			ocount = ocount + 1
		end
	end

	msg:addU16(ocount) -- count
	if ocount > 0 then
		for _, out in pairs(GameOutfits) do
			if self:hasOutfit(out.lookType) then
				msg:addU16(out.lookType)
				msg:addString(out.name)
				local addon = 0
				if self:hasOutfit(out.lookType, 3) then
					addon = 3
				elseif self:hasOutfit(out.lookType, 2) then
					addon = 2
				elseif self:hasOutfit(out.lookType, 1) then
					addon = 1
				end
				msg:addByte(addon) -- addons
				msg:addByte(0x00)
				msg:addU32(0x00)
			end
		end
	end

	msg:addByte(outfit.lookHead)
	msg:addByte(outfit.lookBody)
	msg:addByte(outfit.lookLegs)
	msg:addByte(outfit.lookFeet)


	local GameMount, ocount = Game.getMounts(sex), 0
	for _, mount in pairs(GameMount) do
		if self:hasMount(mount.id) then
			ocount = ocount + 1
		end
	end
	msg:addU16(ocount) -- mount
	if ocount > 0 then
		for _, mount in pairs(GameMount) do
			if self:hasMount(mount.id) then
				msg:addU16(mount.clientId)
				msg:addString(mount.name)
				msg:addByte(0x00)
				msg:addU32(0x00)
			end
		end
	end

	msg:sendToPlayer(self)
end

function Player.sendStoreSummary(self)
	local msg = NetworkMessage()
	msg:addByte(0xda)
	msg:addByte(Character.Info.StoreSummary)
	msg:addByte(0x00)

	msg:addU32(0x00)
	msg:addU32(0x00)

	msg:addByte(0x8)
	msg:addString("Blood of the Mountain")
	msg:addByte(0x00)
	msg:addString("Heart of the Mountain")
	msg:addByte(0x00)
	msg:addString("Spark of the Phoenix")
	msg:addByte(0x00)
	msg:addString("Embrace of Tibia")
	msg:addByte(0x00)
	msg:addString("Spiritual Shielding")
	msg:addByte(0x00)
	msg:addString("Fire of the Suns")
	msg:addByte(0x00)
	msg:addString("Wisdom of Solitude")
	msg:addByte(0x00)
	msg:addString("Twist of Fate")
	msg:addByte(0x00)

	msg:addByte(0x00)
	msg:addByte(0x00)
	msg:addByte(0x00)
	msg:addByte(0x00)
	msg:addByte(0x00)
	msg:addByte(0x00)
	msg:addByte(0x00)
	msg:addU16(0x0)


	msg:sendToPlayer(self)
end

function Player.sendTitles(self)
	local msg = NetworkMessage()
msg:addByte(0xda)
msg:addByte(0xb)
msg:addByte(0x00)
msg:addByte(playerTitle[self:getId()] or 0) -- atual titulo

msg:addByte(0x3e) -- 62

msg:addByte(0x3e)
msg:addString("Feared Bountyhunter")
msg:addString("Invested 655.000 task points.")
msg:addByte(0x1)
msg:addByte(0x00)

msg:addByte(0x3d)
msg:addString("Competent Beastslayer")
msg:addString("Invested 500.000 task points.")
msg:addByte(0x1)
msg:addByte(0x00)

msg:addByte(0x3c)
msg:addString("Aspiring Huntsman")
msg:addString("Invested 250.000 task points.")
msg:addByte(0x01)
msg:addByte(0x00)

msg:addByte(0x3b)
msg:addString("Creature of Habit (Grade 5)")
msg:addString("Reward streak of at least 365 days of consecutive daily logins.")
msg:addByte(0x01)
msg:addByte(0x00)

msg:addByte(0x3a)
msg:addString("Creature of Habit (Grade 4)")
msg:addString("Reward streak of at least 180 days of consecutive daily logins.")
msg:addByte(0x01)
msg:addByte(0x00)

msg:addByte(0x39)
msg:addString("Creature of Habit (Grade 3)")
msg:addString("Reward streak of at least 90 days of consecutive daily logins.")
msg:addByte(0x01)
msg:addByte(0x00)

msg:addByte(0x38)
msg:addString("Creature of Habit (Grade 2)")
msg:addString("Reward streak of at least 30 days of consecutive daily logins.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x37)
msg:addString("Creature of Habit (Grade 1)")
msg:addString("Reward streak of at least 7 days of consecutive daily logins.")
msg:addByte(0x01)
msg:addByte(0x00)

msg:addByte(0x36)
msg:addString("Executioner")
msg:addString("Unlocked all Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)

msg:addByte(0x35)
msg:addString("Legend of Marksmanship")
msg:addString("Highest distance fighting level on character's world.")
msg:addByte(0x00)
msg:addByte(0x00)

msg:addByte(0x34)
msg:addString("Legend of Magic")
msg:addString("Highest magic level on character's world.")
msg:addByte(0x00)
msg:addByte(0x00)

msg:addByte(0x33)
msg:addString("Legend of Fishing")
msg:addString("Highest fishing level on character's world.")
msg:addByte(0x00)
msg:addByte(0x00)

msg:addByte(0x32)
msg:addString("Legend of the Shield")
msg:addString("Highest shielding level on character's world.")
msg:addByte(0x00)
msg:addByte(0x00)

msg:addByte(0x31)
msg:addString("Legend of the Fist")
msg:addString("Highest fist fighting level on character's world.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x30)
msg:addString("Legend of the Club")
msg:addString("Highest club fighting level on character's world.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x2f)
msg:addString("Legend of the Axe")
msg:addString("Highest axe fighting level on character's world.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x16)
msg:addString("Globetrotter")
msg:addString("Explored all map areas.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x15)
msg:addString("Dedicated Entrepreneur")
msg:addString("Explored 50% of all map areas.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x14)
msg:addString("Interdimensional Destroyer")
msg:addString("Unlocked all \"Extra Dimensional\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x13)
msg:addString("Exterminator")
msg:addString("Unlocked all \"Vermin\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x12)
msg:addString("Ghosthunter")
msg:addString("Unlocked all \"Undead\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x11)
msg:addString("Ooze Blues")
msg:addString("Unlocked all \"Slime\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x10)
msg:addString("Snake Charmer")
msg:addString("Unlocked all \"Reptile\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0xf)
msg:addString("Weedkiller")
msg:addString("Unlocked all \"Plant\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0xe)
msg:addString("Huntsman")
msg:addString("Unlocked all \"Mammal\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0xd)
msg:addString("Master of Illusion")
msg:addString("Unlocked all \"Magical\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0xc)
msg:addString("Blood Moon Hunter")
msg:addString("Unlocked all \"Lycanthrope\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0xb)
msg:addString("Bipedantic")
msg:addString("Unlocked all \"Humanoid\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x01)
msg:addString("Coldblooded")
msg:addString("Unlocked all \"Amphibic\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x2)
msg:addString("Sea Bane")
msg:addString("Unlocked all \"Aquatic\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x3)
msg:addString("Death from Below")
msg:addString("Unlocked all \"Bird\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x4)
msg:addString("Handyman")
msg:addString("Unlocked all \"Construct\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x5)
msg:addString("Demonator")
msg:addString("Unlocked all \"Demon\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x6)
msg:addString("Dragonslayer")
msg:addString("Unlocked all \"Dragon\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x7)
msg:addString("Elementalist")
msg:addString("Unlocked all \"Elemental\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x8)
msg:addString("Fey Swatter")
msg:addString("Unlocked all \"Fey\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x9)
msg:addString("Tumbler")
msg:addString("Unlocked all \"Giant\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0xa)
msg:addString("Manhunter")
msg:addString("Unlocked all \"Human\" Bestiary entries.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x17)
msg:addString("Guild Leader")
msg:addString("Leading a guild.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x18)
msg:addString("Tibia's Topmodel (Grade 1)")
msg:addString("Unlocked 10 or more outfits.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x19)
msg:addString("Tibia's Topmodel (Grade 2)")
msg:addString("Unlocked 20 or more outfits.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x1a)
msg:addString("Tibia's Topmodel (Grade 3)")
msg:addString("Unlocked 30 or more outfits.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x1b)
msg:addString("Tibia's Topmodel (Grade 4)")
msg:addString("Unlocked 40 or more outfits.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x1c)
msg:addString("Tibia's Topmodel (Grade 5)")
msg:addString("Unlocked 50 or more outfits.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x1d)
msg:addString("Beastrider (Grade 1)")
msg:addString("Unlocked 10 or more mounts.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x1e)
msg:addString("Beastrider (Grade 2)")
msg:addString("Unlocked 20 or more mounts.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x1f)
msg:addString("Beastrider (Grade 3)")
msg:addString("Unlocked 30 or more mounts.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x20)
msg:addString("Beastrider (Grade 4)")
msg:addString("Unlocked 40 or more mounts.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x21)
msg:addString("Beastrider (Grade 5)")
msg:addString("Unlocked 50 or more mounts.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x22)
msg:addString("Gold Hoarder")
msg:addString("Earned at least 1,000,000 gold.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x23)
msg:addString("Platinum Hoarder")
msg:addString("Earned at least 10,000,000 gold.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x24)
msg:addString("Crystal Hoarder")
msg:addString("Earned at least 100,000,000 gold.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x25)
msg:addString("Big Spender")
msg:addString("Unlocked the full Golden Outfit.")
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x26)
msg:addString("Trolltrasher")
msg:addString("Reached level 50.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x27)
msg:addString("Cyclopscamper")
msg:addString("Reached level 100.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x28)
msg:addString("Dragondouser")
msg:addString("Reached level 200.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x29)
msg:addString("Demondoom")
msg:addString("Reached level 300.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x2a)
msg:addString("Drakenbane")
msg:addString("Reached level 400.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x2b)
msg:addString("Silencer")
msg:addString("Reached level 500.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x2c)
msg:addString("Exalted")
msg:addString("Reached level 1000.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x2d)
msg:addString("Apex Predator")
msg:addString("Highest level on character's world.")
msg:addByte(0x00)
msg:addByte(0x00)
msg:addByte(0x2e)
msg:addString("Legend of the Sword")
msg:addString("Highest sword fighting level on character's world.")
msg:addByte(0x00)
msg:addByte(0x00)
	msg:sendToPlayer(self)
end
