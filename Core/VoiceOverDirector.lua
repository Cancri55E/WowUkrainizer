local _, ns = ...

local voiceOverDirector = {
    currentTalkingHeadHandler = {},
    currentCinematicHandler = {},
    currentDialogHandler = {},
    lastSelectedNpcId = 0
}

function voiceOverDirector:Init()
    local function MuteNpcEmotions()
    end

    local function MuteNpcDialogs()
    end
end

function voiceOverDirector:PlayVoiceOverForDialog(hash, type)

end

function voiceOverDirector:PlayVoiceOverForEmotion(npcId, emotionType)
end

ns.VoiceOverDirector = voiceOverDirector
