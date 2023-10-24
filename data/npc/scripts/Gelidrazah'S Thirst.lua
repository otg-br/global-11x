local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

local function greetCallback(cid)
	npcHandler.topic[cid] = 0
	return true
end


		
local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	
	local player = Player(cid)
	-- CHECAR SE ELE ESTÁ NA QUEST
	if msgcontains(msg, "yes") and npcHandler.topic[cid] == 0 then
		if player:getStorageValue(Storage.TheFirstDragon.tamorilTasksKnowledge) < 3 then
			npcHandler:say({
				'There are three questions. First: What is the name of the princess who fell in love with a Thaian nobleman during the regency of pharaoh Uthemath? Second: Who is the author of the book \'The Language of the Wolves\'? ...',
				'Which ancient Tibian race reportedly travelled the sky in cloud ships? Can you answer these questions?'
			}, cid)
			npcHandler.topic[cid] = 1		
		else
			npcHandler:say({
			'I don\'t have questions for you.'}, cid)
			return false
		end
			
			
	-- SE ESTIVER NA QUEST
		elseif npcHandler.topic[cid] == 1 and msgcontains(msg, "yes") then
		npcHandler:say({"So I ask you: What is the name of the princess who fell in love with a Thaian nobleman during the regency of pharaoh Uthemath?"}, cid)
		npcHandler.topic[cid] = 2
		elseif npcHandler.topic[cid] == 2 and msgcontains(msg, "Tahmehe") then
		npcHandler:say({"That's right. Listen to the second question: Who is the author of the book 'The Language of the Wolves'?"}, cid)
		npcHandler.topic[cid] = 3
		elseif npcHandler.topic[cid] == 3 and msgcontains(msg, "Ishara") then
		npcHandler:say({"That's right. Listen to the third question: Which ancient Tibian race reportedly travelled the sky in cloud ships?"}, cid)
		npcHandler.topic[cid] = 4
		elseif npcHandler.topic[cid] == 4 and msgcontains(msg, "Svir") then
		npcHandler:say({"That is correct. You satisfactorily answered all questions. You may pass and enter Gelidrazah's lair."}, cid)
		player:setStorageValue(Storage.TheFirstDragon.tamorilTasksKnowledge, 3)
		end
	return true
end



npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
