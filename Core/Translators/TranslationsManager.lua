--- @class WowUkrainizerInternals
local ns = select(2, ...);

--- TranslationsManager handles initializing and managing translators
---@class TranslationsManager
---@field _translators BaseTranslator[]
local manager = {
    _translators = {}
}
ns.TranslationsManager = manager

--- Initializes all added translators by calling Init() if they are enabled
function manager:Init()
    for _, translator in ipairs(self._translators) do
        if (translator:IsEnabled()) then
            translator:Init()
        end
    end
end

--- Adds a translator to the manager
---@param translator BaseTranslator
function manager:AddTranslator(translator)
    table.insert(self._translators, translator)
end
