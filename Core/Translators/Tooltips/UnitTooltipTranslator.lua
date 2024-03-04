--- @type string, WowUkrainizerInternals
local _, ns = ...;

local _G = _G

local LEADER_TRANSLATION = ns.LEADER_TRANSLATION
local LEVEL_TRANSLATION = ns.LEVEL_TRANSLATION
local PET_LEVEL_TRANSLATION = ns.PET_LEVEL_TRANSLATION
local PET_CAPTURABLE_TRANSLATION = ns.PET_CAPTURABLE_TRANSLATION
local PET_COLLECTED_TRANSLATION = ns.PET_COLLECTED_TRANSLATION

local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName
local GetTranslatedUnitSubname = ns.DbContext.Units.GetTranslatedUnitSubname
local GetTranslatedUnitType = ns.DbContext.Units.GetTranslatedUnitType
local GetTranslatedUnitRank = ns.DbContext.Units.GetTranslatedUnitRank
local GetTranslatedUnitFraction = ns.DbContext.Units.GetTranslatedUnitFraction
local GetTranslatedQuestTitle = ns.DbContext.Quests.GetTranslatedQuestTitle
local GetTranslatedQuestObjective = ns.DbContext.Quests.GetTranslatedQuestObjective

local StartsWith = ns.StringUtil.StartsWith
local ExtractNumericValues = ns.StringUtil.ExtractNumericValues
local InsertNumericValues = ns.StringUtil.InsertNumericValues

---@class UnitTooltipTranslator : BaseTooltipTranslator
local translator = setmetatable({ tooltipDataType = Enum.TooltipDataType.Unit }, { __index = ns.BaseTooltipTranslator })

