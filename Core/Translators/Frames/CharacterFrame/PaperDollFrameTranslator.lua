--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedSpecialization = ns.DbContext.Player.GetTranslatedSpecialization
local GetTranslatedClass = ns.DbContext.Player.GetTranslatedClass
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local SetText = ns.FontStringUtil.SetText

---@class PaperDollFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true -- TODO: Add settings
end

local updatedEquipmentManagerPaneButtons = {}

-- local function UpdateItemSlotTooltip(obj)
--     local gameTooltipOwner = GameTooltip:GetOwner()
--     if (gameTooltipOwner and gameTooltipOwner ~= obj) then return end

--     -- TODO: Item slot is empty

--     local firstLine = _G["GameTooltipTextLeft1"]
--     if (firstLine) then
--         SetText(firstLine, GetTranslatedGlobalString(firstLine:GetText()))
--     end

--     GameTooltip:Show()
-- end

-- local function UpdateTooltip(obj)
--     local gameTooltipOwner = GameTooltip:GetOwner()
--     if (gameTooltipOwner and gameTooltipOwner ~= obj) then return end

--     local firstLine = _G["GameTooltipTextLeft1"]
--     if (firstLine) then
--         SetText(firstLine, GetTranslatedGlobalString(firstLine:GetText()))
--     end

--     local secondLine = _G["GameTooltipTextLeft2"]
--     local secondLineText = secondLine and secondLine:GetText()
--     if (secondLineText) then
--         local level = ExtractFromText(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, secondLineText)
--         if (level) then
--             SetText(secondLine, GetTranslatedGlobalString(FEATURE_BECOMES_AVAILABLE_AT_LEVEL):format(level))
--         else
--             SetText(secondLine, GetTranslatedGlobalString(secondLine:GetText()))
--         end
--     end

--     GameTooltip:Show()
-- end

local function OnUpdateTooltip(tooltip, expectedOwner)
    local currentTooltipOwner = tooltip:GetOwner()
    if (currentTooltipOwner and currentTooltipOwner ~= expectedOwner) then return end

    for i = 1, tooltip:NumLines() do
        local tooltipName = tooltip:GetName()
        local tooltipLeftLine = _G[tooltipName .. "TextLeft" .. i]
        SetText(tooltipLeftLine, GetTranslatedGlobalString(tooltipLeftLine:GetText()))
    end

    tooltip:Show()
end

local function OnUpdateGameTooltip(expectedOwner)
    OnUpdateTooltip(GameTooltip, expectedOwner)
end

local function ModelSceneControlButton_OnEnter_Hook()
    if (GetCVar("UberTooltips") ~= "1") then return end

    local tooltip = GetAppropriateTooltip();
    local owner = GetAppropriateTopLevelParent();

    OnUpdateTooltip(tooltip, owner)
end

local function GearSetButton_OnEnter_Hook()
    local tooltipName = GameTooltip:GetName()

    local itemsCountText = _G[tooltipName .. "TextRight1"]
    SetText(itemsCountText, GetTranslatedGlobalString(itemsCountText:GetText()))

    for i = 2, GameTooltip:NumLines() do
        local tooltipLine = _G[tooltipName .. "TextLeft" .. i]
        if (CreateColor(tooltipLine:GetTextColor()):IsEqualTo(RED_FONT_COLOR)) then
            local tooltipText = tooltipLine:GetText()
            local translatedText = string.gsub(tooltipText, "(.-)%s*(%d*)%s*missing", function(slot, slotIndex)
                if (slotIndex ~= "") then
                    return GetTranslatedGlobalString("%s %d missing"):format(GetTranslatedGlobalString(slot), slotIndex)
                else
                    return GetTranslatedGlobalString("%s missing"):format(GetTranslatedGlobalString(slot))
                end
            end)
            SetText(tooltipLine, translatedText)
        else
            SetText(tooltipLine, GetTranslatedGlobalString(tooltipLine:GetText()))
        end
    end

    GameTooltip:Show()
end

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

