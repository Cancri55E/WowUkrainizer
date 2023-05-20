local _, ns = ...;

local GetSpecialization = ns.DbContext.Units.GetSpecialization
local GetSpecializationNote = ns.DbContext.Units.GetSpecializationNote
local GetRole = ns.DbContext.Units.GetRole
local GetAttribute = ns.DbContext.Units.GetAttribute
local UpdateFontString = ns.FontStringExtensions.UpdateFontString
local GetTranslationOrDefault = ns.DbContext.Frames.GetTranslationOrDefault

local eventHandler = ns.EventHandler:new()
local translator = class("SpecializationFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.SpecializationFrameTranslator = translator

local function getTranslationOrDefault(default)
    return GetTranslationOrDefault("specialization", default)
end

local function translateFontString(fontString, translationFunc)
    if (fontString == nil) then return end
    local enText = fontString:GetText()

    if (enText == nil or enText == "") then return end
    UpdateFontString(fontString, translationFunc(enText))
end

local function setDefaultFonts(specContentFrame)
    local function updateFont(obj, fontName, scale)
        local _, height, flags = obj:GetFont()
        obj:SetFont(fontName, height * scale, flags)
    end

    updateFont(specContentFrame.SpecName, ns.DefaultFontName, 1.15)
    updateFont(specContentFrame.SampleAbilityText, ns.DefaultFontName, 1.1)
    updateFont(specContentFrame.ActivatedText, ns.DefaultFontName, 1.1)
    updateFont(specContentFrame.RoleName, ns.DefaultFontName, 1.1)
    updateFont(specContentFrame.Description, ns.DefaultFontName, 1.1)
    updateFont(specContentFrame.ActivateButton.Text, ns.DefaultFontName, 1.1)
end

local function OnAddOnLoaded(self, addonName)
    if (addonName ~= 'Blizzard_ClassTalentUI') then return end

    self.isSpecContentFramesFontUpdated = false
    SPEC_FRAME_PRIMARY_STAT = getTranslationOrDefault(SPEC_FRAME_PRIMARY_STAT)

    hooksecurefunc(ClassTalentFrame.SpecTab, "UpdateSpecContents", function(specTab)
        print("UpdateSpecContents")
        if (not self:IsEnabled()) then return end
        print("UpdateSpecContents enabled")
        -- TODO: To func
        for specContentFrame in specTab.SpecContentFramePool:EnumerateActive() do
            if (not self.isSpecContentFramesFontUpdated) then
                setDefaultFonts(specContentFrame)
            end
            translateFontString(specContentFrame.SpecName, GetSpecialization)
            translateFontString(specContentFrame.SampleAbilityText, getTranslationOrDefault)
            translateFontString(specContentFrame.ActivatedText, getTranslationOrDefault)
            translateFontString(specContentFrame.ActivateButton.Text, getTranslationOrDefault)
            translateFontString(specContentFrame.RoleName, GetRole)

            local sex = UnitSex("player");
            local _, _, description, _, _, primaryStat = GetSpecializationInfo(specContentFrame.specIndex, false, false,
                nil, sex);
            if primaryStat and primaryStat ~= 0 then
                local translatedStat = GetAttribute(SPEC_STAT_STRINGS[primaryStat])
                local translatedDescription = GetSpecializationNote(description) ..
                    "|n" .. SPEC_FRAME_PRIMARY_STAT:format(translatedStat)
                UpdateFontString(specContentFrame.Description, translatedDescription)
            end
        end

        if (not self.isSpecContentFramesFontUpdated) then
            self.isSpecContentFramesFontUpdated = true
        end
    end)

    eventHandler:Unregister(OnAddOnLoaded, "ADDON_LOADED")
end

function translator:initialize()
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
    -- TODO: Move to base frame
    CONTINUE = getTranslationOrDefault(CONTINUE)
    CANCEL = getTranslationOrDefault(CANCEL)

    --_G[""] = GetTranslationOrDefault(_G[""])

    eventHandler:Register(function(_, name)
        OnAddOnLoaded(self, name)
    end, "ADDON_LOADED")
end
