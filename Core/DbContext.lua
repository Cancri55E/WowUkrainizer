local addonName, ns = ...;

if (ns.DbContext) then return end

local dbContext = {}

do
    if (dbContext.Creatures) then return end

    local repository = {}

    function repository.GetUnitName(id)
        return nil -- TODO:
    end

    function repository.GetUnitSubnameWithFallback(default)
        return default -- TODO:
    end

    function repository.GetUnitTypeWithFallback(default)
        return default -- TODO:
    end

    function repository.GetUnitRankWithFallback(default)
        return default -- TODO:
    end

    function repository.GetUnitFractionWithFallback(default)
        return default -- TODO:
    end

    dbContext.Creatures = repository
end

ns.DbContext = dbContext
