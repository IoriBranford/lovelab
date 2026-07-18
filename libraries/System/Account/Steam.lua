local hassteam, luasteam = pcall(require, "luasteam")
if not hassteam then
	return false
end

local SteamAccount = {}

local initialized

function SteamAccount.init()
    initialized = luasteam.init()
end

function SteamAccount.update()
    if not initialized then return end
    luasteam.runCallbacks()
end

function SteamAccount.quit()
    if initialized then
        luasteam.shutdown()
        initialized = nil
    end
end

return SteamAccount