--- @class WowUkrainizerInternals
local ns = select(2, ...);

--- Utility module providing ....
---@class QuestFrameUtil
local internal = {}
ns.QuestFrameUtil = internal

function internal.CreateMtIconTexture(parentFrame, offsetX, offsetY)
    local icon = parentFrame:CreateTexture(nil, "OVERLAY");
    icon:ClearAllPoints();
    icon:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", offsetX, offsetY);
    icon:SetWidth(22);
    icon:SetHeight(22);
    icon:SetTexture([[Interface\AddOns\WowUkrainizer\assets\images\robot.png]]);
    icon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT");
        GameTooltip:ClearLines();
        GameTooltip:SetText("Перекладено за допомогою ШІ.", 1, 1, 1)
        GameTooltip:AddLine(
            "Ви завжди можете вимкнути переклади зроблені |nза допомогою ШІ в налаштуваннях додатку.",
            RAID_CLASS_COLORS.MAGE.r,
            RAID_CLASS_COLORS.MAGE.g,
            RAID_CLASS_COLORS.MAGE.b)
        GameTooltip:Show()
    end)
    icon:SetScript("OnLeave", function(_)
        GameTooltip:Hide()
    end);
    return icon
end

function internal.CreateSwitchTranslationButton(parentFrame, onClickFunc, offsetX, offsetY)
    local button = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate");
    button:SetSize(90, 22);
    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_TEXT_OPTION)) then
        button:SetText("Оригінал");
    else
        button:SetText("Переклад");
    end
    button:ClearAllPoints();
    button:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", offsetX, offsetY);
    button:SetScript("OnMouseDown", function(_)
        local newValue = not ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_TEXT_OPTION)
        ns.SettingsProvider.SetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_TEXT_OPTION, newValue)
        if (newValue) then
            button:SetText("Оригінал");
        else
            button:SetText("Переклад");
        end
        onClickFunc()
    end)
    button:Show();
    return button
end

function internal.CreateWowheadButton(parentFrame, offsetX, offsetY, data)
    local button = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate");
    button:SetSize(22, 22);
    button:ClearAllPoints();
    button:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", offsetX, offsetY);
    button:SetNormalAtlas("UI-HUD-MicroMenu-Shop-Up");
    button:SetPushedAtlas("UI-HUD-MicroMenu-Shop-Down");
    button:SetScript("OnMouseDown",
        function(_) _G["StaticPopup_Show"]("WowUkrainizer_WowheadLink", nil, nil, data) end)
    button:Show();
    return button
end
