local _, ns = ...;

if (ns.DbContext) then return end

local NormalizeStringAndExtractNumerics = ns.StringNormalizer.NormalizeStringAndExtractNumerics
local ReconstructStringWithNumerics = ns.StringNormalizer.ReconstructStringWithNumerics
local NormalizePersonalizedString = ns.StringNormalizer.NormalizePersonalizedString
local ReconstructPersonalizedString = ns.StringNormalizer.ReconstructPersonalizedString

local NormalizePersonalizedString = ns.StringNormalizer.NormalizePersonalizedString
local ReconstructPersonalizedString = ns.StringNormalizer.ReconstructPersonalizedString

local dbContext = {}

local function getValueOrDefault(hashTable, default)
    if (not default) then return default end
    local hash = ns.StringExtensions.GetHash(default)
    return hashTable[hash] or default, hash
end

local function getFormattedValueOrDefault(hashTable, default)
    if (not default) then return default end
    local text, numValues = NormalizeStringAndExtractNumerics(default)
    local translatedText = getValueOrDefault(hashTable, text)
    return ReconstructStringWithNumerics(translatedText, numValues)
end

local function getPersonalizedValueOrDefault(hashTable, default)
    if (not default) then return default end
    local text = NormalizePersonalizedString(default)
    local translatedText, hash = getValueOrDefault(hashTable, text)
    return ReconstructPersonalizedString(translatedText), hash
end

local function removeBrackets(str)
    return str:gsub("[%[%]]", "")
end

local function replaceBrackets(str)
    str = str:gsub("%[", "|cFF47D5FF")
    str = str:gsub("%]", "|r")
    return str
end

-- Units
do
    local repository = {}

    local function calcIndex(index, gender)
        if (not index or not gender) then return 1 end
        --gender = 2 -- hook until table with translations not complited
        return index * 2 - (3 - gender)
    end

    function repository.GetUnitNameOrDefault(default)
        return getValueOrDefault(ns._db.UnitNames, default)
    end

    function repository.GetUnitSubnameOrDefault(default, gender)
        return getValueOrDefault(ns._db.UnitSubnames, default):gsub("{sex|(.-)|(.-)}", function(male, female)
            if (gender == 3) then
                return female
            else
                return male
            end
        end)
    end

    function repository.GetUnitTypeOrDefault(default)
        return getValueOrDefault(ns._db.UnitTypes, default)
    end

    function repository.GetUnitRankOrDefault(default)
        return getValueOrDefault(ns._db.UnitRanks, default)
    end

    function repository.GetUnitFractionOrDefault(default)
        if (not default) then return default end
        return default -- TODO:
    end

    function repository.GetClass(default, case, gender)
        if (not default) then return default end

        local class = getValueOrDefault(ns._db.Classes, default)
        if (not class) then return default end

        return class[calcIndex(case, gender)] or default
    end

    function repository.GetSpecialization(default)
        if (not default) then return default end
        return getValueOrDefault(ns._db.Specializations, default)
    end

    function repository.GetSpecializationNote(default)
        if (not default) then return default end
        return getValueOrDefault(ns._db.SpecializationNotes, default)
    end

    function repository.GetRole(default)
        if (not default) then return default end
        return getValueOrDefault(ns._db.Roles, default)
    end

    function repository.GetAttribute(default)
        if (not default) then return default end
        return getValueOrDefault(ns._db.Attributes, default)
    end

    dbContext.Units = repository
end

-- Spells
do
    local repository = {}

    function repository.GetSpellNameOrDefault(default, highlight)
        local result = getValueOrDefault(ns._db.SpellNames, default)
        if (result ~= default) then
            if (highlight) then
                return replaceBrackets(result)
            else
                return removeBrackets(result)
            end
        end
        return default
    end

    function repository.GetSpellDescriptionOrDefault(default, highlight)
        local result = getFormattedValueOrDefault(ns._db.SpellDescriptions, default)
        if (result ~= default) then
            if (highlight) then
                return replaceBrackets(result)
            else
                return removeBrackets(result)
            end
        end
        return default
    end

    function repository.GetSpellAttributeOrDefault(default)
        return getFormattedValueOrDefault(ns._db.CommonSpellAttributes, default)
    end

    dbContext.Spells = repository
end

-- Frames
do
    local repository = {}

    function repository.GetTranslationOrDefault(type, default)
        if (type == "spellbook") then
            return getFormattedValueOrDefault(ns._db.SpellbookFrameLines, default)
        elseif (type == "class_talent") then
            return getFormattedValueOrDefault(ns._db.ClassTalentFrameLines, default)
        elseif (type == "main") then
            return getFormattedValueOrDefault(ns._db.MainFrameLines, default)
        elseif (type == "quest") then
            return getValueOrDefault(ns._db.QuestFrameLines, default)
        end
    end

    function repository.GetAdditionalSpellTipsOrDefault(default)
        return getFormattedValueOrDefault(ns._db.AdditionalSpellTips, default)
    end

    dbContext.Frames = repository
end

-- Subtitles
do
    local repository = {}

    function repository.GetMovieSubtitle(default)
        return getValueOrDefault(ns._db.MovieSubtitles, default)
    end

    dbContext.Subtitles = repository
end

-- NPC Dialogs
do
    local repository = {}

    function repository.GetDialogText(default)
        return getPersonalizedValueOrDefault(ns._db.DialogTexts, default)
    end

    function repository.GetCinematicSubtitle(default)
        return getPersonalizedValueOrDefault(ns._db.CinematicSubtitles, default)
    end

    dbContext.NpcDialogs = repository
