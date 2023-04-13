local _, ns = ...;

local LEVEL_TRANSLATION = ns.LEVEL_TRANSLATION
local PET_LEVEL_TRANSLATION = ns.PET_LEVEL_TRANSLATION

local GetUnitNameWithFallback = ns.DbContext.Units.GetUnitNameWithFallback
local GetUnitSubnameWithFallback = ns.DbContext.Units.GetUnitSubnameWithFallback
local GetUnitTypeWithFallback = ns.DbContext.Units.GetUnitTypeWithFallback
local GetUnitRankWithFallback = ns.DbContext.Units.GetUnitRankWithFallback
local GetUnitFractionWithFallback = ns.DbContext.Units.GetUnitFractionWithFallback

local translator = {
    static = {
        isEnabled = false,
        isInitialized = false,
        enableDebugInfo = false
    }
}
ns.UnitTooltipTranslator = translator

local function parseUnitLevelString(unitLevelString)
    local level, unitType, rank, isPet = nil, nil, nil, false
    local unitLevelParts = {}

    for part in unitLevelString:gmatch("%S+") do
        unitLevelParts[#unitLevelParts + 1] = part
    end

    if unitLevelParts[1] == "Level" then
        level = unitLevelParts[2]
        if #unitLevelParts > 2 then
            local rankIndex = 3
            if unitLevelParts[3]:sub(1, 1) == "(" then
                rank = unitLevelParts[3]:sub(2, -2)
                rankIndex = 4
            end
            if #unitLevelParts > rankIndex - 1 then
                unitType = unitLevelParts[rankIndex]
            end
        end
    elseif unitLevelParts[1] == "Pet" then
        isPet = true
        level = unitLevelParts[3]
        if #unitLevelParts > 3 then
            unitType = unitLevelParts[4]
        end
    end

    return level, unitType, rank, isPet
end

local function parseUnitTooltip(unitTooltipLines)
    local leftTexts = {}
    for _, tooltipLine in ipairs(unitTooltipLines) do
        leftTexts[#leftTexts + 1] = tooltipLine.leftText
    end

    local unitTooltip = { name = leftTexts[1], levelData = {} }
    if (#leftTexts > 1) then
        local index = 2
        unitTooltip.subnameData = leftTexts[index] and leftTexts[index]:sub(1, 9) ~= "Pet Level" and
            leftTexts[index]:sub(1, 5) ~= "Level" and
            { index = index, value = leftTexts[index] }
        index = index + (unitTooltip.subnameData and 1 or 0)

        unitTooltip.levelData.index, unitTooltip.levelData.level, unitTooltip.levelData.unitType, unitTooltip.levelData.rank, unitTooltip.levelData.isPet =
            index, parseUnitLevelString(leftTexts[index])

        for i = index + 1, #leftTexts do
            local str = leftTexts[i]
            if str == "PvP" then
                unitTooltip.pvpData = { index = i, value = str }
            elseif not unitTooltip.pvpData then
                unitTooltip.fractionData = { index = i, value = str }
            else
                unitTooltip.leaderLineIndex = i
            end
        end
    end

    return unitTooltip
end

local function getLocalizedUnitTooltip(unitTooltipLines)
    local parsedTooltip = parseUnitTooltip(unitTooltipLines)
    if (not parsedTooltip.name or not parsedTooltip.levelData) then return end

    local name = GetUnitNameWithFallback(parsedTooltip.name)
    local levelData = {
        index = parsedTooltip.levelData.index,
    }
    if (not parsedTooltip.levelData.isPet) then
        levelData.value = string.format("%s %s %s %s",
            LEVEL_TRANSLATION,
            parsedTooltip.levelData.level,
            (parsedTooltip.levelData.unitType and GetUnitTypeWithFallback(parsedTooltip.levelData.unitType)) or "",
            (parsedTooltip.levelData.rank and "(" .. GetUnitRankWithFallback(parsedTooltip.levelData.rank) .. ")") or "")
    else
        levelData.value = string.format("%s %s",
            string.gsub(PET_LEVEL_TRANSLATION, "{1}", parsedTooltip.levelData.level),
            (parsedTooltip.levelData.unitType and GetUnitTypeWithFallback(parsedTooltip.levelData.unitType)) or "")
    end

    local subnameData = nil
    if (parsedTooltip.subnameData) then
        local subname = GetUnitSubnameWithFallback(parsedTooltip.subnameData.value)
        subnameData = { index = parsedTooltip.subnameData.index, value = subname }
    end

    local fractionData = nil
    if (parsedTooltip.fractionData) then
        local fraction = GetUnitFractionWithFallback(parsedTooltip.fractionData.value)
        fractionData = { index = parsedTooltip.fractionData.index, value = fraction }
    end

    local leaderData = nil
    if (parsedTooltip.leaderLineIndex) then
        leaderData = { index = parsedTooltip.leaderLineIndex, value = ns.LEADER_TRANSLATION }
    end

    return {
        name = name,
        levelData = levelData,
        subnameData = subnameData,
        fractionData = fractionData,
        leaderData = leaderData,
    }
end

local function unitTooltipCallback(tooltip, tooltipLineData)
    if (not translator.static.isEnabled) then return end

    local unitKind, _, _, _, _, unitId, _ = strsplit("-", tooltipLineData.guid)

    if (unitKind == "Creature" or unitKind == "Vehicle") then
        local localizedTooltip = getLocalizedUnitTooltip(tooltipLineData.lines)
        if (localizedTooltip) then
            local tooltipLines = {}
            for i = 1, tooltip:NumLines() do
                local line = _G["GameTooltipTextLeft" .. i]
                tooltipLines[#tooltipLines + 1] = line
            end

            local r, g, b = tooltipLines[1]:GetTextColor()
            tooltipLines[1]:SetText(localizedTooltip.name)
            tooltipLines[1]:SetTextColor(r, g, b)

            tooltipLines[localizedTooltip.levelData.index]:SetText(localizedTooltip.levelData.value)

            if (localizedTooltip.subnameData) then
                tooltipLines[localizedTooltip.subnameData.index]:SetText(localizedTooltip.subnameData.value)
            end

            if (localizedTooltip.fractionData) then
                tooltipLines[localizedTooltip.fractionData.index]:SetText(localizedTooltip.fractionData.value)
            end

            if (localizedTooltip.leaderData) then
                tooltipLines[localizedTooltip.leaderData.index]:SetText(localizedTooltip.leaderData.value)
            end
        end
    end
end

local function initialize()
    if (translator.static.isInitialized) then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, unitTooltipCallback)
    translator.static.isInitialized = true
end

local function enable()
    if (translator.static.isEnabled) then return end
    initialize()
    translator.static.isEnabled = true
end

local function disable()
    if (not translator.static.isEnabled) then return end
    translator.static.isEnabled = false
end

function translator.SetEnabled(value)
    if (value) then
        enable()
    else
        disable()
    end
end

function translator.EnableDebugInfo(value)
    translator.static.enableDebugInfo = value
end