local function PaperDollFrame_SetLevel_Hook()
    local primaryTalentTree = GetSpecialization();
    local classDisplayName, class = UnitClass("player");
    local classColorString = RAID_CLASS_COLORS[class].colorStr;
    local specName, _;

    if (primaryTalentTree) then
        _, specName = GetSpecializationInfo(primaryTalentTree, nil, nil, nil, ns.PlayerInfo.Gender);
    end

    local level = UnitLevel("player");
    local effectiveLevel = UnitEffectiveLevel("player");

    if (effectiveLevel ~= level) then
        level = EFFECTIVE_LEVEL_FORMAT:format(effectiveLevel, level);
    end

    local translatedClass = GetTranslatedClass(classDisplayName, 1, ns.PlayerInfo.Gender)
    if (specName and specName ~= "") then
        local translatedSpecialization = GetTranslatedSpecialization(specName)
        CharacterLevelText:SetFormattedText("Рівень %s |c%s%s %s|r", level, classColorString, translatedSpecialization, translatedClass);
    else
        CharacterLevelText:SetFormattedText("Рівень %s |c%s%s|r", level, classColorString, translatedClass);
    end
end

function translator:Init()
    for _, tabButton in ipairs(CharacterFrame.Tabs) do
        UpdateTextWithTranslation(tabButton.Text, GetTranslatedGlobalString)
    end

    UpdateTextWithTranslation(PaperDollFrame.EquipmentManagerPane.EquipSet, GetTranslatedGlobalString)
    UpdateTextWithTranslation(PaperDollFrame.EquipmentManagerPane.SaveSet, GetTranslatedGlobalString)

    PaperDollFrame.EquipmentManagerPane:HookScript("OnUpdate", PaperDollFrame_EquipmentManagerPane_OnUpdate_Hook)

    UpdateTextWithTranslation(CharacterStatsPane.ItemLevelCategory.Title, GetTranslatedGlobalString)
    UpdateTextWithTranslation(CharacterStatsPane.AttributesCategory.Title, GetTranslatedGlobalString)
    UpdateTextWithTranslation(CharacterStatsPane.EnhancementsCategory.Title, GetTranslatedGlobalString)

    for _, equipmentSlotButton in ipairs(PaperDollItemsFrame.EquipmentSlots) do
        equipmentSlotButton:HookScript("OnEnter", OnUpdateGameTooltip)
        hooksecurefunc(equipmentSlotButton, "UpdateTooltip", OnUpdateGameTooltip)
    end

    for _, equipmentSlotButton in ipairs(PaperDollItemsFrame.WeaponSlots) do
        equipmentSlotButton:HookScript("OnEnter", OnUpdateGameTooltip)
        hooksecurefunc(equipmentSlotButton, "UpdateTooltip", OnUpdateGameTooltip)
    end

    hooksecurefunc("PaperDollFrame_SetLevel", PaperDollFrame_SetLevel_Hook)

    hooksecurefunc("EquipmentFlyout_DisplaySpecialButton", function() OnUpdateGameTooltip(EquipmentFlyoutFrame.buttonFrame) end)

    PaperDollSidebarTab1:HookScript("OnEnter", OnUpdateGameTooltip)
    PaperDollSidebarTab2:HookScript("OnEnter", OnUpdateGameTooltip)
    PaperDollSidebarTab3:HookScript("OnEnter", OnUpdateGameTooltip)

    hooksecurefunc("GearSetButton_OnEnter", GearSetButton_OnEnter_Hook)

    CharacterModelScene.ControlFrame.zoomInButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)
    CharacterModelScene.ControlFrame.zoomOutButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)
    CharacterModelScene.ControlFrame.rotateLeftButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)
    CharacterModelScene.ControlFrame.rotateRightButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)
    CharacterModelScene.ControlFrame.resetButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)

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

    ns.SelectedIconFrameTranslationUtil:TranslateSelectedIconFrame(GearManagerPopupFrame)
end

ns.TranslationsManager:AddTranslator(translator)
