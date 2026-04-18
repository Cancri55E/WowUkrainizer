--- @type string, WowUkrainizerInternals
local _, ns = ...;

local EndsWith = ns.StringUtil.EndsWith
local StartsWith = ns.StringUtil.StartsWith
local StringsAreEqual = ns.StringUtil.StringsAreEqual
local NormalizeStringAndExtractNumerics = ns.StringNormalizer.NormalizeStringAndExtractNumerics


local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedSpellDescription = ns.DbContext.Spells.GetTranslatedSpellDescription
local GetTranslatedSpellAttribute = ns.DbContext.Spells.GetTranslatedSpellAttribute
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

local ptrHelpText = "|c0042b1fePress F6 to submit an issue for this Spell"

--- Convert a WoW format string to an anchored Lua match pattern.
--- %s placeholders become captures: lazy (.-) for all but the last, greedy (.+) for the last.
--- %d placeholders become (%d+) captures (integer numbers).
--- Literal characters that are Lua pattern specials are escaped.
local function buildMatchPattern(fmt)
    local parts = {}
    local pos = 1
    local totalS = select(2, fmt:gsub("%%s", ""))
    local seenS = 0
    while pos <= #fmt do
        local sS, eS = fmt:find("%%s", pos)
        local sD, eD = fmt:find("%%d", pos)

        -- Pick the nearest placeholder
        local placeholderStart, placeholderEnd, isString
        if sS and (not sD or sS <= sD) then
            placeholderStart, placeholderEnd, isString = sS, eS, true
        elseif sD then
            placeholderStart, placeholderEnd, isString = sD, eD, false
        end

        if not placeholderStart then
            table.insert(parts, (fmt:sub(pos):gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")))
            break
        end
        if placeholderStart > pos then
            table.insert(parts, (fmt:sub(pos, placeholderStart - 1):gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")))
        end
        if isString then
            seenS = seenS + 1
            table.insert(parts, seenS < totalS and "(.-)" or "(.+)")
        else
            table.insert(parts, "(%d+)")
        end
        pos = placeholderEnd + 1
    end
    return "^" .. table.concat(parts) .. "$"
end

-- Patterns derived from Blizzard format constants via buildMatchPattern.
local talentRankWithMaxPattern = buildMatchPattern(TALENT_BUTTON_TOOLTIP_RANK_FORMAT)
local talentRankNoMaxPattern = buildMatchPattern(TALENT_BUTTON_TOOLTIP_RANK_NO_MAX_FORMAT)
local talentReplacedByPattern = buildMatchPattern(TALENT_BUTTON_TOOLTIP_REPLACED_BY_FORMAT)
local talentReplacesPattern = buildMatchPattern(REPLACES_SPELL)
local maxChargesPattern = buildMatchPattern(SPELL_MAX_CHARGES)
local capstoneTitlePattern = buildMatchPattern(TALENT_BUTTON_TOOLTIP_CAPSTONE_TRACK_TITLE_FORMAT)
local capstoneTierHeaderPattern = buildMatchPattern(TOOLTIP_TALENT_RANK_CAPSTONE)
local capstoneNextPreviewText = TALENT_BUTTON_TOOLTIP_CAPSTONE_RANK_NEXT_STAGE_PREVIEW_TITLE

-- ---------------------------------------------------------------------------
-- Fragment classification
-- ---------------------------------------------------------------------------

local function isEvokerSpellColor(str)
    return str == "Red" or str == "Green" or str == "Blue" or str == "Black" or str == "Bronze"
end

local function isAdditionalSpellTips(str)
    return str == "Left click to select this talent."
        or StartsWith(str, "Unlocked at level ")
        or str == "Click to learn"
        or str == "Talents cannot be changed in combat."
end

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

--- Classify a single fragment text into a category.
--- When lineType is available (spell-like tooltips from tooltipData), it is
--- checked first for an instant match before falling through to text patterns.
---@param text string
---@param isRight boolean
---@param lineType number|nil Enum.TooltipDataLineType value from tooltipData
---@return string|nil category
---@return table|nil extra
local function classifyFragment(text, isRight, lineType)
    if text == ptrHelpText then return "Ignorable" end

    -- Fast path: use structured line type when available
    if lineType then
        if lineType == Enum.TooltipDataLineType.SpellDescription then return "Description" end
        if lineType == Enum.TooltipDataLineType.SpellPassive then return "Passive" end
    end

    local resourceTypes = processResourceStrings(text)
    if resourceTypes then return "ResourceType", { values = resourceTypes } end

    local replacedBy = text:match(talentReplacedByPattern)
    if replacedBy then return "ReplacedBy", { name = replacedBy:trim() } end

    local replaces = text:match(talentReplacesPattern)
    if replaces then return "Replaces", { name = replaces:trim() } end

    if text == "Passive" then return "Passive" end
    if text == "Upgrade" then return "Upgrade" end

    if text == "Melee Range" or text == "Unlimited range" or EndsWith(text, "yd range") then
        return "Range"
    end

    if text == "Instant" or text == "Channeled"
        or EndsWith(text, "sec cast") or EndsWith(text, "sec empower") then
        return "CastTime"
    end

    if StartsWith(text, "Requires") then return "Requires" end

    if EndsWith(text, "cooldown") or EndsWith(text, "recharge")
        or StartsWith(text, "Recharging: ") then
        return "Cooldown"
    end

    if StartsWith(text, "Cooldown remaining:") then return "CooldownRemaining" end
    if string.match(text, maxChargesPattern) then return "MaxCharges" end
    if isEvokerSpellColor(text) then return "EvokerSpellColor" end
    if isAdditionalSpellTips(text) then return "AdditionalSpellTip" end

    if not isRight then return "Description" end

    return nil
end

-- ---------------------------------------------------------------------------
-- SpellBlock builder — the reusable atomic unit
-- ---------------------------------------------------------------------------

--- Build a SpellBlock from a contiguous range of classified fragments.
---@param fragments table Array of { value, line, right }
---@param startIdx number First fragment index to consume (inclusive)
---@param stopFn fun(frag: table, idx: number): boolean|nil Predicate; true to stop BEFORE this fragment
---@return table spellBlock
---@return number nextIdx First unconsumed fragment index
local function buildSpellBlock(fragments, startIdx, stopFn)
    local block = {}
    local i = startIdx
    while i <= #fragments do
        local frag = fragments[i]
        if stopFn and stopFn(frag, i) then break end

        local text = frag.value
        if text ~= nil and text ~= "" then
            local cat, extra = classifyFragment(text, frag.right, frag.type)
            if cat == "ResourceType" then
                block.ResourceType = { line = frag.line, right = frag.right, values = extra.values }
            elseif cat == "ReplacedBy" then
                block.ReplacedBy = { value = extra.name, line = frag.line, right = frag.right }
            elseif cat == "Replaces" then
                block.Replaces = { value = extra.name, line = frag.line, right = frag.right }
            elseif cat == "Range" then
                block.Range = { value = text, line = frag.line, right = frag.right }
            elseif cat == "CastTime" then
                block.CastTime = { value = text, line = frag.line, right = frag.right }
            elseif cat == "Cooldown" then
                block.Cooldown = { value = text, line = frag.line, right = frag.right }
            elseif cat == "CooldownRemaining" then
                block.CooldownRemaining = { value = text, line = frag.line, right = frag.right }
            elseif cat == "MaxCharges" then
                block.MaxCharges = { value = text, line = frag.line, right = frag.right }
            elseif cat == "EvokerSpellColor" then
                block.EvokerSpellColor = { value = text, line = frag.line, right = frag.right }
            elseif cat == "Passive" then
                block.Passive = { line = frag.line, right = frag.right }
            elseif cat == "Upgrade" then
                block.Upgrade = { line = frag.line, right = frag.right }
            elseif cat == "Requires" then
                block.Requires = { value = text, line = frag.line, right = frag.right }
            elseif cat == "AdditionalSpellTip" then
                if not block.AdditionalSpellTips then block.AdditionalSpellTips = {} end
                table.insert(block.AdditionalSpellTips, { value = text, line = frag.line, right = frag.right })
            elseif cat == "Description" then
                if not block.Descriptions then block.Descriptions = {} end
                table.insert(block.Descriptions, { value = text, line = frag.line, right = frag.right })
            end
            -- "Ignorable" and nil are silently skipped
        end
        i = i + 1
    end
    return block, i
end

-- ---------------------------------------------------------------------------
-- Input adapters (unchanged from before)
-- ---------------------------------------------------------------------------

--- Build an ordered fragment array for a spell-like tooltip from tooltipData.lines.
---@param tooltipData table
---@return table|nil fragments Array of { value, line, right } entries
local function buildSpellLikeInput(tooltipData)
    if not tooltipData or not tooltipData.lines or #tooltipData.lines == 0 then
        return nil
    end

    local fragments = {}
    local tooltipLineNum = 0

    for _, line in ipairs(tooltipData.lines) do
        local leftText = line.leftText
        local rightText = line.rightText

        local leftIsSecret  = leftText  ~= nil and issecretvalue(leftText)
        local rightIsSecret = rightText ~= nil and issecretvalue(rightText)

        local leftVal  = leftIsSecret  and "" or (leftText  or "")
        local rightVal = rightIsSecret and "" or (rightText or "")

        local isRendered = leftVal ~= "" or rightVal ~= "" or leftIsSecret or rightIsSecret
        if isRendered then
            tooltipLineNum = tooltipLineNum + 1
        end

        if not leftIsSecret and leftVal ~= "" then
            table.insert(fragments, { value = leftVal, line = tooltipLineNum, right = false, type = line.type })
        end

        if not rightIsSecret and rightVal ~= "" then
            table.insert(fragments, { value = rightVal, line = tooltipLineNum, right = true, type = line.type })
        end
    end

    return #fragments > 0 and fragments or nil
end

--- Build an ordered fragment array for a talent tooltip from visible FontStrings.
---@param tooltip GameTooltip
---@param TLA TooltipLineAccessor
---@return table|nil fragments Array of { value, line, right } entries
local function buildTalentInput(tooltip, TLA)
    if tooltip:NumLines() == 0 then return nil end

    local fragments = {}

    for i = 1, tooltip:NumLines() do
        local leftText, leftIsSecret = TLA.GetLeftText(tooltip, i)
        if leftText and leftText ~= "" and not leftIsSecret then
            table.insert(fragments, { value = leftText, line = i, right = false })
        end

        local rightText, rightIsSecret = TLA.GetRightText(tooltip, i)
        if rightText and rightText ~= "" and not rightIsSecret then
            table.insert(fragments, { value = rightText, line = i, right = true })
        end
    end

    return #fragments > 0 and fragments or nil
end

-- ---------------------------------------------------------------------------
-- Family detection
-- ---------------------------------------------------------------------------

--- Detect the tooltip family based on the tooltip owner.
---@param tooltipOwner table|nil
---@return "spell-like"|"talent-spend"|"talent-capstone"
local function detectTooltipFamily(tooltipOwner)
    if not tooltipOwner or not tooltipOwner.definitionID then
        return "spell-like"
    end
    local nodeInfo = tooltipOwner.nodeInfo
    if nodeInfo
        and nodeInfo.type == Enum.TraitNodeType.Tiered
        and FlagsUtil.IsSet(nodeInfo.flags, Enum.TraitNodeFlag.ShowTierTrack)
        and nodeInfo.entryIDs and #nodeInfo.entryIDs > 1
    then
        return "talent-capstone"
    end
    return "talent-spend"
end

--- Check if a fragment is a capstone tier header ("Rank N").
local function isCapstoneTierHeader(text)
    return text:match(capstoneTierHeaderPattern) ~= nil
end

--- Validate that a talent tooltip layout is complete enough to translate.
---@param tooltipOwner table|nil
---@param fragments table
---@param family "talent-spend"|"talent-capstone"
---@return boolean complete
local function isTalentLayoutComplete(tooltipOwner, fragments, family)
    if not tooltipOwner or not tooltipOwner.nodeInfo then return true end

    local currentRank = tooltipOwner.nodeInfo.currentRank
    local maxRanks = tooltipOwner.nodeInfo.maxRanks

    if currentRank == 0 then return true end

    if family == "talent-capstone" then
        for _, frag in ipairs(fragments) do
            if isCapstoneTierHeader(frag.value) then return true end
        end
        return false
    end

    -- Spend completeness check
    local containsNextRank = false
    for _, frag in ipairs(fragments) do
        if frag.value == TALENT_BUTTON_TOOLTIP_NEXT_RANK then
            containsNextRank = true
            break
        end
    end
    if containsNextRank then return true end

    if currentRank < maxRanks then return false end
    if currentRank == maxRanks and tooltipOwner:IsRefundInvalid() then return false end

    return true
end

-- ---------------------------------------------------------------------------
-- Shared header extraction
-- ---------------------------------------------------------------------------

--- Extract Name and optional Form from the beginning of a fragment array.
---@param fragments table
---@return table header { Name, Form? }
---@return number contentStart Index of first content fragment
local function extractHeader(fragments)
    local nameFragment = fragments[1]
    local header = {
        Name = { value = nameFragment.value, line = nameFragment.line, right = nameFragment.right },
    }

    local contentStart = 2
    if fragments[2] and fragments[2].line == nameFragment.line and fragments[2].right then
        local f = fragments[2]
        header.Form = { value = f.value, line = f.line, right = f.right }
        contentStart = 3
    end

    return header, contentStart
end

-- ---------------------------------------------------------------------------
-- Family-specific parsers
-- ---------------------------------------------------------------------------

---@param fragments table
---@return table|nil tooltipInfo
local function parseSpellLikeTooltip(fragments)
    if not fragments or #fragments == 0 then return nil end

    local header, contentStart = extractHeader(fragments)
    local block = buildSpellBlock(fragments, contentStart, nil)
    if not block.Descriptions then return nil end -- Empty-description guard

    local tooltipInfo = {
        Name = header.Name,
        Form = header.Form,
        Spell = block,
    }
    return tooltipInfo
end

---@param fragments table
---@return table|nil tooltipInfo
local function parseTalentSpendTooltip(fragments)
    if not fragments or #fragments == 0 then return nil end

    local header, contentStart = extractHeader(fragments)
    local tooltipInfo = { Name = header.Name, Form = header.Form }

    -- Try to match a rank line at contentStart
    local talent = nil
    local rankFrag = fragments[contentStart]
    if rankFrag then
        local minRank, maxRank = rankFrag.value:match(talentRankWithMaxPattern)
        if minRank then
            talent = {
                Rank = { value = rankFrag.value, line = rankFrag.line, right = rankFrag.right },
                MinRank = minRank, MaxRank = maxRank,
                CurrentRank = {}, NextRankHeader = nil, NextRank = {},
            }
            contentStart = contentStart + 1
        elseif talentRankNoMaxPattern then
            local rank = rankFrag.value:match(talentRankNoMaxPattern)
            if rank then
                talent = {
                    Rank = { value = rankFrag.value, line = rankFrag.line, right = rankFrag.right },
                    MinRank = rank, MaxRank = nil,
                    CurrentRank = {}, NextRankHeader = nil, NextRank = {},
                }
                contentStart = contentStart + 1
            end
        end
    end

    if not talent then
        -- Talent without a recognized rank line — fall back to spell-like shape
        local block = buildSpellBlock(fragments, contentStart, nil)
        if not block.Descriptions then return nil end
        tooltipInfo.Spell = block
        return tooltipInfo
    end

    -- Parse current rank block, stopping at "Next Rank:" marker
    local nextRankText = TALENT_BUTTON_TOOLTIP_NEXT_RANK
    talent.CurrentRank = buildSpellBlock(fragments, contentStart, function(frag)
        return frag.value == nextRankText
    end)

    -- Look for the "Next Rank:" header and parse the next rank block
    for idx = contentStart, #fragments do
        if fragments[idx].value == nextRankText then
            talent.NextRankHeader = {
                value = fragments[idx].value,
                line = fragments[idx].line,
                right = fragments[idx].right,
            }
            talent.NextRank = buildSpellBlock(fragments, idx + 1, nil)
            break
        end
    end

    if not talent.CurrentRank.Descriptions then return nil end
    tooltipInfo.Talent = talent
    return tooltipInfo
end

---@param fragments table
---@return table|nil tooltipInfo
local function parseTalentCapstoneTooltip(fragments)
    if not fragments or #fragments == 0 then return nil end

    -- Title: "SpellName (X/Y)" or just "SpellName" when totalMaxRanks == 0
    local nameFragment = fragments[1]
    local rawTitle = nameFragment.value
    local spellName, currentRank, totalMaxRanks = rawTitle:match(capstoneTitlePattern)
    if not spellName then
        spellName = rawTitle
    end

    local tooltipInfo = {
        Name = { value = spellName, line = nameFragment.line, right = nameFragment.right },
        Capstone = {
            RawTitle = rawTitle,
            TitleLine = nameFragment.line,
            CurrentRank = currentRank,
            TotalMaxRanks = totalMaxRanks,
            Tiers = {},
            Passive = nil,
        },
    }

    -- Check for "Passive" right after title (before first tier header)
    local contentStart = 2
    if fragments[contentStart] and fragments[contentStart].value == "Passive" then
        tooltipInfo.Capstone.Passive = {
            line = fragments[contentStart].line,
            right = fragments[contentStart].right,
        }
        contentStart = contentStart + 1
    end

    -- Collect tier boundary indices
    local tierStarts = {}
    for idx = contentStart, #fragments do
        if isCapstoneTierHeader(fragments[idx].value) then
            table.insert(tierStarts, idx)
        end
    end

    -- Parse each tier: header → current block → optional "Next:" → next block
    for t = 1, #tierStarts do
        local tierIdx = tierStarts[t]
        local tierEndIdx = tierStarts[t + 1] or (#fragments + 1)

        local tierHeader = fragments[tierIdx]
        local tier = {
            Header = { value = tierHeader.value, line = tierHeader.line, right = tierHeader.right },
            TierNumber = tonumber(tierHeader.value:match(capstoneTierHeaderPattern)),
            CurrentBlock = {},
            NextHeader = nil,
            NextBlock = nil,
        }

        -- Build current block, stopping at "Next:" or next tier
        local blockStart = tierIdx + 1
        tier.CurrentBlock = buildSpellBlock(fragments, blockStart, function(frag, idx)
            return idx >= tierEndIdx or frag.value == capstoneNextPreviewText
        end)

        -- Check for "Next:" within this tier
        for idx = blockStart, tierEndIdx - 1 do
            if fragments[idx].value == capstoneNextPreviewText then
                tier.NextHeader = {
                    value = fragments[idx].value,
                    line = fragments[idx].line,
                    right = fragments[idx].right,
                }
                tier.NextBlock = buildSpellBlock(fragments, idx + 1, function(_, bidx)
                    return bidx >= tierEndIdx
                end)
                break
            end
        end

        table.insert(tooltipInfo.Capstone.Tiers, tier)
    end

    -- If no tiers were found, fall back to spell-like shape
    if #tooltipInfo.Capstone.Tiers == 0 then
        tooltipInfo.Capstone = nil
        local block = buildSpellBlock(fragments, contentStart, nil)
        if not block.Descriptions then return nil end
        tooltipInfo.Spell = block
    end

    return tooltipInfo
end

-- ---------------------------------------------------------------------------
-- Translation
-- ---------------------------------------------------------------------------

---@class SpellTooltipTranslator : BaseTooltipTranslator
local translator = setmetatable({
    tooltipDataTypes = { Enum.TooltipDataType.Spell, Enum.TooltipDataType.Macro }
}, { __index = ns.BaseTooltipTranslator })

local function extractRequirementTalentName(str)
    local prefix = "Requires "
    local suffix = " talent"
    local start = str:find("^" .. prefix)
    local _end = str:find(suffix .. "$")
    if start and _end then
        local extracted = str:sub(#prefix + 1, _end - 1)
        return prefix .. "%s" .. suffix, extracted
    end
    return str
end

--- Translate all fields of a SpellBlock using the appropriate repositories.
local function translateTooltipSpellInfo(spellContainer, highlightSpellName)
    if (not spellContainer) then return end

    local translatedTooltipLines = {}

    if (spellContainer.ResourceType) then
        local translatedValues = {}
        for _, resourceValue in ipairs(spellContainer.ResourceType.values) do
            table.insert(translatedValues, GetTranslatedSpellAttribute(resourceValue))
        end
        table.insert(translatedTooltipLines, {
            line = spellContainer.ResourceType.line,
            right = spellContainer.ResourceType.right,
            value = table.concat(translatedValues, "\n")
        })
    end

    if (spellContainer.Range) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.Range.line,
            right = spellContainer.Range.right,
            value = GetTranslatedSpellAttribute(spellContainer.Range.value)
        })
    end

    if (spellContainer.Requires) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.Requires.line,
            right = spellContainer.Requires.right,
            value = GetTranslatedSpellAttribute(spellContainer.Requires.value)
        })
    end

    if (spellContainer.ReplacedBy) then
        local translatedFormat = GetTranslatedGlobalString(TALENT_BUTTON_TOOLTIP_REPLACED_BY_FORMAT)
        local spellName = GetTranslatedSpellName(spellContainer.ReplacedBy.value, false)
        table.insert(translatedTooltipLines, {
            line = spellContainer.ReplacedBy.line,
            right = spellContainer.ReplacedBy.right,
            value = translatedFormat:format(spellName)
        })
    end

    if (spellContainer.Replaces) then
        local translatedFormat = GetTranslatedGlobalString(REPLACES_SPELL)
        local spellName = GetTranslatedSpellName(spellContainer.Replaces.value, false)
        table.insert(translatedTooltipLines, {
            line = spellContainer.Replaces.line,
            right = spellContainer.Replaces.right,
            value = translatedFormat:format(spellName)
        })
    end

    if (spellContainer.CastTime) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.CastTime.line,
            right = spellContainer.CastTime.right,
            value = GetTranslatedSpellAttribute(spellContainer.CastTime.value)
        })
    end

    if (spellContainer.Cooldown) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.Cooldown.line,
            right = spellContainer.Cooldown.right,
            value = GetTranslatedSpellAttribute(spellContainer.Cooldown.value)
        })
    end

    if (spellContainer.CooldownRemaining) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.CooldownRemaining.line,
            right = spellContainer.CooldownRemaining.right,
            value = GetTranslatedSpellAttribute(spellContainer.CooldownRemaining.value)
        })
    end

    if (spellContainer.MaxCharges) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.MaxCharges.line,
            right = spellContainer.MaxCharges.right,
            value = GetTranslatedSpellAttribute(spellContainer.MaxCharges.value)
        })
    end

    if (spellContainer.EvokerSpellColor) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.EvokerSpellColor.line,
            right = spellContainer.EvokerSpellColor.right,
            value = GetTranslatedSpellAttribute(spellContainer.EvokerSpellColor.value)
        })
    end

    if (spellContainer.Passive) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.Passive.line,
            right = spellContainer.Passive.right,
            value = GetTranslatedGlobalString(SPELL_PASSIVE)
        })
    end

    if (spellContainer.Upgrade) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.Upgrade.line,
            right = spellContainer.Upgrade.right,
            value = GetTranslatedGlobalString(UPGRADE)
        })
    end

    if (spellContainer.AdditionalSpellTips) then
        for _, spellTip in ipairs(spellContainer.AdditionalSpellTips) do
            table.insert(translatedTooltipLines, {
                line = spellTip.line,
                right = spellTip.right,
                value = GetTranslatedGlobalString(spellTip.value)
            })
        end
    end

    if (spellContainer.Descriptions) then
        for _, description in ipairs(spellContainer.Descriptions) do
            local value = description.value:trim()
            if (value ~= "") then
                table.insert(translatedTooltipLines, {
                    line = description.line,
                    right = description.right,
                    value = GetTranslatedSpellDescription(value, highlightSpellName),
                    originalValue = value,
                    tag = "Description"
                })
            end
        end
    end

    return translatedTooltipLines
