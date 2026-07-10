local function fixed_timestep(fps)
    local t = 0
    return function(dt, fixedupdate, ...)
        local n
        n, t = math.modf(t + dt*fps)
        for _ = 1, n do
            fixedupdate(...)
        end
        return t
    end
end

return fixed_timestep