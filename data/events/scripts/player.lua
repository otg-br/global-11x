-- Internal Use
STONE_SKIN_AMULET = 2197
GOLD_POUNCH = 26377
ITEM_STORE_INBOX = 26052
CONTAINER_WEIGHT = 100000 -- 10k = 10000 oz | this function is only for containers, item below the weight determined here can be moved inside the container, for others items look game.cpp at the src
-- exercise_ids
local exercise_ids = {32384,32385,32386,32387,32388,32389}
local dummies = {32147,32148,32143,32144,32145,32146}

-- No move items with actionID 8000
NOT_MOVEABLE_ACTION = 8000

-- Capacity imbuement store
local STORAGE_CAPACITY_IMBUEMENT = 42154

-- Players cannot throw items on teleports if set to true
local blockTeleportTrashing = true

local titles = {
	{storageID = 14960, title = " Scout"},
	{storageID = 14961, title = " Sentinel"},
	{storageID = 14962, title = " Steward"},
	{storageID = 14963, title = " Warden"},
	{storageID = 14964, title = " Squire"},
	{storageID = 14965, title = " Warrior"},
	{storageID = 14966, title = " Keeper"},
	{storageID = 14967, title = " Guardian"},
	{storageID = 14968, title = " Sage"},
	{storageID = 14969, title = " Tutor"},
	{storageID = 14970, title = " Senior Tutor"},
	{storageID = 14971, title = " King"},
}

local function getTitle(uid)
	local player = Player(uid)
	if not player then return false end

	for i = #titles, 1, -1 do
		if player:getStorageValue(titles[i].storageID) == 1 then
			return titles[i].title
		end
	end

	return false
end

function Player:onBrowseField(position)
	return true
end

local function getHours(seconds)
	return math.floor((seconds/60)/60)
end

local function getMinutes(seconds)
	return math.floor(seconds/60)
end

local function getSeconds(seconds)
	return seconds%60
end

local function getTime(seconds)
	local hours, minutes = getHours(seconds), getMinutes(seconds)
	if (minutes > 59) then
		minutes = minutes-hours*60
	end

	if (minutes < 10) then
		minutes = "0" ..minutes
	end

	return hours..":"..minutes.. "h"
end

local function getTimeinWords(secs)
	local hours, minutes, seconds = getHours(secs), getMinutes(secs), getSeconds(secs)
	if (minutes > 59) then
		minutes = minutes-hours*60
	end

	local timeStr = ''

	if hours > 0 then
		timeStr = timeStr .. ' hours '
	end

	timeStr = timeStr .. minutes .. ' minutes and '.. seconds .. 'seconds.'

	return timeStr
end