local function parseUnitTooltipLines(tooltipLines)
    local function parseSubnameInfo(tooltipLine)
        local value = tooltipLine.leftText
        local isSubname = value and value:sub(1, 9) ~= "Pet Level" and value:sub(1, 5) ~= "Level"
        return isSubname and { index = tooltipLine.lineIndex, value = tooltipLine.leftText } or nil
    end

    local function parseUnitLevel(unitLevelString)
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

    local function getOrCreateQuestInfo(result, questID)
        if (questID == 0) then return end
        if (not result.questsInfo) then result.questsInfo = {} end
        if (not result.questsInfo[questID]) then result.questsInfo[questID] = { objectives = {} } end

        return result.questsInfo[questID]
    end

    local result = { name = tooltipLines[1].leftText }

    if (#tooltipLines == 1) then return result end

    result.subnameInfo = parseSubnameInfo(tooltipLines[2])

    local index = result.subnameInfo and 3 or 2

    if (index > #tooltipLines) then return result end

    local levelLine = tooltipLines[index]
    if (levelLine) then
        result.levelInfo = { index = index }
        result.levelInfo.level, result.levelInfo.unitType, result.levelInfo.rank, result.levelInfo.isPet = parseUnitLevel(
            levelLine.leftText)
    end

    local currentQuestID = 0
    for i = index + 1, #tooltipLines, 1 do
        local tooltipLine = tooltipLines[i]
        if (tooltipLine.type == Enum.TooltipDataLineType.None) then
            local leftText = tooltipLine.leftText
            if leftText == "Capturable" then
                result.capturableLineIndex = i
            elseif leftText == "Leader" then
                result.leaderLineIndex = i
            elseif leftText == "PvP" then
                result.pvpInfo = { index = i, value = leftText }
            elseif StartsWith(leftText, "Collected") then
                result.collectedInfo = { index = i, value = leftText }
            elseif not result.pvpInfo and not result.unitTypeOrFactionInfo then -- faction always befor pvp, if we already contains PvP then faction not exists
                result.unitTypeOrFactionInfo = { index = i, value = leftText }
            end
        elseif (tooltipLine.type == Enum.TooltipDataLineType.QuestTitle) then
            currentQuestID = math.floor(tonumber(tooltipLine.id) or 0)
            local questInfo = getOrCreateQuestInfo(result, currentQuestID)
            if (questInfo) then
                questInfo.index = i
                questInfo.name = tooltipLine.leftText
            end
        elseif (tooltipLine.type == Enum.TooltipDataLineType.QuestObjective) then
            local questInfo = getOrCreateQuestInfo(result, currentQuestID)
            if (questInfo) then questInfo.objectives[i] = tooltipLine.leftText end
        end
    end

    return result
end

function translator:ParseTooltip(tooltip, tooltipData)
    local unitKind = strsplit("-", tooltipData.guid)
    if (unitKind == "Creature" or unitKind == "Vehicle") then
        for i = 1, tooltip:NumLines() do
            self:AddFontStringToIndexLookup(i, _G["GameTooltipTextLeft" .. i])
        end
        return parseUnitTooltipLines(tooltipData.lines)
    end
end

function translator:TranslateTooltipInfo(tooltipInfo)
    local function getLevelInfoString(levelInfo)
        if (not levelInfo.isPet) then
            return string.format("%s%s%s%s",
                LEVEL_TRANSLATION,
                levelInfo.level and " " .. levelInfo.level or "",
                (levelInfo.unitType and " " .. GetTranslatedUnitType(levelInfo.unitType)) or "",
                (levelInfo.rank and " (" .. GetTranslatedUnitRank(levelInfo.rank) .. ")") or "")
        else
            return string.format("%s %s",
                string.gsub(PET_LEVEL_TRANSLATION, "{1}", levelInfo.level),
                (levelInfo.unitType and GetTranslatedUnitType(levelInfo.unitType)) or "")
        end
    end

    if (not tooltipInfo.name) then return end

    local translatedTooltipLines = {}

    table.insert(translatedTooltipLines, {
        index = 1,
        value = GetTranslatedUnitName(tooltipInfo.name)
    })

    if (tooltipInfo.levelInfo) then
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.levelInfo.index,
            value = getLevelInfoString(tooltipInfo.levelInfo)
        })
    end

    if (tooltipInfo.subnameInfo) then
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.subnameInfo.index,
            value = GetTranslatedUnitSubname(tooltipInfo.subnameInfo.value, UnitSex("mouseover"))
        })
    end

    if (tooltipInfo.unitTypeOrFactionInfo) then
        local value = tooltipInfo.unitTypeOrFactionInfo.value
        local translatedValue = GetTranslatedUnitType(value)
        if (translatedValue == value) then
            translatedValue = GetTranslatedUnitFraction(value)
        end
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.unitTypeOrFactionInfo.index,
            value = translatedValue
        })
    end

    if (tooltipInfo.capturableLineIndex) then
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.capturableLineIndex,
            value = PET_CAPTURABLE_TRANSLATION
        })
    end

    if (tooltipInfo.collectedInfo) then
        local _, numValues = ExtractNumericValues(tooltipInfo.collectedInfo.value)
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.collectedInfo.index,
            value = InsertNumericValues(PET_COLLECTED_TRANSLATION, numValues)
        })
    end

    if (tooltipInfo.leaderLineIndex) then
        table.insert(translatedTooltipLines, {
            index = tooltipInfo.leaderLineIndex,
            value = LEADER_TRANSLATION
        })
    end

    if (tooltipInfo.questsInfo) then
        for questID, questInfo in pairs(tooltipInfo.questsInfo) do
            local translatedTitle = GetTranslatedQuestTitle(questID)
            if (translatedTitle) then
                table.insert(translatedTooltipLines, {
                    index = questInfo.index,
                    value = translatedTitle
                })
            end
            for index, objective in pairs(questInfo.objectives) do
                local translatedObjective = GetTranslatedQuestObjective(questID, objective)
                if (translatedObjective) then
                    table.insert(translatedTooltipLines, {
                        index = index,
                        value = translatedObjective
                    })
                end
            end
        end
    end

    return translatedTooltipLines
end

function translator:IsEnabled()
    return self.settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_UNIT_TOOLTIPS_OPTION)
end

ns.TranslationsManager:AddTranslator(translator)
