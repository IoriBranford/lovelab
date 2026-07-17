---@class ihash<T>
---@field [integer] T
---@field [T] integer
local ihash = {}

---add element
---@generic T
---@param h ihash<T>
---@param t T
---@return integer i
function ihash.add(h, t)
    local i = h[t] or #h+1
    h[i] = t
    h[t] = i
    return i
end

---remove element
---@generic T
---@param h ihash<T>
---@param t T
---@return integer? i
---@return T? u
function ihash.remove(h, t)
    local i = h[t]
    if not i then return end

    local u = h[#h]
    h[i] = u
    h[u] = i
    h[#h] = nil
    h[t] = nil
    return i, u
end

---prune dead elements
---@generic T
---@param h ihash<T>
---@param tdead fun(t:T):boolean
---@param tcleanup fun(t:T)?
---@return integer n
function ihash.prune(h, tdead, tcleanup)
    tcleanup = tcleanup or function() end
    local n = 0
    local remove = ihash.remove
    for i = #h, 1, -1 do
        local t = h[i]
        if tdead(t) then
            tcleanup(t)
            remove(h, t)
            n = n + 1
        end
    end
    return n
end

return ihash
