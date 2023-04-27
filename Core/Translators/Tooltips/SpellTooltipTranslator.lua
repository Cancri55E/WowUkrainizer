local _, ns = ...;

local EndsWith = ns.StringExtensions.EndsWith
local StartsWith = ns.StringExtensions.StartsWith

local SPELL_PASSIVE_TRANSLATION = ns.SPELL_PASSIVE_TRANSLATION
local TALENT_UPGRADE_TRANSLATION = ns.TALENT_UPGRADE_TRANSLATION
local SPELL_RANK_TRANSLATION = ns.SPELL_RANK_TRANSLATION
local SPELL_NEXT_RANK_TRANSLATION = ns.SPELL_NEXT_RANK_TRANSLATION
local TALENT_REPLACES_TRANSLATION = ns.TALENT_REPLACES_TRANSLATION

local GetSpellNameOrDefault = ns.DbContext.Spells.GetSpellNameOrDefault
local GetSpellDescriptionOrDefault = ns.DbContext.Spells.GetSpellDescriptionOrDefault
local GetSpellAttributeOrDefault = ns.DbContext.Spells.GetSpellAttributeOrDefault

local talentRankPattern = "Rank (%d+)/(%d+)"
local talentReplacedByPattern = "Replaced by%s+(.+)"
local maxChargesPattern = "Max %d+ Charges"

local translator = class("SpellTooltipTranslator", ns.Translators.BaseTooltipTranslator)
ns.Translators.SpellTooltipTranslator = translator

local function processResourceStrings(str)
    local function isResourceString(value)
        local spellResources = {
            "Arcane Charges",
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
            "Rune",
            "Runes",
            "Health",
            "Runic Power",
            "Soul Shards",
            "Soul Shard"
        }

        for _, resource in ipairs(spellResources) do
            if value:match("^%d+[.,]?%d* to %d+[.,]?%d* " .. resource .. "$")
                or value:match("^%d+[.,]?%d* " .. resource .. "$")
                or value:match("^%d+[.,]?%d* " .. resource .. ", plus %d+[.,]?%d* per sec$")
                or value:match("^%d+[.,]?%d* " .. resource .. " per sec$") then
                return true
            end
        end

        return false
    end

    local function splitResourceString(value)
        local resourceStrings = {}
        for resourceString in value:gmatch("([^\n]+)") do
            table.insert(resourceStrings, resourceString)
        end
        return resourceStrings
    end

    local resultTable = {}
    local resourceStrings = splitResourceString(str)

    for _, resourceString in ipairs(resourceStrings) do
        if isResourceString(resourceString) then
            local isInTable = false
            for _, element in ipairs(resultTable) do
                if element == resourceString then
                    isInTable = true
                    break
                end
            end
            if not isInTable then
                table.insert(resultTable, resourceString)
            end
        end
    end

    return next(resultTable) ~= nil and resultTable or nil
end

local function isEvokerSpellColor(str)
    return str == "Red" or str == "Green" or str == "Blue" or str == "Black" or str == "Bronze"
end

local function parseSpellTooltip(tooltipTexts)
    local spellTooltip = {
        Name = tooltipTexts[1],
        Form = tooltipTexts[2] or "",
    }

    local contentIndex = 3

    if (tooltipTexts[3]) then
        local minRank, maxRank = tooltipTexts[3]:match(talentRankPattern)
        if (minRank and maxRank) then
            local talent = { MinRank = tonumber(minRank), MaxRank = tonumber(maxRank), CurrentRank = {} }

            if (talent.MaxRank > 1 and talent.MinRank < talent.MaxRank) then
                talent.NextRankIndex = -1
                talent.NextRank = {}
            end

            if (tooltipTexts[5]) then
                local replacedBy = tooltipTexts[5]:match(talentReplacedByPattern)
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

    local spellContainer =
        (spellTooltip.Talent and spellTooltip.Talent.CurrentRank) and spellTooltip.Talent.CurrentRank
        or spellTooltip.Spell
        or nil

    if (spellContainer) then
        for i = contentIndex, #tooltipTexts do
            local element = tooltipTexts[i]
            if (element ~= nil or element ~= "") then
                local resourceTypes = processResourceStrings(element)
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
                    elseif element == "Left click to select this talent." or StartsWith(element, "Unlocked at level ") then -- "Left click to select this talent." and "Unlocked at level " used as part of description in PvP talent
                        spellContainer.PvP = i
                    elseif (isEvokerSpellColor(element)) then
                        spellContainer.EvokerSpellColor = { i, element }
                    elseif (string.match(element, maxChargesPattern)) then
                        spellContainer.MaxCharges = { i, element }
                    elseif element == "Melee Range" or element == "Unlimited range" or EndsWith(element, "yd range") then
                        spellContainer.Range = { i, element }
                    elseif element == "Instant" or element == "Channeled" or EndsWith(element, "sec cast") or EndsWith(element, "sec empower") then
                        spellContainer.CastTime = { i, element }
                    elseif StartsWith(element, "Requires") then
                        spellContainer.Requires = { i, element }
                    elseif StartsWith(element, "Replaces") then
                        spellContainer.Replaces = { i, element }
                    elseif EndsWith(element, "cooldown") or EndsWith(element, "recharge") or StartsWith(element, "Recharging: ") then
                        spellContainer.Cooldown = { i, element }
                    elseif element == "Passive" then
                        spellContainer.Passive = i
                    elseif element == "Upgrade" then
                        spellContainer.Upgrade = i
                    elseif i % 2 == 1 then
                        if not spellContainer.Descriptions then spellContainer.Descriptions = {} end
                        table.insert(spellContainer.Descriptions, { index = i, value = element })
                    end
                end
            end
        end

        if (not spellContainer.Descriptions) then
            return -- HOOK: Description for PvP talent is empty. In this case client send another callback. Need to find why.
        end
    end

    return spellTooltip
