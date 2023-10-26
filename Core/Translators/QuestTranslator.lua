local _, ns = ...;

local _G = _G

local settingsProvider = ns.SettingsProvider:new()
local eventHandler = ns.EventHandler:new()

local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetGossipTitle = ns.DbContext.Gossips.GetGossipTitle
local GetGossipOptionText = ns.DbContext.Gossips.GetGossipOptionText
local GetQuestTitle = ns.DbContext.Quests.GetQuestTitle
local GetQuestData = ns.DbContext.Quests.GetQuestData
local GetQuestObjective = ns.DbContext.Quests.GetQuestObjective

local ACTIVE_TEMPLATE;
local ACTIVE_PARENT_FRAME;
local switchObjectivesTranslationButton

local translator = class("QuestTranslator", ns.Translators.BaseTranslator)
ns.Translators.QuestTranslator = translator

-- local debug_title =
-- [[О, вітаю. Елвінський ліс такий мирний і безтурботний. Єдине, про що варто хвилюватися - це бандити, мурлоки та випадкові гноли, які привертають до себе всю увагу. Це, мабуть, найспокійніший край у Східних Королівствах.

-- Але не для вас, вершників на драконах. У "Подорожі по Елвінському лісі" тобі доведеться мчати понад землею та крізь гілки цих розкішних дерев. Обережно, не вріжся на повній швидкості в стовбур, інакше доведеться використовувати свій Бронзовий годинник, щоб повернути свої зламані кістки на місце. Чи вистачить у тебе сміливості?]]

-- local debug_option_1 = "I'd like to try the course."
-- local debug_option_1_tr =
-- "Я хочу спробувати маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут."

-- local debug_option_2 = "I'd like to try the Advanced course."
-- local debug_option_2_tr =
-- "Я хочу спробувати розширений маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут."

-- local debug_option_3 = "I'd like to try the Reverse course."
-- local debug_option_3_tr =
-- "Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут.Я хочу спробувати зворотній маршрут."

local function getQuestID()
    if (QuestInfoFrame.questLog) then
        return C_QuestLog.GetSelectedQuest();
    else
        return GetQuestID();
    end
end

_G.StaticPopupDialogs["WowUkrainizer_WowheadLink"] = {
    text = "Натисніть Ctrl+C, щоб скопіювати URL-адресу в буфер обміну",
    hasEditBox = 1,
    button1 = "Гаразд",
    OnShow = function(self)
        local questID = getQuestID()
        if questID and questID ~= 0 then
            local box = getglobal(self:GetName() .. "EditBox")
            if box then
                box:SetWidth(275)
                box:SetText("https://www.wowhead.com/quest=" .. questID)
                box:HighlightText()
                box:SetFocus()
            end
        end
    end,

    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

local function getQuestFrameTranslationOrDefault(default)
    return ns.DbContext.Frames.GetTranslationOrDefault("quest", default)
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

local function TranslteQuestObjective(objectiveFrame, questData)
    if (not questData) then return end

    local text = objectiveFrame:GetText()
    local isComplete = C_QuestLog.IsComplete(questData.ID);

    if (isComplete) then
        if (text == QUEST_WATCH_QUEST_READY) then
            objectiveFrame:SetText('Можна здавати') -- TODO: Move to constants 'Можна здавати'
        else
            local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questData.ID)
            local completionText = GetQuestLogCompletionText(questLogIndex)
            if (completionText and questData.CompletionText) then
                objectiveFrame:SetText(questData.CompletionText)
            elseif ((not completionText and not questData.ContainsObjectives) and questData.ObjectivesText) then
                objectiveFrame:SetText(questData.ObjectivesText)
            end
        end

        return
    end

    objectiveFrame:SetText(GetQuestObjective(questData.ID, text))
end

local function TranslteQuestObjectives(objectiveFrames, questData)
    if (not questData) then return end

    for _, objectiveFrame in pairs(objectiveFrames) do
        TranslteQuestObjective(objectiveFrame.Text or objectiveFrame, questData)
    end
end

local function OnGossipShow()
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

