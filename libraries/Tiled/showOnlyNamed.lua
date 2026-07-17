---@param self LayerGroup|ObjectGroup
local function showOnlyNamed(self, ...)
    local n = select("#", ...)
    if n < 1 then
        for _, child in ipairs(self) do
            child:setVisible(false)
        end
        return
    end

    for _, child in ipairs(self) do
        local name = child.name or ""
        local visible = false
        if name ~= "" then
            for arg = 1, n do
                if name == select(arg, ...) then
                    visible = true
                    break
                end
            end
        end
        child:setVisible(visible)
    end
end

return showOnlyNamed