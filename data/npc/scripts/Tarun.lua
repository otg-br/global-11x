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
npcHandler:setMessage(MESSAGE_GREET, "Greetings!")
playerTopic[cid] = 1
npcHandler:addFocus(cid)
end	
return true
end



local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	npcHandler.topic[cid] = playerTopic[cid]
	local player = Player(cid)

	if msgcontains(msg, "mission") then
		if player:getStorageValue(Storage.adventurersGuild.theLostBrother.Mission) < 1 then
			npcHandler:say({"My brother is missing. I fear, he went to this evil palace north of here. A place of great beauty, certainly filled with riches and luxury. But in truth it is a threshold to hell and demonesses are after his blood. ... ",
			"He is my brother, and I am deeply ashamed to admit but I don't dare to go there. Perhaps your heart is more courageous than mine. Would you go to see this place and search for my brother?"}, cid)	
			npcHandler.topic[cid] = 2
			playerTopic[cid] = 2
		elseif player:getStorageValue(Storage.adventurersGuild.theLostBrother.Mission) == 2 then
			npcHandler:say({"So, he is dead as I feared. I warned him to go with this woman, but he gave in to temptation. My heart darkens and moans. But you have my sincere thanks. ...",
 			"Without your help I would have stayed in the dark about his fate. Please, take this as a little recompense."}, cid)
 			player:addExperience(3000)
 			player:addItem(2156) -- Red Gem
 			player:setStorageValue(Storage.adventurersGuild.theLostBrother.Mission, 3)
		end
	elseif msgcontains(msg, "yes") then
		if playerTopic[cid] == 2 or npcHandler.topic[cid] == 2 then
			if player:getStorageValue(Storage.adventurersGuild.Questline) < 1 then
	   			player:setStorageValue(Storage.adventurersGuild.Questline, 1)
			end
			player:setStorageValue(Storage.adventurersGuild.theLostBrother.Mission, 1)
			npcHandler:say({"I thank you! This is more than I could hope!"}, cid)
			npcHandler.topic[cid] = 0
			playerTopic[cid] = 0
		end
	end
return true
end

npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

local function onTradeRequest(cid)
	return true
end

npcHandler:setCallback(CALLBACK_ONTRADEREQUEST, onTradeRequest)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())