function Player:onLook(thing, position, distance)
	local description = "You see "
	if thing:isItem() then
		if thing.actionid == 5640 then
			description = description .. "a honeyflower patch."
		elseif thing.actionid == 5641 then
			description = description .. "a banana palm."
		elseif thing.itemid >= ITEM_HEALTH_CASK_START and thing.itemid <= ITEM_HEALTH_CASK_END
		or thing.itemid >= ITEM_MANA_CASK_START and thing.itemid <= ITEM_MANA_CASK_END
		or thing.itemid >= ITEM_SPIRIT_CASK_START and thing.itemid <= ITEM_SPIRIT_CASK_END
		or thing.itemid >= ITEM_KEG_START and thing.itemid <= ITEM_KEG_END then
			description = description .. thing:getDescription(distance)
			local charges = thing:getAttribute(ITEM_ATTRIBUTE_DATE)
			if charges then
			description = string.format("%s\nIt has %d refillings left.", description, charges)
			end
		else
			description = description .. thing:getDescription(distance)
		end
	else
		description = description .. thing:getDescription(distance)
		if thing:isMonster() then
			local master = thing:getMaster()
			if master and table.contains({'thundergiant','grovebeast','emberwing','skullfrost'}, thing:getName():lower()) then
				description = description..' (Master: ' .. master:getName() .. '). It will disappear in ' .. getTimeinWords((thing:getRemoveTime()/1000))
			end
		end
	end

	if self:getGroup():getId() >= 5 then
		if thing:isItem() then
			local itemType = thing:getType()
			description = string.format("%s\nItem ID: %d (%d)", description, thing:getId(), itemType:getClientId())

			local actionId = thing:getActionId()
			if actionId ~= 0 then
				description = string.format("%s, Action ID: %d", description, actionId)
			end

			local uniqueId = thing:getAttribute(ITEM_ATTRIBUTE_UNIQUEID)
			if uniqueId > 0 and uniqueId < 65536 then
				description = string.format("%s, Unique ID: %d", description, uniqueId)
			end

			local transformEquipId = itemType:getTransformEquipId()
			local transformDeEquipId = itemType:getTransformDeEquipId()
			if transformEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onEquip)", description, transformEquipId)
			elseif transformDeEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onDeEquip)", description, transformDeEquipId)
			end

			local decayId = itemType:getDecayId()
			if decayId ~= -1 then
				description = string.format("%s\nDecays to: %d", description, decayId)
			end
		elseif thing:isCreature() then
			if thing:isMonster() and self:getGroup():getId() >= 6 then
				description = string.format("%s Race ID: %d", description, thing:getRaceId())
			end
			local str = "%s\nHealth: %d / %d"
			if thing:isPlayer() and thing:getMaxMana() > 0 then
				str = string.format("%s, Mana: %d / %d", str, thing:getMana(), thing:getMaxMana())
			end
			description = string.format(str, description, thing:getHealth(), thing:getMaxHealth()) .. "."
		end

		local position = thing:getPosition()
		description = string.format(
			"%s\nPosition: %d, %d, %d",
			description, position.x, position.y, position.z
		)

		if thing:isCreature() then
			if thing:isPlayer() then
				description = string.format("%s\nIP: %s.", description, Game.convertIpToString(thing:getIp()))
				description = string.format("%s\nClient: %.2f OS: %d", description, thing:getClient().version/100, thing:getClient().os)
			end
		end
	end
	-- local strKills = "%s\n[Kills: %d]\n[Deaths: %d]"
	-- if thing:isPlayer() then
		-- description = string.format(strKills, description, math.max(thing:getStorageValue(STORAGE_KILL_COUNT), 0), math.max(thing:getStorageValue(STORAGE_DEATH_COUNT), 0))
	-- end
	-- if thing:isPlayer() and thing:getClient().version <= 1100 then
	-- 	description = string.format("%s\nUsing Client 10: *possible bot!*", description)
	-- end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInBattleList(creature, distance)
	local description = "You see " .. creature:getDescription(distance)
	if creature:isMonster() then
		local master = creature:getMaster()
		if master and table.contains({'thundergiant','grovebeast','emberwing','skullfrost'}, creature:getName():lower()) then
			description = description..' (Master: ' .. master:getName() .. '). It will disappear in ' .. getTimeinWords((creature:getRemoveTime()/1000))
		end
	end
	if self:getGroup():getId() >= 5 then
		if creature:isMonster() and self:getGroup():getId() >= 6 then
			description = string.format("%s Race ID: %d", description, creature:getRaceId())
		end
		local str = "%s\nHealth: %d / %d"
		if creature:isPlayer() and creature:getMaxMana() > 0 then
			str = string.format("%s, Mana: %d / %d", str, creature:getMana(), creature:getMaxMana())
		end
		description = string.format(str, description, creature:getHealth(), creature:getMaxHealth()) .. "."

		local position = creature:getPosition()
		description = string.format(
			"%s\nPosition: %d, %d, %d",
			description, position.x, position.y, position.z
		)

		if creature:isPlayer() then
			description = string.format("%s\nIP: %s", description, Game.convertIpToString(creature:getIp()))
			description = string.format("%s\nClient: %d OS: %d", description, creature:getClient().version/100, creature:getClient().os)
		end
	end

	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInTrade(partner, item, distance)
	self:sendTextMessage(MESSAGE_INFO_DESCR, "You see " .. item:getDescription(distance))
end

function Player:onLookInShop(itemType, count)
	return true
end

local config = {
	maxItemsPerSeconds = 1,
	exhaustTime = 2000,
}

if not pushDelay then
	pushDelay = { }
end

