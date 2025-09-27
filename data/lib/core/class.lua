local class = {
	_VERSION = 'class.lua v2020.02.08',
	_URL = 'https://gist.github.com/lyuz1n/6ef834507fbbeb57040ea5a325af6cbb'
}

local function copyTable(table)
	local result = {}
	local mt = getmetatable(table)
	if mt then
		setmetatable(result, mt)
	end
	for k, v in pairs(table) do
		if type(v) == 'table' and k ~= '__index' and k ~= '__newindex' then
			result[k] = copyTable(v)
		else
			result[k] = v
		end
	end
	return result
end

setmetatable(class, {
	__call = function(self, classScope)
		return setmetatable({}, {
			__index = classScope,
			__call = function(self, objectScope)
				local obj = objectScope or {}
				setmetatable(obj, {__index = self})
				if obj.constructor and type(obj.constructor) == 'function' then
					obj:constructor()
				end
				for key, value in pairs(classScope) do
					if type(value) == 'table' then
						obj[key] = copyTable(value)
					else
						obj[key] = value
					end
				end
				return obj
			end
		})
	end
})

return class
