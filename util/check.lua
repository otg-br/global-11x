NetworkMessage = {}


function NetworkMessage.create(pdata)
	-- NetworkMessage.create([pdata])
	-- @params
	--	'pdata': string
	-- Instancia a classe NetworkMessage, se pdata é fornecido é definido o atributo data igual a pdata e size igual a #pdata
	return setmetatable({ data = pdata or "", size = pdata and #pdata or 0, pos = 1}, { __index = NetworkMessage })
end

function NetworkMessage:reset()
	-- NetworkMessage.reset(self)
	-- self:reset()
	-- @params
	-- 	'self': table
	-- Reinicia os atributos do objeto
	self.data = ""
	self.size = 0
	self.pos  = 1
end

function NetworkMessage:setBuffer(buffer)
	-- NetworkMessage.setBuffer(self, buffer)
	-- self:setBuffer(buffer)
	-- @params
	-- 	'self': table
	--  'buffer': string
	-- Define 'buffer' como atributo data
	if not type(buffer) == "string" then
		return false
	end

	self.data = buffer
	self.size = #buffer
	self.pos = 1
end

function NetworkMessage:getBuffer()
	-- NetworkMessage.getBuffer(self)
	-- self:getBuffer()
	-- @params
	--  'self': table
	-- Retorna o atributo 'data'
	return self.data
end

function NetworkMessage:getSize()
	-- NetworkMessage.getSize(self)
	-- self:getSize()
	-- @params
	--  'self': table
	-- Retorna o atributo 'size'
	return self.size
end

function NetworkMessage:getRanges(byteCount, signed)
	-- NetworkMessage.getRanges(self, byteCount, signed)
	-- self:getRanges(byteCount, signed)
	-- @params
	-- 	'self': table
	-- 	'byteCount': number
	--  'signed': boolean
	-- Função interna usada para calcular o limite do valor de 'byteCount' bytes, se signed é true reajusta seu valor para signed
	local min, max = 0, ((256^byteCount) -1)
	if(signed)then
		max = math.floor(max/2)
		min = -max-1
	end
	return -min, max
end

function NetworkMessage:canRead(size)
	-- NetworkMessage.canRead(self, size)
	-- self:canRead(size)
	-- @params
	--  'self': table
	--  'size': number
	-- Verifica se pode ser lido o numero 'size' de bytes, retorna um booleano
	return (self.pos + size) > (self.size + 1)
end

function NetworkMessage:readBytes(byteCount, signed)
	-- NetworkMessage.readBytes(self, byteCount, signed)
	-- self:readBytes(byteCount, signed)
	-- @params
	--  'self': table
	--  'byteCount': number
	--  'signed': boolean
	-- Tenta ler 'byteCount' numero de bytes, retorna o valor numerico dos bytes
	-- se possivel a leitura, e false se não. Se signed é true reajusta valor para signed
	if self:canRead(byteCount) then return false end

	local min, _ = self:getRanges(byteCount, signed)
	local value = 0

	for byte = 1, byteCount do
		value = value + ( self.data:byte(self.pos) * (256^(byte-1)) )
		self.pos = self.pos + 1
	end

	return value + min
end

function NetworkMessage:addBytes(value, count, signed)
	-- NetworkMessage.addBytes(self, value, count, signed)
	-- self:addBytes(value, count, signed)
	-- @params
	--  'self': table
	-- 	'value': number
	--  'count':number
	--  'signed':boolean
	-- Tenta escrever 'value' em 'count' bytes, se 'value' for maior que o numero de bytes
	-- suporta retorna false. Se signed é true reajusta valor para signed
	if signed then
		value = value * 2
	end

	if value >= (256^count) then
		return false
	end

	for byte = count, 1, -1 do
		local power = (256 ^ (byte-1))
		self.data = self.data .. string.char( math.floor(value/power) )
		value = value % power
	end

	self.size = self.size + count
	self.pos = self.pos + count
	return true
end

-- Metodos para pegar valores
function NetworkMessage:getU8()
	return self:readBytes(1, false)
end

function NetworkMessage:getU16()
	return self:readBytes(2, false)
end

function NetworkMessage:getU32()
	return self:readBytes(4, false)
end

function NetworkMessage:getU64()
	return self:readBytes(8, false)
end

function NetworkMessage:getI8()
	return self:readBytes(1, true)
end

function NetworkMessage:getI16()
	return self:readBytes(2, true)
end

function NetworkMessage:getI32()
	return self:readBytes(4, true)
end

function NetworkMessage:getI64()
	return self:readBytes(8, true)
end

-- Metodos para adição de valores
function NetworkMessage:addU8(value)
	return self:addBytes(value, 1, false)
end

function NetworkMessage:addU16(value)
	return self:addBytes(value, 2, false)
end

function NetworkMessage:addU32(value)
	return self:addBytes(value, 4, false)
end

function NetworkMessage:addU64(value)
	return self:addBytes(value, 8, false)
end

function NetworkMessage:addI8(value)
	return self:addBytes(value, 1, true)
end

function NetworkMessage:addI16(value)
	return self:addBytes(value, 2, true)
end

function NetworkMessage:addI32(value)
	return self:addBytes(value, 4, true)
end

function NetworkMessage:addI64(value)
	return self:addBytes(value, 8, true)
end

function NetworkMessage:addString(str)
	-- NetworkMessage.addString(self, str)
	-- self:addString(str)
	-- @params
	--  'self': table
	--  'str': string
	-- Tenta adicionar 'str', se o tamanho supera dois bytes, retorna false
	if not self:addU16(#str) then
		return false
	end

	self.data = self.data .. str

	self.size = self.size + #str
	self.pos = self.pos + #str
	return true
end

function NetworkMessage:getString()
	-- NetworkMessage.getString(self)
	-- self:getString()
	-- @params
	--  'self': table
	-- Tenta ler a string e retorna-la em caso de sucesso, se falho retorna false
	local size = self:getU16()
	if not (size and self:canRead(size)) then return false end

	local str = ""
	for byte=0, size-1 do
		str = str .. string.char(self.data:byte(self.pos + byte))
	end
	self.pos = self.pos + size
	return str
end

local function readFile(filename)
	local fp = io.open(filename, "r")
	local ct = fp:read("*a")
	fp:close()
	return ct
end

desc = string.format('{')
local last = 0
local filename = "C:\\Users\\Lucas\\Desktop\\store\\staticdata.dat"
local mov = readFile(filename)
local msg = NetworkMessage.create(mov)
local pass = 1
for line in io.lines(filename) do
	local msg = NetworkMessage.create(line)
	pass = pass + 1
	if pass ~= 4 then
		msg:getU8()
	end

	id = 1
	if pass == 11 then
		msg:getU8()
		msg:getU8()
		id = last + 1
	elseif pass == 27 then --
		msg:getU8()
		id = last + 1
	elseif pass == 116 or pass == 122 then --
		id = msg:getU8()
		msg:getU8()

	elseif pass == 580 or pass == 589 then -- 6Ibytes
		local byte = msg:getU8()
		msg:getU8()
		id = (13 * 128) + (math.abs(byte - 128))
	elseif pass == 567 then -- 6Ibytes
		local byte = msg:getU8()
		msg:getU8()
		id = (13 * 128) + (math.abs(byte - 128))
	elseif pass == 500 then -- 6Ibytes
		local byte = msg:getU8()
		msg:getU8()
		id = (10 * 128) + (math.abs(byte - 128))
	elseif pass >= 562 then -- 6Ibytes
		msg:getU8()
		local byte = msg:getU8()
		local x = msg:getU8()
		local multi = x == 32 and 13 or x
		id = (multi * 128) + (math.abs(byte - 128))
	elseif pass >= 507 then -- 6Ibytes
		msg:getU8()
		local byte = msg:getU8()
		local x = msg:getU8()
		local multi = x == 32 and 10 or x
		id = (multi * 128) + (math.abs(byte - 128))
	elseif pass == 401 then -- 6Ibytes
		msg:getU8()
		local byte = msg:getU8()
		local x = msg:getU8()
		local multi = x == 32 and 10 or x
		id = (multi * 128) + (math.abs(byte - 128))
	elseif pass == 402 then -- 6Ibytes
		local byte = msg:getU8()
		local x = msg:getU8()
		local multi = x == 32 and 10 or x
		id = (multi * 128) + (math.abs(byte - 128))
	elseif pass >= 498 then -- 6Ibytes
		msg:getU8()
		local byte = msg:getU8()
		local x = msg:getU8()
		id = (10 * 128) + (math.abs(byte - 128))
	elseif pass >= 495 then -- 6Ibytes
		msg:getU8()
		local byte = msg:getU8()
		local x = msg:getU8()
		local multi = x == 32 and 10 or x
		id = (multi * 128) + (math.abs(byte - 128))
	elseif pass == 238 or pass == 259 or pass == 266 or pass == 362 or pass == 386 or pass == 401 or pass == 443 or pass == 495 then -- 6Ibytes
		local byte = msg:getU8()
		local multi = msg:getU8()
		id = (multi * 128) + (math.abs(byte - 128))
	elseif pass >= 207 then -- 6Ibytes
		msg:getU8()
		local byte = msg:getU8()
		local multi = msg:getU8()
		id = (multi * 128) + (math.abs(byte - 128))
	elseif pass >= 173 then -- 6Ibytes
		msg:getI8()
		id = msg:getI8()
		msg:getU8()
	elseif pass >= 171 then -- 6Ibytes
		id = msg:getI8()
		msg:getU8()
	elseif pass >= 147 then -- 6Ibytes
		msg:getU8()
		id = msg:getI8()
		msg:getU8()
	elseif pass == 111 then -- u16 - puro
		id = msg:getU8()
		msg:getU16()
	elseif pass >= 110 then -- 6Ubytes
		msg:getU8()
		id = msg:getU8()
		msg:getU8()

	elseif pass >= 72 and pass < 74 or pass == 84 then -- 4bytes
		id = msg:getU8()
	elseif pass >= 55 and pass < 57 then -- 5 bytes
		id = msg:getU8()
		msg:getU16()
	elseif pass >= 28 then
		msg:getU8()
		id = msg:getU8()
	elseif pass >= 26 and pass <= 27 then
		id = msg:getU8()
	elseif pass < 26 then
		msg:getU8()
		id = msg:getU8()
	end
	last = id
	local name = msg:getString()
	if id ~= false then
	print(string.format('\n[%d] = "%s",', pass, name))
	desc = string.format('%s\n[%d] = "%s",', desc, id, name)
	end
end
desc = string.format('%s}', desc)

print(desc)





