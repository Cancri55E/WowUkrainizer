--- @class WowUkrainizerInternals
local ns = select(2, ...);

---@class MapFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return false
end

function translator:Init()
end

ns.TranslationsManager:AddTranslator(translator)
