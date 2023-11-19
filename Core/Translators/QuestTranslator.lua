local _, ns = ...;

local _G = _G

local eventHandler = ns.EventHandler:new()

local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetGossipTitle = ns.DbContext.Gossips.GetGossipTitle
local GetGossipOptionText = ns.DbContext.Gossips.GetGossipOptionText
local GetQuestTitle = ns.DbContext.Quests.GetQuestTitle
local GetQuestData = ns.DbContext.Quests.GetQuestData
local GetQuestObjective = ns.DbContext.Quests.GetQuestObjective
local GetQuestRewardText = ns.DbContext.Quests.GetQuestRewardText
local GetQuestProgressText = ns.DbContext.Quests.GetQuestProgressText
local ContainsQuestData = ns.DbContext.Quests.ContainsQuestData

local FACTION_ALLIANCE = ns.FACTION_ALLIANCE
local FACTION_HORDE = ns.FACTION_HORDE

local ABANDON_QUEST_CONFIRM_UA = ns.ABANDON_QUEST_CONFIRM_UA
local YES_UA = ns.YES_UA
local NO_UA = ns.NO_UA

local ACTIVE_TEMPLATE;
local ACTIVE_PARENT_FRAME;

local questFrameSwitchTranslationButton
local questPopupFrameSwitchTranslationButton
local questMapDetailsFrameSwitchTranslationButton

local ERR_QUEST_OBJECTIVE_COMPLETE_S = 302
local ERR_QUEST_UNKNOWN_COMPLETE = 303
local ERR_QUEST_ADD_KILL_SII = 304
local ERR_QUEST_ADD_FOUND_SII = 305
local ERR_QUEST_ADD_ITEM_SII = 306
local ERR_QUEST_ADD_PLAYER_KILL_SII = 307

local UIInfoMessageChange = {
    [ERR_QUEST_OBJECTIVE_COMPLETE_S] = {},
    [ERR_QUEST_UNKNOWN_COMPLETE] = {},
    [ERR_QUEST_ADD_KILL_SII] = {},
    [ERR_QUEST_ADD_FOUND_SII] = {},
    [ERR_QUEST_ADD_ITEM_SII] = {},
    [ERR_QUEST_ADD_PLAYER_KILL_SII] = {},
}

local WorldMapStorylineQuestPinsCache = {}
local WorldMapChildFramesCache = {}

local translator = class("QuestTranslator", ns.Translators.BaseTranslator)
ns.Translators.QuestTranslator = translator

local function getQuestFrameTranslationOrDefault(default)
    return ns.DbContext.Frames.GetTranslationOrDefault("quest", default)
end

local function translateUIFontString(fontString)
    if (not fontString.GetText or not fontString.SetText) then return end
    local text = fontString:GetText()
    local translateText = getQuestFrameTranslationOrDefault(text)
    if (text ~= translateText) then
        fontString:SetText(translateText)
    end
end

local function translateButton(button, width, height)
    translateUIFontString(button.Text)
    if (width and height) then
        button:SetSize(width, height)
    else
        button:FitToText()
        if (width) then
            button:SetSize(width, button:GetHeight())
        elseif (height) then
            button:SetSize(button:GetWidth(), height)
        end
    end
end

local function getQuestID()
    if (QuestInfoFrame.questLog) then
        return C_QuestLog.GetSelectedQuest();
    else
        return GetQuestID();
    end
end

local function showCommandButtonsForQuest(questID)
    if (ContainsQuestData(questID)) then
        questFrameSwitchTranslationButton:Show()
        questPopupFrameSwitchTranslationButton:Show()
        questMapDetailsFrameSwitchTranslationButton:Show()
    else
        questFrameSwitchTranslationButton:Hide()
        questPopupFrameSwitchTranslationButton:Hide()
        questMapDetailsFrameSwitchTranslationButton:Hide()
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

