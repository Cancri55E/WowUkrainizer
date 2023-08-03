local _, ns = ...;

local chatBubbleTimer

local aceHook = LibStub("AceHook-3.0")
local eventHandler = ns.EventHandler:new()

local GenerateUuid = ns.CommonExtensions.GenerateUuid
local Split, Trim = ns.StringExtensions.Split, ns.StringExtensions.Trim
local SetFontStringText = ns.FontStringExtensions.SetText
local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetDialogText = ns.DbContext.NpcDialogs.GetDialogText

local translator = class("NpcMessageTranslator", ns.Translators.BaseTranslator)
ns.Translators.NpcMessageTranslator = translator

local function updateChatBubbleMessage(chatBubbles)
    local function getFontString(chatBubble)
        local chatBubbleFrame = select(1, chatBubble:GetChildren());
        for i = 1, chatBubbleFrame:GetNumRegions() do
            local region = select(i, chatBubbleFrame:GetRegions())
            if region:GetObjectType() == "FontString" then
                return region
            end
        end
    end

    for _, chatBubble in pairs(chatBubbles) do
        if not chatBubble:IsForbidden() then
            local fontString = getFontString(chatBubble);
            if (fontString) then
                local message = fontString:GetText() or "";
                local translatedMsg, msgHash = GetDialogText(message)
                ns.VoiceOverDirector:PlayVoiceOverForDialog(msgHash, false, "Dialog")
                SetFontStringText(fontString, translatedMsg)
            end
        end
    end
end

local function onChatBubbleTimerUpdate(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed > 0.01 then
        self:Stop()
        updateChatBubbleMessage(C_ChatBubbles.GetAllChatBubbles())
    end
end

local function onMonsterMessageReceived(instance, msg, author, ...)
    local displayInTalkingHead = false
    local _, _, soundKitID, _, _, _, talkingHeadAuthor, talkingHeadMsg, _, _ = C_TalkingHead.GetCurrentLineInfo();
    if (talkingHeadMsg == msg and talkingHeadAuthor == author) then
        displayInTalkingHead = true
    end

    local translatedAuthor = GetUnitNameOrDefault(author)
    local translatedMsg = GetDialogText(msg)

    if (msg == translatedMsg) then
        local untranslatedData = instance.untranslatedDataStorage:GetOrAdd("NpcMessages", author, msg)
        if (displayInTalkingHead) then
            untranslatedData.talkingHead = true
            untranslatedData.soundKitID = soundKitID
        end
    end

    if (displayInTalkingHead) then
        SetFontStringText(TalkingHeadFrame.NameFrame.Name, translatedAuthor);
        SetFontStringText(TalkingHeadFrame.TextFrame.Text, translatedMsg);
    else
        chatBubbleTimer:Start();
    end

    return false, translatedMsg, translatedAuthor, ...
end

local function onCinematicFrameAddSubtitle(instance, chatType, subtitle)
    local parts = Split(subtitle, ":")

    local author = ''
    local msg = ''
    if (#parts == 1) then
        msg = parts[1]
    elseif (#parts == 2) then
        author = parts[1]
        msg = Trim(parts[2])
    else
        author = parts[1]
        msg = parts[2]
        for i = 3, #parts do
            msg = msg .. ":" .. parts[i]
        end
        msg = Trim(msg)
    end


    local translatedAuthor = GetUnitNameOrDefault(author)
    local translatedMsg, msgHash = GetDialogText(msg)

    if (translatedMsg == msg) then
        local untranslatedData = instance.untranslatedDataStorage:GetOrAdd("NpcMessages", author, msg)
        untranslatedData.cinematicUuid = instance.cinematicUuid
        untranslatedData.subtitleOrder = instance.subtitleOrder
    end

    local translatedSubtitle = author == '' and translatedMsg or translatedAuthor .. ": " .. translatedMsg
    ns.VoiceOverDirector:PlayVoiceOverForDialog(msgHash, true, "Dialog")
    instance.hooks["CinematicFrame_AddSubtitle"](chatType, translatedSubtitle)

    instance.subtitleOrder = instance.subtitleOrder + 1
end

function translator:initialize()
    ns.Translators.BaseTranslator.initialize(self)

    local instance = self
    instance.hooks = aceHook.hooks
    instance.untranslatedDataStorage = ns.UntranslatedDataStorage:new()

    local function onMonsterMessageReceivedHook(_, _, msg, author, ...)
        return onMonsterMessageReceived(instance, msg, author, ...)
    end

    local function onCinematicFrameAddSubtitleHook(chatType, subtitle)
        onCinematicFrameAddSubtitle(instance, chatType, subtitle)
    end

    chatBubbleTimer = CreateFrame("Frame", "ChatBubble-Timer", WorldFrame)
    chatBubbleTimer:SetFrameStrata("TOOLTIP")
    chatBubbleTimer.Start = chatBubbleTimer.Show
    chatBubbleTimer.Stop = function()
        chatBubbleTimer:Hide()
        chatBubbleTimer.elapsed = 0
    end
    chatBubbleTimer:Stop()
    chatBubbleTimer:SetScript("OnUpdate", onChatBubbleTimerUpdate)

    aceHook:RawHook("CinematicFrame_AddSubtitle", onCinematicFrameAddSubtitleHook, true)

    eventHandler:Register(function()
        instance.cinematicUuid = GenerateUuid()
        instance.subtitleOrder = 0
    end, "CINEMATIC_START")

    eventHandler:Register(function()
        instance.cinematicUuid = ''
        instance.subtitleOrder = -1
    end, "CINEMATIC_STOP")

    eventHandler:Register(function()
        if (not instance.talkingHeadUuid or instance.talkingHeadUuid == '') then
            instance.talkingHeadUuid = GenerateUuid()
        end
    end, "TALKINGHEAD_REQUESTED")

    eventHandler:Register(function() instance.talkingHeadUuid = '' end, "TALKINGHEAD_CLOSE")

    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_PARTY", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", onMonsterMessageReceivedHook)
end
