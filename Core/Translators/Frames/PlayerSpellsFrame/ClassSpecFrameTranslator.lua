--- @class WowUkrainizerInternals
local ns = select(2, ...);

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

local GetTranslatedSpecialization = ns.DbContext.Player.GetTranslatedSpecialization
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local GetTranslatedRole = ns.DbContext.Player.GetTranslatedRole
local GetTranslatedAttribute = ns.DbContext.Player.GetTranslatedAttribute
local GetTranslatedSpecializationNote = ns.DbContext.Player.GetTranslatedSpecializationNote
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local SetText = ns.FontStringUtil.SetText

---@class ClassSpecFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SPELLBOOK_FRAME_OPTION)
end

local function SpecFrame_UpdateSpecContents(specTab)
    for specContentFrame in specTab.SpecContentFramePool:EnumerateActive() do
        local sex = UnitSex("player");
        local _, _, description, _, _, primaryStat = GetSpecializationInfo(specContentFrame.specIndex, false, false,
            nil, sex);
        if primaryStat and primaryStat ~= 0 then
            local translatedStat = GetTranslatedAttribute(SPEC_STAT_STRINGS[primaryStat])
            local translatedDescription = GetTranslatedSpecializationNote(description) ..
                "|n" .. GetTranslatedGlobalString(_G["SPEC_FRAME_PRIMARY_STAT"]):format(translatedStat)
            SetText(specContentFrame.Description, translatedDescription)
        end
        UpdateTextWithTranslation(specContentFrame.SpecName, GetTranslatedSpecialization)
        UpdateTextWithTranslation(specContentFrame.SampleAbilityText, GetTranslatedGlobalString)
        UpdateTextWithTranslation(specContentFrame.ActivatedText, GetTranslatedGlobalString)
        UpdateTextWithTranslation(specContentFrame.ActivateButton.Text, GetTranslatedGlobalString)
        UpdateTextWithTranslation(specContentFrame.RoleName, GetTranslatedRole)
    end
end

function translator:Init()
    local function OnAddOnLoaded(_, name)
        if (name == "Blizzard_PlayerSpells") then
            hooksecurefunc(PlayerSpellsFrame.SpecFrame, "UpdateSpecContents", SpecFrame_UpdateSpecContents)
            eventHandler:Unregister(OnAddOnLoaded, "ADDON_LOADED")
        end
    end
    eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")
end

ns.TranslationsManager:AddTranslator(translator)
