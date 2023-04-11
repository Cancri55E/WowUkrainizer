local addonName, ns = ...;

local eventHandler = ns.EventHandler:new()

local gameTooltipFontName = [[Interface\AddOns\WoWUkrainify\assets\Arsenal_Regular.ttf]]

local function OnPlayerLogin()
    if (not _G.WoWUkrainify_UntranslatedData) then
        _G.WoWUkrainify_UntranslatedData = {}
    end

    local _, height, flags = GameTooltipHeaderText:GetFont()
    GameTooltipHeaderText:SetFont(gameTooltipFontName, height * 1.1, flags)

    local _, height, flags = GameTooltipText:GetFont()
    GameTooltipText:SetFont(gameTooltipFontName, height * 1.1, flags)

    local _, height, flags = GameTooltipTextSmall:GetFont()
    GameTooltipTextSmall:SetFont(gameTooltipFontName, height * 1.1, flags)

    ns.UnitTooltipTranslator.SetEnabled(true)
    ns.UnitTooltipTranslator.EnableDebugInfo(true)

    ns.SpellTooltipTranslator.SetEnabled(true)
    ns.SpellTooltipTranslator.EnableDebugInfo(true)
end

local function OnAddOnLoaded(_, name)
    if (name == addonName) then
        if name == addonName then
            if not IsLoggedIn() then
                eventHandler:Register(OnPlayerLogin, "PLAYER_LOGIN")
            else
                OnPlayerLogin()
            end
        end
    end
end

eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")
