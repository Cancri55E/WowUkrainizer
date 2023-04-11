local _, ns = ...;

local EndsWith = ns.StringExtensions.EndsWith
local StartsWith = ns.StringExtensions.StartsWith
local Split = ns.StringExtensions.Split

local SPELL_PASSIVE_TRANSLATION = ns.SPELL_PASSIVE_TRANSLATION
local SPELL_RANK_TRANSLATION = ns.SPELL_RANK_TRANSLATION
local SPELL_NEXT_RANK_TRANSLATION = ns.SPELL_NEXT_RANK_TRANSLATION

local GetSpellNameOrDefault = ns.DbContext.Spells.GetSpellNameOrDefault
local GetSpellDescriptionOrDefault = ns.DbContext.Spells.GetSpellDescriptionOrDefault
local GetSpellAttributeOrDefault = ns.DbContext.Spells.GetSpellAttributeOrDefault

local talentRankPattern = "Rank (%d+)/(%d+)"
local talentReplacedByPattern = "Replaced by%s+(.+)"

local spellResources = { "Arcane Charges",
    "Astral Power",
    "Chi",
    "Combo Points",
    "Energy",
    "Essence",
    "Focus",
    "Fury",
    "Holy Power",
    "Insanity",
    "Maelstrom",
    "Mana",
    "Pain",
    "Rage",
    "Runes",
    "Health",
    "Runic Power",
    "Soul Shards"
}

local translator = {
    static = {
        isEnabled = false,
        isInitialized = false,
        debugEnabled = false
    }
}
ns.SpellTooltipTranslator = translator

local function tryGetResourceType(tooltipText)
    local resourcePatterns = {}
    for _, resource in ipairs(spellResources) do
        table.insert(resourcePatterns, "(%d[%d,]*%.?%d*) " .. resource)
    end

    local resources = {}
    local foundResource = false

    for _, inputPart in ipairs(Split(tooltipText, '\n')) do
        foundResource = false
        for _, pattern in ipairs(resourcePatterns) do
            for _ in inputPart:gmatch(pattern) do
                foundResource = true
                table.insert(resources, inputPart)
            end
        end
        if (not foundResource) then break end
    end
    return foundResource and resources or nil
end

