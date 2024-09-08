--- @class WowUkrainizerInternals
local ns = select(2, ...);

local _G = _G

local Uft8Upper = ns.StringUtil.Uft8Upper
local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedSpecialization = ns.DbContext.Player.GetTranslatedSpecialization
local GetTranslatedSpecializationNote = ns.DbContext.Player.GetTranslatedSpecializationNote
local GetTranslatedClass = ns.DbContext.Player.GetTranslatedClass
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

local heroSpecFrameTranslated = {}

---@class ClassTalentFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

-- Translates the text in GameTooltip when it's attached to a specific owner
local function TranslateTooltips(owner)
    if (GameTooltip:GetOwner() ~= owner) then return end

    for i = 1, GameTooltip:NumLines() do
        local lineLeft = _G["GameTooltipTextLeft" .. i]
        if (lineLeft) then
            UpdateTextWithTranslation(lineLeft, GetTranslatedGlobalString)
        end
    end
    GameTooltip:Show()
end

-- Sets up hooks for various talent frame functions to enable translation
local function HookTalentFrameFunctions(talentsFrame)
    -- Updates and translates the display of class and spec
    local function TalentsFrame_RefreshCurrencyDisplay()
        UpdateTextWithTranslation(talentsFrame.ClassCurrencyDisplay.CurrencyLabel,
            function(fontStringObject)
                local className = GetTranslatedClass(fontStringObject, 1)
                return Uft8Upper(className)
            end)
        UpdateTextWithTranslation(talentsFrame.SpecCurrencyDisplay.CurrencyLabel,
            function(fontStringObject)
                local specName = GetTranslatedSpecialization(fontStringObject)
                return Uft8Upper(specName)
            end)
    end

    -- Updates and translates the hero spec required text
    local function HeroTalentsContainer_UpdateHeroSpecButton()
        local container = talentsFrame.HeroTalentsContainer
        container.LockedLabel2:SetText(GetTranslatedGlobalString(HERO_TALENTS_LOCKED_2):format(container.heroSpecsRequiredLevel))
        if (container.activeSubTreeInfo) then
            container.HeroSpecLabel:SetText(Uft8Upper(GetTranslatedSpecialization(container.activeSubTreeInfo.name)))
        end
    end

    -- Translates PvP talent names in the talent list
    local function PvPTalentList_OnUpdate()
        talentsFrame.PvPTalentList.ScrollBox:ForEachFrame(function(listButton)
            listButton.Name:SetText(GetTranslatedSpellName(listButton.talentInfo.name, false));
        end);
    end

    local function HeroTalentsSelectionDialog_ShowDialog(dialog)
        for subTreeID, specFrame in pairs(dialog.specFramesBySubTreeID) do
            UpdateTextWithTranslation(specFrame.SpecName, function(specName)
                local tranlatedSpecName = GetTranslatedSpecialization(specName)
                return Uft8Upper(tranlatedSpecName)
            end)

            UpdateTextWithTranslation(specFrame.Description, GetTranslatedSpecializationNote)

            if (not heroSpecFrameTranslated[subTreeID]) then
                UpdateTextWithTranslation(specFrame.ActivatedText, GetTranslatedGlobalString)
                UpdateTextWithTranslation(specFrame.ActivateButton.Text, GetTranslatedGlobalString)
                UpdateTextWithTranslation(specFrame.ApplyChangesButton.Text, GetTranslatedGlobalString)
                UpdateTextWithTranslation(specFrame.CurrencyFrame.LabelText, GetTranslatedGlobalString)

                heroSpecFrameTranslated[subTreeID] = true
            end
        end
    end

    hooksecurefunc(HeroTalentsSelectionDialog, "ShowDialog", HeroTalentsSelectionDialog_ShowDialog)
    hooksecurefunc(TalentFrameGateMixin, "OnEnter", TranslateTooltips)
    hooksecurefunc(talentsFrame, "RefreshCurrencyDisplay", TalentsFrame_RefreshCurrencyDisplay)
    hooksecurefunc(talentsFrame.HeroTalentsContainer, "UpdateHeroSpecButton", HeroTalentsContainer_UpdateHeroSpecButton)
    talentsFrame.PvPTalentList:HookScript("OnUpdate", PvPTalentList_OnUpdate)

    -- TODO: talentsFrame.HeroTalentsContainer.CollapseButton OnEnter Tooltip
end

-- Translates static text elements in the talent frame
local function TranslateStaticElements(talentsFrame)
    UpdateTextWithTranslation(talentsFrame.HeroTalentsContainer.ChooseSpecLabel1, GetTranslatedGlobalString)
    UpdateTextWithTranslation(talentsFrame.HeroTalentsContainer.ChooseSpecLabel2, GetTranslatedGlobalString)
    UpdateTextWithTranslation(talentsFrame.HeroTalentsContainer.LockedLabel1, GetTranslatedGlobalString)
    UpdateTextWithTranslation(talentsFrame.ApplyButton.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(talentsFrame.InspectCopyButton.Text, GetTranslatedGlobalString)
    talentsFrame.UndoButton.tooltipText = GetTranslatedGlobalString(talentsFrame.UndoButton.tooltipText)
end

-- Sets up tooltip translation hooks for various frame elements
local function HookTooltipTranslations(talentsFrame)
    for i = 1, 3, 1 do
        talentsFrame.PvPTalentSlotTray["TalentSlot" .. i]:HookScript("OnEnter", TranslateTooltips)
    end
    talentsFrame.ApplyButton:HookScript("OnEnter", TranslateTooltips)
    hooksecurefunc(talentsFrame.WarmodeButton, "Update", TranslateTooltips)
    talentsFrame.WarmodeButton:HookScript("OnEnter", TranslateTooltips)
    talentsFrame.WarmodeButton.WarmodeIncentive:HookScript("OnEnter", TranslateTooltips)
end

-- Configures translations for static popup dialogs
local function SetupStaticPopupTranslations()
    -- Translates text in a static popup dialog and adjusts its height if necessary
    local function TranslateStaticPopup(extraHeight)
        local popup = _G["StaticPopup1"]
        if (not popup) then return end

        UpdateTextWithTranslation(popup.text, GetTranslatedGlobalString)
        UpdateTextWithTranslation(popup.button1.Text, GetTranslatedGlobalString)
        UpdateTextWithTranslation(popup.button2.Text, GetTranslatedGlobalString)

        if (extraHeight) then
            popup:SetHeight(popup:GetHeight() + extraHeight);
        end
    end

    hooksecurefunc(PlayerSpellsFrame, "CheckConfirmResetAction", function(...) TranslateStaticPopup(16) end)
    hooksecurefunc(PlayerSpellsFrame.TalentsFrame, "CheckConfirmStarterBuildDeviation", function(...) TranslateStaticPopup(16) end)
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_CLASS_TALENTS_FRAME_OPTION)
end

function translator:Init()
    local function onAddonLoaded(_, addonName)
        if (addonName ~= 'Blizzard_PlayerSpells') then return end

        local talentsFrame = PlayerSpellsFrame.TalentsFrame

        HookTalentFrameFunctions(talentsFrame)
        TranslateStaticElements(talentsFrame)
        HookTooltipTranslations(talentsFrame)
        SetupStaticPopupTranslations()

        eventHandler:Unregister(onAddonLoaded, "ADDON_LOADED")
    end

    eventHandler:Register(onAddonLoaded, "ADDON_LOADED")
end

ns.TranslationsManager:AddTranslator(translator)
