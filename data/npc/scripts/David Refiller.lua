 local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)	npcHandler:onCreatureAppear(cid)	end
function onCreatureDisappear(cid)npcHandler:onCreatureDisappear(cid)	end
function onCreatureSay(cid, type, msg)npcHandler:onCreatureSay(cid, type, msg)end
function onThink()npcHandler:onThink()	end


local options = {
	['potions'] = {
		{name = 'ultimate mana potion', id = 26029, buy = 438},
		{name = 'ultimate health potion', id = 8473, buy = 310},
		{name = 'ultimate spirit potion', id = 26030, buy = 438},
		{name = 'strong health potion', id = 7588, buy = 100},
		{name = 'strong mana potion', id = 7589, buy = 80},
		{name = 'great mana potion', id = 7590, buy = 120},
		{name = 'great spirit potion', id = 8472, buy = 190},
		{name = 'great health potion', id = 7591, buy = 438},
		{name = 'health potion', id = 7618, buy = 45},
		{name = 'mana potion', id = 7620, buy = 50},
		{name = 'supreme health potion', id = 26031, buy = 500}
	},
	['runes'] = {
		{name = "animate dead rune", id = 2316, buy = 375},
		{name = "avalanche rune", id = 2274, buy = 25},
		{name = "black pearl", id = 2144, buy = 280},
		{name = "bronze goblet", id = 5807, buy = 2000},
		{name = "chameleon rune", id = 2291, buy = 210},
		{name = "convince creature rune", id = 2290, buy = 80},
		{name = "cure poison rune", id = 2266, buy = 65},
		{name = "disintegrate rune", id = 2310, buy = 26},
		{name = "destroy field rune", id = 2261, buy = 15},
		{name = "energy bomb rune", id = 2262, buy = 162},
		{name = "energy field rune", id = 2277, buy = 38},
		{name = "energy wall rune", id = 2279, buy = 85},
		{name = "explosion rune", id = 2313, buy = 31},
		{name = "fire bomb rune", id = 2305, buy = 55},
		{name = "fire field rune", id = 2301, buy = 28},
		{name = "fire wall rune", id = 2303, buy = 61},
		{name = "fireball rune", id = 2302, buy = 30},
		{name = "great fireball rune", id = 2304, buy = 45},
		{name = "heavy magic missile rune", id = 2311, buy = 12},
		{name = "intense healing rune", id = 2265, buy = 95},
		{name = "light magic missile rune", id = 2287, buy = 4},
		{name = "magic wall rune", id = 2293, buy = 55},
		{name = "paralyze rune", id = 2278, buy = 500},
		{name = "poison bomb rune", id = 2286, buy = 85},
		{name = "poison field rune", id = 2285, buy = 21},
		{name = "poison wall rune", id = 2289, buy = 52},
		{name = "soulfire rune", id = 2308, buy = 46},
		{name = "stalagmite rune", id = 2292, buy = 12},
		{name = "stone shower rune", id = 2288, buy = 37},
		{name = "sudden death rune", id = 2268, buy = 50},
		{name = "supreme health potion", id = 26031, buy = 500},
		{name = "thunderstorm rune", id = 2315, buy = 37},
		{name = "ultimate healing rune", id = 2273, buy = 175},
		{name = "wild growth rune", id = 2269, buy = 160}
	},
	['equipment'] = {
		{name = "axe", id = 2386, buy = 20},
		{name = "battle axe", id = 2378, buy = 235},
		{name = "battle hammer", id = 2417, buy = 350},
		{name = "bone sword", id = 2450, buy = 75},
		{name = "brass armor", id = 2465, buy = 450},
		{name = "brass helmet", id = 2460, buy = 120},
		{name = "brass legs", id = 2478, buy = 195},
		{name = "brass shield", id = 2511, buy = 65},
		{name = "carlin sword", id = 2395, buy = 473},
		{name = "chain armor", id = 2464, buy = 200},
		{name = "chain helmet", id = 2458, buy = 52},
		{name = "chain legs", id = 2648, buy = 80},
		{name = "club", id = 2382, buy = 5},
		{name = "coat", id = 2651, buy = 8},
		{name = "crowbar", id = 2416, buy = 260},
		{name = "dagger", id = 2379, buy = 5},
		{name = "doublet", id = 2485, buy = 16},
		{name = "dwarven shield", id = 2525, buy = 500},
		{name = "hand axe", id = 2380, buy = 8},
		{name = "iron helmet", id = 2459, buy = 390},
		{name = "jacket", id = 2650, buy = 12},
		{name = "leather armor", id = 2467, buy = 35},
		{name = "leather boots", id = 2643, buy = 10},
		{name = "leather helmet", id = 2461, buy = 12},
		{name = "leather legs", id = 2649, buy = 10},
		{name = "longsword", id = 2397, buy = 160},
		{name = "mace", id = 2398, buy = 90},
		{name = "morning star", id = 2394, buy = 430},
		{name = "plate armor", id = 2463, buy = 1200},
		{name = "plate shield", id = 2510, buy = 125},
		{name = "rapier", id = 2384, buy = 15},
		{name = "sabre", id = 2385, buy = 35},
		{name = "scale armor", id = 2483, buy = 260},
		{name = "short sword", id = 2406, buy = 26},
		{name = "sickle", id = 2405, buy = 7},
		{name = "soldier helmet", id = 2481, buy = 110},
		{name = "spike sword", id = 2383, buy = 8000},
		{name = "steel helmet", id = 2457, buy = 580},
		{name = "steel shield", id = 2509, buy = 240},
		{name = "studded armor", id = 2484, buy = 90},
		{name = "studded helmet", id = 2482, buy = 63},
		{name = "studded legs", id = 2468, buy = 50},
		{name = "studded shield", id = 2526, buy = 50},
		{name = "throwing knife", id = 2410, buy = 25},
		{name = "two handed sword", id = 2377, buy = 950},
		{name = "viking helmet", id = 2473, buy = 265},
		{name = "viking shield", id = 2531, buy = 260},
		{name = "war hammer", id = 2391, buy = 10000},
		{name = "wooden shield", id = 2512, buy = 15}
	},
	['distance'] = {
		{name = "arrow", id = 2544, buy = 3},
		{name = "bolt", id = 2543, buy = 4},
		{name = "bow", id = 2456, buy = 400},
		{name = "crystalline arrow", id = 18304, buy = 20},
		{name = "drill bolt", id = 18436, buy = 12},
		{name = "earth arrow", id = 7850, buy = 5},
		{name = "envenomed arrow", id = 18437, buy = 12},
		{name = "flaming arrow", id = 7840, buy = 5},
		{name = "flash arrow", id = 7838, buy = 5},
		{name = "onyx arrow", id = 7365, buy = 7},
		{name = "piercing bolt", id = 7363, buy = 5},
		{name = "power bolt", id = 2547, buy = 7},
		{name = "prismatic bolt", id = 18435, buy = 20},
		{name = "shiver arrow", id = 7839, buy = 5},
		{name = "sniper arrow", id = 7364, buy = 5},
		{name = "spear", id = 2389, buy = 9},
		{name = "tarsal arrow", id = 15648, buy = 6},
		{name = "throwing knife", id = 2410, buy = 25},
		{name = "throwing star", id = 2399, buy = 42}
	},
	['supplies'] = {
		{name = "white mushroom", id = 2787, buy = 6},
		{name = "brown mushroom", id = 2789, buy = 10},
		{name = "red mushroom", id = 2788, buy = 12},
		{name = "bread", id = 2689, buy = 4},
		{name = "ham", id = 2671, buy = 8},
		{name = "cheese", id = 2696, buy = 6},
		{name = "meat", id = 2666, buy = 5}
	},
	['tools'] = {
		{name = "backpack", id = 1988, buy = 20},
		{name = "bag", id = 1987, buy = 5},
		{name = "fishing rod", id = 2580, buy = 150},
		{name = "machete", id = 2420, buy = 40},
		{name = "pick", id = 2553, buy = 50},
		{name = "present", id = 1990, buy = 10},
		{name = "rope", id = 2120, buy = 50},
		{name = "scroll", id = 1949, buy = 5},
		{name = "scythe", id = 2550, buy = 50},
		{name = "shovel", id = 2554, buy = 50},
		{name = "torch", id = 2050, buy = 2},
		{name = "watch", id = 6091, buy = 20},
		{name = "worm", id = 3976, buy = 1}
	},
	['postal'] = {
		{name = "label", id = 2599, buy = 1},
		{name = "parcel", id = 2595, buy = 15},
		{name = "letter", id = 2597, buy = 8}
	},
	['rods'] = {
		{name = "terra rod", id = 2181, buy = 10000},
		{name = "underworld rod", id = 8910, buy = 22000},
		{name = "hailstorm rod", id = 2183, buy = 15000},
		{name = "moonlight rod", id = 2186, buy = 1000},
		{name = "necrotic rod", id = 2185, buy = 5000},
		{name = "northwind rod", id = 8911, buy = 7500},
		{name = "snakebite rod", id = 2182, buy = 500},
		{name = "springsprout rod", id = 8912, buy = 18000},
	},
	['wands'] = {
		{name = "wand of cosmic energy", id = 2189, buy = 10000},
		{name = "wand of decay", id = 2188, buy = 5000},
		{name = "wand of draconia", id = 8921, buy = 7500},
		{name = "wand of dragonbreath", id = 2191, buy = 1000},
		{name = "wand of inferno", id = 2187, buy = 15000},
		{name = "wand of starstorm", id = 8920, buy = 18000},
		{name = "wand of voodoo", id = 8922, buy = 22000},
		{name = "wand of vortex", id = 2190, buy = 500},
	},
	['various'] = {
		{name = "exercise sword", id = 33082, buy = 262500, type = 'chargable', charges = 500},
		{name = "exercise axe", id = 33083, buy = 262500, type = 'chargable', charges = 500},
		{name = "exercise club", id = 33084, buy = 262500, type = 'chargable', charges = 500},
		{name = "exercise rod", id = 33086, buy = 262500, type = 'chargable', charges = 500},
		{name = "exercise wand", id = 33087, buy = 262500, type = 'chargable', charges = 500},
		{name = "exercise bow", id = 33085, buy = 262500, type = 'chargable', charges = 500},
	}
}

