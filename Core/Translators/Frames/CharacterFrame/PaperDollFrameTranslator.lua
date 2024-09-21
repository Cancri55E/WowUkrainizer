--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local SetText = ns.FontStringUtil.SetText
local ExtractFromText = ns.StringUtil.ExtractFromText

---@class PaperDollFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true -- TODO: Add settings
end

local function UpdateItemSlotTooltip(obj)
    local gameTooltipOwner = GameTooltip:GetOwner()
    if (gameTooltipOwner and gameTooltipOwner ~= obj) then return end

    -- TODO: Item slot is empty

    local firstLine = _G["GameTooltipTextLeft1"]
    if (firstLine) then
        SetText(firstLine, GetTranslatedGlobalString(firstLine:GetText()))
    end

    GameTooltip:Show()
end

local function UpdateTooltip(obj)
    local gameTooltipOwner = GameTooltip:GetOwner()
    if (gameTooltipOwner and gameTooltipOwner ~= obj) then return end

    local firstLine = _G["GameTooltipTextLeft1"]
    if (firstLine) then
        SetText(firstLine, GetTranslatedGlobalString(firstLine:GetText()))
    end

    local secondLine = _G["GameTooltipTextLeft2"]
    local secondLineText = secondLine and secondLine:GetText()
    if (secondLineText) then
        local level = ExtractFromText(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, secondLineText)
        if (level) then
            SetText(secondLine, GetTranslatedGlobalString(FEATURE_BECOMES_AVAILABLE_AT_LEVEL):format(level))
        else
            SetText(secondLine, GetTranslatedGlobalString(secondLine:GetText()))
        end
    end

    GameTooltip:Show()
end

local updatedEquipmentManagerPaneButtons = {}

function translator:Init()
    for _, tabButton in ipairs(CharacterFrame.Tabs) do
        UpdateTextWithTranslation(tabButton.Text, GetTranslatedGlobalString)
    end

    UpdateTextWithTranslation(PaperDollFrame.EquipmentManagerPane.EquipSet, GetTranslatedGlobalString)
    UpdateTextWithTranslation(PaperDollFrame.EquipmentManagerPane.SaveSet, GetTranslatedGlobalString)

    PaperDollFrame.EquipmentManagerPane:HookScript("OnUpdate", function(pane)
        pane.ScrollBox:ForEachFrame(function(button)
            if (not button.setID) then
                UpdateTextWithTranslation(button.text, GetTranslatedGlobalString) -- TODO: Optimize someday
            else
                if (not updatedEquipmentManagerPaneButtons[button.setID]) then
                    button.EditButton:HookScript("OnEnter", UpdateTooltip)
                    button.DeleteButton:HookScript("OnEnter", UpdateTooltip)
                    updatedEquipmentManagerPaneButtons[button.setID] = true
                end
            end
        end)
    end)

    UpdateTextWithTranslation(CharacterStatsPane.ItemLevelCategory.Title, GetTranslatedGlobalString)
    UpdateTextWithTranslation(CharacterStatsPane.AttributesCategory.Title, GetTranslatedGlobalString)
    UpdateTextWithTranslation(CharacterStatsPane.EnhancementsCategory.Title, GetTranslatedGlobalString)

    for _, equipmentSlotButton in ipairs(PaperDollItemsFrame.EquipmentSlots) do
        equipmentSlotButton:HookScript("OnEnter", UpdateItemSlotTooltip)
        hooksecurefunc(equipmentSlotButton, "UpdateTooltip", UpdateItemSlotTooltip)
    end

    for _, equipmentSlotButton in ipairs(PaperDollItemsFrame.WeaponSlots) do
        equipmentSlotButton:HookScript("OnEnter", UpdateItemSlotTooltip)
        hooksecurefunc(equipmentSlotButton, "UpdateTooltip", UpdateItemSlotTooltip)
    end

    PaperDollSidebarTab1:HookScript("OnEnter", UpdateTooltip)
    PaperDollSidebarTab2:HookScript("OnEnter", UpdateTooltip)
    PaperDollSidebarTab3:HookScript("OnEnter", UpdateTooltip)

    UpdateTextWithTranslation(GearManagerPopupFrame.BorderBox.IconSelectionText, GetTranslatedGlobalString)
    UpdateTextWithTranslation(GearManagerPopupFrame.BorderBox.EditBoxHeaderText, function(text) return GetTranslatedGlobalString(text, true) end)
    UpdateTextWithTranslation(GearManagerPopupFrame.BorderBox.CancelButton.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(GearManagerPopupFrame.BorderBox.OkayButton.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(GearManagerPopupFrame.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconHeader, GetTranslatedGlobalString)

    hooksecurefunc(Menu, "PopulateDescription", function(_, dropdown, rootDescription)
        if (dropdown ~= GearManagerPopupFrame.BorderBox.IconTypeDropdown) then return end
        for _, elementDescription in rootDescription:EnumerateElementDescriptions() do
            elementDescription:AddInitializer(function(button)
                button.fontString:SetText(button.fontString:GetText() .. "DDD");
            end)
        end
    end)
end

ns.TranslationsManager:AddTranslator(translator)
