local _, ns = ...
local VoiceOverData = ns.VoiceOverData
local eventHandler = ns.EventHandler:new()

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
        voiceOverDirector:PlayVoiceOverForEmotion(tonumber(unitId), EMOTION_TYPES.GREETINGS)
    end
end

local function onPlaySoudHook(soundKitID, channel, forceNoDuplicates, runFinishCallback)
    if (channel ~= "Talking Head") then return end

    local hash = VoiceOverData.SoundKindIds[soundKitID]
    if (not hash) then return end

    ns.VoiceOverDirector:PlayVoiceOverForDialog(hash, false, "Talking Head")
end

local function getUniqueRandomValue(current, maxRange)
    local value
    repeat value = math.random(maxRange) until value ~= current
    return value
end

function voiceOverDirector:Initialize()
    for _, soundFile in pairs(VoiceOverData.MuteDialogs) do
        MuteSoundFile(soundFile)
    end

    for _, soundFile in pairs(VoiceOverData.MuteEmotions) do
        MuteSoundFile(soundFile)
    end

    eventHandler:Register(onGlobalMouseDown, "GLOBAL_MOUSE_DOWN")

    hooksecurefunc("PlaySound", onPlaySoudHook)

    QuestFrame:HookScript("OnShow", function()
        voiceOverDirector.lastQuestGiverId = voiceOverDirector.currentUnit.id
    end)

    QuestFrame:HookScript("OnHide", function()
        voiceOverDirector:PlayVoiceOverForEmotion(self.lastQuestGiverId, EMOTION_TYPES.FAREWELLS)
        voiceOverDirector.lastQuestGiverId = 0
    end)
end

function voiceOverDirector:ResetNpcEmotions()
    self.currentUnit = {
        id = 0,
        greetingsId = 0,
        greetingsCount = 0,
        pissedId = 0,
    }
end

function voiceOverDirector:PlaingVoiceCompleted(soundHandle, isEmotion)
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

function voiceOverDirector:PlayVoiceOverForDialog(hash, isCinematic, channel)
    local voData = isCinematic and VoiceOverData.Cinematics[hash] or VoiceOverData.Dialogs[hash]
    if (voData) then
        StopSound(self.currentEmotionHandler)
        self.currentEmotionHandler = 0;
        self.emotionsIsPlaying = false

        StopSound(self.currentDialogHandler)
        self.currentDialogHandler = 0;
        self.dialogIsPlaying = false

        local willPlay, soundHandler = PlaySoundFile(voData.file, channel)
        if (willPlay) then
            self.currentDialogHandler = soundHandler
            self.dialogIsPlaying = true

            C_Timer.After(voData.lengthInSeconds, function()
                self:PlaingVoiceCompleted(soundHandler, false)
            end)
        end
    end
end

local function getGreetingsOrPissedEmotion(self, unitId)
    local emotionId = VoiceOverData.NpcEmotions[unitId]
    if (not emotionId) then return end

    local greetingEmotions = VoiceOverData.Emotions[emotionId][EMOTION_TYPES.GREETINGS]
    if (not greetingEmotions) then return end

    self.currentUnit.greetingsCount = self.currentUnit.greetingsCount + 1

    local pissedEmotions = VoiceOverData.Emotions[emotionId][EMOTION_TYPES.PISSED]
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

local function getFarewellsEmotion(unitId)
    local emotionId = VoiceOverData.NpcEmotions[unitId]
    if (not emotionId) then return end

    local farewellsEmotions = VoiceOverData.Emotions[emotionId][EMOTION_TYPES.FAREWELLS]
    if (not farewellsEmotions) then return end

    return farewellsEmotions[math.random(#farewellsEmotions)]
end

function voiceOverDirector:PlayVoiceOverForEmotion(unitId, emotionType)
    if (self.currentUnit.id ~= unitId) then
        self:ResetNpcEmotions()
        self.currentUnit.id = unitId
    end

    if (self.dialogIsPlaying or self.emotionsIsPlaying) then return end

    local emotion
    if emotionType == EMOTION_TYPES.GREETINGS then
        emotion = getGreetingsOrPissedEmotion(self, unitId)
    elseif emotionType == EMOTION_TYPES.FAREWELLS then
        emotion = getFarewellsEmotion(unitId)
    end

    if (emotion) then
        local willPlay, soundHandler = PlaySoundFile(emotion.file, "Dialog")
        if (willPlay) then
            self.currentEmotionHandler = soundHandler
            self.emotionsIsPlaying = true

            C_Timer.After(emotion.lengthInSeconds, function()
                self:PlaingVoiceCompleted(soundHandler, true)
            end)
        end
    end
end

ns.VoiceOverDirector = voiceOverDirector
