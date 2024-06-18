--- @class WowUkrainizerInternals
local ns = select(2, ...);

--- Utility module providing versatile functions for a wow api
---@class GameApiUtil
local internal = {}
ns.GameApiUtil = internal

--- Get the player position
---@return number,number,number @The map id, x and y position
function internal.GetPlayerMapPosition()
    local uiMapID = C_Map.GetBestMapForUnit("player") or WorldMapFrame:GetMapID()
    local location = nil;
    if uiMapID then
        location = C_Map.GetPlayerMapPosition(uiMapID, "player");
    end

    if not location then return uiMapID, 0, 0; end
    local x, y = location:GetXY()

    return uiMapID, floor(x * 1000 + 0.5), floor(y * 1000 + 0.5)
end
