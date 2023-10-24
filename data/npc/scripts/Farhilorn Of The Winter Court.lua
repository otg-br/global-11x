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
		npcHandler:setMessage(MESSAGE_GREET, "Hello fighter. I guess you are here to {fight} for our noble {cause}.")
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

	-- Começou a quest
	if player:getStorageValue(Storage.DreamCourts.DreamScar.Permission) < 1 then
		if msgcontains(msg, "fight") and npcHandler.topic[cid] == 1 then
			npcHandler:say({"We allow able champions of all races to fight for our cause against the challenges of the {arena}. So are you interested? I'm not interested in fancy'wordplay, so a simple {yes} or {no} will suffice!"}, cid)
			npcHandler.topic[cid] = 2
			playerTopic[cid] = 2
		elseif msgcontains(msg, "yes") and npcHandler.topic[cid] == 2 then
			npcHandler:say({"You are now able to enter the teleport."}, cid)
			player:setStorageValue(Storage.DreamCourts.DreamScar.Permission, 1)
			npcHandler.topic[cid] = 0
			playerTopic[cid] = 0
		elseif msgcontains(msg, "no") and npcHandler.topic[cid] == 2 then
			npcHandler:say({"As you wish."}, cid)
			npcHandler.topic[cid] = 1
			playerTopic[cid] = 1
		end
	end
	if msgcontains(msg, "arena") then
		npcHandler:say({"This place has always been a site where the champions of summer and winter have clashed in battle. Over the centuries this spectacle has drawn many creatures here to watch, participate and indulge in less savory activities."}, cid)
	end
	return true
end



npcHandler:setMessage(MESSAGE_WALKAWAY, 'Well, bye then.')

npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
