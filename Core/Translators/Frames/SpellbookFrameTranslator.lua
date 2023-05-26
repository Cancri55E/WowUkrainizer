local _, ns = ...;

local _G = _G

local PAGE_TRANSLATION, SPELL_PASSIVE_TRANSLATION = ns.PAGE_TRANSLATION, ns.SPELL_PASSIVE_TRANSLATION
local SPELL_RANK_TRANSLATION, LEVEL_TRANSLATION = ns.SPELL_RANK_TRANSLATION, ns.LEVEL_TRANSLATION
local SPELL_GENERAL_TRANSLATION = ns.SPELL_GENERAL_TRANSLATION

local StartsWith, SetText = ns.StringExtensions.StartsWith, ns.FontStringExtensions.SetText
local GetSpellNameOrDefault = ns.DbContext.Spells.GetSpellNameOrDefault
local GetSpellAttributeOrDefault = ns.DbContext.Spells.GetSpellAttributeOrDefault
local GetClass, GetSpecialization = ns.DbContext.Units.GetClass, ns.DbContext.Units.GetSpecialization

local function getTranslationOrDefault(default)
    return ns.DbContext.Frames.GetTranslationOrDefault("spellbook", default)
end

local translator = class("SpellbookFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.SpellbookFrameTranslator = translator

local function updateSpellButtonCallback(self)
    local slot, _, _ = SpellBook_GetSpellBookSlot(self);
    if (not slot) then return end

    local _, _, spellID = GetSpellBookItemName(slot, SpellBookFrame.bookType);
    if (not spellID) then return end

    local spellString = self.SpellName
    if (spellString) then
        SetText(spellString, GetSpellNameOrDefault(spellString:GetText(), false))
    end

    local subSpellNameString = self.SpellSubName
    local subSpellName = subSpellNameString and subSpellNameString:GetText() or nil;

    local requiredLevelString = self.RequiredLevelString
    local requiredLevel = requiredLevelString and requiredLevelString:GetText() or nil;

    if (subSpellName or requiredLevel) then
        local spell = Spell:CreateFromSpellID(spellID);
        spell:ContinueOnSpellLoad(function()
            if (subSpellName) then
                if (subSpellName == "Passive") then
                    SetText(subSpellNameString, SPELL_PASSIVE_TRANSLATION)
                elseif (StartsWith(subSpellName, "Rank")) then
                    SetText(subSpellNameString, string.gsub(subSpellName, "Rank", SPELL_RANK_TRANSLATION))
                else
                    SetText(subSpellNameString, GetSpellAttributeOrDefault(subSpellName))
                end
            end

            if (requiredLevel) then
                if (StartsWith(requiredLevel, "Level")) then
                    SetText(requiredLevelString, string.gsub(requiredLevel, "Level", LEVEL_TRANSLATION))
                end
            end
        end);
    end
end

local function updateSkillLineTabsCallback()
    local numSkillLineTabs = GetNumSpellTabs();
    local gender = UnitSex("player")
    for i = 1, MAX_SKILLLINE_TABS do
        local skillLineTab = _G["SpellBookSkillLineTab" .. i];
        if (i <= numSkillLineTabs and SpellBookFrame.bookType == BOOKTYPE_SPELL) then
            local name, _, _, _, _, _, shouldHide, _ = GetSpellTabInfo(i);
            if (not shouldHide) then
                if (i == 1) then
                    skillLineTab.tooltip = SPELL_GENERAL_TRANSLATION
                elseif (i == 2) then
                    skillLineTab.tooltip = GetClass(name, 1, gender);
                else
                    skillLineTab.tooltip = GetSpecialization(name, 1, gender);
                end
            end
        end
    end
end

local function updatePagesCallback()
    SetText(SpellBookPageText, string.gsub(SpellBookPageText:GetText(), "Page", PAGE_TRANSLATION))
end

local function updateCallback(...)
    local titleTextFontString = SpellBookFrame:GetTitleText()
    titleTextFontString:SetText(getTranslationOrDefault(titleTextFontString:GetText()))

    SpellBookFrameTabButton1:SetText(getTranslationOrDefault(SpellBookFrameTabButton1:GetText()))
    SpellBookFrameTabButton2:SetText(getTranslationOrDefault(SpellBookFrameTabButton2:GetText()))
    if (SpellBookFrameTabButton3) then
        SpellBookFrameTabButton3:SetText(getTranslationOrDefault(SpellBookFrameTabButton3:GetText()))
    end
end

function translator:initialize()
    local function updateSpellButtonWrapper(spellButton)
        if (not self:IsEnabled()) then return end
        updateSpellButtonCallback(spellButton)
    end

    SpellBookFrame_HelpPlate[1].ToolTipText = getTranslationOrDefault(_G["SPELLBOOK_HELP_1"])
    SpellBookFrame_HelpPlate[2].ToolTipText = getTranslationOrDefault(_G["SPELLBOOK_HELP_2"])
    SpellBookFrame_HelpPlate[3].ToolTipText = getTranslationOrDefault(_G["SPELLBOOK_HELP_3"])

    hooksecurefunc(SpellButton1, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton2, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton3, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton4, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton5, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton6, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton7, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton8, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton9, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton10, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton11, "UpdateButton", updateSpellButtonWrapper)
    hooksecurefunc(SpellButton12, "UpdateButton", updateSpellButtonWrapper)

    hooksecurefunc("SpellBookFrame_UpdateSkillLineTabs", function(_)
        if (not self:IsEnabled()) then return end
        updateSkillLineTabsCallback()
    end)

    hooksecurefunc("SpellBookFrame_UpdatePages", function(_)
        if (not self:IsEnabled()) then return end
        updatePagesCallback()
    end)

    hooksecurefunc("SpellBookFrame_Update", function(_)
        if (not self:IsEnabled()) then return end
        updateCallback()
    end)
end
