--- @class WowUkrainizerInternals
local ns = select(2, ...);

local sharedMedia = LibStub("LibSharedMedia-3.0")

--- Utility class responsible for managing and providing access to addon settings.
--- This class ensures the proper initialization and handling of various options.
---@class SettingsProvider
---@field defaultOptions table<string, any> @Default options for addon.
local _settingsProviderPrototype = {
    defaultOptions = {
        -- Font
        [WOW_UKRAINIZER_MAIN_FONT_NAME_OPTION] = "Friz Quadrata TT (укр.)",
        [WOW_UKRAINIZER_TITLE_FONT_NAME_OPTION] = "Morpheus (укр.)",
        [WOW_UKRAINIZER_TOOLTIP_FONT_NAME_OPTION] = "Friz Quadrata TT (укр.)",
        [WOW_UKRAINIZER_MAIN_FONT_SCALE_IN_PERCENT_OPTION] = 1,
        [WOW_UKRAINIZER_TITLE_FONT_SCALE_IN_PERCENT_OPTION] = 1,
        [WOW_UKRAINIZER_TOOLTIP_FONT_SCALE_IN_PERCENT_OPTION] = 1,
        [WOW_UKRAINIZER_USE_DEFAULT_FONTS_OPTION] = false,
        [WOW_UKRAINIZER_USE_ADAPTED_FONTS_OPTION] = true,
        [WOW_UKRAINIZER_USE_CUSTOMIZED_FONTS_OPTION] = false,
        -- General
        [WOW_UKRAINIZER_IS_FIRST_RUN_OPTION] = true,
        [WOW_UKRAINIZER_TRANSLATE_CLASS_TALENTS_FRAME_OPTION] = true,
        [WOW_UKRAINIZER_TRANSLATE_SPELLBOOK_FRAME_OPTION] = true,
        [WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION] = true,
        [WOW_UKRAINIZER_DISABLE_MT_FOR_QUESTS_OPTION] = false,
        [WOW_UKRAINIZER_TRANSLATE_QUEST_TEXT_OPTION] = true,
        [WOW_UKRAINIZER_TRANSLATE_NAMEPLATES_AND_UNIT_FRAMES_OPTION] = true,
        [WOW_UKRAINIZER_SPELL_NAME_LANG_IN_SPELLBOOK_OPTION] = "ua",
        [WOW_UKRAINIZER_TRANSLATE_SUBTITLES_OPTION] = true,
        [WOW_UKRAINIZER_TRANSLATE_NPC_MESSAGES_OPTION] = true,
        [WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION] = true,
        [WOW_UKRAINIZER_TRANSLATE_MAP_AND_QUEST_LOG_FRAME_OPTION] = true,
        -- Tooltips
        [WOW_UKRAINIZER_TRANSLATE_UNIT_TOOLTIPS_OPTION] = true,
        [WOW_UKRAINIZER_TRANSLATE_SPELL_TOOLTIPS_OPTION] = true,
        [WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_NAME_OPTION] = "both",
        [WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_DESCRIPTION_OPTION] = "ua",
        [WOW_UKRAINIZER_HIGHLIGHT_SPELL_NAME_IN_DESCRIPTION_OPTION] = true,
        [WOW_UKRAINIZER_TRANSLATE_ITEM_TOOLTIPS_OPTION] = true,
        [WOW_UKRAINIZER_DO_NOT_TRANSLATE_ITEM_NAME_OPTION] = false,
        [WOW_UKRAINIZER_DO_NOT_TRANSLATE_ITEM_ATTRIBUTES_OPTION] = false,
        -- Changelogs
        [WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION] = "1.14.0",
    }
}

--- Resets addon options to their default values. WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION and WOW_UKRAINIZER_IS_FIRST_RUN_OPTION not ressets
function _settingsProviderPrototype:ResetToDefault()
    local currentLastAutoShownChangelogVersion =
        WowUkrainizer_Options[WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION]

    local isFirstRun =
        WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION]

    for k, v in pairs(self.defaultOptions) do
        WowUkrainizer_Options[k] = v
    end

    WowUkrainizer_Options[WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION] = currentLastAutoShownChangelogVersion
    WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION] = isFirstRun
end

