local addonName, ns = ...;

local sharedMedia = LibStub("LibSharedMedia-3.0")
local eventHandler = ns.EventHandler:new()
local settingsProvider = ns.SettingsProvider:new()

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
        name = "SubtitlesTranslator",
        args = nil,
        isEnabled = function()
            return
                WowUkrainizer_Options.TranslateSubtitles
        end
    },
    {
        name = "NpcMessageTranslator",
        args = nil,
        isEnabled = function()
            return
                WowUkrainizer_Options.TranslateNpcDialogs or WowUkrainizer_Options.TranslateCinematics
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
    local function _setScaledFont(fontFamily, fontName, scale)
        if (not fontFamily) then return end
        local _, height, flags = fontFamily:GetFont()
        fontFamily:SetFont(fontName, height * scale, flags)
    end

    local function _setFont(fontFamily, fontName, height)
        if (not fontFamily) then return end
        local _, _, flags = fontFamily:GetFont()
        fontFamily:SetFont(fontName, height, flags)
    end

    local useDefaultFonts, fontName, fontScale, tooltipHeaderFontScale, tooltipFontScale =
        settingsProvider.GetFontSettings()

    local questTitleFont = settingsProvider.GetQuestTitleFontFile()
    local FRIZQTFont = settingsProvider.GetQuestFontFile()

    if not useDefaultFonts then
        local fontElements = {
            { element = SystemFont_Shadow_Med1,   scale = fontScale },
            { element = SystemFont_Shadow_Small,  scale = fontScale },
            { element = SystemFont_Shadow_Med2,   scale = fontScale },
            { element = SystemFont_Shadow_Large2, scale = fontScale },
            { element = Game30Font,               scale = fontScale },
            { element = GameTooltipHeader,        scale = tooltipHeaderFontScale },
            { element = Tooltip_Med,              scale = tooltipFontScale },
            { element = Tooltip_Small,            scale = tooltipFontScale },
            -- TODO: Other
        }

        for _, fontElement in ipairs(fontElements) do
            _setScaledFont(fontElement.element, fontName, fontElement.scale)
        end
    else
        local fontElements = {
            -- fonts
            { element = SystemFont_Outline_Small,         fontName = FRIZQTFont,     height = 10 },
            { element = SystemFont_Outline,               fontName = FRIZQTFont,     height = 13 },
            { element = SystemFont_InverseShadow_Small,   fontName = FRIZQTFont,     height = 10 },
            { element = SystemFont_Huge1,                 fontName = FRIZQTFont,     height = 20 },
            { element = SystemFont_Huge1_Outline,         fontName = FRIZQTFont,     height = 20 },
            { element = SystemFont_OutlineThick_Huge2,    fontName = FRIZQTFont,     height = 22 },
            { element = SystemFont_OutlineThick_Huge4,    fontName = FRIZQTFont,     height = 26 },
            { element = SystemFont_OutlineThick_WTF,      fontName = FRIZQTFont,     height = 32 },
            { element = NumberFont_GameNormal,            fontName = FRIZQTFont,     height = 10 },
            { element = Game48FontShadow,                 fontName = FRIZQTFont,     height = 48 },
            { element = Game15Font_o1,                    fontName = FRIZQTFont,     height = 15 },
            { element = MailFont_Large,                   fontName = FRIZQTFont,     height = 15 },
            { element = SpellFont_Small,                  fontName = FRIZQTFont,     height = 10 },
            { element = InvoiceFont_Med,                  fontName = FRIZQTFont,     height = 12 },
            { element = InvoiceFont_Small,                fontName = FRIZQTFont,     height = 10 },
            { element = AchievementFont_Small,            fontName = FRIZQTFont,     height = 10 },
            { element = ReputationDetailFont,             fontName = FRIZQTFont,     height = 10 },
            { element = FriendsFont_Normal,               fontName = FRIZQTFont,     height = 12 },
            { element = FriendsFont_11,                   fontName = FRIZQTFont,     height = 11 },
            { element = FriendsFont_Small,                fontName = FRIZQTFont,     height = 10 },
            { element = FriendsFont_Large,                fontName = FRIZQTFont,     height = 14 },
            { element = GameFont_Gigantic,                fontName = FRIZQTFont,     height = 32 },
            { element = ChatBubbleFont,                   fontName = FRIZQTFont,     height = 14 },
            { element = SystemFont_NamePlateFixed,        fontName = FRIZQTFont,     height = 14 },
            { element = SystemFont_LargeNamePlateFixed,   fontName = FRIZQTFont,     height = 20 },
            { element = SystemFont_NamePlate,             fontName = FRIZQTFont,     height = 9 },
            { element = SystemFont_LargeNamePlate,        fontName = FRIZQTFont,     height = 12 },
            { element = SystemFont_NamePlateCastBar,      fontName = FRIZQTFont,     height = 10 },
            { element = Fancy22Font,                      fontName = questTitleFont, height = 22 },
            -- glue fonts
            -- INFO: This font can't be changed sine in game they font object are equals nil
            -- { element = SystemFont_Shadow_Outline_Small,    fontName = FRIZQTFont, height = 10 },
            -- { element = SystemFont_Outline_Med1,            fontName = FRIZQTFont, height = 12 },
            -- { element = SystemFont_Outline_Med2,            fontName = FRIZQTFont, height = 15 },
            -- { element = SystemFont_Shadow_Outline_Large,    fontName = FRIZQTFont, height = 18 },
            -- { element = SystemFont_Shadow_Outline_Gigantor, fontName = FRIZQTFont, height = 32 },
            -- { element = OptionsFont,                        fontName = FRIZQTFont, height = 12 },
            { element = OptionsFontSmall,                 fontName = FRIZQTFont,     height = 10 },
            { element = OptionsFontLarge,                 fontName = FRIZQTFont,     height = 18 },
            { element = OptionsFontHighlight,             fontName = FRIZQTFont,     height = 12 },
            { element = OptionsFontHighlightSmall,        fontName = FRIZQTFont,     height = 10 },
            -- shared fonts
            { element = SystemFont_Tiny2,                 fontName = FRIZQTFont,     height = 8 },
            { element = SystemFont_Tiny,                  fontName = FRIZQTFont,     height = 9 },
            { element = SystemFont_Shadow_Small,          fontName = FRIZQTFont,     height = 10 },
            { element = Game10Font_o1,                    fontName = FRIZQTFont,     height = 10 },
            { element = SystemFont_Small,                 fontName = FRIZQTFont,     height = 10 },
            { element = SystemFont_Small2,                fontName = FRIZQTFont,     height = 11 },
            { element = SystemFont_Shadow_Small2,         fontName = FRIZQTFont,     height = 11 },
            { element = SystemFont_Shadow_Small_Outline,  fontName = FRIZQTFont,     height = 10 },
            { element = SystemFont_Shadow_Small2_Outline, fontName = FRIZQTFont,     height = 11 },
            { element = SystemFont_Shadow_Med1_Outline,   fontName = FRIZQTFont,     height = 12 },
            { element = SystemFont_Shadow_Med1,           fontName = FRIZQTFont,     height = 12 },
            { element = SystemFont_Med2,                  fontName = FRIZQTFont,     height = 13 },
            { element = SystemFont_Med3,                  fontName = FRIZQTFont,     height = 14 },
            { element = SystemFont_Shadow_Med3,           fontName = FRIZQTFont,     height = 14 },
            { element = SystemFont_Shadow_Med3_Outline,   fontName = FRIZQTFont,     height = 14 },
            { element = SystemFont_Large,                 fontName = FRIZQTFont,     height = 16 },
            { element = SystemFont_Shadow_Large_Outline,  fontName = FRIZQTFont,     height = 16 },
            { element = SystemFont_Shadow_Med2,           fontName = FRIZQTFont,     height = 14 },
            { element = SystemFont_Shadow_Med2_Outline,   fontName = FRIZQTFont,     height = 14 },
            { element = SystemFont_Shadow_Large,          fontName = FRIZQTFont,     height = 16 },
            { element = SystemFont_Shadow_Large2,         fontName = FRIZQTFont,     height = 18 },
            { element = SystemFont_Shadow_Huge1,          fontName = FRIZQTFont,     height = 20 },
            { element = SystemFont_Shadow_Huge1_Outline,  fontName = FRIZQTFont,     height = 20 },
            { element = SystemFont_Huge2,                 fontName = FRIZQTFont,     height = 24 },
            { element = SystemFont_Shadow_Huge2,          fontName = FRIZQTFont,     height = 24 },
            { element = SystemFont_Shadow_Huge2_Outline,  fontName = FRIZQTFont,     height = 24 },
            { element = SystemFont_Shadow_Huge3,          fontName = FRIZQTFont,     height = 25 },
            { element = SystemFont_Shadow_Outline_Huge3,  fontName = FRIZQTFont,     height = 25 },
            { element = SystemFont_Huge4,                 fontName = FRIZQTFont,     height = 27 },
            { element = SystemFont_Shadow_Huge4,          fontName = FRIZQTFont,     height = 27 },
            { element = SystemFont_Shadow_Huge4_Outline,  fontName = FRIZQTFont,     height = 27 },
            { element = SystemFont_World,                 fontName = FRIZQTFont,     height = 64 },
            { element = SystemFont_World_ThickOutline,    fontName = FRIZQTFont,     height = 64 },
            { element = SystemFont22_Outline,             fontName = FRIZQTFont,     height = 22 },
            { element = SystemFont22_Shadow_Outline,      fontName = FRIZQTFont,     height = 22 },
            { element = SystemFont_Med1,                  fontName = FRIZQTFont,     height = 12 },
            { element = SystemFont_WTF2,                  fontName = FRIZQTFont,     height = 36 },
            { element = SystemFont_Outline_WTF2,          fontName = FRIZQTFont,     height = 36 },
            { element = GameTooltipHeader,                fontName = FRIZQTFont,     height = 14 },
            { element = System_IME,                       fontName = FRIZQTFont,     height = 16 },
            { element = Tooltip_Med,                      fontName = FRIZQTFont,     height = 12 },
            { element = Tooltip_Small,                    fontName = FRIZQTFont,     height = 10 },
            { element = System15Font,                     fontName = FRIZQTFont,     height = 15 },
            { element = Game30Font,                       fontName = FRIZQTFont,     height = 30 },
        }
        for _, fontElement in ipairs(fontElements) do
            _setFont(fontElement.element, fontElement.fontName, fontElement.height)
        end
    end

    local questFontSettings = {
        { element = QuestFont_Large,              fontName = questTitleFont, height = 15 },
        { element = QuestFont_Huge,               fontName = questTitleFont, height = 18 },
        { element = QuestFont_30,                 fontName = questTitleFont, height = 30 },
        { element = QuestFont_39,                 fontName = questTitleFont, height = 39 },
        { element = QuestFont_Outline_Huge,       fontName = questTitleFont, height = 18 },
        { element = QuestFont_Super_Huge,         fontName = questTitleFont, height = 24 },
        { element = QuestFont_Super_Huge_Outline, fontName = questTitleFont, height = 24 },
        { element = QuestFont_Enormous,           fontName = questTitleFont, height = 30 },
        { element = QuestFont_Shadow_Small,       fontName = questTitleFont, height = 14 },
        { element = SystemFont_Med2,              fontName = FRIZQTFont,     height = 13 },
    }

    for _, fontElement in ipairs(questFontSettings) do
        _setFont(fontElement.element, fontElement.fontName, fontElement.height)
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

    ns.VoiceOverDirector:Initialize()
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
