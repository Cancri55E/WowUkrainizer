local _, ns = ...;

local internal = {}
ns.CommonExtensions = internal

function internal.GenerateUuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function internal.IsValueInTable(table, value, key)
    for _, row in ipairs(table) do
        local valueToCheck = key and row[key] or row
        if valueToCheck == value then
            return true
        end
    end
    return false
end
