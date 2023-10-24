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
		npcHandler:setMessage(MESSAGE_GREET, "Hello, |PLAYERNAME|. I'm here to give you the chance to prove your worth. If you are interested, just say {challenge}.")
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
	
	if msgcontains(msg, "challenge") then
	npcHandler:say({"Good. Every warrior needs to be prepared to fight any kind of creature, do you agree? ...",
	"This challenge will test you. You basically need to survive several waves of monsters. There are three levels of difficulty: {white}, the easiest, {blue}, the standard difficulty, and {red}, the impossible."}, cid)
	playerTopic[cid] = 2
	npcHandler.topic[cid] = 2	
	elseif npcHandler.topic[cid] == 2 and msgcontains(msg, "white") then
	npcHandler:say({"Even if the color white represents peace, that does not mean that the monsters will pity you. ...",
	"To give you access to the white challenge, I'll need 10,000 gold coins. Do you have this value?"}, cid)
	playerTopic[cid] = 5
	npcHandler.topic[cid] = 5
	elseif npcHandler.topic[cid] == 5 then
		if msgcontains(msg, "yes") then
			if player:getLevel() >= 50 and player:getLevel() < 201 then
				if player:getStorageValue(Storage.desafioMonstros.easyPermission) < 1 then
					if (player:getMoney() + player:getBankBalance()) >= 10000 then
					   player:removeMoneyNpc(10000)
					   player:setStorageValue(Storage.desafioMonstros.easyPermission, 1)
					   npcHandler:say({"Now you are able to pass trougth the white teleport."}, cid)
					   player:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
					else
					npcHandler:say({"You don't have enough money."}, cid)
					end
				else
				npcHandler:say({"You already have the permission."}, cid)
				end
			else
			npcHandler:say({"You don't have enough level. Check our website to see the level limit of this event."}, cid)
			end
		end
	elseif npcHandler.topic[cid] == 2 and msgcontains(msg, "blue") then
	npcHandler:say({"Even if the color blue represents calm, that does not mean that you will not have problems. ...",
	"To give you access to the blue challenge, I'll need 25,000 gold coins. Do you have this value?"}, cid)
	playerTopic[cid] = 10
	npcHandler.topic[cid] = 10
	elseif npcHandler.topic[cid] == 10 then
		if msgcontains(msg, "yes") then
			if player:getLevel() > 201 and player:getLevel() < 301 then
				if player:getStorageValue(Storage.desafioMonstros.mediumPermission) < 1 then
					if (player:getMoney() + player:getBankBalance()) >= 25000 then
					   player:removeMoneyNpc(25000)
					   player:setStorageValue(Storage.desafioMonstros.mediumPermission, 1)
					  npcHandler:say({"Now you are able to pass trougth the white teleport."}, cid)
					  player:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
					else
					npcHandler:say({"You don't have enough money."}, cid)
					end
				else
				npcHandler:say({"You already have the permission."}, cid)
				end
			else
			npcHandler:say({"You don't have enough level. Check our website to see the level limit of this event."}, cid)
			end
		end
	elseif npcHandler.topic[cid] == 2 and msgcontains(msg, "red") then
	npcHandler:say({"You know the meaning of red color, right? I do not need to warn you that it will be dangerous. ...",
	"To give you access to the red challenge, I'll need 50,000 gold coins. Do you have this value?"}, cid)
	playerTopic[cid] = 15
	npcHandler.topic[cid] = 15
	elseif npcHandler.topic[cid] == 15 then
		if msgcontains(msg, "yes") then
			if player:getLevel() > 300 then
				if player:getStorageValue(Storage.desafioMonstros.hardPermission) < 1 then
					if (player:getMoney() + player:getBankBalance()) >= 50000 then
					   player:removeMoneyNpc(50000)
					   player:setStorageValue(Storage.desafioMonstros.hardPermission, 1)
					   npcHandler:say({"Now you are able to pass trougth the white teleport."}, cid)
					   player:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
					else
					npcHandler:say({"You don't have enough money."}, cid)
					end
				else
				npcHandler:say({"You already have the permission."}, cid)
				end
			else
			npcHandler:say({"You don't have enough level. Check our website to see the level limit of this event."}, cid)
			end
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