--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local SetFontStringText = ns.FontStringUtil.SetText
local GetTranslatedPvpText = ns.ZoneFrameUtil.GetTranslatedPvpText

---@class MinimapFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

local function OnMinimapUpdate()
    SetFontStringText(MinimapZoneText, GetTranslatedZoneText(GetMinimapZoneText()))
end

local function OnMinimapSetTooltip(pvpType, factionName, worldMap)
    local translatedPvpText = GetTranslatedPvpText(pvpType, factionName)
    local zoneName = GetZoneText();
    local subzoneName = GetSubZoneText();

    local i = 1
    _G["GameTooltipTextLeft" .. i]:SetText(GetTranslatedZoneText(_G["GameTooltipTextLeft" .. i]:GetText()))

    if (subzoneName ~= zoneName) then
        i = i + 1
        if (_G["GameTooltipTextLeft" .. i]) then
            _G["GameTooltipTextLeft" .. i]:SetText(GetTranslatedZoneText(_G["GameTooltipTextLeft" .. i]:GetText()))
        end
    end

    if (translatedPvpText) then
        i = i + 1
        if (_G["GameTooltipTextLeft" .. i]) then
            _G["GameTooltipTextLeft" .. i]:SetText(translatedPvpText)
        end
    end

    if (worldMap) then
        i = i + 1
        if (_G["GameTooltipTextLeft" .. i]) then
            _G["GameTooltipTextLeft" .. i]:SetText(MicroButtonTooltipText(GetTranslatedGlobalString(WORLDMAP_BUTTON), "TOGGLEWORLDMAP"))
        end
    end
end

local function OnZoneTextButtonEnter()
    local pvpType, _, factionName = C_PvP.GetZonePVPInfo();
    OnMinimapSetTooltip(pvpType, factionName, true)
end

function translator:Init()
    if (WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION) then
        hooksecurefunc("Minimap_Update", OnMinimapUpdate)
        hooksecurefunc("Minimap_SetTooltip", OnMinimapSetTooltip)

        MinimapCluster.ZoneTextButton:HookScript("OnEnter", OnZoneTextButtonEnter)
    end
end

ns.TranslationsManager:AddTranslator(translator)
