 local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()		npcHandler:onThink()		end

local function releasePlayer(cid)
	if not Player(cid) then
		return
	end

	npcHandler:releaseFocus(cid)
	npcHandler:resetNpc(cid)
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)

	if msgcontains(msg, 'boots') then
		if player:getStorageValue(Storage.DreamersChallenge.Boots) < 1 then
			npcHandler:say({"Do you have a pair of boots for me?"}, cid)
			npcHandler.topic[cid] = 2
		else
			npcHandler:say({"The north has a puzzle to complete."}, cid)
			npcHandler.topic[cid] = 0
		end
	elseif msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 2 then
			if player:removeItem(2643, 1) then
				npcHandler:say({"Oh thank you. Perhaps this will give me some comfort. It is that cold since I am dead ... for so long ...",
				"All I can give you is a little hint though: Not me but only the lost heroes can show you the way and though its only a game it might change what will happen."}, cid)
				npcHandler.topic[cid] = 0
				player:setStorageValue(Storage.DreamersChallenge.Boots, 1)
			else
				npcHandler:say({"No ... you don't. Still so cold ... so cold. "}, cid)
			end
		end
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, 'Greetings, |PLAYERNAME|! Looking for wisdom and power, eh?')
npcHandler:setMessage(MESSAGE_FAREWELL, 'Farewell.')
npcHandler:setMessage(MESSAGE_WALKAWAY, 'Farewell.')

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())


local voices = { {text = 'Alone ... so alone. So cold.'} }
npcHandler:addModule(VoiceModule:new(voices))

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = "Once I was a member of the order of the nightmare knights. Now I am but a shadow who walks these cold halls."})

npcHandler:setMessage(MESSAGE_GREET, "I feel you. I hear your thoughts. You are ... alive.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Alone ... so alone. So cold.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Alone ... so alone. So cold.")

npcHandler:addModule(FocusModule:new())
