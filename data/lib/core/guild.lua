--
-- uso para Private War sem precisar registar no banco de dados
--

if not tempGuildStorage then
	tempGuildStorage = {}
end

function Guild.getTempStorage(self, key)
	if not tempGuildStorage[self:getId()] then
		tempGuildStorage[self:getId()] = {}
	end
	if not tempGuildStorage[self:getId()][key] then
		return -1
	end

	return tempGuildStorage[self:getId()][key]
end

function Guild.setTempStorage(self, key, value)
	if not tempGuildStorage[self:getId()] then
		tempGuildStorage[self:getId()] = {}
	end

	tempGuildStorage[self:getId()][key] = value
	return true
end
