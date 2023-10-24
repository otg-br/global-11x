function onThink(p, interval)		
	if not p:isPlayer() or p:getPosition() ~= CASTLE_INFO.THRONE_POSITION then
		p:unregisterEvent('Castle')
		return true
	end
	local health = (p:getHealth()*100)/p:getMaxHealth()
	local pts = math.max(p:getStorageValue(CASTLE_INFO.STORAGE), 0)
	local amount = 1 -- Just for make sure
	for i = 1, #CASTLE_INFO.CONDITIONS do
		if health <= CASTLE_INFO.CONDITIONS[i].HEALTH then
			amount = CASTLE_INFO.CONDITIONS[i].AMOUNT
		end
	end
	p:setStorageValue(CASTLE_INFO.STORAGE, pts + amount)
	p:say(pts, TALKTYPE_MONSTER_SAY)
	return true
end
