local info = {
	fromPos = Position(33390, 32642, 6),
	toPos = Position(33402, 32654, 6),
	mirrors = {36188, 36189, 36191, 36190}
}


function onThink(interval)
	for x = info.fromPos.x, info.toPos.x do
		for y = info.fromPos.y, info.toPos.y do
			local sqm = Tile(Position(x, y, 6))
			if sqm then
				for _, id in pairs(info.mirrors) do
					local item = sqm:getItemById(id)
					if item then
						item:transform(info.mirrors[math.random(#info.mirrors)])
					end

				end

			end
		end
	end
	return true
end