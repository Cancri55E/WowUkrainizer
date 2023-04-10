local _, ns = ...;

if (ns.DbContext) then return end

local ExtractValuesFromString = ns.StringExtensions.ExtractValuesFromString
local InsertValuesIntoString = ns.StringExtensions.InsertValuesIntoString

local dbContext = {}

local function getValueWithFallback(hashTable, default)
    if (not default) then return default end
    local hash = ns.StringExtensions.GetHash(default)
    return hashTable[hash] or default
end

do
    local repository = {}

    function repository.GetUnitNameWithFallback(default)
        return getValueWithFallback(ns._db.UnitNames, default)
    end

    function repository.GetUnitSubnameWithFallback(default)
        return getValueWithFallback(ns._db.UnitSubnames, default)
    end

    function repository.GetUnitTypeWithFallback(default)
        return getValueWithFallback(ns._db.UnitTypes, default)
    end

    function repository.GetUnitRankWithFallback(default)
        return getValueWithFallback(ns._db.UnitRanks, default)
    end

    function repository.GetUnitFractionWithFallback(default)
        if (not default) then return default end
        return default -- TODO:
    end

    dbContext.Units = repository
end

do
    local repository = {}

    function repository.GetSpellNameWithFallback(default)
        return getValueWithFallback(ns._db.SpellNames, default)
    end

    function repository.GetSpellDescriptionWithFallback(default)
        local text, values = ExtractValuesFromString(default)
        local translatedText = getValueWithFallback(ns._db.SpellDescriptions, text)
        return InsertValuesIntoString(translatedText, values)
    end

    function repository.GetSpellCharacteristicsWithFallback(default)
        local text, values = ExtractValuesFromString(default)
        local translatedText = getValueWithFallback(ns._db.CommonSpellCharacteristics, text)
        return InsertValuesIntoString(translatedText, values)
    end

    dbContext.Spells = repository
end

ns.DbContext = dbContext