local function TranslteQuestObjective(objectiveFrame, questData, isQuestFrame)
    local originalHeight = objectiveFrame:GetHeight()
    if (not questData) then return originalHeight end

    local text = objectiveFrame:GetText()
    local isComplete = C_QuestLog.IsComplete(questData.ID);

    local translatedText = nil
    if (isComplete) then
        if (text == QUEST_WATCH_QUEST_READY) then
            translatedText = getQuestFrameTranslationOrDefault(QUEST_WATCH_QUEST_READY)
        else
            if (not isQuestFrame) then
                local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questData.ID)
                local completionText = GetQuestLogCompletionText(questLogIndex)
                if (completionText and questData.CompletionText) then
                    translatedText = questData.CompletionText
                elseif ((not completionText and not questData.ContainsObjectives) and questData.ObjectivesText) then
                    translatedText = questData.ObjectivesText
                end
            end
        end
    end

    if (not translatedText) then
        translatedText = GetQuestObjective(questData.ID, text)
    end

    objectiveFrame:SetText(translatedText)
    return objectiveFrame:GetHeight()
end

local function TranslteQuestObjectives(objectiveFrames, questData, isOnQuestFrame)
    if (not questData) then return 0 end

    local questObjectiveHeight = 0
    for _, objectiveFrame in pairs(objectiveFrames) do
        local objectiveHeight = TranslteQuestObjective(objectiveFrame.Text or objectiveFrame, questData, isOnQuestFrame)
        if (objectiveHeight) then
            objectiveFrame:SetHeight(objectiveHeight)
            questObjectiveHeight = questObjectiveHeight + objectiveHeight
        end
    end

    return questObjectiveHeight
end

local function OnGossipShow()
    local title = GossipFrameTitleText:GetText();
    GossipFrameTitleText:SetText(GetUnitNameOrDefault(title));

    local optionHeightOffset = 0
    for _, childFrame in GossipFrame.GreetingPanel.ScrollBox:EnumerateFrames() do
        local data = childFrame:GetElementData()
        local buttonType = data.buttonType
        if (buttonType == GOSSIP_BUTTON_TYPE_TITLE) then
            local currentHeight = childFrame.GreetingText:GetHeight()
            childFrame.GreetingText:SetText(GetGossipTitle(childFrame.GreetingText:GetText()))
            optionHeightOffset = childFrame.GreetingText:GetHeight() - currentHeight
            if (optionHeightOffset < 1) then optionHeightOffset = 0 end
        elseif (buttonType == GOSSIP_BUTTON_TYPE_OPTION or buttonType == GOSSIP_BUTTON_TYPE_ACTIVE_QUEST or buttonType == GOSSIP_BUTTON_TYPE_AVAILABLE_QUEST) then
            if (optionHeightOffset > 0) then
                local point, relativeTo, relativePoint, xOfs, yOfs = childFrame:GetPoint(1)
                childFrame:ClearAllPoints()
                childFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs - optionHeightOffset)
            end

            local currentHeight = childFrame:GetHeight()
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
        end
    end
end

