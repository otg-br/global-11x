function Monster:onDropLoot(corpse)
    if hasEvent.onDropLoot then
        Event.onDropLoot(self, corpse)
    end
end

function Monster:onSpawn(position, startup, artificial)
   if hasEvent.onSpawn then
		return Event.onSpawn(self, position, startup, artificial)
    else
        if not self:getType():canSpawn(position) then
            return false
        end

        if self:getType():isRewardBoss() then
            self:setReward(true)
        end

        if not startup then
            local spec = Game.getSpectators(position, false, false)
            for _, pid in pairs(spec) do
                local monster = Monster(pid)
                if monster and not monster:getType():canSpawn(position) then
                    monster:remove()
                end
            end

            if self:getName():lower() == 'iron servant replica' then
                local chance = math.random(100)
                if Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismDiamond) >= 1 and Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismGolden) >= 1 then
                    if chance > 30 then
                        local chance2 = math.random(2)
                        if chance2 == 1 then
                            Game.createMonster('diamond servant replica', self:getPosition(), false, true)
                        elseif chance2 == 2 then
                            Game.createMonster('golden servant replica', self:getPosition(), false, true)
                        end
                        return false
                    end
                    return true
                end
                if Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismDiamond) >= 1 then
                    if chance > 30 then
                        Game.createMonster('diamond servant replica', self:getPosition(), false, true)
                        return false
                    end
                end
                if Game.getStorageValue(GlobalStorage.ForgottenKnowledge.MechanismGolden) >= 1 then
                    if chance > 30 then
                        Game.createMonster('golden servant replica', self:getPosition(), false, true)
                        return false
                    end
                end
            end
        end

        return true
    end
end
