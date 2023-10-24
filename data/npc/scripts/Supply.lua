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
		npcHandler:setMessage(MESSAGE_GREET, {"Thanks for joining our beta. Speak {money}, {level} to gain 50 level's, {tibia coins}, {gold token} or {silver token}."})
	end
	npcHandler:addFocus(cid)
	return true
end

local function getExpForLevel(level)
	level = level - 1
	return ((50 * level * level * level) - (150 * level * level) + (400 * level)) / 3
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	npc = Npc(cid)

	if msgcontains(msg, "money") then
		player:addItem(2160, 100)
		npcHandler:say("I think you can now test quietly.", cid)
	elseif msgcontains(msg, "level") then
		if player:getLevel() < 1000 then
			if player:getStorageValue(Storage.Supply) < os.stime() then
				for i = 1, 50 do
					player:addExperience(getExpForLevel(player:getLevel() + 1) - player:getExperience(), false)
				end
				npcHandler:say("I think you can now test quietly.", cid)
				player:setStorageValue(Storage.Supply, os.stime() + 3)
			else
				npcHandler:say("Wait 3 seconds.", cid)
			end
		else
			npcHandler:say("I can't help you anymore.", cid)
		end
	elseif msgcontains(msg, "tibia coins") then
		if player:getTibiaCoins() < 1500 then
			if player:getStorageValue(Storage.Supply) < os.stime() then
				player:addCoinsBalance(250)
				npcHandler:say("You have won 250 tibia coins. This money will not be saved to your account.", cid)
				player:setStorageValue(Storage.Supply, os.stime() + 15)
			else
				npcHandler:say("Wait 15 seconds.", cid)
			end
		else
			npcHandler:say("You reached the maximum.", cid)
		end
	elseif msgcontains(msg, "gold token") then
		player:addItem(25377, 100)
		npcHandler:say("I think you can now test quietly.", cid)
	elseif msgcontains(msg, "silver token") then
		player:addItem(25172, 100)
		npcHandler:say("I think you can now test quietly.", cid)
	end

	return true
end


npcHandler:setMessage(MESSAGE_WALKAWAY, 'Well, bye then.')

npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
