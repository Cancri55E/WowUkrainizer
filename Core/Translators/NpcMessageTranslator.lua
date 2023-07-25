local _, ns = ...;

local chatBubbleTimer

local aceHook = LibStub("AceHook-3.0")
local eventHandler = ns.EventHandler:new()

local GenerateUuid = ns.CommonExtensions.GenerateUuid
local SetFontStringText = ns.FontStringExtensions.SetText
local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetDialogText = ns.DbContext.NpcDialogs.GetDialogText
local GetCinematicSubtitle = ns.DbContext.Subtitles.GetCinematicSubtitle

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
    if (instance.cinematicUuid and instance.cinematicUuid ~= '') then
        return;
    end

    local translatedAuthor = GetUnitNameOrDefault(author)
    local translatedMsg = GetDialogText(msg)

    if (msg == translatedMsg) then instance.untranslatedDataStorage:Add("NpcMessages", author, msg) end

    chatBubbleTimer:Start();

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

    chatBubbleTimer = CreateFrame("Frame", "ChatBubble-Timer", WorldFrame)
    chatBubbleTimer:SetFrameStrata("TOOLTIP")
    chatBubbleTimer.Start = chatBubbleTimer.Show
    chatBubbleTimer.Stop = function()
        chatBubbleTimer:Hide()
        chatBubbleTimer.elapsed = 0
    end
    chatBubbleTimer:Stop()
    chatBubbleTimer:SetScript("OnUpdate", onChatBubbleTimerUpdate)

    aceHook:RawHook("CinematicFrame_AddSubtitle", function(chatType, subtitle)
        local translatedSubtitle = GetCinematicSubtitle(subtitle)
        if (translatedSubtitle == subtitle) then
            instance.untranslatedDataStorage:Add("CinematicSubtitles", instance.cinematicUuid, translatedSubtitle)
        end
        instance.hooks["CinematicFrame_AddSubtitle"](chatType, translatedSubtitle)
    end, true)

    eventHandler:Register(function() instance.cinematicUuid = GenerateUuid() end, "CINEMATIC_START")
    eventHandler:Register(function() instance.cinematicUuid = '' end, "CINEMATIC_STOP")

    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_PARTY", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", onMonsterMessageReceivedHook)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", onMonsterMessageReceivedHook)
end
