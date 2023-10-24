local foldedCarpet = {
	[25393] = 25392, [25392] = 25393, --rift carpet
	
	[26193] = 26192, [26192] = 26193, --void carpet
	
	[26087] = 26109, [26109] = 26087, --yalahahari carpet
	
	[26088] = 26110, [26110] = 26088, --white fur carpet
	
	[26089] = 26111, [26111] = 26089, --bamboo matr carpet
	
	[26371] = 26363, [26363] = 26371, --crimson carpet
	
	[26366] = 26372, [26372] = 26366, --azure carpet
	
	[26367] = 26373, [26373] = 26367, --emerald carpet
	
	[26368] = 26374, [26374] = 26368, --light parquet carpet
	
	[26369] = 26375, [26375] = 26369, --dark parquet carpet
	
	[26370] = 26376, [26376] = 26370, --marble floor
	
	[27084] = 27092, [27092] = 27084, --flowery carpet
	
	[27085] = 27093, [27093] = 27085, --Colourful Carpet
	
	[27086] = 27094, [27094] = 27086, --striped carpet
	
	[27087] = 27095, [27095] = 27087, --fur carpet
	
	[27088] = 27096, [27096] = 27088, --diamond carpet
	
	[27089] = 27097, [27097] = 27089, --patterned carpet
	
	[27090] = 27098, [27098] = 27090, --night sky carpet
	
	[27091] = 27099, [27099] = 27091, --star carpet
	
	[29350] = 29351, [29351] = 29350, --verdant carpet
	
	[29352] = 29353, [29353] = 29352, --shaggy carpet
	
	[29355] = 29354, [29354] = 29355, --mystic carpet
	
	[29356] = 29357, [29357] = 29356, --stone tile
	
	[29359] = 29358, [29358] = 29359, --wooden plank
	
	[29386] = 29387, [29387] = 29386, --wheat carpet
	
	[29388] = 29389, [29389] = 29388, --crested carpet
	
	[29390] = 29391, [29391] = 29390, --decorated carpet
	
	[36180] = 36182, [36182] = 36180, --tournament carpet
	
	[36181] = 36183, [36183] = 36181, --sublime tournament carpet

}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local carpet = foldedCarpet[item.itemid]
	if not carpet then
		return false
	end

	if fromPosition.x == CONTAINER_POSITION then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "Put the item on the floor first.")
	elseif not fromPosition:getTile():getHouse() then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You may use this only inside a house.")
	else
		item:transform(carpet)
	end
	return true
end
