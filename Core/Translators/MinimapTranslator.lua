--- @class WowUkrainizerInternals
local ns = select(2, ...);

---@class MinimapTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

function translator:Init()
end

ns.TranslationsManager:AddTranslator(translator)
