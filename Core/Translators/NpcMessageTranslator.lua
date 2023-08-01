local _, ns = ...;

local chatBubbleTimer

local aceHook = LibStub("AceHook-3.0")
local eventHandler = ns.EventHandler:new()
local voiceOverDirector = ns.VoiceOverDirector

local GenerateUuid = ns.CommonExtensions.GenerateUuid
local Split, Trim = ns.StringExtensions.Split, ns.StringExtensions.Trim
local SetFontStringText = ns.FontStringExtensions.SetText
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
                if (message == "Let's move into sparring positions. I'll let you have the first strike.") then
                    message = "Перейдемо на спарингові позиції. Перший удар залишу за тобою."
                    PlaySoundFile(
                        [[Interface\AddOns\WowUkrainizer\assets\sounds\creatures\private_cole\vo_152846_3486957.ogg]],
                        "Dialog")
                end
                if (message == "Never run from your opponent. Stand your ground and fight until the end!") then
                    message = "Ніколи не тікай від супротивника. Будь непохитним і бийся до кінця!"
                    PlaySoundFile(
                        [[Interface\AddOns\WowUkrainizer\assets\sounds\creatures\private_cole\vo_152847_3486958.ogg]],
                        "Dialog")
                end
                if (message == "Remember to always face your enemy!") then
                    message = "Не забувай завжди дивитися на ворога!"
                    PlaySoundFile(
                        [[Interface\AddOns\WowUkrainizer\assets\sounds\creatures\private_cole\vo_152897_3488623.ogg]],
                        "Dialog")
                end
                if (message == "I yield! Well, I'd say you're more than ready for whatever we find on that island.") then
                    message =
                    "Я здаюсь! Думаю ти готовий до всього, що ми зустрінемо на острові."
                    PlaySoundFile(
                        [[Interface\AddOns\WowUkrainizer\assets\sounds\creatures\private_cole\vo_152848_3486959.ogg]],
                        "Dialog")
                end
                if (message == "Captain! We can't weather this storm for long!") then
                    message =
                    "Капітане! Довго ми не витримаємо в такий шторм!"
                    PlaySoundFile(
                        [[Interface\AddOns\WowUkrainizer\assets\sounds\creatures\private_cole\vo_152849_3486966.ogg]],
                        "Dialog")
                end
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
    local translatedMsg = GetDialogText(msg)

    if (translatedMsg == msg) then
        local untranslatedData = instance.untranslatedDataStorage:GetOrAdd("NpcMessages", author, msg)
        untranslatedData.cinematicUuid = instance.cinematicUuid
        untranslatedData.subtitleOrder = instance.subtitleOrder
    end

    local translatedSubtitle = author == '' and translatedMsg or translatedAuthor .. ": " .. translatedMsg

    if (translatedSubtitle == "You are a soldier of the noble Alliance, a coalition of kingdoms upholding the ideals of valor and justice across Azeroth.") then
        translatedSubtitle =
        "Ви - солдат благородного Альянсу, коаліції королівств, що відстоюють ідеали доблесті та справедливості в Азероті."
        PlaySoundFile(
            [[Interface\AddOns\WowUkrainizer\assets\sounds\cinematics\exiles_rich_alliance_begin\vo_152835_3486924.ogg]],
            "Dialog")
    end
    if (translatedSubtitle == "An Alliance expedition sent to explore an uncharted island has recently gone missing.") then
        translatedSubtitle = "Нещодавно зникла експедиція Альянсу, що відправилась для дослідження незвіданого острова."
        PlaySoundFile(
            [[Interface\AddOns\WowUkrainizer\assets\sounds\cinematics\exiles_rich_alliance_begin\vo_152836_3486925.ogg]],
            "Dialog")
    end
    if (translatedSubtitle == "As a bold new recruit, you have joined the rescue mission departing from Stormwind.") then
        translatedSubtitle =
        "Як сміливий новобранець, ви приєднались до рятувальної місії, що відправляється зі Штормовію."
        PlaySoundFile(
            [[Interface\AddOns\WowUkrainizer\assets\sounds\cinematics\exiles_rich_alliance_begin\vo_152837_3486926.ogg]],
            "Dialog")
    end
    if (translatedSubtitle == "Find the lost expedition members and bring them home. For the Alliance!") then
        translatedSubtitle = "Знайдіть зниклих членів експедиції та поверніть їх додому. За Альянс!"
        PlaySoundFile(
            [[Interface\AddOns\WowUkrainizer\assets\sounds\cinematics\exiles_rich_alliance_begin\vo_152845_3486934.ogg]],
            "Dialog")
    end



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

    local function onPlaySoudHook(soundKitID, channel, forceNoDuplicates, runFinishCallback)
        onPlaySoud(instance, soundKitID, channel, forceNoDuplicates, runFinishCallback)
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

    hooksecurefunc("PlaySound", onPlaySoudHook)

    -- private_cole
    MuteSoundFile(3486957)
    MuteSoundFile(3486958)
    MuteSoundFile(3486959)
    MuteSoundFile(3488623)
    MuteSoundFile(3486966)
    -- private_cole (emotions)
    -- cinematics
    MuteSoundFile(3486924)
    MuteSoundFile(3486925)
    MuteSoundFile(3486926)
    MuteSoundFile(3486934)
end
