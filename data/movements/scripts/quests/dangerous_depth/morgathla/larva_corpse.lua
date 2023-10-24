function onStepIn(creature, item, position, fromPosition, toPosition)
	if not creature or not creature:isMonster() then
		return true
    end
    local r = math.random(3333, 5555)
    local cName = creature:getName()
    if cName:lower() == "ancient spawn of morgathla" then
        creature:addHealth(r)
        item:remove(1)
    end
	return true
end