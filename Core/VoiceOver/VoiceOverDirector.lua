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

local function onGlobalMouseDown()
    local tooltipData = GameTooltip:GetTooltipData()
    if (tooltipData == nil) then return end
    if (tooltipData.guid == nil) then return end

    local reaction = UnitReaction("mouseover", "player")
    if (not reaction or reaction < 4) then return end

    local unitKind, _, _, _, _, unitId, _ = strsplit("-", tooltipData.guid)
    if (unitKind == "Creature" or unitKind == "Vehicle") then
        voiceOverDirector:PlayEmotion(tonumber(unitId), EMOTION_TYPES.GREETINGS)
    end
end

local function onLoadingScreenEnabled()
    voiceOverDirector:StopImmediately();
end

local function onPlaySoudHook(soundKitID, channel, forceNoDuplicates, runFinishCallback)
    if (channel ~= "Talking Head") then return end

    local hash = VoiceOverData.SoundKindIds[soundKitID]
    if (not hash) then return end

    ns.VoiceOverDirector:PlayDialog(hash, false, "Talking Head")
end

local function getUniqueRandomValue(current, maxRange)
    local value
    repeat value = math.random(maxRange) until value ~= current
    return value
end

function voiceOverDirector:Initialize()
    settingsProvider:Load()

    for _, soundFile in pairs(VoiceOverData.MuteDialogs) do
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

    if (settingsProvider.IsNeedTranslateDialogVoiceOver()) then
        for _, soundFile in pairs(VoiceOverData.MuteEmotions) do
            MuteSoundFile(soundFile)
        end

        eventHandler:Register(onGlobalMouseDown, "GLOBAL_MOUSE_DOWN")
        eventHandler:Register(onLoadingScreenEnabled, "LOADING_SCREEN_ENABLED")

        hooksecurefunc("PlaySound", onPlaySoudHook)

        QuestFrame:HookScript("OnShow", function()
            voiceOverDirector.lastQuestGiverId = voiceOverDirector.currentUnit.id
        end)

        QuestFrame:HookScript("OnHide", function()
            voiceOverDirector:PlayEmotion(self.lastQuestGiverId, EMOTION_TYPES.FAREWELLS)
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

function voiceOverDirector:PlayDialog(hash, isCinematic, channel)
    if (isCinematic and not settingsProvider.IsNeedTranslateCinematicVoiceOver()) then return end
    if (not isCinematic and not settingsProvider.IsNeedTranslateDialogVoiceOver()) then return end

    local voData = isCinematic and VoiceOverData.Cinematics[hash] or VoiceOverData.Dialogs[hash]
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

local function getGreetingsOrPissedEmotion(self, unitId)
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

local function getFarewellsEmotion(self, unitId)
    self.currentUnit.pissedId = 0
    self.currentUnit.greetingsCount = 0

    local emotionId = VoiceOverData.NpcEmotions[unitId] and VoiceOverData.NpcEmotions[unitId][EMOTION_TYPES.FAREWELLS]
    if (not emotionId) then return end

    local farewellsEmotions = VoiceOverData.Emotions[emotionId]
    if (not farewellsEmotions) then return end

    return farewellsEmotions[math.random(#farewellsEmotions)]
end

function voiceOverDirector:PlayEmotion(unitId, emotionType)
    if (not settingsProvider.IsNeedTranslateDialogVoiceOver()) then return end

    if (self.currentUnit.id ~= unitId) then
        self:ResetEmotions()
        self.currentUnit.id = unitId
    end

    if (self.dialogIsPlaying or self.emotionsIsPlaying) then return end

    local emotion
    if emotionType == EMOTION_TYPES.GREETINGS then
        emotion = getGreetingsOrPissedEmotion(self, unitId)
    elseif emotionType == EMOTION_TYPES.FAREWELLS then
        emotion = getFarewellsEmotion(self, unitId)
    end

    if (emotion) then
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
