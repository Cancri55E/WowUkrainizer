--- @type string, WowUkrainizerInternals
local _, ns = ...;

local _G = _G

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName
local GetTranslatedGossipText = ns.DbContext.Gossips.GetTranslatedGossipText
local GetTranslatedGossipOptionText = ns.DbContext.Gossips.GetTranslatedGossipOptionText
local GetTranslatedQuestTitle = ns.DbContext.Quests.GetTranslatedQuestTitle
local GetTranslatedQuestData = ns.DbContext.Quests.GetTranslatedQuestData
local GetTranslatedQuestObjective = ns.DbContext.Quests.GetTranslatedQuestObjective
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

local CreateSwitchTranslationButton = ns.QuestFrameUtil.CreateSwitchTranslationButton
local CreateWowheadButton = ns.QuestFrameUtil.CreateWowheadButton

local FACTION_ALLIANCE = ns.FACTION_ALLIANCE
local FACTION_HORDE = ns.FACTION_HORDE

local IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION = ns.IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION
local ABANDON_QUEST_CONFIRM_UA = ns.ABANDON_QUEST_CONFIRM_UA
local YES_UA = ns.YES_UA
local NO_UA = ns.NO_UA

local ACTIVE_TEMPLATE;
local ACTIVE_PARENT_FRAME;

local questFrameSwitchTranslationButton
local questPopupFrameSwitchTranslationButton
local questMapDetailsFrameSwitchTranslationButton

local WorldMapStorylineQuestPinsCache = {}
local WorldMapChildFramesCache = {}

local translatedWithAILinkType = "TranslatedWithAI"

---@class QuestTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

local OnUpdateGameTooltip = function(expectedOwner)
    ns.TooltipUtil:OnUpdateGameTooltip(expectedOwner, GetTranslatedGlobalString, true)
end

local function getQuestTitleForQuestList(questID, isTrivial)
    local translatedTitle = GetTranslatedQuestTitle(questID)
    if (not translatedTitle) then return end

    if (isTrivial) then
        translatedTitle = translatedTitle .. IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION
    end

    return translatedTitle
end

local function translateUIFontString(fontString)
    if (not fontString.GetText or not fontString.SetText) then return end
    local text = fontString:GetText()
    local translateText = GetTranslatedGlobalString(text)
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

