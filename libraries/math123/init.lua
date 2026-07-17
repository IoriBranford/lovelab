local math1 = require "math123.math1"
local math2 = require "math123.math2"
local math3 = require "math123.math3"

local math123 = {
    math1,
    math2,
    math3,
}

function math123.goGlobal()
    _G.math1 = math1
    _G.math2 = math2
    _G.math3 = math3
end

return math123
