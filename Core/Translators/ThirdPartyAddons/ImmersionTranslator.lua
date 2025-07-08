--- @type string, WowUkrainizerInternals
local _, ns = ...;

local IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION = ns.IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION

local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation

local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName
local GetTranslatedGossipText = ns.DbContext.Gossips.GetTranslatedGossipText
local GetTranslatedGossipOptionText = ns.DbContext.Gossips.GetTranslatedGossipOptionText
local GetTranslatedQuestTitle = ns.DbContext.Quests.GetTranslatedQuestTitle
local GetTranslatedQuestData = ns.DbContext.Quests.GetTranslatedQuestData
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local CreateSwitchTranslationButton = ns.QuestFrameUtil.CreateSwitchTranslationButton
local CreateMtIconTexture = ns.QuestFrameUtil.CreateMtIconTexture
local CreateWowheadButton = ns.QuestFrameUtil.CreateWowheadButton

local immersionTitleOriginal, immersionTextOriginal, immersionObjectivesTextOriginal

local immersionFrameSwitchTranslationButton, immersionFrameMTIcon, immersionWowheadButton

---@class ImmersionTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_QUEST_AND_OBJECTIVES_FRAME_OPTION)
end

local function GetTranslatedQuestTitleInternal(questID, isTrivial)
    local translatedTitle = GetTranslatedQuestTitle(questID)
    if (not translatedTitle) then return end

    if (isTrivial) then
        translatedTitle = translatedTitle .. IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION
    end

    return translatedTitle
end

local function UpdateCommandButtonsVisibility(needToShow, isMTData)
    if (needToShow) then
        if (immersionFrameSwitchTranslationButton) then
            immersionFrameSwitchTranslationButton:Show()
        end
        if (isMTData) then
            if (immersionFrameMTIcon) then
                immersionFrameMTIcon:Show()
            end
        else
            if (immersionFrameMTIcon) then
                immersionFrameMTIcon:Hide()
            end
        end
    else
        if (immersionFrameSwitchTranslationButton) then
            immersionFrameSwitchTranslationButton:Hide()
        end
        if (immersionFrameMTIcon) then
            immersionFrameMTIcon:Hide()
        end
    end
end

local function ImmersionFrame_UpdateTalkingHead(immersionFrame, title, text)
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

        UpdateCommandButtonsVisibility(questData ~= nil, questData and questData.IsMtData)

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

local function ImmersionFrame_TalkBox_Elements_Display(elements)
    local SEAL_QUESTS = {
        [40519] = '|cff04aaffКороль|nВаріан Рінн|r',
        [43926] = '|cff480404Воєначальник|nВол\'джин|r',
        [46730] = '|cff2f0a48Кадґар|r',
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
            UpdateTextWithTranslation(elements.Content.SpecialObjectivesFrame.SpellObjectiveLearnLabel, GetTranslatedGlobalString)
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
        UpdateTextWithTranslation(elements.Content.RewardsFrame.ItemChooseText, GetTranslatedGlobalString)
        UpdateTextWithTranslation(elements.Content.RewardsFrame.ItemReceiveText, GetTranslatedGlobalString)
        UpdateTextWithTranslation(elements.Content.RewardsFrame.HonorFrame.Name, GetTranslatedGlobalString)

        for fontString in elements.Content.RewardsFrame.spellHeaderPool:EnumerateActive() do
            if (fontString:GetText() ~= nil) then
                UpdateTextWithTranslation(fontString, GetTranslatedGlobalString);
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
    local immersionModelFrame = ImmersionFrame.TalkBox.MainFrame.Model

    immersionWowheadButton = CreateWowheadButton(immersionModelFrame, 30, immersionModelFrame:GetHeight() * -1 + 20,
        { getQuestID = function() return GetQuestID() end })

    immersionFrameSwitchTranslationButton = CreateSwitchTranslationButton(immersionWowheadButton, function()
        ImmersionFrame_UpdateTalkingHead(ImmersionFrame, immersionTitleOriginal, immersionTextOriginal)
        ImmersionFrame_TalkBox_Elements_Display(ImmersionFrame.TalkBox.Elements)
        ImmersionFrame.TalkBox.TextFrame.Text:RepeatTexts();
    end, 92, 0)

    immersionFrameMTIcon = CreateMtIconTexture(immersionFrameSwitchTranslationButton, 24, 0)
end

function translator:Init()
    if (ImmersionFrame == nil) then return end

    InitializeCommandButtons()

    hooksecurefunc(ImmersionFrame, "UpdateTalkingHead", function(immersionFrame, title, text)
        immersionTitleOriginal = title
        immersionTextOriginal = text
        ImmersionFrame_UpdateTalkingHead(immersionFrame, title, text)
    end)

    hooksecurefunc(ImmersionFrame.TalkBox.Elements, "Display", function(elements)
        immersionObjectivesTextOriginal = elements.Content.ObjectivesText:GetText()
        ImmersionFrame_TalkBox_Elements_Display(elements)
    end)

    hooksecurefunc(ImmersionFrame.TitleButtons, "UpdateAvailableQuests", function(titleButtons, availableQuests)
        for i, quest in ipairs(availableQuests) do
            local button = titleButtons:GetButton(i)
            local questTitle = GetTranslatedQuestTitleInternal(quest.questID, quest.isTrivial)
            if (questTitle) then
                button:SetText(questTitle)
            end
        end
    end)

    hooksecurefunc(ImmersionFrame.TitleButtons, "UpdateActiveQuests", function(titleButtons, activeQuests)
        local numGossipAvailableQuests = #ImmersionAPI:GetGossipAvailableQuests()
        for i, quest in ipairs(activeQuests) do
            local button = titleButtons:GetButton(i + numGossipAvailableQuests)
            local questTitle = GetTranslatedQuestTitleInternal(quest.questID, quest.isTrivial)
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
            local questTitle = GetTranslatedQuestTitleInternal(GetActiveQuestID(i), IsActiveQuestTrivial(i))
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
                local questTitle = GetTranslatedQuestTitleInternal(questID, isTrivial)
                if (questTitle) then
                    button:SetText(questTitle)
                end
            end
        end)

    -- Consts
    UpdateTextWithTranslation(ImmersionContentFrame.ObjectivesHeader, GetTranslatedGlobalString)
    UpdateTextWithTranslation(ImmersionContentFrame.RewardsFrame.Header, GetTranslatedGlobalString)
    UpdateTextWithTranslation(ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText, GetTranslatedGlobalString)
    UpdateTextWithTranslation(ImmersionContentFrame.QuestInfoAccountCompletedNotice, GetTranslatedGlobalString)
    UpdateTextWithTranslation(ImmersionFrame.TalkBox.Elements.Progress.MoneyText, GetTranslatedGlobalString)
    UpdateTextWithTranslation(ImmersionFrame.TalkBox.Elements.Progress.ReqText, GetTranslatedGlobalString)    
end

ns.TranslationsManager:AddTranslator(translator)
