local _, ns = ...;

-- Constants
ns.LEVEL_TRANSLATION = "Рівень"
ns.PAGE_TRANSLATION = "Сторінка"
ns.LEADER_TRANSLATION = "Правитель"

ns._db = {}
do
    local data = {
        [1263733816] = "Звір",
        [1380758106] = "Драконід",
        [2922108995] = "Демон",
        [530495695] = "Елементаль",
        [1257650543] = "Гігант",
        [1335182036] = "Нежить",
        [589698483] = "Гуманоїд",
        [514370084] = "Створіння",
        [1163581639] = "Механізм",
        [237873257] = "Тотем",
        [4168209797] = "Небойовий Улюбленець",
        [2103008983] = "Газова Хмара",
        [2721766664] = "Дика Тварина",
        [3623635121] = "Аберація",
        [496532506] = "Труп",
    }

    ns._db.UnitTypes = data
end

do
    local data = {
        [133474279] = "Елітний",
        [3982664215] = "Рідкісний",
        [2482834624] = "Рідкісний Елітний",
        [595924386] = "Бос",
    }

    ns._db.UnitRanks = data
end

do
    local data = {
        [0] = "Arcane Charges",
        [0] = "Astral Power",
        [0] = "Chi",
        [0] = "Combo Points",
        [0] = "Energy",
        [0] = "Essence",
        [0] = "Focus",
        [0] = "Fury",
        [0] = "Holy Power",
        [0] = "Insanity",
        [0] = "Maelstrom",
        [0] = "Mana",
        [0] = "Pain",
        [0] = "Rage",
        [0] = "Runes",
        [0] = "Runic Power",
        [0] = "Soul Shards"
    }

    ns._db.SpellResourceTypes = data
end
