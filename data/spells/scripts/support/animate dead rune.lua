function onCastSpell(creature, variant, isHotkey)
	if not creature:isPlayer() then
		return false
	end

	local position = Variant.getPosition(variant)
	local tile = Tile(position)
	if tile and creature:getSkull() ~= SKULL_BLACK then
		local corpse = tile:getTopDownItem()
		if corpse then
			local itemType = corpse:getType()
			if itemType:isCorpse() and itemType:isMovable() then
				local summonCount = creature:getSummons()
				if #summonCount < 2 then
					local monster = Game.createMonster("Skeleton", position)
					if monster then
						corpse:remove()
						monster:setMaster(creature)
						position:sendMagicEffect(CONST_ME_MAGIC_BLUE)						
					end
				else
					creature:sendCancelMessage("You can only have 2 summons per time.")
					return true
				end
			end
		end
	end

	creature:getPosition():sendMagicEffect(CONST_ME_POFF)
	creature:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
	return false
end