local function OnObjectiveTrackerQuestHeaderUpdated()
    translateUIFontString(ObjectiveTrackerBlocksFrame.QuestHeader.Text)
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
        local tagName = tagInfo.tagName; -- TODO:
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
                end -- TODO: ?
                local translatedText = GetQuestObjective(questID, text)
                GameTooltip:AddLine(QUEST_DASH .. translatedText or text, color.r, color.g, color.b,
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
        GameTooltip:SetQuestPartyProgress(questID, omitTitle, ignoreActivePlayer);
    end

    GameTooltip:Show();
end

local function OnQuestLogQuestsUpdate()
    local updatedHeight = {}

    for titleFrame in QuestScrollFrame.titleFramePool:EnumerateActive() do
        local questID = titleFrame.questID
        if (not updatedHeight[questID]) then updatedHeight[questID] = 0 end

        local translatedTitle = GetQuestTitle(questID)
        if (translatedTitle) then
            titleFrame.Text:SetText(translatedTitle)
        end
        updatedHeight[questID] = updatedHeight[questID] + titleFrame.Text:GetHeight() + 2
    end

    for objectiveFramePool in QuestScrollFrame.objectiveFramePool:EnumerateActive() do
        local questID = objectiveFramePool.questID
        if (not updatedHeight[questID]) then updatedHeight[questID] = 0 end
        local objectiveHeight = TranslteQuestObjective(objectiveFramePool.Text, GetQuestData(questID), false)
        if (objectiveHeight > 0) then
            objectiveFramePool:SetHeight(objectiveHeight)
            updatedHeight[questID] = updatedHeight[questID] + objectiveHeight + 4
        end
    end

    for _, ChildFrame in pairs(QuestScrollFrame.Contents:GetLayoutChildren()) do
        local questID = ChildFrame.questID
        if (questID) then
            local height = updatedHeight[questID]
            if (height and ChildFrame:GetHeight() < height) then
                ChildFrame:SetHeight(height)
            end
        end
    end

    QuestScrollFrame.Contents:Layout();

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
        local block = module:GetBlock(questID);

        local blockHeight = 0;
        local questData = GetQuestData(tonumber(questID))
        if (questData and questData.Title) then
            questObjectiveBlock.HeaderText:SetText(questData.Title)
            blockHeight = questObjectiveBlock.HeaderText:GetHeight()
        end

        local objectivesHeights = TranslteQuestObjectives(questObjectiveBlock.lines, questData, false)

        for _, line in pairs(questObjectiveBlock.lines) do
            line:SetHeight(line.Text:GetHeight())
        end

        blockHeight = blockHeight + objectivesHeights + (block.module.lineSpacing * #questObjectiveBlock.lines)

        if (block:GetHeight() < blockHeight) then
            block:SetHeight(blockHeight)
        end
    end
end

local function UpdateQuestDetailsButtons()
    translateButton(QuestMapFrame.DetailsFrame.TrackButton, 110, 22);
    translateButton(QuestLogPopupDetailFrame.TrackButton);
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

    local title = QuestFrameTitleText:GetText();
    QuestFrameTitleText:SetText(GetUnitNameOrDefault(title));

    local questID = getQuestID()
    if (not questID or questID == 0) then return end

    showCommandButtonsForQuest(questID)

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
                    TranslteQuestObjectives(QuestInfoObjectivesFrame.Objectives, questData, true)
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
                if (WowUkrainizer_Options.TranslateQuestText) then
                    local rewardText = GetQuestRewardText(questID)
                    if (rewardText) then
                        QuestInfoRewardText:SetText(rewardText)
                    end
                end
                translateUIFontString(QuestInfoRewardsFrame.ItemChooseText)
                translateUIFontString(QuestInfoRewardsFrame.ItemReceiveText)
                translateUIFontString(QuestInfoRewardsFrame.QuestSessionBonusReward);
            elseif (name == "MapQuestInfoRewardsFrame") then
                -- ignore
                translateUIFontString(QuestInfoFrame.rewardsFrame.ItemChooseText)
                translateUIFontString(QuestInfoFrame.rewardsFrame.ItemReceiveText)
                translateUIFontString(QuestInfoFrame.rewardsFrame.PlayerTitleText)
                translateUIFontString(QuestInfoFrame.rewardsFrame.QuestSessionBonusReward)
                translateUIFontString(QuestInfoFrame.rewardsFrame.WarModeBonusFrame)
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

local function OnQuestFrameProgressPanelShow(_)
    local title = QuestFrameTitleText:GetText();
    QuestFrameTitleText:SetText(GetUnitNameOrDefault(title));

    local questID = getQuestID()
    if (not questID or questID == 0) then return end

    showCommandButtonsForQuest(questID)

    if (WowUkrainizer_Options.TranslateQuestText) then
        local title = GetQuestTitle(questID)
        if (title) then
            QuestProgressTitleText:SetText(title)
        end

        local progressText = GetQuestProgressText(questID)
        if (progressText) then
            QuestProgressText:SetText(progressText)
        end
    end
end

local function OnStaticPopupShow(which, text_arg1, text_arg2)
    local function _findStaticPopup()
        for index = 1, STATICPOPUP_NUMDIALOGS, 1 do
            local frame = _G["StaticPopup" .. index];
            if (frame:IsShown() and (frame.which == which)) then
                return frame
            end
        end
    end

    if (which == "ABANDON_QUEST") then
        local questId = getQuestID()
        if (not questId or questId == 0) then return end

        local frame = _findStaticPopup()
        if (not frame) then return end

        frame.text:SetFormattedText(ABANDON_QUEST_CONFIRM_UA, GetQuestTitle(questId) or text_arg1, text_arg2)
        frame.button1.Text:SetText(YES_UA)
        frame.button2.Text:SetText(NO_UA)

        StaticPopup_Resize(frame, which);
    end
end

local function InitializeCommandButtons()
    local function CreateSwitchTranslationButton(parentFrame, onClickFunc, offsetX, offsetY)
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
            onClickFunc()
        end)
        button:Show();
        return button
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

    questFrameSwitchTranslationButton = CreateSwitchTranslationButton(QuestFrame, function()
        if (QuestFrameProgressPanel:IsShown()) then
            QuestFrameProgressPanel_OnShow(QuestFrameProgressPanel)
        else
            QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
                QuestInfoFrame.mapView)
        end
    end, -34, -30)
    CreateWowheadButton(QuestFrame, -6, -30)

    questPopupFrameSwitchTranslationButton = CreateSwitchTranslationButton(QuestLogPopupDetailFrame, function()
        QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
            QuestInfoFrame.mapView)
    end, -194, -28)
    CreateWowheadButton(QuestLogPopupDetailFrame, -166, -28)

    questMapDetailsFrameSwitchTranslationButton = CreateSwitchTranslationButton(QuestMapDetailsScrollFrame, function()
        QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
            QuestInfoFrame.mapView)
    end, -16, 30)
    CreateWowheadButton(QuestMapDetailsScrollFrame, 12, 30)