local function OnObjectiveTrackerQuestHeaderUpdated()
    ObjectiveTrackerBlocksFrame.QuestHeader.Text:SetText("Завдання") -- Quest
end

local function OnQuestMapLogTitleButtonTooltipShow(button)
    local info = C_QuestLog.GetInfo(button.questLogIndex);
    assert(info and not info.isHeader);

    local questID = info.questID;
    local questData = GetQuestData(questID)
    if (not questData) then return end

    QuestMapFrame:GetParent():SetHighlightedQuestID(questID);

    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPLEFT", button, "TOPRIGHT", 34, 0);
    GameTooltip:SetOwner(button, "ANCHOR_PRESERVE");
    GameTooltip:SetText(questData.Title);
    local tooltipWidth = 20 + max(231, GameTooltipTextLeft1:GetStringWidth());
    if (tooltipWidth > UIParent:GetRight() - QuestMapFrame:GetParent():GetRight()) then
        GameTooltip:ClearAllPoints();
        GameTooltip:SetPoint("TOPRIGHT", button, "TOPLEFT", -5, 0);
        GameTooltip:SetOwner(button, "ANCHOR_PRESERVE");
        GameTooltip:SetText(questData.Title);
    end

    if C_QuestLog.IsQuestReplayable(questID) then
        GameTooltip_AddInstructionLine(GameTooltip,
            QuestUtils_GetReplayQuestDecoration(questID) ..
            getQuestFrameTranslationOrDefault(QUEST_SESSION_QUEST_TOOLTIP_IS_REPLAY), false);
    elseif C_QuestLog.IsQuestDisabledForSession(questID) then
        GameTooltip_AddColoredLine(GameTooltip,
            QuestUtils_GetDisabledQuestDecoration(questID) ..
            getQuestFrameTranslationOrDefault(QUEST_SESSION_ON_HOLD_TOOLTIP_TITLE),
            DISABLED_FONT_COLOR, false);
    end

    -- quest tag
    local tagInfo = C_QuestLog.GetQuestTagInfo(questID);
    if (tagInfo) then
        local tagName = tagInfo.tagName;
        local factionGroup = GetQuestFactionGroup(questID);
        -- Faction-specific account quests have additional info in the tooltip
        if (tagInfo.tagID == Enum.QuestTag.Account and factionGroup) then
            local factionString = FACTION_ALLIANCE;
            if (factionGroup == LE_QUEST_FACTION_HORDE) then
                factionString = FACTION_HORDE;
            end
            tagName = format("%s (%s)", tagName, factionString);
        end

        local overrideQuestTag = tagInfo.tagID;
        if (QuestUtils_GetQuestTagAtlas(tagInfo.tagID)) then
            if (tagInfo.tagID == Enum.QuestTag.Account and factionGroup) then
                overrideQuestTag = "ALLIANCE";
                if (factionGroup == LE_QUEST_FACTION_HORDE) then
                    overrideQuestTag = "HORDE";
                end
            end
        end

        -- TODO: Translate TAG INFO ?
        QuestUtils_AddQuestTagLineToTooltip(GameTooltip, tagName, overrideQuestTag, tagInfo.worldQuestType,
            NORMAL_FONT_COLOR);
    end

    GameTooltip_CheckAddQuestTimeToTooltip(GameTooltip, questID);

    if (info.frequency == Enum.QuestFrequency.Daily) then
        QuestUtils_AddQuestTagLineToTooltip(GameTooltip, getQuestFrameTranslationOrDefault(DAILY), "DAILY", nil,
            NORMAL_FONT_COLOR);
    elseif (info.frequency == Enum.QuestFrequency.Weekly) then
        QuestUtils_AddQuestTagLineToTooltip(GameTooltip, getQuestFrameTranslationOrDefault(WEEKLY), "WEEKLY", nil,
            NORMAL_FONT_COLOR);
    end

    if C_QuestLog.IsFailed(info.questID) then
        QuestUtils_AddQuestTagLineToTooltip(GameTooltip, getQuestFrameTranslationOrDefault(FAILED), "FAILED", nil,
            RED_FONT_COLOR);
    end

    GameTooltip:AddLine(" ");

    -- description
    local isComplete = C_QuestLog.IsComplete(info.questID);
    if isComplete then
        local completionText = GetQuestLogCompletionText(button.questLogIndex)
        if (completionText) then
            completionText = questData.CompletionText
        else
            completionText = getQuestFrameTranslationOrDefault(QUEST_WATCH_QUEST_READY)
        end
        GameTooltip:AddLine(completionText, 1, 1, 1, true);
        GameTooltip:AddLine(" ");
    else
        local needsSeparator = false;
        GameTooltip:AddLine(questData.ObjectivesText, 1, 1, 1, true);
        GameTooltip:AddLine(" ");
        local requiredMoney = C_QuestLog.GetRequiredMoney(questID);
        local numObjectives = GetNumQuestLeaderBoards(button.questLogIndex);
        for i = 1, numObjectives do
            local text, _, finished = GetQuestLogLeaderBoard(i, button.questLogIndex);
            if (text) then
                local color = HIGHLIGHT_FONT_COLOR;
                if (finished) then
                    color = GRAY_FONT_COLOR;
                end
                GameTooltip:AddLine(QUEST_DASH .. GetQuestObjective(questID, text), color.r, color.g, color.b,
                    true);
                needsSeparator = true;
            end
        end
        if (requiredMoney > 0) then
            local playerMoney = GetMoney();
            local color = HIGHLIGHT_FONT_COLOR;
            if (requiredMoney <= playerMoney) then
                playerMoney = requiredMoney;
                color = GRAY_FONT_COLOR;
            end
            GameTooltip:AddLine(QUEST_DASH .. GetMoneyString(playerMoney) .. " / " .. GetMoneyString(requiredMoney),
                color.r, color.g, color.b);
            needsSeparator = true;
        end

        if (needsSeparator) then
            GameTooltip:AddLine(" ");
        end
    end

    GameTooltip:AddLine(getQuestFrameTranslationOrDefault(CLICK_QUEST_DETAILS),
        GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);

    if QuestUtils_GetNumPartyMembersOnQuest(questID) > 0 then
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(getQuestFrameTranslationOrDefault(PARTY_QUEST_STATUS_ON));

        local omitTitle = true;
        local ignoreActivePlayer = true;
        GameTooltip:SetQuestPartyProgress(questID, omitTitle, ignoreActivePlayer); -- TODO: Translate?
    end

    GameTooltip:Show();
