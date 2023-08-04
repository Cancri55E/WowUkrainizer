local _, ns = ...

local VoiceOverData = ns.VoiceOverData
local eventHandler = ns.EventHandler:new()

local voiceOverDirector = {
    currentDialogHandler = 0,
    dialogIsPlaying = false,
    currentEmotionsHandler = 0,
    emotionsIsPlaying = false,
    lastNpc = {
        id = 0,
        greetingsId = 0,
        greetingsCount = 0,
        farewellsId = 0,
        pissedId = 0,
    },
}

local function onGlobalMouseDown()
    local tooltipData = GameTooltip:GetTooltipData()
    if (tooltipData == nil) then return end
    if (tooltipData.guid == nil) then return end

    local reaction = UnitReaction("mouseover", "player")
    if (not reaction or reaction < 4) then return end

    local unitKind, _, _, _, _, unitId, _ = strsplit("-", tooltipData.guid)
    if (unitKind == "Creature" or unitKind == "Vehicle") then
        local name = UnitName("mouseover")
        voiceOverDirector:PlayVoiceOverForEmotion(tonumber(unitId), "Greetings")
    end
end

local function onPlaySoudHook(soundKitID, channel, forceNoDuplicates, runFinishCallback)
    if (channel ~= "Talking Head") then return end

    local hash = VoiceOverData.SoundKindIds[soundKitID]
    if (not hash) then return end

    ns.VoiceOverDirector:PlayVoiceOverForDialog(hash, false, channel)
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
end

function voiceOverDirector:ResetNpc()
    self.lastNpc = {
        id = 0,
        greetingsId = 0,
        greetingsCount = 0,
        farewellsId = 0,
        pissedId = 0,
    }
end

function voiceOverDirector:PlaingVoiceCompleted(soundHandle, isEmotion)
    if (isEmotion) then
        if self.currentEmotionsHandler == soundHandle then
            self.emotionsIsPlaying = false
            self.currentEmotionsHandler = 0
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
        StopSound(self.currentEmotionsHandler)
        self.currentEmotionsHandler = 0;
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

function voiceOverDirector:PlayVoiceOverForEmotion(npcId, emotionType)
    if (self.lastNpc.id ~= npcId) then
        self:ResetNpc()
        self.lastNpc.id = npcId
    end

    local emotionId = VoiceOverData.NpcEmotions[npcId]
    if (not emotionId) then return end

    if (VoiceOverData.Emotions[emotionId] == nil) then return end
    if (VoiceOverData.Emotions[emotionId][emotionType] == nil) then return end

    if (self.dialogIsPlaying or self.emotionsIsPlaying) then return end

    local emotions = nil
    local emotionIndex = nil

    if (emotionType == "Greetings") then
        local greetingEmotions = VoiceOverData.Emotions[emotionId][emotionType]
        local pissedEmotions = VoiceOverData.Emotions[emotionId]["Pissed"]
        self.lastNpc.greetingsCount = self.lastNpc.greetingsCount + 1
        if (self.lastNpc.greetingsCount > 6 and pissedEmotions) then
            self.lastNpc.pissedId = self.lastNpc.pissedId + 1
            if (self.lastNpc.pissedId <= #pissedEmotions) then
                emotions = pissedEmotions
                emotionIndex = self.lastNpc.pissedId
            else
                self.lastNpc.pissedId = 0
                self.lastNpc.greetingsCount = 0
                self.lastNpc.greetingsId = 1

                emotions = greetingEmotions
                emotionIndex = 1
            end
        else
            if (self.lastNpc.greetingsId == 0) then
                self.lastNpc.greetingsId = self.lastNpc.greetingsId + 1
            else
                local newGreetingsId
                repeat
                    newGreetingsId = math.random(#greetingEmotions)
                until newGreetingsId ~= self.lastNpc.greetingsId
                self.lastNpc.greetingsId = newGreetingsId
            end

            emotions = greetingEmotions
            emotionIndex = self.lastNpc.greetingsId
        end
    elseif (emotionType == "Farewells") then
        local farewellsEmotions = VoiceOverData.Emotions[emotionId][emotionType]
        if (self.lastNpc.farewellsId == 0) then
            self.lastNpc.farewellsId = self.lastNpc.farewellsId + 1
        else
            local newFarewellsId
            repeat
                newFarewellsId = math.random(#farewellsEmotions)
            until newFarewellsId ~= self.lastNpc.farewellsId
            self.lastNpc.farewellsId = newFarewellsId
        end

        emotions = farewellsEmotions
        emotionIndex = self.lastNpc.farewellsId
    end

    local willPlay, soundHandler = PlaySoundFile(emotions[emotionIndex].file, "Dialog")
    if (willPlay) then
        self.currentEmotionsHandler = soundHandler
        self.emotionsIsPlaying = true

        C_Timer.After(emotions[emotionIndex].lengthInSeconds, function()
            self:PlaingVoiceCompleted(soundHandler, true)
        end)
    end
end

ns.VoiceOverDirector = voiceOverDirector
