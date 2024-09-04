--- @class WowUkrainizerInternals
local ns = select(2, ...);

if (ns.DbContext) then return end

local NormalizeStringAndExtractNumerics = ns.StringNormalizer.NormalizeStringAndExtractNumerics
local ReconstructStringWithNumerics = ns.StringNormalizer.ReconstructStringWithNumerics

local NormalizePersonalizedString = ns.StringNormalizer.NormalizePersonalizedString
local ReconstructPersonalizedString = ns.StringNormalizer.ReconstructPersonalizedString

local RemoveBrackets = ns.StringUtil.RemoveBrackets
local ReplaceBracketsToColor = ns.StringUtil.ReplaceBracketsToColor

local GetHash = ns.StringUtil.GetHash
local GetNameHash = ns.StringUtil.GetNameHash
local Uft8Upper = ns.StringUtil.Uft8Upper
local ExtractFromText = ns.StringUtil.ExtractFromText

---@class DbContext
local dbContext = {}

---@class BaseRepository
local baseRepository = {}

--- Protected method to get the translated or the original (English) text if not translated.
---@param dbTable table<integer, string> @ The database table for translations.
---@param original string @ The original (English) text.
---@return string @ The translated or original value.
---@protected
function baseRepository._getValue(dbTable, original)
    if (not original or original == "") then return original end
    local hash = GetHash(original)
    return dbTable[hash] or original
end

--- Protected method to get the translated or the original (English) name if not translated.
---@param dbTable table<integer, string> @ The database table for translations.
---@param original string @ The original (English) name.
---@return string @ The translated or original value.
---@protected
function baseRepository._getNameValue(dbTable, original)
    if (not original or original == "") then return original end
    local hash = GetNameHash(original)
    return dbTable[hash] or original
end

--- Protected method to get the translated or the original (English) text if not translated. This method should be used if the text may contain numeric values and use 'Default' hash algorithm.
---@param dbTable table<integer, string> @ The database table for translations.
---@param original string @ The original (English) text.
---@return string @ The translated or original value.
---@protected
function baseRepository:_getFormattedValue(dbTable, original)
    if (not original) then return original end
    local text, numValues = NormalizeStringAndExtractNumerics(original)

    if (not text) then return original end

    local translatedText = self._getValue(dbTable, text)
    return ReconstructStringWithNumerics(translatedText, numValues)
end

--- Protected method to get the translated or the original (English) text if not translated. This method should be used if the text may contain numeric values and use 'Name' hash algorithm.
---@param dbTable table<integer, string> @ The database table for translations.
---@param original string @ The original (English) text.
---@return string @ The translated or original value.
---@protected
function baseRepository:_getFormattedNameValue(dbTable, original)
    if (not original) then return original end
    local text, numValues = NormalizeStringAndExtractNumerics(original)

    if (not text) then return original end

    local translatedText = self._getNameValue(dbTable, text)
    return ReconstructStringWithNumerics(translatedText, numValues)
end

--- Protected method to get the translated or the original (English) text if not translated. This method should be used if the text may contain personalized values (player name, class, etc.).
---@param dbTable table<integer, string> @ The database table for translations.
---@param original string @ The original (English) text.
---@return string @ The translated or original value.
---@protected
function baseRepository:_getPersonalizedValue(dbTable, original)
    if (not original) then return original end
    local text = NormalizePersonalizedString(original)
    local translatedText = self._getNameValue(dbTable, text)
    return ReconstructPersonalizedString(translatedText)
end

