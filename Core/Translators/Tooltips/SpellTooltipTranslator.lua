--- @type string, WowUkrainizerInternals
local _, ns = ...;

local EndsWith = ns.StringUtil.EndsWith
local StartsWith = ns.StringUtil.StartsWith
local StringsAreEqual = ns.StringUtil.StringsAreEqual
local BuildMatchPattern = ns.StringUtil.BuildMatchPattern
local NormalizeStringAndExtractNumerics = ns.StringNormalizer.NormalizeStringAndExtractNumerics


local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedSpellDescription = ns.DbContext.Spells.GetTranslatedSpellDescription
local GetTranslatedSpellAttribute = ns.DbContext.Spells.GetTranslatedSpellAttribute
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

local F6_ISSUE_HELP_TEXT = "|c0042b1fePress F6 to submit an issue for this Spell"

local TALENT_RANK_WITH_MAX_PATTERN = BuildMatchPattern(TALENT_BUTTON_TOOLTIP_RANK_FORMAT)
local TALENT_RANK_NO_MAX_PATTERN = BuildMatchPattern(TALENT_BUTTON_TOOLTIP_RANK_NO_MAX_FORMAT)
local TALENT_REPLACED_BY_PATTERN = BuildMatchPattern(TALENT_BUTTON_TOOLTIP_REPLACED_BY_FORMAT)
local TALENT_REPLACES_PATTERN = BuildMatchPattern(REPLACES_SPELL)
local MAX_CHARGES_PATTERN = BuildMatchPattern(SPELL_MAX_CHARGES)
local CAPSTONE_TITLE_PATTERN = BuildMatchPattern(TALENT_BUTTON_TOOLTIP_CAPSTONE_TRACK_TITLE_FORMAT)
local CAPSTONE_TIER_HEADER_PATTERN = BuildMatchPattern(TOOLTIP_TALENT_RANK_CAPSTONE)
local CAPSTONE_NEXT_PREVIEW_TEXT = TALENT_BUTTON_TOOLTIP_CAPSTONE_RANK_NEXT_STAGE_PREVIEW_TITLE

-- Classification literals used by classifyFragment and friends. Grouped here
-- so the tooltip grammar is visible at a glance rather than scattered inline.
local CLASSIFIER = {
    PASSIVE = "Passive",
    UPGRADE = "Upgrade",
    MELEE_RANGE = "Melee Range",
    UNLIMITED_RANGE = "Unlimited range",
    RANGE_SUFFIX = "yd range",
    INSTANT = "Instant",
    CHANNELED = "Channeled",
    SEC_CAST_SUFFIX = "sec cast",
    SEC_EMPOWER_SUFFIX = "sec empower",
    REQUIRES_PREFIX = "Requires",
    COOLDOWN_SUFFIX = "cooldown",
    RECHARGE_SUFFIX = "recharge",
    RECHARGING_PREFIX = "Recharging: ",
    COOLDOWN_REMAINING_PREFIX = "Cooldown remaining:",
    UNLOCKED_AT_LEVEL_PREFIX = "Unlocked at level ",
    EVOKER_COLORS = { Red = true, Green = true, Blue = true, Black = true, Bronze = true },
    ADDITIONAL_TIPS = {
        ["Left click to select this talent."] = true,
        ["Click to learn"] = true,
        ["Talents cannot be changed in combat."] = true,
    },
}

-- SpellBlock fields whose translation is a plain GetTranslatedSpellAttribute
-- lookup on field.value. Non-simple fields (ResourceType, ReplacedBy, Replaces,
-- Passive, Upgrade, AdditionalSpellTips, Descriptions) stay inline in
-- translateTooltipSpellInfo — each has its own shape.
local SIMPLE_ATTRIBUTE_FIELDS = {
    "Range", "Requires", "CastTime", "Cooldown",
    "CooldownRemaining", "MaxCharges", "EvokerSpellColor",
}

local SPELL_RESOURCES = {
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
    "Soul Shard",
}

---@param str string
---@return boolean
local function isEvokerColor(str)
    return CLASSIFIER.EVOKER_COLORS[str] == true
end

---@param str string
---@return boolean
local function isAdditionalSpellTip(str)
    return CLASSIFIER.ADDITIONAL_TIPS[str] == true
        or StartsWith(str, CLASSIFIER.UNLOCKED_AT_LEVEL_PREFIX)
