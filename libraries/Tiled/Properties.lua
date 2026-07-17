local Properties = {}

local addIfNew = require "Tiled.addIfNew"
local Assets   = require "Tiled.Assets"
local pathlite = require "Tiled.pathlite"

function Properties.resolveAssetPaths(properties, directory)
    if (directory or "") == "" then return end
    for k,v in pairs(properties) do
        if type(v) == "table" then
            if v.id then
            else
                Properties.resolveAssetPaths(v, directory)
            end
        elseif Assets.isAsset(v) then
            properties[k] = pathlite.normjoin(directory, v)
        end
    end
end

function Properties.resolveObjectRefs(properties, mapobjects)
    for k,v in pairs(properties) do
        if type(v) == "table" then
            if v.id then
                properties[k] = mapobjects[v.id]
            else
                Properties.resolveObjectRefs(v, mapobjects)
            end
        end
    end
end

function Properties.moveUp(t, dest)
    local properties = t.properties
    if properties then
        dest = dest or t
        for k, v in pairs(properties) do
            addIfNew(dest, k, v)
        end
        t.properties = nil
    end
end

return Properties