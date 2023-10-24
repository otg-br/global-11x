local config = {
	[1] = {actionid = 14010, checkStorage = Storage.TheFirstDragon.ankrahmunChecked, text = 'You enter the circle of trees and flowers. By visiting this sacred site you\'re infused with the power of nature and plants.'},
	[2] = {actionid = 14011, checkStorage = Storage.TheFirstDragon.carlinChecked, text = 'You enter the beautiful oasis. By visiting this sacred site you\'re infused with the power of water bringing life to the desert.'},
	[3] = {actionid = 14012, checkStorage = Storage.TheFirstDragon.abdendrielChecked, text = 'You entered the suntower of Ab\'dendriel. By visiting this sacred site you\'re infused with the power of the life-giving sun.'}
}

local questStorage = Storage.TheFirstDragon.tamorilTasksLife

function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local isInQuest = player:getStorageValue(questStorage)
	if isInQuest >= 0 and isInQuest <= 3 then
		for _, p in pairs(config) do
			if item.actionid == p.actionid then
				if player:getStorageValue(p.checkStorage) < 1 then
					player:setStorageValue(p.checkStorage, 1)
					player:setStorageValue(questStorage, isInQuest + 1)
					player:say(p.text, TALKTYPE_MONSTER_SAY)	
				end
			end
		end
	end		
	return true
end

