local InputParse = {}

---@return KeyInput?
function InputParse.key(s)
    local key = string.match(s, "^key (%S+)$")
    return {
        type = "key", key = key
    }
end

---@return KeyAxisInput?
function InputParse.keyaxis(s)
    local negative, positive = string.match(s, "^keyaxis (%S+) (%S+)$")
    return {
        type = "keyaxis", negative = negative, positive = positive
    }
end

function InputParse.pad(s)
    local gamepadid, inputtype, values = string.match(s, "^pad(%d+) (%w+) ([%w ]+)$")
    local padparse = InputParse[inputtype]
    return padparse and padparse({
        gamepadid = tonumber(gamepadid)
    }, values)
end

---@return GamepadAxisInput?
function InputParse.axis(input, axis)
    input.type = "gamepadaxis"
    input.axis = axis
    return input
end

---@return GamepadButtonInput?
function InputParse.button(input, button)
    input.type = "gamepadbutton"
    input.button = button
    return input
end

function InputParse.buttonaxis(input, values)
    local negative, positive = string.match(values, "^(%w+) (%w+)$")
    input.type = "gamepadbuttonaxis"
    input.negative = negative
    input.positive = positive
    return input
end

function InputParse.parse(s)
    local device = string.match(s, "^(%a+)")
    local parse = InputParse[device]
    if parse then return parse(s) end
end

return InputParse