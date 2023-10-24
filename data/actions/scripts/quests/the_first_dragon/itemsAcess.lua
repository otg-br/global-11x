-- Portão The First Dragon
local portaoItems = {
	[27607] = {storage = 0},
	[27609] = {base = 1},
	[27610] = {base = 2},
	[27608] = {base = 3},
}
local posPiso = Position(33047, 32712, 3)

function onUse(player, item, position, target, targetPosition)
	local items = portaoItems[item:getId()]
	if(items and target:getPosition() == posPiso) then
		local killBoss = 0
		local stgBase = (player:getStorageValue(Storage.TheFirstDragon.quatroDragoes) < 0 and 0 or player:getStorageValue(Storage.TheFirstDragon.quatroDragoes))
		local bossBit = NewBit(stgBase)	
		for i = 0, 3 do
			local base = bit.lshift(1, i)
			if(bossBit:hasFlag(base))then
				killBoss = killBoss + 1
			end		
		end
		--broadcastMessage(""..killBoss)
		if killBoss < 4 then
			player:sendCancelMessage('What are you doing here, fool?')
			return true
		end	
		local stg5 = (player:getStorageValue(Storage.TheFirstDragon.portaoFinal) < 0 and 0 or player:getStorageValue(Storage.TheFirstDragon.portaoFinal))		
		local itemsMeta = NewBit(stg5)
		local base = bit.lshift(1, items.base)			
		if(itemsMeta:hasFlag(base))then
			player:sendCancelMessage('You already sacrified this item.')
			return true
		end
			
		itemsMeta:updateFlag(base)
		posPiso:sendMagicEffect(CONST_ME_HITBYFIRE)
		player:setStorageValue(Storage.TheFirstDragon.portaoFinal, itemsMeta:getNumber())
	
		item:remove()		
		return true
	end
end
