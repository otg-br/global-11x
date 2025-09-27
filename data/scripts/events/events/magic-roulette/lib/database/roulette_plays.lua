--[[
	Description: This file is part of Roulette System (refactored)
	Author: Lyµ
	Discord: Lyµ#8767
]]

local DatabaseRoulettePlays = {}

function DatabaseRoulettePlays:create(uuid, playerId, reward) 
	db.query(('INSERT INTO roulette_plays (player_id, uuid, reward_id, reward_count) VALUES (%d, %s, %d, %d)'):format(
		playerId,
		db.escapeString(uuid),
		reward.id,
		reward.count
	))
end

function DatabaseRoulettePlays:update(uuid, status)
	db.query(('UPDATE roulette_plays SET status = %d, updated_at = %d WHERE uuid = %s'):format(
		status,
		os.time(),
		db.escapeString(uuid)
	))
end

function DatabaseRoulettePlays:select(uuid)
	local resultId = db.storeQuery(('SELECT player_id, reward_id, reward_count FROM roulette_plays WHERE uuid = %s'):format(
		db.escapeString(uuid)
	))

	if resultId then
		local playerGuid = result.getNumber(resultId, 'player_id')
		local rewardId = result.getNumber(resultId, 'reward_id')
		local rewardCount = result.getNumber(resultId, 'reward_count')
		result.free(resultId)

		return {
			playerGuid = playerGuid,
			uuid = uuid,
			id = rewardId,
			count = rewardCount
		}
	end
end

function DatabaseRoulettePlays:selectPendingPlayRewardsByPlayerGuid(guid)
	local rewards = {}

	local resultId = db.storeQuery(('SELECT uuid, reward_id, reward_count FROM roulette_plays WHERE player_id = %d AND status = 1'):format(
		guid
	))

	if resultId then
		repeat
			local uuid = result.getString(resultId, 'uuid')
			local rewardId = result.getNumber(resultId, 'reward_id')
			local rewardCount = result.getNumber(resultId, 'reward_count')
			
			rewards[#rewards + 1] = {
				uuid = uuid,
				id = rewardId,
				count = rewardCount
			}
		until not result.next(resultId)
		result.free(resultId)
	end

	return rewards
end

function DatabaseRoulettePlays:updateAllRollingToPending()
	db.query('UPDATE roulette_plays SET status = 1 WHERE status = 0')
end

return DatabaseRoulettePlays
