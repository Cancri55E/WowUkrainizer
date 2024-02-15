local _, ns = ...
local VoiceOverData = ns.VoiceOverData
local eventHandler = ns.EventHandler:new()
local settingsProvider = ns.SettingsProvider:new()

local EMOTION_TYPES = {
    GREETINGS = "Greetings",
    FAREWELLS = "Farewells",
    PISSED = "Pissed"
}

local voiceOverDirector = {
    currentDialogHandler = 0,
    dialogIsPlaying = false,
    currentEmotionHandler = 0,
    emotionsIsPlaying = false,
    currentUnit = {
        id = 0,
        greetingsId = 0,
        greetingsCount = 0,
        pissedId = 0,
    },
    lastQuestGiverId = 0
}

function voiceOverDirector:Initialize()
    local function toggleAudioMuteBySettings()
        for _, soundFile in pairs(VoiceOverData.MuteDialogs) do
            if (settingsProvider.IsNeedTranslateDialogVoiceOver()) then
                MuteSoundFile(soundFile)
            else
                UnmuteSoundFile(soundFile)
            end
        end

        for _, soundFile in pairs(VoiceOverData.MuteEmotions) do
            if (settingsProvider.IsNeedTranslateDialogVoiceOver()) then
                MuteSoundFile(soundFile)
            else
                UnmuteSoundFile(soundFile)
            end
        end

        for _, soundFile in pairs(VoiceOverData.MuteCinematics) do
            if (settingsProvider.IsNeedTranslateCinematicVoiceOver()) then
                MuteSoundFile(soundFile)
            else
                UnmuteSoundFile(soundFile)
            end
        end
    end

    local function playSoundHook(soundKitID, channel, forceNoDuplicates, runFinishCallback)
        if (channel ~= "Talking Head") then return end
        ns.VoiceOverDirector:PlaySoundFileForTalkingHead(soundKitID)
    end

    local function onLoadingScreenEnabled()
        voiceOverDirector:StopImmediately();
    end

    local function onGlobalMouseDown()
        local tooltipData = GameTooltip:GetTooltipData()
        if (tooltipData == nil) then return end
        if (tooltipData.guid == nil) then return end

        local reaction = UnitReaction("mouseover", "player")
        if (not reaction or reaction < 4) then return end

        local unitKind, _, _, _, _, unitId, _ = strsplit("-", tooltipData.guid)
        if (unitKind == "Creature" or unitKind == "Vehicle") then
            voiceOverDirector:PlaySoundFileForEmotion(tonumber(unitId), EMOTION_TYPES.GREETINGS)
        end
    end

    settingsProvider:Load()

    toggleAudioMuteBySettings()

    if (settingsProvider.IsNeedTranslateDialogVoiceOver()) then
        eventHandler:Register(onGlobalMouseDown, "GLOBAL_MOUSE_DOWN")
        eventHandler:Register(onLoadingScreenEnabled, "LOADING_SCREEN_ENABLED")

        hooksecurefunc("PlaySound", playSoundHook)

        QuestFrame:HookScript("OnShow", function()
            voiceOverDirector.lastQuestGiverId = voiceOverDirector.currentUnit.id
        end)

        QuestFrame:HookScript("OnHide", function()
            voiceOverDirector:PlaySoundFileForEmotion(self.lastQuestGiverId, EMOTION_TYPES.FAREWELLS)
            voiceOverDirector.lastQuestGiverId = 0
        end)
    end

    if (settingsProvider.IsNeedTranslateCinematicVoiceOver()) then
        eventHandler:Register(onLoadingScreenEnabled, "LOADING_SCREEN_ENABLED")
    end
end

function voiceOverDirector:ResetEmotions()
    self.currentUnit = {
        id = 0,
        greetingsId = 0,
        greetingsCount = 0,
        pissedId = 0,
    }
end

function voiceOverDirector:PlayCompleted(soundHandle, isEmotion)
    if (isEmotion) then
        if self.currentEmotionHandler == soundHandle then
            self.emotionsIsPlaying = false
            self.currentEmotionHandler = 0
        end
    else
        if self.currentDialogHandler == soundHandle then
            self.dialogIsPlaying = false
            self.currentDialogHandler = 0
        end
    end
end

function voiceOverDirector:StopImmediately()
    StopSound(self.currentEmotionHandler)
    self.currentEmotionHandler = 0;
    self.emotionsIsPlaying = false

    StopSound(self.currentDialogHandler)
    self.currentDialogHandler = 0;
    self.dialogIsPlaying = false
end