end

local function OnQuestLogQuestsUpdate()
    for titleFrame in QuestScrollFrame.titleFramePool:EnumerateActive() do
        local translatedTitle = GetQuestTitle(titleFrame.questID)
        if (translatedTitle) then
            titleFrame.Text:SetText(translatedTitle)
        end
    end

    for objectiveFramePool in QuestScrollFrame.objectiveFramePool:EnumerateActive() do
        TranslteQuestObjective(objectiveFramePool.Text, GetQuestData(objectiveFramePool.questID))
    end

    -- local i = 1
    -- for headerFramePool in QuestScrollFrame.headerFramePool:EnumerateActive() do
    --     DevTool:AddData(headerFramePool, "headerFramePool " .. i)
    --     i = i + 1
    -- end

    -- i = 1
    -- for campaignHeaderFramePool in QuestScrollFrame.campaignHeaderFramePool:EnumerateActive() do
    --     DevTool:AddData(campaignHeaderFramePool, "campaignHeaderFramePool " .. i)
    --     i = i + 1
    -- end

    -- i = 1
    -- for campaignHeaderMinimalFramePool in QuestScrollFrame.campaignHeaderMinimalFramePool:EnumerateActive() do
    --     DevTool:AddData(campaignHeaderMinimalFramePool, "campaignHeaderMinimalFramePool " .. i)
    --     i = i + 1
    -- end

    -- i = 1
    -- for covenantCallingsHeaderFramePool in QuestScrollFrame.covenantCallingsHeaderFramePool:EnumerateActive() do
    --     DevTool:AddData(covenantCallingsHeaderFramePool, "covenantCallingsHeaderFramePool " .. i)
    --     i = i + 1
    -- end
    -- DevTool:AddData("!done!", "---")
end

