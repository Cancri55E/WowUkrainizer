local _, ns = ...;

local _G = _G

local LEADER_TRANSLATION = ns.LEADER_TRANSLATION
local LEVEL_TRANSLATION = ns.LEVEL_TRANSLATION
local PET_LEVEL_TRANSLATION = ns.PET_LEVEL_TRANSLATION
local PET_CAPTURABLE_TRANSLATION = ns.PET_CAPTURABLE_TRANSLATION
local PET_COLLECTED_TRANSLATION = ns.PET_COLLECTED_TRANSLATION

local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetUnitSubnameOrDefault = ns.DbContext.Units.GetUnitSubnameOrDefault
local GetUnitTypeOrDefault = ns.DbContext.Units.GetUnitTypeOrDefault
local GetUnitRankOrDefault = ns.DbContext.Units.GetUnitRankOrDefault
local GetUnitFractionOrDefault = ns.DbContext.Units.GetUnitFractionOrDefault

local StartsWith = ns.StringExtensions.StartsWith
local ExtractNumericValuesFromString = ns.StringExtensions.ExtractNumericValuesFromString
local InsertNumericValuesIntoString = ns.StringExtensions.InsertNumericValuesIntoString

local translator = class("UnitTooltipTranslator", ns.Translators.BaseTooltipTranslator)
ns.Translators.UnitTooltipTranslator = translator

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

    local tooltipInfo = { name = leftTexts[1], levelInfo = {} }

    if (#leftTexts > 1) then
        local index = 2

        tooltipInfo.subnameInfo = parseSubnameInfo(leftTexts, index)
        index = index + (tooltipInfo.subnameInfo and 1 or 0)

        tooltipInfo.levelInfo.index, tooltipInfo.levelInfo.level, tooltipInfo.levelInfo.unitType,
        tooltipInfo.levelInfo.rank, tooltipInfo.levelInfo.isPet = index, parseUnitLevelString(leftTexts[index])

        tooltipInfo.pvpInfo, tooltipInfo.factionInfo, tooltipInfo.capturableLineIndex, tooltipInfo.collectedInfo,
        tooltipInfo.leaderLineIndex = parseRemainingInfo(leftTexts, index + 1)
    end

    return tooltipInfo
end

function translator:ParseTooltip(tooltip, tooltipData)
    local unitKind = strsplit("-", tooltipData.guid)
    if (unitKind == "Creature" or unitKind == "Vehicle") then
        for i = 1, tooltip:NumLines() do
            self:_addFontStringToIndexLookup(i, _G["GameTooltipTextLeft" .. i])
        end

        return parseUnitTooltipLines(tooltipData.lines)
    end
end

function translator:TranslateTooltipInfo(tooltipInfo)
    local function getLevelInfoString(levelInfo)
        if (not levelInfo.isPet) then
            return string.format("%s %s %s %s",
                LEVEL_TRANSLATION,
                levelInfo.level or "",
                (levelInfo.unitType and GetUnitTypeOrDefault(levelInfo.unitType)) or "",
                (levelInfo.rank and "(" .. GetUnitRankOrDefault(levelInfo.rank) .. ")") or "")
        else
            return string.format("%s %s",
                string.gsub(PET_LEVEL_TRANSLATION, "{1}", levelInfo.level),
                (levelInfo.unitType and GetUnitTypeOrDefault(levelInfo.unitType)) or "")
        end
    end

    if (not tooltipInfo.name or not tooltipInfo.levelInfo) then return end

    local translatedTooltipLines = {}

    table.insert(translatedTooltipLines, {
        index = 1,
        value = GetUnitNameOrDefault(tooltipInfo.name)
    })

    table.insert(translatedTooltipLines, {
        index = tooltipInfo.levelInfo.index,
        value = getLevelInfoString(tooltipInfo.levelInfo)
    })

    if (tooltipInfo.subnameInfo) then
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.subnameInfo.index,
            value = GetUnitSubnameOrDefault(tooltipInfo.subnameInfo.value)
        })
    end

    if (tooltipInfo.factionInfo) then
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.factionInfo.index,
            value = GetUnitFractionOrDefault(tooltipInfo.factionInfo.value)
        })
    end

    if (tooltipInfo.capturableLineIndex) then
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.capturableLineIndex,
            value = PET_CAPTURABLE_TRANSLATION
        })
    end

    if (tooltipInfo.collectedInfo) then
        local _, numValues = ExtractNumericValuesFromString(tooltipInfo.collectedInfo.value)
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.collectedInfo.index,
            value = InsertNumericValuesIntoString(PET_COLLECTED_TRANSLATION, numValues)
        })
    end

    if (tooltipInfo.leaderLineIndex) then
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.leaderLineIndex,
            value = LEADER_TRANSLATION
        })
    end

    return translatedTooltipLines
end
