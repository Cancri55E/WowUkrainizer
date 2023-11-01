local addonName, ns = ...;

local sharedMedia = LibStub("LibSharedMedia-3.0")
local eventHandler = ns.EventHandler:new()
local settingsProvider = ns.SettingsProvider:new()

local SetFont = ns.FontStringExtensions.SetFont
local SetFontH = ns.FontStringExtensions.SetFontH

local translators = {
    {
        name = "MainFrameTranslator",
        args = nil,
        isEnabled = function() return true end
    },
    {
        name = "ClassTalentFrameTranslator",
        args = nil,
        isEnabled = function()
            return WowUkrainizer_Options
                .TranslateClassTalentsFrame
        end
    },
    {
        name = "SpellbookFrameTranslator",
        args = nil,
        isEnabled = function()
            return WowUkrainizer_Options
                .TranslateSpellbookFrame
        end
    },
    {
        name = "NameplateAndUnitFrameTranslator",
        args = nil,
        isEnabled = function()
            return WowUkrainizer_Options
                .TranslateNameplatesAndUnitFrames
        end
    },
    {
        name = "SpellTooltipTranslator",
        args = Enum.TooltipDataType.Spell,
        isEnabled = function()
            return
                WowUkrainizer_Options.TranslateSpellTooltips
        end
    },
    {
        name = "UnitTooltipTranslator",
        args = Enum.TooltipDataType.Unit,
        isEnabled = function()
            return
                WowUkrainizer_Options.TranslateUnitTooltips
        end
    },
    {
        name = "MovieTranslator",
        args = nil,
        isEnabled = function()
            return
                WowUkrainizer_Options.TranslateMovieSubtitles
        end
    },
    {
        name = "NpcMessageTranslator",
        args = nil,
        isEnabled = function()
            return
                WowUkrainizer_Options.TranslateNpcMessages
        end
    },
    {
        name = "QuestTranslator",
        args = nil,
        isEnabled = function()
            return WowUkrainizer_Options.TranslateQuestAndObjectivesFrame
        end
    },
}

local initialized = false

local function createInterfaceOptions()
    settingsProvider:Build()

    local namespace = "WowUkrainizer"
    LibStub("AceConfig-3.0"):RegisterOptionsTable(namespace, ns.Options)

    local configDialogLib = LibStub("AceConfigDialog-3.0")
    configDialogLib:AddToBlizOptions(namespace, "WowUkrainizer", nil, "General")
    configDialogLib:AddToBlizOptions(namespace, "Причетні", "WowUkrainizer", "Contributors")
end

local function setGameFonts()
    local useDefaultFonts, fontName, fontScale, tooltipHeaderFontScale, tooltipFontScale =
        settingsProvider.GetFontSettings()

    if not useDefaultFonts then
        local fontElements = {
            { element = SystemFont_Shadow_Med1,   scale = fontScale },
            { element = SystemFont_Shadow_Small,  scale = fontScale },
            { element = SystemFont_Shadow_Med2,   scale = fontScale },
            { element = SystemFont_Shadow_Large2, scale = fontScale },
            { element = Game30Font,               scale = fontScale },
        }

        local tooltipElements = {
            { element = GameTooltipHeader, scale = tooltipHeaderFontScale },
            { element = Tooltip_Med,       scale = tooltipFontScale },
            { element = Tooltip_Small,     scale = tooltipFontScale },
        }

        for _, fontElement in ipairs(fontElements) do
            SetFont(fontElement.element, fontName, fontElement.scale)
        end

        for _, tooltipElement in ipairs(tooltipElements) do
            SetFont(tooltipElement.element, fontName, tooltipElement.scale)
        end
    end

    local questTitleFont = settingsProvider.GetQuestTitleFontFile()
    local questFont = settingsProvider.GetQuestFontFile()
    local questElements = {
        { element = QuestFont_Large,              name = questTitleFont, height = 15 },
        { element = QuestFont_Huge,               name = questTitleFont, height = 18 },
        { element = QuestFont_30,                 name = questTitleFont, height = 30 },
        { element = QuestFont_39,                 name = questTitleFont, height = 39 },
        { element = QuestFont_Outline_Huge,       name = questTitleFont, height = 18 },
        { element = QuestFont_Super_Huge,         name = questTitleFont, height = 24 },
        { element = QuestFont_Super_Huge_Outline, name = questTitleFont, height = 24 },
        { element = QuestFont_Enormous,           name = questTitleFont, height = 30 },
        { element = QuestFont_Shadow_Small,       name = questTitleFont, height = 14 },
        { element = SystemFont_Med2,              name = questFont,      height = 13 },
    }

    for _, fontElement in ipairs(questElements) do
        SetFontH(fontElement.element, fontElement.name, fontElement.height)
    end
end

local function initializeAddon()
    if (initialized) then return end

    StaticPopupDialogs["WOW_UKRAINIZAER_RESET_SETTINGS"] = {
        text = "Ви впевнені, що хочете скинути всі налаштування до стандартних значень?",
        button1 = "Продовжити",
        button2 = "Скасувати",
        OnAccept = function() settingsProvider:Reset() end,
        OnShow = function() PlaySound(SOUNDKIT.RAID_WARNING) end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    sharedMedia:Register("font", "Arsenal Regular", [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Regular.ttf]])
    sharedMedia:Register("font", "Arsenal Bold", [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Bold.ttf]])
end

local function OnPlayerLogin()
    ns.PlayerData = {
        Name = GetUnitName("player"),
        Race = UnitRace("player"),
        Class = UnitClass("player"),
        Gender = UnitSex("player")
    }

    settingsProvider:Load()
    createInterfaceOptions()
    setGameFonts();

    local function createTranslator(translatorName, args)
        local translator
        if args ~= nil then
            translator = ns.Translators[translatorName]:new(args)
        else
            translator = ns.Translators[translatorName]:new()
        end
        translator:SetEnabled(true)
        return translator
    end

    for _, translatorData in ipairs(translators) do
        if translatorData.isEnabled() then
            translatorData.translator = createTranslator(translatorData.name, translatorData.args)
        end
    end
end

local function OnAddOnLoaded(_, name)
    if (name == addonName) then
        initializeAddon()
        if not IsLoggedIn() then
            eventHandler:Register(OnPlayerLogin, "PLAYER_LOGIN")
        else
            OnPlayerLogin()
        end
    end
end

eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")
