function onUse(player, item, fromPosition, itemEx, toPosition)
local inside = Position(31994, 32390, 9)
local posEntrada = Position(33047, 32712, 3)
local posSaida = Position(31994, 32390, 9)

-- SAÍDA
if item:getPosition() == posSaida then
	player:teleportTo(posEntrada)
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)	
	return true
end

-- ENTRADA
if item:getPosition() == posEntrada then
	if(player:getStorageValue(Storage.TheFirstDragon.portaoFinal) == 15) then
		player:teleportTo(inside)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)	
			else
			player:sendCancelMessage('You are not prepared yet.')
		end
	end
	return true
end
