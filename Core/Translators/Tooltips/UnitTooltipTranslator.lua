local _, ns = ...;

local LEADER_TRANSLATION = ns.LEADER_TRANSLATION
local LEVEL_TRANSLATION = ns.LEVEL_TRANSLATION
local PET_LEVEL_TRANSLATION = ns.PET_LEVEL_TRANSLATION
local PET_CAPTURABLE_TRANSLATION = ns.PET_CAPTURABLE_TRANSLATION
local PET_COLLECTED_TRANSLATION = ns.PET_COLLECTED_TRANSLATION


local GetUnitNameWithFallback = ns.DbContext.Units.GetUnitNameWithFallback
local GetUnitSubnameWithFallback = ns.DbContext.Units.GetUnitSubnameWithFallback
local GetUnitTypeWithFallback = ns.DbContext.Units.GetUnitTypeWithFallback
local GetUnitRankWithFallback = ns.DbContext.Units.GetUnitRankWithFallback
local GetUnitFractionWithFallback = ns.DbContext.Units.GetUnitFractionWithFallback

local StartsWith = ns.StringExtensions.StartsWith
local ExtractNumericValuesFromString = ns.StringExtensions.ExtractNumericValuesFromString
local InsertNumericValuesIntoString = ns.StringExtensions.InsertNumericValuesIntoString
local UpdateFontString = ns.FontStringExtensions.UpdateFontString

local translator = {
    static = {
        isEnabled = false,
        isInitialized = false,
        enableDebugInfo = false
    }
}
ns.UnitTooltipTranslator = translator

