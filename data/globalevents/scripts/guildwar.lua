function onThink(interval)
	local time = os.stime()
	local resultid = db.storeQuery("SELECT * FROM guild_wars WHERE status = 1")
	if resultid ~= false then
		repeat
			local warid = result.getNumber(resultid, "id")
			local guild1 = result.getNumber(resultid, "guild1")
			local guild2 = result.getNumber(resultid, "guild2")
			local frags = result.getNumber(resultid, "frags_limit")
			local cleaned = false
			local secondQuery = db.storeQuery("SELECT COUNT(*) as 'count' FROM guildwar_kills WHERE warid = ".. warid .. " and killerguild = ".. guild1)
			if secondQuery ~= false then
				local count = result.getNumber(secondQuery, "count")
				if count >= frags then
					db.asyncQuery("UPDATE `guild_wars` SET `status` = 4, `ended` = " .. os.stime() .. " WHERE id = " .. warid)
					cleaned = true
				end
			end
			result.free(secondQuery)
			if not cleaned then
				secondQuery = db.storeQuery("SELECT COUNT(*) as 'count' FROM guildwar_kills WHERE warid = "..warid .. " and killerguild = ".. guild2)
				if secondQuery ~= false then
					local count = result.getNumber(secondQuery, "count")
					if count >= frags then
						db.asyncQuery("UPDATE `guild_wars` SET `status` = 4, `ended` = " .. os.stime() .. " WHERE id = " .. warid)
						cleaned = true
					end
				end
			end
			result.free(secondQuery)
		until not result.next(resultid)
	end
	result.free(resultid)
	return true
end
