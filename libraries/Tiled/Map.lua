local Tileset = require "Tiled.Tileset"
local TileLayer = require "Tiled.TileLayer"
local indexElementsByName = require "Tiled.indexElementsByName"
local ObjectGroup = require "Tiled.ObjectGroup"
local Properties  = require "Tiled.Properties"
local LayerGroup  = require "Tiled.LayerGroup"
local ImageLayer  = require "Tiled.ImageLayer"
local class = require "Tiled.class"
local Assets= require "Tiled.Assets"
local pathlite = require "Tiled.pathlite"

---@class TiledMap:Class
---@field version string The TMX format version. Was “1.0” so far, and will be incremented to match minor Tiled releases.
---@field tiledversion string The Tiled version used to save the file (since Tiled 1.0.1). May be a date (for snapshot builds). (optional)
---@field class string The class of this map (since 1.9, defaults to “”).
---@field orientation string Map orientation. Tiled supports “orthogonal”, “isometric”, “staggered” and “hexagonal” (since 0.11).
---@field renderorder string The order in which tiles on tile layers are rendered. Valid values are right-down (the default), right-up, left-down and left-up. In all cases, the map is drawn row-by-row. (only supported for orthogonal maps at the moment)
---@field compressionlevel integer The compression level to use for tile layer data (defaults to -1, which means to use the algorithm default).
---@field width integer The map width in tiles.
---@field height integer The map height in tiles.
---@field tilewidth integer The width of a tile.
---@field tileheight integer The height of a tile.
---@field hexsidelength integer Only for hexagonal maps. Determines the width or height (depending on the staggered axis) of the tile’s edge, in pixels.
---@field staggeraxis string For staggered and hexagonal maps, determines which axis (“x” or “y”) is staggered. (since 0.11)
---@field staggerindex string For staggered and hexagonal maps, determines whether the “even” or “odd” indexes along the staggered axis are shifted. (since 0.11)
---@field parallaxoriginx number X coordinate of the parallax origin in pixels (defaults to 0). (since 1.8)
---@field parallaxoriginy number Y coordinate of the parallax origin in pixels (defaults to 0). (since 1.8)
---@field backgroundcolor integer[] [r, g, b] (converted to range 0..1) The background color of the map. (optional, may include alpha value since 0.15 in the form #AARRGGBB. Defaults to fully transparent.)
---@field nextlayerid integer Stores the next available ID for new layers. This number is stored to prevent reuse of the same ID after layers have been removed. (since 1.2) (defaults to the highest layer id in the file + 1)
---@field nextobjectid integer Stores the next available ID for new objects. This number is stored to prevent reuse of the same ID after objects have been removed. (since 0.11) (defaults to the highest object id in the file + 1)
---@field infinite boolean Whether this map is infinite. An infinite map has no fixed size and can grow in all directions. Its layer data is stored in chunks. (0 for false, 1 for true, defaults to 0)
---@field tilesets Tileset[] Access by index (or by tileset name after calling indexTilesetsByName)
---@field layers LayerGroup Access by index (or by layer name after calling indexLayersByName)
---@field directory string Directory path containing the map file. Prepended to all asset paths in the map file: image files, file properties
---@field file string Path of the map file
---@field objects {[integer]: TiledObject} All map objects by their id
---@field tiles Tile[] All tileset tiles by their gid
---@field properties table Moved into map itself
local TiledMap = class()

----@field offsetx number Horizontal offset of the image layer in pixels. (defaults to 0) (since 0.15)
----@field offsety number Vertical offset of the image layer in pixels. (defaults to 0) (since 0.15)
----@field properties table Moved into layer itself

function TiledMap:initLayersZ(z1, layerfilter)
    local function initLayerZ(layer, z, groupscalez)
        local layertype = layer.type
        if layerfilter and not layerfilter:find(layertype) then
            return
        end
        layer.z = layer.z or z
        if layertype == "group" then
            groupscalez = (groupscalez or 1) / #layer
            local subz = z
            for i = 1, #layer do
                initLayerZ(layer[i], subz, groupscalez)
                subz = layer[i].z + groupscalez
            end
        elseif layertype == "objectgroup" then
            for _, object in ipairs(layer) do
                object.z = object.z or z
            end
        end
    end

    local z = z1 or 1
    for _, layer in ipairs(self.layers) do
        initLayerZ(layer, z)
        z = layer.z + 1
    end
end

function TiledMap:indexEverythingByName()
    self:indexTilesetsByName()
    self:indexTilesetTilesByName()
    self:indexTileShapesByName()
    self:indexLayersByName()
    self:indexLayerObjectsByName()
end

function TiledMap:indexTilesetsByName()
    indexElementsByName(self.tilesets)
end

function TiledMap:indexTilesetTilesByName()
    for _, tileset in ipairs(self.tilesets) do
        indexElementsByName(tileset, 0)
    end
end

function TiledMap:indexTileShapesByName()
    for _, tile in ipairs(self.tiles) do
        if tile.shapes then
            indexElementsByName(tile.shapes)
        end
    end
end

function TiledMap:indexLayersByName()
    self.layers:indexLayersByName(true)
end

function TiledMap:indexLayerObjectsByName()
    self.layers:indexLayerObjectsByName()
end

function TiledMap:initClasses()
    class.init_as(self, self.class)
    self.layers:initClasses()
end

function TiledMap:bindClasses()
    class.reqcast(self, self.class)
    self.layers:bindClasses()
end

function TiledMap:batchLayerTiles()
    local function batch(layer)
        local layertype = layer.type
        if layertype == "tilelayer" then
            layer:batchTiles()
        elseif layertype == "group" then
            for _, sublayer in ipairs(layer) do
                batch(sublayer)
            end
        end
    end
    for _, layer in ipairs(self.layers) do
        batch(layer)
    end
end

function TiledMap:animate(dt)
    self.layers:animate(dt)
end

function TiledMap:draw()
    self.layers:draw()
end

Assets.addLoaders {
    luatileset = function(tilesetassetid, tilesetfile, tilesetref)
        local tilesetdata = assert(love.filesystem.load(tilesetfile))()
        tilesetdata.firstgid = tilesetref.firstgid
        tilesetdata.exportfilename = tilesetref.exportfilename
        local tilesetdir = pathlite.splitpath(tilesetfile)
        return Tileset.from(tilesetdata, tilesetdir)
    end
}

---@param mapfile string
---@return TiledMap
function TiledMap.load(mapfile, options)
    local map = Assets.maps[mapfile]
    if map then
        return map
    end
    local mapf, err = love.filesystem.load(mapfile)
    assert(mapf, err)
    map = mapf() ---@type TiledMap
    setmetatable(map, TiledMap)
    Assets.maps[mapfile] = map
    Assets.all[mapfile] = map

    local mapdir = pathlite.splitpath(mapfile)
    map.directory = mapdir
    map.file = mapfile

    if map.backgroundcolor then
        for i, c in ipairs(map.backgroundcolor) do
            map.backgroundcolor[i] = c / 256
        end
    end

    local maptiles = {}
    map.tiles = maptiles
    local mapobjects = {}
    map.objects = mapobjects
    local nextobjectid = map.nextobjectid

    local function findObjects(layers)
        for i = 1, #layers do
            local layer = layers[i]
            if layer.objects then
                local objects = layer.objects
                for i = 1, #objects do
                    local object = objects[i]
                    if mapobjects[object.id] then
                        error(mapfile.." has two objects with id "..object.id)
                    end
                    if object.id >= nextobjectid then
                        error(mapfile.." object id "..object.id.." is over the next object id "..nextobjectid)
                    end
                    mapobjects[object.id] = object
                    if object.rotation then
                        object.rotation = math.rad(object.rotation)
                    end
                end
            elseif layer.layers then
                findObjects(layer.layers)
            end
        end
    end

    local maptilesets = map.tilesets
    local alltilesets = Assets.tilesets
    for i = 1, #maptilesets do
        local tileset = maptilesets[i]
        if alltilesets[tileset.name] then
            tileset = alltilesets[tileset.name]
            maptilesets[i] = tileset
        else
            if tileset.filename then
                local extfilename = tileset.exportfilename or ""
                assert(pathlite.extension(extfilename) == ".lua",
                    "Tileset " .. tileset.name ..
                        " in map " .. mapfile ..
                        " is external but not exported to lua")
                local tilesetfile = pathlite.normjoin(mapdir, extfilename)
                tileset = Assets.get(tilesetfile.."tileset", tilesetfile, tileset) ---@type Tileset
                maptilesets[i] = tileset
            else
                Tileset.from(tileset, mapdir)
            end
            alltilesets[tileset.name] = tileset
        end
        for t = 0, tileset.tilecount - 1 do
            maptiles[#maptiles + 1] = tileset[t]
        end
    end

    local function doLayer(layer)
        local layertype = layer.type
        layer.x = layer.offsetx
        layer.y = layer.offsety
        if layertype == "group" then
            LayerGroup.from(layer)
            for i = 1, #layer do
                doLayer(layer[i])
            end
        elseif layertype == "tilelayer" then
            TileLayer.from(layer, map)
        elseif layertype == "objectgroup" then
            ObjectGroup.from(layer, map)
        elseif layertype == "imagelayer" then
            ImageLayer.from(layer, mapdir)
        end
        Properties.resolveAssetPaths(layer.properties, mapdir)
        Properties.resolveObjectRefs(layer.properties, mapobjects)
        Properties.moveUp(layer)
    end

    local layers = map.layers
    layers.type = "group"
    LayerGroup.cast(layers)
    findObjects(layers)

    for i = 1, #layers do
        local layer = layers[i]
        doLayer(layer)
    end
    Properties.resolveAssetPaths(map.properties, mapdir)
    Properties.resolveObjectRefs(map.properties, mapobjects)
    Properties.moveUp(map)

    if options then
        if options.index == "all" then
            map:indexEverythingByName()
        end
        if options.withclasses then
            map:initClasses()
        end
    end

    return map
end

return TiledMap