--- Get font settings for WowUkrainizer.
--- @return boolean useDefaultFonts @Whether to use default fonts.
--- @return string|nil mainFontPath @Path of the main font if not using default fonts; otherwise, nil.
--- @return number|nil mainFontScale @Scale of the main font if not using default fonts; otherwise, nil.
--- @return string|nil titleFontPath @Path of the title font if not using default fonts; otherwise, nil.
--- @return number|nil titleFontScale @Scale of the title font if not using default fonts; otherwise, nil.
--- @return string|nil tooltipFontPath @Path of the tooltip font if not using default fonts; otherwise, nil.
--- @return number|nil tooltipFontScale @Scale of the tooltip font if not using default fonts; otherwise, nil.
function _settingsProviderPrototype.GetFontSettings()
    if (WowUkrainizer_Options[WOW_UKRAINIZER_USE_DEFAULT_FONTS_OPTION]) then
        return true
    elseif (WowUkrainizer_Options[WOW_UKRAINIZER_USE_ADAPTED_FONTS_OPTION]) then
        return false,
            WOW_UKRAINIZER_ADAPTED_MAIN_FONT_PATH, 1,
            WOW_UKRAINIZER_ADAPTED_TITLE_FONT_PATH, 1,
            WOW_UKRAINIZER_ADAPTED_MAIN_FONT_PATH, 1
    else
        return false,
            sharedMedia:Fetch('font', WowUkrainizer_Options[WOW_UKRAINIZER_MAIN_FONT_NAME_OPTION]),
            WowUkrainizer_Options[WOW_UKRAINIZER_MAIN_FONT_SCALE_IN_PERCENT_OPTION],
            sharedMedia:Fetch('font', WowUkrainizer_Options[WOW_UKRAINIZER_TITLE_FONT_NAME_OPTION]),
            WowUkrainizer_Options[WOW_UKRAINIZER_TITLE_FONT_SCALE_IN_PERCENT_OPTION],
            sharedMedia:Fetch('font', WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_FONT_NAME_OPTION]),
            WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_FONT_SCALE_IN_PERCENT_OPTION]
    end
end

--- Checks if the changelog should be shown.
---@return boolean @True if the changelog should be shown; otherwise, false.
function _settingsProviderPrototype.ShouldShowChangelog()
    local lastAutoShownChangelogVersion = WowUkrainizer_Options[WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION]
    local isFirstRun = WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION]

    return not isFirstRun and ns._db.Changelogs[1].version ~= lastAutoShownChangelogVersion
end

--- Checks if the installer wizard should be shown.
---@return boolean @True if the installer wizard should be shown; otherwise, false.
function _settingsProviderPrototype.ShouldShowInstallerWizard()
    return WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION] == true
end

--- Checks if spell names in the spellbook should be translated to Ukrainian.
---@return boolean @True if spell names in the spellbook should be translated to Ukrainian; otherwise, false.
function _settingsProviderPrototype.IsNeedTranslateSpellNameInSpellbook()
    return WowUkrainizer_Options[WOW_UKRAINIZER_SPELL_NAME_LANG_IN_SPELLBOOK_OPTION] == "ua"
end

--- Checks if spell descriptions in tooltips should be translated to Ukrainian.
---@return boolean @True if spell descriptions in tooltips should be translated to Ukrainian; otherwise, false.
function _settingsProviderPrototype.IsNeedTranslateSpellDescriptionInTooltip()
    return WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_DESCRIPTION_OPTION] == "ua"
end

--- Checks if spell names should be highlighted in spell descriptions.
---@return boolean @True if spell names should be highlighted in spell descriptions; otherwise, false.
function _settingsProviderPrototype.IsNeedHighlightSpellNameInDescription()
    return WowUkrainizer_Options[WOW_UKRAINIZER_HIGHLIGHT_SPELL_NAME_IN_DESCRIPTION_OPTION] == true
end

--- Checks if item name in tooltips should be translated to Ukrainian.
---@return boolean @True if item name in tooltips should be translated to Ukrainian; otherwise, false.
function _settingsProviderPrototype.IsNeedToTranslateItemNameInTooltip()
    return WowUkrainizer_Options[WOW_UKRAINIZER_DO_NOT_TRANSLATE_ITEM_NAME_OPTION] == false
end

--- Checks if item attribute in tooltips should be translated to Ukrainian.
---@return boolean @True if item attribute in tooltips should be translated to Ukrainian; otherwise, false.
function _settingsProviderPrototype.IsNeedToTranslateItemAttributesInTooltip()
    return WowUkrainizer_Options[WOW_UKRAINIZER_DO_NOT_TRANSLATE_ITEM_ATTRIBUTES_OPTION] == false
end

--- Retrieves the value of an option from addon options.
---@param name string @The name of the option.
---@return any @The value of the option.
function _settingsProviderPrototype.GetOption(name)
    return WowUkrainizer_Options[name]
end

--- Sets an option in addon options.
---@param name string @The name of the option.
---@param value any @The value to set for the option.
function _settingsProviderPrototype.SetOption(name, value)
    WowUkrainizer_Options[name] = value
end

--- Create the singleton instance of the SettingsProvider.
function ns:CreateSettingsProvider()
    if not self.SettingsProvider then
        self.SettingsProvider = setmetatable({}, { __index = _settingsProviderPrototype })

        WowUkrainizer_Options = WowUkrainizer_Options or {}

        for k, v in pairs(_settingsProviderPrototype.defaultOptions) do
            if (WowUkrainizer_Options[k] == nil) then
                WowUkrainizer_Options[k] = v
            end
        end
    end
end
