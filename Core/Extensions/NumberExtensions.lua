local _, ns = ...;

local internal = {}
ns.NumberExtensions = internal

function internal.TimestampToDate(timestamp)
    local value = tonumber(timestamp) or 0

    local totalSeconds = value
    local seconds = totalSeconds % 60
    totalSeconds = math.floor(totalSeconds / 60)
    local minutes = totalSeconds % 60
    totalSeconds = math.floor(totalSeconds / 60)
    local hours = totalSeconds % 24
    totalSeconds = math.floor(totalSeconds / 24)
    local day = totalSeconds % 31 + 1
    totalSeconds = math.floor(totalSeconds / 31)
    local month = totalSeconds % 12 + 1
    totalSeconds = math.floor(totalSeconds / 12)
    local year = totalSeconds + 1970

    return string.format("%02d-%02d-%04d %02d:%02d:%02d", day, month, year, hours, minutes, seconds)
end
