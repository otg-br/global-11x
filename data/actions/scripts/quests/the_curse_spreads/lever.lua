local t = {
	Position(33446, 31574, 11), -- sqm 1
	Position(33446, 31575, 11), -- sqm 2
	Position(33446, 31576, 11), -- sqm 3
	Position(33446, 31577, 11), -- sqm 4
	Position(33446, 31578, 11) -- sqm 5
}
local t2 = {
	Position(33447, 31574, 11), -- sqm 1
	Position(33447, 31575, 11), -- sqm 2
	Position(33447, 31576, 11), -- sqm 3
	Position(33447, 31577, 11), -- sqm 4
	Position(33447, 31578, 11) -- sqm 5
}
local t3 = {
	Position(33448, 31574, 11), -- sqm 1
	Position(33448, 31575, 11), -- sqm 2
	Position(33448, 31576, 11), -- sqm 3
	Position(33448, 31577, 11), -- sqm 4
	Position(33448, 31578, 11) -- sqm 5
}
local t4 = {
	Position(33449, 31574, 11), -- sqm 1
	Position(33449, 31575, 11), -- sqm 2
	Position(33449, 31576, 11), -- sqm 3
	Position(33449, 31577, 11), -- sqm 4
	Position(33449, 31578, 11) -- sqm 5
}
local t5 = {
	Position(33450, 31574, 11), -- sqm 1
	Position(33450, 31575, 11), -- sqm 2
	Position(33450, 31576, 11), -- sqm 3
	Position(33450, 31577, 11), -- sqm 4
	Position(33450, 31578, 11) -- sqm 5
}
local righttile = {
	Position(33446, 31574, 11),
	Position(33447, 31575, 11),
	Position(33448, 31576, 11),
	Position(33449, 31575, 11),
	Position(33450, 31574, 11)
}
local levers = {
	Position(33446, 31573, 11),
	Position(33447, 31573, 11),
	Position(33448, 31573, 11),
	Position(33449, 31573, 11),
	Position(33450, 31573, 11)
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local righ1 = Tile(righttile[1]):getGround()
	local righ2 = Tile(righttile[2]):getGround()
	local righ3 = Tile(righttile[3]):getGround()
	local righ4 = Tile(righttile[4]):getGround()
	local righ5 = Tile(righttile[5]):getGround()
	local threetiles1 = Tile(t2[1]):getGround()
	local threetiles2 = Tile(t3[1]):getGround()
	local threetiles3 = Tile(t4[1]):getGround()
	
	if player:getStorageValue(50734) == 1 then
		return false
	end
	
	if righ1.itemid == 457 and righ2.itemid == 457 and righ3.itemid == 457 and righ4.itemid == 457 and righ5.itemid == 457 then
		--Effects
		righ1:getPosition():sendMagicEffect(73)
		threetiles1:getPosition():sendMagicEffect(73)
		threetiles1:getPosition():sendMagicEffect(73)
		threetiles1:getPosition():sendMagicEffect(73)
		righ5:getPosition():sendMagicEffect(73)
		righ1:getPosition():sendMagicEffect(73)
		threetiles1:getPosition():sendMagicEffect(73)
		threetiles1:getPosition():sendMagicEffect(73)
		threetiles1:getPosition():sendMagicEffect(73)
		righ5:getPosition():sendMagicEffect(73)
		
		player:setStorageValue(50734, 1)
		righ2:transform(424)
		righ3:transform(424)
		righ4:transform(424)
		threetiles1:transform(457)
		threetiles2:transform(457)
		threetiles3:transform(457)
		
	else
		if item.itemid == 10044 then
			if item:getPosition().x == 33446 then
				local ground1 = Tile(t[1]):getGround()
				local ground2 = Tile(t[2]):getGround()
				local ground3 = Tile(t[3]):getGround()
				local ground4 = Tile(t[4]):getGround()
				local ground5 = Tile(t[5]):getGround()
				
				if ground1.itemid == 457 then
					ground1:transform(424)
					ground2:transform(457)
				elseif ground2.itemid == 457 then
					ground2:transform(424)
					ground3:transform(457)
				elseif ground3.itemid == 457 then
					ground3:transform(424)
					ground4:transform(457)
				elseif ground4.itemid == 457 then
					ground4:transform(424)
					ground5:transform(457)
				elseif ground5.itemid == 457 then
					ground5:transform(424)
					ground1:transform(457)
				end
			elseif item:getPosition().x == 33447 then
				local ground1 = Tile(t2[1]):getGround()
				local ground2 = Tile(t2[2]):getGround()
				local ground3 = Tile(t2[3]):getGround()
				local ground4 = Tile(t2[4]):getGround()
				local ground5 = Tile(t2[5]):getGround()
				
				if ground1.itemid == 457 then
					ground1:transform(424)
					ground2:transform(457)
				elseif ground2.itemid == 457 then
					ground2:transform(424)
					ground3:transform(457)
				elseif ground3.itemid == 457 then
					ground3:transform(424)
					ground4:transform(457)
				elseif ground4.itemid == 457 then
					ground4:transform(424)
					ground5:transform(457)
				elseif ground5.itemid == 457 then
					ground5:transform(424)
					ground1:transform(457)
				end
			elseif item:getPosition().x == 33448 then
				local ground1 = Tile(t3[1]):getGround()
				local ground2 = Tile(t3[2]):getGround()
				local ground3 = Tile(t3[3]):getGround()
				local ground4 = Tile(t3[4]):getGround()
				local ground5 = Tile(t3[5]):getGround()
				
				if ground1.itemid == 457 then
					ground1:transform(424)
					ground2:transform(457)
				elseif ground2.itemid == 457 then
					ground2:transform(424)
					ground3:transform(457)
				elseif ground3.itemid == 457 then
					ground3:transform(424)
					ground4:transform(457)
				elseif ground4.itemid == 457 then
					ground4:transform(424)
					ground5:transform(457)
				elseif ground5.itemid == 457 then
					ground5:transform(424)
					ground1:transform(457)
				end
			elseif item:getPosition().x == 33449 then
				local ground1 = Tile(t4[1]):getGround()
				local ground2 = Tile(t4[2]):getGround()
				local ground3 = Tile(t4[3]):getGround()
				local ground4 = Tile(t4[4]):getGround()
				local ground5 = Tile(t4[5]):getGround()
				
				if ground1.itemid == 457 then
					ground1:transform(424)
					ground2:transform(457)
				elseif ground2.itemid == 457 then
					ground2:transform(424)
					ground3:transform(457)
				elseif ground3.itemid == 457 then
					ground3:transform(424)
					ground4:transform(457)
				elseif ground4.itemid == 457 then
					ground4:transform(424)
					ground5:transform(457)
				elseif ground5.itemid == 457 then
					ground5:transform(424)
					ground1:transform(457)
				end
			elseif item:getPosition().x == 33450 then
				local ground1 = Tile(t5[1]):getGround()
				local ground2 = Tile(t5[2]):getGround()
				local ground3 = Tile(t5[3]):getGround()
				local ground4 = Tile(t5[4]):getGround()
				local ground5 = Tile(t5[5]):getGround()
				
				if ground1.itemid == 457 then
					ground1:transform(424)
					ground2:transform(457)
				elseif ground2.itemid == 457 then
					ground2:transform(424)
					ground3:transform(457)
				elseif ground3.itemid == 457 then
					ground3:transform(424)
					ground4:transform(457)
				elseif ground4.itemid == 457 then
					ground4:transform(424)
					ground5:transform(457)
				elseif ground5.itemid == 457 then
					ground5:transform(424)
					ground1:transform(457)
				end
			end
		end
	end	
	return item:transform(item.itemid == 10044 and 10045 or 10044)
end