local _, ns = ...;

local _G = _G

local GetSpecialization = ns.DbContext.Units.GetSpecialization
local GetSpecializationNote = ns.DbContext.Units.GetSpecializationNote
local GetRole = ns.DbContext.Units.GetRole
local GetAttribute = ns.DbContext.Units.GetAttribute
local GetTranslationOrDefault = ns.DbContext.Frames.GetTranslationOrDefault

local SetText = ns.FontStringExtensions.SetText

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
    SetText(fontString, translationFunc(enText))
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
                "|n" .. SPEC_FRAME_PRIMARY_STAT:format(translatedStat)
            SetText(specContentFrame.Description, translatedDescription)
        end
        translateFontStringText(specContentFrame.SpecName, GetSpecialization)
        translateFontStringText(specContentFrame.SampleAbilityText, getTranslationOrDefault)
        translateFontStringText(specContentFrame.ActivatedText, getTranslationOrDefault)
        translateFontStringText(specContentFrame.ActivateButton.Text, getTranslationOrDefault)
        translateFontStringText(specContentFrame.RoleName, GetRole)
    end
end

local function onBlizzardClassTalentUILoaded(self)
    hooksecurefunc(ClassTalentFrame.SpecTab, "UpdateSpecContents", function(specTab)
        updateSpecContentsHook(self, specTab)
    end)
end

function translator:initialize()
    local function onAddonLoaded(_, addonName)
        if (addonName ~= 'Blizzard_ClassTalentUI') then return end
        onBlizzardClassTalentUILoaded(self)
        eventHandler:Unregister(onAddonLoaded, "ADDON_LOADED")
    end
    eventHandler:Register(onAddonLoaded, "ADDON_LOADED")
end

function translator:OnEnabled()
    local constants = {
        -- Tabs and Title
        "TALENT_FRAME_TAB_LABEL_SPEC",
        "TALENT_FRAME_TAB_LABEL_TALENTS",
        "SPECIALIZATION",
        "TALENTS",
        -- Spec
        "SPEC_FRAME_PRIMARY_STAT",
        -- Talents
        "TALENT_FRAME_RESET_BUTTON_DROPDOWN_TITLE",
        "TALENT_FRAME_RESET_BUTTON_DROPDOWN_LEFT",
        "TALENT_FRAME_RESET_BUTTON_DROPDOWN_RIGHT",
        "TALENT_FRAME_RESET_BUTTON_DROPDOWN_ALL",
        "TALENT_FRAME_NEW_LOADOUT_DISABLED_TOOLTIP",
        "TALENT_FRAME_EXPORT_LOADOUT_DISABLED_TOOLTIP",
        "TALENT_FRAME_DROP_DOWN_DEFAULT",
        "TALENT_FRAME_DROP_DOWN_NEW_LOADOUT",
        "TALENT_FRAME_DROP_DOWN_TOOLTIP_EDIT",
        "TALENT_FRAME_DROP_DOWN_IMPORT",
        "TALENT_FRAME_DROP_DOWN_EXPORT_CLIPBOARD",
        "TALENT_FRAME_DROP_DOWN_EXPORT_CHAT_LINK",
        "TALENT_FRAME_DROP_DOWN_STARTER_BUILD_TOOLTIP",
        "TALENT_FRAME_DROP_DOWN_STARTER_BUILD",
        -- warmode
        "WAR_MODE_CALL_TO_ARMS",
        "WAR_MODE_BONUS_INCENTIVE_TOOLTIP",
        "PVP_LABEL_WAR_MODE",
        "PVP_WAR_MODE_DESCRIPTION_FORMAT",
        "PVP_WAR_MODE_ENABLED",
        "TALENT_FRAME_CONFIRM_CLOSE",
        -- TODO: Other?
        -- "TALENTS_INSPECT_FORMAT",
        -- "TALENTS_LINK_FORMAT"
    }
    for _, const in ipairs(constants) do
        _G[const] = getTranslationOrDefault(_G[const])
    end
end
