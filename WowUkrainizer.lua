local addonName, ns = ...;

local sharedMedia = LibStub("LibSharedMedia-3.0")
local eventHandler = ns.EventHandler:new()
local settingsProvider = ns.SettingsProvider:new()

local dataBroker
local addOnSettingsCategoryID

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
            return settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_CLASS_TALENTS_FRAME_OPTION)
        end
    },
    {
        name = "SpellbookFrameTranslator",
        args = nil,
        isEnabled = function()
            return settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SPELLBOOK_FRAME_OPTION)
        end
    },
    {
        name = "NameplateAndUnitFrameTranslator",
        args = nil,
        isEnabled = function()
            return settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_NAMEPLATES_AND_UNIT_FRAMES_OPTION)
        end
    },
    {
        name = "SpellTooltipTranslator",
        args = Enum.TooltipDataType.Spell,
        isEnabled = function()
            return settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SPELL_TOOLTIPS_OPTION)
        end
    },
    {
        name = "UnitTooltipTranslator",
        args = Enum.TooltipDataType.Unit,
        isEnabled = function()
            return settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_UNIT_TOOLTIPS_OPTION)
        end
    },
    {
        name = "SubtitlesTranslator",
        args = nil,
        isEnabled = function()
            return settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SUBTITLES_OPTION)
        end
    },
    {
        name = "NpcMessageTranslator",
        args = nil,
        isEnabled = function()
            return settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_NPC_MESSAGES_OPTION)
        end
    },
    {
        name = "QuestTranslator",
        args = nil,
        isEnabled = function()
            return settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION)
        end
    },
}

local initialized = false

local function createInterfaceOptions()
    local settingsFrame = CreateFrame("Frame", "WowUkrainizerSettings", nil, "WowUkrainizerSettingsFrameTemplate");
    local category, _ = Settings.RegisterCanvasLayoutCategory(settingsFrame, addonName);
    Settings.RegisterAddOnCategory(category);
    addOnSettingsCategoryID = category:GetID()

    local contributorsFrame = CreateFrame("Frame", "WowUkrainizerContributors", nil,
        "WowUkrainizerContributorsFrameTemplate");
    contributorsFrame:SetBestSize(680)

    Settings.RegisterCanvasLayoutSubcategory(category, contributorsFrame, "Причетні");
end

local function preloadAvailableFonts()
    local preloader = CreateFrame('Frame')
    preloader:SetPoint('TOP', UIParent, 'BOTTOM', 0, -500)
    preloader:SetSize(100, 100)

    local preloadFont = function(_, data)
        local loadFont = preloader:CreateFontString()
        loadFont:SetAllPoints()

        if pcall(loadFont.SetFont, loadFont, data, 14) then
            pcall(loadFont.SetText, loadFont, 'cache')
        end
    end

    local sharedFonts = sharedMedia:HashTable('font')
    for key, data in next, sharedFonts do
        preloadFont(key, data)
    end
end

