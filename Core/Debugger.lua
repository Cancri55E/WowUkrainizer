local _, ns = ...;

local internal = {}
ns.Debugger = internal

function internal.GenerateUuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function internal.PrintTableFunctions(tbl, prefix)
    prefix = prefix or ""
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            internal.PrintTable(value, prefix .. key .. ".")
        elseif type(value) == "function" and type(value) ~= 'userdata' then
            print(prefix .. key .. ": " .. tostring(value))
        end
    end
end
