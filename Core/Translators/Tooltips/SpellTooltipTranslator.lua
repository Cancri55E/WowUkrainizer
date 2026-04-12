--- @type string, WowUkrainizerInternals
local _, ns = ...;

local EndsWith = ns.StringUtil.EndsWith
local StartsWith = ns.StringUtil.StartsWith
local StringsAreEqual = ns.StringUtil.StringsAreEqual
local NormalizeStringAndExtractNumerics = ns.StringNormalizer.NormalizeStringAndExtractNumerics

local SPELL_PASSIVE_TRANSLATION = ns.SPELL_PASSIVE_TRANSLATION
local TALENT_UPGRADE_TRANSLATION = ns.TALENT_UPGRADE_TRANSLATION
local SPELL_RANK_TRANSLATION = ns.SPELL_RANK_TRANSLATION
local SPELL_NEXT_RANK_TRANSLATION = ns.SPELL_NEXT_RANK_TRANSLATION
local TALENT_REPLACES_TRANSLATION = ns.TALENT_REPLACES_TRANSLATION
local TALENT_REPLACED_BY_TRANSLATION = ns.TALENT_REPLACED_BY_TRANSLATION

local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedSpellDescription = ns.DbContext.Spells.GetTranslatedSpellDescription
local GetTranslatedSpellAttribute = ns.DbContext.Spells.GetTranslatedSpellAttribute
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

local talentRankPattern = "Rank (%d+)/(%d+)"
local talentReplacedByPattern = "^Replaced by%s+(.+)"
local talentReplacesPattern = "^Replaces%s+(.+)"
local maxChargesPattern = "Max %d+ Charges"
local nextRankText = "Next Rank:"
local ptrHelpText = "|c0042b1fePress F6 to submit an issue for this Spell"

--- Detect the tooltip family based on the tooltip owner.
--- TalentFrame tooltips are identified by definitionID. All other spell-like
--- tooltips (regular spells, macros, PvP talents) fall into the spell-like family.
---@param tooltipOwner table|nil
---@return "talent"|"spell-like"
local function detectTooltipFamily(tooltipOwner)
    if tooltipOwner and tooltipOwner.definitionID then
        return "talent"
    end
    return "spell-like"
end

--- Build an ordered fragment array for a spell-like tooltip from tooltipData.lines.
--- Each fragment carries the display line number and side. Secret values and empty
--- lines are dropped — no placeholder fragments are emitted.
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

        -- Only advance the line counter for lines that GameTooltip renders.
        -- Empty spacer rows in tooltipData.lines do not produce a visible line.
        local isRendered = leftVal ~= "" or rightVal ~= "" or leftIsSecret or rightIsSecret
        if isRendered then
            tooltipLineNum = tooltipLineNum + 1
        end

        if not leftIsSecret and leftVal ~= "" then
            table.insert(fragments, { value = leftVal, line = tooltipLineNum, right = false })
        end

        if not rightIsSecret and rightVal ~= "" then
            table.insert(fragments, { value = rightVal, line = tooltipLineNum, right = true })
        end
    end

    return #fragments > 0 and fragments or nil
end

--- Build an ordered fragment array for a talent tooltip from visible FontStrings.
--- Secret values and empty FontStrings are dropped.
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

--- Validate that a talent tooltip layout is complete enough to translate.
--- Uses nodeInfo rank state and the fragment array to detect incomplete first
--- callbacks where the full rank content has not yet arrived.
---@param tooltipOwner table|nil
---@param fragments table
---@return boolean complete True if the layout is ready for translation
local function isTalentLayoutComplete(tooltipOwner, fragments)
    if not tooltipOwner or not tooltipOwner.nodeInfo then return true end

    local currentRank = tooltipOwner.nodeInfo.currentRank
    local maxRanks = tooltipOwner.nodeInfo.maxRanks

    if currentRank == 0 then return true end

    local containsNextRank = false
    for _, frag in ipairs(fragments) do
        if frag.value == nextRankText then
            containsNextRank = true
            break
        end
    end
    if containsNextRank then return true end

    if currentRank < maxRanks then return false end
    if currentRank == maxRanks and tooltipOwner:IsRefundInvalid() then return false end

    return true
