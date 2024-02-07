local _, ns = ...;

local sharedMedia = LibStub("LibSharedMedia-3.0")

local settingsProvider = class("SettingsProvider");
ns.SettingsProvider = settingsProvider

local defaultOptions = {
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
    -- Tooltips
    [WOW_UKRAINIZER_TRANSLATE_UNIT_TOOLTIPS_OPTION] = true,
    [WOW_UKRAINIZER_TRANSLATE_SPELL_TOOLTIPS_OPTION] = true,
    [WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_NAME_OPTION] = "both",
    [WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_DESCRIPTION_OPTION] = "ua",
    [WOW_UKRAINIZER_HIGHLIGHT_SPELL_NAME_IN_DESCRIPTION_OPTION] = true,
    -- Changelogs
    [WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION] = "1.9.2",
}

function settingsProvider:Load()
    WowUkrainizer_Options = WowUkrainizer_Options or {}

    if (WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION] = defaultOptions
            [WOW_UKRAINIZER_IS_FIRST_RUN_OPTION]
    end

    -- Font settings
    WowUkrainizer_Options[WOW_UKRAINIZER_MAIN_FONT_NAME_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_MAIN_FONT_NAME_OPTION] or
        defaultOptions[WOW_UKRAINIZER_MAIN_FONT_NAME_OPTION]

    WowUkrainizer_Options[WOW_UKRAINIZER_TITLE_FONT_NAME_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_TITLE_FONT_NAME_OPTION] or
        defaultOptions[WOW_UKRAINIZER_TITLE_FONT_NAME_OPTION]

    WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_FONT_NAME_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_FONT_NAME_OPTION] or
        defaultOptions[WOW_UKRAINIZER_TOOLTIP_FONT_NAME_OPTION]

    WowUkrainizer_Options[WOW_UKRAINIZER_MAIN_FONT_SCALE_IN_PERCENT_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_MAIN_FONT_SCALE_IN_PERCENT_OPTION] or
        defaultOptions[WOW_UKRAINIZER_MAIN_FONT_SCALE_IN_PERCENT_OPTION]

    WowUkrainizer_Options[WOW_UKRAINIZER_TITLE_FONT_SCALE_IN_PERCENT_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_TITLE_FONT_SCALE_IN_PERCENT_OPTION] or
        defaultOptions[WOW_UKRAINIZER_TITLE_FONT_SCALE_IN_PERCENT_OPTION]

    WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_FONT_SCALE_IN_PERCENT_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_FONT_SCALE_IN_PERCENT_OPTION] or
        defaultOptions[WOW_UKRAINIZER_TOOLTIP_FONT_SCALE_IN_PERCENT_OPTION]

    if (WowUkrainizer_Options[WOW_UKRAINIZER_USE_DEFAULT_FONTS_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_USE_DEFAULT_FONTS_OPTION] = defaultOptions
            [WOW_UKRAINIZER_USE_DEFAULT_FONTS_OPTION]
    end

    if (WowUkrainizer_Options[WOW_UKRAINIZER_USE_ADAPTED_FONTS_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_USE_ADAPTED_FONTS_OPTION] = defaultOptions
            [WOW_UKRAINIZER_USE_ADAPTED_FONTS_OPTION]
    end

    if (WowUkrainizer_Options[WOW_UKRAINIZER_USE_CUSTOMIZED_FONTS_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_USE_CUSTOMIZED_FONTS_OPTION] =
            defaultOptions[WOW_UKRAINIZER_USE_CUSTOMIZED_FONTS_OPTION]
    end

    -- General settings
    if (WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_CLASS_TALENTS_FRAME_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_CLASS_TALENTS_FRAME_OPTION] =
            defaultOptions[WOW_UKRAINIZER_TRANSLATE_CLASS_TALENTS_FRAME_OPTION]
    end

    if (WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_SPELLBOOK_FRAME_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_SPELLBOOK_FRAME_OPTION] = defaultOptions
            [WOW_UKRAINIZER_TRANSLATE_SPELLBOOK_FRAME_OPTION]
    end

    if (WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_NAMEPLATES_AND_UNIT_FRAMES_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_NAMEPLATES_AND_UNIT_FRAMES_OPTION] =
            defaultOptions[WOW_UKRAINIZER_TRANSLATE_NAMEPLATES_AND_UNIT_FRAMES_OPTION]
    end

    if (WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION] =
            defaultOptions[WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION]
    end

    if (WowUkrainizer_Options[WOW_UKRAINIZER_DISABLE_MT_FOR_QUESTS_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_DISABLE_MT_FOR_QUESTS_OPTION] =
            defaultOptions[WOW_UKRAINIZER_DISABLE_MT_FOR_QUESTS_OPTION]
    end

    WowUkrainizer_Options[WOW_UKRAINIZER_SPELL_NAME_LANG_IN_SPELLBOOK_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_SPELL_NAME_LANG_IN_SPELLBOOK_OPTION] or
        defaultOptions[WOW_UKRAINIZER_SPELL_NAME_LANG_IN_SPELLBOOK_OPTION]

    if (WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_SPELL_TOOLTIPS_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_SPELL_TOOLTIPS_OPTION] =
            defaultOptions[WOW_UKRAINIZER_TRANSLATE_SPELL_TOOLTIPS_OPTION]
    end

    if (WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_UNIT_TOOLTIPS_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_UNIT_TOOLTIPS_OPTION] =
            defaultOptions[WOW_UKRAINIZER_TRANSLATE_UNIT_TOOLTIPS_OPTION]
    end

    if (WowUkrainizer_Options[WOW_UKRAINIZER_HIGHLIGHT_SPELL_NAME_IN_DESCRIPTION_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_HIGHLIGHT_SPELL_NAME_IN_DESCRIPTION_OPTION] =
            defaultOptions[WOW_UKRAINIZER_HIGHLIGHT_SPELL_NAME_IN_DESCRIPTION_OPTION]
    end

    if (WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_SUBTITLES_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_SUBTITLES_OPTION] =
            defaultOptions[WOW_UKRAINIZER_TRANSLATE_SUBTITLES_OPTION]
    end


    if (WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_NPC_MESSAGES_OPTION] == nil) then
        WowUkrainizer_Options[WOW_UKRAINIZER_TRANSLATE_NPC_MESSAGES_OPTION] =
            defaultOptions[WOW_UKRAINIZER_TRANSLATE_NPC_MESSAGES_OPTION]
    end

    WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_NAME_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_NAME_OPTION] or
        defaultOptions[WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_NAME_OPTION]

    WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_DESCRIPTION_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_DESCRIPTION_OPTION] or
        defaultOptions[WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_DESCRIPTION_OPTION]

    WowUkrainizer_Options[WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION] =
        WowUkrainizer_Options[WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION] or
        defaultOptions[WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION]
end

function settingsProvider:ResetToDefault()
    local currentLastAutoShownChangelogVersion =
        WowUkrainizer_Options[WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION]

    local isFirstRun =
        WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION]

    for k, v in pairs(defaultOptions) do
        WowUkrainizer_Options[k] = v
    end

    WowUkrainizer_Options[WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION] = currentLastAutoShownChangelogVersion
    WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION] = isFirstRun
