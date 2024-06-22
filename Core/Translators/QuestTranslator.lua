--- @type string, WowUkrainizerInternals
local _, ns = ...;

local _G = _G

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

local TryCallAPIFn = ns.CommonUtil.TryCallAPIFn
local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName
local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedGossipText = ns.DbContext.Gossips.GetTranslatedGossipText
local GetTranslatedGossipOptionText = ns.DbContext.Gossips.GetTranslatedGossipOptionText
local GetTranslatedQuestTitle = ns.DbContext.Quests.GetTranslatedQuestTitle
local GetTranslatedQuestData = ns.DbContext.Quests.GetTranslatedQuestData
local GetTranslatedQuestObjective = ns.DbContext.Quests.GetTranslatedQuestObjective

local FACTION_ALLIANCE = ns.FACTION_ALLIANCE
local FACTION_HORDE = ns.FACTION_HORDE

local IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION = ns.IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION
local ABANDON_QUEST_CONFIRM_UA = ns.ABANDON_QUEST_CONFIRM_UA
local YES_UA = ns.YES_UA
local NO_UA = ns.NO_UA

local ACTIVE_TEMPLATE;
local ACTIVE_PARENT_FRAME;

local questFrameSwitchTranslationButton
local questFrameMTIcon
local questPopupFrameSwitchTranslationButton
local questPopupFrameMTIcon
local questMapDetailsFrameSwitchTranslationButton
local questMapDetailsFrameMTIcon
local immersionFrameSwitchTranslationButton
local immersionFrameMTIcon
local immersionWowheadButton

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

local MinimapTooltipCache = {}
local WorldMapStorylineQuestPinsCache = {}
local WorldMapChildFramesCache = {}

---@class QuestTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

local function copyTable(originalTable)
    local newTable = {}
    for key, value in pairs(originalTable) do
        if type(value) == "table" then
            newTable[key] = copyTable(value)
        else
            newTable[key] = value
        end
    end
    return newTable
end

local function getQuestTitle(questID, isTrivial)
    local translatedTitle = GetTranslatedQuestTitle(questID)
    if (not translatedTitle) then return end

    if (isTrivial) then
        translatedTitle = translatedTitle .. IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION
    end

    return translatedTitle
end

local function getQuestFrameTranslationOrDefault(default)
    return ns.DbContext.Frames.GetTranslatedUIText("Quest", default)
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

local function showCommandButtonsForQuest(needToShow, isMTData)
    if (needToShow) then
        questFrameSwitchTranslationButton:Show()
        questPopupFrameSwitchTranslationButton:Show()
        questMapDetailsFrameSwitchTranslationButton:Show()
        if (immersionFrameSwitchTranslationButton) then
            immersionFrameSwitchTranslationButton:Show()
        end
        if (isMTData) then
            questFrameMTIcon:Show()
            questPopupFrameMTIcon:Show()
            questMapDetailsFrameMTIcon:Show()
            if (immersionFrameMTIcon) then
                immersionFrameMTIcon:Show()
            end
        else
            questFrameMTIcon:Hide()
            questPopupFrameMTIcon:Hide()
            questMapDetailsFrameMTIcon:Hide()
            if (immersionFrameMTIcon) then
                immersionFrameMTIcon:Hide()
            end
        end
    else
        questFrameSwitchTranslationButton:Hide()
        questFrameMTIcon:Hide()
        questPopupFrameSwitchTranslationButton:Hide()
        questPopupFrameMTIcon:Hide()
        questMapDetailsFrameSwitchTranslationButton:Hide()
        questMapDetailsFrameMTIcon:Hide()

        if (immersionFrameSwitchTranslationButton) then
            immersionFrameSwitchTranslationButton:Hide()
        end
        if (immersionFrameMTIcon) then
            immersionFrameMTIcon:Hide()
        end
    end
end

