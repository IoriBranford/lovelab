local Gid = require "Tiled.Gid"
local Graphics = require "Tiled.Graphics"
local TileBatching = require "Tiled.TileBatching"
local forCells     = require "Tiled.forCells"
local Color        = require "Tiled.Color"
local drawTile     = require "Tiled.drawTile"

---@class Chunk
---@field visible boolean
---@field x integer The x coordinate of the chunk, **converted from tiles to pixels**.
---@field y integer The y coordinate of the chunk, **converted from tiles to pixels**.
---@field width integer The width of the chunk, **converted from tiles to pixels**.
---@field height integer The height of the chunk, **converted from tiles to pixels**.
---@field col0 integer The x coordinate of the chunk, in tiles.
---@field row0 integer The y coordinate of the chunk, in tiles.
---@field columns integer The width of the chunk, in tiles.
---@field rows integer The height of the chunk, in tiles.
---@field data integer[]|string
---@field tilebatch love.SpriteBatch?
---@field batchanimations Animation[]? Indices in the data which have animated tiles
local Chunk = class()

---@param tilelayer TileLayer
function Chunk:_init(tilelayer)
    self.visible = tilelayer.visible
    self.tilelayer = tilelayer
    self.data = Gid.decode(self.data, self.tilelayer.encoding, self.tilelayer.compression)
    self.col0, self.row0, self.columns, self.rows = self.x, self.y, self.width, self.height
    self.x = self.x * tilelayer.tilewidth
    self.y = self.y * tilelayer.tileheight
    self.width = self.width * tilelayer.tilewidth
    self.height = self.height * tilelayer.tileheight
    self.animationtime = 0
end

function Chunk:getWorldPosition()
    local x, y = self.tilelayer:getWorldPosition()
    return x + self.x, y + self.y
end

function Chunk:forCells(f)
    local x, y = self.tilelayer:getWorldPosition()
    y = y + self.tilelayer.tileheight
    forCells(f, self.data, self.columns, self.rows,
        self.tilelayer.maptiles, x + self.x, y + self.y,
        self.tilelayer.tilewidth, self.tilelayer.tileheight)
end

function Chunk:batchTiles()
    self.tilebatch, self.batchanimations =
        TileBatching.batchTiles(self.tilelayer.maptiles, self.data,
                self.tilelayer.tilewidth, self.tilelayer.tileheight,
                self.columns, self.rows)
end

function Chunk:animate(dt)
    self.animationtime = self.animationtime + dt
    TileBatching.animateBatch(self, self.animationtime,
        self.tilelayer.tilewidth, self.tilelayer.tileheight)
end

function Chunk:draw()
    local r, g, b, a = 1, 1, 1, self.tilelayer.opacity or 1
    local tintcolor = self.tilelayer.tintcolor
    if tintcolor then
        r, g, b = Color.unpack(tintcolor)
    end
    love.graphics.setColor(r, g, b, a)

    Graphics.pushTransform(self.tilelayer)
    if self.tilebatch then
        love.graphics.draw(self.tilebatch, self.x, self.y)
    else
        forCells(drawTile, self.data, self.columns, self.rows, self.tilelayer.maptiles,
            self.x, self.y + self.tilelayer.tileheight,
            self.tilelayer.tilewidth, self.tilelayer.tileheight)
    end
    love.graphics.pop()
    if tintcolor then
        love.graphics.setColor(1,1,1)
    end
end

return Chunk