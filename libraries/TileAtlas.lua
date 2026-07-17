local Heap = require "Heap"

---@class AtlasTile
---@field image love.Texture
---@field quad love.Quad?

---@class AtlasSpace
---@field x number
---@field y number
---@field width number
---@field height number
---@field tile AtlasTile
local AtlasSpace = {}
AtlasSpace.__index = AtlasSpace

function AtlasSpace.__lt(a, b)
    return a.width * a.height < b.width * b.height
end

local function newSpace(x, y, w, h)
    return setmetatable({x = x, y = y, width = w, height = h}, AtlasSpace)
end

function AtlasSpace:fits(w, h)
    return self.width >= w and self.height >= h
end

function AtlasSpace:usedUp()
    return self.width <= 0 or self.height <= 0
end

function AtlasSpace:take(tilew, tileh, tile)
    local x, y = self.x, self.y
    local w, h = self.width, self.height
    local tilespace = newSpace(x, y, tilew, tileh)
    tilespace.tile = tile
    local tilevertical = tileh >= tilew
    local rightw = w - tilew
    local downh = h - tileh
    local newfreespace
    if rightw <= 0 and downh <= 0 then
        self.width, self.height = 0, 0
    elseif tilevertical then
        if rightw > 0 then
            self.x, self.width, self.height = x + tilew, rightw, tileh
            if downh > 0 then
                newfreespace = newSpace(x, y + tileh, w, downh)
            end
        elseif downh > 0 then
            self.y, self.height = y + tileh, downh
        end
    else
        if downh > 0 then
            self.y, self.width, self.height = y + tileh, tilew, downh
            if rightw > 0 then
                newfreespace = newSpace(x + tilew, y, rightw, h)
            end
        elseif rightw > 0 then
            self.x, self.width = x + tilew, rightw
        end
    end
    return tilespace, newfreespace
end

---@class TileAtlas
---@field width number
---@field height number
---@field freespaces Heap<AtlasSpace>
---@field newtilespaces AtlasSpace[]
---@field newtiles AtlasTile[]
---@field tiles AtlasTile[]
---@field canvas love.Canvas
local TileAtlas = {}
TileAtlas.__index = TileAtlas

local MaxTextureSize

function TileAtlas.New(width, height)
    MaxTextureSize = MaxTextureSize or love.graphics.getSystemLimits().texturesize
    local self = setmetatable({}, TileAtlas)
    width = width or 2048
    height = height or width
    self.width, self.height = width, height
    self.canvas = love.graphics.newCanvas(width, height)
    local emptytile = {
        image = self.canvas,
        quad = love.graphics.newQuad(1, 1, 2, 2, width, height)
    }
    self.freespaces = Heap.new()
    self.freespaces:push(newSpace(0, 0, width, height))
    self:takeSpace(4, 4, emptytile)
    self.newtilespaces = {}
    self.newtiles = {}
    self.tiles = {emptytile}
    return self
end

