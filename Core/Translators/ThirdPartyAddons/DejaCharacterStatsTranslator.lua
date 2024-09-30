--- @class WowUkrainizerInternals
local ns = select(2, ...);

---@class DejaCharacterStatsTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

ns.TranslationsManager:AddTranslator(translator)
