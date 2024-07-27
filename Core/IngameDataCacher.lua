--- @class WowUkrainizerInternals
local ns = select(2, ...);

local _G = _G
local IsValueInTable = ns.CommonUtil.IsValueInTable
local GetBuildInfo = GetBuildInfo

--- Prototype for IngameDataCacher, providing methods for initializing and managing cached data.
---@class IngameDataCacher
---@field playerHash number @Return hash for current character
local _ingameDataCacherPrototype = {}

--- Retrieves or adds category to the IngameDataCacher.
--- @param categories table @A list of categories forming the chain.
function _ingameDataCacherPrototype:GetOrAddCategory(categories)
    local currentCategory = _G.WowUkrainizerData.Cache
    for _, category in ipairs(categories) do
        if not currentCategory[category] then
            currentCategory[category] = {}
        end
        currentCategory = currentCategory[category]
    end

    return currentCategory
end

--- Retrieves or adds data to the IngameDataCacher.
--- @param category any @Category forming the chain.
--- @param key string @The data key to be stored or retrieved.
--- @param data any @The data to be stored or retrieved.
--- @param metadata any @The metadata to be stored for data.
--- @return table @The table containing the data, either retrieved or added.
function _ingameDataCacherPrototype:GetOrAddToCategory(category, key, data, metadata)
    local founded, currentValue = IsValueInTable(category, data, key)
    if not founded or currentValue.player ~= self.playerHash then
        local newValue = { metadata = metadata, player = self.playerHash, date = date("%d.%m.%y %H:%M:%S") }
        newValue[key] = data
        table.insert(category, newValue)
        return newValue;
    else
        return currentValue
    end
end

--- Retrieves or adds data to the IngameDataCacher.
--- @param categories table @A list of categories forming the chain.
--- @param data any @The data to be stored or retrieved.
--- @param metadata any @The metadata to be stored for data.
--- @return table @The table containing the data, either retrieved or added.
function _ingameDataCacherPrototype:GetOrAdd(categories, data, metadata)
    return self:GetOrAddToCategory(self:GetOrAddCategory(categories), "data", data, metadata)
end

--- Retrieves the singleton instance of the IngameDataCacher.
function ns:CreateIngameDataCacher()
    if not self.IngameDataCacher then
        self.IngameDataCacher = setmetatable({}, { __index = _ingameDataCacherPrototype })

        ---@diagnostic disable-next-line: inject-field
        if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
        if (not _G.WowUkrainizerData.Cache) then _G.WowUkrainizerData.Cache = {} end

        local _, build = GetBuildInfo()
        local playerData = ns.PlayerInfo
        local playerHash = ns.StringUtil.GetHash(playerData.Name .. "-" .. playerData.Realm)

        local characterCategory = self.IngameDataCacher:GetOrAddCategory({ "characters" })
        if (not characterCategory[tostring(playerHash)]) then
            characterCategory[tostring(playerHash)] = playerData
        end

        local todayBuildCategory = self.IngameDataCacher:GetOrAddCategory({ "builds", tostring(date("%d.%m.%y")) })
        local founded = IsValueInTable(todayBuildCategory, build)
        if (not founded) then
            table.insert(todayBuildCategory, build)
        end

        self.IngameDataCacher.playerHash = playerHash
    end
end