local function antiPush(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if toPosition.x == CONTAINER_POSITION then
		return true
	end

	local tile = Tile(toPosition)
	if not tile then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return false
	end

	local cid = self:getId()
	if not pushDelay[cid] then
		pushDelay[cid] = {items = 0, time = 0}
	end

	pushDelay[cid].items = pushDelay[cid].items + 1

	local currentTime = os.mtime()
	if pushDelay[cid].time == 0 then
		pushDelay[cid].time = currentTime
	elseif pushDelay[cid].time == currentTime then
		pushDelay[cid].items = pushDelay[cid].items + 1
	elseif currentTime > pushDelay[cid].time then
		pushDelay[cid].time = 0
		pushDelay[cid].items = 0
	end

	if pushDelay[cid].items > config.maxItemsPerSeconds then
		pushDelay[cid].time = currentTime + config.exhaustTime
	end

	if pushDelay[cid].time > currentTime then
		self:sendCancelMessage("You can't move that item so fast.")
		return false
	end

	return true
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
  -- Exercise Weapons
    if isInArray(exercise_ids,item.itemid) then
        self:sendCancelMessage('You cannot move this item outside this container.')
        return false
    end

    if isInArray(dummies, item.itemid) then
    	if not toPosition:getTile():getHouse() then
    		 self:sendCancelMessage('You cannot move this item outside the house.')
    		 return false
    	end
    end

 	-- No move if item count > 20 items
	local tile = Tile(toPosition)
	if tile and tile:getItemCount() > 20 then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return false
	end
	
	-- Moving bath tube
	local bathTube = {29312, 29313}
	if isInArray(bathTube, item.itemid) then
		if Tile(fromPosition) then
			if Tile(fromPosition):getTopCreature() then
				self:sendCancelMessage("Your cannot move this item with someone inside.")
				return false
			elseif Tile(toPosition):getTopCreature() then
				self:sendCancelMessage("Your cannot move this item over someone.")
				return false
			end
		end
	end
	
	-- falcon escutcheon forge
	if toPosition == Position(33363, 31342, 7) and item.itemid == 33223 then
		if tile and tile:getItemById(8671) then
			if self:getItemCount(33303) < 1 then
				self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Only a grant of arms from the king or the grand master of the Order of the Falcon permits to forge or bear a falcon escutcheon.")
				return false
			else
				if self:getItemCount(33223) > 0 and self:getItemCount(33300) > 0 then
					self:removeItem(33223, 1)
					self:removeItem(33300, 1)
					self:addItem(33224, 1)
					toPosition:sendMagicEffect(CONST_ME_POFF)
				end			
			end
		end
	end
	
	-- feeding the turtle [secret library]
	if toPosition == Position(32460, 32928, 7) and item.itemid == 2667 then		
		toPosition:sendMagicEffect(CONST_ME_HEARTS)
		self:say('You feed the turtle, now you may pass.', TALKTYPE_MONSTER_SAY)
		Game.setStorageValue(GlobalStorage.secretLibrary.SmallIslands.Turtle, os.stime() + 10*60)
		item:remove(1)
	end

	-- Cults of Tibia begin
	local frompos = Position(33023, 31904, 14) -- Checagem
	local topos = Position(33052, 31932, 15) -- Checagem
	if self:getPosition():isInRange(frompos, topos) and item:getId() == 26397 then
		local tileBoss = Tile(toPosition)
		if tileBoss and tileBoss:getTopCreature() and tileBoss:getTopCreature():isMonster() then
			if tileBoss:getTopCreature():getName():lower() == 'the remorseless corruptor' then
				tileBoss:getTopCreature():addHealth(-17000)
				item:remove(1)
				if tileBoss:getTopCreature():getHealth() <= 300 then
					tileBoss:getTopCreature():remove()
					local monster  = Game.createMonster('the corruptor of souls', toPosition)
					monster:registerEvent('checkPiso')
					if Game.getStorageValue('healthSoul') > 0 then
						monster:addHealth(-(monster:getHealth() - Game.getStorageValue('healthSoul')))
					end
					Game.setStorageValue('checkPiso', os.stime()+30)
				end
			elseif tileBoss:getTopCreature():getName():lower() == 'the corruptor of souls' then
				Game.setStorageValue('checkPiso', os.stime()+30)
				item:remove(1)
			end
		end
	end
	-- Cults of Tibia end
	
	local lionsRock = {
		[2147] = {position = Position(33069, 32298, 9), msg = "You place the ruby on the small socket. A red flame begins to burn.",
		flameId = 1488, storage = GlobalStorage.lionsRock.Red},
		[2146] = {position = Position(33069, 32302, 9), msg = "You place the sapphire on the small socket. A blue flame begins to burn.",
		flameId = 8058, storage = GlobalStorage.lionsRock.Blue},
		[2150] = {position = Position(33077, 32302, 9), msg = "You place the amethyst on the small socket. A violet flame begins to burn.",
		flameId = 7473, storage = GlobalStorage.lionsRock.Violet},
		[9970] = {position = Position(33077, 32298, 9), msg = "You place the topaz on the small socket. A yellow flame begins to burn.",
		flameId = 1500, storage = GlobalStorage.lionsRock.Yellow},
	}

	--- LIONS ROCK START
	if self:getStorageValue(lionrock.storages.playerCanDoTasks) - os.stime() < 0 then
		local it = lionsRock[item.itemid]
		if it then
			local mayPass = true
			if toPosition == it.position then
				local sqm = Tile(it.position)
				if sqm and sqm:getItemCountById(it.flameId) < 1 then
					local flame = Game.createItem(it.flameId, 1, it.position)
					if flame then flame:decay() end
					self:sendTextMessage(MESSAGE_EVENT_ADVANCE, it.msg)
					Game.setStorageValue(it.storage, 1)		
					item:remove(1)
					for _, k in pairs(lionsRock) do
						if Game.getStorageValue(k.storage) < 1 then
							mayPass = false
						end
					end
					if mayPass then
						local fountain = Game.createItem(6390, 1, Position(33073, 32300, 9))
						fountain:setActionId(41357)
						local stone = Tile(Position(33073, 32300, 9)):getItemById(3608)
						if stone ~= nil then
							stone:remove()
						end
						self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Something happens at the centre of the room ...")
					end
				end
			end
		end
	end
	---- LIONS ROCK END

	-- SSA exhaust
	local exhaust = { }
	if toPosition.x == CONTAINER_POSITION and toPosition.y == CONST_SLOT_NECKLACE and item:getId() == STONE_SKIN_AMULET then
		local pid = self:getId()
		if exhaust[pid] then
			self:sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED)
			return false
		else
			exhaust[pid] = true
			addEvent(function() exhaust[pid] = false end, 2000, pid)
			return true
		end
	end

	-- Store Inbox
	local containerIdFrom = fromPosition.y - 64
	local containerFrom = self:getContainerById(containerIdFrom)
	if (containerFrom) then
		if (containerFrom:getId() == ITEM_STORE_INBOX and toPosition.y >= 1 and toPosition.y <= 11 and toPosition.y ~= 3) then
			self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
			return false
		end
		if (containerFrom:getId() == ITEM_SUPPLY_STASH and toPosition.y >= 1 and toPosition.y <= 11 and toPosition.y ~= 3) then
			self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
			return false
		end
	end

	local function getContainerParent(self)
		local parent = self:getParent()
	--	if parent and parent:isItem() and not parent:getGround() then
		if parent and parent:isItem() then
			local peekNextParent = parent:getParent()
			if peekNextParent and peekNextParent.itemid == 1 then
				return parent
			end
		end

		return false
	end

	local containerTo = self:getContainerById(toPosition.y-64)
	if (containerTo) then
		if (containerTo:getId() == ITEM_STORE_INBOX) then
			self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
			return false
		end
		if (containerTo:getId() == ITEM_SUPPLY_STASH) then
			self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
			return false
		end
		-- Gold Pounch
		if (containerTo:getId() == GOLD_POUNCH) then
			if (not (item:getId() == ITEM_CRYSTAL_COIN or item:getId() == ITEM_PLATINUM_COIN or item:getId() == ITEM_GOLD_COIN)) then
				self:sendCancelMessage("You can move only money to this container.")
				return false
			end

			-- moving to bank
			local worth = {
				[2148] = 1, -- gold
				[2152] = 100, -- platinum
				[2160] = 10000, -- crystal
			}
			local gold = worth[item:getId()]
			if gold then
				local newbalance = self:getBankBalance() + (gold*item:getCount())
				item:remove()
				self:setBankBalance(newbalance)
				self:sendTextMessage(MESSAGE_STATUS_DEFAULT, string.format("Your new bank balance is %d gps.", newbalance))
				return true
			end
		end

		-- print("Buscando fix ".. item:getId(), "Destino: "..containerTo:getId())
		local ignoreArray = {2594, 2589, ITEM_DEPOT_NULL,ITEM_DEPOT_I,ITEM_DEPOT_II,ITEM_DEPOT_III,ITEM_DEPOT_IV,ITEM_DEPOT_V,ITEM_DEPOT_VI,ITEM_DEPOT_VII,ITEM_DEPOT_VIII,ITEM_DEPOT_IX,ITEM_DEPOT_X,ITEM_DEPOT_XI,ITEM_DEPOT_XII,ITEM_DEPOT_XIII,ITEM_DEPOT_XIV,ITEM_DEPOT_XV,ITEM_DEPOT_XVI, ITEM_DEPOT_XVII, ITEM_DEPOT_XVIII,}
		if not isInArray(ignoreArray, containerTo:getId()) and getContainerParent(containerTo) and getContainerParent(containerTo):getId() == ITEM_STORE_INBOX then
			self:sendCancelMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM)
			return false
		end

		local iType = ItemType(containerTo:getId())
		if iType:isCorpse() then
			return false
		end

	end

	-- No move gold pounch
	if item:getId() == GOLD_POUNCH then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return false
	end

	-- No move items with actionID 8000
	if item:getActionId() == NOT_MOVEABLE_ACTION then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return false
	end

	-- Check two-handed weapons
	if toPosition.x ~= CONTAINER_POSITION then
		return true
	end

	if item:getTopParent() == self and bit.band(toPosition.y, 0x40) == 0 then
		local itemType, moveItem = ItemType(item:getId())
		if bit.band(itemType:getSlotPosition(), SLOTP_TWO_HAND) ~= 0 and toPosition.y == CONST_SLOT_LEFT then
			moveItem = self:getSlotItem(CONST_SLOT_RIGHT)
			if moveItem and itemType:getWeaponType() == WEAPON_DISTANCE and ItemType(moveItem:getId()):getWeaponType() == WEAPON_QUIVER then
				return true
			end
		elseif itemType:getWeaponType() == WEAPON_SHIELD and toPosition.y == CONST_SLOT_RIGHT then
			moveItem = self:getSlotItem(CONST_SLOT_LEFT)
			if moveItem and bit.band(ItemType(moveItem:getId()):getSlotPosition(), SLOTP_TWO_HAND) == 0 then
				return true
			end
		end

		if moveItem then
			local parent = item:getParent()
			if parent:getSize() == parent:getCapacity() then
				self:sendTextMessage(MESSAGE_STATUS_SMALL, Game.getReturnMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM))
				return false
			else
				return moveItem:moveTo(parent)
			end
		end
	end

	-- Reward System
	if toPosition.x == CONTAINER_POSITION then
		local containerId = toPosition.y - 64
		local container = self:getContainerById(containerId)
		if not container then
			return true
		end

		-- Do not let the player insert items into either the Reward Container or the Reward Chest
		local itemId = container:getId()
		if itemId == ITEM_REWARD_CONTAINER or itemId == ITEM_REWARD_CHEST then
			self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
			return false
		end

		-- The player also shouldn't be able to insert items into the boss corpse
		local tile = Tile(container:getPosition())
		for _, item in ipairs(tile:getItems() or { }) do
			if item:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER) == 2^31 - 1 and item:getName() == container:getName() then
				self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
				return false
			end
		end
	end

	-- Do not let the player move the boss corpse.
	if item:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER) == 2^31 - 1 then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return false
	end

	-- Players cannot throw items on reward chest
	local tile = Tile(toPosition)
	if tile and tile:getItemById(ITEM_REWARD_CHEST) then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		self:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	-- Players cannot throw items on teleports
	if blockTeleportTrashing and toPosition.x ~= CONTAINER_POSITION then
		local thing = Tile(toPosition):getItemByType(ITEM_TYPE_TELEPORT)
		if thing then
			self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
			self:getPosition():sendMagicEffect(CONST_ME_POFF)
			return false
		end
	end

	if tile and tile:getItemById(370) then -- Trapdoor
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		self:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	if not antiPush(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder) then
		return false
	end

	return true