local function UpdateTrackerModule(module)
    local objectiveTrackerBlockTemplate = module.usedBlocks["ObjectiveTrackerBlockTemplate"]
    if (not objectiveTrackerBlockTemplate) then return end

    for questID, questObjectiveBlock in pairs(objectiveTrackerBlockTemplate) do
        local questData = GetQuestData(tonumber(questID))
        if (questData and questData.Title) then
            questObjectiveBlock.HeaderText:SetText(questData.Title)
        end
        TranslteQuestObjectives(questObjectiveBlock.lines, questData)
    end
end

local function UpdateQuestDetailsButtons()
    local text = QuestMapFrame.DetailsFrame.TrackButton:GetText()
    local translatedText = ''
    if (text == TRACK_QUEST_ABBREV) then
        translatedText = "Відстежувати"
    else
        translatedText = "Не відстежувати"
    end

    QuestMapFrame.DetailsFrame.TrackButton:SetText(translatedText);
    QuestMapFrame.DetailsFrame.TrackButton:SetSize(110, 22)

    QuestLogPopupDetailFrame.TrackButton:SetText(translatedText);
    QuestLogPopupDetailFrame.TrackButton:FitToText();
end

local function ShowQuestPortrait()
    local questID = getQuestID()
    if (not questID or questID == 0) then return end

    local questData = GetQuestData(questID)
    if (not questData) then return end

    if (questData.TargetName) then QuestNPCModelNameText:SetText(questData.TargetName) end
    if (questData.TargetDescription) then QuestNPCModelText:SetText(questData.TargetDescription) end
end

local function DisplayQuestInfo(template, parentFrame)
    if (template ~= QUEST_TEMPLATE_MAP_REWARDS) then
        ACTIVE_TEMPLATE = template
        ACTIVE_PARENT_FRAME = parentFrame
    end

    local questID = getQuestID()
    if (not questID or questID == 0) then return end

    local questData = GetQuestData(questID)

    local elementsTable = template.elements;
    for i = 1, #elementsTable, 3 do
        local shownFrame, _ = elementsTable[i](parentFrame);
        if (shownFrame) then
            local _, name = TryCallAPIFn("GetName", shownFrame)
            if (name == "QuestInfoTitleHeader") then
                if (WowUkrainizer_Options.TranslateQuestText) then
                    if (questData and questData.Title) then
                        QuestInfoTitleHeader:SetText(questData.Title)
                    end
                end
            elseif (name == "QuestInfoObjectivesText") then
                if (WowUkrainizer_Options.TranslateQuestText) then
                    if (questData and questData.ObjectivesText) then
                        QuestInfoObjectivesText:SetText(questData.ObjectivesText)
                    end
                end
            elseif (name == "QuestInfoObjectivesFrame") then
                if (WowUkrainizer_Options.TranslateQuestText) then
                    TranslteQuestObjectives(QuestInfoObjectivesFrame.Objectives, questData)
                end
            elseif (name == "QuestInfoDescriptionHeader") then
                -- ignore
            elseif (name == "QuestInfoDescriptionText") then
                if (WowUkrainizer_Options.TranslateQuestText) then
                    if (questData and questData.Description) then
                        QuestInfoDescriptionText:SetText(questData.Description)
                    end
                end
            elseif (name == "QuestInfoSpacerFrame") then
                -- ignore
            elseif (name == "QuestInfoRewardsFrame") then
                QuestInfoRewardsFrame.ItemChooseText:SetText("Ти зможеш вибрати одну з цих винагород:"); -- You will be ableІ to choose one of these rewards:
                QuestInfoRewardsFrame.ItemReceiveText:SetText("Ти отримаєш:"); -- You will receive: or You will also receive:
                -- Completing this quest while in Party Sync may reward:
                QuestInfoRewardsFrame.QuestSessionBonusReward:SetText(
                    "Проходження цього завдання в режимі синхронізації групи передбачає винагороду:");
            elseif (name == "MapQuestInfoRewardsFrame") then
                -- ignore
                QuestInfoFrame.rewardsFrame.ItemChooseText:SetText("Ти отримаєш:") -- You will receive:
                QuestInfoFrame.rewardsFrame.ItemReceiveText:SetText("Ти також отримаєш:") -- You will also receive:
                QuestInfoFrame.rewardsFrame.PlayerTitleText:SetText("Ви отримаєте титул:") -- You shall be granted the title:
                QuestInfoFrame.rewardsFrame.QuestSessionBonusReward:SetText(
                    "При виконання цього квесту в режимі Party Sync дасть можливість отримати винагороду:") -- Completing this quest while in Party Sync may reward:
                QuestInfoFrame.rewardsFrame.WarModeBonusFrame:SetText("Бонус від режиму війни") -- War Mode Bonus
            end
        end
    end
