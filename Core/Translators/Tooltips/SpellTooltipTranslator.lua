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

--- Build the flat text array and index-to-line map for a spell-like tooltip.
--- Reads from tooltipData.lines (API data). Always emits one left and one right
--- entry per line to preserve the positional structure that parseSpellTooltip
--- expects (Name at index 1, Form at index 2).
---@param tooltipData table
---@return table|nil tooltipTexts
---@return table|nil indexToLine
local function buildSpellLikeInput(tooltipData)
    if not tooltipData or not tooltipData.lines or #tooltipData.lines == 0 then
        return nil, nil
    end

    local tooltipTexts = {}
    local indexToLine = {}

    for i, line in ipairs(tooltipData.lines) do
        local lli = #tooltipTexts + 1
        tooltipTexts[lli] = line.leftText or ""
        indexToLine[lli] = { line = i }

        local lri = #tooltipTexts + 1
        tooltipTexts[lri] = line.rightText or ""
        indexToLine[lri] = { line = i, right = true }
    end

    return tooltipTexts, indexToLine
end

--- Build the flat text array and index-to-line map for a talent tooltip.
--- Reads from visible FontStrings (layout source). At PostCall time this
--- contains the same API-provided lines as tooltipData.lines; wrapper lines
--- added by TalentDisplayMixin:SetTooltipInternal are not present yet.
---@param tooltip GameTooltip
---@param TLA TooltipLineAccessor
---@return table|nil tooltipTexts
---@return table|nil indexToLine
local function buildTalentInput(tooltip, TLA)
    if tooltip:NumLines() == 0 then return nil, nil end

    local tooltipTexts = {}
    local indexToLine = {}

    for i = 1, tooltip:NumLines() do
        local lineLeft = TLA.GetLeftFontString(tooltip, i)
        if lineLeft then
            local lli = #tooltipTexts + 1
            local text, isSecret = TLA.GetLeftText(tooltip, i)
            if isSecret then return nil, nil end
            tooltipTexts[lli] = text or ""
            indexToLine[lli] = { line = i }
        end

        local lineRight = TLA.GetRightFontString(tooltip, i)
        if lineRight then
            local lri = #tooltipTexts + 1
            local text, isSecret = TLA.GetRightText(tooltip, i)
            if isSecret then return nil, nil end
            tooltipTexts[lri] = text or ""
            indexToLine[lri] = { line = i, right = true }
        end
    end

    if #tooltipTexts == 0 then return nil, nil end
    return tooltipTexts, indexToLine
end

--- Validate that a talent tooltip layout is complete enough to translate.
--- Uses nodeInfo rank state and visible layout to detect incomplete first
--- callbacks where the full rank content has not yet arrived.
---@param tooltipOwner table|nil
---@param tooltipTexts table
---@return boolean complete True if the layout is ready for translation
local function isTalentLayoutComplete(tooltipOwner, tooltipTexts)
    if not tooltipOwner or not tooltipOwner.nodeInfo then return true end

    local currentRank = tooltipOwner.nodeInfo.currentRank
    local maxRanks = tooltipOwner.nodeInfo.maxRanks

    if currentRank == 0 then return true end

    local containsNextRank = ns.CommonUtil.FindKeyByValue(tooltipTexts, nextRankText)
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

