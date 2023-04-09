local addonName, ns = ...;

local eventHandler = ns.EventHandler:new()

local function OnPlayerLogin()
    _G.WoWUkrainify_UntranslatedData = {}

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
