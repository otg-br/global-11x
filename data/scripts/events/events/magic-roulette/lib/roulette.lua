--[[
	Description: This file is part of Roulette System (refactored)
	Author: Ly�
	Discord: Ly�#8767
]]

local Config = require('data/scripts/events/events/magic-roulette/config')
local Animation = require('data/scripts/events/events/magic-roulette/lib/animation')
local DatabaseRoulettePlays = require('data/scripts/events/events/magic-roulette/lib/database/roulette_plays')
local Strings = require('data/scripts/events/events/magic-roulette/lib/core/strings')

local Roulette = {}

function Roulette:startup()
	DatabaseRoulettePlays:updateAllRollingToPending()

	self.slots = Config.slots
	for actionid, slot in pairs(self.slots) do
		slot:generatePositions()
		slot:loadChances(actionid)
	end
end

function Roulette:roll(player, slot)
	if slot:isRolling() then
		player:sendCancelMessage(Strings.WAIT_TO_SPIN)
		return false
	end

	local reward = slot:generateReward()
	if not reward then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, Strings.GENERATE_REWARD_FAILURE)	
		return false
	end

	local needItem = slot:getNeedItem()
	local needItemName = ItemType(needItem.id):getName()

	if not player:removeItem(needItem.id, needItem.count) then
		player:sendTextMessage(MESSAGE_EVENT_DEFAULT, Strings.NEEDITEM_TO_SPIN:format(
			needItem.count,
			needItemName
		))
		return false
	end

	local playerName = player:getName()
	
	slot.uuid = uuid()
	DatabaseRoulettePlays:create(slot.uuid, player:getGuid(), reward)
	
	slot:setRolling(true)
	slot:clearDummies()

	player:setMovementBlocked(true)
	player:setStorageValue(1000, 1)
	
	slot.centerPosition:sendMagicEffect(CONST_ME_MAGIC_GREEN)

	local onFinish = function()
		slot:deliverReward()
		slot:setRolling(false)
	
		player:setMovementBlocked(false)
		player:setStorageValue(1000, 0)
		
		slot.centerPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)

		if reward.rare then
			slot.centerPosition:sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
			player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
			
			Game.broadcastMessage(Strings.GIVE_REWARD_FOUND_RARE:format(
				playerName,
				reward.count,
				ItemType(reward.id):getName()
			), MESSAGE_EVENT_ADVANCE)
		end
	end
	
	Animation:start({
		slot = slot,
		reward = reward,
		onFinish = onFinish
	})
	return true
end

function Roulette:getSlot(actionid)
	return self.slots[actionid]
end

return Roulette
