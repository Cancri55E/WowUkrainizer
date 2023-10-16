local _, ns = ...;

local eventHandler = ns.EventHandler:new()

local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetGossipTitle = ns.DbContext.Gossips.GetGossipTitle
local GetGossipOptionText = ns.DbContext.Gossips.GetGossipOptionText

local translator = class("QuestTranslator", ns.Translators.BaseTranslator)
ns.Translators.QuestTranslator = translator

local debug_title =
[[О, вітаю. Елвінський ліс такий мирний і безтурботний. Єдине, про що варто хвилюватися - це бандити, мурлоки та випадкові гноли, які привертають до себе всю увагу. Це, мабуть, найспокійніший край у Східних Королівствах.

Але не для вас, вершників на драконах. У "Подорожі по Елвінському лісі" тобі доведеться мчати понад землею та крізь гілки цих розкішних дерев. Обережно, не вріжся на повній швидкості в стовбур, інакше доведеться використовувати свій Бронзовий годинник, щоб повернути свої зламані кістки на місце. Чи вистачить у тебе сміливості?]]

local debug_option_1 = "I'd like to try the course."
local debug_option_1_tr =
"Я хочу спробувати маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут."

local debug_option_2 = "I'd like to try the Advanced course."
local debug_option_2_tr =
"Я хочу спробувати розширений маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут."

local debug_option_3 = "I'd like to try the Reverse course."
local debug_option_3_tr =
"Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут."

local function OnGossipShow()
    local title = GossipFrameTitleText:GetText();
    GossipFrameTitleText:SetText(GetUnitNameOrDefault(title));

    local optionHeightOffset = 0
    for _, childFrame in GossipFrame.GreetingPanel.ScrollBox:EnumerateFrames() do
        local buttonType = childFrame:GetElementData().buttonType
        if (buttonType == GOSSIP_BUTTON_TYPE_TITLE) then
            --
            local currentHeight = childFrame.GreetingText:GetHeight()
            --
            --childFrame.GreetingText:SetText(debug_title)
            childFrame.GreetingText:SetText(GetGossipTitle(childFrame.GreetingText:GetText()))
            --
            optionHeightOffset = childFrame.GreetingText:GetHeight() - currentHeight
            if (optionHeightOffset < 1) then optionHeightOffset = 0 end
            --
        elseif (buttonType == GOSSIP_BUTTON_TYPE_OPTION or buttonType == GOSSIP_BUTTON_TYPE_ACTIVE_QUEST or buttonType == GOSSIP_BUTTON_TYPE_AVAILABLE_QUEST) then
            --
            if (optionHeightOffset > 0) then
                local point, relativeTo, relativePoint, xOfs, yOfs = childFrame:GetPoint(1)
                childFrame:ClearAllPoints()
                childFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs - optionHeightOffset)
            end
            --
            local currentHeight = childFrame:GetHeight()
            --
            -- local text = childFrame:GetText();
            -- if (text == debug_option_1) then
            --     childFrame:SetText(debug_option_1_tr)
            -- elseif (text == debug_option_2) then
            --     childFrame:SetText(debug_option_2_tr)
            -- elseif (text == debug_option_3) then
            --     childFrame:SetText(debug_option_3_tr)
            -- end
            --
            childFrame:SetText(GetGossipOptionText(childFrame:GetText()))
            childFrame:Resize();

            local currentHeightOffset = childFrame:GetHeight() - currentHeight
            if (currentHeightOffset < 1) then currentHeightOffset = 0 end

            if (currentHeightOffset > 0) then
                optionHeightOffset = optionHeightOffset + currentHeightOffset;
            end
            --
        end
    end
end

function translator:initialize()
    GossipFrame.GreetingPanel.GoodbyeButton:SetText("Прощавай"); -- goodbye

    eventHandler:Register(function()
        if (not self:IsEnabled()) then return end
        OnGossipShow()
    end, "GOSSIP_SHOW", "GOSSIP_CLOSED")
end
