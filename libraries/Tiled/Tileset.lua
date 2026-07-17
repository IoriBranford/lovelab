local class = require "Tiled.class"
local Assets = require "Tiled.Assets"
local Properties = require "Tiled.Properties"
local Tile       = require "Tiled.Tile"
local pathlite   = require "Tiled.pathlite"

---@class Tileset:Class
---@field firstgid integer The first global tile ID of this tileset (this global ID maps to the first tile in this tileset).
---@field filename string? If this tileset is stored in an external Lua file, this attribute refers to the original Tiled TSX file.
---@field exportfilename string? If this tileset is stored in an external Lua file, this attribute refers to that file. That Lua file has the same structure as the Tileset class described here. (There is the firstgid attribute missing and this source attribute is also not there. These two attributes are kept in the TMX map, since they are map specific.)
---@field name string The name of this tileset.
---@field class string The class of this tileset (since 1.9, defaults to “”).
---@field tilewidth integer The (maximum) width of the tiles in this tileset. Irrelevant for image collection tilesets, but stores the maximum tile width.
---@field tileheight integer The (maximum) height of the tiles in this tileset. Irrelevant for image collection tilesets, but stores the maximum tile height.
---@field spacing integer The spacing in pixels between the tiles in this tileset (applies to the tileset image, defaults to 0). Irrelevant for image collection tilesets.
---@field margin integer The margin around the tiles in this tileset (applies to the tileset image, defaults to 0). Irrelevant for image collection tilesets.
---@field tilecount integer The number of tiles in this tileset (since 0.13). Note that there can be tiles with a higher ID than the tile count, in case the tileset is an image collection from which tiles have been removed.
---@field columns integer The number of tile columns in the tileset. For image collection tilesets it is editable and is used when displaying the tileset. (since 0.15)
---@field objectalignment string Controls the alignment for tile objects. Valid values are unspecified, topleft, top, topright, left, center, right, bottomleft, bottom and bottomright. The default value is unspecified, for compatibility reasons. When unspecified, tile objects use bottomleft in orthogonal mode and bottom in isometric mode. (since 1.4)
---@field blanktiles table<integer,Tile> Tile ids whose pixels are all fully transparent (alpha = 0)
---@field blanktilecount integer
---@field tiles Tile[] Moved to array part of tileset
---@field image love.Texture|Aseprite|string
---@field imagefile string
---@field imagetype "image"|"aseprite"
---@field tileoffset {x: number, y: number}
---@field [integer] Tile All tiles including ones that have no special properties (0-based)
---@field [string] Tile All tiles with string property called "name", after calling Map:indexTilesetTilesByName
----@field properties table Moved into tileset itself
local Tileset = class()

function Tileset:_init(directory)
    local imagefile = self.image
    local imagetype
    ---@cast imagefile string
    local AseFileType = ".ase"
    if imagefile:sub(-#AseFileType) == AseFileType then
        imagefile = imagefile:sub(1, -1-#AseFileType)..".jase"
        imagetype = "aseprite"
    else
        imagetype = "image"
    end
    if directory ~= "" then
        imagefile = pathlite.normjoin(directory, imagefile)
    end
    self.imagetype = imagetype
    self.imagefile = imagefile
    local image = Assets.get(imagefile)
    ---@cast image love.Image|Aseprite
    self.image = image
    local columns = self.columns
    local n = self.tilecount
    local tw = self.tilewidth
    local th = self.tileheight

    local ObjectAlignments = {
        topleft     = {0.0, 0.0},
        top         = {0.5, 0.0},
        topright    = {1.0, 0.0},
        left        = {0.0, 0.5},
        center      = {0.5, 0.5},
        right       = {1.0, 0.5},
        bottomleft  = {0.0, 1.0},
        bottom      = {0.5, 1.0},
        bottomright = {1.0, 1.0},
        unspecified  = {0.0, 1.0},
    }
    local alignment = ObjectAlignments[self.objectalignment or "bottomleft"]
    local objectox, objectoy = alignment[1]*tw, alignment[2]*th
    local offsetx, offsety = 0, 0
    if self.tileoffset then
        offsetx = self.tileoffset.x
        offsety = self.tileoffset.y
        objectox = objectox - offsetx
        objectoy = objectoy - offsety
    end

    for id = 0, n-1 do
        self[id] = Tile.cast {
            id = id,
            tileset = self,
            image = image,
            imagetype = imagetype,
            width = tw,
            height = th,
            offsetx = offsetx,
            offsety = offsety,
            objectoriginx = objectox,
            objectoriginy = objectoy
        }
    end

    if self.imagetype == "aseprite" then
    else
        ---@cast image love.Image
        local iw, ih = image:getDimensions()
        for id = 0, n - 1 do
            local tx = (id % columns) * tw
            local ty = (math.floor(id / columns)) * th
            self[id].quad = love.graphics.newQuad(tx, ty, tw, th, iw, ih)
        end
    end

    local tilesdata = self.tiles
    if tilesdata then
        for i = 1, #tilesdata do
            local tiledata = tilesdata[i]
            local tileid = tiledata.id
            Tile.from(self[tileid], tiledata)
        end
    end

    Properties.resolveAssetPaths(self.properties, directory)
    Properties.moveUp(self)

    local blanks = self.blanktiles
    if type(blanks) == "string" then
        local t = {}
        self.blanktiles = t
        for s in blanks:gmatch("(%d+)[,$]") do
            local i = assert(tonumber(s), blanks)
            t[i] = self[i]
        end
    end
end

return Tileset