_G["StaticPopupDialogs"]["WowUkrainizer_WowheadLink"] = {
    text = "Натисніть Ctrl+C, щоб скопіювати URL-адресу в буфер обміну",
    hasEditBox = 1,
    button1 = "Гаразд",
    OnShow = function(self)
        local questID = self.data.getQuestID()
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
                elseif (not questData.ContainsObjectives and questData.ObjectivesText) then
                    translatedText = questData.ObjectivesText
                end
            end
        end
    end

    if (not translatedText) then
        translatedText = GetTranslatedQuestObjective(questData.ID, text)
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

local function OnQuestFrameGreetingPanelShow(_)
    local function _translateQuestButton(button, questID, isTrivial)
        local translatedText = getQuestTitle(questID, isTrivial)
        if (not translatedText) then return end

        button:SetText(translatedText)
        button:SetHeight(math.max(button:GetTextHeight() + 2, button.Icon:GetHeight()));
    end

    local translatedTitle = GetTranslatedGossipText(GreetingText:GetText())
    if (translatedTitle) then
        GreetingText:SetText(translatedTitle)
    end

    local activeQuestIndex = 1
    local availableQuestIndex = 1
    for button in QuestFrameGreetingPanel.titleButtonPool:EnumerateActive() do
        if (button.isActive == 1) then
            local questID = GetActiveQuestID(activeQuestIndex)
            local isTrivial = IsActiveQuestTrivial(activeQuestIndex)
            _translateQuestButton(button, questID, isTrivial)
            activeQuestIndex = activeQuestIndex + 1
        else
            local isTrivial, _, _, _, questID = GetAvailableQuestInfo(availableQuestIndex);
            _translateQuestButton(button, questID, isTrivial)
            availableQuestIndex = availableQuestIndex + 1
        end
    end
end

local function OnGossipShow()
    local title = GossipFrameTitleText:GetText();
    GossipFrameTitleText:SetText(GetTranslatedUnitName(title));

    local optionHeightOffset = 0
    for _, childFrame in GossipFrame.GreetingPanel.ScrollBox:EnumerateFrames() do
        local data = childFrame:GetElementData()
        local buttonType = data.buttonType
        if (buttonType == GOSSIP_BUTTON_TYPE_TITLE) then
            local currentHeight = childFrame.GreetingText:GetHeight()
            childFrame.GreetingText:SetText(GetTranslatedGossipText(childFrame.GreetingText:GetText()))
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
                childFrame:SetText(GetTranslatedGossipOptionText(childFrame:GetText()))
                childFrame:Resize();
            else
                local translatedTitle = getQuestTitle(tonumber(data.info.questID), data.info.isTrivial)
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
    local questData = GetTranslatedQuestData(questID)
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
        if (not completionText) then
            completionText = getQuestFrameTranslationOrDefault(QUEST_WATCH_QUEST_READY)
        elseif (completionText and questData.CompletionText) then
            completionText = questData.CompletionText
        elseif (not questData.ContainsObjectives and questData.ObjectivesText) then
            completionText = questData.ObjectivesText
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
                local translatedText = GetTranslatedQuestObjective(questID, text)
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

        local translatedTitle = GetTranslatedQuestTitle(questID)
        if (translatedTitle) then
            titleFrame.Text:SetText(translatedTitle)
        end
        updatedHeight[questID] = updatedHeight[questID] + titleFrame.Text:GetHeight() + 2
    end

    for objectiveFramePool in QuestScrollFrame.objectiveFramePool:EnumerateActive() do
        local questID = objectiveFramePool.questID
        if (not updatedHeight[questID]) then updatedHeight[questID] = 0 end
        local objectiveHeight = TranslteQuestObjective(objectiveFramePool.Text, GetTranslatedQuestData(questID), false)
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

        questID = tonumber(questID)
        local blockHeight = 0;
        local questData = questID and GetTranslatedQuestData(questID)
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

    local questData = GetTranslatedQuestData(questID)
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
    QuestFrameTitleText:SetText(GetTranslatedUnitName(title));

    local questID = getQuestID()
    if (not questID or questID == 0) then return end

    local questData = GetTranslatedQuestData(questID)

    showCommandButtonsForQuest(questData ~= nil, questData and questData.IsMtData)

    local elementsTable = template.elements;
    for i = 1, #elementsTable, 3 do
        local shownFrame, _ = elementsTable[i](parentFrame);
        local translateQuestText = ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_TEXT_OPTION)
        if (shownFrame) then
            local _, name = TryCallAPIFn("GetName", shownFrame)
            if (name == "QuestInfoTitleHeader") then
                if (translateQuestText) then
                    if (questData and questData.Title) then
                        QuestInfoTitleHeader:SetText(questData.Title)
                    end
                end
            elseif (name == "QuestInfoObjectivesText") then
                if (translateQuestText) then
                    if (questData and questData.ObjectivesText) then
                        QuestInfoObjectivesText:SetText(questData.ObjectivesText)
                    end
                end
            elseif (name == "QuestInfoObjectivesFrame") then
                if (translateQuestText) then
                    TranslteQuestObjectives(QuestInfoObjectivesFrame.Objectives, questData, true)
                end
            elseif (name == "QuestInfoDescriptionHeader") then
                -- ignore
            elseif (name == "QuestInfoDescriptionText") then
                if (translateQuestText) then
                    if (questData and questData.Description) then
                        QuestInfoDescriptionText:SetText(questData.Description)
                    end
                end
            elseif (name == "QuestInfoSpacerFrame") then
                -- ignore
            elseif (name == "QuestInfoRewardsFrame") then
                if (translateQuestText) then
                    if (questData and questData.RewardText) then
                        QuestInfoRewardText:SetText(questData.RewardText)
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
    QuestFrameTitleText:SetText(GetTranslatedUnitName(title));

    local questID = getQuestID()
    if (not questID or questID == 0) then return end

    local questData = GetTranslatedQuestData(questID)

    showCommandButtonsForQuest(questData ~= nil, questData and questData.IsMtData)

    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_TEXT_OPTION)) then
        if (questData and questData.Title) then
            QuestProgressTitleText:SetText(questData.Title)
        end

        if (questData and questData.ProgressText) then
            QuestProgressText:SetText(questData.ProgressText)
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

        frame.text:SetFormattedText(ABANDON_QUEST_CONFIRM_UA, GetTranslatedQuestTitle(questId) or text_arg1, text_arg2)
        frame.button1.Text:SetText(YES_UA)
        frame.button2.Text:SetText(NO_UA)

        StaticPopup_Resize(frame, which);
    end
