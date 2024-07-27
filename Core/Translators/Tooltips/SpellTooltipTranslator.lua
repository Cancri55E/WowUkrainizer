--- @type string, WowUkrainizerInternals
local _, ns = ...;

local _G = _G

local EndsWith = ns.StringUtil.EndsWith
local StartsWith = ns.StringUtil.StartsWith
local StringsAreEqual = ns.StringUtil.StringsAreEqual
local NormalizeStringAndExtractNumerics = ns.StringNormalizer.NormalizeStringAndExtractNumerics
local IsValueInTable = ns.CommonUtil.IsValueInTable

local SPELL_PASSIVE_TRANSLATION = ns.SPELL_PASSIVE_TRANSLATION
local TALENT_UPGRADE_TRANSLATION = ns.TALENT_UPGRADE_TRANSLATION
local SPELL_RANK_TRANSLATION = ns.SPELL_RANK_TRANSLATION
local SPELL_NEXT_RANK_TRANSLATION = ns.SPELL_NEXT_RANK_TRANSLATION
local TALENT_REPLACES_TRANSLATION = ns.TALENT_REPLACES_TRANSLATION
local TALENT_REPLACED_BY_TRANSLATION = ns.TALENT_REPLACED_BY_TRANSLATION

local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedSpellDescription = ns.DbContext.Spells.GetTranslatedSpellDescription
local GetTranslatedSpellAttribute = ns.DbContext.Spells.GetTranslatedSpellAttribute
local GetTranslatedUISpellTooltip = ns.DbContext.Frames.GetTranslatedUISpellTooltip

local talentRankPattern = "Rank (%d+)/(%d+)"
local talentReplacedByPattern = "^Replaced by%s+(.+)"
local talentReplacesPattern = "^Replaces%s+(.+)"
local maxChargesPattern = "Max %d+ Charges"
local nextRankText = "Next Rank:"
local ptrHelpText = "|c0042b1fePress F6 to submit an issue for this Spell"

---@class SpellTooltipTranslator : BaseTooltipTranslator
local translator = setmetatable({ tooltipDataType = Enum.TooltipDataType.Spell }, { __index = ns.BaseTooltipTranslator })

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
            if (text ~= nil or text ~= "") then
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
                value = GetTranslatedUISpellTooltip(spellTip[2])
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
    local linePrefix = "GameTooltip";
    if (tooltip == _G["ElvUI_SpellBookTooltip"]) then linePrefix = 'ElvUI_SpellBookTooltip' end

    self._postCallLineCount = tonumber(tooltip:NumLines())

    local tooltipTexts = {}
    for i = 1, tooltip:NumLines() do
        local lineLeft = _G[linePrefix .. "TextLeft" .. i]
        if (lineLeft) then
            local lli = #tooltipTexts + 1;
            tooltipTexts[lli] = lineLeft:GetText() or ''
            self:AddFontStringToIndexLookup(lli, lineLeft)
        end

        local lineRight = _G[linePrefix .. "TextRight" .. i]
        if (lineRight) then
            local lri = #tooltipTexts + 1;
            tooltipTexts[lri] = lineRight:GetText() or ''
            self:AddFontStringToIndexLookup(lri, lineRight)
        end
    end

    local tooltipOwner = tooltip:GetOwner()

    -- HOOK: No Rank 1/2+ info in multirang talent tooltip. In this case client send another callback.
    if (tooltipOwner.nodeInfo) then
        local currentRank = tooltipOwner.nodeInfo.currentRank
        local maxRanks = tooltipOwner.nodeInfo.maxRanks

        local containsNextRank = ns.CommonUtil.FindKeyByValue(tooltipTexts, nextRankText)
        if (currentRank ~= 0 and not containsNextRank) then
            if ((currentRank < maxRanks) or (currentRank == maxRanks and tooltipOwner:IsRefundInvalid())) then
                return
            end
        end
    end

    local tooltipInfo = parseSpellTooltip(tooltipTexts)
    if (not tooltipInfo) then return end

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

    return translatedTooltipLines
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SPELL_TOOLTIPS_OPTION)
end

function translator:Init()
    ns.BaseTooltipTranslator.Init(self)

    hooksecurefunc(_G["TalentDisplayMixin"], "SetTooltipInternal", function(...)
        if (not self._postCallLineCount) then return end
        for i = self._postCallLineCount + 1, GameTooltip:NumLines() do
            local lineLeft = _G["GameTooltipTextLeft" .. i]
            if (lineLeft) then
                local leftTranslatedTips = GetTranslatedUISpellTooltip(lineLeft:GetText())
                lineLeft:SetText(leftTranslatedTips)
            end

            local lineRight = _G["GameTooltipTextRight" .. i]
            if (lineRight) then
                local rightTranslatedTips = GetTranslatedUISpellTooltip(lineRight:GetText())
                lineRight:SetText(rightTranslatedTips)
            end
        end
        GameTooltip:Show();
    end)

    EventRegistry:RegisterCallback("PvPTalentButton.TooltipHook", function(...)
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

        if (not self._postCallLineCount) then return end
        for i = self._postCallLineCount + 1, GameTooltip:NumLines() do
            local lineLeft = _G["GameTooltipTextLeft" .. i]
            if (lineLeft) then
                local text = lineLeft:GetText() or ''
                local requiresText, talentName = extractRequirementTalentName(text)
                if (talentName ~= nil) then
                    local translatedRequiresText = GetTranslatedSpellAttribute(requiresText)
                    translatedRequiresText = translatedRequiresText:format(GetTranslatedSpellName(talentName, false))
                    lineLeft:SetText(translatedRequiresText)
                else
                    lineLeft:SetText(GetTranslatedUISpellTooltip(text))
                end
            end
        end
        GameTooltip:Show();
    end, translator)
end

ns.TranslationsManager:AddTranslator(translator)