end

function Player:onItemMoved(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	-- Loot Analyser apenas 11.x+
	local t = Tile(fromCylinder:getPosition())
	local corpse = t:getTopDownItem()
	if corpse then
	    local itemType = corpse:getType()
		if itemType:isCorpse() and toPosition.x == CONTAINER_POSITION then
		    self:sendLootStats(item)
		end
	end

	local containerIdTo = toPosition.y - 64
	local containerTo = self:getContainerById(containerIdTo)
	if (containerTo and isDepot(containerIdTo)) then
		self:onManageLocker(item, false)
	elseif containerTo and containerTo:getTopParent() and containerTo:getTopParent():getId() == self:getId() then
		if isDepot(fromPosition.y - 64) then
			self:onManageLocker(item, true)
		end
	end

end

local isTrainingStorage = 12835

function Player:onMoveCreature(creature, fromPosition, toPosition)
	if self:getGroup():getId() < 4 then
		if Game.getWorldType() == WORLD_TYPE_RETRO_OPEN_PVP then
			if creature:isMonster() and creature:getType() and not creature:getType():isPet() then
				return false
			end
		end
		if creature:isPlayer() and creature:getStorageValue(isTrainingStorage) > 0 then
			self:sendCancelMessage("You cannot push a player while he is training.")
			return false
		end
	end
	return true
end

local function hasPendingReport(name, targetName, reportType)
	local f = io.open(string.format("data/reports/players/%s-%s-%d.txt", name, targetName, reportType), "r")
	if f then
		io.close(f)
		return true
	else
		return false
	end
end

function Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
	local name = self:getName()
	if hasPendingReport(name, targetName, reportType) then
		self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your report is being processed.")
		return
	end

	local file = io.open(string.format("data/reports/players/%s-%s-%d.txt", name, targetName, reportType), "a")
	if not file then
		self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There was an error when processing your report, please contact a gamemaster.")
		return
	end

	io.output(file)
	io.write("------------------------------\n")
	io.write("Reported by: " .. name .. "\n")
	io.write("Target: " .. targetName .. "\n")
	io.write("Type: " .. reportType .. "\n")
	io.write("Reason: " .. reportReason .. "\n")
	io.write("Comment: " .. comment .. "\n")
	if reportType ~= REPORT_TYPE_BOT then
		io.write("Translation: " .. translation .. "\n")
	end
	io.write("------------------------------\n")
	io.close(file)
	self:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Thank you for reporting %s. Your report will be processed by %s team as soon as possible.", targetName, configManager.getString(configKeys.SERVER_NAME)))
	return
end

function Player:onReportBug(message, position, category)
	local name = self:getName()
	local file = io.open("data/reports/bugs/" .. name .. " report.txt", "a")

	if not file then
		self:sendTextMessage(MESSAGE_EVENT_DEFAULT, "There was an error when processing your report, please contact a gamemaster.")
		return true
	end

	io.output(file)
	io.write("------------------------------\n")
	io.write("Name: " .. name)
	if category == BUG_CATEGORY_MAP then
		io.write(" [Map position: " .. position.x .. ", " .. position.y .. ", " .. position.z .. "]")
	end
	local playerPosition = self:getPosition()
	io.write(" [Player Position: " .. playerPosition.x .. ", " .. playerPosition.y .. ", " .. playerPosition.z .. "]\n")
	io.write("Comment: " .. message .. "\n")
	io.close(file)

	self:sendTextMessage(MESSAGE_EVENT_DEFAULT, "Your report has been sent to " .. configManager.getString(configKeys.SERVER_NAME) .. ".")
	return true
end

function Player:onTurn(direction)
	if self:getGroup():getId() >= 5 and self:getDirection() == direction then
		local nextPosition = self:getPosition()
		nextPosition:getNextPosition(direction)

		self:teleportTo(nextPosition, true)
	end

	return true
end

function Player:onTradeRequest(target, item)
    self:closeImbuementWindow(target)
	if isInArray(exercise_ids,item.itemid) then
        return false
    end
 	return true
end

function Player:onTradeAccept(target, item, targetItem)
	self:closeImbuementWindow(target)
	return true
end

local soulCondition = Condition(CONDITION_SOUL, CONDITIONID_DEFAULT)
soulCondition:setTicks(4 * 60 * 1000)
soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)

