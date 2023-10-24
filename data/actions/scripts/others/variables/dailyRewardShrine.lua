function onUse(player, item, fromPosition, itemEx, toPosition)
	-- DailyReward.loadDailyReward(player,0)
	player:sendRewardWindow()
	return true
end
