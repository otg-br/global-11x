function onStepIn(creature, position, fromPosition, toPosition)
	if not creature or not creature:isMonster() then
		return true
    end
    local r = math.random(1, 2)
    local cName = creature:getName()
    if cName:lower() == "ancient spawn of morgathla" then
        creature:say('The crystal drains the scarabs power', TALKTYPE_MONSTER_SAY)
        creature:setStorageValue("canHeal", 1)
        addEvent(function(cid)
            local c = Creature(cid)
            if c then
                creature:setStorageValue("canHeal", 0)
            end
        end, r*60*1000, creature:getId())
        item:transform(32410)
    end
	return true
end