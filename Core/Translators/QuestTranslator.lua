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

local function QuestInfo_GetQuestID()
    if (QuestInfoFrame.questLog) then
        return C_QuestLog.GetSelectedQuest();
    else
        return GetQuestID();
    end
end

function TryCallAPIFn(fnName, value)
    -- this function is helper fn to get table type from wow api.
    -- if there is GetObjectType then we will return it.
    -- returns Button, Frame or something like this

    -- VALIDATION
    if type(value) ~= "table" then
        return
    end

    -- VALIDATION FIX if __index is function we don't want to execute it
    -- Example in ACP.L
    local metatable = getmetatable(value)
    if metatable and type(metatable) == "table" and type(metatable.__index) == "function" then
        return
    end

    -- VALIDATION is forbidden from wow api
    if value.IsForbidden then
        local ok, forbidden = pcall(value.IsForbidden, value)
        if not ok or (ok and forbidden) then
            return
        end
    end

    local fn = value[fnName]
    -- VALIDATION has WoW API
    if not fn or type(fn) ~= "function" then
        return
    end

    -- MAIN PART:
    return pcall(fn, value)
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

local function translteObjectives(objectiveFrames, objectivesText, objectives)
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
            elseif (not objectives and objectivesText) then
                uiObject:SetText(objectivesText)
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
        local uiForTranslation = nil
        if (objectiveFrame:IsObjectType("FontString")) then
            uiForTranslation = objectiveFrame
        else
            uiForTranslation = objectiveFrame.Text
        end

        if (objectiveID == 'QuestComplete') then
            if (uiForTranslation:GetText() == QUEST_WATCH_QUEST_READY) then
                uiForTranslation:SetText('Можна здавати') -- TODO: Move to constants 'Ready for turn-in' and 'Можна здавати'
            elseif (not objectives and objectivesText) then
                uiForTranslation:SetText(objectivesText)
            end
        else
            local objectiveText = objectives and objectives[tonumber(objectiveID)]
            if (objectiveText) then
                local originalText = uiForTranslation:GetText()
                local progressText = string.match(originalText, "^(%d+/%d+)")
                if (progressText) then
                    uiForTranslation:SetText(progressText .. " " .. objectiveText)
                else
                    uiForTranslation:SetText(objectiveText)
                end
            end
        end
    end
end

local function updateTrackerModule(module)
    print("onUpdateQuestTrackerModule")
    local objectiveTrackerBlockTemplate = module.usedBlocks["ObjectiveTrackerBlockTemplate"]
    if (not objectiveTrackerBlockTemplate) then return end

    for questID, questObjectiveBlock in pairs(objectiveTrackerBlockTemplate) do
        local questData = GetQuestData(tonumber(questID))
        if (questData and questData.Title) then
            questObjectiveBlock.HeaderText:SetText(questData.Title)
        end

        local objectives = GetQuestObjectives(tonumber(questID))
        translteObjectives(questObjectiveBlock.lines, questData and questData.ObjectivesText, objectives)
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
    QuestInfoDescriptionHeader:SetText("Опис") -- Quest Objectives

    --QuestFrame:HookScript("OnShow", onQuestFrameShow);

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
    hooksecurefunc(QUEST_TRACKER_MODULE, "Update", updateTrackerModule)
    hooksecurefunc(CAMPAIGN_QUEST_TRACKER_MODULE, "Update", updateTrackerModule)

    -- Quest popup
    QuestLogPopupDetailFrame.ShowMapButton.Text:SetText("Показати карту"); -- Show Map
    QuestLogPopupDetailFrame.AbandonButton:SetText("Bідмовитися"); -- Abandon
    QuestLogPopupDetailFrame.AbandonButton:FitToText();
    QuestLogPopupDetailFrame.ShareButton:SetText("Поділитися"); -- Share
    QuestLogPopupDetailFrame.ShareButton:FitToText();

    hooksecurefunc("QuestInfo_Display", function(template, parentFrame)
        local questID = QuestInfo_GetQuestID()
        print("Quest ID: ", questID)

        if (not questID or questID == 0) then return end

        local questData = GetQuestData(questID)
        local objectives = GetQuestObjectives(questID)

        if (not questData and not objectives) then return end

        local elementsTable = template.elements;
        for i = 1, #elementsTable, 3 do
            local shownFrame, bottomShownFrame = elementsTable[i](parentFrame);
            if (shownFrame) then
                local _, name = TryCallAPIFn("GetName", shownFrame)
                local logRow = "index: " .. i .. " Name: " .. name
                print(logRow)

                DevTool:AddData(shownFrame, logRow)
                DevTool:AddData(bottomShownFrame, logRow)

                if (name == "QuestInfoTitleHeader") then
                    if (questData and questData.Title) then QuestInfoTitleHeader:SetText(questData.Title) end
                elseif (name == "QuestInfoObjectivesText") then
                    if (questData and questData.ObjectivesText) then
                        QuestInfoObjectivesText:SetText(questData.ObjectivesText)
                    end
                elseif (name == "QuestInfoObjectivesFrame") then
                    if (objectives) then
                        translteObjectives(QuestInfoObjectivesFrame.Objectives, questData and questData.ObjectivesText,
                            objectives)
                    end
                elseif (name == "QuestInfoDescriptionHeader") then
                    -- ignore
                elseif (name == "QuestInfoDescriptionText") then
                    if (questData and questData.Description) then QuestInfoDescriptionText:SetText(questData.Description) end
                elseif (name == "QuestInfoSpacerFrame") then
                    -- ignore
                elseif (name == "QuestInfoRewardsFrame") then
                    QuestInfoRewardsFrame.ItemChooseText:SetText("Ти зможеш вибрати одну з цих винагород:"); -- You will be ableІ to choose one of these rewards:
                    QuestInfoRewardsFrame.ItemReceiveText:SetText("Ти отримаєш:"); -- You will receive: or You will also receive:
                    -- Completing this quest while in Party Sync may reward:
                    QuestInfoRewardsFrame.QuestSessionBonusReward:SetText(
                        "Проходження цього завдання в режимі синхронізації групи передбачає винагороду:");
                elseif (name == "MapQuestInfoRewardsFrame") then
                end
            end
        end

        -- TODO: check and move to right place
        if (QuestModelScene:IsVisible()) then
            if (not questData) then return end
            if (questData.TargetName) then QuestNPCModelNameText:SetText(questData.TargetName) end
            if (questData.TargetDescription) then QuestNPCModelText:SetText(questData.TargetDescription) end
        end
    end)

    hooksecurefunc("QuestMapFrame_UpdateQuestDetailsButtons", updateQuestDetailsButtons)
end