local function parseSpellTooltip(tooltipTextArray)
    local spellTooltip = {
        Name = tooltipTextArray[1],
        Form = tooltipTextArray[2] or "",
    }

    local contentIndex = 3

    if (tooltipTextArray[3]) then
        local minRank, maxRank = tooltipTextArray[3]:match(talentRankPattern)
        if (minRank and maxRank) then
            local talent = { MinRank = tonumber(minRank), MaxRank = tonumber(maxRank), CurrentRank = {} }

            if (talent.MaxRank > 1 and talent.MinRank < talent.MaxRank) then
                talent.NextRankIndex = -1
                talent.NextRank = {}
            end

            if (tooltipTextArray[5]) then
                local replacedBy = tooltipTextArray[5]:match(talentReplacedByPattern)
                if (replacedBy) then
                    contentIndex = 5
                    talent.ReplacedBy = replacedBy
                end
            end

            spellTooltip.Talent = talent

            contentIndex = contentIndex + 4
        else
            spellTooltip.Spell = {}
        end
    end

    local spellContainer = spellTooltip.Talent and spellTooltip.Talent.CurrentRank or spellTooltip.Spell

    for i = contentIndex, #tooltipTextArray do
        local element = tooltipTextArray[i]
        if (element ~= nil or element ~= "") then
            local resourceTypes = tryGetResourceType(element)
            if (resourceTypes) then
                spellContainer.ResourceType = { i }
                for x, resourceType in ipairs(resourceTypes) do
                    table.insert(spellContainer.ResourceType, x + 1, resourceType)
                end
            end

            if not resourceTypes then
                if (element == "Next Rank:") then
                    spellTooltip.Talent.NextRankIndex = i
                    spellContainer = spellTooltip.Talent.NextRank
                elseif element == "Melee Range" or EndsWith(element, "yd range") then
                    spellContainer.Range = { i, element }
                elseif element == "Instant" or EndsWith(element, "sec cast") or StartsWith(element, "Channeled") then
                    spellContainer.CastTime = { i, element }
                elseif StartsWith(element, "Requires") then
                    spellContainer.Requires = { i, element }
                elseif EndsWith(element, "cooldown") or EndsWith(element, "recharge") then
                    spellContainer.Cooldown = { i, element }
                elseif element == "Passive" then
                    spellContainer.Passive = i
                elseif i % 2 == 1 then
                    if (not spellContainer.Descriptions) then spellContainer.Descriptions = {} end
                    spellContainer.Descriptions[#spellContainer.Descriptions + 1] = { index = i, value = element }
                end
            end
        end
    end

    return spellTooltip
end

local function fillTranslationFor(spellContainer)
    if (not spellContainer) then return end

    if (spellContainer.ResourceType) then
        for i = 2, #spellContainer.ResourceType do
            spellContainer.ResourceType[i] = GetSpellAttributeOrDefault(spellContainer.ResourceType[i])
        end
    end

    if (spellContainer.Range) then
        spellContainer.Range[2] = GetSpellAttributeOrDefault(spellContainer.Range[2])
    end

    if (spellContainer.Requires) then
        spellContainer.Requires[2] = GetSpellAttributeOrDefault(spellContainer.Requires[2])
    end

    if (spellContainer.CastTime) then
        spellContainer.CastTime[2] = GetSpellAttributeOrDefault(spellContainer.CastTime[2])
    end
    if (spellContainer.Cooldown) then
        spellContainer.Cooldown[2] = GetSpellAttributeOrDefault(spellContainer.Cooldown[2])
    end

    if (spellContainer.ReplacedBy) then
        spellContainer.ReplacedBy = GetSpellAttributeOrDefault(spellContainer.ReplacedBy)
    end

    if (spellContainer.Descriptions) then
        for _, description in ipairs(spellContainer.Descriptions) do
            description.value = GetSpellDescriptionOrDefault(description.value)
        end
    end
end

local function getTranslatedSpellTooltip(spellId, tooltipTextArray)
    local spellTooltip = parseSpellTooltip(tooltipTextArray)

    if (translator.static.debugEnabled) then
        if (not _G.WoWUkrainify_UntranslatedData.SpellDebugInfo) then
            _G.WoWUkrainify_UntranslatedData.SpellDebugInfo = {}
        end
        _G.WoWUkrainify_UntranslatedData.SpellDebugInfo[tonumber(spellId)] = spellTooltip
    end

    spellTooltip.Name = GetSpellNameOrDefault(spellTooltip.Name)
    spellTooltip.Form = GetSpellAttributeOrDefault(spellTooltip.Form)

    if (spellTooltip.Spell) then
        fillTranslationFor(spellTooltip.Spell)
    elseif (spellTooltip.Talent) then
        fillTranslationFor(spellTooltip.Talent.CurrentRank)
        if (spellTooltip.Talent.NextRankIndex ~= -1) then
            fillTranslationFor(spellTooltip.Talent.NextRank)
        end
    end

    return spellTooltip
end

local function setGameTooltipText(index, value)
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

local function setGameTooltipTextFrom(spellContainer)
    if (not spellContainer) then return end

    if (spellContainer.ResourceType) then
        setGameTooltipText(spellContainer.ResourceType[1], table.concat(spellContainer.ResourceType, "\n", 2))
    end
    if (spellContainer.Range) then
        setGameTooltipText(spellContainer.Range[1], spellContainer.Range[2])
    end

    if (spellContainer.CastTime) then
        setGameTooltipText(spellContainer.CastTime[1], spellContainer.CastTime[2])
    end
    if (spellContainer.Cooldown) then
        setGameTooltipText(spellContainer.Cooldown[1], spellContainer.Cooldown[2])
    end
    if (spellContainer.Passive) then
        setGameTooltipText(spellContainer.Passive, SPELL_PASSIVE_TRANSLATION)
    end

    if (spellContainer.ReplacedBy) then
        setGameTooltipText(5, spellContainer.ReplacedBy)
    end

    if (spellContainer.Requires) then
        setGameTooltipText(spellContainer.Requires[1], spellContainer.Requires[2])
    end

    if (spellContainer.Descriptions) then
        for _, description in ipairs(spellContainer.Descriptions) do
            if (description.value ~= "") then
                setGameTooltipText(description.index, description.value)
            end
        end
    end
end

local function tooltipCallback(tooltip, tooltipData)
    if (not translator.static.isEnabled) then return end

    local spellId = tonumber(tooltipData.id)

    local tooltipTextArray = {}
    for i = 1, tooltip:NumLines() do
        local lineLeft = _G["GameTooltipTextLeft" .. i]
        if (lineLeft) then
            tooltipTextArray[#tooltipTextArray + 1] = lineLeft:GetText() or ''
        end

        local lineRight = _G["GameTooltipTextRight" .. i]
        if (lineRight) then
            tooltipTextArray[#tooltipTextArray + 1] = lineRight:GetText() or ''
        end
    end

    local translatedTooltip = getTranslatedSpellTooltip(spellId, tooltipTextArray)

    if (translatedTooltip and translatedTooltip.Talent and translatedTooltip.Talent.NextRankIndex == -1) then return end -- Hook

    setGameTooltipText(1, translatedTooltip.Name)
    if (translatedTooltip.Form and translatedTooltip.Form ~= "") then
        setGameTooltipText(2, translatedTooltip.Form)
    end

    local talent = translatedTooltip.Talent
    if (talent) then
        setGameTooltipText(3, SPELL_RANK_TRANSLATION .. " " .. talent.MinRank .. "/" .. talent.MaxRank)
        setGameTooltipTextFrom(talent.CurrentRank)

        if (talent.NextRankIndex) then
            setGameTooltipText(talent.NextRankIndex, SPELL_NEXT_RANK_TRANSLATION)
            setGameTooltipTextFrom(talent.NextRank)
        end
    else
        setGameTooltipTextFrom(translatedTooltip.Spell)
    end
end

local function initialize()
    if (translator.static.isInitialized) then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, tooltipCallback)
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
    translator.static.debugEnabled = value
end
