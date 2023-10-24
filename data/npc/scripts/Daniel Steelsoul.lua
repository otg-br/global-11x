local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local condition = Condition(CONDITION_FIRE)
condition:setParameter(CONDITION_PARAM_DELAYED, 1)
condition:addDamage(14, 1000, -10)

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)
	if isInArray({"fuck", "idiot", "asshole", "ass", "fag", "stupid", "tyrant", "shit", "lunatic"}, msg) then
		npcHandler:say("Take this!", cid)
		player:getPosition():sendMagicEffect(CONST_ME_EXPLOSIONAREA)
		player:addCondition(condition)
		npcHandler:releaseFocus(cid)
		npcHandler:resetNpc(cid)
	elseif msgcontains(msg, "mission") then
		if player:getStorageValue(Storage.TibiaTales.AgainstTheSpiderCult) < 1 then
			npcHandler.topic[cid] = 1
			npcHandler:say("Very good, we need heroes like you to go on a suici.....er....to earn respect of the authorities here AND in addition get a great reward for it. Are you interested in the job?", cid)
		elseif player:getStorageValue(Storage.TibiaTales.AgainstTheSpiderCult) == 5 then
			player:setStorageValue(Storage.TibiaTales.AgainstTheSpiderCult, 6)
			npcHandler.topic[cid] = 0
			player:addItem(7887, 1)
			npcHandler:say("What? YOU DID IT?!?! That's...that's...er....<drops a piece of paper. You see the headline 'death certificate'> like I expected!! Here is your reward.", cid)
		end
	elseif msgcontains(msg, "yes") then
		if npcHandler.topic[cid] == 1 then
			player:setStorageValue(Storage.TibiaTales.DefaultStart, 1)
			player:setStorageValue(Storage.TibiaTales.AgainstTheSpiderCult, 1)
			npcHandler:say({
				"Very well, maybe you know that the orcs here in Edron learnt to raise giant spiders. It is going to become a serious threat. ...",
				"The mission is simple: go to the orcs and destroy all spider eggs that are hatched by the giant spider they have managed to catch. The orcs are located in the south of the western part of the island."
			}, cid)
		elseif npcHandler.topic[cid] == 3 then
			npcHandler:say({
			"I'm very relieved to hear that. The most important thing right now is to cure the curse of as many affected people as possible. Maeryn already told me that the purple nightshade is able to revert the effects of lycanthropy. ... ",
			"We tried this but it worked only partially. Strangely, we were able to cure the people living outside the town in the more rural parts of Edron. But there are also some affected people in the town itself and the nightshade doesn't have any effect... ",
			"I'm neither a sage nor a magician. But I'm the one who is supposed to find a solution for this problem. Please pay a visit to the Magic Academy of Edron. Perhaps one of the mages there can help you."
			}, cid)
			player:setStorageValue(Storage.CurseSpreads.roteiroquest, 2)
			npcHandler.topic[cid] = 0
		end
	elseif msgcontains(msg, "curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 15 then
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 16)
		npcHandler:say("Please seek out the subterranean caves of the lycanthropes on Edron and Cormaya and kill the alpha leader of each kind of were-beast, five altogether. This should waken them enough to hold them at bay for quite a while.", cid)
	elseif msgcontains(msg, "curse") and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 1 then
		npcHandler:say({
			"Yes, recently we have a major problem here on Edron. Strange proceedings are troubling me as well as the common citizens. With each full moon, monsters are roaming the woods - monsters that we only knew from tales until now. ... ",
			"They look like badgers and foxes who are transforming into humans. Unfortunately, it's the other way round: Peaceful citizens transform into feral beasts as soon as the moon is full. ... ",
			"Some hunters even claim that they have spotted monstrous humanoid boars, wolves and bears. I know what is going on on Grimvale so I sent a messenger to Maeryn. She confirmed what I already feared: Those creatures are were-beasts. ... ",
			"The so-called Curse of the Full Moon is spreading and reached Edron. I asked Maeryn for help but she has plenty of trouble on Grimvale and can't leave the island. ...",
			"Do you know something about this curse and - even more important - would you be willing to help us?"
		}, cid)
		npcHandler.topic[cid] = 3
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 2)
	elseif msgcontains(msg, "potion") and player:getItemCount(30696) >= 1 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 6 then
		player:removeItem(30696, 1)
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 7)
		npcHandler:say({
			"You did a great job! I really have hope this potion may cure the infected people here in town. At least i have trust in Master Milos experience. But theres another problem: Cormaya ...  ",
			"The curse reached Cormaya, too. Please go there and talk to Yoem. "
		}, cid)
	elseif msgcontains(msg, "were") and player:getStorageValue(50745) == 1 and player:getStorageValue(50746) == 1 and player:getStorageValue(50747) == 1 and player:getStorageValue(50748) == 1 and player:getStorageValue(50749) == 1 and player:getStorageValue(Storage.CurseSpreads.roteiroquest) == 16 then
		player:addItem(30800, 1)
		player:setStorageValue(Storage.CurseSpreads.roteiroquest, 17)
		npcHandler:say({
			"You defeated the five alpha leaders! Well done, this should weaken them enough to hold them at bay for quite a while. Please take this pendant in return, it may be of use for you. ...",
			"Banor grant that this is just unfounded gossip and that the curse didn't spread further. Well, I guess, we will find out soon. Edron, for the thing begin, is a safer place now, thanks to you. "
		}, cid)
	end
	
	return true
end

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = "I am the governor of this isle, Edron, and grandmaster of the Knights of Banor's Blood."})
keywordHandler:addKeyword({'king'}, StdModule.say, {npcHandler = npcHandler, text = "LONG LIVE THE KING!"})

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET, "Greetings and Banor be with you, |PLAYERNAME|!")
npcHandler:setMessage(MESSAGE_FAREWELL, "PRAISE TO BANOR!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "PRAISE TO BANOR!")
npcHandler:addModule(FocusModule:new())
