--- @class WowUkrainizerInternals
local ns = select(2, ...);

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

local _G = _G

local StartsWith, SetText = ns.StringUtil.StartsWith, ns.FontStringUtil.SetText
local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedSpellAttribute = ns.DbContext.Spells.GetTranslatedSpellAttribute
local GetTranslatedClass = ns.DbContext.Units.GetTranslatedClass
local GetTranslatedSpecialization = ns.DbContext.Units.GetTranslatedSpecialization
local GetTranslatedUISpellTooltip = ns.DbContext.Frames.GetTranslatedUISpellTooltip

local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation

local function getTranslatedSpellbookFrameText(default)
    return ns.DbContext.Frames.GetTranslatedUIText("Spellbook", default)
end

---@class SpellbookFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

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

function translator:PagedContentFrame_OnUpdate()
    for _, frame in PlayerSpellsFrame.SpellBookFrame.PagedSpellsFrame:EnumerateFrames() do
        if frame.HasValidData and frame:HasValidData() then
            if (ns.SettingsProvider.IsNeedTranslateSpellNameInSpellbook()) then
                print(frame.Name:GetText())
                UpdateTextWithTranslation(frame.Name, GetTranslatedSpellName)
            end

            if (frame.SubName:IsVisible()) then
                local subNameText = frame.SubName:GetText()
                if (subNameText and string.match(subNameText, TRADESKILL_RANK_HEADER)) then
                    local rank = C_Spell.GetSpellSkillLineAbilityRank(frame.spellBookItemInfo.spellID)
                    frame.SubName:SetText(string.format(GetTranslatedGlobalString(TRADESKILL_RANK_HEADER), rank))
                else
                    UpdateTextWithTranslation(frame.SubName, GetTranslatedGlobalString)
                end
            end

            if (frame.RequiredLevel:IsVisible()) then
                local requiredLevel = C_SpellBook.GetSpellBookItemLevelLearned(frame.slotIndex, frame.spellBank);
                frame.RequiredLevel:SetText(string.format(GetTranslatedGlobalString(SPELLBOOK_AVAILABLE_AT), requiredLevel))
            end
        else
            local elementData = frame:GetElementData()
            if (elementData.spellGroup) then
                if (elementData.spellGroup.specID) then
                    UpdateTextWithTranslation(frame.Text, GetTranslatedSpecialization)
                else
                    UpdateTextWithTranslation(frame.Text, GetTranslatedClass)
                end
            else
                UpdateTextWithTranslation(frame.Text, GetTranslatedGlobalString)
            end
        end
    end
end

local function PlayerSpellsFrame_UpdateFrameTitle(playerSpellsFrame)
    if playerSpellsFrame:IsInspecting() then
        local inspectUnit = playerSpellsFrame:GetInspectUnit();
        if inspectUnit then
            playerSpellsFrame:SetTitle(GetTranslatedGlobalString(TALENTS_INSPECT_FORMAT):format(UnitName(playerSpellsFrame:GetInspectUnit())));
        else
            playerSpellsFrame:SetTitle(GetTranslatedGlobalString(TALENTS_LINK_FORMAT):format(
                GetTranslatedSpecialization(playerSpellsFrame:GetSpecName()),
                GetTranslatedClass(playerSpellsFrame:GetClassName())));
        end
    else
        UpdateTextWithTranslation(playerSpellsFrame:GetTitleText(), GetTranslatedGlobalString)
    end
end

function translator:Init()
    local function OnAddOnLoaded(_, name)
        if (name == "Blizzard_PlayerSpells") then
            for i = 1, 3, 1 do
                UpdateTextWithTranslation(PlayerSpellsFrame.TabSystem.tabs[i].Text, GetTranslatedGlobalString)
            end

            local spellBookFrame = PlayerSpellsFrame.SpellBookFrame
            UpdateTextWithTranslation(spellBookFrame.CategoryTabSystem.tabs[1].Text, GetTranslatedClass)
            UpdateTextWithTranslation(spellBookFrame.CategoryTabSystem.tabs[2].Text, GetTranslatedGlobalString)
            UpdateTextWithTranslation(spellBookFrame.CategoryTabSystem.tabs[3].Text, GetTranslatedGlobalString)

            UpdateTextWithTranslation(spellBookFrame.HidePassivesCheckButton.Label, GetTranslatedGlobalString)
            UpdateTextWithTranslation(spellBookFrame.SearchBox.Instructions, GetTranslatedGlobalString)
            spellBookFrame.SearchBox.instructionText = GetTranslatedGlobalString(spellBookFrame.SearchBox.instructionText)

            local pagedSpellsFrame = spellBookFrame.PagedSpellsFrame
            pagedSpellsFrame.PagingControls.currentPageOnlyText = GetTranslatedGlobalString(pagedSpellsFrame.PagingControls.currentPageOnlyText)
            pagedSpellsFrame.PagingControls.currentPageWithMaxText = GetTranslatedGlobalString(pagedSpellsFrame.PagingControls.currentPageWithMaxText)

            hooksecurefunc(PlayerSpellsFrame, "UpdateFrameTitle", PlayerSpellsFrame_UpdateFrameTitle)

            pagedSpellsFrame:RegisterCallback(PagedContentFrameBaseMixin.Event.OnUpdate, self.PagedContentFrame_OnUpdate, self);

            eventHandler:Unregister(OnAddOnLoaded, "ADDON_LOADED")
        end
    end
    eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")

    -- SpellBookFrame_HelpPlate[1].ToolTipText = getTranslatedSpellbookFrameText(_G["SPELLBOOK_HELP_1"])
    -- SpellBookFrame_HelpPlate[2].ToolTipText = getTranslatedSpellbookFrameText(_G["SPELLBOOK_HELP_2"])
    -- SpellBookFrame_HelpPlate[3].ToolTipText = getTranslatedSpellbookFrameText(_G["SPELLBOOK_HELP_3"])

    -- hooksecurefunc("SpellBookFrame_Update", function(_)
    --     if (not self:IsEnabled()) then return end
    --     updateFrameCallback()
    -- end)
end

ns.TranslationsManager:AddTranslator(translator)
