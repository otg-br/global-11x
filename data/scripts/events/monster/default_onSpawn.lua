local event = Event()
event.onSpawn = function(monster, position, startup, artificial)
	if not monster:getType():canSpawn(position) then
		return false
	end

	if monster:getType():isRewardBoss() then
		monster:setReward(true)
	end

	if not startup then
		local spec = Game.getSpectators(position, false, false)
		for _, pid in pairs(spec) do
			local specMonster = Monster(pid)
			if specMonster and not specMonster:getType():canSpawn(position) then
				specMonster:remove()
			end
		end

		if monster:getName():lower() == 'iron servant replica' then
			local chance = math.random(100)
			if Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismDiamond) >= 1 and Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismGolden) >= 1 then
				if chance > 30 then
					local chance2 = math.random(2)
					if chance2 == 1 then
						Game.createMonster('diamond servant replica', monster:getPosition(), false, true)
					elseif chance2 == 2 then
						Game.createMonster('golden servant replica', monster:getPosition(), false, true)
					end
					return false
				end
				return true
			end
			if Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismDiamond) >= 1 then
				if chance > 30 then
					Game.createMonster('diamond servant replica', monster:getPosition(), false, true)
					return false
				end
			end
			if Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismGolden) >= 1 then
				if chance > 30 then
					Game.createMonster('golden servant replica', monster:getPosition(), false, true)
					return false
				end
			end
		end
	end

	return true
end
event:register()
