
local Gid = {}

function Gid.parse(gid)
    local h, v = 1, 1
    if gid > 0x080000000 then
        h = -h
        gid = gid - 0x080000000
    end
    if gid > 0x040000000 then
        v = -v
        gid = gid - 0x040000000
    end
    return gid, h, v
end

function Gid.decode(data, encoding, compression)
    if encoding == "lua" then
        return data
    end

    if encoding == "base64" then
        data = love.data.decode("data", encoding, data)
        if compression then
            data = love.data.decompress("data", compression, data)
        end
    end

    local gids = {}
    local i, n = 1, data:getSize()
    while i <= n do
        gids[#gids + 1], i = love.data.unpack("I4", data, i)
    end
    return gids
end

return Gid