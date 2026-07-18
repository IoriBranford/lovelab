local Platform = require "System.Platform"
local InputParse = require "System.InputParse"
local InputString= require "System.InputString"

local Inputs = {}

local DefaultPressThreshold = .25

---@alias InputString string

local inputs = {} ---@type {[InputString]: Input}
local actions = {} ---@type {[string]: InputAction}
local gamepadsbyid = {} ---@type {[integer]: love.Joystick} gamepads by id
local gamepadconfigs = {}
local gamepaddefaultconfig = {}
local keyboardconfig = {}
local enabledinputtypes = { ---@type {[InputType]: boolean}
    key = true,
    keyaxis = true,
    gamepadbutton = true,
    gamepadaxis = true,
    gamepadbuttonaxis = true
}

---@class InputAction
---@field name string
---@field position number
---@field lastposition number
---@field pressthreshold number
---@field pressed boolean
---@field down boolean
---@field released boolean

---@alias InputType "key"|"keyaxis"|"gamepadbutton"|"gamepadbuttonaxis"|"gamepadaxis"

---@class Input
---@field type InputType
---@field action InputAction

---@class KeyInput:Input
---@field type "key"
---@field key love.KeyConstant

---@class KeyAxisInput:Input
---@field type "keyaxis"
---@field positive love.KeyConstant
---@field negative love.KeyConstant

---@class GamepadButtonInput:Input
---@field type "gamepadbutton"
---@field gamepadid integer
---@field button love.GamepadButton

---@class GamepadButtonAxisInput:Input
---@field type "gamepadbuttonaxis"
---@field gamepadid integer
---@field positive love.GamepadButton
---@field negative love.GamepadButton

---@class GamepadAxisInput:Input
---@field type "gamepadaxis"
---@field gamepadid integer
---@field axis love.GamepadAxis

local InputPosition = {}

---@param input KeyInput
function InputPosition.key(input)
    return love.keyboard.isDown(input.key) and 1 or 0
end

---@param input KeyAxisInput
function InputPosition.keyaxis(input)
    return (love.keyboard.isDown(input.positive) and 1 or 0)
        - (love.keyboard.isDown(input.negative) and 1 or 0)
end

---@param input GamepadAxisInput
function InputPosition.gamepadaxis(input)
    local gamepad = gamepadsbyid[input.gamepadid]
    return gamepad and gamepad:getGamepadAxis(input.axis) or 0
end

---@param input GamepadButtonInput
function InputPosition.gamepadbutton(input)
    local gamepad = gamepadsbyid[input.gamepadid]
    return gamepad and gamepad:isGamepadDown(input.button) and 1 or 0
end

---@param input GamepadButtonAxisInput
function InputPosition.gamepadbuttonaxis(input)
    local gamepad = gamepadsbyid[input.gamepadid]
    return gamepad and
        ((gamepad:isGamepadDown(input.positive) and 1 or 0)
        - (gamepad:isGamepadDown(input.negative) and 1 or 0))
        or 0
end

function InputPosition.get(input)
    return InputPosition[input.type](input)
end

function Inputs.initGamepads(defaultconfig)
    if defaultconfig then
        gamepaddefaultconfig = defaultconfig
    end
    if love.filesystem.getInfo("data/gamecontrollerdb.txt", "file") then
        love.joystick.loadGamepadMappings("data/gamecontrollerdb.txt")
    end
    if love.filesystem.getInfo("gamecontrollerdb.txt", "file") then
        love.joystick.loadGamepadMappings("gamecontrollerdb.txt")
    end
end

function Inputs.saveGamepadMappings()
    love.joystick.saveGamepadMappings("gamecontrollerdb.txt")
end

---@param joystick love.Joystick
function Inputs.joystickadded(joystick)
    local id = joystick:getID()
    gamepadsbyid[id] = joystick

    if not joystick:isGamepad() then
        local DefaultMapping = "%s,%s,a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b8,leftshoulder:b4,leftstick:b9,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b10,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3,platform:%s,"

        local os = Platform.OS
        local GCDBOS = {
            ["OS X"] = "Mac OS X"
        }
        os = GCDBOS[os] or os
        local mapping = string.format(DefaultMapping, joystick:getGUID(), joystick:getName(), os)
        love.joystick.loadGamepadMappings(mapping)
    end

    local gamepadconfig = gamepadconfigs[id]
    if not gamepadconfig then
        gamepadconfig = {}
        gamepadconfigs[id] = gamepadconfig
    end

    for gamepadinput, actionname in pairs(gamepaddefaultconfig) do
        if not gamepadconfig[gamepadinput] then
            Inputs.configureGamepadInput(id, gamepadinput, actionname)
        end
    end
end

function Inputs.enableTypes(...)
    for i = 1, select("#", ...) do
        local inputtype = select(i, ...) ---@type InputType
        if enabledinputtypes[inputtype] ~= nil then
            enabledinputtypes[inputtype] = true
        end
    end
end

function Inputs.disableTypes(...)
    for i = 1, select("#", ...) do
        local inputtype = select(i, ...) ---@type InputType
        if enabledinputtypes[inputtype] ~= nil then
            enabledinputtypes[inputtype] = false
        end
    end
end

function Inputs.getAction(name)
    return actions[name]
end

