local paper = 33040

function onDeath(creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	local cPos = creature:getPosition()
	if creature:getName():lower() == "dark knowledge" then
		local item = Game.createItem(paper, 1, cPos)
	end
end