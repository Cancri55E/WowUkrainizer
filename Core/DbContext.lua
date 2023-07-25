local _, ns = ...;

if (ns.DbContext) then return end

local NormalizeStringAndExtractNumerics = ns.StringNormalizer.NormalizeStringAndExtractNumerics
local ReconstructStringWithNumerics = ns.StringNormalizer.ReconstructStringWithNumerics

local dbContext = {}

local function getValueOrDefault(hashTable, default)
    if (not default) then return default end
    local hash = ns.StringExtensions.GetHash(default)
    return hashTable[hash] or default
end

local function getFormattedValueOrDefault(hashTable, default)
    if (not default) then return default end
    local text, numValues = NormalizeStringAndExtractNumerics(default)
    local translatedText = getValueOrDefault(hashTable, text)
    return ReconstructStringWithNumerics(translatedText, numValues)
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
        gender = 2 -- hook until table with translations not complited
        return index * 2 - (3 - gender)
    end

    function repository.GetUnitNameOrDefault(default)
        return getValueOrDefault(ns._db.UnitNames, default)
    end

    function repository.GetUnitSubnameOrDefault(default)
        return getValueOrDefault(ns._db.UnitSubnames, default)
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

    function repository.GetCinematicSubtitle(default)
        return getValueOrDefault(ns._db.CinematicSubtitles, default)
    end

    dbContext.Subtitles = repository
end

-- NPC Dialogs
do
    local repository = {}

    function repository.GetDialogText(default)
        return getValueOrDefault(ns._db.DialogTexts, default)
    end

    dbContext.NpcDialogs = repository
end

ns.DbContext = dbContext
