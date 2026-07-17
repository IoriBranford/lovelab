---@class multitask
---@field [integer] any function is a task, all others are results
---@field index table<string,integer>
local multitask = {}
multitask.__index = multitask

local type = type

---@return multitask
function multitask.new()
    return setmetatable({index = {}}, multitask)
end

function multitask:push(func, name)
    local i = #self+1
    self[i] = func
    if name and type(name) == "string" then
        self.index[i] = name
        self.index[name] = i
    end
    return i
end

function multitask:run1(i, ...)
    if type(i) ~= "number" then i = self.index[i] end
    if not i then return end

    local task = self[i]
    if type(task) == "function" then
        local result = task(...)
        if result ~= nil then
            self[i] = result
        end
    end
end

function multitask:runAll(...)
    for i = 1, #self do
        self:run1(i, ...)
    end
end

function multitask:peek(i)
    if type(i) ~= "number" then i = self.index[i] end
    if not i then return end
    local result = self[i]
    return type(result) ~= "function" and result
end

function multitask:take(i)
    if type(i) ~= "number" then i = self.index[i] end
    if not i then return end
    local result = self[i]
    if type(result) == "function" then return end
    self[i] = nil
    local name = self.index[i]
    if name then
        self.index[name] = nil
        self.index[i] = nil
    end
    return result
end

function multitask:allDone()
    for i = 1, #self do
        if type(self[i]) == "function" then
            return false
        end
    end
    return true
end

function multitask:clear()
    self.index = {}
    for i = #self, 1, -1 do
        self[i] = nil
    end
end

return multitask