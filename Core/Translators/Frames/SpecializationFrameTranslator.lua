local _, ns = ...;

local aceHook = LibStub("AceHook-3.0")
local _G = _G

local GetTranslatedSpecialization = ns.DbContext.Units.GetSpecialization

local eventHandler = ns.EventHandler:new()
local translator = class("SpecializationFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.SpecializationFrameTranslator = translator

local function GetTranslationOrDefault(default)
    return ns.DbContext.Frames.GetTranslationOrDefault("specialization", default)
end

local function translateFontString(fontString, translationFunc)
    if (fontString == nil) then return end
    local enText = fontString:GetText()

    if (enText == nil or enText == "") then return end
    ns.FontStringExtensions.UpdateFontString(fontString, translationFunc(enText))
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

    SPEC_STAT_STRINGS = {
        [LE_UNIT_STAT_STRENGTH] = GetTranslationOrDefault(_G["SPEC_FRAME_PRIMARY_STAT_STRENGTH"]),
        [LE_UNIT_STAT_AGILITY] = GetTranslationOrDefault(_G["SPEC_FRAME_PRIMARY_STAT_AGILITY"]),
        [LE_UNIT_STAT_INTELLECT] = GetTranslationOrDefault(_G["SPEC_FRAME_PRIMARY_STAT_INTELLECT"]),
    };

    hooksecurefunc(ClassTalentFrame.SpecTab, "UpdateSpecContents", function(specTab)
        -- TODO: To func
        for specContentFrame in specTab.SpecContentFramePool:EnumerateActive() do
            if (not self.isSpecContentFramesFontUpdated) then
                setDefaultFonts(specContentFrame)
            end
            translateFontString(specContentFrame.SpecName, GetTranslatedSpecialization)
            translateFontString(specContentFrame.SampleAbilityText, GetTranslationOrDefault)
            -- Description
            translateFontString(specContentFrame.ActivatedText, GetTranslationOrDefault)
            translateFontString(specContentFrame.ActivateButton.Text, GetTranslationOrDefault)
        end

        if (not self.isSpecContentFramesFontUpdated) then
            self.isSpecContentFramesFontUpdated = true
        end
    end)

    eventHandler:Unregister(OnAddOnLoaded, "ADDON_LOADED")
end

function translator:initialize()
    if (not self:IsEnabled()) then return end

    _G["DAMAGER"] = GetTranslationOrDefault(_G["DAMAGER"])
    _G["TANK"] = GetTranslationOrDefault(_G["TANK"])
    _G["HEALER"] = GetTranslationOrDefault(_G["HEALER"])
    -- WAR_MODE
    _G["WAR_MODE_CALL_TO_ARMS"] = GetTranslationOrDefault(_G["WAR_MODE_CALL_TO_ARMS"])
    _G["WAR_MODE_BONUS_INCENTIVE_TOOLTIP"] = GetTranslationOrDefault(_G["WAR_MODE_BONUS_INCENTIVE_TOOLTIP"])
    _G["PVP_LABEL_WAR_MODE"] = GetTranslationOrDefault(_G["PVP_LABEL_WAR_MODE"])
    _G["PVP_WAR_MODE_DESCRIPTION_FORMAT"] = GetTranslationOrDefault(_G["PVP_WAR_MODE_DESCRIPTION_FORMAT"])
    _G["PVP_WAR_MODE_ENABLED"] = GetTranslationOrDefault(_G["PVP_WAR_MODE_ENABLED"])
    -- Tabs
    _G["TALENT_FRAME_TAB_LABEL_SPEC"] = GetTranslationOrDefault(_G["TALENT_FRAME_TAB_LABEL_SPEC"])
    _G["TALENT_FRAME_TAB_LABEL_TALENTS"] = GetTranslationOrDefault(_G["TALENT_FRAME_TAB_LABEL_TALENTS"])
    -- Common
    _G["TALENT_FRAME_CONFIRM_CLOSE"] = GetTranslationOrDefault(_G["TALENT_FRAME_CONFIRM_CLOSE"])
    _G["TALENTS_INSPECT_FORMAT"] = GetTranslationOrDefault(_G["TALENTS_INSPECT_FORMAT"])
    _G["TALENTS_LINK_FORMAT"] = GetTranslationOrDefault(_G["TALENTS_LINK_FORMAT"])
    _G["SPECIALIZATION"] = GetTranslationOrDefault(_G["SPECIALIZATION"])
    _G["TALENTS"] = GetTranslationOrDefault(_G["TALENTS"])

    -- TODO: Move to base frame
    _G["CONTINUE"] = GetTranslationOrDefault(_G["CONTINUE"])
    _G["CANCEL"] = GetTranslationOrDefault(_G["CANCEL"])


    --_G[""] = GetTranslationOrDefault(_G[""])

    eventHandler:Register(function(_, name)
        OnAddOnLoaded(self, name)
    end, "ADDON_LOADED")
end
