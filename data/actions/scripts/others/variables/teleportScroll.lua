local options = {
	[1] = "My house",
	[2] = "Any city",
}

local function sendModal(pid)
	local p = Player(pid)
	if not p then return true end
	p:registerEvent("modalWindow_teleportScroll")
	local title = "Choose an option below"
	local message = "Where do you want to go? :)"
	local window = ModalWindow(Modal.teleportScroll, title, message)
	window:addButton(100, "Okay")
	window:addButton(101, "Close")	
	for i = 1, #options do
		window:addChoice(i, options[i])
	end
	window:setDefaultEnterButton(100)
	window:setDefaultEscapeButton(101)	
	window:sendToPlayer(p)
	return true
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if (player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT) or player:isPzLocked()) 
		and not (Tile(player:getPosition()):hasFlag(TILESTATE_PROTECTIONZONE)) then
		player:sendCancelMessage("You can't use this when you're in a fight.")
		return true
	elseif player:getStorageValue(TEMPLE_TELEPORT_SCROLL) > os.stime() then
		player:sendCancelMessage("You must wait 5 minutes before use this item again.")
		return true
	end
	if item.actionid < 100 then
		player:teleportTo(player:getTown():getTemplePosition())
		player:setStorageValue(TEMPLE_TELEPORT_SCROLL, os.stime() + 5*60)
		item:remove(1)
		return true
	else
		if player:getVipDays() > os.stime() then
			player:say("*using premium teleport scroll*")
			player:getPosition():sendMagicEffect(CONST_ME_TUTORIALSQUARE)
			sendModal(player:getId())
		else
			player:sendCancelMessage("You must be vip account to use this scroll.")
		end
	end
	return true
end