local function showCommandButtonsForQuest(needToShow)
    if (needToShow) then
        questFrameSwitchTranslationButton:Show()
        questPopupFrameSwitchTranslationButton:Show()
        questMapDetailsFrameSwitchTranslationButton:Show()
    else
        questFrameSwitchTranslationButton:Hide()
        questPopupFrameSwitchTranslationButton:Hide()
        questMapDetailsFrameSwitchTranslationButton:Hide()
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
            translatedText = GetTranslatedGlobalString(QUEST_WATCH_QUEST_READY)
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
        local translatedText = getQuestTitleForQuestList(questID, isTrivial)
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
                local translatedTitle = getQuestTitleForQuestList(tonumber(data.info.questID), data.info.isTrivial)
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

    local npcGUID = UnitGUID("npc")
    if (npcGUID) then
        local _, _, _, _, _, npcID = strsplit("-", npcGUID)

        local titlesCategory = ns.IngameDataCacher:GetOrAddCategory({ "npc-gossips", npcID, "titles" })
        ns.IngameDataCacher:GetOrAddToCategory(titlesCategory, "title", C_GossipInfo.GetText())

        local options = C_GossipInfo.GetOptions()
        if (options and #options ~= 0) then
            local optionsCategory = ns.IngameDataCacher:GetOrAddCategory({ "npc-gossips", npcID, "options" })
            for _, gossipOption in ipairs(options) do
                ns.IngameDataCacher:GetOrAddToCategory(optionsCategory, "option", gossipOption.name)
            end
        end
    end
end

local function OnQuestMapLogTitleButtonTooltipShow(button)
    local info = C_QuestLog.GetInfo(button.questLogIndex);
    assert(info and not info.isHeader);

    local questID = info.questID;
    local questData = GetTranslatedQuestData(questID)
    if (not questData) then return end

    QuestMapFrame:GetParent():SetHighlightedQuestID(questID);

    if (questData.Title) then
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
    end

    if C_QuestLog.IsQuestReplayable(questID) then
        GameTooltip_AddInstructionLine(GameTooltip,
            QuestUtils_GetReplayQuestDecoration(questID) ..
            GetTranslatedGlobalString(QUEST_SESSION_QUEST_TOOLTIP_IS_REPLAY), false);
    elseif C_QuestLog.IsQuestDisabledForSession(questID) then
        GameTooltip_AddColoredLine(GameTooltip,
            QuestUtils_GetDisabledQuestDecoration(questID) ..
            GetTranslatedGlobalString(QUEST_SESSION_ON_HOLD_TOOLTIP_TITLE),
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
        QuestUtils_AddQuestTagLineToTooltip(GameTooltip, GetTranslatedGlobalString(DAILY), "DAILY", nil,
            NORMAL_FONT_COLOR);
    elseif (info.frequency == Enum.QuestFrequency.Weekly) then
        QuestUtils_AddQuestTagLineToTooltip(GameTooltip, GetTranslatedGlobalString(WEEKLY), "WEEKLY", nil,
            NORMAL_FONT_COLOR);
    end

    if C_QuestLog.IsFailed(info.questID) then
        QuestUtils_AddQuestTagLineToTooltip(GameTooltip, GetTranslatedGlobalString(FAILED), "FAILED", nil,
            RED_FONT_COLOR);
    end

    GameTooltip:AddLine(" ");

    -- description
    local isComplete = C_QuestLog.IsComplete(info.questID);
    if isComplete then
        local completionText = GetQuestLogCompletionText(button.questLogIndex)
        if (not completionText) then
            completionText = GetTranslatedGlobalString(QUEST_WATCH_QUEST_READY)
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

    GameTooltip:AddLine(GetTranslatedGlobalString(CLICK_QUEST_DETAILS),
        GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);

    if QuestUtils_GetNumPartyMembersOnQuest(questID) > 0 then
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(GetTranslatedGlobalString(PARTY_QUEST_STATUS_ON));

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

    showCommandButtonsForQuest(questData ~= nil)

    local translateQuestText = ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_TEXT_OPTION)
    if (not translateQuestText) then return end

    if (QuestInfoTitleHeader:IsVisible()) then
        if (questData and questData.Title) then
            local link = ""
            if (questData.IsMtData) then
                link = ("|H%s:%d|h%s|h"):format(translatedWithAILinkType, 0, [[|TInterface\AddOns\WowUkrainizer\assets\images\robot.png:14|t]]) .. ""
            end
            QuestInfoTitleHeader:SetText(link .. " " .. QuestUtils_DecorateQuestText(questID, questData.Title, true))
        end
    end

    if (QuestInfoObjectivesText:IsVisible()) then
        if (questData and questData.ObjectivesText) then
            QuestInfoObjectivesText:SetText(questData.ObjectivesText)
        end
    end

    if (QuestInfoObjectivesFrame:IsVisible()) then
        TranslteQuestObjectives(QuestInfoObjectivesFrame.Objectives, questData, true)
    end

    if (QuestInfoDescriptionText:IsVisible()) then
        if (questData and questData.Description) then
            QuestInfoDescriptionText:SetText(questData.Description)
        end
    end

    if (QuestInfoRewardsFrame:IsVisible()) then
        if (questData and questData.RewardText) then
            QuestInfoRewardText:SetText(questData.RewardText)
        end
        translateUIFontString(QuestInfoRewardsFrame.ItemChooseText)
        translateUIFontString(QuestInfoRewardsFrame.ItemReceiveText)
        translateUIFontString(QuestInfoRewardsFrame.QuestSessionBonusReward);
    end

    if (QuestInfoFrame.rewardsFrame:IsVisible()) then
        -- ignore
        translateUIFontString(QuestInfoFrame.rewardsFrame.ItemChooseText)
        translateUIFontString(QuestInfoFrame.rewardsFrame.ItemReceiveText)
        translateUIFontString(QuestInfoFrame.rewardsFrame.PlayerTitleText)
        translateUIFontString(QuestInfoFrame.rewardsFrame.QuestSessionBonusReward)
        translateUIFontString(QuestInfoFrame.rewardsFrame.WarModeBonusFrame)
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

    showCommandButtonsForQuest(questData ~= nil)

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

local function InitializeCommandButtons()
    questFrameSwitchTranslationButton = CreateSwitchTranslationButton(QuestFrame, function()
        if (QuestFrameProgressPanel:IsShown()) then
            QuestFrameProgressPanel_OnShow(QuestFrameProgressPanel)
        else
            QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
                QuestInfoFrame.mapView)
        end
    end, -160, -32)
    CreateWowheadButton(QuestFrame, -250, -32, { getQuestID = function() return GetQuestID() end })

    questPopupFrameSwitchTranslationButton = CreateSwitchTranslationButton(QuestLogPopupDetailFrame, function()
        QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
            QuestInfoFrame.mapView)
    end, -188, -30)
    CreateWowheadButton(QuestLogPopupDetailFrame, -4, -30, { getQuestID = function() return C_QuestLog.GetSelectedQuest() end })

    questMapDetailsFrameSwitchTranslationButton = CreateSwitchTranslationButton(QuestMapDetailsScrollFrame, function()
        QuestInfo_Display(ACTIVE_TEMPLATE, ACTIVE_PARENT_FRAME, QuestInfoFrame.acceptButton, QuestInfoFrame.material,
            QuestInfoFrame.mapView)
    end, -104, 32)
    CreateWowheadButton(QuestMapDetailsScrollFrame, -194, 32, { getQuestID = function() return C_QuestLog.GetSelectedQuest() end })
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
    if (not questID) then return end

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
        GameTooltip:AddLine(GetTranslatedGlobalString(AVAILABLE_QUEST), 1, 1, 1, true);
        if (questLineInfo.floorLocation == Enum.QuestLineFloorLocation.Below) then
            GameTooltip:AddLine(GetTranslatedGlobalString(QUESTLINE_LOCATED_BELOW), 0.5, 0.5, 0.5, true);
        elseif (questLineInfo.floorLocation == Enum.QuestLineFloorLocation.Above) then
            GameTooltip:AddLine(GetTranslatedGlobalString(QUESTLINE_LOCATED_ABOVE), 0.5, 0.5, 0.5, true);
        end
        GameTooltip:Show();
    end
