local _, ns = ...;

local questDump = {}
ns.QuestDump = questDump

function questDump.FindCompaign()
    if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
    if (not _G.WowUkrainizerData.QuestData) then _G.WowUkrainizerData.QuestData = {} end
    if (not _G.WowUkrainizerData.QuestData.Campaigns) then _G.WowUkrainizerData.QuestData.Campaigns = {} end

    local campaigns = _G.WowUkrainizerData.QuestData.Campaigns
    for campaignID = 1, 500, 1 do
        local campaignInfo = C_CampaignInfo.GetCampaignInfo(campaignID)
        if (campaignInfo) then
            if (not campaigns[campaignID]) then campaigns[campaignID] = { chapters = {} } end

            campaigns[campaignID].name = campaignInfo.name

            local chapterIDs = C_CampaignInfo.GetChapterIDs(campaignID)
            if (chapterIDs) then
                for _, campaignChapterID in pairs(chapterIDs) do
                    local campaignChapterInfo = C_CampaignInfo.GetCampaignChapterInfo(campaignChapterID)
                    if (campaignChapterInfo) then
                        if (not campaigns[campaignID].chapters[campaignChapterID]) then
                            campaigns[campaignID].chapters[campaignChapterID] = {}
                        end
                        campaigns[campaignID].chapters[campaignChapterID].name = campaignChapterInfo.name
                        campaigns[campaignID].chapters[campaignChapterID].description = campaignChapterInfo.description
                    end
                end
            end
        end
    end
end

function questDump.DumpQuestObjectiveInfo(questID)
    if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
    if (not _G.WowUkrainizerData.QuestData) then _G.WowUkrainizerData.QuestData = {} end
    if (not _G.WowUkrainizerData.QuestData[questID]) then _G.WowUkrainizerData.QuestData[questID] = {} end

    local questData = _G.WowUkrainizerData.QuestData[questID]
    if (not questData.Objectives) then questData.Objectives = {} end

    for objectiveIndex = 1, 20, 1 do
        local text, _, _, _, _ = GetQuestObjectiveInfo(questID, objectiveIndex, false)
        if (text) then
            questData.Objectives[objectiveIndex] = { Text = text }
            local completeText, _, _, _, _ = GetQuestObjectiveInfo(questID, objectiveIndex, false)
            if (completeText and completeText ~= text) then
                questData.Objectives[objectiveIndex].CompleteText = completeText
            end
        end
    end
end
