--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedPvpText = ns.ZoneFrameUtil.GetTranslatedPvpText
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

local function OnZoneEventHandled()
    local pvpType, isSubZonePvP, factionName = C_PvP.GetZonePVPInfo();

    local pvpTextString = PVPInfoTextString;
    if (isSubZonePvP or pvpType == "combat") then
        pvpTextString = PVPArenaTextString;
    end

    local translatedPvpText = GetTranslatedPvpText(pvpType, factionName)
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

function translator:Init()
    eventHandler:Register(OnZoneEventHandled, "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA")
    eventHandler:Register(OnAutoFollowEventHandled, "AUTOFOLLOW_BEGIN", "AUTOFOLLOW_END")
end

ns.TranslationsManager:AddTranslator(translator)