end

local function addUntranslatedSpellInfoToCache(spellID, translatedTooltipLines)
    local function findUntranslatedDescriptions(tooltipLines)
        local results = {}
        for _, obj in ipairs(tooltipLines) do
            if obj.tag == "Description" and StringsAreEqual(obj.value, obj.originalValue, true) then
                table.insert(results, obj.originalValue)
            end
        end
        return results
    end

    local originalName
    if translatedTooltipLines[1] then
        originalName = translatedTooltipLines[1].originalValue
    end

    if (originalName == nil) then return end

    local untranslatedDescriptions = findUntranslatedDescriptions(translatedTooltipLines)
    local untranslatedName = translatedTooltipLines[1].value == originalName and originalName or ""

    if (#untranslatedDescriptions == 0 and untranslatedName == "") then return end

    local classID, specID, isTalent
    local spellBookItemSlotIndex, spellBookItemSpellBank = C_SpellBook.FindSpellBookSlotForSpell(spellID, true, true, true, true)

    if (PlayerSpellsFrame and PlayerSpellsFrame:IsShown()) then
        classID = PlayerSpellsFrame:GetClassID();
        specID = PlayerSpellsFrame:GetSpecID();

        if (PlayerSpellsFrame:IsInspecting() and PlayerSpellsFrame:GetInspectUnit()) then
            isTalent = true
        else
            isTalent = C_Spell.IsClassTalentSpell(spellID) or C_Spell.IsPvPTalentSpell(spellID)
        end
    else
        _, _, classID = UnitClass("player")
        specID, _ = GetSpecializationInfo(GetSpecialization())
        isTalent = C_Spell.IsClassTalentSpell(spellID) or C_Spell.IsPvPTalentSpell(spellID)
    end

    local spellCategory
    if (not spellBookItemSlotIndex and not spellBookItemSpellBank and not isTalent) then
        spellCategory = ns.IngameDataCacher:GetOrAddCategory({ "spells", "others", spellID })
    else
        spellCategory = ns.IngameDataCacher:GetOrAddCategory({ "spells", classID, specID, spellID })
    end

    ns.IngameDataCacher:GetOrAddToCategory(spellCategory, "name", originalName)
    for _, desc in ipairs(untranslatedDescriptions) do
        local formattedDesc, _ = NormalizeStringAndExtractNumerics(desc)
        ns.IngameDataCacher:GetOrAddToCategory(spellCategory, "desc", formattedDesc)
    end
end

-- ---------------------------------------------------------------------------
-- Translator interface
-- ---------------------------------------------------------------------------

function translator:ParseTooltip(tooltip, tooltipData)
    local TLA = ns.TooltipLineAccessor
    local tooltipOwner = tooltip:GetOwner()
    local family = detectTooltipFamily(tooltipOwner)

    local fragments

    if family == "spell-like" then
        fragments = buildSpellLikeInput(tooltipData)
        if not fragments then return end
    else
        fragments = buildTalentInput(tooltip, TLA)
        if not fragments then return end
        if not isTalentLayoutComplete(tooltipOwner, fragments, family) then return end
    end

    local tooltipInfo
    if family == "spell-like" then
        tooltipInfo = parseSpellLikeTooltip(fragments)
    elseif family == "talent-capstone" then
        tooltipInfo = parseTalentCapstoneTooltip(fragments)
    else
        tooltipInfo = parseTalentSpendTooltip(fragments)
    end

    if not tooltipInfo then return end
    tooltipInfo.SpellId = tonumber(tooltipData.id)

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

    local spellNameLang = ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_NAME_OPTION)
    if (spellNameLang ~= "en") then
        local nameValue = tooltipInfo.Name.value
        local translatedValue = GetTranslatedSpellName(nameValue, true)

        local spellName = nameValue
        if (nameValue ~= translatedValue) then
            spellName = spellNameLang == "ua" and translatedValue or "|cFF47D5FF" .. nameValue .. "|r\n" .. translatedValue
        end

        -- Capstone title: reconstruct "TranslatedName (X/Y)" format
        if tooltipInfo.Capstone and tooltipInfo.Capstone.CurrentRank then
            spellName = string.format("%s (%s/%s)",
                spellName,
                tooltipInfo.Capstone.CurrentRank,
                tooltipInfo.Capstone.TotalMaxRanks)
        end

        table.insert(translatedTooltipLines, {
            line = tooltipInfo.Name.line,
            right = tooltipInfo.Name.right,
            value = spellName,
            originalValue = nameValue,
            tag = "Name"
        })
    end

    if (ns.SettingsProvider.IsNeedTranslateSpellDescriptionInTooltip()) then
        if (tooltipInfo.Form) then
            table.insert(translatedTooltipLines, {
                line = tooltipInfo.Form.line,
                right = tooltipInfo.Form.right,
                value = GetTranslatedSpellAttribute(tooltipInfo.Form.value)
            })
        end

        local highlightSpellName = ns.SettingsProvider.IsNeedHighlightSpellNameInDescription()

        if (tooltipInfo.Spell) then
            addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Spell, highlightSpellName))

        elseif (tooltipInfo.Talent) then
            local rankValue
            if tooltipInfo.Talent.MaxRank then
                rankValue = GetTranslatedGlobalString(TALENT_BUTTON_TOOLTIP_RANK_FORMAT)
                    :format(tooltipInfo.Talent.MinRank, tooltipInfo.Talent.MaxRank)
            else
                rankValue = GetTranslatedGlobalString(TALENT_BUTTON_TOOLTIP_RANK_NO_MAX_FORMAT)
                    :format(tooltipInfo.Talent.MinRank)
            end
            table.insert(translatedTooltipLines, {
                line = tooltipInfo.Talent.Rank.line,
                right = tooltipInfo.Talent.Rank.right,
                value = rankValue
            })
            addRange(translatedTooltipLines,
                translateTooltipSpellInfo(tooltipInfo.Talent.CurrentRank, highlightSpellName))

            if (tooltipInfo.Talent.NextRankHeader) then
                table.insert(translatedTooltipLines, {
                    line = tooltipInfo.Talent.NextRankHeader.line,
                    right = tooltipInfo.Talent.NextRankHeader.right,
                    value = GetTranslatedGlobalString(TALENT_BUTTON_TOOLTIP_NEXT_RANK)
                })
                addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Talent.NextRank, highlightSpellName))
            end

        elseif (tooltipInfo.Capstone) then
            local cap = tooltipInfo.Capstone

            if cap.Passive then
                table.insert(translatedTooltipLines, {
                    line = cap.Passive.line,
                    right = cap.Passive.right,
                    value = GetTranslatedGlobalString(SPELL_PASSIVE)
                })
            end

            for _, tier in ipairs(cap.Tiers) do
                table.insert(translatedTooltipLines, {
                    line = tier.Header.line,
                    right = tier.Header.right,
                    value = GetTranslatedGlobalString(TOOLTIP_TALENT_RANK_CAPSTONE):format(tier.TierNumber)
                })

                addRange(translatedTooltipLines, translateTooltipSpellInfo(tier.CurrentBlock, highlightSpellName))

                if tier.NextHeader then
                    table.insert(translatedTooltipLines, {
                        line = tier.NextHeader.line,
                        right = tier.NextHeader.right,
                        value = GetTranslatedGlobalString(TALENT_BUTTON_TOOLTIP_CAPSTONE_RANK_NEXT_STAGE_PREVIEW_TITLE)
                    })
                    if tier.NextBlock then
                        addRange(translatedTooltipLines, translateTooltipSpellInfo(tier.NextBlock, highlightSpellName))
                    end
                end
            end
        end
    end

    addUntranslatedSpellInfoToCache(tooltipInfo.SpellId, translatedTooltipLines)

    return translatedTooltipLines
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SPELL_TOOLTIPS_OPTION)
end

function translator:Init()
    local TLA = ns.TooltipLineAccessor

    ns.BaseTooltipTranslator.Init(self)

    hooksecurefunc(_G["TalentDisplayMixin"], "SetTooltipInternal", function(...)
        if (not self._postCallLineCount) then return end
        TLA.TranslateLines(GameTooltip, GetTranslatedGlobalString, self._postCallLineCount + 1)
        GameTooltip:Show();
    end)

    EventRegistry:RegisterCallback("PvPTalentButton.TooltipHook", function(...)
        if (not self._postCallLineCount) then return end
        TLA.TranslateLines(GameTooltip, function(text)
            local requiresText, talentName = extractRequirementTalentName(text)
            if talentName then
                local translated = GetTranslatedSpellAttribute(requiresText)
                return translated:format(GetTranslatedSpellName(talentName, false))
            end
            return GetTranslatedGlobalString(text)
        end, self._postCallLineCount + 1)
        GameTooltip:Show()
    end, translator)
end

ns.TranslationsManager:AddTranslator(translator)