end


function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION)
end

function translator:Init()
    local function _addQuestInfoToCache(progressText, completeText)
        local category = ns.IngameDataCacher:GetOrAddCategory({ "quests", GetQuestID() })
        if (progressText) then
            ns.IngameDataCacher:GetOrAddToCategory(category, "progress", progressText)
        end

        if (completeText) then
            ns.IngameDataCacher:GetOrAddToCategory(category, "complete", completeText)
        end
    end
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
    -- Quest popup
    translateUIFontString(QuestLogPopupDetailFrame.ShowMapButton.Text)
    translateButton(QuestLogPopupDetailFrame.AbandonButton)
    translateButton(QuestLogPopupDetailFrame.ShareButton)
    -- Quest map
    translateUIFontString(MapQuestInfoRewardsFrame.TitleFrame.Name)
    for _, region in ipairs({ QuestMapFrame.DetailsFrame.RewardsFrameContainer.RewardsFrame:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            translateUIFontString(region)
        end
    end
    translateButton(QuestMapFrame.DetailsFrame.AbandonButton, 90, 22)
    translateButton(QuestMapFrame.DetailsFrame.ShareButton, 90, 22)
    translateButton(QuestMapFrame.DetailsFrame.BackFrame.BackButton, nil, 24)
    translateUIFontString(QuestScrollFrame.CampaignTooltip.CompleteRewardText)
    translateUIFontString(QuestFrame.AccountCompletedNotice.Text)
    translateUIFontString(QuestMapFrame.DetailsFrame.BackFrame.AccountCompletedNotice.Text)
    QuestFrame.AccountCompletedNotice:HookScript("OnEnter", OnUpdateGameTooltip)
    QuestMapFrame.DetailsFrame.BackFrame.AccountCompletedNotice:HookScript("OnEnter", OnUpdateGameTooltip)

    eventHandler:Register(function() _addQuestInfoToCache(GetProgressText()) end, "QUEST_PROGRESS")
    eventHandler:Register(function() _addQuestInfoToCache(nil, GetRewardText()) end, "QUEST_COMPLETE")

    eventHandler:Register(OnGossipShow, "GOSSIP_SHOW", "GOSSIP_CLOSED")

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
    hooksecurefunc("StaticPopup_Show", OnStaticPopupShow)

    hooksecurefunc("QuestInfo_OnHyperlinkEnter", function (owner, link) -- TODO: Other QuestInfo_OnHyperlinkEnter translations in next release
        local linkType = LinkUtil.SplitLinkData(link);
        if linkType == translatedWithAILinkType then
            GameTooltip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT");
            GameTooltip:ClearLines();
            GameTooltip:SetText("Перекладено за допомогою ШІ.", 1, 1, 1)
            GameTooltip:AddLine(
                "Ви завжди можете вимкнути переклади зроблені |nза допомогою ШІ в налаштуваннях додатку.",
                RAID_CLASS_COLORS.MAGE.r,
                RAID_CLASS_COLORS.MAGE.g,
                RAID_CLASS_COLORS.MAGE.b)
            GameTooltip:Show();
        else
            OnUpdateGameTooltip(owner)
        end
    end)

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

                        -- Addons like World Quest Tracker, for example, create their own buttons on the world map, but do not have the UpdateTooltip function
                        local success, result = pcall(function() return type(frame.UpdateTooltip) end) -- TODO: [Tech Debt] Create function safehooksecurefunc
                        if (success and result == "function") then
                            hooksecurefunc(frame, "UpdateTooltip", OnWorldMapPinButtonTooltipUpdated)
                        end

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

ns.TranslationsManager:AddTranslator(translator)
