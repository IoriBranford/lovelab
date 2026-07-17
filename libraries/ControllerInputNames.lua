local ControllerInputNames = {
    XBOX = {
        a = "A",
        b = "B",
        x = "X",
        y = "Y",
        start = "Start",
        back = "Back",
        leftshoulder = "LB",
        rightshoulder = "RB",
        triggerleft = "LT",
        triggerright = "RT",
        leftstick = "LS",
        rightstick = "RS",
        guide = "Guide",
    },
    SWITCH = {
        a = "B",
        b = "A",
        x = "Y",
        y = "X",
        start = "+",
        back = "-",
        leftshoulder = "L",
        rightshoulder = "R",
        triggerleft = "ZL",
        triggerright = "ZR",
        leftstick = "LS",
        rightstick = "RS",
        guide = "Home",
    },
    ["PS1/2/3"] = {
        a = "⨯",
        b = "○",
        x = "□",
        y = "△",
        start = "Start",
        back = "Select",
        leftshoulder = "L1",
        rightshoulder = "R1",
        triggerleft = "L2",
        triggerright = "R2",
        leftstick = "L3",
        rightstick = "R3",
        guide = "PS",
    },
}

local PS4 = {}
ControllerInputNames.PS4 = PS4
for k,v in pairs(ControllerInputNames["PS1/2/3"]) do
    PS4[k] = v
end
ControllerInputNames.PS4.start = "Options"
ControllerInputNames.PS4.back = "Share"

local PS5 = {}
ControllerInputNames.PS5 = PS5
for k,v in pairs(ControllerInputNames["PS1/2/3"]) do
    PS5[k] = v
end
ControllerInputNames.PS5.start = "≡"
ControllerInputNames.PS5.back = "Create"

return ControllerInputNames