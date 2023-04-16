local _, ns = ...;

if (ns.DbContext) then return end

local ExtractNumericValuesFromString = ns.StringExtensions.ExtractNumericValuesFromString
local InsertNumericValuesIntoString = ns.StringExtensions.InsertNumericValuesIntoString

local dbContext = {}

local function getValueOrDefault(hashTable, default)
    if (not default) then return default end
    local hash = ns.StringExtensions.GetHash(default)
    return hashTable[hash] or default
end

local function getFormattedValueOrDefault(hashTable, default)
    if (not default) then return default end
    local text, numValues = ExtractNumericValuesFromString(default)
    local translatedText = getValueOrDefault(hashTable, text)
    return InsertNumericValuesIntoString(translatedText, numValues)
end

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

    dbContext.Units = repository
end

do
    local repository = {}

    function repository.GetSpellNameOrDefault(default)
        for _, value in ipairs(ns._db.SpellNames) do
            local result = getValueOrDefault(value, default)
            if (result ~= default) then return result end
        end
        return default
    end

    function repository.GetSpellDescriptionOrDefault(default)
        for _, value in ipairs(ns._db.SpellDescriptions) do
            local result = getFormattedValueOrDefault(value, default)
            if (result ~= default) then return result end
        end
        return default
    end

    function repository.GetSpellAttributeOrDefault(default)
        return getFormattedValueOrDefault(ns._db.CommonSpellAttributes, default)
    end

    dbContext.Spells = repository
end

do
    local repository = {}

    function repository.GetTranslationOrDefault(default)
        return getValueOrDefault(ns._db.SpellbookFrameLines, default)
    end

    dbContext.SpellbookFrame = repository
end

ns.DbContext = dbContext
