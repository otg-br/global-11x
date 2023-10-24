local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local id_cloak = 29079 -- id do item
local id_feather = 29417 -- id da feather

local playerTopic = {}

local function greetCallback(cid)
	local player = Player(cid)
	if player then
		npcHandler:setMessage(MESSAGE_GREET, {"Greatings, mortal beigin."})
		playerTopic[cid] = 1
	end
	npcHandler:addFocus(cid)
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	
	npcHandler.topic[cid] = playerTopic[cid]
	local player = Player(cid)
	npc = Npc(cid)
	
	local pegouCloak = false
	
	if player:getStorageValue(Storage.ThreatenedDreams.Valindara.pegouCloak) == 1 then
		pegouCloak = true
	end

	if msgcontains(msg, "cloak") and npcHandler.topic[cid] == 1 then
		if player:getStorageValue(Storage.ThreatenedDreams.Valindara.Questline)~= 1 then
			npcHandler:say({"You did us a great favour, mortal being! Well, as I promised I will craft you a feathery cloak. Bring me one hundred swan feathers and I will make them into a beautiful robe. Do you have enough feathers yet?"}, cid)
			playerTopic[cid] = 2
			npcHandler.topic[cid] = 2
		elseif player:getStorageValue(Storage.ThreatenedDreams.Valindara.Questline)== 1 and not (pegouCloak) 
		and player:getStorageValue(Storage.ThreatenedDreams.Valindara.cloakTime) <= os.stime() then
			npcHandler:say({"You're returning just in time. Here, take the cloak I crafted for you. Thanks again for helping us, mortal being."}, cid)
			player:addItem(id_cloak, 1)
			player:setStorageValue(Storage.ThreatenedDreams.Valindara.pegouCloak, 1)
			playerTopic[cid] = 0
			npcHandler.topic[cid] = 0
		elseif player:getStorageValue(Storage.ThreatenedDreams.Valindara.Questline)== 1 and not (pegouCloak) 
		and player:getStorageValue(Storage.ThreatenedDreams.Valindara.cloakTime) > os.stime() then
			npcHandler:say({"Your cloak isn't ready yet."}, cid)
		else
			npcHandler:say({"Did you lost your cloak? Please, be kind."}, cid)
		end
	elseif msgcontains(msg, "yes") and npcHandler.topic[cid] == 2 then
		if player:getItemCount(id_feather) >= 100 then
			npcHandler:say({"Very good. I will craft the cloak for you. This will take some time, so return tomorrow please."}, cid)
			player:setStorageValue(Storage.ThreatenedDreams.Valindara.cloakTime, os.stime() + 24 * 60 * 60)
			player:setStorageValue(Storage.ThreatenedDreams.Valindara.Questline, 1)
			if player:getStorageValue(Storage.ThreatenedDreams.Start) < 1 then
				player:setStorageValue(Storage.ThreatenedDreams.Start, 1)
			end
			player:removeItem(id_feather, 100)
			playerTopic[cid] = 0
			npcHandler.topic[cid] = 0
		else
			npcHandler:say({"You still don't have enough feathers."}, cid)
		end
	else
		npcHandler:say({"I didn't understand."}, cid)
	end
	
	return true
end

local voices = { {text = 'Im eager for a bath in the lake.'},{text = 'Im interested in shiny precious things, if you have some.'},{text = 'No, you cant have this cloak.'} }
npcHandler:addModule(VoiceModule:new(voices))

npcHandler:setMessage(MESSAGE_SENDTRADE, "Yes, i have some potions and runes if you are interested. Or do you want to buy only potions or only runes?oh if you want sell or buy gems, your may also ask me.")
npcHandler:setMessage(MESSAGE_FAREWELL, "May enlightenment be your path, |PLAYERNAME|.")

npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())

