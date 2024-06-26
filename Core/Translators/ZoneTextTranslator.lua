--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedFaction = ns.DbContext.Factions.GetTranslatedFaction
local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName
local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local SetFontStringText = ns.FontStringUtil.SetText
local ExtractFromText = ns.StringUtil.ExtractFromText

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

---@class ZoneTextTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)
end

local function GetPvpText(pvpType, factionName)
    if (pvpType == "sanctuary") then
        return GetTranslatedGlobalString(SANCTUARY_TERRITORY);
    elseif (pvpType == "arena") then
        return GetTranslatedGlobalString(FREE_FOR_ALL_TERRITORY);
    elseif (pvpType == "friendly" or pvpType == "hostile") then
        if (factionName and factionName ~= "") then
            -- hook with genitive
            if (factionName == FACTION_ALLIANCE) then
                factionName = 'Альянсу'
            elseif (factionName == FACTION_HORDE) then
                factionName = 'Орди'
            else
                factionName = GetTranslatedFaction(factionName)
            end
            return string.format(GetTranslatedGlobalString(FACTION_CONTROLLED_TERRITORY), factionName);
        end
    elseif (pvpType == "contested") then
        return GetTranslatedGlobalString(CONTESTED_TERRITORY);
    elseif (pvpType == "combat") then
        return GetTranslatedGlobalString(COMBAT_ZONE);
    end
end

local function OnZoneEventHandled()
    local pvpType, isSubZonePvP, factionName = C_PvP.GetZonePVPInfo();

    local pvpTextString = PVPInfoTextString;
    if (isSubZonePvP or pvpType == "combat") then
        pvpTextString = PVPArenaTextString;
    end

    local translatedPvpText = GetPvpText(pvpType, factionName)
    if (translatedPvpText) then
        SetFontStringText(pvpTextString, translatedPvpText);
    end

    SetFontStringText(ZoneTextString, GetTranslatedZoneText(ZoneTextString:GetText()))
    SetFontStringText(SubZoneTextString, GetTranslatedZoneText(SubZoneTextString:GetText()))
end

local function OnAutoFollowEventHandled(eventName)
    local globalString = eventName == "AUTOFOLLOW_BEGIN" and AUTOFOLLOWSTART or AUTOFOLLOWSTOP
    local unitName = ExtractFromText(globalString, AutoFollowStatusText:GetText())
    if (unitName and unitName ~= "") then
        unitName = GetTranslatedUnitName(unitName)
    end
    SetFontStringText(AutoFollowStatusText, string.format(GetTranslatedGlobalString(globalString), unitName))
end

local function OnMinimapUpdate()
    SetFontStringText(MinimapZoneText, GetTranslatedZoneText(GetMinimapZoneText()))
end

local function OnMinimapSetTooltip(pvpType, factionName, worldMap)
    local translatedPvpText = GetPvpText(pvpType, factionName)
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
    eventHandler:Register(OnZoneEventHandled, "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA")
    eventHandler:Register(OnAutoFollowEventHandled, "AUTOFOLLOW_BEGIN", "AUTOFOLLOW_END")

    hooksecurefunc("Minimap_Update", OnMinimapUpdate)
    hooksecurefunc("Minimap_SetTooltip", OnMinimapSetTooltip)

    MinimapCluster.ZoneTextButton:HookScript("OnEnter", OnZoneTextButtonEnter)
end

ns.TranslationsManager:AddTranslator(translator)