local function parseUnitTooltipLines(unitTooltipLines)
    local function isSubname(str)
        return str and str:sub(1, 9) ~= "Pet Level" and str:sub(1, 5) ~= "Level"
    end

    local function parseSubnameInfo(leftTexts, index)
        return isSubname(leftTexts[index]) and { index = index, value = leftTexts[index] } or nil
    end

    local function parseRemainingInfo(leftTexts, startIndex)
        local pvpInfo, factionInfo, capturableLineIndex, collectedInfo, leaderLineIndex

        for i = startIndex, #leftTexts do
            local str = leftTexts[i]

            if str == "Capturable" then
                capturableLineIndex = i
            elseif StartsWith(str, "Collected") then
                collectedInfo = { index = i, value = str }
            elseif str == "PvP" then
                pvpInfo = { index = i, value = str }
            elseif not pvpInfo then
                factionInfo = { index = i, value = str }
            else
                leaderLineIndex = i
            end
        end

        return pvpInfo, factionInfo, capturableLineIndex, collectedInfo, leaderLineIndex
    end

    local function parseUnitLevelString(unitLevelString)
        local level, unitType, rank, isPet = nil, nil, nil, false
        local stringParts = {}

        for part in unitLevelString:gmatch("%S+") do
            table.insert(stringParts, part)
        end

        if stringParts[1] == "Level" then
            level = stringParts[2]
            if #stringParts > 2 then
                local rankIndex = 3
                if stringParts[3]:sub(1, 1) == "(" then
                    rank = stringParts[3]:sub(2, -2)
                    rankIndex = 4
                end
                if #stringParts > rankIndex - 1 then
                    unitType = stringParts[rankIndex]
                end
            end
        elseif stringParts[1] == "Pet" then
            isPet = true
            level = stringParts[3]
            if #stringParts > 3 then
                unitType = stringParts[4]
            end
        end

        return level, unitType, rank, isPet
    end

    local leftTexts = {}

    for _, tooltipLine in ipairs(unitTooltipLines) do
        table.insert(leftTexts, tooltipLine.leftText)
    end

    local unitTooltipInfo = { name = leftTexts[1], levelInfo = {} }

    if (#leftTexts > 1) then
        local index = 2

        unitTooltipInfo.subnameInfo = parseSubnameInfo(leftTexts, index)
        index = index + (unitTooltipInfo.subnameInfo and 1 or 0)

        unitTooltipInfo.levelInfo.index, unitTooltipInfo.levelInfo.level, unitTooltipInfo.levelInfo.unitType,
        unitTooltipInfo.levelInfo.rank, unitTooltipInfo.levelInfo.isPet = index, parseUnitLevelString(leftTexts[index])

        unitTooltipInfo.pvpInfo, unitTooltipInfo.factionInfo, unitTooltipInfo.capturableLineIndex, unitTooltipInfo.collectedInfo,
        unitTooltipInfo.leaderLineIndex = parseRemainingInfo(leftTexts, index + 1)
    end

    return unitTooltipInfo
end

local function getTranslatedUnitTooltip(unitTooltipLines)
    local unitTooltipInfo = parseUnitTooltipLines(unitTooltipLines)

    if (not unitTooltipInfo.name or not unitTooltipInfo.levelInfo) then return end

    local function getLevelInfoString(levelInfo)
        if (not levelInfo.isPet) then
            return string.format("%s %s %s %s",
                LEVEL_TRANSLATION,
                levelInfo.level,
                (levelInfo.unitType and GetUnitTypeWithFallback(levelInfo.unitType)) or "",
                (levelInfo.rank and "(" .. GetUnitRankWithFallback(levelInfo.rank) .. ")") or "")
        else
            return string.format("%s %s",
                string.gsub(PET_LEVEL_TRANSLATION, "{1}", levelInfo.level),
                (levelInfo.unitType and GetUnitTypeWithFallback(levelInfo.unitType)) or "")
        end
    end

    local name = GetUnitNameWithFallback(unitTooltipInfo.name)
    local levelInfo = {
        index = unitTooltipInfo.levelInfo.index,
        value = getLevelInfoString(unitTooltipInfo.levelInfo)
    }

    local subnameInfo = nil
    if (unitTooltipInfo.subnameInfo) then
        local subname = GetUnitSubnameWithFallback(unitTooltipInfo.subnameInfo.value)
        subnameInfo = { index = unitTooltipInfo.subnameInfo.index, value = subname }
    end

    local factionInfo = nil
    if (unitTooltipInfo.factionInfo) then
        local fraction = GetUnitFractionWithFallback(unitTooltipInfo.factionInfo.value)
        factionInfo = { index = unitTooltipInfo.factionInfo.index, value = fraction }
    end

    local capturableInfo
    if (unitTooltipInfo.capturableLineIndex) then
        capturableInfo = { index = unitTooltipInfo.capturableLineIndex, value = PET_CAPTURABLE_TRANSLATION }
    end

    local collectedInfo
    if (unitTooltipInfo.collectedInfo) then
        local text, numValues = ExtractNumericValuesFromString(unitTooltipInfo.collectedInfo.value)
        collectedInfo = {
            index = unitTooltipInfo.collectedInfo.index,
            value = InsertNumericValuesIntoString(PET_COLLECTED_TRANSLATION, numValues)
        }
    end

    local leaderInfo = nil
    if (unitTooltipInfo.leaderLineIndex) then
        leaderInfo = { index = unitTooltipInfo.leaderLineIndex, value = LEADER_TRANSLATION }
    end

    return {
        name = name,
        levelInfo = levelInfo,
        subnameInfo = subnameInfo,
        fractionInfo = factionInfo,
        leaderInfo = leaderInfo,
        capturableInfo = capturableInfo,
        collectedInfo = collectedInfo
    }
end

local function unitTooltipCallback(tooltip, tooltipLineData)
    if (not translator.static.isEnabled) then return end

    local unitKind = strsplit("-", tooltipLineData.guid)

    if (unitKind == "Creature" or unitKind == "Vehicle") then
        local translatedTooltip = getTranslatedUnitTooltip(tooltipLineData.lines)
        if (not translatedTooltip) then return end

        local tooltipLines = {}
        for i = 1, tooltip:NumLines() do
            local line = _G["GameTooltipTextLeft" .. i]
            tooltipLines[#tooltipLines + 1] = line
        end

        UpdateFontString(tooltipLines[1], translatedTooltip.name)
        UpdateFontString(tooltipLines[translatedTooltip.levelInfo.index], translatedTooltip.levelInfo.value)

        if (translatedTooltip.subnameInfo) then
            UpdateFontString(tooltipLines[translatedTooltip.subnameInfo.index], translatedTooltip.subnameInfo.value)
        end

        if (translatedTooltip.fractionInfo) then
            UpdateFontString(tooltipLines[translatedTooltip.fractionInfo.index], translatedTooltip.fractionInfo.value)
        end

        if (translatedTooltip.capturableInfo) then
            UpdateFontString(tooltipLines[translatedTooltip.capturableInfo.index], translatedTooltip.capturableInfo
                .value)
        end

        if (translatedTooltip.collectedInfo) then
            UpdateFontString(tooltipLines[translatedTooltip.collectedInfo.index], translatedTooltip.collectedInfo.value)
        end

        if (translatedTooltip.leaderInfo) then
            UpdateFontString(tooltipLines[translatedTooltip.leaderInfo.index], translatedTooltip.leaderInfo.value)
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
