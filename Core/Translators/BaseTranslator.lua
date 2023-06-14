local _, ns = ...;

ns.Translators = {}

local translator = class("BaseTranslator")
ns.Translators.BaseTranslator = translator

function translator:initialize()
    self.enabled = false
end

function translator:SetEnabled(enabled)
    self.enabled = enabled
    if (enabled) then self:OnEnabled() else self:OnDisabled() end
end

function translator:OnEnabled()
end

function translator:OnDisabled()
end

function translator:AddToDebugOutput(category, data)
    local function isValueInTable(t, value)
        for _, v in ipairs(t) do
            if v == value then
                return true
            end
        end
        return false
    end

    if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
    if (not _G.WowUkrainizerData.UntranslatedData) then _G.WowUkrainizerData.UntranslatedData = {} end
    if (not _G.WowUkrainizerData.UntranslatedData[category]) then _G.WowUkrainizerData.UntranslatedData[category] = {} end

    local categoryTable = _G.WowUkrainizerData.UntranslatedData[category]
    if (not isValueInTable(categoryTable, data)) then table.insert(categoryTable, data) end
end

function translator:IsEnabled()
    return self.enabled
end
