local math1 = {}

local Debug_acosOutOfRange = false

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

function math1.sign(x)
    return x == 0 and 1 or x/abs(x)
end

function math1.round(x)
    local i, f = modf(x)
    if x < 0 then
        return f > -0.5 and i or i - 1
    end
    return f < 0.5 and i or i + 1
end

function math1.clamp(x, a, b)
    return max(a, min(x, b))
end

function math1.lerp(t, a, b)
    return a + t*(b-a)
end

return math1