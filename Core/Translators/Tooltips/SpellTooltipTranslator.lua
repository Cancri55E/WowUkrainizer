--- @type string, WowUkrainizerInternals
local _, ns = ...;

local _G = _G
local spellTooltipUtil = ns.SpellTooltipUtil

local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedSpellAttribute = ns.DbContext.Spells.GetTranslatedSpellAttribute
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

---@class SpellTooltipTranslator : BaseTooltipTranslator
local translator = setmetatable({ tooltipDataType = Enum.TooltipDataType.Spell }, { __index = ns.BaseTooltipTranslator })

function translator:ParseTooltip(tooltip, tooltipData)
    self._postCallLineCount = tonumber(tooltip:NumLines())
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

    hooksecurefunc(_G["TalentDisplayMixin"], "SetTooltipInternal", function(...)
        if (not self._postCallLineCount) then return end
        for i = self._postCallLineCount + 1, GameTooltip:NumLines() do
            local lineLeft = _G["GameTooltipTextLeft" .. i]
            if (lineLeft) then
                local leftTranslatedTips = GetTranslatedGlobalString(lineLeft:GetText())
                lineLeft:SetText(leftTranslatedTips)
            end

            local lineRight = _G["GameTooltipTextRight" .. i]
            if (lineRight) then
                local rightTranslatedTips = GetTranslatedGlobalString(lineRight:GetText())
                lineRight:SetText(rightTranslatedTips)
            end
        end
        GameTooltip:Show();
    end)

    EventRegistry:RegisterCallback("PvPTalentButton.TooltipHook", function(...)
        local function extractRequirementTalentName(str)
            local prefix = "Requires "
            local suffix = " talent"
            local start = str:find("^" .. prefix)
            local _end = str:find(suffix .. "$")
            if start and _end then
                local extracted = str:sub(#prefix + 1, _end - 1)
                return prefix .. "%s" .. suffix, extracted
            end
            return str
        end

        if (not self._postCallLineCount) then return end
        for i = self._postCallLineCount + 1, GameTooltip:NumLines() do
            local lineLeft = _G["GameTooltipTextLeft" .. i]
            if (lineLeft) then
                local text = lineLeft:GetText() or ''
                local requiresText, talentName = extractRequirementTalentName(text)
                if (talentName ~= nil) then
                    local translatedRequiresText = GetTranslatedSpellAttribute(requiresText)
                    translatedRequiresText = translatedRequiresText:format(GetTranslatedSpellName(talentName, false))
                    lineLeft:SetText(translatedRequiresText)
                else
                    lineLeft:SetText(GetTranslatedGlobalString(text))
                end
            end
        end
        GameTooltip:Show();
    end, translator)
end

ns.TranslationsManager:AddTranslator(translator)
