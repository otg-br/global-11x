 local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local playerTopic = {}
local quantidade = {}

local function greetCallback(cid)
	local player = Player(cid)
	if player then
		npcHandler:setMessage(MESSAGE_GREET, {"Oh hello. Nice to see some civilized person down {here}."})
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
	
	-- Conseguindo o Mallet
	if msgcontains(msg, "mallet") and npcHandler.topic[cid] == 1 then
		if (player:getItemCount(30759) >= 1 and player:getItemCount(30760) >= 1
		and player:getItemCount(30761) >= 1) then
			npcHandler:say({"Marvelous! You have found all parts of the mallet! It only takes some gnomish ingeniuty and mushroom glue to fix it. Shall I give it a try?"}, cid)
			playerTopic[cid] = 10
			npcHandler.topic[cid] = 10
		else
			npcHandler:say({"You need to get those three mallet parts for me, then I'll help you to fix it."}, cid)
			playerTopic[cid] = 1
			npcHandler.topic[cid] = 1
		end
	elseif msgcontains(msg, "yes") and npcHandler.topic[cid] == 10 then
		if (player:getItemCount(30759) >= 1 and player:getItemCount(30760) >= 1
		and player:getItemCount(30761) >= 1) then
			npcHandler:say({"Aaaand there it is! As good as new!"}, cid)
			playerTopic[cid] = 1
			npcHandler.topic[cid] = 1
			-- Adicionando e removendo itens!
			player:addItem(30758, 1)
			for i = 30759, 30761 do
				player:removeItem(i, 1)
			end
		else
			npcHandler:say({"Don't waste my time."}, cid)
			playerTopic[cid] = 1
			npcHandler.topic[cid] = 1
		end
	end

	return true
end



npcHandler:setMessage(MESSAGE_WALKAWAY, 'Well, bye then.')

npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())