end

local function OnUIErrorsFrameMessageAdded(_, message, _, _, _, _, messageType)
    if (messageType == ERR_QUEST_OBJECTIVE_COMPLETE_S) then
        local text = message
        message:gsub("(.*) %(Complete%)", function(t)
            text = t
        end)

        local translatedText = nil
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local questID = C_QuestLog.GetQuestIDForLogIndex(i);
            if questID and questID > 0 then
                local objective = GetQuestObjective(questID, text)
                if (objective ~= text) then
                    translatedText = objective .. " (Виконано)"
                    break
                end
            end
        end

        if (not translatedText) then return end

        table.insert(UIInfoMessageChange[ERR_QUEST_OBJECTIVE_COMPLETE_S],
            { text = message, translatedText = translatedText })
    end

    if (messageType == ERR_QUEST_ADD_ITEM_SII or messageType == ERR_QUEST_ADD_FOUND_SII) then
        local text = message
        local progress = nil
        message:gsub("(.*): (%d+/%d+)", function(o, p)
            text = o
            progress = p
        end)

        local translatedText = nil
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local questID = C_QuestLog.GetQuestIDForLogIndex(i);
            if questID and questID > 0 then
                local objective = GetQuestObjective(questID, text)
                if (objective ~= text) then
                    translatedText = objective
                    if (progress) then translatedText = translatedText .. ": " .. progress end
                    break
                end
            end
        end

        if (not translatedText) then return end

        table.insert(UIInfoMessageChange[messageType], { text = message, translatedText = translatedText })
    end

    if (messageType == ERR_QUEST_ADD_KILL_SII) then
        local text = message
        local progress = nil
        message:gsub("(.*) slain: (%d+/%d+)", function(o, p)
            text = o .. " slain"
            progress = p
        end)

        local translatedText = nil
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local questID = C_QuestLog.GetQuestIDForLogIndex(i);
            if questID and questID > 0 then
                local objective = GetQuestObjective(questID, text)
                if (objective ~= text) then
                    translatedText = objective
                    if (progress) then translatedText = translatedText .. ": " .. progress end
                    break
                end
            end
        end

        if (not translatedText) then return end

        table.insert(UIInfoMessageChange[messageType], { text = message, translatedText = translatedText })
    end


    if (messageType == ERR_QUEST_UNKNOWN_COMPLETE) then
        table.insert(UIInfoMessageChange[ERR_QUEST_UNKNOWN_COMPLETE],
            { text = message, translatedText = "Завдання виконано." })
    end

    if (messageType == ERR_QUEST_ADD_PLAYER_KILL_SII) then
        local translatedText = message:gsub("Players slain: (%d+/%d+)", function(progress)
            return "Вбито гравців: " .. progress
        end)
        table.insert(UIInfoMessageChange[ERR_QUEST_ADD_PLAYER_KILL_SII],
            { text = message, translatedText = translatedText })
    end
