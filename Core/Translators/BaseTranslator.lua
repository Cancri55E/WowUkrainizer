--- @class WowUkrainizerInternals
local ns = select(2, ...);

---@class BaseTranslator
local baseTranslator = {}
ns.BaseTranslator = baseTranslator

function baseTranslator:IsEnabled()
    return false
end

function baseTranslator:Init()
end
