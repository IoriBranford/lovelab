local huge = math.huge

---@generic T: {x: number, y: number, z: number}
---@param x number
---@param y number
---@param items T[]
---@return T closest, number closestdsq
return function(items, x, y, z)
    local closest
    local closestdsq = huge
    for i = 1, #items do
        local item = items[i]
        local ix, iy, iz = item.x, item.y, item.z
        local dx, dy, dz = x - ix, y - iy, z - iz
        local dsq = dx*dx + dy*dy + dz*dz
        if dsq < closestdsq then
            closest = item
            closestdsq = dsq
        end
    end
    return closest, closestdsq
end