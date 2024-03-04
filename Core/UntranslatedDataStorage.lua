--- @class WowUkrainizerInternals
local ns = select(2, ...);

local _G = _G
local IsValueInTable = ns.CommonUtil.IsValueInTable
local GetBuildInfo = GetBuildInfo

--- Prototype for UntranslatedDataStorage, providing methods for initializing and managing untranslated data.
---@class UntranslatedDataStorage
---@field gameBuild string @Return string buildNumber from GetBuildInfo
local _dataStoragePrototype = {}

--- Retrieves or adds data to the UntranslatedDataStorage.
--- @param category string @The category of the data.
--- @param subCategory string @The sub-category of the data, can be nil.
--- @param data any @The data to be stored or retrieved.
--- @return table @The table containing the data, either retrieved or added.
function _dataStoragePrototype:GetOrAdd(category, subCategory, data)
    if (not _G.WowUkrainizerData.UntranslatedData[category]) then _G.WowUkrainizerData.UntranslatedData[category] = {} end

    local untranslatedData
    if (subCategory ~= nil) then
        if (not _G.WowUkrainizerData.UntranslatedData[category][subCategory]) then _G.WowUkrainizerData.UntranslatedData[category][subCategory] = {} end
        untranslatedData = _G.WowUkrainizerData.UntranslatedData[category][subCategory]
    else
        untranslatedData = _G.WowUkrainizerData.UntranslatedData[category]
    end

    local valueFounded, currentValue = IsValueInTable(untranslatedData, data, "value")

    if (not valueFounded) then
        local newValue = { value = data, build = self.gameBuild }
        table.insert(untranslatedData, newValue)
        return newValue
    else
        return currentValue
    end
end

--- Retrieves the singleton instance of the UntranslatedDataStorage.
function ns:CreateUntranslatedDataStorage()
    if not self.UntranslatedDataStorage then
        self.UntranslatedDataStorage = setmetatable({}, { __index = _dataStoragePrototype })

        ---@diagnostic disable-next-line: inject-field
        if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
        if (not _G.WowUkrainizerData.UntranslatedData) then _G.WowUkrainizerData.UntranslatedData = {} end

        local _, build = GetBuildInfo()
        self.UntranslatedDataStorage.gameBuild = build
    end
end
