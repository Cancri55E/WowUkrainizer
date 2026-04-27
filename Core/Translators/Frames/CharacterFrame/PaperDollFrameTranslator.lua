--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedAttribute = ns.DbContext.Player.GetTranslatedAttribute
local GetTranslatedSpecialization = ns.DbContext.Player.GetTranslatedSpecialization
local GetTranslatedClass = ns.DbContext.Player.GetTranslatedClass
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation

local OnUpdateTooltip = function(tooltip, expectedOwner)
    ns.TooltipUtil:OnUpdateTooltip(tooltip, expectedOwner, GetTranslatedGlobalString, true)
end

local OnUpdateGameTooltip = function(expectedOwner)
    ns.TooltipUtil:OnUpdateGameTooltip(expectedOwner, GetTranslatedGlobalString, true)
end

local OnUpdateEquipmentSlotTooltip = function(expectedOwner)
    ns.TooltipUtil:OnUpdateGameTooltip(expectedOwner, function (text)
        if (text == "Back") then
            return 'Спина' -- HOOK: Override the ambiguous `BACK` string for the equipment slot context.
        else
            return GetTranslatedGlobalString(text)
        end
    end, true)
end

---@class PaperDollFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_CHARACTER_FRAME_OPTION)
end

local function ModelSceneControlButton_OnEnter_Hook()
    if (GetCVar("UberTooltips") ~= "1") then return end

    local tooltip = GetAppropriateTooltip();
    local owner = GetAppropriateTopLevelParent();

    OnUpdateTooltip(tooltip, owner)
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
        CharacterLevelText:SetFormattedText("Рівень %s |c%s%s (%s)|r", level, classColorString, translatedClass, translatedSpecialization);
    else
        CharacterLevelText:SetFormattedText("Рівень %s |c%s%s|r", level, classColorString, translatedClass);
    end
end

local function PaperDollFrame_SetLabelAndText_Hook(statFrame, label)
    if (statFrame.Label) then
        UpdateTextWithTranslation(statFrame.Label, function() return format(STAT_FORMAT, GetTranslatedAttribute(label)) end)
    end
end

local function PaperDollStatTooltip_Hook(statFrame)
    if (not statFrame.tooltip) then return end

    local currentTooltipOwner = GameTooltip:GetOwner()
    if (currentTooltipOwner and currentTooltipOwner ~= statFrame) then return end

    local TLA = ns.TooltipLineAccessor
    local line1Text = TLA.GetLeftText(GameTooltip, 1)
    if not line1Text then return end

    local translatedLabel = ""
    if (statFrame.Label) then
        translatedLabel = line1Text:gsub(HIGHLIGHT_FONT_COLOR_CODE .. "([A-Za-z%s]+)(.+)",
            function(_, other)
                local result = HIGHLIGHT_FONT_COLOR_CODE .. string.sub(statFrame.Label:GetText(), 1, -2)
                if (other) then
                    result = result .. " " .. other
                end
                return result .. FONT_COLOR_CODE_CLOSE
            end)
    else
        translatedLabel = line1Text:gsub(HIGHLIGHT_FONT_COLOR_CODE .. "(.+)" .. FONT_COLOR_CODE_CLOSE,
            function(tooltipText)
                local translatedTooltipText = GetTranslatedGlobalString(tooltipText)
                return HIGHLIGHT_FONT_COLOR_CODE .. translatedTooltipText .. FONT_COLOR_CODE_CLOSE
            end)
    end
    TLA.SetLeftText(GameTooltip, 1, translatedLabel)

    if (statFrame.tooltip2) then
        local text2 = TLA.GetLeftText(GameTooltip, 2)
        if text2 then TLA.SetLeftText(GameTooltip, 2, GetTranslatedGlobalString(text2)) end
    end

    if (statFrame.tooltip3) then
        local text2 = TLA.GetLeftText(GameTooltip, 2)
        if text2 then TLA.SetLeftText(GameTooltip, 3, GetTranslatedGlobalString(text2)) end
    end

    GameTooltip:Show()
end

function translator:Init()
    for _, tabButton in ipairs(CharacterFrame.Tabs) do
        UpdateTextWithTranslation(tabButton.Text, GetTranslatedGlobalString)
    end

    UpdateTextWithTranslation(CharacterStatsPane.ItemLevelCategory.Title, GetTranslatedGlobalString)
    UpdateTextWithTranslation(CharacterStatsPane.AttributesCategory.Title, GetTranslatedGlobalString)
    UpdateTextWithTranslation(CharacterStatsPane.EnhancementsCategory.Title, GetTranslatedGlobalString)

    for _, equipmentSlotButton in ipairs(PaperDollItemsFrame.EquipmentSlots) do
        equipmentSlotButton:HookScript("OnEnter", OnUpdateEquipmentSlotTooltip)
        hooksecurefunc(equipmentSlotButton, "UpdateTooltip", OnUpdateEquipmentSlotTooltip)
    end

    for _, equipmentSlotButton in ipairs(PaperDollItemsFrame.WeaponSlots) do
        equipmentSlotButton:HookScript("OnEnter", OnUpdateGameTooltip)
        hooksecurefunc(equipmentSlotButton, "UpdateTooltip", OnUpdateGameTooltip)
    end

    hooksecurefunc("PaperDollFrame_SetLevel", PaperDollFrame_SetLevel_Hook)
    hooksecurefunc("PaperDollFrame_SetLabelAndText", PaperDollFrame_SetLabelAndText_Hook)
    hooksecurefunc("PaperDollStatTooltip", PaperDollStatTooltip_Hook)

    PaperDollSidebarTab1:HookScript("OnEnter", OnUpdateGameTooltip)
    PaperDollSidebarTab2:HookScript("OnEnter", OnUpdateGameTooltip)
    PaperDollSidebarTab3:HookScript("OnEnter", OnUpdateGameTooltip)

    CharacterModelScene.ControlFrame.zoomInButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)
    CharacterModelScene.ControlFrame.zoomOutButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)
    CharacterModelScene.ControlFrame.rotateLeftButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)
    CharacterModelScene.ControlFrame.rotateRightButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)
    CharacterModelScene.ControlFrame.resetButton:HookScript("OnEnter", ModelSceneControlButton_OnEnter_Hook)
end

ns.TranslationsManager:AddTranslator(translator)
