--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedFaction = ns.DbContext.Factions.GetTranslatedFaction
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

--- Utility module providing ....
---@class ZoneFrameUtil
local internal = {}
ns.ZoneFrameUtil = internal

function internal.GetTranslatedPvpText(pvpType, factionName)
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