end

function settingsProvider.GetFontSettings()
    if (WowUkrainizer_Options[WOW_UKRAINIZER_USE_DEFAULT_FONTS_OPTION]) then
        return true
    end
    if (WowUkrainizer_Options[WOW_UKRAINIZER_USE_ADAPTED_FONTS_OPTION]) then
        return false,
            WOW_UKRAINIZER_ADAPTED_MAIN_FONT_PATH, 1,
            WOW_UKRAINIZER_ADAPTED_TITLE_FONT_PATH, 1,
            WOW_UKRAINIZER_ADAPTED_MAIN_FONT_PATH, 1
    end
    if (WowUkrainizer_Options[WOW_UKRAINIZER_USE_CUSTOMIZED_FONTS_OPTION]) then
        return false,
            sharedMedia:Fetch('font', WowUkrainizer_Options[WOW_UKRAINIZER_MAIN_FONT_NAME_OPTION]),
            WowUkrainizer_Options[WOW_UKRAINIZER_MAIN_FONT_SCALE_IN_PERCENT_OPTION],
            sharedMedia:Fetch('font', WowUkrainizer_Options[WOW_UKRAINIZER_TITLE_FONT_NAME_OPTION]),
            WowUkrainizer_Options[WOW_UKRAINIZER_TITLE_FONT_SCALE_IN_PERCENT_OPTION],
            sharedMedia:Fetch('font', WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_FONT_NAME_OPTION]),
            WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_FONT_SCALE_IN_PERCENT_OPTION]
    end
end

function settingsProvider.ShouldShowChangelog()
    local lastAutoShownChangelogVersion = WowUkrainizer_Options[WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION]
    local isFirstRun = WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION]

    return not isFirstRun and ns._db.Changelogs[1][1] ~= lastAutoShownChangelogVersion
end

function settingsProvider.ShouldShowInstallerWizard()
    return WowUkrainizer_Options[WOW_UKRAINIZER_IS_FIRST_RUN_OPTION] == true
end

function settingsProvider.IsNeedTranslateSpellNameInSpellbook()
    return WowUkrainizer_Options[WOW_UKRAINIZER_SPELL_NAME_LANG_IN_SPELLBOOK_OPTION] == "ua"
end

function settingsProvider.IsNeedTranslateSpellDescriptionInTooltip()
    return WowUkrainizer_Options[WOW_UKRAINIZER_TOOLTIP_SPELL_LANG_IN_DESCRIPTION_OPTION] == "ua"
end

function settingsProvider.IsNeedHighlightSpellNameInDescription()
    return WowUkrainizer_Options[WOW_UKRAINIZER_HIGHLIGHT_SPELL_NAME_IN_DESCRIPTION_OPTION] == true
end

function settingsProvider.SetOption(name, value)
    WowUkrainizer_Options[name] = value
end

function settingsProvider.GetOption(name)
    return WowUkrainizer_Options[name]
end
