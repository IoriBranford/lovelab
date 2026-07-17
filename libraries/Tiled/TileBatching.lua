local forCells = require "Tiled.forCells"
local Gid      = require "Tiled.Gid"

local parseGid = Gid.parse

---@module 'TileBatching'
local TileBatching = {}

function TileBatching.batchTiles(maptiles, data, cellwidth, cellheight, cols, rows)
    local tile1
    for i = 1, #data do
        tile1 = maptiles[data[i]]
        if tile1 then
            break
        end
    end
    if not tile1 then
        return
    end

    local tilebatch = love.graphics.newSpriteBatch(tile1.image, cols * rows)
    local batchanimations = {}
    local i = 1
    forCells(function(x, y, tile, sx, sy)
        if tile and tile.quad then
            local hw, hh = tile.width / 2, tile.height / 2
            x, y = x + hw + tile.offsetx, y - hh + tile.offsety
            tilebatch:add(tile.quad, x, y, 0, sx, sy, hw, hh)
            batchanimations[i] = tile.animation
        else
            tilebatch:add(x, y, 0, 0, 0)
        end
        i = i + 1
    end, data, cols, rows, maptiles, 0, cellheight, cellwidth, cellheight)

    return tilebatch, batchanimations
end

---@param self TileLayer|Chunk
function TileBatching.animateBatch(self, animationtime, tilewidth, tileheight)
    local tilebatch = self.tilebatch
    local batchanimations = self.batchanimations
    if not tilebatch or not batchanimations then
        return
    end

    local columns = self.columns
    local gids = self.data
    for i, animation in pairs(batchanimations) do
        local _, sx, sy = parseGid(gids[i])
        local nframes = #animation
        local _, progress = math.modf(animationtime / animation.duration)
        local frameindex = math.floor(nframes * progress) + 1
        local tile = animation[frameindex].tile
        local r = math.floor((i-1) / columns) + 1
        local c =           ((i-1) % columns)
        local x = c*tilewidth
        local y = r*tileheight
        local hw, hh = tile.width / 2, tile.height / 2
        x, y = x + hw + tile.offsetx, y - hh + tile.offsety
        tilebatch:set(i, tile.quad, x, y, 0, sx, sy, hw, hh)
    end
end

return TileBatching