--- @type string
local addonName = select(1, ...);

--- @class WowUkrainizerInternals
local ns = select(2, ...);

local _G = _G

local sharedMedia = LibStub("LibSharedMedia-3.0")
local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

local minimapDataBroker
local addOnSettingsCategoryID

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
    local function _setScaledFont(fontFamily, fontName, size, scale)
        if (not fontFamily) then return end
        local _, _, flags = fontFamily:GetFont()
        fontFamily:SetFont(fontName, size * scale, flags)
    end

    local useDefaultFonts, mainFontName, mainFontScale, titleFontName, titleFontScale, tooltipFontName, tooltipFontScale =
        ns.SettingsProvider.GetFontSettings()

    if (useDefaultFonts) then return end

    local fontElements = {
        -- fonts
        { element = SystemFont_Outline_Small,         fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = SystemFont_Outline,               fontName = mainFontName,    scale = mainFontScale,    size = 13 },
        { element = SystemFont_InverseShadow_Small,   fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = SystemFont_Huge1,                 fontName = mainFontName,    scale = mainFontScale,    size = 20 },
        { element = SystemFont_Huge1_Outline,         fontName = mainFontName,    scale = mainFontScale,    size = 20 },
        { element = SystemFont_OutlineThick_Huge2,    fontName = mainFontName,    scale = mainFontScale,    size = 22 },
        { element = SystemFont_OutlineThick_Huge4,    fontName = mainFontName,    scale = mainFontScale,    size = 26 },
        { element = SystemFont_OutlineThick_WTF,      fontName = mainFontName,    scale = mainFontScale,    size = 32 },
        { element = NumberFont_GameNormal,            fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = Game48FontShadow,                 fontName = mainFontName,    scale = mainFontScale,    size = 48 },
        { element = Game15Font_o1,                    fontName = mainFontName,    scale = mainFontScale,    size = 15 },
        { element = MailFont_Large,                   fontName = mainFontName,    scale = mainFontScale,    size = 15 },
        { element = SpellFont_Small,                  fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = InvoiceFont_Med,                  fontName = mainFontName,    scale = mainFontScale,    size = 12 },
        { element = InvoiceFont_Small,                fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = AchievementFont_Small,            fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = ReputationDetailFont,             fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = FriendsFont_Normal,               fontName = mainFontName,    scale = mainFontScale,    size = 12 },
        { element = FriendsFont_11,                   fontName = mainFontName,    scale = mainFontScale,    size = 11 },
        { element = FriendsFont_Small,                fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = FriendsFont_Large,                fontName = mainFontName,    scale = mainFontScale,    size = 14 },
        { element = GameFont_Gigantic,                fontName = mainFontName,    scale = mainFontScale,    size = 32 },

        { element = ChatBubbleFont,                   fontName = mainFontName,    scale = mainFontScale,    size = 14 },
        { element = SystemFont_NamePlate,             fontName = mainFontName,    scale = mainFontScale,    size = 9 },
        { element = SystemFont_NamePlateFixed,        fontName = mainFontName,    scale = mainFontScale,    size = 14 },
        { element = SystemFont_LargeNamePlate,        fontName = mainFontName,    scale = mainFontScale,    size = 12 },
        { element = SystemFont_LargeNamePlateFixed,   fontName = mainFontName,    scale = mainFontScale,    size = 20 },
        { element = Fancy22Font,                      fontName = titleFontName,   scale = titleFontScale,   size = 22 },
        -- glue fonts
        -- INFO: This font can't be changed sine in game they font object are equals nil
        -- { element = SystemFont_Shadow_Outline_Small,    fontName = mainFontName, scale = mainFontScale },
        -- { element = SystemFont_Outline_Med1,            fontName = mainFontName, scale = mainFontScale },
        -- { element = SystemFont_Outline_Med2,            fontName = mainFontName, scale = mainFontScale },
        -- { element = SystemFont_Shadow_Outline_Large,    fontName = mainFontName, scale = mainFontScale },
        -- { element = SystemFont_Shadow_Outline_Gigantor, fontName = mainFontName, scale = mainFontScale },
        -- { element = OptionsFont,                        fontName = mainFontName, scale = mainFontScale },
        { element = OptionsFontSmall,                 fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = OptionsFontLarge,                 fontName = mainFontName,    scale = mainFontScale,    size = 18 },
        { element = OptionsFontHighlight,             fontName = mainFontName,    scale = mainFontScale,    size = 12 },
        { element = OptionsFontHighlightSmall,        fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        -- shared fonts
        { element = SystemFont_Tiny2,                 fontName = mainFontName,    scale = mainFontScale,    size = 8 },
        { element = SystemFont_Tiny,                  fontName = mainFontName,    scale = mainFontScale,    size = 9 },
        { element = SystemFont_Shadow_Small,          fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = Game10Font_o1,                    fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = SystemFont_Small,                 fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = SystemFont_Small2,                fontName = mainFontName,    scale = mainFontScale,    size = 11 },
        { element = SystemFont_Shadow_Small2,         fontName = mainFontName,    scale = mainFontScale,    size = 11 },
        { element = SystemFont_Shadow_Small_Outline,  fontName = mainFontName,    scale = mainFontScale,    size = 10 },
        { element = SystemFont_Shadow_Small2_Outline, fontName = mainFontName,    scale = mainFontScale,    size = 11 },
        { element = SystemFont_Shadow_Med1_Outline,   fontName = mainFontName,    scale = mainFontScale,    size = 12 },
        { element = SystemFont_Shadow_Med1,           fontName = mainFontName,    scale = mainFontScale,    size = 12 },
        { element = SystemFont_Med2,                  fontName = mainFontName,    scale = mainFontScale,    size = 13 },
        { element = SystemFont_Med3,                  fontName = mainFontName,    scale = mainFontScale,    size = 14 },
        { element = SystemFont_Shadow_Med3,           fontName = mainFontName,    scale = mainFontScale,    size = 14 },
        { element = SystemFont_Shadow_Med3_Outline,   fontName = mainFontName,    scale = mainFontScale,    size = 14 },
        { element = SystemFont_Large,                 fontName = mainFontName,    scale = mainFontScale,    size = 16 },
        { element = SystemFont_Shadow_Large_Outline,  fontName = mainFontName,    scale = mainFontScale,    size = 16 },
        { element = SystemFont_Shadow_Med2,           fontName = mainFontName,    scale = mainFontScale,    size = 14 },
        { element = SystemFont_Shadow_Med2_Outline,   fontName = mainFontName,    scale = mainFontScale,    size = 14 },
        { element = SystemFont_Shadow_Large,          fontName = mainFontName,    scale = mainFontScale,    size = 16 },
        { element = SystemFont_Large2,                fontName = mainFontName,    scale = mainFontScale,    size = 18 },
        { element = SystemFont_Shadow_Large2,         fontName = mainFontName,    scale = mainFontScale,    size = 18 },
        { element = SystemFont_Shadow_Large2_Outline, fontName = mainFontName,    scale = mainFontScale,    size = 18 },
        { element = Game17Font_Shadow,                fontName = mainFontName,    scale = mainFontScale,    size = 17 },
        { element = SystemFont_Shadow_Huge1,          fontName = mainFontName,    scale = mainFontScale,    size = 20 },
        { element = SystemFont_Shadow_Huge1_Outline,  fontName = mainFontName,    scale = mainFontScale,    size = 20 },
        { element = SystemFont_Huge2,                 fontName = mainFontName,    scale = mainFontScale,    size = 24 },
        { element = SystemFont_Shadow_Huge2,          fontName = mainFontName,    scale = mainFontScale,    size = 24 },
        { element = SystemFont_Shadow_Huge2_Outline,  fontName = mainFontName,    scale = mainFontScale,    size = 24 },
        { element = SystemFont_Shadow_Huge3,          fontName = mainFontName,    scale = mainFontScale,    size = 25 },
        { element = SystemFont_Shadow_Outline_Huge3,  fontName = mainFontName,    scale = mainFontScale,    size = 25 },
        { element = SystemFont_Huge4,                 fontName = mainFontName,    scale = mainFontScale,    size = 27 },
        { element = SystemFont_Shadow_Huge4,          fontName = mainFontName,    scale = mainFontScale,    size = 27 },
        { element = SystemFont_Shadow_Huge4_Outline,  fontName = mainFontName,    scale = mainFontScale,    size = 27 },
        { element = SystemFont_World,                 fontName = mainFontName,    scale = mainFontScale,    size = 64 },
        { element = SystemFont_World_ThickOutline,    fontName = mainFontName,    scale = mainFontScale,    size = 64 },
        { element = SystemFont22_Outline,             fontName = mainFontName,    scale = mainFontScale,    size = 22 },
        { element = SystemFont22_Shadow_Outline,      fontName = mainFontName,    scale = mainFontScale,    size = 22 },
        { element = SystemFont_Med1,                  fontName = mainFontName,    scale = mainFontScale,    size = 12 },
        { element = SystemFont_WTF2,                  fontName = mainFontName,    scale = mainFontScale,    size = 36 },
        { element = SystemFont_Outline_WTF2,          fontName = mainFontName,    scale = mainFontScale,    size = 36 },
        { element = GameTooltipHeader,                fontName = tooltipFontName, scale = tooltipFontScale, size = 14 },
        { element = System_IME,                       fontName = mainFontName,    scale = mainFontScale,    size = 16 },
        { element = Tooltip_Med,                      fontName = tooltipFontName, scale = tooltipFontScale, size = 12 },
        { element = Tooltip_Small,                    fontName = tooltipFontName, scale = tooltipFontScale, size = 10 },
        { element = System15Font,                     fontName = mainFontName,    scale = mainFontScale,    size = 15 },
        { element = Game11Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 11 },
        { element = Game12Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 12 },
        { element = Game13Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 13 },
        { element = Game13FontShadow,                 fontName = mainFontName,    scale = mainFontScale,    size = 13 },
        { element = Game15Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 15 },
        { element = Game15Font_Shadow,                fontName = mainFontName,    scale = mainFontScale,    size = 15 },
        { element = Game16Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 16 },
        { element = Game18Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 18 },
        { element = Game20Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 20 },
        { element = Game24Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 24 },
        { element = Game27Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 27 },
        { element = Game30Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 30 },
        { element = Game32Font_Shadow2,               fontName = mainFontName,    scale = mainFontScale,    size = 32 },
        { element = Game36Font_Shadow2,               fontName = mainFontName,    scale = mainFontScale,    size = 36 },
        { element = Game36Font_Shadow2,               fontName = mainFontName,    scale = mainFontScale,    size = 36 },
        { element = Game46Font_Shadow2,               fontName = mainFontName,    scale = mainFontScale,    size = 46 },
        { element = Game52Font_Shadow2,               fontName = mainFontName,    scale = mainFontScale,    size = 52 },
        { element = Game58Font_Shadow2,               fontName = mainFontName,    scale = mainFontScale,    size = 58 },
        { element = Game69Font_Shadow2,               fontName = mainFontName,    scale = mainFontScale,    size = 72 },
        { element = Game72Font,                       fontName = mainFontName,    scale = mainFontScale,    size = 69 },
        { element = Game72Font_Shadow,                fontName = mainFontName,    scale = mainFontScale,    size = 72 },
        -- quest fonts
        { element = QuestFont_Large,                  fontName = titleFontName,   scale = titleFontScale,   size = 15 },
        { element = QuestFont_Huge,                   fontName = titleFontName,   scale = titleFontScale,   size = 18 },
        { element = QuestFont_30,                     fontName = titleFontName,   scale = titleFontScale,   size = 30 },
        { element = QuestFont_39,                     fontName = titleFontName,   scale = titleFontScale,   size = 39 },
        { element = QuestFont_Outline_Huge,           fontName = titleFontName,   scale = titleFontScale,   size = 18 },
        { element = QuestFont_Super_Huge,             fontName = titleFontName,   scale = titleFontScale,   size = 24 },
        { element = QuestFont_Super_Huge_Outline,     fontName = titleFontName,   scale = titleFontScale,   size = 24 },
        { element = QuestFont_Enormous,               fontName = titleFontName,   scale = titleFontScale,   size = 30 },
        { element = QuestFont_Shadow_Small,           fontName = titleFontName,   scale = titleFontScale,   size = 14 }, --
        -- objectives fonts
        { element = ObjectiveTrackerFont12,           fontName = mainFontName,    scale = mainFontScale,    size = 12 },
        { element = ObjectiveTrackerFont13,           fontName = mainFontName,    scale = mainFontScale,    size = 13 },
        { element = ObjectiveTrackerFont14,           fontName = mainFontName,    scale = mainFontScale,    size = 14 },
        { element = ObjectiveTrackerFont15,           fontName = mainFontName,    scale = mainFontScale,    size = 15 },
        { element = ObjectiveTrackerFont16,           fontName = mainFontName,    scale = mainFontScale,    size = 16 },
        { element = ObjectiveTrackerFont17,           fontName = mainFontName,    scale = mainFontScale,    size = 17 },
        { element = ObjectiveTrackerFont18,           fontName = mainFontName,    scale = mainFontScale,    size = 18 },
        { element = ObjectiveTrackerFont19,           fontName = mainFontName,    scale = mainFontScale,    size = 19 },
        { element = ObjectiveTrackerFont20,           fontName = mainFontName,    scale = mainFontScale,    size = 20 },
        { element = ObjectiveTrackerFont21,           fontName = mainFontName,    scale = mainFontScale,    size = 21 },
        { element = ObjectiveTrackerFont22,           fontName = mainFontName,    scale = mainFontScale,    size = 22 },
    }
    for _, fontElement in ipairs(fontElements) do
        _setScaledFont(fontElement.element, fontElement.fontName, fontElement.size, fontElement.scale)
    end
end

local function initializeAddon()
    if (initialized) then return end

    ns:CreateSettingsProvider()
    ns:CreateUntranslatedDataStorage()

    _G["StaticPopupDialogs"]["WOW_UKRAINIZAER_RESET_SETTINGS"] = {
        text = "Ви впевнені, що хочете скинути всі налаштування до стандартних значень?",
        button1 = "Продовжити",
        button2 = "Скасувати",
        OnAccept = function()
            ns.SettingsProvider:ResetToDefault()
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

    if LibStub("LibDBIcon-1.0", true) and minimapDataBroker then
        LibStub("LibDBIcon-1.0"):Register("WowUkrainizerMinimapIcon", minimapDataBroker, WowUkrainizer_MinimapIcon)
    end

    local releaseDate = tonumber(C_AddOns.GetAddOnMetadata(addonName, "X-ReleaseDate")) or 0
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")

    ns.AddonInfo = {
        ReleaseDate = releaseDate,
        Version = version,
        VesionStr = "Версія: " ..
            version .. " (" .. date("%d.%m.%y %H:%M:%S", releaseDate) .. ")"
    }

    ns.Frames = {}
    ns.Frames["WarningFrame"] = CreateFrame("FRAME", "WarningFrame", UIParent, "WowUkrainizerWarningFrame")

    if (ns.SettingsProvider.ShouldShowChangelog() and ns.AddonInfo.Version == "[alpha] 1.10.0") then
        ns.Frames["WarningFrame"]:ShowWarning("|cffE60965Остання Alpha версія!|r",
            "|cffFFD150УВАГА! 1.10.0 остання версія яка буде виходити як Alpha. " ..
            "Тому, будь ласка, оновить додаток до Release версії (в CurseForge клієнті натисніть ПКМ на додатку -> Release Type -> Release)|r",
            150)
    end
end

local function ShowUnsupportedLangWarning(locale)
    local firstMessage =
    "Для роботи доповнення потрібно встановити англійську мову в грі. Інші мови наразі не підтримуються."

    local ruMessage =
    "|cffE60965Увага! Підтримка російської мови не планується.|r Однак ми рекомендуємо вам спробувати пограти українською на європейських серверах. Там діють дружні українські гільдії та спільноти, які з радістю доповнять ваш ігровий досвід цікавими подіями та спілкуванням."

    local lastMessage = [[Дякуємо за розуміння та підтримку!

Хочемо нагадати, що наразі не весь контент гри перекладено українською. Однак команда перекладачів працює цілодобово, й нові переклади та виправлення з'являються майже щодня. Ми докладаємо максимум зусиль, тому, будь ласка будьте терплячими та насолоджуйтесь грою українською в міру появи нових перекладів.]]

    local height = 230
    local msg = firstMessage .. "|n|n"
    if (locale == "ruRU") then
        msg = msg .. ruMessage .. "|n|n"
        height = 270
    end
    msg = msg .. lastMessage

    ns.Frames["WarningFrame"]:ShowWarning("|cffE60965Переклад з вибраної мови неможливий!|r", msg, height)
end

local function OnPlayerLogin()
    ns.PlayerInfo = {
        Name = GetUnitName("player"),
        Realm = GetRealmName(),
        Race = UnitRace("player"),
        Class = UnitClass("player"),
        Gender = UnitSex("player")
    }

    ns:CreateIngameDataCacher()
    createInterfaceOptions()
    preloadAvailableFonts()
    setGameFonts()

    ns.Frames["ChangelogsFrame"] = CreateFrame("Frame", "ChangelogsFrame", UIParent, "WowUkrainizerChangelogsFrame")
    ns.Frames["InstallerFrame"] = CreateFrame("Frame", "InstallerFrame", UIParent, "WowUkrainizerInstallerFrame")

    ns.TranslationsManager:Init()

    local settingsProvider = ns.SettingsProvider
    if (settingsProvider) then
        if (settingsProvider.ShouldShowInstallerWizard()) then
            ns.Frames["InstallerFrame"]:ToggleUI()
            settingsProvider.SetOption(WOW_UKRAINIZER_IS_FIRST_RUN_OPTION, false)
        elseif (settingsProvider.ShouldShowChangelog()) then
            ns.Frames["ChangelogsFrame"]:ToggleUI()
            settingsProvider.SetOption(WOW_UKRAINIZER_LAST_AUTO_SHOWN_CHANGELOG_VERSION_OPTION, ns._db.Changelogs[1].version)
        end
    end
end

local function OnAddOnLoaded(_, name)
    if (name == addonName) then
        initializeAddon()

        local locale = GetLocale()
        if (locale ~= "enGB" and locale ~= "enUS") then
            ShowUnsupportedLangWarning(locale)
            return
        end

        if not IsLoggedIn() then
            eventHandler:Register(OnPlayerLogin, "PLAYER_LOGIN")
        else
            OnPlayerLogin()
        end
    end
end

do
    if LibStub("LibDataBroker-1.1", true) then
        minimapDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject(
            "WowUkrainizerMinimapIcon",
            {
                type = "launcher",
                label = "WowUkrainizerMinimapIcon",
                icon = [[Interface\AddOns\WowUkrainizer\assets\images\logo.png]],
                OnClick = function()
                    if IsShiftKeyDown() then
                        ReloadUI()
                    else
                        local locale = GetLocale()
                        if (locale ~= "enGB" and locale ~= "enUS") then
                            ShowUnsupportedLangWarning(locale)
                        else
                            Settings.OpenToCategory(addOnSettingsCategoryID)
                        end
                    end
                end,
                OnTooltipShow = function(GameTooltip)
                    GameTooltip:SetText("WowUkrainizer", 1, 1, 1)
                    GameTooltip:AddLine(ns.AddonInfo.VesionStr,
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