local function useStamina(player)
	local staminaMinutes = player:getStamina()
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	local currentTime = os.stime()
	if not nextUseStaminaTime[playerId] then
		nextUseStaminaTime[playerId] = currentTime - 2
	end
	local timePassed = currentTime - nextUseStaminaTime[playerId]
	if timePassed <= 0 then
		return
	end

	if timePassed > 60 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseStaminaTime[playerId] = currentTime + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseStaminaTime[playerId] = currentTime + 60
	end
	player:setStamina(staminaMinutes)
end

local function useStaminaXp(player)
	local staminaMinutes = player:getExpBoostStamina() / 60
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	local currentTime = os.stime()
	local timePassed = currentTime - nextUseXpStamina[playerId]
	if timePassed <= 0 then
		return
	end

	if timePassed > 60 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseXpStamina[playerId] = currentTime + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseXpStamina[playerId] = currentTime + 60
	end
	player:setExpBoostStamina(staminaMinutes * 60)
end

local function sharedExpParty(player, exp)
	local party = player:getParty()
	if not party then
		return exp
	end

	if not party:isSharedExperienceActive() then
		return exp
	end

	if not party:isSharedExperienceEnabled() then
		return exp
	end

	local config = {
		{amount = 2, multiplier = 1.3},
		{amount = 3, multiplier = 1.6},
		{amount = 4, multiplier = 2}
	}

	local sharedExperienceMultiplier = 1.2 -- 20% if the same vocation
	local vocationsIds = {}
	local vocationId = party:getLeader():getVocation():getBase():getId()
	if vocationId ~= VOCATION_NONE then
		table.insert(vocationsIds, vocationId)
	end
	for _, member in ipairs(party:getMembers()) do
		vocationId = member:getVocation():getBase():getId()
		if not table.contains(vocationsIds, vocationId) and vocationId ~= VOCATION_NONE then
			table.insert(vocationsIds, vocationId)
		end
	end	
	local size = #vocationsIds
	for _, info in pairs(config) do
		if size == info.amount then
			sharedExperienceMultiplier = info.multiplier
		end
	end	

	local finalExp = (exp * sharedExperienceMultiplier) / (#party:getMembers() + 1)
	return finalExp
end

function Player:onGainExperience(source, exp, rawExp)
	if not source or source:isPlayer() then
		if self:getClient().version <= 1100 then
			self:addExpTicks(exp)
		end
		return exp
	elseif source and source:isMonster() and source:isBoosted() then
		exp = exp * 2
	end
	
	-- Guild Level System
	if self:getGuild() then
		local rewards = {}
		local number = false
		rewards = getReward(self:getId()) or {}
		for i = 1, #rewards do
			if rewards[i].type == GUILD_LEVEL_BONUS_EXP then
				number = rewards[i].quantity
			end
		end
		if number then
			exp = exp +(exp*number)
		end
	end
	-- Soul Regeneration
	local vocation = self:getVocation()
	if self:getSoul() < vocation:getMaxSoul() and exp >= self:getLevel() then
		soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks() * 1000)
		self:addCondition(soulCondition)
	end

	-- Experience Stage Multiplier
	exp = Game.getExperienceStage(self:getLevel()) * exp
	exp = sharedExpParty(self, exp)

	local multiplier = 1
	baseExp = rawExp
	-- Store Bonus
	self:updateExpState()
	useStaminaXp(self) -- Use store boost stamina

	local grindingBoost = 0
	if (self:getGrindingXpBoost() > 0) then
		grindingBoost = exp * 0.5
	end

	local xpBoost = 0
	if (self:getStoreXpBoost() > 0) then
		xpBoost = exp * 0.5
	end

	local staminaMultiplier = 1
	-- Stamina Bonus
	local isPremium = configManager.getBoolean(configKeys.FREE_PREMIUM) and true or self:isPremium()
	local staminaMinutes = self:getStamina()
	if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		useStamina(self)
		if staminaMinutes > 2400 and isPremium then
			staminaMultiplier = 1.5
		elseif staminaMinutes <= 840 then
			staminaMultiplier = 0.5
		end
	end

	if self:getVipDays() > os.stime() then
		multiplier = 1.10
	end

	-- print("baseExp:" .. baseExp,
	-- 	"stage:".. Game.getExperienceStage(self:getLevel()).."x",
	-- 	"exp*stage*party:"..exp, "multiplier:".. multiplier,
	-- 	"finalExp + grinding:"..(math.ceil(multiplier * exp)*grindingBoost),
	-- 	"finalExp + xpBoost:"..((math.ceil(multiplier * exp)*grindingBoost)* xpBoost),
	-- 	"finalExp+stamina:" ..((math.ceil(multiplier * exp)*grindingBoost)* xpBoost)*staminaMultiplier)

	exp = multiplier * exp
	exp = exp + grindingBoost
	exp = exp + xpBoost
	exp = exp * staminaMultiplier
	-- 50% XP
	-- exp = math.ceil(exp*1.5)

	if self:getClient().version <= 1100 then
		self:addExpTicks(exp)
	end

	return exp
