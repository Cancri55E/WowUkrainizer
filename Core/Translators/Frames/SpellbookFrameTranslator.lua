--- @type string, WowUkrainizerInternals
local _, ns = ...;

local _G = _G

local PAGE_TRANSLATION, SPELL_PASSIVE_TRANSLATION = ns.PAGE_TRANSLATION, ns.SPELL_PASSIVE_TRANSLATION
local SPELL_RANK_TRANSLATION = ns.SPELL_RANK_TRANSLATION
local SPELL_GENERAL_TRANSLATION = ns.SPELL_GENERAL_TRANSLATION

local StartsWith, SetText = ns.StringUtil.StartsWith, ns.FontStringUtil.SetText
local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedSpellAttribute = ns.DbContext.Spells.GetTranslatedSpellAttribute
local GetTranslatedClass = ns.DbContext.Units.GetTranslatedClass
local GetTranslatedSpecialization = ns.DbContext.Units.GetTranslatedSpecialization
local GetTranslatedUISpellTooltip = ns.DbContext.Frames.GetTranslatedUISpellTooltip

local function getTranslatedSpellbookFrameText(default)
    return ns.DbContext.Frames.GetTranslatedUIText("Spellbook", default)
end

---@class SpellbookFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

local function updateSpellButtonCallback(spellButton)
    if (ns.SettingsProvider.IsNeedTranslateSpellNameInSpellbook()) then
        local spellString = spellButton.SpellName
        if (spellString) then
            SetText(spellString, GetTranslatedSpellName(spellString:GetText(), false))
        end
    end

    local subSpellNameString = spellButton.SpellSubName
    local subSpellName = subSpellNameString and subSpellNameString:GetText() or nil;
    if (subSpellName) then
        if (subSpellName == "Passive") then
            SetText(subSpellNameString, SPELL_PASSIVE_TRANSLATION)
        elseif (StartsWith(subSpellName, "Rank")) then
            SetText(subSpellNameString, string.gsub(subSpellName, "Rank", SPELL_RANK_TRANSLATION))
        else
            SetText(subSpellNameString, GetTranslatedSpellAttribute(subSpellName))
        end
    end

    if (spellButton.RequiredLevelString) then
        local requiredLevelStringText = spellButton.RequiredLevelString:GetText()
        spellButton.RequiredLevelString:SetText(getTranslatedSpellbookFrameText(requiredLevelStringText));
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
                    skillLineTab.tooltip = GetTranslatedClass(name, 1, gender);
                else
                    skillLineTab.tooltip = GetTranslatedSpecialization(name);
                end
            end
        end
    end
end

local function updatePagesCallback()
    SetText(SpellBookPageText, string.gsub(SpellBookPageText:GetText(), "Page", PAGE_TRANSLATION))
end

local function updateFrameCallback(...)
    local titleTextFontString = SpellBookFrame:GetTitleText()
    titleTextFontString:SetText(getTranslatedSpellbookFrameText(titleTextFontString:GetText()))

    SpellBookFrameTabButton1:SetText(getTranslatedSpellbookFrameText(SpellBookFrameTabButton1:GetText()))
    SpellBookFrameTabButton2:SetText(getTranslatedSpellbookFrameText(SpellBookFrameTabButton2:GetText()))
    if (SpellBookFrameTabButton3) then
        SpellBookFrameTabButton3:SetText(getTranslatedSpellbookFrameText(SpellBookFrameTabButton3:GetText()))
    end
end

local function unlearnButtonTooltipHook()
    local tooltipLine = _G["GameTooltipTextLeft1"]
    if (tooltipLine) then
        local text = tooltipLine:GetText()
        if (text) then tooltipLine:SetText(getTranslatedSpellbookFrameText(text)) end
    end
end

local function spellButtonTooltipHook(button)
    if (not button) then return end
    if (GameTooltip:GetOwner() ~= button) then return end

    for i = 1, GameTooltip:NumLines() do
        local lineLeft = _G["GameTooltipTextLeft" .. i]
        if (lineLeft) then
            local text = lineLeft:GetText() or ''
            if (text == _G["SPELLBOOK_SPELL_NOT_ON_ACTION_BAR"]) then
                lineLeft:SetText(GetTranslatedUISpellTooltip(_G["SPELLBOOK_SPELL_NOT_ON_ACTION_BAR"]))
            elseif (text == _G["CLICK_BINDING_NOT_AVAILABLE"]) then
                lineLeft:SetText(getTranslatedSpellbookFrameText(_G["CLICK_BINDING_NOT_AVAILABLE"]))
            end
        end
    end
    GameTooltip:Show()
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SPELLBOOK_FRAME_OPTION)
end

function translator:Init()
    SpellBookFrame_HelpPlate[1].ToolTipText = getTranslatedSpellbookFrameText(_G["SPELLBOOK_HELP_1"])
    SpellBookFrame_HelpPlate[2].ToolTipText = getTranslatedSpellbookFrameText(_G["SPELLBOOK_HELP_2"])
    SpellBookFrame_HelpPlate[3].ToolTipText = getTranslatedSpellbookFrameText(_G["SPELLBOOK_HELP_3"])

    for i = 1, 12, 1 do
        local spellButton = _G["SpellButton" .. i]

        hooksecurefunc(spellButton, "UpdateButton", function()
            if (not self:IsEnabled()) then return end
            updateSpellButtonCallback(spellButton)
        end)

        spellButton:HookScript("OnUpdate", function()
            if (not self:IsEnabled()) then return end
            spellButtonTooltipHook(spellButton)
        end)
    end

    hooksecurefunc("SpellBookFrame_UpdateSkillLineTabs", function()
        if (not self:IsEnabled()) then return end
        updateSkillLineTabsCallback()
    end)

    hooksecurefunc("SpellBookFrame_UpdatePages", function()
        if (not self:IsEnabled()) then return end
        updatePagesCallback()
    end)

    hooksecurefunc("SpellBookFrame_Update", function(_)
        if (not self:IsEnabled()) then return end
        updateFrameCallback()
    end)

    PrimaryProfession1.UnlearnButton:HookScript("OnEnter", function()
        if (not self:IsEnabled()) then return end
        unlearnButtonTooltipHook()
    end)

    PrimaryProfession2.UnlearnButton:HookScript("OnEnter", function()
        if (not self:IsEnabled()) then return end
        unlearnButtonTooltipHook()
    end)
end

ns.TranslationsManager:AddTranslator(translator)