end

local immersionTitleOriginal, immersionTextOriginal, immersionObjectivesTextOriginal

local function ImmersionUpdateTalkingHeadHook(immersionFrame, title, text)
    local function updateTalkBoxText(translatedTitle, translatedText)
        if (translatedTitle and translatedTitle ~= "") then
            immersionFrame.TalkBox.NameFrame.Name:SetText(translatedTitle)
        end
        if (translatedText and translatedText ~= "") then
            immersionFrame.TalkBox.TextFrame.Text:SetText(translatedText)
        end
    end

    local questID = GetQuestID()

    if (questID == 0) then
        immersionWowheadButton:Hide()
    else
        immersionWowheadButton:Show()
    end

    if (not ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_TEXT_OPTION)) then
        updateTalkBoxText(title, text)
        return
    end

    local playbackEvent = immersionFrame.playbackEvent
    if (playbackEvent == "QUEST_GREETING") then
        -- TODO: Check when gossip translations is ready
        updateTalkBoxText(GetTranslatedUnitName(title), GetTranslatedGossipText(text))
    else
        local questData = GetTranslatedQuestData(questID)

        showCommandButtonsForQuest(questData ~= nil, questData and questData.IsMtData)

        if (questData) then
            if (playbackEvent == "QUEST_PROGRESS") then
                updateTalkBoxText(questData.Title, questData.ProgressText)
            elseif (playbackEvent == "QUEST_COMPLETE") then
                updateTalkBoxText(questData.Title, questData.RewardText)
            elseif (playbackEvent == "QUEST_DETAIL") then
                updateTalkBoxText(questData.Title, questData.Description)
            end
        end
    end
end

