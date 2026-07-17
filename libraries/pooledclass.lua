local setmetatable = setmetatable
local tablepool = require "tablepool"
local clear = require "table.clear"
local fetch = tablepool.fetch
local release = tablepool.release

local function initObject(object, class, ...)
    setmetatable(object, class)
    local init = object._init
    if init then
        init(object, ...)
    end
    return object
end

local function createObject(class, ...)
    local object = fetch(class,
        class._narr, class._nrec)
    return initObject(object, class, ...)
end

---@param base Class?
---@param init function?
local function createClass(base, init)
    ---@class PooledClass
    local class = {
        _init = init,
        _narr = 0,
        _nrec = 0
    }
    class.__index = class

    function class:_release()
        clear(self)
        release(class, self, true)
    end

    function class.cast(t)
        return setmetatable(t, class)
    end

    function class.from(t, ...)
        return initObject(t, class, ...)
    end

    function class.super(t)
        local baseinit = base and base._init
        if baseinit then
            baseinit(t)
        end
    end

    if base then
        -- metamethods must be copied as they can't be inherited
        class.__lt = base.__lt
    end

    local classmt = {
        __call = createObject,
        __index = base
    }

    return setmetatable(class, classmt)
end

local function reqCast(object, requirestr)
    requirestr = requirestr or ""
    if requirestr == "" then
        return
    end
    local ok, class = pcall(require, requirestr)
    if not ok then
        return nil, class
    end
    return setmetatable(object, class)
end

local function initAs(object, requirestr, ...)
    requirestr = requirestr or ""
    if requirestr == "" then
        return
    end
    local ok, class = pcall(require, requirestr)
    if not ok then
        return nil, class
    end
    return class.from(object, ...)
end

return setmetatable({
    reqcast = reqCast,
    init_as = initAs
}, {
    __call = function(_, ...)
        return createClass(...)
    end
})