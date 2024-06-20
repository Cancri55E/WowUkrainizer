--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText

---@class MapFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

function translator:Init()
    WorldMapFrame.NavBar.homeButton.text:SetFontObject(SystemFont_Shadow_Med1)
    WorldMapFrame.NavBar.homeButton.text:SetText("Світ")

    hooksecurefunc(WorldMapFrame.NavBar, "Refresh", function(navBar)
        for _, button in ipairs(navBar.navList) do
            -- hook. TODO: remove hook after crowdin files will be changed
            local text = button:GetText()
            if (text == "Azeroth") then
                text = "Азерот"
            else
                text = GetTranslatedZoneText(text)
            end

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

ns.TranslationsManager:AddTranslator(translator)