end

local function OnUIErrorsFrameUpdated()
    for messageType, messages in pairs(UIInfoMessageChange) do
        if (UIErrorsFrame:HasMessageByID(messageType)) then
            local fontString = UIErrorsFrame:GetFontStringByID(messageType)
            if (fontString) then
                for i = 1, #messages, 1 do
                    if (messages[i] and fontString:GetText() == messages[i].text) then
                        fontString:SetText(messages[i].translatedText)
                        table.remove(messages, i)
                    end
                end
            end
        end
    end
end

local function IsQuestDungeonQuest_Internal(tagID, worldQuestType) -- dublicate local function from blizzard code!
    if worldQuestType ~= nil then
        return WORLD_QUEST_TYPE_DUNGEON_TYPES[worldQuestType];
    end
    return QUEST_TAG_DUNGEON_TYPES[tagID];
end

local function GetTranslatedTooltip(frame, questID, questLogIndex, numPOITooltips)
    local translatedObjectives = {}
    local numObjectives = GetNumQuestLeaderBoards(questLogIndex);
    for i = 1, numObjectives do
        local text, _, finished;

        if numPOITooltips and numPOITooltips == numObjectives then
            local questPOIIndex = frame:GetTooltipIndex(i);
            text, _, finished = GetQuestPOILeaderBoard(questPOIIndex, questLogIndex);
        else
            text, _, finished = GetQuestLogLeaderBoard(i, questLogIndex);
        end

        if text and not finished then
            local translatedObjective = GetQuestObjective(questID, text)
            table.insert(translatedObjectives, QUEST_DASH .. translatedObjective or text)
        end
    end

    local translatedTitle = GetQuestTitle(questID)
    if (not translatedTitle) then
        translatedTitle = C_QuestLog.GetTitleForQuestID(questID);
    else
        translatedTitle = NORMAL_FONT_COLOR_CODE .. translatedTitle
    end

    return translatedTitle, translatedObjectives
end

local function OnWorldMapQuestPOIFrameTooltipUpdated(questPOIFrame) -- original function is QuestBlobPinMixin:UpdateTooltip()
    local mouseX, mouseY = questPOIFrame:GetMap():GetNormalizedCursorPosition();
    local questID, numPOITooltips = questPOIFrame:UpdateMouseOverTooltip(mouseX, mouseY);
    local questLogIndex = questID and C_QuestLog.GetLogIndexForQuestID(questID);
    if not questLogIndex then return end

    local gameTooltipOwner = GameTooltip:GetOwner();
    if gameTooltipOwner and gameTooltipOwner ~= questPOIFrame then return end
    if C_QuestLog.IsThreatQuest(questID) then return end

    local translatedTitle, objectives = GetTranslatedTooltip(questPOIFrame, questID, questLogIndex,
        numPOITooltips)
    _G["GameTooltipTextLeft1"]:SetText(translatedTitle)
    local objectiveOffset = 1
    local info = C_QuestLog.GetQuestTagInfo(questID);
    if (info and IsQuestDungeonQuest_Internal(info.tagID, info.worldQuestType)) then
        objectiveOffset = objectiveOffset + 1
        -- TODO: Translate QuestTypeToTooltip
        -- QuestUtils_AddQuestTypeToTooltip(GameTooltip, questID, NORMAL_FONT_COLOR);
    end
    for i = objectiveOffset + 1, GameTooltip:NumLines() do
        local lineLeft = _G["GameTooltipTextLeft" .. i]
        if (lineLeft) then
            local objective = objectives[i - 1]
            if (objective) then
                lineLeft:SetText(objective)
            end
        end
    end
    GameTooltip:Show()
end