end

function Player:onLoseExperience(exp)
	return exp
end

function Player:onGainSkillTries(skill, tries)
	if APPLY_SKILL_MULTIPLIER == false then
		return tries
	end

	if skill == SKILL_MAGLEVEL then
		return tries * Game.getMagicLevelStage(self:getMagicLevel())
	end
	return tries * Game.getSkillStage(self:getSkillLevel(skill))
end

function Player:onRemoveCount(item)
	self:sendWaste(item:getId())
end

function Player:onRequestQuestLog()
	self:sendQuestLog()
end

function Player:onRequestQuestLine(questId)
	self:sendQuestLine(questId)
end

function Player:onStorageUpdate(key, value, oldValue, currentFrameTime)
	self:updateStorage(key, value, oldValue, currentFrameTime)
end

function Player:canBeAppliedImbuement(imbuement, item)
	local categories = {}
	local slots = ItemType(item:getId()):getImbuingSlots()
	if slots > 0 then
		for slot = 0, slots - 1 do
			local duration = item:getImbuementDuration(slot)
			if duration > 0 then
				local imbue = item:getImbuement(slot)
				local catid = imbue:getCategory().id
				table.insert(categories, catid)
			end
		end
	end

	if isInArray(categories, imbuement:getCategory().id) then
		return false
	end

	if imbuement:isPremium() and self:getPremiumDays() < 1 then
		return false
	end

	if not self:canImbueItem(imbuement, item) then
		return false
	end

	return true
