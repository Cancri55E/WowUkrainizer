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

    dbContext.Units = repository
end

do
    local repository = {}

    function repository.GetSpellNameOrDefault(default)
        return getValueOrDefault(ns._db.SpellNames, default)
    end

    function repository.GetSpellDescriptionOrDefault(default)
        return getFormattedValueOrDefault(ns._db.SpellDescriptions, default)
    end

    function repository.GetSpellAttributeOrDefault(default)
        return getFormattedValueOrDefault(ns._db.CommonSpellAttributes, default)
    end

    dbContext.Spells = repository
end

ns.DbContext = dbContext
