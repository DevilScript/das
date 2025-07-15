local Buffer = {}
Buffer.__index = Buffer

function Buffer.new(bytes)
	local self = setmetatable({}, Buffer)
	self.buf = buffer.create(#bytes)
	for i = 1, #bytes do
		buffer.writeu8(self.buf, i - 1, bytes[i])
	end
	return self
end

function Buffer:push(...)
	for _, v in ipairs({...}) do
		buffer.writeu8(self.buf, buffer.len(self.buf), v)
	end
end

function Buffer:get()
	return self.buf
end

function Buffer.fromString(str)
	return buffer.fromstring(str)
end

function Buffer.toString(buf)
	return buffer.tostring(buf)
end

function Buffer.unpack(buf)
	local out = {}
	for i = 0, buffer.len(buf) - 1 do
		table.insert(out, buffer.readu8(buf, i))
	end
	return out
end

return Buffer
