local class = require "Tiled.class"
local showOnlyNamed = require "Tiled.showOnlyNamed"

---@class Layer:Class
---@field layer Layer? parent layer
---@field type "tilelayer"|"objectgroup"|"imagelayer"|"group"
---@field id integer Unique ID of the layer (defaults to 0, with valid IDs being at least 1). Each layer that added to a map gets a unique id. Even if a layer is deleted, no layer ever gets the same ID. Can not be changed in Tiled. (since Tiled 1.2)
---@field name string The name of the image layer. (defaults to “”)
---@field class string The class of the image layer (since 1.9, defaults to “”).
---@field parallaxx number Horizontal parallax factor for this layer. Defaults to 1. (since 1.5)
---@field parallaxy number Vertical parallax factor for this layer. Defaults to 1. (since 1.5)
---@field x number The x position of the image layer in pixels. Copy of offsetx
---@field y number The y position of the image layer in pixels. Copy of offsety
---@field opacity number The opacity of the layer as a value from 0 to 1. (defaults to 1)
---@field visible boolean Whether the layer is shown (1) or hidden (0). (defaults to 1)
---@field tintcolor Color A color that is multiplied with the image drawn by this layer in #AARRGGBB or #RRGGBB format (optional).
---@field z number? Drawing order. Set in editor with layer property "z" (float or int). Call initLayersZ to set defaults based on layer hierarchy.
---@field [integer] Layer|TiledObject for group and objectgroup layers
local Layer = class()

function Layer:setVisible(visible)
    self.visible = visible
end

function Layer:setVisibleDown(visible)
    self:setVisible(visible)
    for _, child in ipairs(self) do
        if self.type == "group"
        or self.type == "objectgroup" then
            ---@cast child LayerGroup
            child:setVisibleDown(visible)
        else
            child:setVisible(visible)
        end
    end
end

function Layer:setVisibleUp(visible)
    self:setVisible(visible)
    if self.layer then
        self.layer:setVisibleUp(visible)
    end
end

function Layer:getWorldPosition()
    local x, y = self.x, self.y
    local parent = self.layer
    while parent do
        x = x + parent.x
        y = y + parent.y
        parent = parent.layer
    end
    return x, y
end

function Layer:move(dx, dy)
    local x = self.x + dx
    local y = self.y + dy
    self.x, self.y = x, y
    for i = 1, #self do
        self[i]:move(dx, dy)
    end
end

function Layer:moveTo(x, y)
    self:move(x - self.x, y - self.y)
end

function Layer:hideChildrenIf(condition)
    for _, child in ipairs(self) do
        child:setVisible(condition(child))
    end
end

Layer.showOnlyNamed = showOnlyNamed

function Layer:animate(dt)
end

function Layer:draw()
end

return Layer