end

local function translateTooltipSpellInfo(spellContainer)
    local function extractReplaceSpellName(str)
        local spellName = str:match("Replaces%s+(.+)")
        if spellName ~= nil then
            spellName = spellName:trim()
        end
        return spellName
    end

    if (not spellContainer) then return end

    local translatedTooltipLines = {}

    if (spellContainer.ReplacedBy) then
        table.insert(translatedTooltipLines, {
            index = 5,
            value = GetSpellAttributeOrDefault(spellContainer.ReplacedBy)
        })
    end

    if (spellContainer.ResourceType) then
        for i = 2, #spellContainer.ResourceType do
            spellContainer.ResourceType[i] = GetSpellAttributeOrDefault(spellContainer.ResourceType[i])
        end
        table.insert(translatedTooltipLines, {
            index = spellContainer.ResourceType[1],
            value = table.concat(spellContainer.ResourceType, "\n", 2)
        })
    end

    if (spellContainer.Range) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.Range[1],
            value = GetSpellAttributeOrDefault(spellContainer.Range[2])
        })
    end

    if (spellContainer.Requires) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.Requires[1],
            value = GetSpellAttributeOrDefault(spellContainer.Requires[2])
        })
    end

    if (spellContainer.Replaces) then
        local replaceSpellName = GetSpellNameOrDefault(extractReplaceSpellName(spellContainer.Replaces[2]), false)
        table.insert(translatedTooltipLines, {
            index = spellContainer.Replaces[1],
            value = TALENT_REPLACES_TRANSLATION .. " " .. replaceSpellName
        })
    end

    if (spellContainer.CastTime) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.CastTime[1],
            value = GetSpellAttributeOrDefault(spellContainer.CastTime[2])
        })
    end

    if (spellContainer.Cooldown) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.Cooldown[1],
            value = GetSpellAttributeOrDefault(spellContainer.Cooldown[2])
        })
    end

    if (spellContainer.MaxCharges) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.MaxCharges[1],
            value = GetSpellAttributeOrDefault(spellContainer.MaxCharges[2])
        })
    end

    if (spellContainer.EvokerSpellColor) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.EvokerSpellColor[1],
            value = GetSpellAttributeOrDefault(spellContainer.EvokerSpellColor[2])
        })
    end

    if (spellContainer.Passive) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.Passive,
            value = SPELL_PASSIVE_TRANSLATION
        })
    end

    if (spellContainer.Upgrade) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.Upgrade,
            value = TALENT_UPGRADE_TRANSLATION
        })
    end

    if (spellContainer.Descriptions) then
        for _, description in ipairs(spellContainer.Descriptions) do
            table.insert(translatedTooltipLines, {
                index = description.index,
                value = GetSpellDescriptionOrDefault(description.value)
            })
        end
    end

    return translatedTooltipLines
end

function translator:ParseTooltip(tooltip, tooltipData)
    local tooltipTexts = {}
    for i = 1, tooltip:NumLines() do
        local lineLeft = _G["GameTooltipTextLeft" .. i]
        if (lineLeft) then
            local lli = #tooltipTexts + 1;
            tooltipTexts[lli] = lineLeft:GetText() or ''
            self:_addFontStringToIndexLookup(lli, lineLeft)
        end

        local lineRight = _G["GameTooltipTextRight" .. i]
        if (lineRight) then
            local lri = #tooltipTexts + 1;
            tooltipTexts[lri] = lineRight:GetText() or ''
            self:_addFontStringToIndexLookup(lri, lineRight)
        end
    end

    local tooltipInfo = parseSpellTooltip(tooltipTexts)

    if (not tooltipInfo) then return end

    if (tooltipInfo and tooltipInfo.Talent and (tooltipInfo.Talent.MinRank ~= 0 and tooltipInfo.Talent.NextRankIndex == -1)) then return end -- HOOK: No Rank 1/2+ info in multirang talent tooltip. In this case client send another callback. Need to find why

    return tooltipInfo
end

function translator:TranslateTooltipInfo(tooltipInfo)
    local function addRange(t1, t2)
        if (not t2) then return end
        for _, value in ipairs(t2) do
            table.insert(t1, value)
        end
    end

    local translatedTooltipLines = {}

    table.insert(translatedTooltipLines, {
        index = 1,
        value = GetSpellNameOrDefault(tooltipInfo.Name, true)
    })

    if (tooltipInfo.Form and tooltipInfo.Form ~= "") then
        table.insert(translatedTooltipLines, {
            index = 2,
            value = GetSpellAttributeOrDefault(tooltipInfo.Form)
        })
    end

    if (tooltipInfo.Spell) then
        addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Spell))
    elseif (tooltipInfo.Talent) then
        table.insert(translatedTooltipLines, {
            index = 3,
            value = SPELL_RANK_TRANSLATION .. " " .. tooltipInfo.Talent.MinRank .. "/" .. tooltipInfo.Talent.MaxRank
        })
        addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Talent.CurrentRank))

        if (tooltipInfo.Talent.NextRankIndex ~= -1) then
            table.insert(translatedTooltipLines, {
                index = tooltipInfo.Talent.NextRankIndex,
                value = SPELL_NEXT_RANK_TRANSLATION
            })
            addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Talent.NextRank))
        end
    end

    return translatedTooltipLines
end
