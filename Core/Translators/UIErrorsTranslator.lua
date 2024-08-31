--- @class WowUkrainizerInternals
local ns = select(2, ...);

local ExtractFromText = ns.StringUtil.ExtractFromText
local GetTranslatedZoneText = ns.DbContext.ZoneTexts.GetTranslatedZoneText
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local GetTranslatedQuestObjective = ns.DbContext.Quests.GetTranslatedQuestObjective

---@class UIErrorsTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

local ZoneMessages = {
    [LE_GAME_ERR_ZONE_EXPLORED] = {},
    [LE_GAME_ERR_ZONE_EXPLORED_XP] = {},
    [LE_GAME_ERR_NEWTAXIPATH] = {},
}

local QuestMessages = {
    [LE_GAME_ERR_QUEST_ALREADY_DONE] = {},
    [LE_GAME_ERR_QUEST_ALREADY_DONE_DAILY] = {},
    [LE_GAME_ERR_QUEST_ALREADY_ON] = {},
    [LE_GAME_ERR_QUEST_FAILED_CAIS] = {},
    [LE_GAME_ERR_QUEST_FAILED_EXPANSION] = {},
    [LE_GAME_ERR_QUEST_FAILED_LOW_LEVEL] = {},
    [LE_GAME_ERR_QUEST_FAILED_MISSING_ITEMS] = {},
    [LE_GAME_ERR_QUEST_FAILED_NOT_ENOUGH_MONEY] = {},
    [LE_GAME_ERR_QUEST_FAILED_SPELL] = {},
    [LE_GAME_ERR_QUEST_FAILED_WRONG_RACE] = {},
    [LE_GAME_ERR_QUEST_HAS_IN_PROGRESS] = {},
    [LE_GAME_ERR_QUEST_IGNORED] = {},
    [LE_GAME_ERR_QUEST_LOG_FULL] = {},
    [LE_GAME_ERR_QUEST_MUST_CHOOSE] = {},
    [LE_GAME_ERR_QUEST_NEED_PREREQS] = {},
    [LE_GAME_ERR_QUEST_ONLY_ONE_TIMED] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_ALREADY_ACTIVE] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_ALREADY_JOINED] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_ALREADY_MEMBER] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_ALREADY_OWNER] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_BUSY] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_DISABLED] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_INVALID_AREA] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_IN_COMBAT] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_IN_PET_BATTLE] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_IN_RAID] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_JOIN_REJECTED] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_LEFT] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_LEGACY_LOOT_MODE] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_MEMBER_IN_COMBAT] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_NOT_ACTIVE] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_NOT_IN_PARTY] = {},
    [LE_GAME_ERR_QUEST_PUSH_NOT_IN_PARTY_S] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_NOT_MEMBER] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_NOT_OWNER] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_QUEST_NOT_COMPLETED] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_READY_CHECK_FAILED] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_RESTRICTED] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_RESTRICTED_CROSS_FACTION] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_RESYNC] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_STARTED] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_STOPPED] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_TIMEOUT] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_UNKNOWN] = {},
    [LE_GAME_ERR_QUEST_UNIGNORED] = {},
    [LE_GAME_ERR_QUEST_UNKNOWN_COMPLETE] = {},
}

local QuestMessagesWithVariables = {
    [LE_GAME_ERR_QUEST_NEED_PREREQS_CUSTOM] = {},
    [LE_GAME_ERR_QUEST_TURN_IN_FAIL_REASON] = {},
    [LE_GAME_ERR_QUEST_OBJECTIVE_COMPLETE_S] = {},
    [LE_GAME_ERR_QUEST_ADD_KILL_SII] = {},
    [LE_GAME_ERR_QUEST_ADD_FOUND_SII] = {},
    [LE_GAME_ERR_QUEST_ADD_ITEM_SII] = {},
    [LE_GAME_ERR_QUEST_ADD_PLAYER_KILL_SII] = {},
    [LE_GAME_ERR_QUEST_ACCEPTED_S] = {},
    [LE_GAME_ERR_QUEST_COMPLETE_S] = {},
    [LE_GAME_ERR_QUEST_FAILED_BAG_FULL_S] = {},
    [LE_GAME_ERR_QUEST_FAILED_MAX_COUNT_S] = {},
    [LE_GAME_ERR_QUEST_FAILED_S] = {},
    [LE_GAME_ERR_QUEST_FAILED_TOO_MANY_DAILY_QUESTS_I] = {},
    [LE_GAME_ERR_QUEST_FORCE_REMOVED_S] = {},
    [LE_GAME_ERR_QUEST_PET_BATTLE_VICTORIES_PVP_II] = {},
    [LE_GAME_ERR_QUEST_PUSH_ACCEPTED_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_ALREADY_DONE_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_ALREADY_DONE_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_BUSY_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_CLASS_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_CLASS_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_CROSS_FACTION_RESTRICTED_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_DEAD_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_DEAD_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_DECLINED_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_DIFFERENT_SERVER_DAILY_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_DIFFERENT_SERVER_DAILY_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_EXPANSION_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_EXPANSION_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_HIGH_FACTION_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_HIGH_FACTION_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_HIGH_LEVEL_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_HIGH_LEVEL_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_INVALID_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_INVALID_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_LOG_FULL_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_LOG_FULL_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_LOW_FACTION_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_LOW_FACTION_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_LOW_LEVEL_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_LOW_LEVEL_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_NEW_PLAYER_EXPERIENCE_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_NEW_PLAYER_EXPERIENCE_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_NOT_ALLOWED_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_NOT_DAILY_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_NOT_GARRISON_OWNER_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_ONQUEST_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_ONQUEST_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_PREREQUISITE_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_PREREQUISITE_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_RACE_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_SUCCESS_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_TIMER_EXPIRED_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_TOO_FAR_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_WRONG_COVENANT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_WRONG_COVENANT_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_WRONG_FACTION_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_WRONG_FACTION_TO_RECIPIENT_S] = {},
    [LE_GAME_ERR_QUEST_REWARD_EXP_I] = {},
    [LE_GAME_ERR_QUEST_REWARD_MONEY_S] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_OWNER_REFUSED_S] = {},
    [LE_GAME_ERR_QUEST_SESSION_RESULT_INVALID_OWNER_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_NOT_GARRISON_OWNER_S] = {},
    [LE_GAME_ERR_QUEST_PUSH_RACE_S] = {},
}