local function setGameFonts()
    local function _setScaledFont(fontFamily, fontName, scale)
        if (not fontFamily) then return end
        local _, height, flags = fontFamily:GetFont()
        fontFamily:SetFont(fontName, height * scale, flags)
    end

    local useDefaultFonts, mainFontName, mainFontScale, titleFontName, titleFontScale, tooltipFontName, tooltipFontScale =
        settingsProvider.GetFontSettings()

    if (useDefaultFonts) then return end

    local fontElements = {
        -- fonts
        { element = SystemFont_Outline_Small,         fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Outline,               fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_InverseShadow_Small,   fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Huge1,                 fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Huge1_Outline,         fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_OutlineThick_Huge2,    fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_OutlineThick_Huge4,    fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_OutlineThick_WTF,      fontName = mainFontName,    scale = mainFontScale },
        { element = NumberFont_GameNormal,            fontName = mainFontName,    scale = mainFontScale },
        { element = Game48FontShadow,                 fontName = mainFontName,    scale = mainFontScale },
        { element = Game15Font_o1,                    fontName = mainFontName,    scale = mainFontScale },
        { element = MailFont_Large,                   fontName = mainFontName,    scale = mainFontScale },
        { element = SpellFont_Small,                  fontName = mainFontName,    scale = mainFontScale },
        { element = InvoiceFont_Med,                  fontName = mainFontName,    scale = mainFontScale },
        { element = InvoiceFont_Small,                fontName = mainFontName,    scale = mainFontScale },
        { element = AchievementFont_Small,            fontName = mainFontName,    scale = mainFontScale },
        { element = ReputationDetailFont,             fontName = mainFontName,    scale = mainFontScale },
        { element = FriendsFont_Normal,               fontName = mainFontName,    scale = mainFontScale },
        { element = FriendsFont_11,                   fontName = mainFontName,    scale = mainFontScale },
        { element = FriendsFont_Small,                fontName = mainFontName,    scale = mainFontScale },
        { element = FriendsFont_Large,                fontName = mainFontName,    scale = mainFontScale },
        { element = GameFont_Gigantic,                fontName = mainFontName,    scale = mainFontScale },
        { element = ChatBubbleFont,                   fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_NamePlateFixed,        fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_LargeNamePlateFixed,   fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_NamePlate,             fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_LargeNamePlate,        fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_NamePlateCastBar,      fontName = mainFontName,    scale = mainFontScale },
        { element = Fancy22Font,                      fontName = titleFontName,   scale = titleFontScale },
        -- glue fonts
        -- INFO: This font can't be changed sine in game they font object are equals nil
        -- { element = SystemFont_Shadow_Outline_Small,    fontName = mainFontName, scale = mainFontScale },
        -- { element = SystemFont_Outline_Med1,            fontName = mainFontName, scale = mainFontScale },
        -- { element = SystemFont_Outline_Med2,            fontName = mainFontName, scale = mainFontScale },
        -- { element = SystemFont_Shadow_Outline_Large,    fontName = mainFontName, scale = mainFontScale },
        -- { element = SystemFont_Shadow_Outline_Gigantor, fontName = mainFontName, scale = mainFontScale },
        -- { element = OptionsFont,                        fontName = mainFontName, scale = mainFontScale },
        { element = OptionsFontSmall,                 fontName = mainFontName,    scale = mainFontScale },
        { element = OptionsFontLarge,                 fontName = mainFontName,    scale = mainFontScale },
        { element = OptionsFontHighlight,             fontName = mainFontName,    scale = mainFontScale },
        { element = OptionsFontHighlightSmall,        fontName = mainFontName,    scale = mainFontScale },
        -- shared fonts
        { element = SystemFont_Tiny2,                 fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Tiny,                  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Small,          fontName = mainFontName,    scale = mainFontScale },
        { element = Game10Font_o1,                    fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Small,                 fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Small2,                fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Small2,         fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Small_Outline,  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Small2_Outline, fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Med1_Outline,   fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Med1,           fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Med2,                  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Med3,                  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Med3,           fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Med3_Outline,   fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Large,                 fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Large_Outline,  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Med2,           fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Med2_Outline,   fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Large,          fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Large2,         fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Huge1,          fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Huge1_Outline,  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Huge2,                 fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Huge2,          fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Huge2_Outline,  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Huge3,          fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Outline_Huge3,  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Huge4,                 fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Huge4,          fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Shadow_Huge4_Outline,  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_World,                 fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_World_ThickOutline,    fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont22_Outline,             fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont22_Shadow_Outline,      fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Med1,                  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_WTF2,                  fontName = mainFontName,    scale = mainFontScale },
        { element = SystemFont_Outline_WTF2,          fontName = mainFontName,    scale = mainFontScale },
        { element = GameTooltipHeader,                fontName = tooltipFontName, scale = tooltipFontScale },
        { element = System_IME,                       fontName = mainFontName,    scale = mainFontScale },
        { element = Tooltip_Med,                      fontName = tooltipFontName, scale = tooltipFontScale },
        { element = Tooltip_Small,                    fontName = tooltipFontName, scale = tooltipFontScale },
        { element = System15Font,                     fontName = mainFontName,    scale = mainFontScale },
        { element = Game30Font,                       fontName = mainFontName,    scale = mainFontScale },
        -- quest fonts
        { element = QuestFont_Large,                  fontName = titleFontName,   scale = titleFontScale },
        { element = QuestFont_Huge,                   fontName = titleFontName,   scale = titleFontScale },
        { element = QuestFont_30,                     fontName = titleFontName,   scale = titleFontScale },
        { element = QuestFont_39,                     fontName = titleFontName,   scale = titleFontScale },
        { element = QuestFont_Outline_Huge,           fontName = titleFontName,   scale = titleFontScale },
        { element = QuestFont_Super_Huge,             fontName = titleFontName,   scale = titleFontScale },
        { element = QuestFont_Super_Huge_Outline,     fontName = titleFontName,   scale = titleFontScale },
        { element = QuestFont_Enormous,               fontName = titleFontName,   scale = titleFontScale },
        { element = QuestFont_Shadow_Small,           fontName = titleFontName,   scale = titleFontScale },
    }
    for _, fontElement in ipairs(fontElements) do
        _setScaledFont(fontElement.element, fontElement.fontName, fontElement.scale)
    end
