--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation

local areaLabelDataProviderHooked

---@class MapFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_MAP_AND_QUEST_LOG_FRAME_OPTION)
end

--- Extract and separate level text from a given string.
--- @param text string @The input string containing the zone name and level text.
--- @return string modifiedText @The text with the level text removed.
--- @return string levelText @The extracted level text with the color tags.
--- @example
--- local zoneText, levelText = ExtractLevelText("Zone Name |cff123456(35-40)|r")
--- -- zoneText: "Zone Name"
--- -- levelText: "|cff123456(35-40)|r"
local function ExtractLevelText(text)
    local levelText
    text = text:gsub("(.+)|cff(.+)|r", function(s1, s2)
        levelText = "|cff" .. s2 .. "|r"
        return s1
    end)

    return text, levelText
end

local function TranslateMapLegend()
    UpdateTextWithTranslation(QuestMapFrame.MapLegend.TitleText, GetTranslatedGlobalString)
    UpdateTextWithTranslation(QuestMapFrame.MapLegend.BackButton.Text, GetTranslatedGlobalString)
    for _, categoryFrame in pairs({ QuestMapFrame.MapLegend.ScrollFrame.ScrollChild:GetChildren() }) do
        for _, layoutTable in pairs({ categoryFrame:GetLayoutChildren() }) do
            for _, legendItemFrame in ipairs(layoutTable) do
                UpdateTextWithTranslation(legendItemFrame, GetTranslatedGlobalString)
                if (legendItemFrame.nameText) then
                    legendItemFrame.nameText = GetTranslatedGlobalString(legendItemFrame.nameText)
                end
                if (legendItemFrame.tooltipText) then
                    legendItemFrame.tooltipText = GetTranslatedGlobalString(legendItemFrame.tooltipText)
                end
            end
        end
    end
end

local function AreaLabelDataProvider_SetLabel(areaNameLabels, areaLabelType, name, description, _, _, _)
    local areaLabelInfo = areaNameLabels.labelInfoByType[areaLabelType];
    if (name) then
        local nameText, levelText = ExtractLevelText(name)
        local translatedName = GetTranslatedZoneText(nameText)

        if (nameText ~= translatedName) then
            areaLabelInfo.name = translatedName
            if (levelText) then
                areaLabelInfo.name = translatedName .. levelText
            end
        end
    end

    if (description) then
        local descriptionText, levelText = ExtractLevelText(description)
        local translatedDescription = GetTranslatedGlobalString(descriptionText)

        if (descriptionText ~= translatedDescription) then
            if (levelText) then
                areaLabelInfo.description = translatedDescription .. " " .. levelText
            else
                areaLabelInfo.description = translatedDescription
            end
        end
    end
end

local function WorldMapFrame_NavBar_Refresh(navBar)
    for provider, _ in pairs(WorldMapFrame.dataProviders) do
        if (provider.Label) then
            if (not areaLabelDataProviderHooked) then
                areaLabelDataProviderHooked = true
                hooksecurefunc(provider.Label, "SetLabel", AreaLabelDataProvider_SetLabel)
            end
        end
    end

    for _, button in ipairs(navBar.navList) do
        UpdateTextWithTranslation(button, GetTranslatedZoneText)
        if (button.MenuArrowButton) then
            local buttonExtraWidth;
            if (button.MenuArrowButton:IsShown()) then
                buttonExtraWidth = 53;
            else
                buttonExtraWidth = 30;
            end
            button:SetWidth(button.text:GetStringWidth() + buttonExtraWidth);
        end

        button.listFunc = function()
            local list = WorldMapNavBarButtonMixin.GetDropdownList(button)
            for _, entry in ipairs(list) do
                entry.text = GetTranslatedZoneText(entry.text)
            end
            return list;
        end;
    end
end

local function WorldMapFrame_BorderFrame_SetTitle(borderFrame)
    UpdateTextWithTranslation(borderFrame:GetTitleText(), GetTranslatedGlobalString)
end

function translator:Init()
    hooksecurefunc(WorldMapFrame.BorderFrame, "SetTitle", WorldMapFrame_BorderFrame_SetTitle)

    TranslateMapLegend();

    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)) then
        WorldMapFrame.NavBar.homeButton.text:SetFontObject(SystemFont_Shadow_Med1)
        UpdateTextWithTranslation(WorldMapFrame.NavBar.homeButton.text, GetTranslatedGlobalString)

        hooksecurefunc(WorldMapFrame.NavBar, "Refresh", WorldMapFrame_NavBar_Refresh)
    end
end

ns.TranslationsManager:AddTranslator(translator)
