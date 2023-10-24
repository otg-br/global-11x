--[[
#### worthdavi
#### 12/07/2019
--]]

local valor = {}
local quantidade = {}
local itemName = {}
local precoTotal = {}
local itemId = {}
local _outfit = {male = 0, female = 0}

local moeda = 15515

local config = {
	TYPE_ITEM = 1,
	TYPE_MOUNT = 2,
	TYPE_OUTFIT = 3,
	TYPE_OTHERSTUFF = 4,
	itens = {
		[2798] = {valor = 50},
	    [20620] = {valor = 300},
	    [33082] = {valor = 50}, -- exercises bg
	    [33083] = {valor = 50},
	    [33084] = {valor = 50},
	    [33085] = {valor = 50},
	    [33086] = {valor = 50},
	    [33087] = {valor = 50}, -- exercises end
	    [23588] = {valor = 150},
	    [16007] = {valor = 1500},
	    [27063] = {valor = 1500},
		[3954] = {valor = 250},
		[7184] = {valor = 250},
		[9006] = {valor = 250},
		[7487] = {valor = 250},
		[2108] = {valor = 250},
		[35036] = {valor = 250},
		[2355] = {valor = 250}
		},
	outfits = {
		['lion of war'] = {valor = 2600, idF = 1206, idM = 1207},
		['veteran paladin'] = {valor = 2600, idF = 1204, idM = 1205},
		['void master'] = {valor = 2600, idF = 1202, idM = 1203}
	},
	mounts = {
		[44] = {valor = 2600},
		[45] = {valor = 2600},
		[37] = {valor = 2600}
	},
	otherStuff = {
		["all bless"] = {valor = 30},
		["boost exp"] = {valor = 150},
		["prey bonus reroll"] = {valor = 100},
		["prey bonus reroll 5x"] = {valor = 450},
		["instant reward access"] = {valor = 50},
		["instant reward access 10x"] = {valor = 400},
	}
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local playerTopic = {}
local function greetCallback(cid)
	local player = Player(cid)	
	if player then
		npcHandler:setMessage(MESSAGE_GREET, "Hello, ".. player:getName() .."! With me you can buy {clothes}, {mounts}, {artifacts} and some {other stuff}, would you be interested?")
		playerTopic[cid] = 1
	end
	npcHandler:addFocus(cid)
	return true
end

local function showCatalog(table, type)
	local max = 0
	for _, k in pairs(table) do
		max = max + 1
	end
	local msg = ""
	local c = 0
	for i, k in pairs(table) do
		local virgula = ", "
		if c ~= (max - 1) then
			c = c + 1
		else
			virgula = ""
		end
		if type == config.TYPE_ITEM then
			msg = msg .. "{".. ItemType(i):getName():lower() .. "}"
		elseif type == config.TYPE_MOUNT then
			msg = msg .. "{".. Mount(i):getName():lower() .. "}"
		elseif type == config.TYPE_OUTFIT then
			msg = msg .. "{".. i:lower() .. "}"
		elseif type == config.TYPE_OTHERSTUFF then
			msg = msg .. "{".. i:lower() .. "}"
		end
		msg = msg .. virgula
	end
	return msg
end

local CONST_RET_STUFF = {
	NONE = 0,
	ERROR = 1,
	SUCCESS = 2,
	NO_OFFER = 3,
}

local function buyOfferStuff(playerid, valor, itemName)
	local player = Player(playerid)
	if not player then
		return CONST_RET_STUFF.NONE
	end

	if player:getItemCount(moeda) < valor then
		player:sendCancelMessage("You dont have money.")
		return CONST_RET_STUFF.ERROR
	end

	if itemName:lower() == "all bless" then
		local blesses = 8
		local blesscount = 0
		for i = 1, blesses do
			if player:hasBlessing(i) then
				blesscount = blesscount + 1
			end
		end

		if blesscount == blesses then
			player:sendCancelMessage("You already have all Blessings.")
			return CONST_RET_STUFF.ERROR
		end

		player:removeItem(moeda, valor)
		for i = 1, blesses do
			player:addBlessing(i, 1)
		end

		return CONST_RET_STUFF.SUCCESS
	elseif itemName:lower() == "boost exp" then
		if (player:getStorageValue(51052) == 6 and (os.stime() - player:getStorageValue(51053)) < 86400) then
			player:sendCancelMessage("You can't buy XP Boost for today.")
			return CONST_RET_STUFF.ERROR
		end

		player:removeItem(moeda, valor)
		local currentExpBoostTime = player:getExpBoostStamina()

		player:setStoreXpBoost(50)
		player:setExpBoostStamina(currentExpBoostTime + 3600)

		if (player:getStorageValue(51052) == -1 or player:getStorageValue(51052) == 6) then
			player:setStorageValue(51052, 1)
		end

		player:setStorageValue(51052, player:getStorageValue(51052) + 1)
		player:setStorageValue(51053, os.stime()) -- last bought

		return CONST_RET_STUFF.SUCCESS

	elseif itemName:lower() == "prey bonus reroll" then
		if player:getClient().version < 1120 then
			player:sendCancelMessage("Use client 12 to buy something related to prey.")
			return CONST_RET_STUFF.ERROR
		end

		player:removeItem(moeda, valor)

		local amount = math.max(player:getPreyBonusRerolls(), 0)
		player:setPreyBonusRerolls(1 + amount)
		player:setPreyBonusRerolls(1 + amount)
		player:setPreyBonusRerolls(1 + amount)

		return CONST_RET_STUFF.SUCCESS
	elseif itemName:lower() == "prey bonus reroll 5x" then
		if player:getClient().version < 1120 then
			player:sendCancelMessage("Use client 12 to buy something related to prey.")
			return CONST_RET_STUFF.ERROR
		end

		player:removeItem(moeda, valor)

		local amount = math.max(player:getPreyBonusRerolls(), 0)
		player:setPreyBonusRerolls(5 + amount)
		player:setPreyBonusRerolls(5 + amount)
		player:setPreyBonusRerolls(5 + amount)

		return CONST_RET_STUFF.SUCCESS
	elseif itemName:lower() == "instant reward access" then
		player:removeItem(moeda, valor)
		player:addRewardTokens(1)
		return CONST_RET_STUFF.SUCCESS
	elseif itemName:lower() == "instant reward access 10x" then
		player:removeItem(moeda, valor)
		player:addRewardTokens(10)
		return CONST_RET_STUFF.SUCCESS
	end

	return CONST_RET_STUFF.NO_OFFER
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	
	npcHandler.topic[cid] = playerTopic[cid]
	local player = Player(cid)
	local plural = ""
	
	local function sendHello(topic)
		npcHandler:say({"Glad you were interested. I'm a different merchant ... My currency is based on the players participating in server events. Do you have event tokens?"}, cid)
		npcHandler.topic[cid] = topic
		playerTopic[cid]= topic
	end
	
	if (msgcontains(msg, "artifacts") or msgcontains(msg, "items")) and (npcHandler.topic[cid] == 1) then
		sendHello(2)
	-- Prosseguindo com a partes de itens
	elseif npcHandler.topic[cid] == 2 then
		if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
			local arrayProdutos = showCatalog(config.itens, config.TYPE_ITEM)
			npcHandler:say({"How nice! Then browse my catalog of artifacts and let me know if something interests you: ".. arrayProdutos .."."}, cid)
			npcHandler.topic[cid] = 3
			playerTopic[cid]= 3
		end
	elseif npcHandler.topic[cid] == 3 then
		local itemType = ItemType(msg)
		if not itemType then
		   npcHandler:say({"An error has ocurred, please contact an administrator."}, cid)
		   return false
		end
		local itensTable = config.itens[itemType:getId()]
		if itensTable then
			valor[cid] = itensTable.valor
			itemName[cid] = msg
			npcHandler:say({"Good choice! If you really want the ".. itemName[cid] ..", it will cost you ".. valor[cid] .." ".. ItemType(moeda):getName():lower() .." each. How many would you be interested in?"}, cid)
			npcHandler.topic[cid] = 4
			playerTopic[cid]= 4
		else
			npcHandler:say({"This item is not in my catalog."}, cid)
		end		
	elseif npcHandler.topic[cid] == 4 then
		quantidade[cid] = tonumber(msg)
		if quantidade[cid] then	
			if quantidade[cid] > 1 then
				plural = plural .. "s"
			end
			if quantidade[cid] >= 20 then
				npcHandler:say({"Calm down!! It doesn't fit in a bag!"}, cid)
			else
				precoTotal[cid] = valor[cid]*quantidade[cid]
				npcHandler:say({"So you want ".. quantidade[cid] .." ".. itemName[cid] .. plural ..". Hmmmm, this will give a total of ".. precoTotal[cid] .." ".. ItemType(moeda):getName():lower() .."s. Do you accept?"}, cid)
				playerTopic[cid] = 5
				npcHandler.topic[cid] = 5
			end
		else
			npcHandler:say({"I did not understand."}, cid)
		end
	elseif npcHandler.topic[cid] == 5 then
		if msgcontains(msg, "yes") or msgcontains(msg, "sim") then
			if player:getItemCount(moeda) >= precoTotal[cid] then					
				itemId[cid] = ItemType(itemName[cid]):getId()
				-- Criando container no mailbox
				local parcel = player:getInbox():addItem(2596, 1, false, 1)
				parcel:addItem(1988, 1, false, 1):addItem(itemId[cid], quantidade[cid], false, 1)
				player:removeItem(moeda, precoTotal[cid]) 
				npcHandler:say({"Great. I will ask my delivery boy to leave the items in your mailbox."}, cid)						
			else
				npcHandler:say({"You don't have enough event tokens..."}, cid)
				npcHandler.topic[cid] = 1
				playerTopic[cid]= 1
			end
		end
		
	-- Prosseguindo com a parte de mounts
	elseif (msgcontains(msg, "mount") or msgcontains(msg, "mounts")) and (npcHandler.topic[cid] == 1) then
		sendHello(6)
	elseif npcHandler.topic[cid] == 6 then
		if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
			local arrayMounts = showCatalog(config.mounts, config.TYPE_MOUNT)		
			npcHandler:say({"How nice! Then browse my catalog of mounts and let me know if something interests you: ".. arrayMounts .."."}, cid)
			npcHandler.topic[cid] = 7
			playerTopic[cid]= 7
		end
	elseif npcHandler.topic[cid] == 7 then
		local mount = Mount(msg)
		if not mount then
			npcHandler:say({"An error has ocurred, please contact an administrator."}, cid)
		    return false
		end
		local mountTable = config.mounts[mount:getId()]
		if mountTable then
			valor[cid] = mountTable.valor
			itemName[cid] = msg
			npcHandler:say({"Good choice! If you really want the ".. itemName[cid] ..", it will cost you ".. valor[cid] .." ".. ItemType(moeda):getName():lower() .."s. Are you sure?"}, cid)
			npcHandler.topic[cid] = 8
			playerTopic[cid]= 8
		else
			npcHandler:say({"I did not understand."}, cid)
		end
	elseif npcHandler.topic[cid] == 8 then
		if msgcontains(msg, "yes") or msgcontains(msg, "sim") then
			if player:getItemCount(moeda) >= valor[cid] then
				if player:hasMount(itemName[cid]) then
					npcHandler:say({"You already have this mount. Choose another one."}, cid)
					npcHandler.topic[cid] = 7
					playerTopic[cid]= 7
				else
					player:addMount(itemName[cid])
					player:removeItem(moeda, valor[cid])
					npcHandler:say({"Great. Here it is."}, cid)
					npcHandler.topic[cid] = 0
					playerTopic[cid]= 0
				end						
			else
				npcHandler:say({"You don't have enough event tokens..."}, cid)
				npcHandler.topic[cid] = 1
				playerTopic[cid]= 1
			end
		end	
	-- Prosseguindo com a parte de clothes
	elseif (msgcontains(msg, "clothes") or msgcontains(msg, "outfit")) and (npcHandler.topic[cid] == 1) then
		sendHello(9)
	elseif npcHandler.topic[cid] == 9 then
		if msgcontains(msg, "sim") or msgcontains(msg, "yes") then
			local arrayOutfits = showCatalog(config.outfits, config.TYPE_OUTFIT)		
			npcHandler:say({"How nice! Then browse my catalog of outfits and let me know if something interests you: ".. arrayOutfits .."."}, cid)
			npcHandler.topic[cid] = 10
			playerTopic[cid]= 10
		end
	elseif npcHandler.topic[cid] == 10 then
		local outfitTable = config.outfits[msg:lower()]
		if outfitTable then
			_outfit.male = outfitTable.idM
			_outfit.female = outfitTable.idF
			valor[cid] = outfitTable.valor
			itemName[cid] = msg
			npcHandler:say({"Good choice! If you really want the ".. itemName[cid] ..", it will cost you ".. valor[cid] .." ".. ItemType(moeda):getName():lower() .."s. Are you sure?"}, cid)
			npcHandler.topic[cid] = 11
			playerTopic[cid]= 11
		else
			npcHandler:say({"I did not understand."}, cid)
		end
	elseif npcHandler.topic[cid] == 11 then
		if msgcontains(msg, "yes") or msgcontains(msg, "sim") then
			if player:getItemCount(moeda) >= valor[cid] then
				if player:hasOutfit(_outfit.male or _outfit.female) then
					npcHandler:say({"You already have this outfit. Choose another one."}, cid)
					npcHandler.topic[cid] = 10
					playerTopic[cid]= 10
				else				
					player:addOutfit(_outfit.male)
					player:addOutfitAddon(_outfit.male, 3)
					player:addOutfit(_outfit.female)
					player:addOutfitAddon(_outfit.female, 3)					
					player:removeItem(moeda, valor[cid])
					npcHandler:say({"Great. Here it is."}, cid)
					npcHandler.topic[cid] = 0
					playerTopic[cid]= 0
				end						
			else
				npcHandler:say({"You don't have enough event tokens..."}, cid)
				npcHandler.topic[cid] = 1
				playerTopic[cid]= 1
			end
		end
	
	-- Prosseguindo com a parte de other stuff
	elseif (msgcontains(msg, "other stuff") or msgcontains(msg, "other") or msgcontains(msg, "stuff")) and (npcHandler.topic[cid] == 1) then
		sendHello(12)
	elseif ((msgcontains(msg, "yes") or msgcontains(msg, "sim")) and npcHandler.topic[cid] == 12) then
		local arrayStuff = showCatalog(config.otherStuff, config.TYPE_OTHERSTUFF)
		npcHandler:say({"How nice! Then browse my catalog of other stuff and let me know if something interests you: ".. arrayStuff .."."}, cid)
		npcHandler.topic[cid] = 13
		playerTopic[cid] = 13
	elseif npcHandler.topic[cid] == 13 then
		local otherStuffTable = config.otherStuff[msg:lower()]
		if otherStuffTable then
			valor[cid] = otherStuffTable.valor
			itemName[cid] = msg
			npcHandler:say({"Good choice! If you really want the ".. itemName[cid] ..", it will cost you ".. valor[cid] .." ".. ItemType(moeda):getName():lower() .."s. Are you sure?"}, cid)
			npcHandler.topic[cid] = 14
			playerTopic[cid]= 14
		else
			npcHandler:say({"I did not understand."}, cid)
		end
	elseif npcHandler.topic[cid] == 14 then
		if msgcontains(msg, "yes") or msgcontains(msg, "sim") then
			if player:getItemCount(moeda) >= valor[cid] then
				local ret = buyOfferStuff(player:getId(), valor[cid], itemName[cid])
				if ret == CONST_RET_STUFF.NO_OFFER then
					local arrayStuff = showCatalog(config.otherStuff, config.TYPE_OTHERSTUFF)
					npcHandler:say({"Offer not found, see my catalog: ".. arrayStuff .. "."}, cid)
					npcHandler.topic[cid] = 13
					playerTopic[cid]= 13
				elseif ret == CONST_RET_STUFF.ERROR then
					npcHandler:say({"There was an error with your purchase..."}, cid)
					npcHandler.topic[cid] = 1
					playerTopic[cid]= 1
				elseif ret == CONST_RET_STUFF.SUCCESS then
					npcHandler:say({"Great. Here it is."}, cid)
					npcHandler.topic[cid] = 12
					playerTopic[cid]= 12
				end
			else
				npcHandler:say({"You don't have enough event tokens..."}, cid)
				npcHandler.topic[cid] = 1
				playerTopic[cid]= 1
			end
		end



	else
		npcHandler:say({"I did not understand."}, cid)
	end	
	
	if msgcontains(msg, "no") or msgcontains(msg, "nao") then
		npcHandler:say({"Ah feel free to talk to me whenever I am here."}, cid)
		npcHandler.topic[cid] = 0
		playerTopic[cid]= 0
	end
	return true
end

npcHandler:setMessage(MESSAGE_WALKAWAY, 'Thanks, |PLAYERNAME|!')

npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())