local config = {
	[1] = {uid = 3041, position = Position(32836, 32221, 14), itemId = 7844, storageOutfit = 2},
	[2] = {uid = 3042, position = Position(32837, 32229, 14), itemId = 7846, storageOutfit = 3},
	[3] = {uid = 3043, position = Position(32833, 32225, 14), itemId = 7845, storageOutfit = 4}
}

local function revertLever(position)
	local leverItem = Tile(position):getItemById(1946)
	if leverItem then
		leverItem:transform(1945)
	end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.itemid ~= 1945 then
		return true
	end
	if item:getUniqueId() == config[1].uid then
		local diamondItem = Tile(config[1].position):getItemById(2145)
		if player:getStorageValue(Storage.OutfitQuest.NightmareOutfit) >= config[1].storageOutfit then
			if diamondItem then
				diamondItem:remove(1)
				config[1].position:sendMagicEffect(CONST_ME_TELEPORT)
				Game.createItem(config[1].itemId, 1, config[1].position)
				item:transform(1946)
				addEvent(revertLever, 4 * 1000, toPosition)
			elseif not diamondItem then
				player:sendCancelMessage('You need to offer a small diamond.')
			else
				player:sendCancelMessage('You have already used this lever!')
			end
		else
			player:sendCancelMessage('You still don\'t have permission.')
		end
	elseif item:getUniqueId() == config[2].uid then
		if player:getStorageValue(Storage.OutfitQuest.NightmareOutfit) >= config[2].storageOutfit then
			local diamondItem = Tile(config[2].position):getItemById(2145)
			if diamondItem then
				diamondItem:remove(1)
				config[2].position:sendMagicEffect(CONST_ME_TELEPORT)
				Game.createItem(config[2].itemId, 1, config[2].position)
				item:transform(1946)
				addEvent(revertLever, 4 * 1000, toPosition)
			elseif not diamondItem then
				player:sendCancelMessage('You need to offer a small diamond.')
			else
				player:sendCancelMessage('You have already used this lever!')
			end
		else
			player:sendCancelMessage('You still don\'t have permission.')
		end
	elseif item:getUniqueId() == config[3].uid then
		if player:getStorageValue(Storage.OutfitQuest.NightmareOutfit) >= config[3].storageOutfit then
			local diamondItem = Tile(config[3].position):getItemById(2145)
			if diamondItem then
				diamondItem:remove(1)
				config[3].position:sendMagicEffect(CONST_ME_TELEPORT)
				Game.createItem(config[3].itemId, 1, config[3].position)
				item:transform(1946)
				addEvent(revertLever, 4 * 1000, toPosition)
			elseif not diamondItem then
				player:sendCancelMessage('You need to offer a small diamond.')
			else
				player:sendCancelMessage('You have already used this lever!')
			end
		else
			player:sendCancelMessage('You still don\'t have permission.')
		end
	end
	return true
end