local function ImmersionTalkBoxElementsDisplayHook(elements)
    local SEAL_QUESTS = {
        [40519] = '|cff04aaffКороль|nВаріан Рінн|r',
        [43926] = '|cff480404Воєначальник|nВол\'джин|r',
        [46730] = '|cff2f0a48Хадґар|r',
    }

    local SuggestedPlayers = 'Рекомендована кількість гравців: [%d]'

    local questID = GetQuestID()

    do -- ShowObjectivesText
        local objectivesText = immersionObjectivesTextOriginal
        if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_TEXT_OPTION)) then
            local questData = GetTranslatedQuestData(questID)
            if (questData and questData.ObjectivesText) then
                objectivesText = questData.ObjectivesText
            end
        end

        elements.Content.ObjectivesText:SetText(objectivesText)
    end

    do -- ShowGroupSize
        if (elements.Content.GroupSize:IsVisible()) then
            local groupNum = ImmersionAPI:GetSuggestedGroupNum()
            if (groupNum > 0) then
                elements.Content.GroupSize:SetText(SuggestedPlayers:format(groupNum))
            end
        end
    end

    do -- ShowSpecialObjectives
        local spellID, spellName, _ = GetCriteriaSpell()
        if (spellID and spellName) then
            translateUIFontString(elements.Content.SpecialObjectivesFrame.SpellObjectiveLearnLabel)
            elements.Content.SpecialObjectivesFrame.SpellObjectiveFrame:SetText(GetTranslatedSpellName(spellName, false))
        end
    end

    do -- ShowSeal
        if (elements.Content.SealFrame:IsVisible()) then
            local sealInfo = SEAL_QUESTS[questID]
            if (sealInfo) then
                elements.Content.SealFrame.Text:SetText(sealInfo)
            end
        end
    end

    do --ShowRewards
        translateUIFontString(elements.Content.RewardsFrame.ItemChooseText)
        translateUIFontString(elements.Content.RewardsFrame.ItemReceiveText)
        translateUIFontString(elements.Content.RewardsFrame.HonorFrame.Name)

        for fontString in elements.Content.RewardsFrame.spellHeaderPool:EnumerateActive() do
            if (fontString:GetText() ~= nil) then
                translateUIFontString(fontString);
            end
        end
        for fontString in elements.Content.RewardsFrame.spellRewardPool:EnumerateActive() do
            local spellRewardName = fontString:GetText()
            if (fontString:GetText() ~= nil) then
                fontString:SetText(GetTranslatedSpellName(spellRewardName, false));
            end
        end
        -- TODO: Add Translation for followerRewardPool when followers module ready
    end

    do -- TODO: Uncomment when GetTranslatedPlayerTitle ready
        -- local playerTitle = ImmersionAPI:GetRewardTitle()
        -- if (playerTitle) then
        --     elements.Content.RewardsFrame.TitleFrame.Name:SetText(GetTranslatedPlayerTitle(playerTitle))
        -- end
    end
end

