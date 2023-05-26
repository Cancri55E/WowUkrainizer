local addonName, ns = ...;

local SetFont = ns.FontStringExtensions.SetFont

ns.DefaultFontName = [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Regular.ttf]]
ns.DefaultBoldFontName = [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Bold.ttf]]

local eventHandler = ns.EventHandler:new()

local unitTooltipTranslator, spellTooltipTranslator, spellbookFrameTranslator, classTalentFrameTranslator
local initialized = false

local function setGameFonts(fontName)
    local tooltipFontScale = 1.1
    local tooltipHeaderFontScale = 1.15
    local fontScale = 1.10

    SetFont(SystemFont_Shadow_Med1, fontName, fontScale)
    SetFont(SystemFont_Shadow_Small, fontName, fontScale)
    SetFont(SystemFont_Shadow_Med2, fontName, fontScale)
    SetFont(SystemFont_Shadow_Large2, fontName, fontScale)
    SetFont(Game30Font, fontName, fontScale)

    -- Tooltips
    SetFont(GameTooltipHeader, fontName, tooltipHeaderFontScale)
    SetFont(Tooltip_Med, fontName, tooltipFontScale)
    SetFont(Tooltip_Small, fontName, tooltipFontScale)
end

local function regAddonCommands()
    local function SlashCommandHandler(msg, _)
        local command, objectType, enable = msg:lower():match("(%S+)%s*(%S*)%s*(%S*)")

        if objectType == "0" then
            enable = false
        elseif objectType == "1" then
            enable = true
        else
            print("|cFFFF0000Помилка:|r Невірний аргумент. Використовуйте 0 або 1.")
            return
        end

        if command == "spell" then
            spellTooltipTranslator:SetEnabled(enable)
            print((enable and "|cFF00FF00Увімкнуто|r" or "|cFFFF0000Вимкнуто|r")
                .. " |cFFFFD700переклад заклинань та талантів.|r")
        elseif command == "unit" then
            unitTooltipTranslator:SetEnabled(enable)
            print((enable and "|cFF00FF00Увімкнуто|r" or "|cFFFF0000Вимкнуто|r")
                .. " |cFFFFD700переклад імен НІП.|r")
        else
            print("|cFFFF0000Помилка:|r Невідома команда.")
        end
    end

    SLASH_WOWUKRAINIZER1 = "/wowukrainizer"
    SLASH_WOWUKRAINIZER2 = "/wu"

    SlashCmdList["WOWUKRAINIZER"] = SlashCommandHandler
    SlashCmdList["WU"] = SlashCommandHandler
end

local function initializeAddon()
    if (initialized) then return end

    setGameFonts(ns.DefaultFontName)
    regAddonCommands()

    -- Tooltips
    unitTooltipTranslator = ns.Translators.UnitTooltipTranslator:new(Enum.TooltipDataType.Unit)
    spellTooltipTranslator = ns.Translators.SpellTooltipTranslator:new(Enum.TooltipDataType.Spell)

    -- Frames
    spellbookFrameTranslator = ns.Translators.SpellbookFrameTranslator:new()
    classTalentFrameTranslator = ns.Translators.ClassTalentFrameTranslator:new()
end

local function OnAddOnLoaded(_, name)
    local function OnPlayerLogin()
        -- Tooltips
        unitTooltipTranslator:SetEnabled(true)
        spellTooltipTranslator:SetEnabled(true)
        -- Frames
        spellbookFrameTranslator:SetEnabled(true)
        classTalentFrameTranslator:SetEnabled(true)
    end

    if (name == addonName) then
        if name == addonName then
            initializeAddon()
            if not IsLoggedIn() then
                eventHandler:Register(OnPlayerLogin, "PLAYER_LOGIN")
            else
                OnPlayerLogin()
            end
        end
    end
end

eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")
