local valor = 10000
local id = 2173

function onSay(cid, words, param)
	if (cid:getMoney() + cid:getBankBalance()) >= valor then
		cid:removeMoneyNpc(valor)
		cid:addItem(id, 1)
		cid:say("*!aol*", TALKTYPE_MONSTER_SAY, false, nil, cid:getPosition())
		cid:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
		else
		doPlayerSendCancel(cid, "You need "..valor.." gold coins to buy an amulet of loss.")
		return false
	end
	return false
end
