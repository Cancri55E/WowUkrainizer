local _, ns = ...;

local morpheusFont = "Interface\\AddOns\\WoWUkrainify\\assets\\Morpheus_UA.ttf"
local frixqtFont = "Interface\\AddOns\\WoWUkrainify\\assets\\FRIZQT_UA.ttf"

local EndsWith = ns.StringExtensions.EndsWith
local StartsWith = ns.StringExtensions.StartsWith

local talentRankPattern = "Rank (%d+)/(%d+)"
local talentReplacedByPattern = "Replaced by%s+(.+)"
local spellResourceMarkers = { "Rage", "Mana", "Energy", "Combo Points" }

local translator = {
    static = {
        isEnabled = false,
        isInitialized = false,
        enableDebugInfo = false
    }
}
ns.SpellTooltipTranslator = translator

local function print_table(tbl, prefix)
    prefix = prefix or ""
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print_table(value, prefix .. key .. ".")
        elseif type(value) == "function" and type(value) ~= 'userdata' then
            print(prefix .. key .. ": " .. tostring(value))
        end
    end
end

local function parseSpellTooltip(spellRow)
    local tooltipInfo = {
        Name = spellRow[1],
        Form = spellRow[2] or "",
    }

    local contentIndex = 3

    if (spellRow[3]) then
        local minRank, maxRank = spellRow[3]:match(talentRankPattern)
        if (minRank and maxRank) then
            local talent = { MinRank = tonumber(minRank), MaxRank = tonumber(maxRank), CurrentRank = {} }

            if (talent.MaxRank > 1 and talent.MinRank < talent.MaxRank) then
                talent.NextRankIndex = -1
                talent.NextRank = {}
            end

            if (spellRow[5]) then
                local replacedBy = spellRow[5]:match(talentReplacedByPattern)
                if (replacedBy) then
                    contentIndex = 5
                    talent.ReplacedBy = replacedBy
                end
            end

            tooltipInfo.Talent = talent

            contentIndex = contentIndex + 4
        else
            tooltipInfo.SpellInfo = {}
        end
    end

    local refObj = tooltipInfo.Talent and tooltipInfo.Talent.CurrentRank or tooltipInfo.SpellInfo

    for i = contentIndex, #spellRow do
        local element = spellRow[i]

        local isResourceType = false
        for _, keyword in ipairs(spellResourceMarkers) do
            if element:find(keyword) then
                refObj.ResourceType = { i, element }
                isResourceType = true
                break
            end
        end

        if not isResourceType then
            if (element == "Next Rank:") then
                tooltipInfo.Talent.NextRankIndex = i
                refObj = tooltipInfo.Talent.NextRank
            elseif element == "Melee Range" or EndsWith(element, "yd range") then
                refObj.Range = { i, element }
            elseif element == "Instant" or EndsWith(element, "sec cast") then
                refObj.CastTime = { i, element }
            elseif StartsWith(element, "Requires") then
                refObj.Requires = { i, element }
            elseif EndsWith(element, "cooldown") or EndsWith(element, "recharge") then
                refObj.Cooldown = { i, element }
            elseif element == "Passive" then
                refObj.Passive = i
            elseif i % 2 == 1 then
                if (not refObj.Description) then refObj.Description = {} end
                refObj.Description[#refObj.Description + 1] = { index = i, value = element }
            end
        end
    end

    return tooltipInfo
end

local function getLocalizedSpellTooltip(spellId, tooltipRows)
    local spellInfo = parseSpellTooltip(tooltipRows)

    --print_table(spellInfo)

    if (tonumber(spellId) == 370695) then
        spellInfo.Name = 'Лють природи'
        spellInfo.Talent.CurrentRank.Description[1].value =
        "Перебуваючи у формі ведмедя, ви наносите на 10% більше шкоди від таємних чарів."
        if (spellInfo.Talent.NextRankIndex ~= -1) then
            spellInfo.Talent.NextRank.Description[1].value =
            "Перебуваючи у формі ведмедя, ви наносите на 20% більше шкоди від таємних чарів."
        end
    end
    if (tonumber(spellId) == 400254) then
        spellInfo.Name = 'Рейз'
    end
    return spellInfo
end

local function setText(index, value)
    local row = math.ceil(index / 2)
    local tooltipTextKey = ''
    if (index % 2 == 0) then
        tooltipTextKey = 'GameTooltipTextRight'
    else
        tooltipTextKey = 'GameTooltipTextLeft'
    end
    local tooltipLines = _G[tooltipTextKey .. row]
    local r, g, b = tooltipLines:GetTextColor()
    tooltipLines:SetText(value)
    tooltipLines:SetTextColor(r, g, b)
end

local function spellTooltipCallback(tooltip, tooltipData)
    if (not translator.static.isEnabled) then return end

    local spellId = tonumber(tooltipData.id)

    local tooltipRows = {}
    for i = 1, tooltip:NumLines() do
        local lineLeft = _G["GameTooltipTextLeft" .. i]
        if (lineLeft) then
            tooltipRows[#tooltipRows + 1] = lineLeft:GetText() or ''
        end

        local lineRight = _G["GameTooltipTextRight" .. i]
        if (lineRight) then
            tooltipRows[#tooltipRows + 1] = lineRight:GetText() or ''
        end
    end

    local localizedSpellTooltipInfo = getLocalizedSpellTooltip(spellId, tooltipRows)

    if (localizedSpellTooltipInfo.Talent and localizedSpellTooltipInfo.Talent.NextRankIndex == -1) then return end

    if (localizedSpellTooltipInfo) then
        setText(1, localizedSpellTooltipInfo.Name)

        local talent = localizedSpellTooltipInfo.Talent
        if (talent) then
            setText(3, "Ранг " .. talent.MinRank .. "/" .. talent.MaxRank)

            local currentRank = localizedSpellTooltipInfo.Talent.CurrentRank
            if (currentRank) then
                setText(currentRank.Description[1].index, currentRank.Description[1].value)
                if (currentRank.Passive) then
                    setText(currentRank.Passive, "Пасивний")
                end
            end

            if (talent.NextRankIndex and talent.NextRankIndex ~= -1) then
                setText(talent.NextRankIndex, "Наступний ранг:")

                local nextRank = localizedSpellTooltipInfo.Talent.NextRank
                setText(nextRank.Description[1].index, nextRank.Description[1].value)
                if (nextRank.Passive) then
                    setText(nextRank.Passive, "Пасивний")
                end
            end
        end
    end
    --print_table(spellInfo)

    -- Form:
    -- Name: Fury of Nature
    -- Talent.NextRankIndex: 13
    -- Talent.NextRank.Description.1.index: 17
    -- Talent.NextRank.Description.1.value: While in Bear Form, you deal 20% increased Arcane damage.
    -- Talent.NextRank.Passive: 15
    -- Talent.CurrentRank.Description.1.index: 9
    -- Talent.CurrentRank.Description.1.value: While in Bear Form, you deal 10% increased Arcane damage.
    -- Talent.CurrentRank.Description.2.index: 11
    -- Talent.CurrentRank.Description.2.value:
    -- Talent.CurrentRank.Passive: 7
    -- Talent.MaxRank: 2
    -- Talent.MinRank: 1

    --print("End Spell")
end

local function initialize()
    if (translator.static.isInitialized) then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, spellTooltipCallback)
    translator.static.isInitialized = true
end

local function enable()
    if (translator.static.isEnabled) then return end
    initialize()
    translator.static.isEnabled = true
end

local function disable()
    if (not translator.static.isEnabled) then return end
    translator.static.isEnabled = false
end

function translator.SetEnabled(value)
    if (value) then
        enable()
    else
        disable()
    end
end

function translator.EnableDebugInfo(value)
    translator.static.enableDebugInfo = value
end
