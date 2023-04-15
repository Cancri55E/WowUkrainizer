local addonName, ns = ...;

local eventHandler = ns.EventHandler:new()

local unitTooltipTranslator, spellTooltipTranslator
local initialized = false

local function setGameTooltipFont()
    local gameTooltipFontName = [[Interface\AddOns\WowUkrainizer\assets\Arsenal_Regular.ttf]]
    local _, height, flags = GameTooltipHeaderText:GetFont()
    GameTooltipHeaderText:SetFont(gameTooltipFontName, height * 1.1, flags)

    local _, height, flags = GameTooltipText:GetFont()
    GameTooltipText:SetFont(gameTooltipFontName, height * 1.1, flags)

    local _, height, flags = GameTooltipTextSmall:GetFont()
    GameTooltipTextSmall:SetFont(gameTooltipFontName, height * 1.1, flags)
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

    setGameTooltipFont()
    regAddonCommands()

    unitTooltipTranslator = ns.Translators.UnitTooltipTranslator:new(Enum.TooltipDataType.Unit)
    spellTooltipTranslator = ns.Translators.SpellTooltipTranslator:new(Enum.TooltipDataType.Spell)
end

local function OnAddOnLoaded(_, name)
    local function OnPlayerLogin()
        unitTooltipTranslator:SetEnabled(true)
        spellTooltipTranslator:SetEnabled(true)
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
