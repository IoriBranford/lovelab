---@class AseSliceKey
---@field frame integer
---@field bounds AseRect
---@field center AseRect?
---@field pivot AsePoint?

---@class AseSlice
---@field name string
---@field color Color
---@field data string?
---@field keys {[integer]:AseSliceKey}
local AseSlice = class()

function AseSlice:getFrameOrigin(i)
    local key = self.keys[i]
	if key then
		local pivotx, pivoty = 0, 0
		if key.pivot then
			pivotx, pivoty = key.pivot.x, key.pivot.y
		end
		return key.bounds.x + pivotx, key.bounds.y + pivoty
	end
end

return AseSlice