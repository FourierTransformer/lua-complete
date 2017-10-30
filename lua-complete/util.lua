local util = {}

-- add things from b to a
function util.appendTables(a, b)
    for k, v in pairs(b) do
        a[k] = v
    end
end

return util
