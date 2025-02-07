--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation

local areaLabelDataProviderHooked

---@class MapFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

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
    local function getTranslatedText(obj, translateFunc)
        local value = obj
        if (type(value) == "function") then
            value = obj()
        end

        local text, levelText = ExtractLevelText(value)
        local translatedText = translateFunc(text)

        if (text ~= translatedText) then
            if (levelText) then
                translatedText = translatedText .. " " .. levelText
            end

            return translatedText
        end
    end

    local areaLabelInfo = areaNameLabels.labelInfoByType[areaLabelType];
    if (name) then
        local translatedText = getTranslatedText(name, GetTranslatedZoneText)
        if (translatedText) then
            areaLabelInfo.name = translatedText
        end
    end

    if (description) then
        local translatedText = getTranslatedText(description, GetTranslatedGlobalString)
        if (translatedText) then
            areaLabelInfo.description = translatedText
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

local function SetupBorderFrameHook()
    hooksecurefunc(WorldMapFrame.BorderFrame, "SetTitle", function(borderFrame)
        UpdateTextWithTranslation(borderFrame:GetTitleText(), GetTranslatedGlobalString)
    end)
end

local function SetupAndTranslateNavBar()
    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)) then
        WorldMapFrame.NavBar.homeButton.text:SetFontObject(GameFontNormal)
        UpdateTextWithTranslation(WorldMapFrame.NavBar.homeButton.text, GetTranslatedGlobalString)

        -- We need to update font for the buttons in navList separately because they are created and added to 
        -- the pool in OnLoad method which is called before our addon laod.
        for _, button in ipairs(WorldMapFrame.NavBar.navList) do
            button.text:SetFontObject(GameFontNormal)
        end

        WorldMapFrame_NavBar_Refresh(WorldMapFrame.NavBar)
        hooksecurefunc(WorldMapFrame.NavBar, "Refresh", WorldMapFrame_NavBar_Refresh)
    end
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_MAP_AND_QUEST_LOG_FRAME_OPTION)
end

function translator:Init()
    SetupBorderFrameHook()
    SetupAndTranslateNavBar()
    TranslateMapLegend();
end

ns.TranslationsManager:AddTranslator(translator)
