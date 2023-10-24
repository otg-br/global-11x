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
		npcHandler:setMessage(MESSAGE_GREET, "Greetings hero. I guess you came to {talk}. ")
		playerTopic[cid] = 1
	end
	npcHandler:addFocus(cid)
	return true
end

local dreamTalisman = 34625 -- id do item

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	npcHandler.topic[cid] = playerTopic[cid]
	local player = Player(cid)

	-- Começou a quest
	if msgcontains(msg, "talk") and npcHandler.topic[cid] == 1 then
			npcHandler:say({"So do you want to learn the {story} behind of this or rather talk about the task at hand? "}, cid)
			npcHandler.topic[cid] = 2
			playerTopic[cid] = 2
	elseif msgcontains(msg, "story") and npcHandler.topic[cid] == 2 then
			npcHandler:say({"Do you prefer the {long} version or the {short} version?"}, cid)
			npcHandler.topic[cid] = 3
			playerTopic[cid] = 3
	elseif msgcontains(msg, "short") and npcHandler.topic[cid] == 3 then
			npcHandler:say({"You will have to re-empower several wardstones all over the world, to weaken the beast of nightmares. ...",
			"The next step would be to enter a place known as dream scar and participate in battles, to gain access to the lower areas. ...",
			"There the nightmare beast can be challenged and defeated.",
			"So do you want to learn the story behind of this or rather talk about the {task} at hand?"}, cid)
			npcHandler.topic[cid] = 4
			playerTopic[cid] = 4
	elseif npcHandler.topic[cid] == 4 then
		if msgcontains(msg, "task") then
			if player:getStorageValue(Storage.DreamCourts.WardStones.Questline) < 1 then
				npcHandler:say({"You have to empower eight ward stones. Once charged with arcane energy, they will strengthen the Nightmare Beast's prison and at the same time weaken this terrible creature. We know about the specific location of six of those stones. ...", 
				"You can find them in the mountains of the island Okolnir, in a water elemental cave beneath Folda, in the depths of Calassa, in the forests of Feyrist and on the islands Meriana and Cormaya. ..." ,
				"The location of the other two ward stones is a bit more obscure, however. We are not completely sure where they are. You should make inquiries at an abandoned house in the Plains of Havoc. You may find it east of an outlaw camp. ..." ,
				"The other stone seems to be somewhere in Tiquanda. Search for a small stone building south-west of Banuta. Take this talisman to empower the ward stones. It will work with the six stones at the known locations. ..." ,
				"However, the empowering of the two hidden stones could be a bit more complicated. But you have to find out on yourself what to do with those stones."}, cid)
				if player:getStorageValue(Storage.DreamCourts.Main.Questline) < 1 then
					player:setStorageValue(Storage.DreamCourts.Main.Questline, 1)
				end
				player:setStorageValue(Storage.DreamCourts.WardStones.Questline, 1)
				player:setStorageValue(Storage.DreamCourts.WardStones.Count, 0)
				player:addItem(dreamTalisman, 1)
				npcHandler.topic[cid] = 0
				playerTopic[cid] = 0
			elseif player:getStorageValue(Storage.DreamCourts.WardStones.Count) >= 8 and player:getStorageValue(Storage.DreamCourts.WardStones.Questline) == 1 then
				npcHandler:say({"You empowered all eight ward stones. Well done! You may now enter the Dream Labyrinth via the portal here in the Court. Beneath it you will find the Nightmare Beast's lair. But the labyrinth is protected by seven so called Dream Doors. ...",
				"You have to find the Seven {Keys} to unlock the Seven Dream Doors down there. Only then you will be able to enter the Nightmare Beast's lair."}, cid)
				player:setStorageValue(Storage.DreamCourts.WardStones.Questline, 2)
				player:setStorageValue(Storage.DreamCourts.TheSevenKeys.Questline, 1)
				npcHandler.topic[cid] = 5
				playerTopic[cid] = 5
			elseif player:getStorageValue(Storage.DreamCourts.WardStones.Questline) >= 3 and not (player:hasOutfit(1146) or player:hasOutfit(1147)) then
				npcHandler:say({"The Nightmare Beast is slain. You have done well. The Courts of Summer and Winter will be forever grateful. For your efforts I want to reward you with our traditional dream warrior outfit. May it suit you well!"}, cid)
				for i = 1146, 1147 do
					player:addOutfit(i)
				end
				npcHandler.topic[cid] = 0
				playerTopic[cid] = 0
			else
				npcHandler:say({"I already gave your task."}, cid)
			end
		end
	elseif msgcontains(msg, "keys") and npcHandler.topic[cid] == 5 then
		npcHandler:say({"They are not literally keys but rather puzzles you have to solve or a secret mechanism you have to discover in order to open the Dream Doors. A parchment in the chest here can tell you more about it."}, cid)
	elseif msgcontains(msg, "addon") then
		if player:hasOutfit(1146) or player:hasOutfit(1147) then
			npcHandler:say({"Are you interested in one or two addons to your dream warrior outfit?"}, cid)
			npcHandler.topic[cid] = 6
			playerTopic[cid] = 6
		else
			npcHandler:say({"You don't even have the outfit."}, cid)
		end		
	elseif msgcontains(msg, "yes") then
		if npcHandler.topic[cid] == 6 then
			npcHandler:say({"I provide two addons. For the first one I need you to bring me five pomegranates. For the second addon you need an ice shield. Do you want one of these addons?"}, cid)
			npcHandler.topic[cid] = 7
			playerTopic[cid] = 7
		elseif npcHandler.topic[cid] == 7 then
			npcHandler:say({"What do you have for me: the {pomegranates} or the {ice shield}?"}, cid)
			npcHandler.topic[cid] = 8
			playerTopic[cid] = 8
		end
	elseif npcHandler.topic[cid] == 8 then
		if msgcontains(msg, "pomegranates") then
			if player:getItemCount(34662) >= 5 then
				npcHandler:say({"Very good! You gained the second addon to the dream warrior outfit."}, cid)
				player:removeItem(34662, 5)
				for i = 1146, 1147 do
					player:addOutfitAddon(i, 2)
				end
				npcHandler.topic[cid] = 0
				playerTopic[cid] = 0
			else
				npcHandler:say({"You do not have enough items."}, cid)
				npcHandler.topic[cid] = 0
				playerTopic[cid] = 0
			end
		elseif msgcontains(msg, "ice shield") then
			if player:getItemCount(34661) >= 1 then
				npcHandler:say({"Very good! You gained the first addon to the dream warrior outfit."}, cid)
				player:removeItem(34661, 1)
				for i = 1146, 1147 do
					player:addOutfitAddon(i, 1)
				end
				npcHandler.topic[cid] = 0
				playerTopic[cid] = 0
			else
				npcHandler:say({"You do not have enough items."}, cid)
				npcHandler.topic[cid] = 0
				playerTopic[cid] = 0
			end
		end
	else
		npcHandler:say({"Sorry, I didn't understand."}, cid)
	end
	return true
end



npcHandler:setMessage(MESSAGE_WALKAWAY, 'Well, bye then.')

npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