local function OnWorldMapPinButtonTooltipUpdated(button) -- original function is QuestPinMixin:OnMouseEnter()
    local questID = button.questID;
    local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID);
    local translatedTitle = GetQuestTitle(questID)
    if (not translatedTitle) then
        translatedTitle = C_QuestLog.GetTitleForQuestID(questID);
    else
        translatedTitle = NORMAL_FONT_COLOR_CODE .. translatedTitle
    end
    _G["GameTooltipTextLeft1"]:SetText(translatedTitle)
    local objectiveOffset = 1
    local info = C_QuestLog.GetQuestTagInfo(questID);
    if (info and IsQuestDungeonQuest_Internal(info.tagID, info.worldQuestType)) then
        objectiveOffset = objectiveOffset + 1
        -- TODO: Translate QuestTypeToTooltip
        -- QuestUtils_AddQuestTypeToTooltip(GameTooltip, questID, NORMAL_FONT_COLOR);
    end
    if C_QuestLog.ShouldDisplayTimeRemaining(questID) then
        objectiveOffset = objectiveOffset + 1
        -- TODO: Translate QuestTimeToTooltip
        -- GameTooltip_CheckAddQuestTimeToTooltip(GameTooltip, questID);
    end

    local wouldShowWaypointText = questID == C_SuperTrack.GetSuperTrackedQuestID() or
        questID == QuestMapFrame_GetFocusedQuestID();
    local waypointText = wouldShowWaypointText and C_QuestLog.GetNextWaypointText(questID);
    if waypointText then
        -- TODO: Translate waypointText
        --GameTooltip_AddColoredLine(GameTooltip, QUEST_DASH .. waypointText, HIGHLIGHT_FONT_COLOR);
    elseif button.style == POIButtonUtil.Style.Numeric then
        local numItemDropTooltips = GetNumQuestItemDrops(questLogIndex);
        if numItemDropTooltips > 0 then
            for i = 1, numItemDropTooltips do
                local text, _, finished = GetQuestLogItemDrop(i, questLogIndex);
                if (text and not finished) then
                    local lineLeft = _G["GameTooltipTextLeft" .. objectiveOffset + i]
                    if (lineLeft) then
                        local translatedObjective = GetQuestObjective(questID, text)
                        if (translatedObjective) then
                            lineLeft:SetText(QUEST_DASH .. translatedObjective)
                        end
                    end
                end
            end
        else
            local numObjectives = GetNumQuestLeaderBoards(questLogIndex);
            for i = 1, numObjectives do
                local text, _, finished = GetQuestLogLeaderBoard(i, questLogIndex);
                if (text and not finished) then
                    local lineLeft = _G["GameTooltipTextLeft" .. objectiveOffset + i]
                    if (lineLeft) then
                        local translatedObjective = GetQuestObjective(questID, text)
                        if (translatedObjective) then
                            lineLeft:SetText(QUEST_DASH .. translatedObjective)
                        end
                    end
                end
            end
        end
    end
    GameTooltip:Show();
end

local function OnMinimapMouseoverTooltipPostCall(tooltip, tooltipData)
    if (tooltipData) then
        local text = tooltip.TextLeft1:GetText()
        if (not text) then return end

        local title = text:gsub("(.*)|cffffffff(.*)", function(t, _) return t end)

        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local questID = C_QuestLog.GetQuestIDForLogIndex(i);
            if questID and questID > 0 then
                if (C_QuestLog.GetTitleForQuestID(questID) == title) then
                    local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID);

                    local translatedTitle, objectives = GetTranslatedTooltip(nil, questID, questLogIndex)
                    local textLeft1 = translatedTitle .. HIGHLIGHT_FONT_COLOR_CODE
                    for i = 1, #objectives, 1 do
                        textLeft1 = textLeft1 .. "\n" .. objectives[i]
                    end
                    textLeft1 = textLeft1 .. "|r"

                    _G["GameTooltipTextLeft1"]:SetText(textLeft1)
                    GameTooltip:Show()
                    break
                end
            end
        end
    end
end

