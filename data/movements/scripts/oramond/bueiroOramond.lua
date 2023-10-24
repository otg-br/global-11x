local upFloorIds = {23669}
function onStepIn(cid, item, position, fromPosition)
	if isInArray(upFloorIds, item.itemid) == TRUE then
		position.x = position.x + 1
		position.z = position.z + 2
	end
	doTeleportThing(cid, position, false)
	return TRUE
end