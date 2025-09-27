--[[
	Description: This file is part of Roulette System (refactored)
	Author: Ly�
	Discord: Ly�#8767
]]

local DatabaseRoulettePlays = require('data/scripts/events/events/magic-roulette/lib/database/roulette_plays')
local Constants = require('data/scripts/events/events/magic-roulette/lib/core/constants')
local Strings = require('data/scripts/events/events/magic-roulette/lib/core/strings')

local Functions = {}

function Functions:giveReward(player, reward)
	local item = Game.createItem(reward.id, reward.count)
	if not item then
		return false
	end

	if player:addItemEx(item) ~= RETURNVALUE_NOERROR then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, Strings.GIVE_REWARD_FAILURE)
		DatabaseRoulettePlays:update(reward.uuid, Constants.PLAY_STATUS_PENDING)
		return false
	end

	DatabaseRoulettePlays:update(reward.uuid, Constants.PLAY_STATUS_DELIVERED)
	player:sendTextMessage(MESSAGE_INFO_DESCR, Strings.GIVE_REWARD_SUCCESS:format(
		reward.count,
		ItemType(reward.id):getName()
	))

	return true
end

return Functions
