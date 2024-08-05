--- @type WowUkrainizerInternals
local ns = select(2, ...);

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()

local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation

---@class MainFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

local MicroButtons = {
    "CharacterMicroButton",
    "ProfessionMicroButton",
    "PlayerSpellsMicroButton",
    "AchievementMicroButton",
    "QuestLogMicroButton",
    "LFDMicroButton",
    "CollectionsMicroButton",
    "EJMicroButton",
    "StoreMicroButton",
    "CharacterFrameTab1",
    "CharacterFrameTab2",
    "CharacterFrameTab3",
    "GuildMicroButton",
    "MainMenuMicroButton",
    "ChatFrameChannelButton",
    "QuickJoinToastButton",
    "ChatFrameToggleVoiceMuteButton"
}

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
            tooltipTitle:SetText(GetTranslatedGlobalString(text))
        else
            tooltipTitle:SetText(GetTranslatedGlobalString(text) .. bindingKeyText)
        end
    end
    GameTooltip:Show()
end

function translator:IsEnabled()
    return true
end

function translator:Init()
    UpdateTextWithTranslation(GameMenuFrame.Header.Text, GetTranslatedGlobalString)

    hooksecurefunc(GameMenuFrame, "InitButtons", function(frame)
        for buttonFrame in frame.buttonPool:EnumerateActive() do
            UpdateTextWithTranslation(buttonFrame, GetTranslatedGlobalString)
        end
    end);

    for i = 1, #MicroButtons do
        _G[MicroButtons[i]]:HookScript("OnEnter", microButtonTooltipHook);
    end

    local function OnAddOnLoaded(_, name)
        if (name == "Blizzard_ItemSocketingUI") then
            UpdateTextWithTranslation(ItemSocketingSocketButton, GetTranslatedGlobalString) -- TODO: Maybe someday move to ItemSocketingFrame Translator
            eventHandler:Unregister(OnAddOnLoaded, "ADDON_LOADED")
        end
    end
    eventHandler:Register(OnAddOnLoaded, "ADDON_LOADED")
end

ns.TranslationsManager:AddTranslator(translator)
