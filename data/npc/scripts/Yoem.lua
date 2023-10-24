local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)

	if msgcontains(msg, "curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 7 then
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 8)
		npcHandler:say({
			"But now it's obvious that there has to be another way. If you ask me: I guess its the ground water. Someone has to enter the caverns underneath cormaya and investigate. ...",
			"In the east of the island there are tunnels where we often spot were-beasts at night. Perhaps you should start there."
		}, cid)
	elseif msgcontains(msg, "curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 9 then
		npcHandler:say("So I was right, it is the ground water! Please try to reverse this contamination. Unfortunately, I don't know anything about magic or arcane matters. But you could ask somebody at the Magic Academy of Edron.", cid)
	elseif msgcontains(msg, "curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 12 then
		npcHandler:say("I had a guess that Milos would know something about the lifting of curses. I hope you will succeed!", cid)
	elseif msgcontains(msg, "curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 14 then
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 15)
		npcHandler:say("You succeeded! Thank you very much for your help, my friend. Please return to Edron and tell Daniel Steelsoul about it, he will be interested in this outcome, too.", cid)
	end
	
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Hello |PLAYERNAME|! Do you need some equipment for your house?")
npcHandler:setMessage(MESSAGE_SENDTRADE, "Have a look. Most furniture comes in handy kits. Just use them in your house to assemble the furniture. Do you want to see only a certain {type} of furniture?")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())

