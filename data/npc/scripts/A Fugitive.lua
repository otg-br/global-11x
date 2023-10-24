local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local vocation = {}
local town = {}
PRICE = 100

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

local function greetCallback(cid)
	local player = Player(cid)
	local curboost = math.max(player:getStorageValue(61924) - os.stime(), 0)
	local level = player:getLevel()
	if player:getMoney() < PRICE and curboost > 0 then
		npcHandler:say("Infrator! Volte quando tiver dinheiro para a fiança ou quando sua pena acabar!", cid)
		npcHandler:resetNpc(cid)
		return false
	elseif level > 100000 then
		npcHandler:say(player:getName() ..", eu não posso deixar você sair.", cid)
		npcHandler:resetNpc(cid)
		return false
	else
		npcHandler:setMessage(MESSAGE_GREET, player:getName() ..", Você poderá sair quando acabar a sua {pena}, ou pagando a {fiança}? Diga {yes}.")
	end
	return true
end

local function creatureSayCallback(cid, type, msg)
	local curboost = math.max(player:getStorageValue(61924) - os.stime(), 0)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	if npcHandler.topic[cid] == 0 then
		if msgcontains(msg, "yes") then
			if curboost > 0 then
			npcHandler:say("Sua pena ainda nao acabou... deseja pagar a fiança? Diga {pagar}.", cid)
			npcHandler.topic[cid] = 1
			else
			npcHandler:say("SUA PENA ACABOU!", cid)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			local oldtown = player:getStorageValue(61922)
			player:setStorageValue(61924, -1)
			player:teleportTo(Town(oldtown):getTemplePosition())
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			end
		end

	elseif npcHandler.topic[cid] == 1 then
	
		if msgcontains(msg, "pagar") then
		if player:removeMoneyNpc(PRICE) then
			npcHandler:say("Então que seja!", cid)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			local oldtown = player:getStorageValue(61922)
			player:setStorageValue(61924, -1)
			player:teleportTo(Town(oldtown):getTemplePosition())
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		end
		else
			npcHandler:say("ENTAO OQUÊ? Cadê a grana?", cid)
			npcHandler.topic[cid] = 0
		
		end
	end
	return true
end

local function onAddFocus(cid)
end

local function onReleaseFocus(cid)
end

npcHandler:setCallback(CALLBACK_ONADDFOCUS, onAddFocus)
npcHandler:setCallback(CALLBACK_ONRELEASEFOCUS, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "Volte aqui quando entender que {bot} é para noobs!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Ignora mesmo, vai apodrecer na prisão...")
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
