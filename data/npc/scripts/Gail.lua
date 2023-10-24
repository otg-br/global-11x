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
	playerTopic[cid] = 1
	npcHandler:addFocus(cid)
	return true
end


local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	npcHandler.topic[cid] = playerTopic[cid]
	local player = Player(cid)

	if msgcontains(msg, "daughter") then
		if player:getStorageValue(Storage.secretLibrary.Asuras.Questline) == 3 then
			npcHandler:say({"I always feared that I lost her. And yet, all those years, I still had a gleam of hope. I'm devasted to learn about her fate - but at least I have certainly now. Thank you for telling me."}, cid)
			player:setStorageValue(Storage.secretLibrary.Asuras.Questline, 4)
		else
			npcHandler:say({"I lost my poor daughter years ago. She wanted to become a member of the Explorer Society and ventured into the deep jungle. Whether she found something or something found her. It was obviously dangerous and baleful. She never returned."}, cid)
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