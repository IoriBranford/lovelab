local addIfNew = require "Tiled.addIfNew"

local function indexElementsByName(array, i0)
    for i = (i0 or 1), #array do
        local element = array[i]
        local name = element.name or ""
        if name ~= "" then
            addIfNew(array, name, element)
        end
    end
end

return indexElementsByName