local equivalente = {
	[1] = 'potions',
	[2] = 'runes',
	[3] = 'equipment',
	[4] = 'distance',
	[5] = 'supplies',
	[6] = 'tools',
	[7] = 'rods',
	[8] = 'wands',
	[9] = 'various',
}

local function getTable(player)
	local msg = equivalente[player:getStorageValue(Storage.NPCTable)]
	if not msg then
		return false
	end

	local itemsList = {}
	local sendTrade = options[msg:lower()]
	if not sendTrade then return false end

	itemsList = sendTrade
	return itemsList
end

local function setNewTradeTable(_table)
	local items, item = {}
	if _table then
		for i = 1, #_table do
			item = _table[i]
			items[item.id] = {itemId = item.id, buyPrice = item.buy, sellPrice = item.sell, subType = 0, realName = item.name, type = item.type, charges = item.charges}
		end
	end
	return items
end

local function onBuy(cid, item, subType, amount, ignoreCap, inBackpacks)
	local player = Player(cid)
	if not player then
		return false
	end

	if not getTable(player) then
		return false
	end

	local items = setNewTradeTable(getTable(player))
	if items then
		if not ignoreCap and player:getFreeCapacity() < ItemType(items[item].itemId):getWeight(amount) then
			return player:sendTextMessage(MESSAGE_INFO_DESCR, 'You don\'t have enough cap.')
		end
		if not player:removeMoneyNpc(items[item].buyPrice * amount) then
			selfSay("You don't have enough money.", cid)
		else
			local itemType = ItemType(items[item].itemId)
			if itemType:isStackable() then
				local item_ = player:addItem(items[item].itemId, amount)
				if item_ then
					if items[item].type and items[item].type == 'chargable' then
						item_:setAttribute(ITEM_ATTRIBUTE_CHARGES, items[item].charges)
					end
				end
			else
				for i = 1, amount do
					local it = player:addItem(itemType:getId(), subType)
					if it then
						if items[item].type and items[item].type == 'chargable' then
							it:setAttribute(ITEM_ATTRIBUTE_CHARGES, items[item].charges)
						end
					end
				end
			end

			return player:sendTextMessage(MESSAGE_INFO_DESCR, 'Bought '..amount..'x '..items[item].realName..' for '..items[item].buyPrice * amount..' gold coins.')
		end
	end
	return true
end

local function onSell(cid, item, subType, amount, ignoreCap, inBackpacks)
	local player = Player(cid)
	if not player then
		return false
	end

	if not getTable(player) then
		return false
	end

	local items = setNewTradeTable(getTable(player))
	if items[item].sellPrice and player:removeItem(items[item].itemId, amount) then
		player:addMoney(items[item].sellPrice * amount)
		return player:sendTextMessage(MESSAGE_INFO_DESCR, 'Sold '..amount..'x '..items[item].realName..' for '..items[item].sellPrice * amount..' gold coins.')
	else
		selfSay("You don't have item to sell.", cid)
	end
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)
	player:setStorageValue(Storage.NPCTable, -1)
	for i = 1, #equivalente do
		if msgcontains(equivalente[i], msg) then
			player:setStorageValue(Storage.NPCTable, i)
			local items = setNewTradeTable(getTable(player))

			openShopWindow(cid, getTable(player), onBuy, onSell)
			npcHandler:say('Alright, here\'s all the ' .. equivalente[i] .. ' I can order for you!', cid)
			break
		end
	end

	return true
end

npcHandler:setMessage(MESSAGE_FAREWELL, 'Good bye. :)')

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
