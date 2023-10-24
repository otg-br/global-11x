local shortcuts = {
	['thais'] = {price = 100, position = Position(32310, 32210, 6)},
	['edron'] = {price = 90, position = Position(33173, 31764, 6)},
	['liberty bay'] = {price = 20, position = Position(32285, 32892, 6)},
	['yalahar'] = {price = 200, position = Position(32816, 31272, 6)}
}

local isles = {
	[1] = {isMission = true, position = Position(32032, 32464, 7)}, -- thais
	[2] = {isMission = false, position = Position(33454, 32160, 7)}, -- feyrist
	[3] = {isMission = false, position = Position(32112, 31745, 7)}, -- svargrond
	[4] = {isMission = false, position = Position(32457, 32937, 7)} -- liberty bay
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local voices = { {text = 'Passages to Thais, Darashia, Edron, Venore, Ankrahmun, Liberty Bay and Yalahar.'} }
npcHandler:addModule(VoiceModule:new(voices))

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)
	if msgcontains(msg, 'shortcut') and player:getStorageValue(Storage.secretLibrary.SmallIslands.Questline) >= 1 then
		npcHandler:say({'This passage is shorter and costs less gold - but on the other hand its is also a bit riskier. On this route there are frequent tempests. ...',
		'Few ship captains would sail this route. But if you want to take the risk, I can bring you to Thais, Edron, Liberty Bay or Yalahar for less gold than usual. Interested?'}, cid)
		npcHandler.topic[cid] = 5
	elseif msgcontains(msg, 'yes') and npcHandler.topic[cid] == 5 then
		npcHandler:say({'Do you seek a shortcut passage to {Thais} for 100 gold, to {Edron} for 90 gold, to {Liberty Bay} for 20 gold or to {Yalahar} for 200 gold?'}, cid)
		npcHandler.topic[cid] = 6
	elseif npcHandler.topic[cid] == 6 then
		local travelTo = shortcuts[msg:lower()]
		if travelTo then
			if (player:getMoney() + player:getBankBalance()) >= travelTo.price then
				local r = math.random(1, #isles)
				local chance = math.random(1, 10)
				if chance <= 3 then
					player:teleportTo(travelTo.position)					
				else
					player:teleportTo(isles[r].position)
					if isles[r].isMission and player:getStorageValue(Storage.secretLibrary.SmallIslands.Questline) < 2 then
						player:setStorageValue(Storage.secretLibrary.SmallIslands.Questline, 2)
					end
				end
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				player:removeMoneyNpc(travelTo.price)
				npcHandler:say({"Set the sails!"}, cid)
				return true
			else
				npcHandler:say({"You don't have enough money."}, cid)
			end
		end
	else
		local function addTravelKeyword(keyword, cost, destination, condition)
			if condition then
				keywordHandler:addKeyword({keyword}, StdModule.say, {npcHandler = npcHandler, text = 'I\'m sorry but I don\'t sail there.'}, condition)
			end
			local travelKeyword = keywordHandler:addKeyword({keyword}, StdModule.say, {npcHandler = npcHandler, text = 'Do you seek a passage to ' .. keyword:titleCase() .. ' for |TRAVELCOST|?', cost = cost, discount = 'postman'})
			travelKeyword:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, cost = cost, discount = 'postman', destination = destination})
			travelKeyword:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, text = 'We would like to serve you some time.', reset = true})
		end
		addTravelKeyword('edron', 150, Position(33173, 31764, 6))
		addTravelKeyword('venore', 160, Position(32954, 32022, 6))
		addTravelKeyword('yalahar', 260, Position(32816, 31272, 6), function(player) return player:getStorageValue(Storage.SearoutesAroundYalahar.PortHope) ~= 1 and player:getStorageValue(Storage.SearoutesAroundYalahar.TownsCounter) < 5 end)
		addTravelKeyword('ankrahmun', 110, Position(33092, 32883, 6))
		addTravelKeyword('darashia', 180, Position(33289, 32480, 6))
		addTravelKeyword('thais', 160, Position(32310, 32210, 6))
		addTravelKeyword('liberty bay', 50, Position(32285, 32892, 6))
		addTravelKeyword('carlin', 120, Position(32387, 31820, 6))
	end
end

-- Basic
keywordHandler:addKeyword({'sail'}, StdModule.say, {npcHandler = npcHandler, text = 'Where do you want to go - {Thais}, {Darashia}, {Venore}, {Liberty Bay}, {Ankrahmun}, {Yalahar} or {Edron?}'})
keywordHandler:addKeyword({'passage'}, StdModule.say, {npcHandler = npcHandler, text = 'Where do you want to go - {Thais}, {Darashia}, {Venore}, {Liberty Bay}, {Ankrahmun}, {Yalahar} or {Edron?}'})
keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'Im the captain of the Poodle, the proudest ship on all oceans.'})
keywordHandler:addKeyword({'captain'}, StdModule.say, {npcHandler = npcHandler, text = 'I am the captain of this ship.'})
keywordHandler:addKeyword({'port hope'}, StdModule.say, {npcHandler = npcHandler, text = "That's where we are."})
keywordHandler:addKeyword({'name'}, StdModule.say, {npcHandler = npcHandler, text = 'It\'s Charles.'})
keywordHandler:addKeyword({'svargrond'}, StdModule.say, {npcHandler = npcHandler, text = 'I\'m sorry, but we don\'t serve the routes to the Ice Islands.'})

npcHandler:setMessage(MESSAGE_GREET, "Ahoy. Where can I sail you today?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Bye.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Bye.")

npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())