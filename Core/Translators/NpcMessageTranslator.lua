local _, ns = ...;

local chatBubbleTimer

local untranslatedDataStorage = ns.UntranslatedDataStorage:new()
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

local function onMonsterMessageReceived(_, _, msg, author, ...)
    local translatedAuthor = GetUnitNameOrDefault(author)
    local translatedMsg = GetDialogText(msg)
    if (msg == translatedMsg) then untranslatedDataStorage:Add("NpcMessages", author, msg) end

    chatBubbleTimer:Start();
    return false, translatedMsg, translatedAuthor, ...
end

function translator:initialize()
    ns.Translators.BaseTranslator.initialize(self)

    chatBubbleTimer = CreateFrame("Frame", "ChatBubble-Timer", WorldFrame)
    chatBubbleTimer:SetFrameStrata("TOOLTIP")
    chatBubbleTimer.Start = chatBubbleTimer.Show
    chatBubbleTimer.Stop = function()
        chatBubbleTimer:Hide()
        chatBubbleTimer.elapsed = 0
    end
    chatBubbleTimer:Stop()

    chatBubbleTimer:SetScript("OnUpdate", onChatBubbleTimerUpdate)

    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", onMonsterMessageReceived)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_PARTY", onMonsterMessageReceived)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", onMonsterMessageReceived)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", onMonsterMessageReceived)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", onMonsterMessageReceived)
end