---@param tile AtlasTile
function TileAtlas:addTile(tile)
    if not tile or tile.image == self.canvas then
        return
    end
    self.newtiles[#self.newtiles+1] = tile
end

---@param tiles AtlasTile[]
function TileAtlas:addTiles(tiles)
    for i = 1, #tiles do
        self:addTile(tiles[i])
    end
end

---@param w integer
---@param h integer
---@param tile AtlasTile
---@return AtlasSpace?
function TileAtlas:takeSpace(w, h, tile)
    local freespaces = self.freespaces

    repeat
        for i = 1, #freespaces do
            local space = freespaces[i]
            if space:fits(w, h) then
                local tilespace, newspace = space:take(w, h, tile)
                freespaces:update(space)
                while freespaces[1] and freespaces[1]:usedUp() do
                    freespaces:pop()
                end
                if newspace then
                    freespaces:push(newspace)
                end
                return tilespace
            end
        end
    until not self:grow2x()
end

function TileAtlas:grow2x()
    if self.width >= MaxTextureSize and self.height >= MaxTextureSize then
        return false
    end

    local newfreespace
    if self.width <= self.height then
        newfreespace = newSpace(self.width, 0, self.width, self.height)
        self.width = self.width * 2
    else
        newfreespace = newSpace(0, self.height, self.width, self.height)
        self.height = self.height * 2
    end

    self.freespaces:push(newfreespace)
    return true
end

function TileAtlas:findNewTileSpaces()
    local tilequeue = self.newtiles
    if #tilequeue <= 0 then return end

    table.sort(tilequeue, function (a, b)
        local aw, ah, bw, bh, _
        if a.quad then
            _, _, aw, ah = a.quad:getViewport()
        else
            aw, ah = a.image:getDimensions()
        end
        if b.quad then
            _, _, bw, bh = b.quad:getViewport()
        else
            bw, bh = b.image:getDimensions()
        end

        local diffarea = aw*ah - bw*bh
        if diffarea ~= 0 then return diffarea > 0 end

        local diffperimeter = 2*(aw+ah) - 2*(bw+bh)
        if diffperimeter ~= 0 then return diffperimeter > 0 end

        local diffbigside = math.max(aw, ah) - math.max(bw, bh)
        if diffbigside ~= 0 then return diffbigside > 0 end

        local diffw = aw - bw
        if diffw ~= 0 then return diffw > 0 end

        return ah > bh
    end)

    for _, tile in ipairs(tilequeue) do
        local quad = tile.quad
        local _, w, h
        if quad then
            _, _, w, h = quad:getViewport()
        else
            w, h = tile.image:getDimensions()
        end
        local tilespace = self:takeSpace(w + 2, h + 2, tile)
        self.newtilespaces[#self.newtilespaces+1] = tilespace
    end

    for i = #tilequeue, 1, -1 do
        tilequeue[i] = nil
    end
end

function TileAtlas:updateCanvas()
    self:findNewTileSpaces()

    local canvas = self.canvas
    local width = self.width
    local height = self.height
    local resized = canvas:getWidth() < width
        or canvas:getHeight() < height
    if resized then
        local newcanvas = love.graphics.newCanvas(width, height)
        newcanvas:renderTo(function()
            love.graphics.draw(canvas, 0, 0)
        end)
        canvas = newcanvas
        self.canvas = newcanvas

        local tiles = self.tiles
        for i = 1, #tiles do
            local tile = tiles[i]
            local x, y, w, h = tile.quad:getViewport()
            tile.image = canvas
            tile.quad:setViewport(x, y, w, h, width, height)
        end
    end

    self:drawNewTilesToCanvas()
end

function TileAtlas:drawNewTilesToCanvas()
    local newtilespaces = self.newtilespaces
    if #newtilespaces <= 0 then return end

    local canvas = self.canvas
    local width = self.width
    local height = self.height
    local tiles = self.tiles

    local blendmode0, alphamode0 = love.graphics.getBlendMode()
    love.graphics.setBlendMode("alpha", "premultiplied")
    local canvas0 = love.graphics.getCanvas()
    love.graphics.setCanvas(canvas)

    local quad = love.graphics.newQuad(0, 0, 1, 1, 1, 1)
    for s = 1, #newtilespaces do
        local space = newtilespaces[s]
        local tile = space.tile
        local srcimage = tile.image
        local tquad = tile.quad
        if not tquad then
            local srciw, srcih = srcimage:getDimensions()
            tquad = love.graphics.newQuad(0, 0, srciw, srcih, srciw, srcih)
            tile.quad = tquad
        end
        local tsorcx, tsorcy, twidth, theigt = tquad:getViewport()
        local tdstx0, tdsty0 = space.x, space.y
        local tdestx, tdesty = tdstx0 + 1, tdsty0 + 1
        local tdstx1, tdsty1 = tdestx + twidth, tdesty + theigt

        tile.image = canvas
        tquad:setViewport(tdestx, tdesty, twidth, theigt, width, height)

        local tsrcx2 = tsorcx + twidth - 1
        local tsrcy2 = tsorcy + theigt - 1
        local srciw, srcih = srcimage:getDimensions()
        local rects = {
            -- tile
            tdestx, tdesty, tsorcx, tsorcy, twidth, theigt,

            -- edges
            tdestx, tdsty0, tsorcx, tsorcy, twidth,      1,
            tdstx0, tdesty, tsorcx, tsorcy,      1, theigt,
            tdstx1, tdesty, tsrcx2, tsorcy,      1, theigt,
            tdestx, tdsty1, tsorcx, tsrcy2, twidth,      1,

            -- corners
            tdstx0, tdsty0, tsorcx, tsorcy,      1,      1,
            tdstx1, tdsty0, tsrcx2, tsorcy,      1,      1,
            tdstx0, tdsty1, tsorcx, tsrcy2,      1,      1,
            tdstx1, tdsty1, tsrcx2, tsrcy2,      1,      1
        }
        for i = 6, #rects, 6 do
            local destx = rects[i-5]
            local desty = rects[i-4]
            local srcx = rects[i-3]
            local srcy = rects[i-2]
            local srctw = rects[i-1]
            local srcth = rects[i-0]
            quad:setViewport(srcx, srcy, srctw, srcth, srciw, srcih)
            love.graphics.draw(srcimage, quad, destx, desty)
        end

        -- love.graphics.rectangle("line", space.x, space.y, space.width, space.height)

        tiles[#tiles+1] = tile
    end

    love.graphics.setCanvas(canvas0)
    love.graphics.setBlendMode(blendmode0, alphamode0)
    for i = #newtilespaces, 1, -1 do
        newtilespaces[i] = nil
    end
end

function TileAtlas:newImageData()
    return self.canvas:newImageData()
end

function TileAtlas:save(path)
    self.canvas:newImageData():encode("png", string.format("%s.png", path))
end

---@param tileset Tileset
function TileAtlas:addTileset(tileset)
    local canvas = self.canvas
    local width = self.width
    local height = self.height
    local blanktiles = tileset.blanktiles
    for i = 0, tileset.tilecount-1 do
        local tile = tileset[i]
        if tile.image ~= canvas then
            if blanktiles and blanktiles[tile.id] then
                tile.image = canvas
                tile.quad:setViewport(1, 1, 2, 2, width, height)
            else
                ---@cast tile AtlasTile
                self:addTile(tile)
            end
        end
    end
end

function TileAtlas:addAseFrame(frame)
    if not frame then
        return
    end
    for i = 1, #frame do
        local cel = frame[i]
        if cel then
            self:addTile(cel)
        end
    end
end

setmetatable(TileAtlas, {__call = function(_, ...) return TileAtlas.New(...) end})
return TileAtlas