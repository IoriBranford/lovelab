local class = require "Tiled.class"
local Gid = require "Tiled.Gid"
local Graphics = require "Tiled.Graphics"
local Color    = require "Tiled.Color"
local Layer    = require "Tiled.Layer"
local forCells = require "Tiled.forCells"
local Chunk    = require "Tiled.Chunk"
local drawTile = require "Tiled.drawTile"

local TileBatching = require "Tiled.TileBatching"
local newTileBatch = TileBatching.batchTiles
local animateBatch = TileBatching.animateBatch
local love_graphics_draw = love.graphics.draw

---@class TileLayer:Layer
---@field type string "tilelayer"
---@field encoding string? The encoding used to encode the tile layer data. When used, it can be “base64” and “csv” at the moment. (optional)
---@field compression string? The compression used to compress the tile layer data. Tiled supports “gzip”, “zlib” and (as a compile-time option since Tiled 1.3) “zstd”.
---@field data integer[]|string? In finite maps
---@field chunks Chunk[]? In infinite maps
---@field tilewidth integer Copy of map.tilewidth
---@field tileheight integer Copy of map.tileheight
---@field tilebatch love.SpriteBatch? In finite maps
---@field batchanimations Animation[]? Indices in the data which have animated tiles
---@field shader love.Shader?
local TileLayer = class(Layer)

---@param map TiledMap?
function TileLayer:_init(map)
    if type(map) ~= "table" or not map.tiledversion then return end
    self.maptiles = map.tiles
    local cellwidth = map.tilewidth
    local cellheight = map.tileheight
    self.mapcols = map.width
    self.maprows = map.height

    local chunks = self.chunks
    local encoding = self.encoding
    local compression = self.compression
    self.tilewidth = cellwidth
    self.tileheight = cellheight
    if chunks then
        for i = 1, #chunks do
            Chunk.from(chunks[i], self)
        end
    else
        local gids = Gid.decode(self.data, encoding, compression)
        self.data = gids
    end
    local tintcolor = self.tintcolor
    if type(tintcolor) == "table" then
        for i, c in ipairs(tintcolor) do
            tintcolor[i] = c/256
        end
    end
    self.animationtime = 0
    return self
end

function TileLayer:setVisible(visible)
    self.visible = visible
    if self.chunks then
        for _, chunk in ipairs(self.chunks) do
            chunk.visible = visible
        end
    end
end

---@param f fun(left:number, bottom: number, tile:Tile, flipx:number, flipy:number): any
function TileLayer:forCells(f)
    local maptiles = self.maptiles
    local chunks = self.chunks
    local cellwidth, cellheight = self.tilewidth, self.tileheight
    local x, y = self:getWorldPosition()
    y = y + cellheight
    if chunks then
        for _, chunk in ipairs(self.chunks) do
            forCells(f, chunk.data, chunk.columns, chunk.rows, maptiles,
                x + chunk.x, y + chunk.y,
                cellwidth, cellheight)
        end
    else
        forCells(f, self.data, self.mapcols, self.maprows, maptiles,
            x, y, cellwidth, cellheight)
    end
end

function TileLayer:batchTiles()
    local maptiles = self.maptiles
    local cellwidth = self.tilewidth
    local cellheight = self.tileheight

    local chunks = self.chunks
    if chunks then
        for i = 1, #chunks do
            local chunk = chunks[i]
            local gids = chunk.data
            chunk.tilebatch, chunk.batchanimations = newTileBatch(maptiles, gids,
                cellwidth, cellheight, chunk.columns, chunk.rows)
        end
    else
        local cols = self.mapcols
        local rows = self.maprows
        local gids = self.data
        self.tilebatch, self.batchanimations = newTileBatch(maptiles, gids,
            cellwidth, cellheight, cols, rows)
    end
end

function TileLayer:animate(dt)
    local time = self.animationtime + dt
    self.animationtime = time

    local chunks = self.chunks
    local tilewidth, tileheight = self.tilewidth, self.tileheight
    if chunks then
        for _, chunk in ipairs(chunks) do
            animateBatch(chunk, time, tilewidth, tileheight)
        end
    else
        animateBatch(self, time, tilewidth, tileheight)
    end
end

local pushTransform = Graphics.pushTransform

function TileLayer:draw(fixedfrac)
    local r, g, b, a = 1, 1, 1, self.opacity or 1
    local tintcolor = self.tintcolor
    if tintcolor then
        r, g, b = Color.unpack(tintcolor)
    end
    love.graphics.setColor(r, g, b, a)

    fixedfrac = fixedfrac or 0
    local velx = (self.velx or 0) * fixedfrac
    local vely = (self.vely or 0) * fixedfrac
    local chunks = self.chunks
    if chunks then
        pushTransform(self)
        local maptiles, cellwidth, cellheight = self.maptiles, self.tilewidth, self.tileheight
        for _, chunk in ipairs(chunks) do
            local x, y = chunk.x + velx, chunk.y + vely
            if chunk.tilebatch then
                love_graphics_draw(chunk.tilebatch, x, y)
            else
                forCells(drawTile, chunk.data, chunk.columns, chunk.rows, maptiles,
                    x, y + cellheight, cellwidth, cellheight, self.animationtime)
            end
        end
        love.graphics.pop()
    else
        local x, y = self.x + velx, self.y + vely

        local batch = self.tilebatch
        if batch then
            love_graphics_draw(batch, x, y,
                self.rotation or 0,
                self.scalex or 1, self.scaley or 1,
                self.originx or 0, self.originy or 0,
                self.skewx or 0, self.skewy or 0)
        else
            forCells(drawTile, self.data, self.mapcols, self.maprows, self.maptiles,
                x, y + self.tileheight, self.tilewidth, self.tileheight, self.animationtime)
        end
    end
    if tintcolor then
        love.graphics.setColor(1,1,1)
    end
end

return TileLayer