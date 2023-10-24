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

	if msgcontains(msg, "the curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 2 then
		npcHandler.topic[cid] = 1
		npcHandler:say({
			"I heard about this problem. It is, indeed, very strange that only the people who live inside the town cannot be healed by purple nightshade blossoms. But I have a theory: I have done some research on ley lines. ... ",
			"You could call them ancient, straight 'paths' in the landscape which have spiritual and arcane significance. This means, on a ley line spells could be enhanced or weakened, potions or artefacts might work differently than expected. ... ",
			"One of those ley lines is crossing the town of Edron and I heavily suppose that this is the reason why the purple nightshade doesn't suffice to cure the curse. You have to find a way to potentiate the purple nightshade's efficacy. ... ",
			"I once did some research on the question 'How to increase the potency of herbal substances'. If you find my old notes they might help you."
		}, cid)
		npcHandler.topic[cid] = 1
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 3)
	elseif msgcontains(msg, "ley") and npcHandler.topic[cid] == 1 then
		npcHandler:say({
			"Most Tibian cultures have some knowledge about those straight lines that run across the landscape, connecting both, natural and sacred sites. Some also call them 'fairy paths' or 'spirit lines'. ... ",
			"As far as I know, in Zao they are called 'dragon lines'. Markers connecting the ley lines can be mounds, cairns, standing stones, stone circles, ponds, wells, shrines, temples or cross-roads. "
		}, cid)
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 3)
		npcHandler.topic[cid] = 0
	elseif msgcontains(msg, "the curse") and player:getItemCount(30678) < 1 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 3 then
		npcHandler:say("You do not have the necessary items.", cid)
		
	elseif msgcontains(msg, "the curse") and player:getItemCount(30678) >= 1 and player:getItemCount(30607) >= 1 and player:getItemCount(30606) >= 1 and player:getItemCount(30605) >= 1 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 3 then
		npcHandler:say({
			"You discovered my notes! Well done! If you find the recommended ingredients you can brew a potion that might cure the ley line enhanced form of the curse. ... ",
			"But as basic ingredient you need a special kind of nightshade. Not the purple but the crimson one. It is even rarer than the purple nightshade but Maeryn sent me one sample from Grimvale. Here, take it and put it to good use. ... ",
			"In addition, take this ancient inscription. It is a map of some of the known Tibian ley lines. Perhaps it can be of use for you. "
		}, cid)
		npcHandler.topic[cid] = 3
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 4)
		player:addItem(30699)
		player:addItem(30700)
	elseif msgcontains(msg, "ingredients") and npcHandler.topic[cid] == 3 then
		npcHandler:say("Just have a look at my notes. The required components are listed there.", cid)
		npcHandler.topic[cid] = 4
		
	elseif msgcontains(msg, "crimson") and npcHandler.topic[cid] == 4 and player:getItemCount(30678) >= 1 and player:getItemCount(30607) >= 1 and player:getItemCount(30606) >= 1 and player:getItemCount(30605) >= 1 then
		npcHandler:say({
			"This is a very rare subspecies of the purple nightshade. It grows exclusively on the small island Grimvale, and even there it is anything but common. In fact, it is so rare, it didn't even have a scientific name as of yet. ... ",
			"So, with becoming modesty, I called it 'solanacea coccinea'. "
		}, cid)
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 4)
		npcHandler.topic[cid] = 0
	elseif msgcontains(msg, "the curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 4 and player:getItemCount(30682) >= 1 and player:getItemCount(30681) >= 1 and player:getItemCount(30700) >= 1 and player:getItemCount(30695) >= 1 then
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 5)
		npcHandler:say({
			"Now you can brew a potion that might cure the ley line enhanced from the curse. You have to distil the crimson nightshade first. You can use the alchemical devices in Sinclair laboratory, here in the Academy. ...",
			"Then you have to add the silver and gold powder, in this order! At last you add the Shadow Bite Berries. "
		}, cid)
	elseif msgcontains(msg, "the curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 9 then
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 10)
		npcHandler:say("As it is a curse related to the moon, you will need a sun artefact to reverse it. A holy symbol of suon should serve this purpose. Here, take mine for the mission.", cid)
		player:addItem(30734, 1)
	elseif msgcontains(msg, "the curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 12 then
		npcHandler:say("The curse should be lifted now. Return to the ground water source beneath Cormaya to be sure.", cid)
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Oh hello. I hardly noticed you. I'm afraid I am a bit distracted at the moment.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Always be on guard, |PLAYERNAME|!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "This ungraceful haste is most suspicious!")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
