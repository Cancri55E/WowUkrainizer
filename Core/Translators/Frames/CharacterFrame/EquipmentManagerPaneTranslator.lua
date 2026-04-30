--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedSpecialization = ns.DbContext.Player.GetTranslatedSpecialization
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local OnUpdateGameTooltip = function(expectedOwner)
    ns.TooltipUtil:OnUpdateGameTooltip(expectedOwner, GetTranslatedGlobalString, true)
end

---@class EquipmentManagerPaneTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_CHARACTER_FRAME_OPTION)
end

local updatedEquipmentManagerPaneButtons = {}

local function PaperDollFrame_EquipmentManagerPane_OnUpdate_Hook(pane)
    pane.ScrollBox:ForEachFrame(function(button)
        if (not button.setID) then
            UpdateTextWithTranslation(button.text, GetTranslatedGlobalString)
        else
            if (not updatedEquipmentManagerPaneButtons[button.setID]) then
                button.EditButton:HookScript("OnEnter", OnUpdateGameTooltip)
                button.DeleteButton:HookScript("OnEnter", OnUpdateGameTooltip)
                updatedEquipmentManagerPaneButtons[button.setID] = true
            end
        end
    end)
end

local function GearSetButton_OnEnter_Hook()
    local TLA = ns.TooltipLineAccessor

    local rightText = TLA.GetRightText(GameTooltip, 1)
    if rightText then TLA.SetRightText(GameTooltip, 1, GetTranslatedGlobalString(rightText)) end

    for i = 2, GameTooltip:NumLines() do
        local leftFS = TLA.GetLeftFontString(GameTooltip, i)
        local leftText = TLA.GetLeftText(GameTooltip, i)
        if leftFS and leftText then
            if (CreateColor(leftFS:GetTextColor()):IsEqualTo(RED_FONT_COLOR)) then
                local translatedText = string.gsub(leftText, "(.-)%s*(%d*)%s*missing", function(slot, slotIndex)
                    if (slotIndex ~= "") then
                        return GetTranslatedGlobalString("%s %d missing"):format(GetTranslatedGlobalString(slot), slotIndex)
                    else
                        return GetTranslatedGlobalString("%s missing"):format(GetTranslatedGlobalString(slot))
                    end
                end)
                TLA.SetLeftText(GameTooltip, i, translatedText)
            else
                TLA.SetLeftText(GameTooltip, i, GetTranslatedGlobalString(leftText))
            end
        end
    end

    GameTooltip:Show()
end

function translator:Init()
    ns.SelectedIconFrameTranslationUtil:TranslateSelectedIconFrame(GearManagerPopupFrame)

    UpdateTextWithTranslation(PaperDollFrame.EquipmentManagerPane.EquipSet, GetTranslatedGlobalString)
    UpdateTextWithTranslation(PaperDollFrame.EquipmentManagerPane.SaveSet, GetTranslatedGlobalString)

    hooksecurefunc("EquipmentFlyout_DisplaySpecialButton", function() OnUpdateGameTooltip(EquipmentFlyoutFrame.buttonFrame) end)
    hooksecurefunc("GearSetButton_OnEnter", GearSetButton_OnEnter_Hook)

    PaperDollFrame.EquipmentManagerPane:HookScript("OnUpdate", PaperDollFrame_EquipmentManagerPane_OnUpdate_Hook)

    local dropdownDescriptionSubscriber = ns.DropdownDescriptionSubscriber:GetInstance()
    dropdownDescriptionSubscriber:Subscribe(PaperDollFrame.EquipmentManagerPane, function(rootDescription)
        for _, elementDescription in rootDescription:EnumerateElementDescriptions() do
            if (elementDescription.isRadio) then
                elementDescription:AddInitializer(function(button)
                    UpdateTextWithTranslation(button.fontString, GetTranslatedSpecialization)
                end)
            else
                elementDescription:AddInitializer(function(button)
                    UpdateTextWithTranslation(button.fontString, GetTranslatedGlobalString)
                end)
            end
        end
    end)

    local staticPopupSubscriber = ns.StaticPopupSubscriber:GetInstance()
    staticPopupSubscriber:Subscribe("CONFIRM_DELETE_EQUIPMENT_SET", function(dialog, text_arg1)
        UpdateTextWithTranslation(dialog.text, function()
            return GetTranslatedGlobalString(CONFIRM_DELETE_EQUIPMENT_SET):format(text_arg1)
        end)
        UpdateTextWithTranslation(dialog.button1.Text, GetTranslatedGlobalString)
        UpdateTextWithTranslation(dialog.button2.Text, GetTranslatedGlobalString)
    end)
    staticPopupSubscriber:Subscribe("CONFIRM_OVERWRITE_EQUIPMENT_SET", function(dialog, text_arg1)
        UpdateTextWithTranslation(dialog.text, function()
            return GetTranslatedGlobalString(CONFIRM_OVERWRITE_EQUIPMENT_SET):format(text_arg1)
        end)
        UpdateTextWithTranslation(dialog.button1.Text, GetTranslatedGlobalString)
        UpdateTextWithTranslation(dialog.button2.Text, GetTranslatedGlobalString)
    end)
    staticPopupSubscriber:Subscribe("CONFIRM_SAVE_EQUIPMENT_SET", function(dialog, text_arg1)
        UpdateTextWithTranslation(dialog.text, function()
            return GetTranslatedGlobalString(CONFIRM_SAVE_EQUIPMENT_SET):format(text_arg1)
        end)
        UpdateTextWithTranslation(dialog.button1.Text, GetTranslatedGlobalString)
        UpdateTextWithTranslation(dialog.button2.Text, GetTranslatedGlobalString)
    end)
end

ns.TranslationsManager:AddTranslator(translator)