local function ProcessZoneMessage(messageType, message)
    if (not ZoneMessages[messageType]) then return end

    if (messageType == LE_GAME_ERR_ZONE_EXPLORED) then
        local zoneName = ExtractFromText(ERR_ZONE_EXPLORED, message)
        local translatedText = string.format(GetTranslatedGlobalString(ERR_ZONE_EXPLORED), GetTranslatedZoneText(zoneName))
        table.insert(ZoneMessages[LE_GAME_ERR_ZONE_EXPLORED], { text = message, translatedText = translatedText })
    elseif (messageType == LE_GAME_ERR_ZONE_EXPLORED_XP) then
        local zoneName, exp = ExtractFromText(ERR_ZONE_EXPLORED_XP, message)
        exp = exp:gsub("[,.]", "")
        local translatedText = string.format(GetTranslatedGlobalString(ERR_ZONE_EXPLORED_XP), GetTranslatedZoneText(zoneName), exp)
        table.insert(ZoneMessages[LE_GAME_ERR_ZONE_EXPLORED_XP], { text = message, translatedText = translatedText })
    elseif (messageType == LE_GAME_ERR_NEWTAXIPATH) then
        table.insert(ZoneMessages[LE_GAME_ERR_NEWTAXIPATH], { text = message, translatedText = GetTranslatedGlobalString(ERR_NEWTAXIPATH) })
    end
end

local function ProcessQuestMessage(messageType, message)
    if (not QuestMessages[messageType]) then return end
    table.insert(QuestMessages[messageType], { text = message, translatedText = GetTranslatedGlobalString(message) })
end

local function ProcessQuestMessageWithVariables(messageType, message)
    if (not QuestMessagesWithVariables[messageType]) then return end

    if (messageType == LE_GAME_ERR_QUEST_OBJECTIVE_COMPLETE_S) then
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

        table.insert(QuestMessagesWithVariables[messageType], { text = message, translatedText = translatedText })
    elseif (messageType == LE_GAME_ERR_QUEST_ADD_ITEM_SII or messageType == LE_GAME_ERR_QUEST_ADD_FOUND_SII) then
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

        table.insert(QuestMessagesWithVariables[messageType], { text = message, translatedText = translatedText })
    elseif (messageType == LE_GAME_ERR_QUEST_ADD_KILL_SII) then
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

        table.insert(QuestMessagesWithVariables[messageType], { text = message, translatedText = translatedText })
    elseif (messageType == LE_GAME_ERR_QUEST_ADD_PLAYER_KILL_SII) then
        local translatedText = message:gsub("Players slain: (%d+/%d+)", function(progress)
            return "Вбито гравців: " .. progress
        end)
        table.insert(QuestMessagesWithVariables[messageType], { text = message, translatedText = translatedText })
    end
end

local function ApplyTranslation(messageCache)
    for messageType, messages in pairs(messageCache) do
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

local function UIErrorsFrame_AddMessage(_, message, _, _, _, _, messageType)
    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)) then
        ProcessZoneMessage(messageType, message)
    end

    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION)) then
        ProcessQuestMessage(messageType, message)
        ProcessQuestMessageWithVariables(messageType, message)
    end
end

local function UIErrorsFrame_OnUpdated()
    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)) then
        ApplyTranslation(ZoneMessages)
    end
    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION)) then
        ApplyTranslation(QuestMessages)
        ApplyTranslation(QuestMessagesWithVariables)
    end
end

function translator:Init()
    hooksecurefunc(UIErrorsFrame, "AddMessage", UIErrorsFrame_AddMessage)
    UIErrorsFrame:HookScript("OnUpdate", UIErrorsFrame_OnUpdated)
    hooksecurefunc(UIErrorsFrame, "SetScript", function(_, _, value)
        if (not value) then UIErrorsFrame:HookScript("OnUpdate", UIErrorsFrame_OnUpdated) end
    end)
end

ns.TranslationsManager:AddTranslator(translator)
