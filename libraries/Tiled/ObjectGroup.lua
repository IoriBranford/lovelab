local class = require "Tiled.class"
local Object = require "Tiled.Object"
local Graphics = require "Tiled.Graphics"
local Layer    = require "Tiled.Layer"

---@class ObjectGroup:Layer
---@field type string "objectgroup"
---@field color Color? The color used to display the objects in this group. (optional)
---@field draworder string Whether the objects are drawn according to the order of appearance (“index”) or sorted by their y-coordinate (“topdown”). (defaults to “topdown”)
---@field [integer] TiledObject Copied from objects
---@field [string] TiledObject? Objects with names, after Map:indexLayerObjectsByName is called
----@field objects TiledObject[] Copied to layer's array part
local ObjectGroup = class(Layer)

function ObjectGroup:_init(map)
    local objects = self.objects
    if not objects then return end
    for i = 1, #objects do
        local object = objects[i]
        object.layer = self
        self[i] = Object.from(object, map)
    end
    self.objects = nil
    return self
end

ObjectGroup.indexObjectsByName = require "Tiled.indexElementsByName"

function ObjectGroup:findObject(f, ...)
    for _, object in ipairs(self) do
        if f(object, ...) then
            return object
        end
    end
end

function ObjectGroup:animate(dt)
    for _, object in ipairs(self) do
        object:animate(dt)
    end
end

local pushTransform = Graphics.pushTransform

function ObjectGroup:draw()
    pushTransform(self)
    for _, object in ipairs(self) do
        if object.visible then
            object:draw()
        end
    end
    love.graphics.pop()
end

return ObjectGroup