local _, ns = ...;

local _G = _G

local PAGE_TRANSLATION, SPELL_PASSIVE_TRANSLATION = ns.PAGE_TRANSLATION, ns.SPELL_PASSIVE_TRANSLATION
local RANK_TRANSLATION, LEVEL_TRANSLATION = ns.RANK_TRANSLATION, ns.LEVEL_TRANSLATION
local SPELL_GENERAL_TRANSLATION = ns.SPELL_GENERAL_TRANSLATION

local StartsWith, UpdateFontString = ns.StringExtensions.StartsWith, ns.FontStringExtensions.UpdateFontString
local GetSpellNameOrDefault = ns.DbContext.Spells.GetSpellNameOrDefault
local GetSpellAttributeOrDefault = ns.DbContext.Spells.GetSpellAttributeOrDefault
local GetTranslationOrDefault = ns.DbContext.SpellbookFrame.GetTranslationOrDefault
local GetClass, GetSpecialization = ns.DbContext.Units.GetClass, ns.DbContext.Units.GetSpecialization

local translator = class("SpellbookFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.SpellbookFrameTranslator = translator

local function updateSpellButtonCallback(self)
    local slot, _, _ = SpellBook_GetSpellBookSlot(self);
    if (not slot) then return end

    local _, _, spellID = GetSpellBookItemName(slot, SpellBookFrame.bookType);
    if (not spellID) then return end

    local name = self:GetName();

    local spellString = self.SpellName
    if (spellString) then
        UpdateFontString(spellString, GetSpellNameOrDefault(spellString:GetText()))
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
                    UpdateFontString(subSpellNameString, SPELL_PASSIVE_TRANSLATION)
                elseif (StartsWith(subSpellName, "Rank")) then
                    UpdateFontString(subSpellNameString, string.gsub(subSpellName, "Rank", RANK_TRANSLATION))
                else
                    UpdateFontString(subSpellNameString, GetSpellAttributeOrDefault(subSpellName))
                end
            end

            if (requiredLevel) then
                if (StartsWith(requiredLevel, "Level")) then
                    UpdateFontString(requiredLevelString, string.gsub(requiredLevel, "Level", LEVEL_TRANSLATION))
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
    UpdateFontString(SpellBookPageText, string.gsub(SpellBookPageText:GetText(), "Page", PAGE_TRANSLATION))
end

local function updateCallback(...)
    local titleTextFontString = SpellBookFrame:GetTitleText()
    titleTextFontString:SetText(GetTranslationOrDefault(titleTextFontString:GetText()))

    SpellBookFrameTabButton1:SetText(GetTranslationOrDefault(SpellBookFrameTabButton1:GetText()))
    SpellBookFrameTabButton2:SetText(GetTranslationOrDefault(SpellBookFrameTabButton2:GetText()))
    if (SpellBookFrameTabButton3) then
        SpellBookFrameTabButton3:SetText(GetTranslationOrDefault(SpellBookFrameTabButton3:GetText()))
    end
end

local function setDefaultFont()
    local function updateFont(obj, fontName, scale)
        local _, height, flags = obj:GetFont()
        obj:SetFont(fontName, height * scale, flags)
    end

    updateFont(SpellBookFrameTabButton1:GetFontString(), ns.DefaultFontName, 1.05)
    updateFont(SpellBookFrameTabButton2:GetFontString(), ns.DefaultFontName, 1.05)
    if (SpellBookFrameTabButton3) then
        updateFont(SpellBookFrameTabButton3:GetFontString(), ns.DefaultFontName, 1.05)
    end

    updateFont(SpellBookPageText, ns.DefaultFontName, 1.05)
    updateFont(SpellBookFrame.TitleContainer.TitleText, ns.DefaultFontName, 1.1)

    for i = 1, 12, 1 do
        local spellString = _G["SpellButton" .. i .. "SpellName"]
        updateFont(spellString, ns.DefaultFontName, 1.15)

        local subSpellNameString = _G["SpellButton" .. i .. "SubSpellName"];
        updateFont(subSpellNameString, ns.DefaultFontName, 1.05)

        local requiredLevelString = _G["SpellButton" .. i .. "RequiredLevelString"];
        updateFont(requiredLevelString, ns.DefaultFontName, 1.05)
    end
end

function translator:initialize()
    local function updateSpellButtonWrapper(spellButton)
        if (not self:IsEnabled()) then return end
        updateSpellButtonCallback(spellButton)
    end

    setDefaultFont()

    SpellBookFrame_HelpPlate[1].ToolTipText = GetTranslationOrDefault(SPELLBOOK_HELP_1)
    SpellBookFrame_HelpPlate[2].ToolTipText = GetTranslationOrDefault(SPELLBOOK_HELP_2)
    SpellBookFrame_HelpPlate[3].ToolTipText = GetTranslationOrDefault(SPELLBOOK_HELP_3)

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
