local itemsid = {
	[2743] = {monster = "spirit of fertility", mainPosition = Position(33595, 31023, 14), action = "transform", monsterTo = "angry plant", delete = false, message = "The fertile spirit brings a plant monster to life!"},
	[2805] = {monster = "unbeatable dragon", action = "transform", monsterTo = "somewhat beatable", delete = true, message = "An allergic reaction weakens the dragon!"},
}

function onStepIn(creature, item, position, fromPosition)
	if creature:isPlayer() then
		return false
	end
	local it = itemsid[item:getId()]
	if it and creature:getName():lower() == it.monster then
		if (it.mainPosition and it.mainPosition ~= item:getPosition()) then
			broadcastMessage('nao')
			return true
		end
		if it.action == "transform" then
			creature:remove()
			local monster = Game.createMonster(it.monsterTo, item:getPosition())
			if(monster)then
				monster:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				monster:setStorageValue("portal_boss", 1)
				monster:registerEvent("salaBoss")
				if it.delete then
					item:remove()
				end
				monster:say(it.message, TALKTYPE_MONSTER_SAY)
			end
		end
	end
	return true
end