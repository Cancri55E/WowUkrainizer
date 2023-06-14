local _, ns = ...;

local _G = _G

local GetSpellNameOrDefault = ns.DbContext.Spells.GetSpellNameOrDefault
local GetRole, GetAttribute = ns.DbContext.Units.GetRole, ns.DbContext.Units.GetAttribute
local GetSpecialization, GetClass = ns.DbContext.Units.GetSpecialization, ns.DbContext.Units.GetClass
local GetSpecializationNote = ns.DbContext.Units.GetSpecializationNote
local GetTranslationOrDefault = ns.DbContext.Frames.GetTranslationOrDefault
local SetText = ns.FontStringExtensions.SetText

local eventHandler = ns.EventHandler:new()
local aceHook = LibStub("AceHook-3.0")

local translator = class("ClassTalentFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.ClassTalentFrameTranslator = translator

local function getTranslationOrDefault(default)
    return GetTranslationOrDefault("class_talent", default)
end

local function translateFontStringText(fontString, translationFunc)
    if (fontString == nil) then return end
    local text = fontString:GetText()

    if (text == nil or text == "") then return end
    SetText(fontString, translationFunc(text))
end

local function translateGameTooltipText(self, owner)
    if (not self:IsEnabled()) then return end
    if (not owner) then return end
    if (GameTooltip:GetOwner() ~= owner) then return end

    for i = 1, GameTooltip:NumLines() do
        local lineLeft = _G["GameTooltipTextLeft" .. i]
        if (lineLeft) then
            lineLeft:SetText(getTranslationOrDefault(lineLeft:GetText() or ''))
        end
    end
    GameTooltip:Show()
end

local function translateStaticPopup(self, extraHeight)
    if (not self:IsEnabled()) then return end

    local popup = _G["StaticPopup1"]
    if (not popup) then return end

    translateFontStringText(popup.text, getTranslationOrDefault)
    translateFontStringText(popup.button1.Text, getTranslationOrDefault)
    translateFontStringText(popup.button2.Text, getTranslationOrDefault)

    if (extraHeight) then
        popup:SetHeight(popup:GetHeight() + extraHeight);
    end
end

local function updateSpecContentsHook(self, specTab)
    if (not self:IsEnabled()) then return end
    for specContentFrame in specTab.SpecContentFramePool:EnumerateActive() do
        local sex = UnitSex("player");
        local _, _, description, _, _, primaryStat = GetSpecializationInfo(specContentFrame.specIndex, false, false,
            nil, sex);
        if primaryStat and primaryStat ~= 0 then
            local translatedStat = GetAttribute(SPEC_STAT_STRINGS[primaryStat])
            local translatedDescription = GetSpecializationNote(description) ..
                "|n" .. getTranslationOrDefault(_G["SPEC_FRAME_PRIMARY_STAT"]):format(translatedStat)
            SetText(specContentFrame.Description, translatedDescription)
        end
        translateFontStringText(specContentFrame.SpecName, GetSpecialization)
        translateFontStringText(specContentFrame.SampleAbilityText, getTranslationOrDefault)
        translateFontStringText(specContentFrame.ActivatedText, getTranslationOrDefault)
        translateFontStringText(specContentFrame.ActivateButton.Text, getTranslationOrDefault)
        translateFontStringText(specContentFrame.RoleName, GetRole)
    end
end

local function updateFrameTitleHook(self, classTalentFrame)
    if (not self:IsEnabled()) then return end

    local titleText = ""
    if classTalentFrame:IsInspecting() then
        local inspectUnit = classTalentFrame:GetInspectUnit();
        if inspectUnit then
            titleText = getTranslationOrDefault(_G["TALENTS_INSPECT_FORMAT"]):format(UnitName(inspectUnit));
        else
            local classNameTranslated = GetClass(classTalentFrame:GetClassName(), 1, 2) -- TODO: Sex ?
            local specNameTranslated = GetSpecialization(classTalentFrame:GetSpecName())
            titleText = getTranslationOrDefault(_G["TALENTS_LINK_FORMAT"]):format(specNameTranslated, classNameTranslated);
        end
    elseif classTalentFrame:GetTab() == classTalentFrame.specTabID then
        titleText = getTranslationOrDefault(_G["SPECIALIZATION"]);
    else -- tabID == self.talentTabID
        titleText = getTranslationOrDefault(_G["TALENTS"]);
    end
    classTalentFrame:SetTitle(titleText)
end

local function talentsTab_OnShow(self, talentsTab)
    if (not self:IsEnabled()) then return end

    local currencyDisplayFormat = getTranslationOrDefault(_G["TALENT_FRAME_CURRENCY_DISPLAY_FORMAT"])

    local classNameTranslated = GetClass(talentsTab:GetClassName(), 1, 2) -- TODO: Sex ?
    talentsTab.ClassCurrencyDisplay.CurrencyLabel:SetText(
        string.upper(currencyDisplayFormat:format(classNameTranslated)));

    local specNameTranslated = GetSpecialization(talentsTab:GetSpecName())
    talentsTab.SpecCurrencyDisplay.CurrencyLabel:SetText(
        string.upper(currencyDisplayFormat:format(specNameTranslated)));
end

local function classTalentFrame_OnShow(self, classTalentFrame)
    if (not self:IsEnabled()) then return end

    classTalentFrame:GetTalentsTabButton():SetText(getTranslationOrDefault(_G["TALENT_FRAME_TAB_LABEL_TALENTS"]))
    classTalentFrame:GetTabButton(classTalentFrame.specTabID):SetText(getTranslationOrDefault(_G
        ["TALENT_FRAME_TAB_LABEL_SPEC"]))
end

local function pvpTalentList_OnUpdate(self, pvpTalentList)
    if (not self:IsEnabled()) then return end
    pvpTalentList.ScrollBox:ForEachFrame(function(listButton)
        listButton.Name:SetText(GetSpellNameOrDefault(listButton.talentInfo.name));
    end);
end

local function onBlizzardClassTalentUILoaded(self)
    local function loadoutDropDownDisabledCallbackHook(originDisabledCallback)
        return function()
            local disabled, title, text, warning = originDisabledCallback()
            if (warning) then warning = getTranslationOrDefault(warning) end
            return disabled, title, text, warning
        end
    end

    ClassTalentFrame.TalentsTab.ApplyButton.Text:SetText(getTranslationOrDefault(_G["TALENT_FRAME_APPLY_BUTTON_TEXT"]))
    ClassTalentFrame.TalentsTab.InspectCopyButton.Text:SetText(getTranslationOrDefault(_G
        ["TALENT_FRAME_INSPECT_COPY_BUTTON_TEXT"]))
    ClassTalentFrame.TalentsTab.UndoButton.tooltipText = getTranslationOrDefault(_G
        ["TALENT_FRAME_DISCARD_CHANGES_BUTTON_TOOLTIP"])
    ClassTalentFrame.TalentsTab.LoadoutDropDown.editEntryTooltip = getTranslationOrDefault(_G
        ["TALENT_FRAME_DROP_DOWN_TOOLTIP_EDIT"])

    for _, value in ipairs(ClassTalentFrame.TalentsTab.LoadoutDropDown.sentinelKeyToInfo) do
        value.disabledCallback = loadoutDropDownDisabledCallbackHook(value.disabledCallback)
    end

    hooksecurefunc(ClassTalentFrame, "UpdateFrameTitle", function(frame)
        updateFrameTitleHook(self, frame)
    end)

    hooksecurefunc(ClassTalentFrame, "CheckConfirmResetAction", function(...)
        translateStaticPopup(self)
    end)

    hooksecurefunc(ClassTalentFrame.SpecTab, "UpdateSpecContents", function(tab)
        updateSpecContentsHook(self, tab)
    end)

    hooksecurefunc(ClassTalentFrame.TalentsTab, "CheckConfirmStarterBuildDeviation", function(...)
        translateStaticPopup(self, 16)
    end)

    hooksecurefunc(ClassTalentFrame.TalentsTab.WarmodeButton, "Update", function(warmodeButton)
        translateGameTooltipText(self, warmodeButton)
    end)

    hooksecurefunc(TalentFrameGateMixin, "OnEnter", function(mixin)
        translateGameTooltipText(self, mixin)
    end)

    ClassTalentFrame:HookScript("OnShow", function(classTalentFrame)
        classTalentFrame_OnShow(self, classTalentFrame)
    end)

    ClassTalentFrame.TalentsTab:HookScript("OnShow", function(talentsTab)
        talentsTab_OnShow(self, talentsTab)
    end)

    ClassTalentFrame.TalentsTab.ApplyButton:HookScript("OnEnter", function(applyButton)
        translateGameTooltipText(self, applyButton)
    end)

    ClassTalentFrame.TalentsTab.WarmodeButton:HookScript("OnEnter", function(warmodeButton)
        translateGameTooltipText(self, warmodeButton)
    end)

    ClassTalentFrame.TalentsTab.WarmodeButton.WarmodeIncentive:HookScript("OnEnter", function(warmodeIncentive)
        translateGameTooltipText(self, warmodeIncentive)
    end)

    ClassTalentFrame.TalentsTab.PvPTalentList:HookScript("OnUpdate", function(pvpTalentList)
        pvpTalentList_OnUpdate(self, pvpTalentList)
    end)

    for i = 1, 3, 1 do
        ClassTalentFrame.TalentsTab.PvPTalentSlotTray["TalentSlot" .. i]:HookScript("OnEnter", function(talentSlot)
            translateGameTooltipText(self, talentSlot)
        end)
    end
end

function translator:initialize()
    local function onAddonLoaded(_, addonName)
        if (addonName ~= 'Blizzard_ClassTalentUI') then return end
        onBlizzardClassTalentUILoaded(self)
        eventHandler:Unregister(onAddonLoaded, "ADDON_LOADED")
    end

    aceHook:RawHook(TalentButtonUtil, "GetStyleForSearchMatchType", function(matchType)
        local result = aceHook.hooks[TalentButtonUtil]["GetStyleForSearchMatchType"](matchType)
        if (result) then result.tooltipText = getTranslationOrDefault(result.tooltipText) end
        return result
    end, true)

    eventHandler:Register(onAddonLoaded, "ADDON_LOADED")
end

function translator:OnEnabled()
    local constants = {
        -- -- Talents
        -- "TALENT_FRAME_RESET_BUTTON_DROPDOWN_TITLE",
        -- "TALENT_FRAME_RESET_BUTTON_DROPDOWN_LEFT",
        -- "TALENT_FRAME_RESET_BUTTON_DROPDOWN_RIGHT",
        -- "TALENT_FRAME_RESET_BUTTON_DROPDOWN_ALL",
    }
    for _, const in ipairs(constants) do
        _G[const] = getTranslationOrDefault(_G[const])
    end
end
