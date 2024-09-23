--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation

--- Utility module providing ....
---@class SelectedIconFrameTranslationUtil
local internal = {}
ns.SelectedIconFrameTranslationUtil = internal

function internal:TranslateSelectedIconFrame(rootFrame)
    local function SelectedIconDescription_SetText_Hook(selectedIconDescription)
        local originalText = selectedIconDescription:GetText()
        local translatedText = GetTranslatedGlobalString(originalText)

        if (originalText ~= translatedText) then
            selectedIconDescription:SetText(translatedText)
        end
    end

    UpdateTextWithTranslation(rootFrame.BorderBox.IconSelectionText, GetTranslatedGlobalString)
    UpdateTextWithTranslation(rootFrame.BorderBox.EditBoxHeaderText, function(text) return GetTranslatedGlobalString(text, true) end)
    UpdateTextWithTranslation(rootFrame.BorderBox.CancelButton.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(rootFrame.BorderBox.OkayButton.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(rootFrame.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconHeader, GetTranslatedGlobalString)

    hooksecurefunc(rootFrame.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription, "SetText", SelectedIconDescription_SetText_Hook)

    rootFrame.BorderBox.IconTypeDropdown:SetSelectionText(function(selections)
        return GetTranslatedGlobalString(selections[1].text)
    end)

    local dropdownDescriptionSubscriber = ns.DropdownDescriptionSubscriber:GetInstance()
    dropdownDescriptionSubscriber:Subscribe(rootFrame.BorderBox.IconTypeDropdown, function(rootDescription)
        for _, elementDescription in rootDescription:EnumerateElementDescriptions() do
            elementDescription:AddInitializer(function(button)
                UpdateTextWithTranslation(button.fontString, GetTranslatedGlobalString)
            end)
        end
    end)
end
