--- @class WowUkrainizerInternals
local ns = select(2, ...);

local IsValueInTable = ns.CommonUtil.IsValueInTable

local dataStorage = class("UntranslatedDataStorage");
ns.UntranslatedDataStorage = dataStorage

function dataStorage:initialize()
    if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
    if (not _G.WowUkrainizerData.UntranslatedData) then _G.WowUkrainizerData.UntranslatedData = {} end

    local _, build = GetBuildInfo()
    self.gameBuild = build
end

function dataStorage:GetOrAdd(category, subCategory, data)
    if (not _G.WowUkrainizerData.UntranslatedData[category]) then _G.WowUkrainizerData.UntranslatedData[category] = {} end

    local untranslatedData
    if (subCategory ~= nil) then
        if (not _G.WowUkrainizerData.UntranslatedData[category][subCategory]) then _G.WowUkrainizerData.UntranslatedData[category][subCategory] = {} end
        untranslatedData = _G.WowUkrainizerData.UntranslatedData[category][subCategory]
    else
        untranslatedData = _G.WowUkrainizerData.UntranslatedData[category]
    end

    local isValueInTable, currentValue = IsValueInTable(untranslatedData, data, "value")

    if (not isValueInTable) then
        local newValue = { value = data, build = self.gameBuild }
        table.insert(untranslatedData, newValue)
        return newValue
    else
        return currentValue
    end
end