local function InitializeCommandButtons()
    local function CreateMtIconTexture(parentFrame, offsetX, offsetY)
        local icon = parentFrame:CreateTexture(nil, "OVERLAY");
        icon:ClearAllPoints();
        icon:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", offsetX, offsetY);
        icon:SetWidth(24);
        icon:SetHeight(24);
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

    local function CreateSwitchTranslationButton(parentFrame, onClickFunc, offsetX, offsetY)
        local button = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate");
        button:SetSize(90, 24);
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

    local function CreateWowheadButton(parentFrame, offsetX, offsetY, data)
        local button = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate");
        button:SetSize(24, 24);
        button:ClearAllPoints();
        button:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", offsetX, offsetY);
        button:SetNormalAtlas("UI-HUD-MicroMenu-Shop-Up");
        button:SetPushedAtlas("UI-HUD-MicroMenu-Shop-Down");
        button:SetScript("OnMouseDown",
            function(_) _G["StaticPopup_Show"]("WowUkrainizer_WowheadLink", nil, nil, data) end)
        button:Show();
        return button
    end

    questFrameSwitchTranslationButton = CreateSwitchTranslationButton(QuestFrame, function()
        if (QuestFrameProgressPanel:IsShown()) then
            QuestFrameProgressPanel_OnShow(QuestFrameProgressPanel)
        else
            QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
                QuestInfoFrame.mapView)
        end
    end, -64, -30)
    questFrameMTIcon = CreateMtIconTexture(QuestFrame, -34, -30)
    CreateWowheadButton(QuestFrame, -6, -30, { getQuestID = function() return GetQuestID() end })

    questPopupFrameSwitchTranslationButton = CreateSwitchTranslationButton(QuestLogPopupDetailFrame, function()
        QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
            QuestInfoFrame.mapView)
    end, -188, -28)
    questPopupFrameMTIcon = CreateMtIconTexture(QuestLogPopupDetailFrame, -162, -28)
    CreateWowheadButton(QuestLogPopupDetailFrame, -2, -28,
        { getQuestID = function() return C_QuestLog.GetSelectedQuest() end })

    questMapDetailsFrameSwitchTranslationButton = CreateSwitchTranslationButton(QuestMapDetailsScrollFrame, function()
        QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
            QuestInfoFrame.mapView)
    end, -44, 30)
    questMapDetailsFrameMTIcon = CreateMtIconTexture(QuestMapDetailsScrollFrame, -16, 30)
    CreateWowheadButton(QuestMapDetailsScrollFrame, 12, 30,
        { getQuestID = function() return C_QuestLog.GetSelectedQuest() end })

    if (ImmersionFrame) then
        local immersionModelFrame = ImmersionFrame.TalkBox.MainFrame.Model

        local yOffset = immersionModelFrame:GetHeight() * -1 + 20
        immersionWowheadButton = CreateWowheadButton(immersionModelFrame, 30, yOffset,
            { getQuestID = function() return GetQuestID() end })
        immersionFrameSwitchTranslationButton = CreateSwitchTranslationButton(immersionWowheadButton, function()
            ImmersionUpdateTalkingHeadHook(ImmersionFrame, immersionTitleOriginal, immersionTextOriginal)
            ImmersionTalkBoxElementsDisplayHook(ImmersionFrame.TalkBox.Elements)
            ImmersionFrame.TalkBox.TextFrame.Text:RepeatTexts();
        end, 92, 0)
        immersionFrameMTIcon = CreateMtIconTexture(immersionFrameSwitchTranslationButton, 24, 0)
    end
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
                local objective = GetTranslatedQuestObjective(questID, text)
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
                local objective = GetTranslatedQuestObjective(questID, text)
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
                local objective = GetTranslatedQuestObjective(questID, text)
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
            local translatedObjective = GetTranslatedQuestObjective(questID, text)
            table.insert(translatedObjectives, QUEST_DASH .. translatedObjective or text)
        end
    end

    local translatedTitle = GetTranslatedQuestTitle(questID)
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
    local translatedTitle = GetTranslatedQuestTitle(questID)
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
                        local translatedObjective = GetTranslatedQuestObjective(questID, text)
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
                        local translatedObjective = GetTranslatedQuestObjective(questID, text)
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
    local function processMinimapTooltip(tooltipLine)
        local result = {}
        local objectives = {}
        local substrings = {}

        for substring in tooltipLine:gmatch("[^\n]+") do
            table.insert(substrings, substring)
        end

        for i = #substrings, 1, -1 do
            local substring = substrings[i]
            if (string.sub(substring, 1, 1) == '-') then
                substring = string.sub(substring, 3)
                if string.sub(substring, -2) == '|r' then
                    substring = string.sub(substring, 1, -3)
                end
                table.insert(objectives, substring)
            elseif (#objectives > 0) then
                local color = nil
                local title = string.gsub(substring,
                    "(.-)%|[cC]([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])",
                    function(t, c)
                        color = c
                        return t
                    end)
                table.insert(result,
                    { type = 'QUEST', title = title, objectives = copyTable(objectives), obejctiveColor = color })
                objectives = {}
            else
                local title = substring
                local icon = nil
                local color = nil
                title = string.gsub(title, "(%|T.-%|t)", function(i)
                    icon = i
                    return ''
                end)
                title = string.gsub(title,
                    "%|[cC]([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])(.-)%|[rR]",
                    function(c, t)
                        color = c
                        return t
                    end)
                table.insert(result, { type = 'NPC_OR_OBJECT', title = title, icon = icon, color = color })
            end
        end
        return result
    end

    if (tooltipData) then
        if (#tooltipData.lines > 0) then
            local text = tooltip.TextLeft1:GetText()
            if (not text) then return end

            local hash = ns.StringUtil.GetHash(text)
            if (not MinimapTooltipCache[hash]) then
                local tooltipRows = processMinimapTooltip(text)

                local questTitleToQuestIdCache = nil
                if (tooltipRows) then
                    for i = 1, #tooltipRows, 1 do
                        local data = tooltipRows[i]
                        if (data.type == 'QUEST') then
                            if (not questTitleToQuestIdCache) then
                                questTitleToQuestIdCache = {}
                                for j = 1, C_QuestLog.GetNumQuestLogEntries() do
                                    local questID = C_QuestLog.GetQuestIDForLogIndex(j);
                                    if (questID and questID > 0) then
                                        local questTitle = C_QuestLog.GetTitleForQuestID(questID)
                                        if (questTitle) then questTitleToQuestIdCache[questTitle] = questID end
                                    end
                                end
                            end
                            local questID = questTitleToQuestIdCache[data.title]
                            if (questID) then
                                local translatedTitle = GetTranslatedQuestTitle(questID)
                                if (translatedTitle) then
                                    data.title = translatedTitle
                                end

                                for j = #data.objectives, 1, -1 do
                                    local objective = data.objectives[j]
                                    local translatedObjective = GetTranslatedQuestObjective(questID, objective)
                                    if (translatedObjective) then
                                        data.objectives[j] = translatedObjective
                                    end
                                end
                            end
                        elseif (data.type == 'NPC_OR_OBJECT') then
                            local translatedTitle = GetTranslatedUnitName(data.title)
                            if (translatedTitle == data.title) then
                                -- TODO: Object Name
                            end
                            data.title = translatedTitle
                        end
                    end

                    local translatedTooltip = ''
                    for i = #tooltipRows, 1, -1 do
                        local data = tooltipRows[i]
                        if (data.icon) then
                            translatedTooltip = translatedTooltip .. data.icon
                        end
                        if (data.color) then
                            translatedTooltip = translatedTooltip .. "|c" .. data.color .. data.title .. "|r"
                        else
                            translatedTooltip = translatedTooltip .. data.title
                        end
                        if (data.objectives) then
                            if (data.obejctiveColor) then
                                translatedTooltip = translatedTooltip .. "|c" .. data.obejctiveColor
                            end
                            for j = #data.objectives, 1, -1 do
                                local objective = data.objectives[j]
                                translatedTooltip = translatedTooltip .. "\n- " .. objective
                            end
                            translatedTooltip = translatedTooltip .. "|r"
                        end
                        translatedTooltip = translatedTooltip .. "\n"
                    end

                    MinimapTooltipCache[hash] = translatedTooltip
                end
            end

            _G["GameTooltipTextLeft1"]:SetText(MinimapTooltipCache[hash])
            GameTooltip:Show()
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
        local listFrameName = "DropDownList" .. level;
        local buttonIndex = 1
        local questID = dropDownFrame.activeFrame.id
        local title = C_QuestLog.GetTitleForQuestID(questID);
        if (title) then
            local translatedTitle = GetTranslatedQuestTitle(questID);
            if (translatedTitle) then
                _G[listFrameName .. "Button" .. buttonIndex]:SetText(translatedTitle)
            end
            buttonIndex = buttonIndex + 1
        end

        local listFrame = _G[listFrameName];
        for i = buttonIndex, listFrame.numButtons do
            translateUIFontString(_G[listFrameName .. "Button" .. i])
        end
    end
end

local function OnStorylineQuestPinMouseEnter(frame)
    local questID = tonumber(frame.questID)
    local questLineInfo = questID and C_QuestLine.GetQuestLineInfo(questID, frame.mapID);
    if (questLineInfo) then
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT");
        GameTooltip:SetText(questLineInfo.questName);

        local translatedTitle = questID and GetTranslatedQuestTitle(questID)
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

-- Immersion
local function InitializeImmersion()
    hooksecurefunc(ImmersionFrame, "UpdateTalkingHead", function(immersionFrame, title, text)
        immersionTitleOriginal = title
        immersionTextOriginal = text
        ImmersionUpdateTalkingHeadHook(immersionFrame, title, text)
    end)

    hooksecurefunc(ImmersionFrame.TalkBox.Elements, "Display", function(elements)
        immersionObjectivesTextOriginal = elements.Content.ObjectivesText:GetText()
        ImmersionTalkBoxElementsDisplayHook(elements)
    end)

    hooksecurefunc(ImmersionFrame.TitleButtons, "UpdateAvailableQuests", function(titleButtons, availableQuests)
        for i, quest in ipairs(availableQuests) do
            local button = titleButtons:GetButton(i)
            local questTitle = getQuestTitle(quest.questID, quest.isTrivial)
            if (questTitle) then
                button:SetText(questTitle)
            end
        end
    end)

    hooksecurefunc(ImmersionFrame.TitleButtons, "UpdateActiveQuests", function(titleButtons, activeQuests)
        local numGossipAvailableQuests = #ImmersionAPI:GetGossipAvailableQuests()
        for i, quest in ipairs(activeQuests) do
            local button = titleButtons:GetButton(i + numGossipAvailableQuests)
            local questTitle = getQuestTitle(quest.questID, quest.isTrivial)
            if (questTitle) then
                button:SetText(questTitle)
            end
        end
    end)

    hooksecurefunc(ImmersionFrame.TitleButtons, "UpdateGossipOptions", function(titleButtons, gossipOptions)
        local numGossipAvailableQuests = #ImmersionAPI:GetGossipAvailableQuests()
        local numGossipActiveQuests = #ImmersionAPI:GetGossipActiveQuests()

        for i, option in ipairs(gossipOptions) do
            local button = titleButtons:GetButton(i + numGossipAvailableQuests + numGossipActiveQuests)
            button:SetText(GetTranslatedGossipOptionText(option.name))
        end
    end)

    hooksecurefunc(ImmersionFrame.TitleButtons, "UpdateActiveGreetingQuests", function(titleButtons, numActiveQuests)
        for i = 1, numActiveQuests do
            local button = titleButtons:GetButton(i)
            local questTitle = getQuestTitle(GetActiveQuestID(i), IsActiveQuestTrivial(i))
            if (questTitle) then
                button:SetText(questTitle)
            end
        end
    end)

    hooksecurefunc(ImmersionFrame.TitleButtons, "UpdateAvailableGreetingQuests",
        function(titleButtons, numAvailableQuests)
            local numActiveQuests = ImmersionAPI:GetNumActiveQuests()
            for i = 1, numAvailableQuests do
                local isTrivial, _, _, _, questID = ImmersionAPI:GetAvailableQuestInfo(i)
                local button = titleButtons:GetButton(i + numActiveQuests)
                local questTitle = getQuestTitle(questID, isTrivial)
                if (questTitle) then
                    button:SetText(questTitle)
                end
            end
        end)

    -- Consts
    translateUIFontString(ImmersionContentFrame.ObjectivesHeader)
    translateUIFontString(ImmersionContentFrame.RewardsFrame.Header)
    translateUIFontString(ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText)
    translateUIFontString(ImmersionFrame.TalkBox.Elements.Progress.MoneyText)
    translateUIFontString(ImmersionFrame.TalkBox.Elements.Progress.ReqText)
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION)
end

function translator:Init()
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
    translateUIFontString(CurrentQuestsText)
    translateUIFontString(AvailableQuestsText)
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

    QuestFrameGreetingPanel:HookScript("OnShow", OnQuestFrameGreetingPanelShow)

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

    if (ImmersionFrame ~= nil) then
        InitializeImmersion()
    end
end

ns.TranslationsManager:AddTranslator(translator)