function baseRepository._normalizeBlizzardPlaceholders(text)
    local function getCaseLetterIndex(caseLetter)
        local case = 1
        if caseLetter and caseLetter ~= "" then
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
        end
        return case
    end

    if text == nil or text == "" then return text end

    local playerData = ns.PlayerInfo

    text = string.gsub(text, "%$[nN]", function(_)
        return playerData.Name
    end)

    text = string.gsub(text, "%$[pP]", function(_)
        return playerData.Name
    end)

    text = string.gsub(text, "%$[rR]:?([^\128-\191]?[\128-\191]?)", function(marker, caseLetter) -- TODO: case like class
        if (marker == "$R") then return Uft8Upper(playerData.Race) end
        return playerData.Race
    end)

    text = string.gsub(text, "%$[rsRS]:?([^\128-\191]?[\128-\191]?)", function(marker, caseLetter) -- TODO: case like class
        if (marker == "$RS") then return Uft8Upper(playerData.Race) end
        return playerData.Race
    end)

    text = string.gsub(text, "(%$[cC]):?([^\128-\191]?[\128-\191]?)", function(marker, caseLetter)
        local classStr = dbContext.Player.GetTranslatedClass(playerData.Class, getCaseLetterIndex(caseLetter), playerData.Gender)
        if (marker == "$C") then return Uft8Upper(classStr) end
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

-- Units
do
    ---@class UnitRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Get the translated unit name or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @param gender number? @ The gender value.
    --- @return string @ The translated unit name or the original (English) text.
    function repository.GetTranslatedUnitName(original, gender)
        --return repository._getValue(ns._db.UnitNames, original)
        if (not original) then return original end
        local translatedUnitName = repository._getValue(ns._db.UnitNames, original):gsub("{sex|(.-)|(.-)}",
            function(male, female) if (gender == 3) then return female else return male end end)
        return translatedUnitName
    end

    --- Get the translated unit subname based on gender or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @param gender number? @ The gender value.
    --- @return string @ The translated unit subname or the original (English) text.
    function repository.GetTranslatedUnitSubname(original, gender)
        if (not original) then return original end
        local translatedUnitSubname = repository._getValue(ns._db.UnitSubnames, original):gsub("{sex|(.-)|(.-)}",
            function(male, female) if (gender == 3) then return female else return male end end)
        return translatedUnitSubname
    end

    --- Get the translated unit type or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @return string @ The translated unit type or the original (English) text.
    function repository.GetTranslatedUnitType(original)
        return repository._getValue(ns._db.UnitTypes, original)
    end

    --- Get the translated unit rank or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @return string @ The translated unit rank or the original (English) text.
    function repository.GetTranslatedUnitRank(original)
        return repository._getValue(ns._db.UnitRanks, original)
    end

    --- Get the translated unit fraction or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @return string @ The translated unit fraction or the original (English) text.
    function repository.GetTranslatedUnitFraction(original)
        return original -- TODO:
    end

    dbContext.Units = repository
end

-- Player
do
    ---@class PlayerRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Calculate the index based on gender and case values.
    --- @param case number @ The case value.
    --- @param gender number? @ The gender value.
    --- @return number @ The calculated index.
    local function calculateClassTranslationIndex(case, gender)
        if (not case or not gender) then return 1 end
        return case * 2 - (3 - gender)
    end

    --- Get the translated class based on case and gender or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @param case number @ The case value.
    --- @param gender number? @ The gender value.
    --- @return string @ The translated class or the original (English) text.
    function repository.GetTranslatedClass(original, case, gender)
        local class = repository._getValue(ns._db.Classes, original)
        if (not class) then return original end

        return class[calculateClassTranslationIndex(case, gender)] or original
    end

    --- Get the translated specialization or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @return string @ The translated specialization or the original (English) text.
    function repository.GetTranslatedSpecialization(original)
        return repository._getValue(ns._db.Specializations, original)
    end

    --- Get the translated specialization note or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @return string @ The translated specialization note or the original (English) text.
    function repository.GetTranslatedSpecializationNote(original)
        return repository._getValue(ns._db.SpecializationNotes, original)
    end

    --- Get the translated role or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @return string @ The translated role or the original (English) text.
    function repository.GetTranslatedRole(original)
        return repository._getValue(ns._db.Roles, original)
    end

    --- Get the translated attribute or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @return string @ The translated attribute or the original (English) text.
    function repository.GetTranslatedAttribute(original)
        return repository._getValue(ns._db.Attributes, original)
    end

    --- Get the translated race or the original (English) text if not translated.
    --- @param original string @ The original (English) text.
    --- @return string @ The translated race or the original (English) text.
    function repository.GetTranslatedRace(original)
        return repository._getValue(ns._db.Races, original)
    end

    --- Get the translated race or the original (English) text if not translated.
    --- @param raceName string @ The english fullname race.
    --- @return string @ The translated short race or the original (English) text.
    function repository.GetTranslatedShortRace(raceName)
        return ns._db.ShortRaces[raceName]
    end

    dbContext.Player = repository
end

-- Spells
do
    ---@class SpellRepository : BaseRepository
    local repository = setmetatable({ _spellColor = "FF47D4FF" }, { __index = baseRepository })

    --- Get the translated or the original (English) spell name.
    --- @param original string @ The the original (English) spell name.
    --- @param highlight boolean @ Whether to highlight the result.
    --- @return string @ The translated or the original (English) spell name.
    function repository.GetTranslatedSpellName(original, highlight)
        local result = repository._getValue(ns._db.SpellNames, original)
        if (result ~= original) then
            if (highlight) then
                return ReplaceBracketsToColor(result, repository._spellColor)
            else
                return RemoveBrackets(result)
            end
        end
        return original
    end

    --- Get the translated or the original (English) spell description.
    --- @param original string @ The the original (English) spell description.
    --- @param highlight boolean @ Whether to highlight the result.
    --- @return string @ The translated or the original (English) spell description.
    function repository.GetTranslatedSpellDescription(original, highlight)
        local result = repository:_getFormattedValue(ns._db.SpellDescriptions, original)
        if (result ~= original) then
            if (highlight) then
                return ReplaceBracketsToColor(result, repository._spellColor)
            else
                return RemoveBrackets(result)
            end
        end
        return original
    end

    --- Get the translated or the original (English) spell attribute.
    --- @param original string @ The the original (English) spell attribute.
    --- @return string @ The translated or default spell attribute.
    function repository.GetTranslatedSpellAttribute(original)
        return repository:_getFormattedValue(ns._db.CommonSpellAttributes, original)
    end

    dbContext.Spells = repository
end

-- Frames
do
    ---@class UIFrameRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    function repository.GetWhatsNewFrameInfo(version)
        return ns._db.SplashFrames.WhatsNew[version]
    end

    dbContext.Frames = repository
end

-- Subtitles
do
    ---@class SubtitleRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Get the translated or original (English) movie subtitle.
    --- @param original string @ The original (English) movie subtitle.
    --- @return string @ The translated or original movie subtitle.
    function repository.GetTranslatedMovieSubtitle(original)
        return repository._getValue(ns._db.MovieSubtitles, original)
    end

    dbContext.Subtitles = repository
end

-- NPC Dialogs
do
    ---@class NpcDialogRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Get the translated or original (English) NPC message text.
    --- @param original string @ The original (English) NPC dialog text.
    --- @return string @ The translated or original NPC dialog text.
    function repository.GetTranslatedNpcMessage(original)
        return repository:_getPersonalizedValue(ns._db.DialogTexts, original)
    end

    --- Get the translated or original (English) cinematic subtitle for NPCs.
    --- @param original string @ The original (English) cinematic subtitle.
    --- @return string @ The translated or original cinematic subtitle.
    function repository.GetTranslatedCinematicSubtitle(original)
        return repository:_getPersonalizedValue(ns._db.CinematicSubtitles, original)
    end

    dbContext.NpcDialogs = repository
end

-- Gossips
do
    ---@class GossipRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Get the translated or original (English) gossip text.
    --- @param original string @ The original (English) gossip text.
    --- @return string @ The translated or original gossip text.
    function repository.GetTranslatedGossipText(original)
        return repository._getValue(ns._db.GossipTitles, original)
    end

    --- Get the translated or original (English) gossip option text.
    --- @param original string @ The original (English) gossip option text.
    --- @return string @ The translated or original gossip option text.
    function repository.GetTranslatedGossipOptionText(original)
        return repository._getValue(ns._db.GossipOptions, original)
    end

    dbContext.Gossips = repository
end

-- Quests
do
    ---Quest data in the database is stored as string arrays, and the indices are used to access specific information, like the quest title or description, within the array.
    ---@enum QuestTranslationIndex
    local QuestTranslationIndex = {
        TITLE = 1,
        DESCRIPTION = 2,
        OBJECTIVES_TEXT = 3,
        TARGET_NAME = 4,
        TARGET_DESCRIPTION = 5,
        COMPLETED_TARGET_NAME = 6,
        COMPLETED_TARGET_DESCRIPTION = 7,
        LOG_COMPLETION_TEXT = 8,
        REWARD_TEXT = 9,
        COMPLETED_TEXT = 10,
        AREA_DESCRIPTION = 11
    }

    ---@class QuestRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Retrieves the quest objective text based on the quest ID.
    ---@param questId number The ID of the quest.
    ---@param original string The original (English) value.
    ---@return string @The translated and normalized quest objective text.
    function repository.GetTranslatedQuestObjective(questId, original)
        if (not original) then return original end

        local objectives = ns._db.QuestObjectives[questId]
        if (not objectives and not ns.SettingsProvider.GetOption(WOW_UKRAINIZER_DISABLE_MT_FOR_QUESTS_OPTION)) then
            objectives = ns._db.MTQuestObjectives[questId]
        end

        if (not objectives) then return original end

        local waypointText = ExtractFromText(WAYPOINT_OBJECTIVE_FORMAT_OPTIONAL, original)
        if (waypointText) then
            local translatedWaypointText = repository.GetWaypointTranslation(waypointText)
            if (translatedWaypointText ~= waypointText) then
                return dbContext.GlobalStrings.GetTranslatedGlobalString(WAYPOINT_OBJECTIVE_FORMAT_OPTIONAL, true):format(translatedWaypointText)
            end
        end

        local progressText = nil
        local completeText = nil
        local optionalText = nil
        local objectiveText = original

        local tmp;
        local containsProgressText = objectiveText:match("^(%d+/%d+)")
        if (containsProgressText) then
            tmp = objectiveText:gsub("^(%d+/%d+)(.*)%s*(%b())%s*(%b())%s*$", function(p, o, op, c)
                progressText = p
                objectiveText = o
                completeText = c
                optionalText = op
            end)
            if (not optionalText) then
                tmp = objectiveText:gsub("^(%d+/%d+)(.*)%s*(%b())%s*$", function(p, o, c)
                    progressText = p
                    objectiveText = o
                    if (c == '(Complete)') then
                        completeText = c
                    else
                        optionalText = c
                    end
                end)
                if (not completeText and not optionalText) then
                    tmp = objectiveText:gsub("^(%d+/%d+)(.*)", function(p, o)
                        progressText = p
                        objectiveText = o
                    end)
                end
            end
        else
            tmp = objectiveText:gsub("^(.*)%s*(%b())%s*(%b())%s*$", function(o, op, c)
                objectiveText = o
                completeText = c
                optionalText = op
            end)
            if (not optionalText) then
                tmp = objectiveText:gsub("^(.*)%s*(%b())%s*$", function(o, c)
                    objectiveText = o
                    if (c == '(Complete)') then
                        completeText = c
                    else
                        optionalText = c
                    end
                end)
            end
        end

        local translatedObjectiveText = repository._getValue(objectives, objectiveText)

        if (progressText) then
            translatedObjectiveText = progressText .. " " .. translatedObjectiveText
        end

        if (optionalText) then
            translatedObjectiveText = dbContext.GlobalStrings.GetTranslatedGlobalString(OPTIONAL_QUEST_OBJECTIVE_DESCRIPTION):format(translatedObjectiveText)
        end

        if (completeText) then
            translatedObjectiveText = dbContext.GlobalStrings.GetTranslatedGlobalString(ERR_QUEST_OBJECTIVE_COMPLETE_S):format(translatedObjectiveText)
        end

        return repository._normalizeBlizzardPlaceholders(translatedObjectiveText)
    end

    --- Retrieves the quest title based on the quest ID.
    ---@param questId number The ID of the quest.
    ---@return string? @The translated quest title.
    function repository.GetTranslatedQuestTitle(questId)
        local data = ns._db.Quests[questId]
        if (not data and not ns.SettingsProvider.GetOption(WOW_UKRAINIZER_DISABLE_MT_FOR_QUESTS_OPTION)) then
            data = ns._db.MTQuests[questId]
        end

        if (not data) then return end

        return data[QuestTranslationIndex.TITLE]
    end

    --- Gets translated quest data including title, description, objectives, and other details.
    ---@param questId number @The ID of the quest.
    ---@return TranslatedQuestData? @An object containing quest details.
    function repository.GetTranslatedQuestData(questId)
        local questData = ns._db.Quests[questId]
        local mtQuestData = nil

        if (not ns.SettingsProvider.GetOption(WOW_UKRAINIZER_DISABLE_MT_FOR_QUESTS_OPTION)) then
            mtQuestData = ns._db.MTQuests[questId]
        end

        if (not questData and not mtQuestData) then return end

        local isMtDataUsed = false

        --- Retrieves a translated value from either the main data or the machine translation data.
        --- @param index number The index of the data row to retrieve.
        --- @param postProcessFunc function | nil The function to apply as a post-processing step on the retrieved data row.
        --- @return string The retrieved translated value, optionally post-processed.
        local function getTranslatedValue(index, postProcessFunc)
            local dataRow = questData and questData[index]
            local mtDataRow = mtQuestData and mtQuestData[index]

            if not dataRow and mtDataRow then
                isMtDataUsed = true
            end

            local value = dataRow or mtDataRow

            if (postProcessFunc ~= nil) then
                return postProcessFunc(value)
            else
                return value
            end
        end

        ---@type TranslatedQuestData
        local translatedQuestData = {
            ID = questId,
            Title = getTranslatedValue(QuestTranslationIndex.TITLE),
            Description = getTranslatedValue(QuestTranslationIndex.DESCRIPTION, repository._normalizeBlizzardPlaceholders),
            ObjectivesText = getTranslatedValue(QuestTranslationIndex.OBJECTIVES_TEXT, repository._normalizeBlizzardPlaceholders),
            ContainsObjectives = ns._db.QuestObjectives[questId] ~= nil or ns._db.MTQuestObjectives[questId] ~= nil,
            CompletionText = getTranslatedValue(QuestTranslationIndex.LOG_COMPLETION_TEXT),
            TargetName = getTranslatedValue(QuestTranslationIndex.TARGET_NAME),
            TargetDescription = getTranslatedValue(QuestTranslationIndex.TARGET_DESCRIPTION),
            TargetCompletedName = getTranslatedValue(QuestTranslationIndex.COMPLETED_TARGET_NAME),
            TargetCompletedDescription = getTranslatedValue(QuestTranslationIndex.COMPLETED_TARGET_DESCRIPTION),
            AreaDescription = getTranslatedValue(QuestTranslationIndex.AREA_DESCRIPTION),
            RewardText = getTranslatedValue(QuestTranslationIndex.REWARD_TEXT, repository._normalizeBlizzardPlaceholders),
            ProgressText = getTranslatedValue(QuestTranslationIndex.COMPLETED_TEXT, repository._normalizeBlizzardPlaceholders),
        }

        if (isMtDataUsed) then
            translatedQuestData.IsMtData = true
        end

        return translatedQuestData
    end

    --- Get the translated or original (English) NPC message text.
    --- @param original string @ The original (English) NPC dialog text.
    --- @return string @ The translated or original NPC dialog text.
    function repository.GetWaypointTranslation(original)
        return repository._getValue(ns._db.Waypoints, original)
    end

    dbContext.Quests = repository
end

-- Zone Texts
do
    ---@class ZoneTextRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Get the translated or original (English) zone or subzone text.
    --- @param original string @ The original (English) zone or subzone text.
    --- @return string @ The translated or original zone or subzone text.
    function repository.GetTranslatedZoneText(original)
        return repository._getNameValue(ns._db.ZoneTexts, original)
    end

    dbContext.ZoneTexts = repository
end

-- Global strings
do
    ---@class GlobalStringRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Get the translated or original (English) global string.
    --- @param original string @ The original (English) global string.
    --- @return string @ The translated or original global string.
    function repository.GetTranslatedGlobalString(original, withoutFormatting)
        if (withoutFormatting) then
            return repository._getNameValue(ns._db.GlobalStrings, original)
        end
        return repository:_getFormattedNameValue(ns._db.GlobalStrings, original)
    end

    dbContext.GlobalStrings = repository
end

-- Items
do
    ---Item data in the database is stored as string arrays, and the indices are used to access specific information, like the title, within the array.
    ---@enum ItemTranslationIndex
    local ItemTranslationIndex = {
        TITLE = 1,
        DESCRIPTION = 2,
    }

    ---@class ItemsRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Get the translated item data including title and description
    --- @param itemID number @The ID of the item.
    --- @return TranslatedItemData? @An object containing translated item data.
    function repository.GetItemTranslation(itemID)
        local itemData = ns._db.Items[itemID]

        if (not itemData) then return end

        ---@type TranslatedItemData
        local translatedData = {
            Title = itemData[ItemTranslationIndex.TITLE],
            Description = itemData[ItemTranslationIndex.DESCRIPTION],
        }
        return translatedData
    end

    --- Get the translated or original (English) description.
    --- @param original string @ The original (English) description.
    --- @return string @ The translated or original description.
    function repository.GetTranslatedItemAttribute(original)
        return repository._getValue(ns._db.ItemAttributes, original)
    end

    dbContext.Items = repository
end

-- Reputations and Factions
do
    ---@class FactionRepository : BaseRepository
    local repository = setmetatable({}, { __index = baseRepository })

    --- Get the translated or original (English) faction.
    --- @param original string @ The original (English) faction.
    --- @return string @ The translated or original faction.
    function repository.GetTranslatedFaction(original)
        return repository._getValue(ns._db.GlobalStrings, original)
    end

    dbContext.Factions = repository
end

ns.DbContext = dbContext
