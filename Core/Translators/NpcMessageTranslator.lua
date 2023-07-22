local _, ns = ...;

local chatBubbleTimer

local SetFontStringText = ns.FontStringExtensions.SetText
local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault
local GetDialogText = ns.DbContext.NpcDialogs.GetDialogText

local translator = class("NpcMessageTranslator", ns.Translators.BaseTranslator)
ns.Translators.NpcMessageTranslator = translator

local function addDialogToUntranslatedData(author, msg)
    local function isValueInTable(t, value) -- TODO: Move to extension
        for _, v in ipairs(t) do
            if v == value then
                return true
            end
        end
        return false
    end

    if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
    if (not _G.WowUkrainizerData.UntranslatedData) then _G.WowUkrainizerData.UntranslatedData = {} end
    if (not _G.WowUkrainizerData.UntranslatedData.MovieSubtitles) then _G.WowUkrainizerData.UntranslatedData.MovieSubtitles = {} end
    if (not _G.WowUkrainizerData.UntranslatedData.MovieSubtitles[author]) then _G.WowUkrainizerData.UntranslatedData.MovieSubtitles[author] = {} end

    local authorTable = _G.WowUkrainizerData.UntranslatedData.MovieSubtitles[author]

    if (not isValueInTable(authorTable, msg)) then table.insert(authorTable, msg) end
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

local function onMonsterMessageReceived(_, _, msg, author, ...)
    author = GetUnitNameOrDefault(author)
    msg = GetDialogText(msg)

    addDialogToUntranslatedData(author, msg)

    chatBubbleTimer:Start();
    return false, msg, author, ...
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
