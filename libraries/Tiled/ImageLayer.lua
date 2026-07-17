local class = require "Tiled.class"
local Assets = require "Tiled.Assets"
local Color  = require "Tiled.Color"
local Layer  = require "Tiled.Layer"
local pathlite = require "Tiled.pathlite"

---@class ImageLayer:Layer
---@field type string "imagelayer"
---@field repeatx boolean Whether the image drawn by this layer is repeated along the X axis. (since Tiled 1.8)
---@field repeaty boolean Whether the image drawn by this layer is repeated along the Y axis. (since Tiled 1.8)
---@field imagefile string
---@field image love.Image|string
---@field shader love.Shader?
local ImageLayer = class(Layer)

function ImageLayer:_init(directory)
    local imagefile = self.image
    if type(imagefile) ~= "string" then return end
    if directory ~= "" then
        imagefile = pathlite.normjoin(directory, imagefile)
    end
    self.imagefile = imagefile
    self.image = Assets.get(self.imagefile)
end

function ImageLayer:draw()
    local r,g,b,a = Color.unpack(self.tintcolor)
    love.graphics.setColor(r,g,b,a)
    love.graphics.draw(self.image,
        (self.x), (self.y),
        self.rotation or 0,
        self.scalex or 1, self.scaley or 1,
        self.originx or 0, self.originy or 0,
        self.skewx or 0, self.skewy or 0)
end

return ImageLayer