local function OnToggleDropDownMenu(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button,
                                    autoHideDelay,
                                    overrideDisplayMode)
    if (dropDownFrame == QuestMapQuestOptionsDropDown) then
        local listFrameName = "DropDownList" .. level;
        local listFrame = _G[listFrameName];
        for i = 1, listFrame.numButtons do
            local button = _G[listFrameName .. "Button" .. i];
            translateUIFontString(button)
        end
    elseif (dropDownFrame == ObjectiveTrackerBlockDropDown) then
        local questID = dropDownFrame.activeFrame.id
        local title = C_QuestLog.GetTitleForQuestID(questID);
        local translatedTitle = GetQuestTitle(questID);
        local listFrameName = "DropDownList" .. level;
        _G[listFrameName .. "Button1"]:SetText(translatedTitle or title)
        local listFrame = _G[listFrameName];
        for i = 2, listFrame.numButtons do
            local button = _G[listFrameName .. "Button" .. i];
            translateUIFontString(button)
        end
    end
end

local function OnStorylineQuestPinMouseEnter(frame)
    local questLineInfo = C_QuestLine.GetQuestLineInfo(frame.questID, frame.mapID);
    if (questLineInfo) then
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT");
        GameTooltip:SetText(questLineInfo.questName);
        local translatedTitle = GetQuestTitle(tonumber(frame.questID))
        if (translatedTitle) then
            GameTooltip:SetText(translatedTitle)
        end
        GameTooltip:AddLine(getQuestFrameTranslationOrDefault(AVAILABLE_QUEST), 1, 1, 1, true);
        if (questLineInfo.floorLocation == Enum.QuestLineFloorLocation.Below) then
            GameTooltip:AddLine(getQuestFrameTranslationOrDefault(QUESTLINE_LOCATED_BELOW), 0.5, 0.5, 0.5, true);
        elseif (questLineInfo.floorLocation == Enum.QuestLineFloorLocation.Above) then
            GameTooltip:AddLine(getQuestFrameTranslationOrDefault(QUESTLINE_LOCATED_ABOVE), 0.5, 0.5, 0.5, true);
        end
        GameTooltip:Show();
    end
end

