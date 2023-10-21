local _, ns = ...;

local eventHandler = ns.EventHandler:new()

local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetGossipTitle = ns.DbContext.Gossips.GetGossipTitle
local GetGossipOptionText = ns.DbContext.Gossips.GetGossipOptionText
local GetQuestTitle = ns.DbContext.Quests.GetQuestTitle
local GetQuestData = ns.DbContext.Quests.GetQuestData
local GetQuestObjectives = ns.DbContext.Quests.GetQuestObjectives

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

local function translteObjectives(objectiveFrames, questData, objectives)
    for objectiveID, objectiveFrame in pairs(objectiveFrames) do
        local uiObject = nil

        if (objectiveFrame:IsObjectType("FontString")) then
            uiObject = objectiveFrame
        else
            uiObject = objectiveFrame.Text
        end

        if (objectiveID == 'QuestComplete') then
            if (uiObject:GetText() == 'Ready for turn-in') then
                uiObject:SetText('Можна здавати') -- TODO: Move to constants 'Ready for turn-in' and 'Можна здавати'
            elseif (not objectives and questData.ObjectivesText) then
                uiObject:SetText(questData.ObjectivesText)
            end
        else
            local objectiveText = objectives and objectives[tonumber(objectiveID)]
            if (objectiveText) then
                local originalText = uiObject:GetText()
                local progressText = string.match(originalText, "^(%d+/%d+)")
                if (progressText) then
                    uiObject:SetText(progressText .. " " .. objectiveText)
                else
                    uiObject:SetText(objectiveText)
                end
            end
        end
    end
end

local function onGossipShow()
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

local function onQuestFrameShow(frame)
    QuestInfoRewardsFrame.ItemChooseText:SetText("Ти зможеш вибрати одну з цих винагород:"); -- You will be ableІ to choose one of these rewards:
    QuestInfoRewardsFrame.ItemReceiveText:SetText("Ти отримаєш:"); -- You will receive: or You will also receive:
    -- Completing this quest while in Party Sync may reward:
    QuestInfoRewardsFrame.QuestSessionBonusReward:SetText(
        "Проходження цього завдання в режимі синхронізації групи передбачає винагороду:");

    local questID = frame.questID
    if (not questID) then
        questID = GetQuestID();
    end

    if (questID and questID ~= 0) then
        print("QuestFrame or QuestLogPopupDetailFrame Show for quest ", questID)

        local questData = GetQuestData(questID)
        if (not questData) then return end

        if (questData.Title) then QuestInfoTitleHeader:SetText(questData.Title) end
        if (questData.Description) then QuestInfoDescriptionText:SetText(questData.Description) end
        if (questData.ObjectivesText) then QuestInfoObjectivesText:SetText(questData.ObjectivesText) end
        if (QuestModelScene:IsVisible()) then
            if (questData.TargetName) then QuestNPCModelNameText:SetText(questData.TargetName) end
            if (questData.TargetDescription) then QuestNPCModelText:SetText(questData.TargetDescription) end
        end

        if (QuestInfoObjectivesFrame:IsVisible()) then
            local objectives = GetQuestObjectives(tonumber(questID))
            translteObjectives(QuestInfoObjectivesFrame.Objectives, questData, objectives)
        end
    end
end

local function onUpdateQuestTrackerModule(module)
    for questID, questObjectiveBlock in pairs(module.usedBlocks["ObjectiveTrackerBlockTemplate"]) do
        print("Q: ", questID)
        local questData = GetQuestData(tonumber(questID))
        if (questData and questData.Title) then
            questObjectiveBlock.HeaderText:SetText(questData.Title)
        end

        local objectives = GetQuestObjectives(tonumber(questID))
        translteObjectives(questObjectiveBlock.lines, questData, objectives)
    end
end

local function onObjectiveTrackerQuestHeaderUpdated()
    ObjectiveTrackerBlocksFrame.QuestHeader.Text:SetText("Завдання") -- Quest
end

local function updateQuestDetailsButtons()
    local text = QuestMapFrame.DetailsFrame.TrackButton:GetText()
    local translatedText = ''
    if (text == TRACK_QUEST_ABBREV) then
        translatedText = "Відстежувати"
    else
        translatedText = "Не відстежувати"
    end

    QuestMapFrame.DetailsFrame.TrackButton:SetText(translatedText);
    QuestMapFrame.DetailsFrame.TrackButton:FitToText();

    QuestLogPopupDetailFrame.TrackButton:SetText(translatedText);
    QuestLogPopupDetailFrame.TrackButton:FitToText();
end

function translator:initialize()
    -- Gossip Frame
    GossipFrame.GreetingPanel.GoodbyeButton:SetText("Прощавай"); -- Goodbye
    GossipFrame.GreetingPanel.GoodbyeButton:FitToText();

    eventHandler:Register(onGossipShow, "GOSSIP_SHOW", "GOSSIP_CLOSED")

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

    QuestFrame:HookScript("OnShow", onQuestFrameShow);

    -- Objectives Frame
    ObjectiveTrackerFrame.HeaderMenu.Title:SetText("Задачі") -- Objectives
    ObjectiveTrackerBlocksFrame.AchievementHeader.Text:SetText("Досягнення") -- Achievements
    ObjectiveTrackerBlocksFrame.AdventureHeader.Text:SetText("Колекції") -- Collections
    ObjectiveTrackerBlocksFrame.CampaignQuestHeader.Text:SetText("Кампанія") -- Campaign
    ObjectiveTrackerBlocksFrame.MonthlyActivitiesHeader.Text:SetText("Щоденник мандрівника") -- Traveler's Log
    ObjectiveTrackerBlocksFrame.ProfessionHeader.Text:SetText("Професія") -- Profession
    ObjectiveTrackerBlocksFrame.ScenarioHeader.Text:SetText("Сценарій") -- Scenario

    ObjectiveTrackerBlocksFrame.QuestHeader:HookScript("OnShow", onObjectiveTrackerQuestHeaderUpdated)
    eventHandler:Register(onObjectiveTrackerQuestHeaderUpdated, "QUEST_SESSION_JOINED", "QUEST_SESSION_LEFT")
    hooksecurefunc(QUEST_TRACKER_MODULE, "Update", onUpdateQuestTrackerModule)
    hooksecurefunc(CAMPAIGN_QUEST_TRACKER_MODULE, "Update", onUpdateQuestTrackerModule)

    -- Quest popup
    QuestLogPopupDetailFrame.ShowMapButton.Text:SetText("Показати карту"); -- Show Map
    QuestLogPopupDetailFrame.AbandonButton:SetText("Bідмовитися"); -- Abandon
    QuestLogPopupDetailFrame.AbandonButton:FitToText();
    QuestLogPopupDetailFrame.ShareButton:SetText("Поділитися"); -- Share
    QuestLogPopupDetailFrame.ShareButton:FitToText();

    QuestLogPopupDetailFrame:HookScript("OnShow", onQuestFrameShow);
    hooksecurefunc("QuestMapFrame_UpdateQuestDetailsButtons", updateQuestDetailsButtons)
end
