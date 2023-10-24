local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
 
function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end
-- lucas cp
--[[
	explica��o para valores de contatoWar:
	�1 escolhe a guild
	�2 envia a pergunta de confirmar ou nao
	�3 da informa��es para o player sobre a anti-entrosa (somente para jogadores que n�o possuem guilds)
	�4 cancelar o invite
	�5 ir para a guerra
	
]]--

-- adicionado tabela para conversa, evitar duas pessoas trocarem a frase
talkUser = {}
local link =  configManager.getString(configKeys.URL).."?subtopic=privatewar" -- colocar o link do site para informa��es

local function greetCallback(cid)
	-- talkUser[cid]
	contatoWar = talkUser[cid]
    local player = Player(cid)
	local msg = 'Hello, '.. player:getName()..','
	local guild = player:getGuild()
	-- para jogadores que n�o tem guild
	if guild == nil then
		msg = msg..' do you want to know {details} about private war?'
	elseif player:getGuildLevel() <= 2 then
	    if not inWarPrivate(guild:getId()) then
	        msg = msg..' to configure private war, you must be the leader of the guild..'
	    else
			-- verificando as informa�oes da guerra/pode voltar ou n�o
			if getWarPrivateInfor(guild:getId()).voltarWar then
				player:setStorageValue(3840,0)
				msg = msg..' to go to the place of war, just say {go}.'
				contatoWar = 5
			else
				if player:getStorageValue(3840) == 1 then
					msg = msg..' it is no longer possible to return to the place of war.'
				else
					msg = msg..' to return to the place of war, just say {go}.'
					contatoWar = 5
				end
			end
		end
	else
		if not inWarPrivate(guild:getId()) then
			-- marcando a guerra
			msg = msg..' I am responsible for applying the private war. Are you interested in going to war with which guild?'
			contatoWar = 1
		else
			if getWarPrivateInfor(guild:getId()).voltarWar then
				player:setStorageValue(3840,0)
				msg = msg..' to go to the place of war, just say {go}.'
				contatoWar = 5
			else
				if player:getStorageValue(3840) == 1 then
					msg = msg..' it is no longer possible to return to the place of war.'
				else
					msg = msg..' to go to the place of war, just say {go}.'
					contatoWar = 5
				end
			end
		end
	end

	npcHandler:say(msg,cid)
    npcHandler:addFocus(cid)
	return false
end

local function sendOpcaoModal(player)
	local as = {30,60, 90, 120, 150, 180}
	player:registerEvent("ModalWindow_war")
	local window1 = ModalWindow(3830, "Private war", "Tempo de guerra")
	for _, a in pairs(as) do
		window1:addChoice(_, a.." minutes")
	end
	window1:addButton(100, "Select")
	window1:addButton(101, "Cancel")
	window1:setDefaultEnterButton(100)
	window1:setDefaultEscapeButton(101)
	window1:sendToPlayer(player)
	return true
end

function creatureSayCallback(cid, type, msg)
	if string.lower(msg) == 'bye' or string.lower(msg) == 'xau' or string.lower(msg) == 'tchau' then
		npcHandler:resetNpc()
		return false
	end

    if(not npcHandler:isFocused(cid)) then 
        return false
    end

	if msg:lower() == "details" then
		selfSay("The private war is an arena where two rival guilds meet for a certain time, in a deserted city. To find out more information, access this link: {".. link .."}",cid)
		return true
	end

	local player = Player(cid)
	local guild = player:getGuild()
	if guild == nil then
		selfSay("Sorry, but to move on you need to have a guild.",cid)
		return true
	end
	local myId = guild:getId()
	local idInimiga = false

	if contatoWar == 1 then
		--[[ if not GuerraAtiva(cid) then
			-- somente guilds em war podem usar o private war
			selfSay('Only guilds in active war can use private war.',cid)
			return false
		end
		]]--
		if msg:lower() == guild:getName():lower() then
			selfSay('You can not go to war with yourself.',cid)
			return true
		end
		idInimiga = db.storeQuery("SELECT `id`, `name` FROM guilds WHERE `name` = "..db.escapeString(msg))
		if idInimiga then
			guildid = result.getNumber(idInimiga,"id")
			result.free(idInimiga)
			inimiga = Guild(guildid)
			-- necessario para nao bugar a funcao de baixo
			if not inimiga or #inimiga:getMembersOnline() == 0 then
				selfSay('There is no enemy guild leader online.',cid)
				return true
			end
			if not getGuildSuperiorOnline(guildid) then
				selfSay('There is no enemy guild leader online.',cid)
				return true
			end		
			-- somente guilds em guerra e rivais podem usar
			if not player:isRivalWar(guildid) then
				selfSay('This guild is not your rival.',cid)
				return true
			end
			contatoWar = 2
			selfSay('You want to go to war with the guild {'.. inimiga:getName() ..'}?', cid)
			return true
		end
		selfSay('There is no guild with the name '.. msg ..'.', cid)
		return true
	end
	
	if contatoWar == 2 then
		if isInArray({'sim', 's', 'yes'}, msg:lower()) then
			tempoMi = 2 -- minutos
			if getGuildStorageValue(myId,3845) > os.stime() then
				-- guilds que enviam convites nao podem mandar outros no tempo menor que tempoMi minutos
				selfSay('Your guild has made or received a proposal recently. Wait '.. tempoMi ..' minutes to send again.', cid)
				return true
			end
			-- se a guild estiver em guerra n�o podera usar o sistema novamente ate quando a guerra acabar
			-- util tambem para caso o outro jogador andar ou deslogar
			if getGuildSuperiorOnline(guildid) ~= false then
				playerRival = getGuildSuperiorOnline(guildid)[1]
			else
				selfSay('There is no leader or vice-leader online of the rival guild to accept the invitation.', cid)
				return true
			end			
			if inWarPrivate(guildid) then
				selfSay('The enemy guild is already in a private war.', cid)
				return true
			end
			if inWarPrivate(myId) then
				selfSay('Your guild is already in a private war.', cid)
				return true
			end
			selfSay('You can already configure the private war with the guild {'.. inimiga:getName() ..'}', cid)
			-- criando o modal para a guild configurar a war
			setGuildStorageValue(myId,3831,guildid)
	        setGuildStorageValue(myId,3845,os.stime()+tempoMi*60)
	        setGuildStorageValue(guildid,3845,os.stime()+tempoMi*60)
			setGuildStorageValue(guildid,3831,myId)
			sendOpcaoModal(player)
			contatoWar = 1
			npcHandler:resetNpc()
			return false
		elseif isInArray({'nao', 'n', 'n�o', 'no'}, msg:lower()) then
			selfSay('All right, come back when you\'re ready.', cid)
			contatoWar = 1
			return false
		else
			selfSay('I did not understand what you mean.',cid)
			return true
		end
	end
	
    if msg:lower() == "cancel" then
        if Guild(player:getRivalInWarPrivate()) then
            cidade = cidadeWarArea[getWarPrivateInfor(myId).cidade] -- removido o inimigo da warinfor
            for _, area in pairs(cidade) do
                if isPlayerInArea(area.from, area.to) then
                    contatoWar = 5
                    selfSay('You can not cancel the invitation because there are already players in the arena. To go there just say {go}.', cid)
                    return true
                end
            end
            removerWarprivate(myId,guildid)
            selfSay("Invitation successfully canceled .", cid)
            return true
        else
            selfSay("Your guild is not at war.", cid)
            return true                
        end
    end
	
	if contatoWar == 5 then
		if msg:lower() == "go" then
			player:mandarParaWar(true)
		end
	end
	
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())