end

local function GetCampaignTooltipFromQuestMapLog()
    -- TODO:
    -- DevTool: ChapterTitle - (4) FontString 'Campaign Progress0/3 Chapters' table: 00000139E4425670
    -- DevTool: Description - (4) FontString 'Trouble in Tiragarde SoundDarkness of DrustvarSecrets of Stormsong Valley' table: 00000139E4425710
    -- DevTool: Title - (3) FontString 'Battle for Azeroth' table: 00000139E44255D0
    -- if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
    -- if (not _G.WowUkrainizerData.QuestData) then _G.WowUkrainizerData.QuestData = {} end
    -- if (not _G.WowUkrainizerData.QuestData.CampaignTooltip) then _G.WowUkrainizerData.QuestData.CampaignTooltip = {} end
    -- _G.WowUkrainizerData.QuestData.CampaignTooltip.Title = QuestScrollFrame.CampaignTooltip.Title:GetText()
    -- _G.WowUkrainizerData.QuestData.CampaignTooltip.Description = QuestScrollFrame.CampaignTooltip.Description:GetText()
    -- _G.WowUkrainizerData.QuestData.CampaignTooltip.ChapterTitle = QuestScrollFrame.CampaignTooltip.ChapterTitle:GetText()
end

local function InitializeCommandButtons()
    local function CreateSwitchTranslationButton(parentFrame, offsetX, offsetY)
        local button = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate");
        button:SetSize(90, 24);
        if (WowUkrainizer_Options.TranslateQuestText) then
            button:SetText("Оригінал");
        else
            button:SetText("Переклад");
        end
        button:ClearAllPoints();
        button:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", offsetX, offsetY);
        button:SetScript("OnMouseDown", function(_)
            WowUkrainizer_Options.TranslateQuestText = not WowUkrainizer_Options.TranslateQuestText
            if (WowUkrainizer_Options.TranslateQuestText) then
                button:SetText("Оригінал");
            else
                button:SetText("Переклад");
            end
            QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
                QuestInfoFrame.mapView)
        end)
        button:Show();
    end

    local function CreateWowheadButton(parentFrame, offsetX, offsetY)
        local button = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate");
        button:SetSize(24, 24);
        button:ClearAllPoints();
        button:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", offsetX, offsetY);
        button:SetNormalAtlas("UI-HUD-MicroMenu-Shop-Up");
        button:SetPushedAtlas("UI-HUD-MicroMenu-Shop-Down");
        button:SetScript("OnMouseDown", function(_) _G.StaticPopup_Show("WowUkrainizer_WowheadLink") end)
        button:Show();
    end

    CreateSwitchTranslationButton(QuestFrame, -34, -30)
    CreateWowheadButton(QuestFrame, -6, -30)

    CreateSwitchTranslationButton(QuestLogPopupDetailFrame, -194, -28)
    CreateWowheadButton(QuestLogPopupDetailFrame, -166, -28)

    CreateSwitchTranslationButton(QuestMapDetailsScrollFrame, -16, 30)
    CreateWowheadButton(QuestMapDetailsScrollFrame, 12, 30)
end

local function OnObjectiveTrackerMinimizeButtonClick()
    print("OnObjectiveTrackerMinimizeButtonOnClick")
    if (not switchObjectivesTranslationButton) then return end
    if (ObjectiveTrackerFrame.collapsed) then
        switchObjectivesTranslationButton:Hide()
    else
        switchObjectivesTranslationButton:Show()
    end
end