end

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

--- Parse a fragment array into a structured spell tooltip model.
--- Every field in the result carries direct { value, line, right } coordinates.
--- fragments[1] is the spell Name (left of line 1).
--- Form is the right-side fragment on the SpellName line when present.
---@param fragments table Array of { value, line, right } entries from an adapter
---@return table|nil spellTooltip Parsed tooltip model, or nil on early-return
local function parseSpellTooltip(fragments)
    local function isEvokerSpellColor(str)
        return str == "Red" or str == "Green" or str == "Blue" or str == "Black" or str == "Bronze"
    end

    local function isAdditionalSpellTips(str)
        return str == "Left click to select this talent."
            or StartsWith(str, "Unlocked at level ")
            or str == "Click to learn"
            or str == "Talents cannot be changed in combat."
    end

    if not fragments or #fragments == 0 then return nil end

    local nameFragment = fragments[1]
    local spellTooltip = {
        Name = { value = nameFragment.value, line = nameFragment.line, right = nameFragment.right },
    }

    -- Form is the right-side fragment on the SpellName line, if present.
    local contentStart = 2
    if fragments[2] and fragments[2].line == nameFragment.line and fragments[2].right then
        local f = fragments[2]
        spellTooltip.Form = { value = f.value, line = f.line, right = f.right }
        contentStart = 3
    end

    -- Detect talent rank at the first content fragment.
    local rankFrag = fragments[contentStart]
    if rankFrag then
        local minRank, maxRank = rankFrag.value:match(talentRankPattern)
        if minRank and maxRank then
            spellTooltip.Talent = {
                Rank = { value = rankFrag.value, line = rankFrag.line, right = rankFrag.right },
                MinRank = tonumber(minRank),
                MaxRank = tonumber(maxRank),
                CurrentRank = {},
                NextRankHeader = nil,
                NextRank = {}
            }
            contentStart = contentStart + 1
        else
            spellTooltip.Spell = {}
        end
    end

    local spellContainer =
        (spellTooltip.Talent and spellTooltip.Talent.CurrentRank) and spellTooltip.Talent.CurrentRank
        or spellTooltip.Spell
        or nil

    if (spellContainer) then
        for i = contentStart, #fragments do
            local frag = fragments[i]
            local text = frag.value
            if (text ~= nil and text ~= "") then
                local resourceTypes = processResourceStrings(text)
                if (resourceTypes) then
                    spellContainer.ResourceType = {
                        line = frag.line,
                        right = frag.right,
                        values = resourceTypes
                    }
                end

                if not resourceTypes then
                    local replacedBy = text:match(talentReplacedByPattern)
                    local replaces = text:match(talentReplacesPattern)
                    if (replaces or replacedBy) then
                        if (replaces) then
                            spellContainer.Replaces = { value = replaces:trim(), line = frag.line, right = frag.right }
                        else
                            spellContainer.ReplacedBy = { value = replacedBy:trim(), line = frag.line, right = frag.right }
                        end
                    elseif (text == nextRankText) then
                        spellTooltip.Talent.NextRankHeader = { value = text, line = frag.line, right = frag.right }
                        spellContainer = spellTooltip.Talent.NextRank
                    elseif isAdditionalSpellTips(text) then
                        if (not spellContainer.AdditionalSpellTips) then spellContainer.AdditionalSpellTips = {} end
                        table.insert(spellContainer.AdditionalSpellTips, { value = text, line = frag.line, right = frag.right })
                    elseif (isEvokerSpellColor(text)) then
                        spellContainer.EvokerSpellColor = { value = text, line = frag.line, right = frag.right }
                    elseif (string.match(text, maxChargesPattern)) then
                        spellContainer.MaxCharges = { value = text, line = frag.line, right = frag.right }
                    elseif text == "Melee Range" or text == "Unlimited range" or EndsWith(text, "yd range") then
                        spellContainer.Range = { value = text, line = frag.line, right = frag.right }
                    elseif text == "Instant" or text == "Channeled" or EndsWith(text, "sec cast") or EndsWith(text, "sec empower") then
                        spellContainer.CastTime = { value = text, line = frag.line, right = frag.right }
                    elseif StartsWith(text, "Requires") then
                        spellContainer.Requires = { value = text, line = frag.line, right = frag.right }
                    elseif EndsWith(text, "cooldown") or EndsWith(text, "recharge") or StartsWith(text, "Recharging: ") then
                        spellContainer.Cooldown = { value = text, line = frag.line, right = frag.right }
                    elseif StartsWith(text, "Cooldown remaining:") then
                        spellContainer.CooldownRemaining = { value = text, line = frag.line, right = frag.right }
                    elseif text == "Passive" then
                        spellContainer.Passive = { line = frag.line, right = frag.right }
                    elseif text == "Upgrade" then
                        spellContainer.Upgrade = { line = frag.line, right = frag.right }
                    elseif text == ptrHelpText then
                        -- ignore
                    elseif not frag.right then
                        if not spellContainer.Descriptions then spellContainer.Descriptions = {} end
                        table.insert(spellContainer.Descriptions, { value = text, line = frag.line, right = frag.right })
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
        local spellName = GetTranslatedSpellName(spellContainer.ReplacedBy.value, false)
        table.insert(translatedTooltipLines, {
            line = spellContainer.ReplacedBy.line,
            right = spellContainer.ReplacedBy.right,
            value = TALENT_REPLACED_BY_TRANSLATION .. " " .. spellName
        })
    end

    if (spellContainer.Replaces) then
        local spellName = GetTranslatedSpellName(spellContainer.Replaces.value, false)
        table.insert(translatedTooltipLines, {
            line = spellContainer.Replaces.line,
            right = spellContainer.Replaces.right,
            value = TALENT_REPLACES_TRANSLATION .. " " .. spellName
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
            value = SPELL_PASSIVE_TRANSLATION
        })
    end

    if (spellContainer.Upgrade) then
        table.insert(translatedTooltipLines, {
            line = spellContainer.Upgrade.line,
            right = spellContainer.Upgrade.right,
            value = TALENT_UPGRADE_TRANSLATION
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

function translator:ParseTooltip(tooltip, tooltipData)
    local TLA = ns.TooltipLineAccessor
    local tooltipOwner = tooltip:GetOwner()
    local family = detectTooltipFamily(tooltipOwner)

    local fragments

    if family == "talent" then
        fragments = buildTalentInput(tooltip, TLA)
        if not fragments then return end
        if not isTalentLayoutComplete(tooltipOwner, fragments) then return end
    else
        fragments = buildSpellLikeInput(tooltipData)
        if not fragments then return end
    end

    local tooltipInfo = parseSpellTooltip(fragments)
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
            table.insert(translatedTooltipLines, {
                line = tooltipInfo.Talent.Rank.line,
                right = tooltipInfo.Talent.Rank.right,
                value = SPELL_RANK_TRANSLATION .. " " .. tooltipInfo.Talent.MinRank .. "/" .. tooltipInfo.Talent.MaxRank
            })
            addRange(translatedTooltipLines,
                translateTooltipSpellInfo(tooltipInfo.Talent.CurrentRank, highlightSpellName))

            if (tooltipInfo.Talent.NextRankHeader) then
                table.insert(translatedTooltipLines, {
                    line = tooltipInfo.Talent.NextRankHeader.line,
                    right = tooltipInfo.Talent.NextRankHeader.right,
                    value = SPELL_NEXT_RANK_TRANSLATION
                })
                addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Talent.NextRank, highlightSpellName))
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
