--- @type WowUkrainizerInternals
local ns = select(2, ...);

---@class Frame
---@field elapsed integer
local chatBubbleTimer

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

local GenerateUuid = ns.CommonUtil.GenerateUuid
local SetFontStringText = ns.FontStringUtil.SetText
local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName
local GetTranslatedNpcMessage = ns.DbContext.NpcDialogs.GetTranslatedNpcMessage

---@class NpcMessageTranslator : BaseTranslator
---@field talkingHeadUuid string?
local translator = setmetatable({ talkingHeadUuid = nil }, { __index = ns.BaseTranslator })

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
                SetFontStringText(fontString, GetTranslatedNpcMessage(message))
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

local function onMonsterMessageReceived(_, msg, author, ...)
    local displayInTalkingHead = false
    local _, _, soundKitID, _, _, _, talkingHeadAuthor, talkingHeadMsg, _, _ = C_TalkingHead.GetCurrentLineInfo();
    if (talkingHeadMsg == msg and talkingHeadAuthor == author) then
        displayInTalkingHead = true
    end

    local translatedAuthor = GetTranslatedUnitName(author)
    local translatedMsg = GetTranslatedNpcMessage(msg)

    if (ns.IngameDataCacher) then
        local metadata = {}
        if (displayInTalkingHead) then
            metadata.talkingHead = true
            metadata.soundKitID = soundKitID
        end
        ns.IngameDataCacher:GetOrAdd({ "npc-texts", author }, msg, metadata)
    end

    if (not displayInTalkingHead) then
        chatBubbleTimer:Start();
    end

    return false, translatedMsg, translatedAuthor, ...
end

function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_NPC_MESSAGES_OPTION)
end

function translator:Init()
    local instance = self --[[@as NpcMessageTranslator]]

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

        local translatedAuthor = GetTranslatedUnitName(TalkingHeadFrame.NameFrame.Name:GetText())
        local translatedMsg = GetTranslatedNpcMessage(TalkingHeadFrame.TextFrame.Text:GetText())

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

ns.TranslationsManager:AddTranslator(translator)