local function parseSpellTooltip(tooltipTexts)
    local function isEvokerSpellColor(str)
        return str == "Red" or str == "Green" or str == "Blue" or str == "Black" or str == "Bronze"
    end

    local function isAdditionalSpellTips(str)
        return str == "Left click to select this talent."
            or StartsWith(str, "Unlocked at level ")
            or str == "Click to learn"
            or str == "Talents cannot be changed in combat."
    end

    local spellTooltip = {
        Name = tooltipTexts[1],
        Form = tooltipTexts[2] or "",
    }

    local contentIndex = 3

    if (tooltipTexts[3]) then
        local minRank, maxRank = tooltipTexts[3]:match(talentRankPattern)
        if (minRank and maxRank) then
            local talent = { MinRank = tonumber(minRank), MaxRank = tonumber(maxRank), CurrentRank = {} }

            talent.NextRankIndex = -1
            talent.NextRank = {}

            spellTooltip.Talent = talent

            contentIndex = contentIndex + 2
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
            local text = tooltipTexts[i]
            if (text ~= nil and text ~= "") then
                local resourceTypes = processResourceStrings(text)
                if (resourceTypes) then
                    spellContainer.ResourceType = { i }
                    for x, resourceType in ipairs(resourceTypes) do
                        table.insert(spellContainer.ResourceType, x + 1, resourceType)
                    end
                end

                if not resourceTypes then
                    local replacedBy = text:match(talentReplacedByPattern)
                    local replaces = text:match(talentReplacesPattern)
                    if (replaces or replacedBy) then
                        if (replaces) then
                            spellContainer.Replaces = { i, replaces:trim() }
                        else
                            spellContainer.ReplacedBy = { i, replacedBy:trim() }
                        end
                    elseif (text == nextRankText) then
                        spellTooltip.Talent.NextRankIndex = i
                        spellContainer = spellTooltip.Talent.NextRank
                    elseif isAdditionalSpellTips(text) then
                        if (not spellContainer.AdditionalSpellTips) then spellContainer.AdditionalSpellTips = {} end
                        table.insert(spellContainer.AdditionalSpellTips, { i, text })
                    elseif (isEvokerSpellColor(text)) then
                        spellContainer.EvokerSpellColor = { i, text }
                    elseif (string.match(text, maxChargesPattern)) then
                        spellContainer.MaxCharges = { i, text }
                    elseif text == "Melee Range" or text == "Unlimited range" or EndsWith(text, "yd range") then
                        spellContainer.Range = { i, text }
                    elseif text == "Instant" or text == "Channeled" or EndsWith(text, "sec cast") or EndsWith(text, "sec empower") then
                        spellContainer.CastTime = { i, text }
                    elseif StartsWith(text, "Requires") then
                        spellContainer.Requires = { i, text }
                    elseif EndsWith(text, "cooldown") or EndsWith(text, "recharge") or StartsWith(text, "Recharging: ") then
                        spellContainer.Cooldown = { i, text }
                    elseif StartsWith(text, "Cooldown remaining:") then
                        spellContainer.CooldownRemaining = { i, text }
                    elseif text == "Passive" then
                        spellContainer.Passive = i
                    elseif text == "Upgrade" then
                        spellContainer.Upgrade = i
                    elseif text == ptrHelpText then
                        -- ignore
                    elseif i % 2 == 1 then
                        if not spellContainer.Descriptions then spellContainer.Descriptions = {} end
                        table.insert(spellContainer.Descriptions, { index = i, value = text })
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
        for i = 2, #spellContainer.ResourceType do
            spellContainer.ResourceType[i] = GetTranslatedSpellAttribute(spellContainer.ResourceType[i])
        end
        table.insert(translatedTooltipLines, {
            index = spellContainer.ResourceType[1],
            value = table.concat(spellContainer.ResourceType, "\n", 2)
        })
    end

    if (spellContainer.Range) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.Range[1],
            value = GetTranslatedSpellAttribute(spellContainer.Range[2])
        })
    end

    if (spellContainer.Requires) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.Requires[1],
            value = GetTranslatedSpellAttribute(spellContainer.Requires[2])
        })
    end

    if (spellContainer.ReplacedBy) then
        local spellName = GetTranslatedSpellName(spellContainer.ReplacedBy[2], false)
        table.insert(translatedTooltipLines, {
            index = spellContainer.ReplacedBy[1],
            value = TALENT_REPLACED_BY_TRANSLATION .. " " .. spellName
        })
    end

    if (spellContainer.Replaces) then
        local spellName = GetTranslatedSpellName(spellContainer.Replaces[2], false)
        table.insert(translatedTooltipLines, {
            index = spellContainer.Replaces[1],
            value = TALENT_REPLACES_TRANSLATION .. " " .. spellName
        })
    end

    if (spellContainer.CastTime) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.CastTime[1],
            value = GetTranslatedSpellAttribute(spellContainer.CastTime[2])
        })
    end

    if (spellContainer.Cooldown) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.Cooldown[1],
            value = GetTranslatedSpellAttribute(spellContainer.Cooldown[2])
        })
    end

    if (spellContainer.CooldownRemaining) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.CooldownRemaining[1],
            value = GetTranslatedSpellAttribute(spellContainer.CooldownRemaining[2])
        })
    end

    if (spellContainer.MaxCharges) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.MaxCharges[1],
            value = GetTranslatedSpellAttribute(spellContainer.MaxCharges[2])
        })
    end

    if (spellContainer.EvokerSpellColor) then
        table.insert(translatedTooltipLines, {
            index = spellContainer.EvokerSpellColor[1],
            value = GetTranslatedSpellAttribute(spellContainer.EvokerSpellColor[2])
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

    if (spellContainer.AdditionalSpellTips) then
        for _, spellTip in ipairs(spellContainer.AdditionalSpellTips) do
            table.insert(translatedTooltipLines, {
                index = spellTip[1],
                value = GetTranslatedGlobalString(spellTip[2])
            })
        end
    end

    if (spellContainer.Descriptions) then
        for _, description in ipairs(spellContainer.Descriptions) do
            local value = description.value:trim()
            if (value ~= "") then
                table.insert(translatedTooltipLines, {
                    index = description.index,
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

    local tooltipTexts, indexToLine

    if family == "talent" then
        tooltipTexts, indexToLine = buildTalentInput(tooltip, TLA)
        if not tooltipTexts then return end
        if not isTalentLayoutComplete(tooltipOwner, tooltipTexts) then return end
    else
        tooltipTexts, indexToLine = buildSpellLikeInput(tooltipData)
        if not tooltipTexts then return end
    end

    local tooltipInfo = parseSpellTooltip(tooltipTexts)
    if not tooltipInfo then return end

    tooltipInfo.SpellId = tonumber(tooltipData.id)
    tooltipInfo._indexToLine = indexToLine

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
        local spellName = tooltipInfo.Name
        local translatedValue = GetTranslatedSpellName(tooltipInfo.Name, true)

        if (spellName ~= translatedValue) then
            spellName = spellNameLang == "ua" and translatedValue or "|cFF47D5FF" .. spellName .. "|r\n" .. translatedValue
        end

        table.insert(translatedTooltipLines, {
            index = 1,
            value = spellName,
            originalValue = tooltipInfo.Name,
            tag = "Name"
        })
    end

    if (ns.SettingsProvider.IsNeedTranslateSpellDescriptionInTooltip()) then
        if (tooltipInfo.Form and tooltipInfo.Form ~= "") then
            table.insert(translatedTooltipLines, {
                index = 2,
                value = GetTranslatedSpellAttribute(tooltipInfo.Form)
            })
        end

        local highlightSpellName = ns.SettingsProvider.IsNeedHighlightSpellNameInDescription()

        if (tooltipInfo.Spell) then
            addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Spell, highlightSpellName))
        elseif (tooltipInfo.Talent) then
            table.insert(translatedTooltipLines, {
                index = 3,
                value = SPELL_RANK_TRANSLATION .. " " .. tooltipInfo.Talent.MinRank .. "/" .. tooltipInfo.Talent.MaxRank
            })
            addRange(translatedTooltipLines,
                translateTooltipSpellInfo(tooltipInfo.Talent.CurrentRank, highlightSpellName))

            if (tooltipInfo.Talent.NextRankIndex ~= -1) then
                table.insert(translatedTooltipLines, {
                    index = tooltipInfo.Talent.NextRankIndex,
                    value = SPELL_NEXT_RANK_TRANSLATION
                })
                addRange(translatedTooltipLines, translateTooltipSpellInfo(tooltipInfo.Talent.NextRank, highlightSpellName))
            end
        end
    end

    addUntranslatedSpellInfoToCache(tooltipInfo.SpellId, translatedTooltipLines)

    local indexToLine = tooltipInfo._indexToLine
    if indexToLine then
        for _, entry in ipairs(translatedTooltipLines) do
            local mapping = indexToLine[entry.index]
            if mapping then
                entry.line = mapping.line
                entry.right = mapping.right or nil
                entry.index = nil
            end
        end
    end

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
