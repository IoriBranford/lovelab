local InputString = {}

function InputString.key(key)
    return string.format("key %s", key)
end

function InputString.keyaxis(negative, positive)
    return string.format("keyaxis %s %s", negative, positive)
end

function InputString.gamepadaxis(gamepadid, axis)
    return string.format("pad%d axis %s", gamepadid, axis)
end

function InputString.gamepadbutton(gamepadid, button)
    return string.format("pad%d button %s", gamepadid, button)
end

function InputString.gamepadbuttonaxis(gamepadid, negative, positive)
    return string.format("pad%d buttonaxis %s %s", gamepadid, negative, positive)
end

function InputString.get(type, ...)
    return InputString[type](...)
end

return InputString