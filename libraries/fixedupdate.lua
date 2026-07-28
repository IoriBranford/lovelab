local modf = math.modf

local function fixedupdate(fps, t, dt, f, ...)
    local n
    n, t = modf(t + dt*fps)
    for _ = 1, n do
        f(...)
    end
    return t, n
end

return fixedupdate