function translator:initialize()
    InitializeCommandButtons()

    -- Gossip Frame
    translateButton(GossipFrame.GreetingPanel.GoodbyeButton)
    -- Quest Frame
    translateButton(QuestFrameAcceptButton)
    translateButton(QuestFrameDeclineButton)
    translateButton(QuestFrameCompleteQuestButton)
    translateButton(QuestFrameCompleteButton)
    translateButton(QuestFrameGoodbyeButton)
    translateUIFontString(QuestInfoRewardsFrame.Header)
    translateUIFontString(QuestInfoRewardsFrame.XPFrame.ReceiveText)
    translateUIFontString(QuestInfoObjectivesHeader)
    translateUIFontString(QuestInfoDescriptionHeader)
    translateUIFontString(QuestProgressRequiredItemsText)
    -- Objectives Frame
    translateUIFontString(ObjectiveTrackerFrame.HeaderMenu.Title)
    translateUIFontString(ObjectiveTrackerBlocksFrame.AchievementHeader.Text)
    translateUIFontString(ObjectiveTrackerBlocksFrame.AdventureHeader.Text)
    translateUIFontString(ObjectiveTrackerBlocksFrame.CampaignQuestHeader.Text)
    translateUIFontString(ObjectiveTrackerBlocksFrame.MonthlyActivitiesHeader.Text)
    translateUIFontString(ObjectiveTrackerBlocksFrame.ProfessionHeader.Text)
    translateUIFontString(ObjectiveTrackerBlocksFrame.ScenarioHeader.Text)
    -- Quest popup
    translateUIFontString(QuestLogPopupDetailFrame.ShowMapButton.Text)
    translateButton(QuestLogPopupDetailFrame.AbandonButton)
    translateButton(QuestLogPopupDetailFrame.ShareButton)
    -- Quest map
    translateUIFontString(MapQuestInfoRewardsFrame.TitleFrame.Name)
    for _, region in ipairs({ QuestMapFrame.DetailsFrame.RewardsFrame:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            translateUIFontString(region)
        end
    end
    translateButton(QuestMapFrame.DetailsFrame.AbandonButton, 90, 22)
    translateButton(QuestMapFrame.DetailsFrame.ShareButton, 90, 22)
    translateButton(QuestMapFrame.DetailsFrame.BackButton, nil, 24)
    translateUIFontString(QuestScrollFrame.CampaignTooltip.CompleteRewardText)

    eventHandler:Register(OnGossipShow, "GOSSIP_SHOW", "GOSSIP_CLOSED")
    eventHandler:Register(OnObjectiveTrackerQuestHeaderUpdated, "QUEST_SESSION_JOINED", "QUEST_SESSION_LEFT")

    hooksecurefunc("ToggleDropDownMenu", OnToggleDropDownMenu)

    hooksecurefunc("QuestInfo_Display", DisplayQuestInfo)
    hooksecurefunc("QuestFrame_ShowQuestPortrait", ShowQuestPortrait)
    hooksecurefunc("QuestMapFrame_UpdateQuestDetailsButtons", UpdateQuestDetailsButtons)
    hooksecurefunc("QuestLogQuests_Update", OnQuestLogQuestsUpdate)
    hooksecurefunc("QuestMapLogTitleButton_OnEnter", OnQuestMapLogTitleButtonTooltipShow)
    hooksecurefunc("QuestMapLog_GetCampaignTooltip", GetCampaignTooltipFromQuestMapLog)

    QuestFrameProgressPanel:HookScript("OnShow", OnQuestFrameProgressPanelShow)
    hooksecurefunc("QuestFrameProgressPanel_OnShow", OnQuestFrameProgressPanelShow)

    ObjectiveTrackerBlocksFrame.QuestHeader:HookScript("OnShow", OnObjectiveTrackerQuestHeaderUpdated)
    hooksecurefunc(QUEST_TRACKER_MODULE, "Update", UpdateTrackerModule)
    hooksecurefunc(CAMPAIGN_QUEST_TRACKER_MODULE, "Update", UpdateTrackerModule)

    hooksecurefunc("StaticPopup_Show", OnStaticPopupShow)

    -- Update yellow text when quest completed or objectives changed
    hooksecurefunc(UIErrorsFrame, "AddMessage", OnUIErrorsFrameMessageAdded)
    UIErrorsFrame:HookScript("OnUpdate", OnUIErrorsFrameUpdated)
    hooksecurefunc(UIErrorsFrame, "SetScript", function(_, _, value)
        if (not value) then UIErrorsFrame:HookScript("OnUpdate", OnUIErrorsFrameUpdated) end
    end)

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.MinimapMouseover, OnMinimapMouseoverTooltipPostCall)

    WorldMapFrame:HookScript("OnShow", function()
        if (WorldMapFrame.pinPools.StorylineQuestPinTemplate and WorldMapFrame.pinPools.StorylineQuestPinTemplate.activeObjects) then
            for pin, _ in pairs(WorldMapFrame.pinPools.StorylineQuestPinTemplate.activeObjects) do
                if (not WorldMapStorylineQuestPinsCache[pin]) then
                    pin:HookScript("OnEnter", function() OnStorylineQuestPinMouseEnter(pin) end)
                    WorldMapStorylineQuestPinsCache[pin] = true
                end
            end
        end

        for _, frame in pairs({ WorldMapFrame.ScrollContainer.Child:GetChildren() }) do
            if (frame) then
                local frameType = frame:GetObjectType()
                if (frameType == "Button" and frame.questID) then
                    if (not WorldMapChildFramesCache[frame]) then
                        frame:HookScript("OnEnter", OnWorldMapPinButtonTooltipUpdated)
                        hooksecurefunc(frame, "UpdateTooltip", OnWorldMapPinButtonTooltipUpdated)
                        WorldMapChildFramesCache[frame] = true
                    end
                elseif (frameType == "QuestPOIFrame") then
                    if (not WorldMapChildFramesCache[frame]) then
                        hooksecurefunc(frame, "UpdateTooltip", OnWorldMapQuestPOIFrameTooltipUpdated)
                        WorldMapChildFramesCache[frame] = true
                    end
                end
            end
        end
    end)
end