end

---@param value string
---@return boolean
local function isResourceString(value)
    for _, resource in ipairs(SPELL_RESOURCES) do
        if value:match("^%d+[.,]?%d* to %d+[.,]?%d* " .. resource .. "$")
            or value:match("^%d+[.,]?%d* " .. resource .. "$")
            or value:match("^%d+[.,]?%d* " .. resource .. ", plus %d+[.,]?%d* per sec$")
            or value:match("^%d+[.,]?%d* " .. resource .. " per sec$") then
            return true
        end
    end
    return false
end

---@param value string
---@return string[]
local function splitResourceString(value)
    local resourceStrings = {}
    for resourceString in value:gmatch("([^\n]+)") do
        table.insert(resourceStrings, resourceString)
    end
    return resourceStrings
end

--- Extract unique resource-cost lines from a multi-line fragment.
---@param str string
---@return string[]|nil
local function extractResourceLines(str)
    local resultTable = {}
    local seen = {}

    for _, resourceString in ipairs(splitResourceString(str)) do
        if isResourceString(resourceString) and not seen[resourceString] then
            seen[resourceString] = true
            table.insert(resultTable, resourceString)
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
    if text == F6_ISSUE_HELP_TEXT then return "Ignorable" end

    -- Fast path: use structured line type when available
    if lineType then
        if lineType == Enum.TooltipDataLineType.SpellDescription then return "Description" end
        if lineType == Enum.TooltipDataLineType.SpellPassive then return "Passive" end
    end

    local resourceTypes = extractResourceLines(text)
    if resourceTypes then return "ResourceType", { values = resourceTypes } end

    local replacedBy = text:match(TALENT_REPLACED_BY_PATTERN)
    if replacedBy then return "ReplacedBy", { name = replacedBy:trim() } end

    local replaces = text:match(TALENT_REPLACES_PATTERN)
    if replaces then return "Replaces", { name = replaces:trim() } end

    if text == CLASSIFIER.PASSIVE then return "Passive" end
    if text == CLASSIFIER.UPGRADE then return "Upgrade" end

    if text == CLASSIFIER.MELEE_RANGE or text == CLASSIFIER.UNLIMITED_RANGE
        or EndsWith(text, CLASSIFIER.RANGE_SUFFIX) then
        return "Range"
    end

    if text == CLASSIFIER.INSTANT or text == CLASSIFIER.CHANNELED
        or EndsWith(text, CLASSIFIER.SEC_CAST_SUFFIX)
        or EndsWith(text, CLASSIFIER.SEC_EMPOWER_SUFFIX) then
        return "CastTime"
    end

    if StartsWith(text, CLASSIFIER.REQUIRES_PREFIX) then return "Requires" end

    if EndsWith(text, CLASSIFIER.COOLDOWN_SUFFIX) or EndsWith(text, CLASSIFIER.RECHARGE_SUFFIX)
        or StartsWith(text, CLASSIFIER.RECHARGING_PREFIX) then
        return "Cooldown"
    end

    if StartsWith(text, CLASSIFIER.COOLDOWN_REMAINING_PREFIX) then return "CooldownRemaining" end
    if text:match(MAX_CHARGES_PATTERN) then return "MaxCharges" end
    if isEvokerColor(text) then return "EvokerSpellColor" end
    if isAdditionalSpellTip(text) then return "AdditionalSpellTip" end

    if not isRight then return "Description" end

    return nil
end

--- Build a SpellBlock from a contiguous range of classified fragments.
---@param fragments TooltipFragment[]
---@param startIdx integer First fragment index to consume (inclusive)
---@param stopFn (fun(frag: TooltipFragment, idx: integer): boolean?)? Predicate; true to stop BEFORE this fragment
---@return SpellBlock spellBlock
---@return integer nextIdx First unconsumed fragment index
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

--- Build an ordered fragment array for a spell-like tooltip from tooltipData.lines.
---@param tooltipData table
---@return TooltipFragment[]|nil
local function buildSpellFragments(tooltipData)
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
---@return TooltipFragment[]|nil
local function buildTalentFragments(tooltip, TLA)
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
---@param text string
---@return boolean
local function isCapstoneTierHeader(text)
    return text:match(CAPSTONE_TIER_HEADER_PATTERN) ~= nil
