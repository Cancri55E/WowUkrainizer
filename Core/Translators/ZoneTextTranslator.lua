--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedFaction = ns.DbContext.Factions.GetTranslatedFaction
local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName
local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local SetFontStringText = ns.FontStringUtil.SetText
local SetFontStringFormattedText = ns.FontStringUtil.SetFormattedText
local ExtractFromText = ns.StringUtil.ExtractFromText

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

---@class ZoneTextTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)
end

function translator:Init()
    eventHandler:Register(function()
        local pvpType, isSubZonePvP, factionName = C_PvP.GetZonePVPInfo();
        local pvpTextString = PVPInfoTextString;
        if (isSubZonePvP) then
            pvpTextString = PVPArenaTextString;
        end
        if (pvpType == "sanctuary") then
            SetFontStringText(pvpTextString, GetTranslatedGlobalString(SANCTUARY_TERRITORY));
        elseif (pvpType == "arena") then
            pvpTextString:SetText(FREE_FOR_ALL_TERRITORY);
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
                SetFontStringFormattedText(pvpTextString, GetTranslatedGlobalString(FACTION_CONTROLLED_TERRITORY), factionName);
            end
        elseif (pvpType == "contested") then
            SetFontStringText(pvpTextString, GetTranslatedGlobalString(CONTESTED_TERRITORY));
        elseif (pvpType == "combat") then
            pvpTextString = PVPArenaTextString;
            SetFontStringText(pvpTextString, GetTranslatedGlobalString(COMBAT_ZONE));
        end

        SetFontStringText(ZoneTextString, GetTranslatedZoneText(ZoneTextString:GetText()))
        SetFontStringText(SubZoneTextString, GetTranslatedZoneText(SubZoneTextString:GetText()))
    end, "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA")

    eventHandler:Register(function(eventName)
        local globalString = eventName == "AUTOFOLLOW_BEGIN" and AUTOFOLLOWSTART or AUTOFOLLOWSTOP
        local unitName = ExtractFromText(globalString, AutoFollowStatusText:GetText())
        if (unitName and unitName ~= "") then
            unitName = GetTranslatedUnitName(unitName)
        end
        SetFontStringFormattedText(AutoFollowStatusText, GetTranslatedGlobalString(globalString), unitName)
    end, "AUTOFOLLOW_BEGIN", "AUTOFOLLOW_END")
end

ns.TranslationsManager:AddTranslator(translator)
