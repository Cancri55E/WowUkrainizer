--- @class WowUkrainizerInternals
local ns = select(2, ...);

local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedQuestData = ns.DbContext.Quests.GetTranslatedQuestData
local GetTranslatedQuestObjective = ns.DbContext.Quests.GetTranslatedQuestObjective
local GetWaypointTranslation = ns.DbContext.Quests.GetWaypointTranslation
local ExtractFromText = ns.StringUtil.ExtractFromText

---@class ObjectivesTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION)
end

local function ScenarioObjectiveTracker_LayoutContents(objectiveTracker)
    local headerTextFontString = objectiveTracker.Header.Text

    local _, _, _, _, _, _, _, _, _, scenarioType, _, _, _ = C_Scenario.GetInfo();

    local inChallengeMode = (scenarioType == LE_SCENARIO_TYPE_CHALLENGE_MODE);
    local inProvingGrounds = (scenarioType == LE_SCENARIO_TYPE_PROVING_GROUNDS);
    local dungeonDisplay = (scenarioType == LE_SCENARIO_TYPE_USE_DUNGEON_DISPLAY);
    local provingGroundsActive = objectiveTracker.ProvingGroundsBlock:IsActive();
    local shouldShowMawBuffs = ShouldShowMawBuffs();

    -- header
    if inChallengeMode then
        -- headerTextFontString:SetText(scenarioName); -- TODO: Add translation when scenario name dbcontext ready
    elseif inProvingGrounds or provingGroundsActive or dungeonDisplay then
        UpdateTextWithTranslation(headerTextFontString, GetTranslatedGlobalString)
    elseif shouldShowMawBuffs and not IsInJailersTower() then
        headerTextFontString:SetText(GetTranslatedZoneText(GetZoneText()))
    else
        -- headerTextFontString:SetText(scenarioName); -- TODO: Add translation when scenario name dbcontext ready
    end
end

local function BonusObjectiveTracker_LayoutContents(objectiveTracker)
    UpdateTextWithTranslation(objectiveTracker.Header.Text, GetTranslatedGlobalString)
end

local function ObjectiveTracker_UpdateSingle(objectiveTracker, quest)
    local questID = tonumber(quest:GetID());
    if (not questID) then return end

    local template = objectiveTracker.blockTemplate;
    if not objectiveTracker.usedBlocks[template] then return end

    local block = objectiveTracker.usedBlocks[template][questID];
    if (not block) then return end

    local questTranslatedData = questID and GetTranslatedQuestData(questID)
    if (questTranslatedData and questTranslatedData.Title) then
        block.HeaderText:SetText(questTranslatedData.Title)
    end

    local blockHeight = block.HeaderText:GetHeight();

    local lineSpacing = block.parentModule.lineSpacing;

    for key, value in pairs(block.usedLines) do
        local text = value.Text:GetText()
        if (key == "Failed") then
            value.Text:SetText(GetTranslatedGlobalString(FAILED))
        elseif (key == "QuestComplete") then
            if (text == QUEST_WATCH_QUEST_READY or text == QUEST_WATCH_QUEST_COMPLETE) then
                UpdateTextWithTranslation(value.Text, GetTranslatedGlobalString)
            else
                if (questTranslatedData) then
                    if (questTranslatedData.CompletionText) then
                        value.Text:SetText(questTranslatedData.CompletionText)
                    elseif (not questTranslatedData.ContainsObjectives and questTranslatedData.ObjectivesText) then
                        value.Text:SetText(questTranslatedData.ObjectivesText)
                    end
                end
            end
        elseif (key == "ClickComplete") then
            UpdateTextWithTranslation(value.Text, GetTranslatedGlobalString)
        elseif (key == "Waypoint") then
            local waypointText = ExtractFromText(WAYPOINT_OBJECTIVE_FORMAT_OPTIONAL, text)
            if (waypointText) then
                value.Text:SetText(GetTranslatedGlobalString(WAYPOINT_OBJECTIVE_FORMAT_OPTIONAL:format(GetWaypointTranslation(waypointText))))
            else
                value.Text:SetText(GetWaypointTranslation(waypointText))
            end
        elseif (key == "Money") then

        elseif (key == "TimeLeft") then -- only for WorldQuestObjectiveTracker

        else
            value.Text:SetText(GetTranslatedQuestObjective(questID, text))
        end

        local height = value.Text:GetHeight();
        value:SetHeight(height);

        blockHeight = blockHeight + height + lineSpacing
    end

    block:SetHeight(blockHeight);
end

local function ObjectiveTracker_UpdateHeight(objectiveTracker)
    if not objectiveTracker.usedBlocks[objectiveTracker.blockTemplate] then return end
    local offset = 0;
    for _, block in pairs(objectiveTracker.usedBlocks[objectiveTracker.blockTemplate]) do
        offset = offset + (block:GetHeight() - block.height)
    end

    objectiveTracker:SetHeight(objectiveTracker:GetHeight() + offset)
end

local function ObjectiveTrackerFrame_Init(frame)
    UpdateTextWithTranslation(frame.Header.Text, GetTranslatedGlobalString)
end

function translator:Init()
    UpdateTextWithTranslation(AchievementObjectiveTracker.Header.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(MonthlyActivitiesObjectiveTracker.Header.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(QuestObjectiveTracker.Header.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(CampaignQuestObjectiveTracker.Header.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(UIWidgetObjectiveTracker.Header.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(WorldQuestObjectiveTracker.Header.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(ProfessionsRecipeTracker.Header.Text, GetTranslatedGlobalString)

    hooksecurefunc(ScenarioObjectiveTracker, "LayoutContents", ScenarioObjectiveTracker_LayoutContents)
    hooksecurefunc(BonusObjectiveTracker, "LayoutContents", BonusObjectiveTracker_LayoutContents)

    hooksecurefunc(QuestObjectiveTracker, "UpdateSingle", ObjectiveTracker_UpdateSingle)
    hooksecurefunc(CampaignQuestObjectiveTracker, "UpdateSingle", ObjectiveTracker_UpdateSingle)

    hooksecurefunc(QuestObjectiveTracker, "UpdateHeight", ObjectiveTracker_UpdateHeight)
    hooksecurefunc(CampaignQuestObjectiveTracker, "UpdateHeight", ObjectiveTracker_UpdateHeight)

    -- Use hooksecurefunc since UpdateTextWithTranslation in this case call taint code!
    hooksecurefunc(ObjectiveTrackerFrame, "Init", ObjectiveTrackerFrame_Init)
end

ns.TranslationsManager:AddTranslator(translator)
