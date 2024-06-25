--- @class WowUkrainizerInternals
local ns = select(2, ...);

local Trim = ns.StringUtil.Trim
local Split = ns.StringUtil.Split
local TryCallAPIFn = ns.CommonUtil.TryCallAPIFn
local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

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
--- local zoneText, levelText = _extractLevelText("Zone Name |cff123456(35-40)|r")
--- -- zoneText: "Zone Name"
--- -- levelText: "|cff123456(35-40)|r"
local function _extractLevelText(text)
    local levelText
    text = text:gsub("(.+)|cff(.+)|r", function(s1, s2)
        levelText = "|cff" .. s2 .. "|r"
        return s1
    end)

    return text, levelText
end

local function _onUIDropDownMenuShow()
    local _, name = TryCallAPIFn("GetName", _G["DropDownList1"].dropdown.Button)
    if (name == "WorldMapFrameButton") then
        for i = 1, _G["DropDownList1"].numButtons, 1 do
            local button = _G["DropDownList1Button" .. i]
            button:SetText(GetTranslatedZoneText(button:GetText()))
        end
    end
end

function translator:Init()
    hooksecurefunc(WorldMapFrame.BorderFrame, "SetTitle", function(borderFrame)
        local currentText = borderFrame:GetTitleText():GetText()
        local translatedText = GetTranslatedGlobalString(currentText)
        if (currentText ~= translatedText) then
            borderFrame:SetTitle(translatedText);
        end
    end)

    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)) then
        WorldMapFrame.NavBar.homeButton.text:SetFontObject(SystemFont_Shadow_Med1)
        WorldMapFrame.NavBar.homeButton.text:SetText(GetTranslatedGlobalString(WORLD))

        EventRegistry:RegisterCallback("UIDropDownMenu.Show", _onUIDropDownMenuShow, self);

        hooksecurefunc(WorldMapFrame.NavBar, "Refresh", function(navBar)
            for provider, _ in pairs(WorldMapFrame.dataProviders) do
                if (provider.Label) then
                    hooksecurefunc(provider.Label, "SetLabel",
                        function(areaNameLabels, areaLabelType, name, description, _, _, _)
                            local areaLabelInfo = areaNameLabels.labelInfoByType[areaLabelType];
                            if (name) then
                                local nameText, levelText = _extractLevelText(name)
                                local translatedName = GetTranslatedZoneText(nameText)

                                if (nameText ~= translatedName) then
                                    areaLabelInfo.name = translatedName
                                    if (levelText) then
                                        areaLabelInfo.name = translatedName .. levelText
                                    end
                                end
                            end

                            if (description) then
                                local descriptionText, levelText = _extractLevelText(description)
                                local translatedDescription = GetTranslatedGlobalString(descriptionText)

                                if (descriptionText ~= translatedDescription) then
                                    areaLabelInfo.description = translatedDescription
                                    if (levelText) then
                                        areaLabelInfo.description = translatedDescription .. " " .. levelText
                                    end
                                end
                            end
                        end)
                end
            end

            for _, button in ipairs(navBar.navList) do
                local text = GetTranslatedZoneText(button:GetText())
                button:SetText(text)
                if (button.MenuArrowButton) then
                    local buttonExtraWidth;
                    if (button.MenuArrowButton:IsShown()) then
                        buttonExtraWidth = 53;
                    else
                        buttonExtraWidth = 30;
                    end
                    button:SetWidth(button.text:GetStringWidth() + buttonExtraWidth);
                end
            end
        end)
    end
end

ns.TranslationsManager:AddTranslator(translator)