end

function Player:onApplyImbuement(imbuement, item, slot, protectionCharm)
	for _, pid in pairs(imbuement:getItems()) do
		if self:getItemCount(pid.itemid) < pid.count then
			self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "You don't have all necessary items.")
			return false
		end
	end

	if item:getImbuementDuration(slot) > 0 then
		self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ERROR, "An error ocurred, please reopen imbuement window.")
		return false
	end
	local base = imbuement:getBase()
	local price = base.price + (protectionCharm and base.protection or 0)
	if not self:removeMoneyNpc(price) then
		self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "You don't have enough money " ..price.. " gps.")
		return false
	end

	local chance = protectionCharm and 100 or base.percent
	if math.random(100) > chance then
		for _, pid in pairs(imbuement:getItems()) do
			self:removeItem(pid.itemid, pid.count)
		end

		self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "Item failed to apply imbuement.")
		return false
	end

	-- Removing items
	for _, pid in pairs(imbuement:getItems()) do
		if not self:removeItem(pid.itemid, pid.count) then
			self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "You don't have all necessary items.")
			return false
		end
	end

	if not item:addImbuement(slot, imbuement:getId()) then
		self:sendImbuementResult(MESSAGEDIALOG_IMBUEMENT_ROLL_FAILED, "Item failed to apply imbuement.")
		return false
	end

	item:setAttribute(ITEM_ATTRIBUTE_IMBUED, 1)

	-- Update item
	local nitem = Item(item.uid)
	self:sendImbuementPanel(nitem)
	return true
