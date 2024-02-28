--- @type string, WowUkrainizerInternals
local _, ns = ...;

local chatBubbleTimer

local aceHook = LibStub("AceHook-3.0")
local eventHandler = ns.EventHandler:new()

local GenerateUuid = ns.CommonUtil.GenerateUuid
local Split, Trim = ns.StringUtil.Split, ns.StringUtil.Trim
local SetFontStringText = ns.FontStringUtil.SetText
local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetDialogText = ns.DbContext.NpcDialogs.GetDialogText

local translator = class("NpcMessageTranslator", ns.Translators.BaseTranslator)
ns.Translators.NpcMessageTranslator = translator

local function onPlaySoud(instance, soundKitID, channel, forceNoDuplicates, runFinishCallback)
    if (channel ~= "Talking Head") then return end
    -- todo: call Voice-over translator when it`s ready
end

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
                SetFontStringText(fontString, GetDialogText(message))
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

    if (not displayInTalkingHead) then
        chatBubbleTimer:Start();
    end

    return false, translatedMsg, translatedAuthor, ...
end

function translator:initialize()
    ns.Translators.BaseTranslator.initialize(self)

    local instance = self
    instance.hooks = aceHook.hooks
    instance.untranslatedDataStorage = ns.UntranslatedDataStorage:new()

    local function onMonsterMessageReceivedHook(_, _, msg, author, ...)
        return onMonsterMessageReceived(instance, msg, author, ...)
    end

    local function onPlaySoudHook(soundKitID, channel, forceNoDuplicates, runFinishCallback)
        onPlaySoud(instance, soundKitID, channel, forceNoDuplicates, runFinishCallback)
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

    eventHandler:Register(function()
        if (not instance.talkingHeadUuid or instance.talkingHeadUuid == '') then
            instance.talkingHeadUuid = GenerateUuid()
        end
    end, "TALKINGHEAD_REQUESTED")

    eventHandler:Register(function() instance.talkingHeadUuid = '' end, "TALKINGHEAD_CLOSE")

    TalkingHeadFrame:HookScript("OnUpdate", function()
        if (not TalkingHeadFrame:IsVisible()) then return end

        local translatedAuthor = GetUnitNameOrDefault(TalkingHeadFrame.NameFrame.Name:GetText())
        local translatedMsg = GetDialogText(TalkingHeadFrame.TextFrame.Text:GetText())

        SetFontStringText(TalkingHeadFrame.NameFrame.Name, translatedAuthor);
        SetFontStringText(TalkingHeadFrame.TextFrame.Text, translatedMsg);
    end)

    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_PARTY", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", onMonsterMessageReceivedHook)

    hooksecurefunc("PlaySound", onPlaySoudHook)
end
