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

function internal.TryCallAPIFn(fnName, value)
    -- this function is helper fn to get table type from wow api.
    -- if there is GetObjectType then we will return it.
    -- returns Button, Frame or something like this

    -- VALIDATION
    if type(value) ~= "table" then
        return
    end

    -- VALIDATION FIX if __index is function we don't want to execute it
    -- Example in ACP.L
    local metatable = getmetatable(value)
    if metatable and type(metatable) == "table" and type(metatable.__index) == "function" then
        return
    end

    -- VALIDATION is forbidden from wow api
    if value.IsForbidden then
        local ok, forbidden = pcall(value.IsForbidden, value)
        if not ok or (ok and forbidden) then
            return
        end
    end

    local fn = value[fnName]
    -- VALIDATION has WoW API
    if not fn or type(fn) ~= "function" then
        return
    end

    -- MAIN PART:
    return pcall(fn, value)
end


--- Safely hook a global function or frame method when it exists.
---@return boolean hooked
function internal.SafeHookSecureFunc(target, methodOrHook, hook)
    if type(target) == "string" then
        if type(_G[target]) ~= "function" or type(methodOrHook) ~= "function" then
            return false
        end
        local ok = pcall(hooksecurefunc, target, methodOrHook)
        return ok
    end

    if type(target) ~= "table" then
        return false
    end

    if type(methodOrHook) == "string" then
        if type(target[methodOrHook]) ~= "function" or type(hook) ~= "function" then
            return false
        end
        local ok = pcall(hooksecurefunc, target, methodOrHook, hook)
        return ok
    end

    if type(methodOrHook) ~= "function" then
        return false
    end

    local ok = pcall(hooksecurefunc, target, methodOrHook)
    return ok
end

--- Safely HookScript only when the frame and script handler are available.
---@return boolean hooked
function internal.SafeHookScript(frame, scriptName, handler)
    if type(frame) ~= "table" or type(scriptName) ~= "string" or type(handler) ~= "function" then
        return false
    end

    if type(frame.HookScript) ~= "function" or type(frame.HasScript) ~= "function" then
        return false
    end

    local okHasScript, hasScript = pcall(frame.HasScript, frame, scriptName)
    if not okHasScript or not hasScript then
        return false
    end

    local ok = pcall(frame.HookScript, frame, scriptName, handler)
    return ok
end

--- Safely register a tooltip post call only when the API exists.
---@return boolean hooked
function internal.SafeAddTooltipPostCall(tooltipDataType, handler)
    if not TooltipDataProcessor or type(TooltipDataProcessor.AddTooltipPostCall) ~= "function" then
        return false
    end
    if tooltipDataType == nil or type(handler) ~= "function" then
        return false
    end

    local ok = pcall(TooltipDataProcessor.AddTooltipPostCall, tooltipDataType, handler)
    return ok
end
