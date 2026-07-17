local function addIfNew(t, k, v)
    if t[k] ~= nil then
        print(string.format("W: tried to overwrite duplicate or reserved field name %s in %s", k, t.name or t))
    else
        t[k] = v
    end
end

return addIfNew