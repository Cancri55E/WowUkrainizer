local _, ns = ...;

local _G = _G

local GetRole, GetAttribute = ns.DbContext.Units.GetRole, ns.DbContext.Units.GetAttribute
local GetSpecialization, GetClass = ns.DbContext.Units.GetSpecialization, ns.DbContext.Units.GetClass
local GetSpecializationNote = ns.DbContext.Units.GetSpecializationNote
local GetTranslationOrDefault = ns.DbContext.Frames.GetTranslationOrDefault
local SetText = ns.FontStringExtensions.SetText
local ReconstructStringWithNumerics = ns.StringNormalizer.ReconstructStringWithNumerics

local eventHandler = ns.EventHandler:new()
local aceHook = LibStub("AceHook-3.0")

local translator = class("ClassTalentFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.ClassTalentFrameTranslator = translator

local function getTranslationOrDefault(default)
    return GetTranslationOrDefault("class_talent", default)
end

local function updateSpecContentsHook(self, specTab)
    local function translateFontStringText(fontString, translationFunc)
        if (fontString == nil) then return end
        local enText = fontString:GetText()

        if (enText == nil or enText == "") then return end
        SetText(fontString, translationFunc(enText))
    end

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

local function refreshCurrencyDisplayHook(self)
    if (not self:IsEnabled()) then return end

    local classNameTranslated = GetClass(ClassTalentFrame.TalentsTab:GetClassName(), 1, 2)
    ClassTalentFrame.TalentsTab.ClassCurrencyDisplay:SetPointTypeText(string.upper(classNameTranslated));

    local specNameTranslated = GetSpecialization(ClassTalentFrame.TalentsTab:GetSpecName())
    ClassTalentFrame.TalentsTab.SpecCurrencyDisplay:SetPointTypeText(string.upper(specNameTranslated));
end

local function onBlizzardClassTalentUILoaded(self)
    hooksecurefunc(ClassTalentFrame.SpecTab, "UpdateSpecContents", function(specTab)
        updateSpecContentsHook(self, specTab)
    end)
    hooksecurefunc(ClassTalentFrame.TalentsTab, "RefreshCurrencyDisplay", function()
        refreshCurrencyDisplayHook(self)
    end)
end

function translator:initialize()
    local function onAddonLoaded(_, addonName)
        if (addonName ~= 'Blizzard_ClassTalentUI') then return end
        onBlizzardClassTalentUILoaded(self)
        eventHandler:Unregister(onAddonLoaded, "ADDON_LOADED")
    end

    -- Translate the TALENT_BUTTON_TOOLTIP_* consts for action
    aceHook:RawHook(TalentButtonUtil, "GetTooltipForActionBarStatus", function(status)
        local statusText = aceHook.hooks[TalentButtonUtil]["GetTooltipForActionBarStatus"](status)
        return getTranslationOrDefault(statusText)
    end, true)

    -- Translate the TALENT_FRAME_SEARCH_TOOLTIP_* consts
    aceHook:RawHook(TalentButtonUtil, "GetStyleForSearchMatchType", function(matchType)
        local result = aceHook.hooks[TalentButtonUtil]["GetStyleForSearchMatchType"](matchType)
        if (result) then
            result.tooltipText = getTranslationOrDefault(result.tooltipText)
        end
        return result
    end, true)

    eventHandler:Register(onAddonLoaded, "ADDON_LOADED")
end

function translator:OnEnabled()
    -- Next constants will be ignored
    --["TALENT_BUTTON_TOOLTIP_RANK_FORMAT"] = "Rank %s/%s",
    --["TALENT_BUTTON_TOOLTIP_NEXT_RANK"] = "Next Rank:",
    --["TALENT_BUTTON_TOOLTIP_REPLACED_BY_FORMAT"] = "Replaced by %s",
    --["TALENT_FRAME_SEARCH_PREVIEW_OVERFLOW_FORMAT"] = "And %s more"
    --["TALENT_FRAME_LABEL_PVP_TALENT_SLOTS"] = "PVP"
    --["TALENT_FRAME_SEARCH_NOT_ON_ACTIONBAR"] = "Missing from action bar"
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
        "TALENT_FRAME_CURRENCY_DISPLAY_FORMAT",
        "TALENT_FRAME_INSPECT_COPY_BUTTON_TEXT",
        "TALENT_FRAME_DROP_DOWN_EXPORT",
        "TALENT_FRAME_EXPORT_TEXT",
        "TALENT_FRAME_CONFIRM_STARTER_DEVIATION",
        "TALENT_FRAME_CONFIG_OPERATION_TOO_FAST",
        "TALENT_FRAME_APPLY_BUTTON_TEXT",
        "TALENT_FRAME_DISCARD_CHANGES_BUTTON_TOOLTIP",
        -- Talent buttons
        "TALENT_BUTTON_TOOLTIP_CLEAR_REPURCHASE_INSTRUCTIONS",
        "TALENT_BUTTON_TOOLTIP_PURCHASE_INSTRUCTIONS",
        "TALENT_BUTTON_TOOLTIP_REPURCHASE_INSTRUCTIONS",
        "TALENT_BUTTON_TOOLTIP_PVP_TALENT_REQUIREMENT_ERROR",
        "TALENT_BUTTON_TOOLTIP_REFUND_INSTRUCTIONS",
        "TALENT_BUTTON_TOOLTIP_SELECTION_ERROR",
        "TALENT_BUTTON_TOOLTIP_SELECTION_CURRENT_INSTRUCTIONS",
        "TALENT_BUTTON_TOOLTIP_COST_FORMAT",
        "TALENT_BUTTON_TOOLTIP_SELECTION_COST_ERROR",
        "TALENT_BUTTON_TOOLTIP_SELECTION_CHOICE_ERROR",
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

    _G["TALENT_FRAME_GATE_TOOLTIP_FORMAT"] = ReconstructStringWithNumerics(getTranslationOrDefault(_G
        ["TALENT_FRAME_GATE_TOOLTIP_FORMAT"]))
end