end

-- Gossips
do
    local repository = {}

    function repository.GetGossipTitle(default)
        return getValueOrDefault(ns._db.GossipTitles, default)
    end

    function repository.GetGossipOptionText(default)
        return getValueOrDefault(ns._db.GossipOptions, default)
    end

    dbContext.Gossips = repository
end

-- Quests
do
    local QUEST_TITLE = 1
    local QUEST_DESCRIPTION = 2
    local QUEST_OBJECTIVES_TEXT = 3
    local QUEST_TARGET_NAME = 4
    local QUEST_TARGET_DESCRIPTION = 5
    local QUEST_COMPLETED_TARGET_NAME = 6
    local QUEST_COMPLETED_TARGET_DESCRIPTION = 7
    local QUEST_LOG_COMPLETION_TEXT = 8
    local QUEST_REWARD_TEXT = 9
    local QUEST_COMPLETED_TEXT = 10
    local QUEST_AREA_DESCRIPTION = 11

    local repository = {}

    local function normalizeQuestString(text)
        if text == nil or text == "" then return text end

        local playerData = ns.PlayerData

        text = string.gsub(text, "%$[nN]", function(_)
            return playerData.Name
        end)

        text = string.gsub(text, "%$[rR]", function(marker) -- TODO: case like class
            if (marker == "$R") then return string.upper(playerData.Race) end
            return playerData.Race
        end)

        text = string.gsub(text, "(%$[cC]):([^\128-\191][\128-\191])", function(marker, caseLetter)
            local case = 1
            if (caseLetter == 'н' or caseLetter == 'Н') then
                case = 1
            elseif (caseLetter == 'р' or caseLetter == 'Р') then
                case = 2
            elseif (caseLetter == 'д' or caseLetter == 'Д') then
                case = 3
            elseif (caseLetter == 'з' or caseLetter == 'З') then
                case = 4
            elseif (caseLetter == 'о' or caseLetter == 'О') then
                case = 5
            elseif (caseLetter == 'м' or caseLetter == 'М') then
                case = 6
            elseif (caseLetter == 'к' or caseLetter == 'К') then
                case = 7
            end

            local classStr = dbContext.Units.GetClass(playerData.Class, case, playerData.Gender)

            if (marker == "$C") then return string.upper(classStr) end
            return classStr
        end)

        text = string.gsub(text, "%$[cC]", function(marker)
            local classStr = dbContext.Units.GetClass(playerData.Class, 1, playerData.Gender)

            if (marker == "$C") then return string.upper(classStr) end
            return classStr
        end)

        text = string.gsub(text, "{sex|(.-)|(.-)}", function(male, female)
            if (playerData.Gender == 3) then
                return female
            else
                return male
            end
        end)

        return text
    end

    function repository.ContainsQuestData(questId) return ns._db.Quests[questId] ~= nil end

    function repository.GetQuestObjective(questId, default)
        if (not default) then return default end

        local objectives = ns._db.QuestObjectives[questId]
        if (not objectives) then return default end

        local progressText = nil
        local completeText = nil
        local objectiveText = default
        objectiveText:gsub("^(%d+/%d+)(.*)%s*(%b())%s*$", function(p, o, c)
            progressText = p
            objectiveText = o
            completeText = c
        end)
        if (not completeText) then
            objectiveText:gsub("^(%d+/%d+)(.*)", function(p, o)
                progressText = p
                objectiveText = o
            end)
        end

        local translatedObjectiveText = getValueOrDefault(objectives, objectiveText)
        if (progressText) then
            translatedObjectiveText = progressText .. " " .. translatedObjectiveText
        end
        if (completeText) then
            translatedObjectiveText = translatedObjectiveText .. " (Виконано)"
        end
        return normalizeQuestString(translatedObjectiveText)
    end

    function repository.GetQuestRewardText(questId)
        local data = ns._db.Quests[questId]
        if (not data) then return end
        return normalizeQuestString(data[QUEST_REWARD_TEXT])
    end

    function repository.GetQuestProgressText(questId)
        local data = ns._db.Quests[questId]
        if (not data) then return end
        return normalizeQuestString(data[QUEST_COMPLETED_TEXT])
    end

    function repository.GetQuestTitle(questId)
        local data = ns._db.Quests[questId]
        if (not data) then return end
        return data[QUEST_TITLE]
    end

    function repository.GetQuestData(questId)
        local data = ns._db.Quests[questId]
        if (not data) then return end
        return {
            ID = questId,
            Title = data[QUEST_TITLE],
            Description = normalizeQuestString(data[QUEST_DESCRIPTION]),
            ObjectivesText = normalizeQuestString(data[QUEST_OBJECTIVES_TEXT]),
            ContainsObjectives = ns._db.QuestObjectives[questId] ~= nil,
            CompletionText = data[QUEST_LOG_COMPLETION_TEXT],
            TargetName = data[QUEST_TARGET_NAME],
            TargetDescription = data[QUEST_TARGET_DESCRIPTION],
            TargetCompletedName = data[QUEST_COMPLETED_TARGET_NAME],
            TargetCompletedDescription = data[QUEST_COMPLETED_TARGET_DESCRIPTION],
            AreaDescription = data[QUEST_AREA_DESCRIPTION],
        }
    end

    dbContext.Quests = repository
end

ns.DbContext = dbContext
