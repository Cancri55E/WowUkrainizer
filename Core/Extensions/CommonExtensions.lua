--- @class WowUkrainizerInternals
local ns = select(2, ...);

--- Utility module providing versatile functions for a variety of tasks
---@class CommonUtil
local internal = {}
ns.CommonUtil = internal

--- Generate a UUID.
---@return string @The generated UUID.
function internal.GenerateUuid()
    local guid = string.gsub('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx', '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
    return guid
end

--- Check if a value exists in a table.
---@param tbl table @The table to search.
---@param value any @The value to search for.
---@param key any @The key to check against (optional).
---@return boolean founded @True if the value is found, false otherwise.
---@return any row @The matching row in the table if found.
function internal.IsValueInTable(tbl, value, key)
    for _, row in ipairs(tbl) do
        if type(row) == "table" then
            if key then
                if row[key] == value then
                    return true, row
                end
            else
                for _, v in pairs(row) do
                    if v == value then
                        return true, row
                    end
                end
            end
        elseif row == value then
            return true, row
        end
    end
    return false
end

--- Find a key by its corresponding value in a table.
---@param tbl table @The table to search.
---@param value any @The value to search for.
---@return any @The key corresponding to the value if found, nil otherwise.
function internal.FindKeyByValue(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then return k end
    end
    return nil
end