end

--- Validate that a talent tooltip layout is complete enough to translate.
---@param tooltipOwner table|nil
---@param fragments TooltipFragment[]
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

--- Extract Name and optional Form from the beginning of a fragment array.
---@param fragments TooltipFragment[]
---@return { Name: TooltipLineValue, Form: TooltipLineValue? } header
---@return integer contentStart Index of first content fragment
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

---@param fragments TooltipFragment[]
---@return SpellTooltipInfo|nil
local function parseSpellTooltip(fragments)
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

---@param fragments TooltipFragment[]
---@return SpellTooltipInfo|nil
local function parseTalentSpendTooltip(fragments)
    if not fragments or #fragments == 0 then return nil end

    local header, contentStart = extractHeader(fragments)
    local tooltipInfo = { Name = header.Name, Form = header.Form }

    -- Try to match a rank line at contentStart. MaxRank is nil when the
    -- NO_MAX pattern matched.
    local talent = nil
    local rankFrag = fragments[contentStart]
    if rankFrag then
        local minRank, maxRank = rankFrag.value:match(TALENT_RANK_WITH_MAX_PATTERN)
        if not minRank then
            minRank = rankFrag.value:match(TALENT_RANK_NO_MAX_PATTERN)
        end
        if minRank then
            talent = {
                Rank = { value = rankFrag.value, line = rankFrag.line, right = rankFrag.right },
                MinRank = minRank, MaxRank = maxRank,
                CurrentRank = {}, NextRankHeader = nil, NextRank = {},
            }
            contentStart = contentStart + 1
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

---@param fragments TooltipFragment[]
---@return SpellTooltipInfo|nil
local function parseTalentCapstoneTooltip(fragments)
    if not fragments or #fragments == 0 then return nil end

    -- Title: "SpellName (X/Y)" or just "SpellName" when totalMaxRanks == 0
    local nameFragment = fragments[1]
    local rawTitle = nameFragment.value
    local spellName, currentRank, totalMaxRanks = rawTitle:match(CAPSTONE_TITLE_PATTERN)
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
    if fragments[contentStart] and fragments[contentStart].value == CLASSIFIER.PASSIVE then
        tooltipInfo.Capstone.Passive = {
            line = fragments[contentStart].line,
            right = fragments[contentStart].right,
        }
        contentStart = contentStart + 1
    end

    -- Walk fragments once, closing the previous tier when a new header or a
    -- "Next:" marker appears. buildSpellBlock returns (block, nextIdx) so the
    -- loop advances without a second pass.
    local currentTier = nil
    local idx = contentStart
    while idx <= #fragments do
        local frag = fragments[idx]
        if isCapstoneTierHeader(frag.value) then
            currentTier = {
                Header = { value = frag.value, line = frag.line, right = frag.right },
                TierNumber = tonumber(frag.value:match(CAPSTONE_TIER_HEADER_PATTERN)),
                CurrentBlock = {},
                NextHeader = nil,
                NextBlock = nil,
            }
            table.insert(tooltipInfo.Capstone.Tiers, currentTier)
            currentTier.CurrentBlock, idx = buildSpellBlock(fragments, idx + 1, function(f)
                return f.value == CAPSTONE_NEXT_PREVIEW_TEXT or isCapstoneTierHeader(f.value)
            end)
        elseif currentTier and frag.value == CAPSTONE_NEXT_PREVIEW_TEXT then
            currentTier.NextHeader = { value = frag.value, line = frag.line, right = frag.right }
            currentTier.NextBlock, idx = buildSpellBlock(fragments, idx + 1, function(f)
                return isCapstoneTierHeader(f.value)
            end)
        else
            idx = idx + 1
        end
    end

    -- Fallback: no tier headers found. `tooltipInfo.Name.value` is the
    -- stripped title (without "(X/Y)") from CAPSTONE_TITLE_PATTERN, which is
    -- the correct display name for spell-like rendering.
    if #tooltipInfo.Capstone.Tiers == 0 then
        tooltipInfo.Capstone = nil
        local block = buildSpellBlock(fragments, contentStart, nil)
        if not block.Descriptions then return nil end
        tooltipInfo.Spell = block
    end

    return tooltipInfo
end

