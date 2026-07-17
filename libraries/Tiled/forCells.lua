local Gid = require "Tiled.Gid"

local parseGid = Gid.parse

---@param f fun(x:number, y: number, tile:Tile, flipx:number, flipy:number, time:number?): any
---@param data integer[]
---@param cols number
---@param rows number
---@param maptiles Tile[]
---@param x0 number? origin
---@param y0 number? origin
---@param dx number?
---@param dy number?
---@param time number?
local function forCells(f, data, cols, rows, maptiles, x0, y0, dx, dy, time)
    local i = 1
    local y = y0 or 0
    x0 = x0 or 0
    dx = dx or 1
    dy = dy or 1
    for _ = 1, rows do
        local x = x0
        for _ = 1, cols do
            local gid, sx, sy = parseGid(data[i])
            local tile = maptiles[gid]
            f(x, y, tile, sx, sy, time)
            i = i + 1
            x = x + dx
        end
        y = y + dy
    end
end

return forCells