function voiceOverDirector:_PlaySoundInternal(voData, channel)
    if (voData) then
        self:StopImmediately()

        local willPlay, soundHandler = PlaySoundFile(voData.file, channel)
        if (willPlay) then
            self.currentDialogHandler = soundHandler
            self.dialogIsPlaying = true

            C_Timer.After(voData.lengthInSeconds, function()
                self:PlayCompleted(soundHandler, false)
            end)
        end
    end
end

function voiceOverDirector:PlaySoundFileForDialogue(msgHash, author)
    if (not settingsProvider.IsNeedTranslateDialogVoiceOver()) then return end

    local hash = tonumber(msgHash)
    if (not hash) then return end

    local voData = VoiceOverData.Dialogs[author] and VoiceOverData.Dialogs[author][hash] or nil
    if (not voData) then return end

    self:_PlaySoundInternal(voData, "Dialog")
end

function voiceOverDirector:PlaySoundFileForTalkingHead(soundKitID)
    if (not settingsProvider.IsNeedTranslateDialogVoiceOver()) then return end

    local voData = VoiceOverData.SoundKindIds[soundKitID]
    if (not voData) then return end

    self:_PlaySoundInternal(voData, "Talking Head")
end

function voiceOverDirector:PlaySoundFileForCinematic(msgHash, author)
    if (not settingsProvider.IsNeedTranslateCinematicVoiceOver()) then return end

    local hash = tonumber(msgHash)
    if (not hash) then return end

    if (not author) then author = "<Common>" end

    local voData = VoiceOverData.Cinematics[author] and VoiceOverData.Cinematics[author][hash] or nil
    if (not voData) then return end

    self:_PlaySoundInternal(voData, "Dialog")
end

function voiceOverDirector:PlaySoundFileForEmotion(unitId, emotionType)
    local function getGreetingsOrPissedEmotion()
        local function getUniqueRandomValue(current, maxRange)
            local value
            repeat value = math.random(maxRange) until value ~= current
            return value
        end

        local greetingEmotionId = VoiceOverData.NpcEmotions[unitId] and
            VoiceOverData.NpcEmotions[unitId][EMOTION_TYPES.GREETINGS]
        if (not greetingEmotionId) then return end

        local greetingEmotions = VoiceOverData.Emotions[greetingEmotionId]
        if (not greetingEmotions) then return end

        self.currentUnit.greetingsCount = self.currentUnit.greetingsCount + 1

        local pissedEmotionId = VoiceOverData.NpcEmotions[unitId] and VoiceOverData.NpcEmotions[unitId]
            [EMOTION_TYPES.PISSED]
        local pissedEmotions = pissedEmotionId and VoiceOverData.Emotions[pissedEmotionId]
        if self.currentUnit.greetingsCount > 6 and pissedEmotions then
            self.currentUnit.pissedId = self.currentUnit.pissedId + 1
            if self.currentUnit.pissedId <= #pissedEmotions then
                return pissedEmotions[self.currentUnit.pissedId]
            else
                self.currentUnit.pissedId = 0
                self.currentUnit.greetingsCount = 0
            end
        end

        self.currentUnit.greetingsId = getUniqueRandomValue(self.currentUnit.greetingsId, #greetingEmotions)
        return greetingEmotions[self.currentUnit.greetingsId]
    end

    local function getFarewellsEmotion()
        self.currentUnit.pissedId = 0
        self.currentUnit.greetingsCount = 0

        local emotionId = VoiceOverData.NpcEmotions[unitId] and
            VoiceOverData.NpcEmotions[unitId][EMOTION_TYPES.FAREWELLS]
        if (not emotionId) then return end

        local farewellsEmotions = VoiceOverData.Emotions[emotionId]
        if (not farewellsEmotions) then return end

        return farewellsEmotions[math.random(#farewellsEmotions)]
    end

    if (not settingsProvider.IsNeedTranslateDialogVoiceOver()) then return end

    if (self.currentUnit.id ~= unitId) then
        self:ResetEmotions()
        self.currentUnit.id = unitId
    end

    if (self.dialogIsPlaying or self.emotionsIsPlaying) then return end

    local emotion
    if emotionType == EMOTION_TYPES.GREETINGS then
        emotion = getGreetingsOrPissedEmotion()
    elseif emotionType == EMOTION_TYPES.FAREWELLS then
        emotion = getFarewellsEmotion()
    end

    if (emotion) then
        self:StopImmediately()

        local willPlay, soundHandler = PlaySoundFile(emotion.file, "Dialog")
        if (willPlay) then
            self.currentEmotionHandler = soundHandler
            self.emotionsIsPlaying = true

            C_Timer.After(emotion.lengthInSeconds, function()
                self:PlayCompleted(soundHandler, true)
            end)
        end
    end
end

ns.VoiceOverDirector = voiceOverDirector
