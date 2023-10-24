function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local hasOutfit = player:hasOutfit(430) or player:hasOutfit(431)
	-- Plgue Mask
	if item.itemid == 13925 then
		if not hasOutfit then
			return false
		end

		if player:hasOutfit(430, 2) or player:hasOutfit(431, 2) then
			return false
		end

		player:addOutfitAddon(430, 2)
		player:addOutfitAddon(431, 2)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:say('You gained a plague mask for your outfit.', TALKTYPE_MONSTER_SAY, false, player)
		item:remove(1)

	-- Plague Bell
	elseif item.itemid == 13926 then
		if not hasOutfit then
			return false
		end

		if player:hasOutfit(430, 1) or player:hasOutfit(431, 1) then
			return false
		end

		player:addOutfitAddon(430, 1)
		player:addOutfitAddon(431, 1)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:say('You gained a plague bell for your outfit.', TALKTYPE_MONSTER_SAY, false, player)
		item:remove(1)

	-- Outfit
	else
		if hasOutfit then
			return false
		end

		for id = 13540, 13545 do
			if player:getItemCount(id) < 1 then
				return false
			end
		end

		for id = 13540, 13545 do
			player:removeItem(id, 1)
		end

		player:addOutfit(430)
		player:addOutfit(431)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:setStorageValue(Storage.OutfitQuest.Afflicted.Outfit, 1)
		player:say('You have restored an outfit.', TALKTYPE_MONSTER_SAY, false, player)
	end
	return true
end