---@class SpellTooltipTranslator : BaseTooltipTranslator
local translator = setmetatable({
    tooltipDataTypes = { Enum.TooltipDataType.Spell, Enum.TooltipDataType.Macro }
}, { __index = ns.BaseTooltipTranslator })

---@param str string
---@return string? format    Translation key format with "%s" for the talent name, or nil on miss
---@return string? talentName Extracted talent name, or nil on miss
local function parseRequiresTalentLine(str)
    local prefix = "Requires "
    local suffix = " talent"
    local start = str:find("^" .. prefix)
    local endPos = str:find(suffix .. "$")
    if start and endPos then
        local talentName = str:sub(#prefix + 1, endPos - 1)
        return prefix .. "%s" .. suffix, talentName
    end
    return nil, nil
end

--- Translate all fields of a SpellBlock using the appropriate repositories.
---@param spellBlock SpellBlock?
---@param highlightSpellName boolean
---@return table[]? translatedTooltipLines Array of { line, right, value, ... } entries
local function translateTooltipSpellInfo(spellBlock, highlightSpellName)
    if not spellBlock then return end

    local translatedTooltipLines = {}

    if spellBlock.ResourceType then
        local translatedValues = {}
        for _, resourceValue in ipairs(spellBlock.ResourceType.values) do
            table.insert(translatedValues, GetTranslatedSpellAttribute(resourceValue))
        end
        table.insert(translatedTooltipLines, {
            line = spellBlock.ResourceType.line,
            right = spellBlock.ResourceType.right,
            value = table.concat(translatedValues, "\n")
        })
    end

    for _, key in ipairs(SIMPLE_ATTRIBUTE_FIELDS) do
        local field = spellBlock[key]
        if field then
            table.insert(translatedTooltipLines, {
                line = field.line,
                right = field.right,
                value = GetTranslatedSpellAttribute(field.value),
            })
        end
    end

    if spellBlock.ReplacedBy then
        local translatedFormat = GetTranslatedGlobalString(TALENT_BUTTON_TOOLTIP_REPLACED_BY_FORMAT)
        local spellName = GetTranslatedSpellName(spellBlock.ReplacedBy.value, false)
        table.insert(translatedTooltipLines, {
            line = spellBlock.ReplacedBy.line,
            right = spellBlock.ReplacedBy.right,
            value = translatedFormat:format(spellName)
        })
    end

    if spellBlock.Replaces then
        local translatedFormat = GetTranslatedGlobalString(REPLACES_SPELL)
        local spellName = GetTranslatedSpellName(spellBlock.Replaces.value, false)
        table.insert(translatedTooltipLines, {
            line = spellBlock.Replaces.line,
            right = spellBlock.Replaces.right,
            value = translatedFormat:format(spellName)
        })
    end

    if spellBlock.Passive then
        table.insert(translatedTooltipLines, {
            line = spellBlock.Passive.line,
            right = spellBlock.Passive.right,
            value = GetTranslatedGlobalString(SPELL_PASSIVE)
        })
    end

    if spellBlock.Upgrade then
        table.insert(translatedTooltipLines, {
            line = spellBlock.Upgrade.line,
            right = spellBlock.Upgrade.right,
            value = GetTranslatedGlobalString(UPGRADE)
        })
    end

    if spellBlock.AdditionalSpellTips then
        for _, spellTip in ipairs(spellBlock.AdditionalSpellTips) do
            table.insert(translatedTooltipLines, {
                line = spellTip.line,
                right = spellTip.right,
                value = GetTranslatedGlobalString(spellTip.value)
            })
        end
    end

    if spellBlock.Descriptions then
        for _, description in ipairs(spellBlock.Descriptions) do
            local value = description.value:trim()
            if value ~= "" then
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

---@param spellId integer?
---@param translatedTooltipLines table[]
local function addUntranslatedSpellInfoToCache(spellId, translatedTooltipLines)
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

    if originalName == nil then return end

    local untranslatedDescriptions = findUntranslatedDescriptions(translatedTooltipLines)
    local untranslatedName = translatedTooltipLines[1].value == originalName and originalName or ""

    if #untranslatedDescriptions == 0 and untranslatedName == "" then return end

    local classId, specId, isTalent = nil, nil, nil
    local spellBookItemSlotIndex, spellBookItemSpellBank = C_SpellBook.FindSpellBookSlotForSpell(
        spellId,
        true, -- includeHidden
        true, -- includeFlyouts
        true, -- includeFutureSpells
        true  -- includeOffSpec
    )

    if PlayerSpellsFrame and PlayerSpellsFrame:IsShown() then
        classId = PlayerSpellsFrame:GetClassID();
        specId = PlayerSpellsFrame:GetSpecID();

        if PlayerSpellsFrame:IsInspecting() and PlayerSpellsFrame:GetInspectUnit() then
            isTalent = true
        else
            isTalent = C_Spell.IsClassTalentSpell(spellId) or C_Spell.IsPvPTalentSpell(spellId)
        end
    else
        _, _, classId = UnitClass("player")
        specId, _ = GetSpecializationInfo(GetSpecialization())
        isTalent = C_Spell.IsClassTalentSpell(spellId) or C_Spell.IsPvPTalentSpell(spellId)
    end

    local spellCategory
    if not spellBookItemSlotIndex and not spellBookItemSpellBank and not isTalent then
        spellCategory = ns.IngameDataCacher:GetOrAddCategory({ "spells", "others", spellId })
    else
        spellCategory = ns.IngameDataCacher:GetOrAddCategory({ "spells", classId, specId, spellId })
    end

    ns.IngameDataCacher:GetOrAddToCategory(spellCategory, "name", originalName)
    for _, desc in ipairs(untranslatedDescriptions) do
        local formattedDesc, _ = NormalizeStringAndExtractNumerics(desc)
        ns.IngameDataCacher:GetOrAddToCategory(spellCategory, "desc", formattedDesc)
    end
end

function translator:ParseTooltip(tooltip, tooltipData)
    local TLA = ns.TooltipLineAccessor
    local tooltipOwner = tooltip:GetOwner()
    local family = detectTooltipFamily(tooltipOwner)

    local fragments

    if family == "spell-like" then
        fragments = buildSpellFragments(tooltipData)
        if not fragments then return end
    else
        fragments = buildTalentFragments(tooltip, TLA)
        if not fragments then return end
        if not isTalentLayoutComplete(tooltipOwner, fragments, family) then return end
    end

    local tooltipInfo
    if family == "spell-like" then
        tooltipInfo = parseSpellTooltip(fragments)
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
        if not t2 then return end
        for _, value in ipairs(t2) do
            table.insert(t1, value)
        end
    end

    local translatedTooltipLines = {}

    local spellNameLang = ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_NAME_OPTION)
    if spellNameLang ~= "en" then
        local nameValue = tooltipInfo.Name.value
        local translatedValue = GetTranslatedSpellName(nameValue, true)

        local spellName = nameValue
        if nameValue ~= translatedValue then
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

    if ns.SettingsProvider.IsNeedTranslateSpellDescriptionInTooltip() then
        if tooltipInfo.Form then
            table.insert(translatedTooltipLines, {
                line = tooltipInfo.Form.line,
                right = tooltipInfo.Form.right,
                value = GetTranslatedSpellAttribute(tooltipInfo.Form.value)
            })
        end

        local highlightSpellName = ns.SettingsProvider.IsNeedHighlightSpellNameInDescription()

        if tooltipInfo.Spell then
            addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Spell, highlightSpellName))

        elseif tooltipInfo.Talent then
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

            if tooltipInfo.Talent.NextRankHeader then
                table.insert(translatedTooltipLines, {
                    line = tooltipInfo.Talent.NextRankHeader.line,
                    right = tooltipInfo.Talent.NextRankHeader.right,
                    value = GetTranslatedGlobalString(TALENT_BUTTON_TOOLTIP_NEXT_RANK)
                })
                addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Talent.NextRank, highlightSpellName))
            end

        elseif tooltipInfo.Capstone then
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
        if not self._postCallLineCount then return end
        TLA.TranslateLines(GameTooltip, GetTranslatedGlobalString, self._postCallLineCount + 1)
        GameTooltip:Show()
    end)

    EventRegistry:RegisterCallback("PvPTalentButton.TooltipHook", function(...)
        if not self._postCallLineCount then return end
        TLA.TranslateLines(GameTooltip, function(text)
            local requiresText, talentName = parseRequiresTalentLine(text)
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
