--[[
https://github.com/openresty/lua-tablepool

This module is licensed under the BSD license.

Copyright (C) 2016-2021, by Yichun "agentzh" Zhang, OpenResty Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

local newtab = require "table.new"
local cleartab = require "table.clear"
local setmetatable = setmetatable


local _M = newtab(0, 2)
local max_pool_size = 200
local pools = newtab(0, 4)


function _M.fetch(tag, narr, nrec)
    local pool = pools[tag]
    if not pool then
        pool = newtab(4, 1)
        pools[tag] = pool
        pool.c = 0
        pool[0] = 0

    else
        local len = pool[0]
        if len > 0 then
            local obj = pool[len]
            pool[len] = nil
            pool[0] = len - 1
            -- ngx.log(ngx.ERR, "HIT")
            return obj
        end
    end

    return newtab(narr, nrec)
end


function _M.release(tag, obj, noclear)
    if not obj then
        error("object empty", 2)
    end

    local pool = pools[tag]
    if not pool then
        pool = newtab(4, 1)
        pools[tag] = pool
        pool.c = 0
        pool[0] = 0
    end

    do
        local cnt = pool.c + 1
        if cnt >= 20000 then
            pool = newtab(4, 1)
            pools[tag] = pool
            pool.c = 0
            pool[0] = 0
            return
        end
        pool.c = cnt
    end

    local len = pool[0] + 1
    if len > max_pool_size then
        -- discard it simply
        return
    end

    if not noclear then
        setmetatable(obj, nil)
        cleartab(obj)
    end

    pool[len] = obj
    pool[0] = len
end


return _M

-- vi: ft=lua ts=4 sw=4 et
