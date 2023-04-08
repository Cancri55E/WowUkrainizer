local _, ns = ...;

if (ns.DbContext) then return end

local dbContext = {}

local function getValueWithFallback(hashTable, default)
    if (not default) then return default end
    local hash = ns.Utils.GetStringHash(default)
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

ns.DbContext = dbContext
