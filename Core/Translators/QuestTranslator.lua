local _, ns = ...;

local eventHandler = ns.EventHandler:new()

local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetGossipTitle = ns.DbContext.Gossips.GetGossipTitle
local GetGossipOptionText = ns.DbContext.Gossips.GetGossipOptionText
local GetQuestTitle = ns.DbContext.Quests.GetQuestTitle
local GetQuestData = ns.DbContext.Quests.GetQuestData

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
    print("OnGossipShow")
    local title = GossipFrameTitleText:GetText();
    GossipFrameTitleText:SetText(GetUnitNameOrDefault(title));

    local optionHeightOffset = 0
    for _, childFrame in GossipFrame.GreetingPanel.ScrollBox:EnumerateFrames() do
        local data = childFrame:GetElementData()
        local buttonType = data.buttonType
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
            if (buttonType == GOSSIP_BUTTON_TYPE_OPTION) then
                childFrame:SetText(GetGossipOptionText(childFrame:GetText()))
                childFrame:Resize();
            else
                local translatedTitle = GetQuestTitle(tonumber(data.info.questID))
                if (translatedTitle) then
                    childFrame:SetText(translatedTitle)
                    childFrame:Resize();
                end
            end

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
    -- Gossip Frame
    GossipFrame.GreetingPanel.GoodbyeButton:SetText("Прощавай"); -- Goodbye
    GossipFrame.GreetingPanel.GoodbyeButton:FitToText();
    eventHandler:Register(OnGossipShow, "GOSSIP_SHOW", "GOSSIP_CLOSED")

    -- Quest Frame
    QuestFrameAcceptButton:SetText("Прийняти"); -- Accept
    QuestFrameAcceptButton:FitToText();
    QuestFrameDeclineButton:SetText("Відмовитись"); -- Decline
    QuestFrameDeclineButton:FitToText();
    QuestFrameCompleteQuestButton:SetText("Завершити завдання"); -- Complete Quest
    QuestFrameCompleteQuestButton:FitToText();
    QuestInfoRewardsFrame.Header:SetText("Винагорода"); -- Rewards
    QuestInfoRewardsFrame.XPFrame.ReceiveText:SetText("Досвід:") -- Experiense:
    QuestInfoObjectivesHeader:SetText("Цілі завдання") -- Quest Objectives

    -- Objectives Frame
    ObjectiveTrackerFrame.HeaderMenu.Title:SetText("Задачі") -- Objectives
    ObjectiveTrackerBlocksFrame.AchievementHeader.Text:SetText("Досягнення") -- Achievements
    ObjectiveTrackerBlocksFrame.AdventureHeader.Text:SetText("Колекції") -- Collections
    ObjectiveTrackerBlocksFrame.CampaignQuestHeader.Text:SetText("Кампанія") -- Campaign
    ObjectiveTrackerBlocksFrame.MonthlyActivitiesHeader.Text:SetText("Щоденник мандрівника") -- Traveler's Log
    ObjectiveTrackerBlocksFrame.ProfessionHeader.Text:SetText("Професія") -- Profession
    ObjectiveTrackerBlocksFrame.ScenarioHeader.Text:SetText("Сценарій") -- Scenario

    ObjectiveTrackerBlocksFrame.QuestHeader:HookScript("OnShow", function()
        print("ObjectiveTrackerBlocksFrame.ProfessionHeader:HookScript")
        ObjectiveTrackerBlocksFrame.QuestHeader.Text:SetText("Завдання")
    end)
    eventHandler:Register(function()
        print("QUEST_SESSION_JOINED or QUEST_SESSION_LEFT")
        ObjectiveTrackerBlocksFrame.QuestHeader.Text:SetText("Завдання")
    end, "QUEST_SESSION_JOINED", "QUEST_SESSION_LEFT")

    QuestFrame:HookScript("OnShow", function()
        QuestInfoRewardsFrame.ItemChooseText:SetText("Ти зможеш вибрати одну з цих винагород:"); -- You will be ableІ to choose one of these rewards:
        QuestInfoRewardsFrame.ItemReceiveText:SetText("Ти отримаєш:"); -- You will receive: or You will also receive:
        -- Completing this quest while in Party Sync may reward:
        QuestInfoRewardsFrame.QuestSessionBonusReward:SetText(
            "Проходження цього завдання в режимі синхронізації групи передбачає винагороду:");

        local questID = GetQuestID();
        if (questID) then
            print("QuestFrame:OnShow", questID)

            local questData = GetQuestData(questID)
            if (not questData) then return end

            if (questData.Title) then QuestInfoTitleHeader:SetText(questData.Title) end
            if (questData.Description) then QuestInfoDescriptionText:SetText(questData.Description) end
            if (questData.ObjectivesText) then QuestInfoObjectivesText:SetText(questData.ObjectivesText) end
            if (QuestModelScene:IsVisible()) then
                print("QuestModelScene:IsVisible")
                if (questData.TargetName) then QuestNPCModelNameText:SetText(questData.TargetName) end
                if (questData.TargetDescription) then QuestNPCModelText:SetText(questData.TargetDescription) end
            end
        end
    end);
end
