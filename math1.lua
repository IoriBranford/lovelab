local Debug_acosOutOfRange = true

if Debug_acosOutOfRange then
    local acos = math.acos
    ---@diagnostic disable-next-line duplicate-set-field
    function math.acos(x)
        assert(-1 <= x and x <= 1, "acos(|x| > 1)")
        return acos(x)
    end
end

local min = math.min
local max = math.max
local rad = math.rad
local modf = math.modf
local abs = math.abs

function math.sign(x)
    return x == 0 and 1 or x/abs(x)
end

function math.round(x)
    local i, f = modf(x)
    if x < 0 then
        return f > -0.5 and i or i - 1
    end
    return f < 0.5 and i or i + 1
end

function math.clamp(x, a, b)
    return max(a, min(x, b))
end

function math.lerp(t, a, b)
    return a + t*(b-a)
end

function math.table_rad(t, k)
    local x = t[k]
    if type(x) == "number" then
        t[k] = rad(x)
    end
end