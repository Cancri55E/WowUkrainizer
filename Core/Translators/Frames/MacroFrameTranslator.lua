--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local SetText = ns.FontStringUtil.SetText

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

---@class MacroFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true -- TODO: Add settings
end

function translator:Init()
    local function OnAddOnLoaded(_, name)
        if (name == "Blizzard_MacroUI") then
            UpdateTextWithTranslation(MacroEditButton.Text, GetTranslatedGlobalString)
            UpdateTextWithTranslation(MacroCancelButton.Text, GetTranslatedGlobalString)
            UpdateTextWithTranslation(MacroSaveButton.Text, GetTranslatedGlobalString)
            UpdateTextWithTranslation(MacroDeleteButton.Text, GetTranslatedGlobalString)
            UpdateTextWithTranslation(MacroNewButton.Text, GetTranslatedGlobalString)
            UpdateTextWithTranslation(MacroExitButton.Text, GetTranslatedGlobalString)

            UpdateTextWithTranslation(MacroFrameEnterMacroText, GetTranslatedGlobalString)

            UpdateTextWithTranslation(MacroFrame.Tabs[1].Text, GetTranslatedGlobalString)
            UpdateTextWithTranslation(MacroFrame.Tabs[2].Text, function()
                return GetTranslatedGlobalString(CHARACTER_SPECIFIC_MACROS):format(ns.PlayerInfo.Name)
            end)

            MacroFrame.Tabs[2]:HookScript("OnEnter", function(tabFrame)
                if ( tabFrame:GetFontString():IsTruncated() ) then
                    local currentTooltipOwner = GameTooltip:GetOwner()
                    if (currentTooltipOwner and currentTooltipOwner ~= tabFrame) then return end
                    SetText(_G["GameTooltipTextLeft1"], GetTranslatedGlobalString(CHARACTER_SPECIFIC_MACROS):format(ns.PlayerInfo.Name))
                    GameTooltip:Show()
                end
            end)

            MacroFrameText:HookScript("OnTextChanged", function()
                UpdateTextWithTranslation(MacroFrameCharLimitText, GetTranslatedGlobalString)
            end)

            local staticPopupSubscriber = ns.StaticPopupSubscriber:GetInstance()
            staticPopupSubscriber:Subscribe("CONFIRM_DELETE_SELECTED_MACRO", function(dialog)
                UpdateTextWithTranslation(dialog.text, function()
                    return GetTranslatedGlobalString(CONFIRM_DELETE_MACRO)
                end)
                UpdateTextWithTranslation(dialog.button1.Text, GetTranslatedGlobalString)
                UpdateTextWithTranslation(dialog.button2.Text, GetTranslatedGlobalString)
            end)

            ns.SelectedIconFrameTranslationUtil:TranslateSelectedIconFrame(MacroPopupFrame)

            eventHandler:Unregister(OnAddOnLoaded, "ADDON_LOADED")
        end
    end
    eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")
end

ns.TranslationsManager:AddTranslator(translator)