function Inputs.getOrMakeAction(name)
    local action = actions[name]
    if not action then
        action = {
            name = name,
            position = 0,
            lastposition = 0,
            numinputsdown = 0,
            pressed = false,
            down = false,
            released = false,
            pressthreshold = DefaultPressThreshold
        }
        actions[name] = action
    end
    return action
end

---@deprecated
function Inputs.addInputAction(inputstring, actionname)
    local input = InputParse.parse(inputstring)
    if input then
        input.action = Inputs.getOrMakeAction(actionname)
        inputs[inputstring] = input
        return input
    end
end

function Inputs.configureKey(keyinput, actionname)
    local key1, key2 = string.match(keyinput, "^(%S+) *(%S*)$")
    local input

    if (key2 or "") ~= "" then
        ---@type KeyAxisInput
        input = {
            type = "keyaxis",
            action = Inputs.getOrMakeAction(actionname),
            negative = key1,
            positive = key2,
        }
    elseif key1 then
        ---@type KeyInput
        input = {
            type = "key",
            action = Inputs.getOrMakeAction(actionname),
            key = key1,
        }
    end

    if input then
        local inputstring = InputString.get(input.type, key1, key2)
        inputs[inputstring] = input
        keyboardconfig[keyinput] = actionname
        return input
    end
end

function Inputs.configureKeyboard(keyinputs)
    for keyinput, actionname in pairs(keyinputs) do
        Inputs.configureKey(keyinput, actionname)
    end
    return keyboardconfig
end

local GamepadInputTypes = {
    leftx = "axis",
    lefty = "axis",
    rightx = "axis",
    righty = "axis",
    triggerleft = "axis",
    triggerright = "axis",
    a = "button",
    b = "button",
    x = "button",
    y = "button",
    leftstick = "button",
    rightstick = "button",
    leftshoulder = "button",
    rightshoulder = "button",
    back = "button",
    start = "button",
    dpup = "button",
    dpdown = "button",
    dpleft = "button",
    dpright = "button",
    guide = "button",
    touchpad = "button",
    paddle1 = "button",
    paddle2 = "button",
    paddle3 = "button",
    paddle4 = "button",
    misc1 = "button"
}

function Inputs.configureGamepadInput(gamepadid, gamepadinput, actionname)
    local input1, input2 = string.match(gamepadinput, "^(%S+) *(%S*)$")
    local input
    if (input2 or "") ~= "" then
        input = {
            type = "gamepadbuttonaxis",
            action = Inputs.getOrMakeAction(actionname),
            gamepadid = gamepadid,
            negative = input1,
            positive = input2,
        }
    elseif input1 then
        local inputtype = GamepadInputTypes[input1]
        if inputtype then
            input = {
                type = "gamepad"..inputtype,
                action = Inputs.getOrMakeAction(actionname),
                gamepadid = gamepadid,
                [inputtype] = input1
            }
        end
    end

    if input then
        local gamepadconfig = gamepadconfigs[gamepadid]
        if not gamepadconfig then
            gamepadconfig = {}
            gamepadconfigs[gamepadid] = gamepadconfig
        end
        gamepadconfig[gamepadinput] = actionname

        local inputstring = InputString.get(input.type, gamepadid, input1, input2)
        inputs[inputstring] = input
        return input
    end
end

function Inputs.configureGamepad(gamepadid, gamepadconfig)
    for input, actionname in pairs(gamepadconfig) do
        Inputs.configureGamepadInput(gamepadid, input, actionname)
    end
end

function Inputs.configureGamepads(newgamepadconfigs)
    for gamepadid, gamepadconfig in pairs(newgamepadconfigs) do
        Inputs.configureGamepad(gamepadid, gamepadconfig)
    end
    return gamepadconfigs
end

---@deprecated
function Inputs.addInputActions(inputactions)
    for inputstring, actionname in pairs(inputactions) do
        Inputs.addInputAction(inputstring, actionname)
    end
end

local InputTypePatterns = {}
for _, inputtype in pairs({"key", "keyaxis", "gamepadbutton", "gamepadaxis", "gamepadbuttonaxis"}) do
    InputTypePatterns[inputtype] = "^%f[%g]"..inputtype.."%f[%G]"
end

function Inputs.getActionsInputs(inputtypes)
    local actionsinputs = {} ---@type {[InputAction]:{[InputString]:Input}}
    for inputstring, input in pairs(inputs) do
        if not inputtypes or inputtypes:find(InputTypePatterns[input.type]) then
            local action = input.action
            local actioninputs = actionsinputs[action] or {}
            actionsinputs[action] = actioninputs
            actioninputs[inputstring] = input
        end
    end

    return actionsinputs
end

function Inputs.removeInput(inputstring)
    local input = inputs[inputstring]
    inputs[inputstring] = nil
end

function Inputs.update()
    for _, action in pairs(actions) do
        action.lastposition = action.position
        action.position = 0
    end

    for _, input in pairs(inputs) do
        if enabledinputtypes[input.type] then
            local position = InputPosition.get(input)
            local action = input.action
            action.position = action.position + position
        end
    end

    for _, action in pairs(actions) do
        local wasdown = math.abs(action.lastposition) > action.pressthreshold
        if math.abs(action.position) > action.pressthreshold then
            action.down = true
            action.pressed = not wasdown
            action.released = false
        else
            action.down = false
            action.pressed = false
            action.released = wasdown
        end
    end
end

return Inputs