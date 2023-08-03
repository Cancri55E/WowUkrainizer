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
        pissedId = 0,
    },
}

local function onGlobalMouseDown()
    local tooltipData = GameTooltip:GetTooltipData()
    if (tooltipData == nil) then return end
    if (tooltipData.guid == nil) then return end

    local reaction = UnitReaction("mouseover", "player")
    if (reaction < 4) then return end

    local unitKind, _, _, _, _, unitId, _ = strsplit("-", tooltipData.guid)
    if (unitKind == "Creature" or unitKind == "Vehicle") then
        local name = UnitName("mouseover")
        voiceOverDirector:PlayVoiceOverForEmotion(unitId, "Greetings")
    end
end

local function onPlaySoudHook(soundKitID, channel, forceNoDuplicates, runFinishCallback)
    if (channel ~= "Talking Head") then return end
    -- todo: call Voice-over translator when it`s ready
end

function voiceOverDirector:Initialize()
    local function MuteNpcEmotions()
        -- private_cole (emotions)
    end

    local function MuteNpcDialogs()
        -- private_cole
        MuteSoundFile(3486957)
        MuteSoundFile(3486958)
        MuteSoundFile(3486959)
        MuteSoundFile(3488623)
        MuteSoundFile(3486966)
        -- cinematics
        MuteSoundFile(3486924)
        MuteSoundFile(3486925)
        MuteSoundFile(3486926)
        MuteSoundFile(3486934)
    end

    MuteNpcEmotions()
    MuteNpcDialogs()

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

function voiceOverDirector:PlayVoiceOverForDialog(hash, type)
    local voFile = VoiceOverData.Dialogs[hash]
    if (voFile) then
        StopSound(self.currentEmotionsHandler)
        self.currentEmotionsHandler = 0;

        StopSound(self.currentDialogHandler)
        self.currentDialogHandler = 0;

        local willPlay, soundHandler = PlaySoundFile(voFile, type)
        if (willPlay) then self.currentDialogHandler = soundHandler end
    end
end

function voiceOverDirector:PlayVoiceOverForEmotion(npcId, emotionType)
    if (self.lastNpc.id ~= npcId) then self:ResetNpc() end

    if (VoiceOverData.Emotions[npcId] == nil) then return end
    if (VoiceOverData.Emotions[npcId][emotionType] == nil) then return end

    if (self.dialogIsPlaying or self.emotionsIsPlaying) then return end

    local emotions = nil
    local emotionId = nil

    if (emotionType == "Greetings") then
        local greetingEmotions = VoiceOverData.Emotions[npcId][emotionType]
        local pissedEmotions = VoiceOverData.Emotions[npcId]["Pissed"]
        self.lastNpc.greetingsCount = self.lastNpc.greetingsCount + 1
        if (self.lastNpc.greetingsCount > 6 and pissedEmotions) then
            self.lastNpc.pissedId = self.lastNpc.pissedId + 1
            if (self.lastNpc.pissedId <= #pissedEmotions) then
                emotions = pissedEmotions
                emotionId = self.lastNpc.pissedId
            else
                self.lastNpc.pissedId = 0
                self.lastNpc.greetingsCount = 0
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
            emotionId = self.lastNpc.greetingsId
        end
    elseif (emotionType == "Farewells") then
        local farewellsEmotions = VoiceOverData.Emotions[npcId][emotionType]
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
        emotionId = self.lastNpc.farewellsId
    end

    local willPlay, soundHandler = PlaySoundFile(emotions[emotionId].file, "Master")
    if (willPlay) then self.currentEmotionsHandler = soundHandler end

    C_Timer.After(self.lengthInSeconds, function() self:PlaingVoiceCompleted(soundHandler, true) end)
end

ns.VoiceOverDirector = voiceOverDirector
