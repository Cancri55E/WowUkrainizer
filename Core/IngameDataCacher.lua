--- @class WowUkrainizerInternals
local ns = select(2, ...);

local _G = _G
local IsValueInTable = ns.CommonUtil.IsValueInTable
local GetBuildInfo = GetBuildInfo

--- Prototype for IngameDataCacher, providing methods for initializing and managing cached data.
---@class IngameDataCacher
---@field gameBuild string @Return string buildNumber from GetBuildInfo
local _ingameDataCacherPrototype = {}

--- Retrieves or adds data to the IngameDataCacher.
--- @param categories table @A list of categories forming the chain.
--- @param data any @The data to be stored or retrieved.
--- @param metadata any @The metadata to be stored for data.
--- @return table @The table containing the data, either retrieved or added.
function _ingameDataCacherPrototype:GetOrAdd(categories, data, metadata)
    local currentCache = _G.WowUkrainizerData.Cache
    for _, category in ipairs(categories) do
        if not currentCache[category] then
            currentCache[category] = {}
        end
        currentCache = currentCache[category]
    end

    local cacheRowFounded, currentValue = IsValueInTable(currentCache, data, "data")

    local cacheRow;
    if not cacheRowFounded then
        cacheRow = { data = data, build = self.gameBuild }
        table.insert(currentCache, cacheRow)
    else
        cacheRow = currentValue
    end

    if (metadata) then
        cacheRow.metadata = metadata
    end

    return cacheRow;
end

--- Retrieves the singleton instance of the IngameDataCacher.
function ns:CreateIngameDataCacher()
    if not self.IngameDataCacher then
        self.IngameDataCacher = setmetatable({}, { __index = _ingameDataCacherPrototype })

        ---@diagnostic disable-next-line: inject-field
        if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
        if (not _G.WowUkrainizerData.Cache) then _G.WowUkrainizerData.Cache = {} end

        local _, build = GetBuildInfo()
        self.IngameDataCacher.gameBuild = build
    end
end
