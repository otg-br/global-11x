local mensagens = {"AFK!", "Ausente!"}
local segundos = 20

local function doSendAutoMessage(cid, pos)
if (isCreature(cid) == true) then
 local cid = Player (cid)
	npos = cid:getPosition()
	if (pos.x == npos.x) and (pos.y == npos.y) and (pos.z == npos.z) then
		cid:say(mensagens[math.random(#mensagens)], TALKTYPE_MONSTER_SAY)
		doSendMagicEffect(getThingPos(cid), CONST_ME_POFF)
		addEvent(doSendAutoMessage, segundos*1000, cid.uid, npos)
		end
	end
end

function onSay(cid, words, param)
local stgTime = cid:getStorageValue(AUSENTE_TIMER)

if(cid:getStorageValue(stgTime) > os.stime())then
			cid:sendCancelMessage('You need to wait for 10 seconds to use this command again.')
			return false
		end
	pos = getThingPos(cid)
	cid:say(mensagens[math.random(#mensagens)], TALKTYPE_MONSTER_SAY)
	doSendMagicEffect(getThingPos(cid), CONST_ME_POFF)
	doCreatureSay(cid, "Ausente ativado.", TALKTYPE_ORANGE_1)
	doPlayerPopupFYI(cid, "Você está ausente. Ande para desativar o comando.")
	cid:setStorageValue(stgTime, os.stime() + 10)
addEvent(doSendAutoMessage, segundos*1000, cid.uid, pos)
return false
end