end

local function initializeAddon()
    if (initialized) then return end

    StaticPopupDialogs["WOW_UKRAINIZAER_RESET_SETTINGS"] = {
        text = "Ви впевнені, що хочете скинути всі налаштування до стандартних значень?",
        button1 = "Продовжити",
        button2 = "Скасувати",
        OnAccept = function()
            settingsProvider:ResetToDefault()
            ReloadUI()
        end,
        OnShow = function() PlaySound(SOUNDKIT.RAID_WARNING) end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    sharedMedia:Register("font", "Arsenal Regular", [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Regular.ttf]])
    sharedMedia:Register("font", "Arsenal Bold", [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Bold.ttf]])
    sharedMedia:Register("font", WOW_UKRAINIZER_ADAPTED_MAIN_FONT_NAME, WOW_UKRAINIZER_ADAPTED_MAIN_FONT_PATH)
    sharedMedia:Register("font", WOW_UKRAINIZER_ADAPTED_TITLE_FONT_NAME, WOW_UKRAINIZER_ADAPTED_TITLE_FONT_PATH)

    if type(WowUkrainizer_MinimapIcon) ~= "table" then
        WowUkrainizer_MinimapIcon = {}
    end

    if LibStub("LibDBIcon-1.0", true) and dataBroker then
        LibStub("LibDBIcon-1.0"):Register("WowUkrainizerMinimapIcon", dataBroker, WowUkrainizer_MinimapIcon)
    end

    local releaseDate = tonumber(C_AddOns.GetAddOnMetadata(addonName, "X-ReleaseDate")) or 0
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    if string.match(version, "-[%w%d][%w%d][%w%d][%w%d][%w%d][%w%d][%w%d][%w%d]$") then
        version = "[alpha] " .. version
    elseif string.match(version, "-alpha$") then
        version = "[alpha] " .. string.gsub(version, "-alpha$", "")
    end

    ns.CommonData = {
        ReleaseDate = releaseDate,
        Version = version,
        VesionStr = "Версія: " ..
            version .. " (" .. date("%d.%m.%y %H:%M:%S", releaseDate) .. ")"
    }
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
    preloadAvailableFonts()
    setGameFonts()

    ns.Frames = {}
    ns.Frames["ChangelogsFrame"] = CreateFrame("Frame", "ChangelogsFrame", UIParent, "WowUkrainizerChangelogsFrame")
    ns.Frames["InstallerFrame"] = CreateFrame("Frame", "InstallerFrame", UIParent, "WowUkrainizerInstallerFrame")

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

    if (settingsProvider.ShouldShowInstallerWizard()) then
        ns.Frames["InstallerFrame"]:ToggleUI()
        settingsProvider.SetOption(WOW_UKRAINIZER_IS_FIRST_RUN_OPTION, false)
    elseif (settingsProvider.ShouldShowChangelog()) then
        ns.Frames["ChangelogsFrame"]:ToggleUI()
        settingsProvider.SetOption(WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION, ns._db.Changelogs[1][1])
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

do
    if LibStub("LibDataBroker-1.1", true) then
        dataBroker = LibStub("LibDataBroker-1.1"):NewDataObject(
            "WowUkrainizerMinimapIcon",
            {
                type = "launcher",
                label = "WowUkrainizerMinimapIcon",
                icon = [[Interface\AddOns\WowUkrainizer\assets\images\logo.png]],
                OnClick = function()
                    if IsShiftKeyDown() then
                        ReloadUI()
                    else
                        Settings.OpenToCategory(addOnSettingsCategoryID)
                    end
                end,
                OnTooltipShow = function(GameTooltip)
                    GameTooltip:SetText("WowUkrainizer", 1, 1, 1)
                    GameTooltip:AddLine(ns.CommonData.VesionStr,
                        NORMAL_FONT_COLOR.r,
                        NORMAL_FONT_COLOR.g,
                        NORMAL_FONT_COLOR.b, 1)
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("ЛКМ щоб відкрити налаштування",
                        RAID_CLASS_COLORS.MAGE.r,
                        RAID_CLASS_COLORS.MAGE.g,
                        RAID_CLASS_COLORS.MAGE.b)
                    GameTooltip:AddLine("Shift + ЛКМ щоб перезавантажити інтерфейс (/reload)",
                        RAID_CLASS_COLORS.MAGE.r,
                        RAID_CLASS_COLORS.MAGE.g,
                        RAID_CLASS_COLORS.MAGE.b)
                end
            }
        )
    end
end

eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")
