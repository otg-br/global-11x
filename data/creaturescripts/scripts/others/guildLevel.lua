function onKill(player, creature)
	if not player:isPlayer() then
		return true
	end
	if not creature:isMonster() or creature:getMaster() then
		return true
	end
	
	-- remove event if player wasn't in a guild
	local g = player:getGuild()
	if not g then
		player:unregisterEvent('guildLevel')
		return true
	end
	
	-- adding points
	local monsterType = creature:getType()
	if monsterType:isRewardBoss() then -- points for killing bosses (must have isrewardboss tag)
		sendKillingPoints(creature:getId(), "boss")
	elseif monsterType:experience() >= CONFIG_GUILD_MONSTERS.minMonsterExp then -- points for killing normal monsters (with exp higher than X)
		sendKillingPoints(creature:getId(), "monster")
	end
	return true
end

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not creature:isPlayer() then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	
	-- remove event if player wasn't in a guild or guild level was under max level 
	local g = creature:getGuild()
	if not g or g:getGuildLevel() < CONFIG_GUILD_LEVEL.maxLevel then
		creature:unregisterEvent('guildLevel_e')
		return true
	end
	
	-- get reward percent
	local rewards = {}
	local percent = false
	rewards = getReward(creature:getId()) or {}
	for i = 1, #rewards do
		if rewards[i].type == GUILD_LEVEL_BONUS_ELEMENTAL then
			percent = rewards[i].quantity
		end
	end
	
	-- decrease damage
	if percent and primaryType ~= COMBAT_PHYSICALDAMAGE then
		primaryDamage = primaryDamage - (primaryDamage*percent)
		creature:sendCancelMessage("Elemental damage decreased in "..percent.."% due to guild level bonus.")
	end
	
    return primaryDamage, primaryType, secondaryDamage, secondaryType
end
