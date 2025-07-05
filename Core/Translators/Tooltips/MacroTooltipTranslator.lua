---@type string, WowUkrainizerInternals
local _, ns = ...

local spellTooltipUtil = ns.SpellTooltipUtil

---@class MacroTooltipTranslator : BaseTooltipTranslator
local translator = setmetatable({
    tooltipDataType = Enum.TooltipDataType.Macro
}, { __index = ns.BaseTooltipTranslator })

function translator:ParseTooltip(tooltip, tooltipData)
    return spellTooltipUtil:ParseTooltip(self, tooltip, tooltipData)
end

function translator:TranslateTooltipInfo(tooltipInfo)
    return spellTooltipUtil:TranslateTooltipInfo(tooltipInfo)
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SPELL_TOOLTIPS_OPTION)
end

function translator:Init()
    ns.BaseTooltipTranslator.Init(self)
end

ns.TranslationsManager:AddTranslator(translator)
