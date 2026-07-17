local has_ffi, ffi = pcall(require, "ffi")
if not has_ffi then
    return false
end

local dllnames = {
    "vgm-player-c",
    "vgm-player-c_Win64",
    "vgm-player-c_Win64d",
}
local ok, libvgmplayer
for _, dllname in ipairs(dllnames) do
    ok, libvgmplayer = pcall(ffi.load, dllname)
    if ok then
        break
    end
end
if not ok then
    print(libvgmplayer)
    return false
end

ffi.cdef[[
typedef struct PlayerA PlayerA;
typedef struct DATA_LOADER DATA_LOADER;

typedef struct PlayerC {
    PlayerA *player;
    DATA_LOADER *loader;
} PlayerC;

PlayerC* PlayerC_NewVGM();
uint8_t PlayerC_SetOutputSettings(PlayerC *p, uint32_t smplRate, uint8_t channels, uint8_t smplBits, uint32_t smplBufferLen);
void PlayerC_SetLoopCount(PlayerC *p, uint32_t loopCount);
void PlayerC_SetFadeSeconds(PlayerC *p, uint32_t seconds);

uint8_t PlayerC_LoadFile(PlayerC *p, const char *filename);
uint8_t PlayerC_LoadMemory(PlayerC *p, const uint8_t *data, uint32_t length);

uint8_t PlayerC_Start(PlayerC *p);
uint32_t PlayerC_Render(PlayerC *p, uint32_t bufSize, void *data);
uint8_t PlayerC_FadeOut(PlayerC *p);
uint8_t PlayerC_Stop(PlayerC *p);

void PlayerC_delete(PlayerC *p);
]]

ffi.metatype("PlayerC", {
    __gc = function(p)
        libvgmplayer.PlayerC_delete(p)
    end
})

return libvgmplayer