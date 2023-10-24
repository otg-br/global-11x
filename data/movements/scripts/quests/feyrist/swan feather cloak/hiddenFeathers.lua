local hiddenFeathers = {
	{position = Position(33526, 32256, 7), storage = Storage.ThreatenedDreams.Valindara.hiddenFeather01},
	{position = Position(33494, 32318, 7), storage = Storage.ThreatenedDreams.Valindara.hiddenFeather02},
	{position = Position(33459, 32293, 7), storage = Storage.ThreatenedDreams.Valindara.hiddenFeather03},
	{position = Position(33470, 32251, 7), storage = Storage.ThreatenedDreams.Valindara.hiddenFeather04},
	{position = Position(33464, 32230, 7), storage = Storage.ThreatenedDreams.Valindara.hiddenFeather05},
	{position = Position(33499, 32193, 7), storage = Storage.ThreatenedDreams.Valindara.hiddenFeather06},
	{position = Position(33550, 32222, 7), storage = Storage.ThreatenedDreams.Valindara.hiddenFeather07},
	{position = Position(33589, 32196, 7), storage = Storage.ThreatenedDreams.Valindara.hiddenFeather08},
}

local featherId = 29417

function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	
	local jogadorPosition = player:getPosition()

	for _, p in pairs(hiddenFeathers) do
		local sqmPosition = p.position
		local featherTime = p.storage
		if sqmPosition == jogadorPosition then
			if player:getStorageValue(featherTime) <= os.stime() then
				player:setStorageValue(featherTime, os.stime() + 20 * 60 * 60)
				player:addItem(featherId, 5)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found some swan feathers!")
			end
		end
	end
end
