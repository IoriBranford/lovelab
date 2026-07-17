local class = require "Tiled.class"
local indexElementsByName = require "Tiled.indexElementsByName"
local Graphics = require "Tiled.Graphics"
local Layer    = require "Tiled.Layer"

---@class LayerGroup:Layer
---@field [integer] Layer Copied from layers
---@field [string] Layer? Layers in group by name, after Map:indexLayersByName is called
----@field layers Layer[] Copied to layer's array part
local LayerGroup = class(Layer)

function LayerGroup:_init()
    local grouplayers = self.layers ---@type Layer[]
    if not grouplayers then return end
    for i = 1, #grouplayers do
        local layer = grouplayers[i]
        layer.layer = self
        self[i] = layer
    end
    self.layers = nil
end

function LayerGroup:indexLayersByName(recursive)
    indexElementsByName(self)
    if recursive then
        for _, layer in ipairs(self) do
            if layer.type == "group" then
                ---@cast layer LayerGroup
                layer:indexLayersByName(recursive)
            end
        end
    end
end

function LayerGroup:indexLayerObjectsByName()
    for _, layer in ipairs(self) do
        local layertype = layer.type
        if layertype == "group" then
            ---@cast layer LayerGroup
            layer:indexLayerObjectsByName()
        elseif layertype == "objectgroup" then
            ---@cast layer ObjectGroup
            layer:indexObjectsByName()
        end
    end
end

function LayerGroup:bindClasses()
    class.reqcast(self, self.class)
    for _, layer in ipairs(self) do
        if layer.type == "group" then
            ---@cast layer LayerGroup
            layer:bindClasses()
        else
            class.reqcast(layer, layer.class)
            for _, object in ipairs(layer) do
                class.reqcast(object, object.type)
            end
        end
    end
end

function LayerGroup:initClasses()
    class.init_as(self, self.class)
    for _, layer in ipairs(self) do
        if layer.type == "group" then
            ---@cast layer LayerGroup
            layer:initClasses()
        else
            class.init_as(layer, layer.class)
            for _, object in ipairs(layer) do
                class.init_as(object, object.type)
            end
        end
    end
end

function LayerGroup:animate(dt)
    for _, object in ipairs(self) do
        if object.animate then
            object:animate(dt)
        end
    end
end

local pushTransform = Graphics.pushTransform

function LayerGroup:draw()
    pushTransform(self)
    for _, layer in ipairs(self) do
        if layer.visible then
            layer:draw()
        end
    end
    love.graphics.pop()
end

return LayerGroup