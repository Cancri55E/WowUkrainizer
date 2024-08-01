--- @class WowUkrainizerInternals
local ns = select(2, ...);

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

local GetTranslatedClass = ns.DbContext.Units.GetTranslatedClass
local GetTranslatedSpecialization = ns.DbContext.Units.GetTranslatedSpecialization
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation

---@class PlayerSpellsFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SPELLBOOK_FRAME_OPTION)
end

local function PlayerSpellsFrame_UpdateFrameTitle(playerSpellsFrame)
    if playerSpellsFrame:IsInspecting() then
        local inspectUnit = playerSpellsFrame:GetInspectUnit();
        if inspectUnit then
            playerSpellsFrame:SetTitle(GetTranslatedGlobalString(TALENTS_INSPECT_FORMAT):format(UnitName(playerSpellsFrame:GetInspectUnit())));
        else
            playerSpellsFrame:SetTitle(GetTranslatedGlobalString(TALENTS_LINK_FORMAT):format(
                GetTranslatedSpecialization(playerSpellsFrame:GetSpecName()),
                GetTranslatedClass(playerSpellsFrame:GetClassName())));
        end
    else
        UpdateTextWithTranslation(playerSpellsFrame:GetTitleText(), GetTranslatedGlobalString)
    end
end

function translator:Init()
    local function OnAddOnLoaded(_, name)
        if (name == "Blizzard_PlayerSpells") then
            for i = 1, 3, 1 do
                UpdateTextWithTranslation(PlayerSpellsFrame.TabSystem.tabs[i].Text, GetTranslatedGlobalString)
            end

            hooksecurefunc(PlayerSpellsFrame, "UpdateFrameTitle", PlayerSpellsFrame_UpdateFrameTitle)

            eventHandler:Unregister(OnAddOnLoaded, "ADDON_LOADED")
        end
    end
    eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")
end

ns.TranslationsManager:AddTranslator(translator)