function translator:initialize()
    InitializeCommandButtons()

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
    QuestInfoDescriptionHeader:SetText("Опис") -- Quest Objectives

    -- Objectives Frame
    ObjectiveTrackerFrame.HeaderMenu.Title:SetText("Задачі") -- Objectives
    ObjectiveTrackerBlocksFrame.AchievementHeader.Text:SetText("Досягнення") -- Achievements
    ObjectiveTrackerBlocksFrame.AdventureHeader.Text:SetText("Колекції") -- Collections
    ObjectiveTrackerBlocksFrame.CampaignQuestHeader.Text:SetText("Кампанія") -- Campaign
    ObjectiveTrackerBlocksFrame.MonthlyActivitiesHeader.Text:SetText("Щоденник мандрівника") -- Traveler's Log
    ObjectiveTrackerBlocksFrame.ProfessionHeader.Text:SetText("Професія") -- Profession
    ObjectiveTrackerBlocksFrame.ScenarioHeader.Text:SetText("Сценарій") -- Scenario

    ObjectiveTrackerFrame.HeaderMenu.MinimizeButton:HookScript("OnClick", OnObjectiveTrackerMinimizeButtonClick)
    ObjectiveTrackerBlocksFrame.QuestHeader:HookScript("OnShow", OnObjectiveTrackerQuestHeaderUpdated)
    eventHandler:Register(OnObjectiveTrackerQuestHeaderUpdated, "QUEST_SESSION_JOINED", "QUEST_SESSION_LEFT")
    hooksecurefunc(QUEST_TRACKER_MODULE, "Update", UpdateTrackerModule)
    hooksecurefunc(CAMPAIGN_QUEST_TRACKER_MODULE, "Update", UpdateTrackerModule)

    -- Quest popup
    QuestLogPopupDetailFrame.ShowMapButton.Text:SetText("Показати карту"); -- Show Map
    QuestLogPopupDetailFrame.AbandonButton:SetText("Bідмовитися"); -- Abandon
    QuestLogPopupDetailFrame.AbandonButton:FitToText();
    QuestLogPopupDetailFrame.ShareButton:SetText("Поділитися"); -- Share
    QuestLogPopupDetailFrame.ShareButton:FitToText();

    -- Quest map
    MapQuestInfoRewardsFrame.TitleFrame.Name:SetText("Винагорода"); -- Rewards

    for _, region in ipairs({ QuestMapFrame.DetailsFrame.RewardsFrame:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            if (region:GetText() == "Rewards") then
                region:SetText("Винагорода")
            end
        end
    end

    QuestMapFrame.DetailsFrame.AbandonButton:SetText("Bідмовитися"); -- Abandon
    QuestMapFrame.DetailsFrame.AbandonButton:SetSize(90, 22)

    QuestMapFrame.DetailsFrame.ShareButton:SetText("Поділитися"); -- Share
    QuestMapFrame.DetailsFrame.ShareButton:SetSize(90, 22)

    QuestMapFrame.DetailsFrame.BackButton:SetText("Повернутись"); -- Back
    QuestMapFrame.DetailsFrame.BackButton:FitToText();
    QuestMapFrame.DetailsFrame.BackButton:SetSize(QuestMapFrame.DetailsFrame.BackButton:GetWidth(), 24)

    hooksecurefunc("QuestInfo_Display", DisplayQuestInfo)
    hooksecurefunc("QuestFrame_ShowQuestPortrait", ShowQuestPortrait)
    hooksecurefunc("QuestMapFrame_UpdateQuestDetailsButtons", UpdateQuestDetailsButtons)
    hooksecurefunc("QuestLogQuests_Update", OnQuestLogQuestsUpdate)
    hooksecurefunc("QuestMapLogTitleButton_OnEnter", OnQuestMapLogTitleButtonTooltipShow)
    hooksecurefunc("QuestMapLog_GetCampaignTooltip", GetCampaignTooltipFromQuestMapLog)

    QuestScrollFrame.CampaignTooltip.CompleteRewardText:SetText("Закінчення цієї глави дасть вам винагороду:") -- WAR_CAMPAIGN_CHAPTER_REWARD_TEXT
end
