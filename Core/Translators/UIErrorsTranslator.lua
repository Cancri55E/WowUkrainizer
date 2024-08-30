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
    [LE_GAME_ERR_QUEST_OBJECTIVE_COMPLETE_S] = {},
    [LE_GAME_ERR_QUEST_UNKNOWN_COMPLETE] = {},
    [LE_GAME_ERR_QUEST_ADD_KILL_SII] = {},
    [LE_GAME_ERR_QUEST_ADD_FOUND_SII] = {},
    [LE_GAME_ERR_QUEST_ADD_ITEM_SII] = {},
    [LE_GAME_ERR_QUEST_ADD_PLAYER_KILL_SII] = {},
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

        table.insert(QuestMessages[messageType], { text = message, translatedText = translatedText })
    end

    if (messageType == LE_GAME_ERR_QUEST_ADD_ITEM_SII or messageType == LE_GAME_ERR_QUEST_ADD_FOUND_SII) then
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

        table.insert(QuestMessages[messageType], { text = message, translatedText = translatedText })
    end

    if (messageType == LE_GAME_ERR_QUEST_ADD_KILL_SII) then
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

        table.insert(QuestMessages[messageType], { text = message, translatedText = translatedText })
    end


    if (messageType == LE_GAME_ERR_QUEST_UNKNOWN_COMPLETE) then
        table.insert(QuestMessages[messageType], { text = message, translatedText = "Завдання виконано." })
    end

    if (messageType == LE_GAME_ERR_QUEST_ADD_PLAYER_KILL_SII) then
        local translatedText = message:gsub("Players slain: (%d+/%d+)", function(progress)
            return "Вбито гравців: " .. progress
        end)
        table.insert(QuestMessages[messageType], { text = message, translatedText = translatedText })
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
    end
end

local function UIErrorsFrame_OnUpdated()
    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_ZONE_TEXTS_OPTION)) then
        ApplyTranslation(ZoneMessages)
    end
    if (ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION)) then
        ApplyTranslation(QuestMessages)
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
