--- @type string, WowUkrainizerInternals
local _, ns = ...;

local translator = class("MainFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.MainFrameTranslator = translator

local function getTranslationOrDefault(default)
    return ns.DbContext.Frames.GetTranslationOrDefault("main", default)
end

local function microButtonTooltipHook(button)
    if (not button) then return end

    local owner = GameTooltip:GetOwner()
    if (owner and owner ~= button) then return end

    local tooltipTitle = _G["GameTooltipTextLeft1"]
    if (tooltipTitle) then
        local bindingKeyText
        local text = tooltipTitle:GetText() or ''
        text = text:gsub("(.-) " .. NORMAL_FONT_COLOR_CODE .. "%((.-)%)" .. FONT_COLOR_CODE_CLOSE, function(t, b)
            bindingKeyText = NORMAL_FONT_COLOR_CODE .. ' (' .. b .. ')' .. FONT_COLOR_CODE_CLOSE
            return t
        end)
        if (not bindingKeyText) then
            tooltipTitle:SetText(getTranslationOrDefault(text))
        else
            tooltipTitle:SetText(getTranslationOrDefault(text) .. bindingKeyText)
        end
    end
    GameTooltip:Show()
end

function translator:initialize()
    GameMenuFrame.Header.Text:SetText(getTranslationOrDefault(GameMenuFrame.Header.Text:GetText()))
    for i = 1, GameMenuFrame:GetNumChildren() do
        local element = select(i, GameMenuFrame:GetChildren())
        if element and element:IsObjectType("Button") and element.GetText then
            element:SetText(getTranslationOrDefault(element:GetText()))
        end
    end

    CharacterMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(CharacterMicroButton) end)
    TalentMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(TalentMicroButton) end)
    SpellbookMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(SpellbookMicroButton) end)
    AchievementMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(AchievementMicroButton) end)
    QuestLogMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(QuestLogMicroButton) end)
    LFDMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(LFDMicroButton) end)
    CollectionsMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(CollectionsMicroButton) end)
    EJMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(EJMicroButton) end)
    StoreMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(StoreMicroButton) end)

    CharacterFrameTab1:HookScript("OnEnter", function() microButtonTooltipHook(CharacterFrameTab1) end)
    CharacterFrameTab2:HookScript("OnEnter", function() microButtonTooltipHook(CharacterFrameTab2) end)
    CharacterFrameTab3:HookScript("OnEnter", function() microButtonTooltipHook(CharacterFrameTab3) end)

    GuildMicroButton:HookScript("OnEnter", function() microButtonTooltipHook(GuildMicroButton) end)
    MainMenuMicroButton:HookScript("OnUpdate", function() microButtonTooltipHook(MainMenuMicroButton) end)
    ChatFrameChannelButton:HookScript("OnEnter", function() microButtonTooltipHook(ChatFrameChannelButton) end)
    QuickJoinToastButton:HookScript("OnEnter", function() microButtonTooltipHook(QuickJoinToastButton) end)
    ChatFrameToggleVoiceMuteButton:HookScript("OnEnter", function()
        microButtonTooltipHook(ChatFrameToggleVoiceMuteButton)
    end)
end
