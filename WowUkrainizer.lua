local addonName, ns = ...;

local sharedMedia = LibStub("LibSharedMedia-3.0")
local settingsProvider = ns.SettingsProvider:new()

local SetFont = ns.FontStringExtensions.SetFont

local unitTooltipTranslator, spellTooltipTranslator, spellbookFrameTranslator, classTalentFrameTranslator
local nameplateAndUnitFrameTranslator, movieTranslator

local initialized = false

local function createInterfaceOptions()
    settingsProvider:Build()

    local namespace = "WowUkrainizer"
    LibStub("AceConfig-3.0"):RegisterOptionsTable(namespace, ns.Options)

    local configDialogLib = LibStub("AceConfigDialog-3.0")
    configDialogLib:AddToBlizOptions(namespace, nil, nil, "General")
end

local function setGameFonts()
    local useDefaultFonts, fontName, fontScale, tooltipHeaderFontScale, tooltipFontScale =
        settingsProvider.GetFontSettings()

    if (useDefaultFonts) then return end

    -- System fonts
    SetFont(SystemFont_Shadow_Med1, fontName, fontScale)
    SetFont(SystemFont_Shadow_Small, fontName, fontScale)
    SetFont(SystemFont_Shadow_Med2, fontName, fontScale)
    SetFont(SystemFont_Shadow_Large2, fontName, fontScale)
    SetFont(Game30Font, fontName, fontScale)

    -- Tooltip fonts
    SetFont(GameTooltipHeader, fontName, tooltipHeaderFontScale)
    SetFont(Tooltip_Med, fontName, tooltipFontScale)
    SetFont(Tooltip_Small, fontName, tooltipFontScale)
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

local eventHandler = ns.EventHandler:new()

local function OnAddOnLoaded(_, name)
    local function OnPlayerLogin()
        settingsProvider:Load()
        createInterfaceOptions()
        setGameFonts();

        local translateClassTalentsFrame, translateSpellbookFrame, translateNameplatesAndUnitFrames, translateSpellTooltips, translateUnitTooltips, translateMovieSubtitles =
            settingsProvider.GetTranslatorsState()

        -- Tooltips
        if (translateUnitTooltips) then
            unitTooltipTranslator = ns.Translators.UnitTooltipTranslator:new(Enum.TooltipDataType.Unit)
            unitTooltipTranslator:SetEnabled(true)
        end

        if (translateSpellTooltips) then
            spellTooltipTranslator = ns.Translators.SpellTooltipTranslator:new(Enum.TooltipDataType.Spell)
            spellTooltipTranslator:SetEnabled(true)
        end

        -- Frames
        if (translateSpellbookFrame) then
            spellbookFrameTranslator = ns.Translators.SpellbookFrameTranslator:new()
            spellbookFrameTranslator:SetEnabled(true)
        end

        if (translateClassTalentsFrame) then
            classTalentFrameTranslator = ns.Translators.ClassTalentFrameTranslator:new()
            classTalentFrameTranslator:SetEnabled(true)
        end
        -- Other
        if (translateNameplatesAndUnitFrames) then
            nameplateAndUnitFrameTranslator = ns.Translators.NameplateAndUnitFrameTranslator:new()
            nameplateAndUnitFrameTranslator:SetEnabled(true)
        end
        if (translateMovieSubtitles) then
            movieTranslator = ns.Translators.MovieTranslator:new()
            movieTranslator:SetEnabled(true)
        end
    end

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