end

function Player:clearImbuement(item, slot)
	local slots = ItemType(item:getId()):getImbuingSlots()
	if slots < slot then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "Sorry, not possible.")
		return false
	end

	if item:getTopParent() ~= self or item:getParent() == self then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "An error occurred while applying the clearing charm to the item.")
		return false
	end

	-- slot is not used
	local info = item:getImbuementDuration(slot)
	if info == 0 then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "An error occurred while applying the clearing charm to the item.")
		return false
	end

	local imbuement = item:getImbuement(slot)
	if not self:removeMoneyNpc(imbuement:getBase().removecust) then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "You don't have enough money " ..imbuement:getBase().removecust.. " gps.")
		return false
	end

	if not item:cleanImbuement(slot) then
		self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_ERROR, "An error occurred while applying the clearing charm to the item.")
		return false
	end

	-- Update item
	local nitem = Item(item.uid)
	self:sendImbuementResult(MESSAGEDIALOG_CLEARING_CHARM_SUCCESS, "Congratulations! You have successfully applied the clearing charm to your item.");
	self:sendImbuementPanel(nitem)

	return true
end

function Player:onCombat(target, item, primaryDamage, primaryType, secondaryDamage, secondaryType)
	if target then
		local monster = Monster(target:getId())
		if monster and monster:getType() and monster:getType():raceId() > 0 then
			local atualCharm = self:getMonsterCharm(monster:getType():raceId())
			if atualCharm == 6 and math.random(1, 10000) <= 100 then
				local condition = Condition(CONDITION_PARALYZE)
				condition:setParameter(CONDITION_PARAM_TICKS, 10000)
				condition:setFormula(-0.40, -0.15, -0.55, -0.15)
				target:addCondition(condition)
				self:sendTextMessage(MESSAGE_DAMAGE_DEALT, "Active charm 'Cripple'")
			end
		end
	end

	if not item or not target then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	if primaryType == COMBAT_HEALING or secondaryType == COMBAT_HEALING then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	local slots = ItemType(item:getId()):getImbuingSlots()
	if slots > 0 then
		for i = 0, slots - 1 do
			local imbuement = item:getImbuement(i)
			if imbuement then
				local percent = imbuement:getElementDamage()
				if percent and percent > 0 then
					if primaryDamage ~= 0 then
						secondaryDamage = primaryDamage*math.min(percent/100, 1)
						secondaryType = imbuement:getCombatType()
						primaryDamage = primaryDamage - secondaryDamage
					elseif secondaryDamage ~= 0 then
						primaryDamage = secondaryDamage*math.min(percent/100, 1)
						primaryType = imbuement:getCombatType()
						secondaryDamage = secondaryDamage - primaryDamage
					end
				end
			end
		end
	end

	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
