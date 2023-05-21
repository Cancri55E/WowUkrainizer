local _, ns = ...;

local GetSpecialization = ns.DbContext.Units.GetSpecialization
local GetSpecializationNote = ns.DbContext.Units.GetSpecializationNote
local GetRole = ns.DbContext.Units.GetRole
local GetAttribute = ns.DbContext.Units.GetAttribute
local GetTranslationOrDefault = ns.DbContext.Frames.GetTranslationOrDefault

local SetFont = ns.FontStringExtensions.SetFont
local UpdateFontString = ns.FontStringExtensions.UpdateFontString

local eventHandler = ns.EventHandler:new()
local translator = class("ClassTalentFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.ClassTalentFrameTranslator = translator

local function getTranslationOrDefault(default)
    return GetTranslationOrDefault("class_talent", default)
end

local function translateFontStringText(fontString, translationFunc)
    if (fontString == nil) then return end
    local enText = fontString:GetText()

    if (enText == nil or enText == "") then return end
    UpdateFontString(fontString, translationFunc(enText))
end

local function updateSpecContentsHook(self, specTab)
    local function updateFontsInSpecContentFrame(frame)
        SetFont(frame.SpecName, ns.DefaultFontName, 1.15)
        SetFont(frame.SampleAbilityText, ns.DefaultFontName, 1.1)
        SetFont(frame.ActivatedText, ns.DefaultFontName, 1.1)
        SetFont(frame.RoleName, ns.DefaultFontName, 1.1)
        SetFont(frame.Description, ns.DefaultFontName, 1.1)
        SetFont(frame.ActivateButton.Text, ns.DefaultFontName, 1.1)
    end

    if (not self:IsEnabled()) then return end

    for specContentFrame in specTab.SpecContentFramePool:EnumerateActive() do
        local fontUpdatedFieldName = "isSpecContentFrame" .. specContentFrame.specIndex .. "FontUpdated"
        if (not self[fontUpdatedFieldName]) then
            updateFontsInSpecContentFrame(specContentFrame)
            self[fontUpdatedFieldName] = true
        end

        local sex = UnitSex("player");
        local _, _, description, _, _, primaryStat = GetSpecializationInfo(specContentFrame.specIndex, false, false,
            nil, sex);
        if primaryStat and primaryStat ~= 0 then
            local translatedStat = GetAttribute(SPEC_STAT_STRINGS[primaryStat])
            local translatedDescription = GetSpecializationNote(description) ..
                "|n" .. SPEC_FRAME_PRIMARY_STAT:format(translatedStat)
            UpdateFontString(specContentFrame.Description, translatedDescription)
        end
        translateFontStringText(specContentFrame.SpecName, GetSpecialization)
        translateFontStringText(specContentFrame.SampleAbilityText, getTranslationOrDefault)
        translateFontStringText(specContentFrame.ActivatedText, getTranslationOrDefault)
        translateFontStringText(specContentFrame.ActivateButton.Text, getTranslationOrDefault)
        translateFontStringText(specContentFrame.RoleName, GetRole)
    end
end

local function onBlizzardClassTalentUILoaded(self)
    SetFont(ClassTalentFrame.TitleContainer.TitleText, ns.DefaultFontName, 1.03)
    SetFont(ClassTalentFrame.TabSystem.tabs[1].Text, ns.DefaultFontName, 1.05)
    SetFont(ClassTalentFrame.TabSystem.tabs[2].Text, ns.DefaultFontName, 1.05)

    SPEC_FRAME_PRIMARY_STAT = getTranslationOrDefault(SPEC_FRAME_PRIMARY_STAT)

    hooksecurefunc(ClassTalentFrame.SpecTab, "UpdateSpecContents",
        function(specTab) updateSpecContentsHook(self, specTab) end)
end

function translator:initialize()
    local function onAddonLoaded(_, addonName)
        if (addonName ~= 'Blizzard_ClassTalentUI') then return end
        onBlizzardClassTalentUILoaded(self)
        eventHandler:Unregister(onAddonLoaded, "ADDON_LOADED")
    end

    -- WAR_MODE
    WAR_MODE_CALL_TO_ARMS = getTranslationOrDefault(WAR_MODE_CALL_TO_ARMS)
    WAR_MODE_BONUS_INCENTIVE_TOOLTIP = getTranslationOrDefault(WAR_MODE_BONUS_INCENTIVE_TOOLTIP)
    PVP_LABEL_WAR_MODE = getTranslationOrDefault(PVP_LABEL_WAR_MODE)
    PVP_WAR_MODE_DESCRIPTION_FORMAT = getTranslationOrDefault(PVP_WAR_MODE_DESCRIPTION_FORMAT)
    PVP_WAR_MODE_ENABLED = getTranslationOrDefault(PVP_WAR_MODE_ENABLED)
    -- Tabs and Title
    TALENT_FRAME_TAB_LABEL_SPEC = getTranslationOrDefault(TALENT_FRAME_TAB_LABEL_SPEC)
    TALENT_FRAME_TAB_LABEL_TALENTS = getTranslationOrDefault(TALENT_FRAME_TAB_LABEL_TALENTS)
    SPECIALIZATION = getTranslationOrDefault(SPECIALIZATION)
    TALENTS = getTranslationOrDefault(TALENTS)
    -- Other
    TALENT_FRAME_CONFIRM_CLOSE = getTranslationOrDefault(TALENT_FRAME_CONFIRM_CLOSE)
    TALENTS_INSPECT_FORMAT = getTranslationOrDefault(TALENTS_INSPECT_FORMAT)
    TALENTS_LINK_FORMAT = getTranslationOrDefault(TALENTS_LINK_FORMAT)

    eventHandler:Register(onAddonLoaded, "ADDON_LOADED")
end
