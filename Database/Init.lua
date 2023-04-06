local _, ns = ...;

do -- Constants
    ns.LEVEL_TRANSLATION = "Рівень"
    ns.PAGE_TRANSLATION = "Сторінка"
    ns.LEADER_TRANSLATION = "Лідер"
end

do
    if (ns._db) then return end

    local db = {}
    ns._db = db
end
