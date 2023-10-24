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
	-- DIÁLOGO PARA FIRST DRAGON
	if msgcontains(msg, "First Dragon") and npcHandler.topic[cid] == 0 then
		npcHandler:say({"The First Dragon? The first of all of us? The Son of {Garsharak}? I'm surprised you heard about him. It is such a long time that he wandered Tibia. Yet, there are some {rumours}."}, cid)
		npcHandler.topic[cid] = 5
	elseif npcHandler.topic[cid] == 5 and msgcontains(msg, "rumours") then
		npcHandler:say({"It is told that the First Dragon had four {descendants}, who became the ancestors of the four kinds of dragons we know in Tibia. They perhaps still have knowledge about the First Dragon's whereabouts - if one could find them."}, cid)
		npcHandler.topic[cid] = 6
	elseif npcHandler.topic[cid] == 6 and msgcontains(msg, "descendants") then
		npcHandler:say({"The names of these four are {Tazhadur}, {Kalyassa}, {Gelidrazah} and {Zorvorax}. Not only were they the ancestors of all dragons after but also the primal representation of the {draconic incitements}. About whom do you want to learn more?"}, cid)
		npcHandler.topic[cid] = 7
	elseif npcHandler.topic[cid] == 7 and msgcontains(msg, "draconic incitements") then
		npcHandler:say({"Each kind of dragon has its own incitement, an important aspect that impels them and occupies their mind. For the common dragons this is the lust for {power}, for the dragon lords the greed for {treasures}. ...", 
		"The frost dragons' incitement is the thirst for {knowledge} und for the undead dragons it's the desire for {life}, as they regret their ancestor's mistake. ...",
		"These incitements are also a kind of trial that has to be undergone if one wants to {find} the First Dragon's four descendants."}, cid)
		npcHandler.topic[cid] = 8
	elseif npcHandler.topic[cid] == 8 and msgcontains(msg, "find") then
		npcHandler:say({"What do you want to do, if you know about these mighty dragons' abodes? Go there and look for a fight?"}, cid)
		npcHandler.topic[cid] = 9
	elseif npcHandler.topic[cid] == 9 and msgcontains(msg, "yes") then
		npcHandler:say({"Fine! I'll tell you where to find our ancestors. You now may ask yourself why I should want you to go there and fight them. It's quite simple: I am a straight descendant of Kalyassa herself. She was not really a caring mother. ...",
		"No, she called herself an empress and behaved exactly like that. She was domineering, farouche and conceited and this finally culminated in a serious quarrel between us. ...",
		"I sought support by my aunt and my uncles but they were not a bit better than my mother was! So, feel free to go to their lairs and challenge them. I doubt you will succeed but then again that's not my problem. ...",
		"So, you want to know about their secret lairs?"}, cid)
		npcHandler.topic[cid] = 10
	elseif npcHandler.topic[cid] == 10 and msgcontains(msg, "yes") then
		npcHandler:say({" So listen: The lairs are secluded and you can only reach them by using a magical gem teleporter. You will find a teleporter carved out of a giant emerald in the dragon lairs deep beneath the Darama desert, which will lead you to Tazhadur's lair. ...",
		"A ruby teleporter located in the western Dragonblaze Peaks allows you to enter the lair of Kalyassa. A teleporter carved out of sapphire is on the island Okolnir and leads you to Gelidrazah's lair. ...",
		"And finally an amethyst teleporter in undead-infested caverns underneath Edron allows you to enter the lair of Zorvorax."}, cid)
		-- Registrando questlog
		player:setStorageValue(Storage.TheFirstDragon.tamorilTasks, 1)
		
		-- Caçar dragons
		player:setStorageValue(Storage.TheFirstDragon.tamorilTasksPower, 0)
		player:setStorageValue(Storage.TheFirstDragon.dragonTaskCount, 0)
		
		-- Responder as perguntas
		player:setStorageValue(Storage.TheFirstDragon.tamorilTasksKnowledge, 0)
		
		-- Andar pelo mapa
		player:setStorageValue(Storage.TheFirstDragon.tamorilTasksLife, 0)
		
		-- Procurar os baús
		player:setStorageValue(Storage.TheFirstDragon.tamorilTasksTreasure, 0)
		
		npcHandler.topic[cid] = 0
	end	
	return true	
end



npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
