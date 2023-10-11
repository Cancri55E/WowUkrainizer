local _, ns = ...;

local aceHook = LibStub("AceHook-3.0")

local translator = class("MainFrameTranslator", ns.Translators.BaseTranslator)
ns.Translators.MainFrameTranslator = translator

local function getTranslationOrDefault(default)
    return ns.DbContext.Frames.GetTranslationOrDefault("main", default)
end

local function microButtonTooltipTextWrapper(text, action)
    return aceHook.hooks["MicroButtonTooltipText"](getTranslationOrDefault(text), action)
end

function translator:initialize()
    for i = 1, GameMenuFrame:GetNumChildren() do
        local element = select(i, GameMenuFrame:GetChildren())
        if element and element:IsObjectType("Button") and element.GetText then
            element:SetText(getTranslationOrDefault(element:GetText()))
        end
    end

    GameMenuFrame.Header.Text:SetText(getTranslationOrDefault(GameMenuFrame.Header.Text:GetText()))

    aceHook:RawHook("MicroButtonTooltipText", microButtonTooltipTextWrapper, true)

    CharacterMicroButton.tooltipText = microButtonTooltipTextWrapper(CHARACTER_BUTTON, "TOGGLECHARACTER0");
    TalentMicroButton.tooltipText = microButtonTooltipTextWrapper(TALENTS_BUTTON, "TOGGLETALENTS");
    SpellbookMicroButton.tooltipText = microButtonTooltipTextWrapper(SPELLBOOK_ABILITIES_BUTTON, "TOGGLESPELLBOOK");
    AchievementMicroButton.tooltipText = microButtonTooltipTextWrapper(ACHIEVEMENT_BUTTON, "TOGGLEACHIEVEMENT");
    QuestLogMicroButton.tooltipText = microButtonTooltipTextWrapper(QUESTLOG_BUTTON, "TOGGLEQUESTLOG");
    LFDMicroButton.tooltipText = microButtonTooltipTextWrapper(DUNGEONS_BUTTON, "TOGGLEGROUPFINDER");
    CollectionsMicroButton.tooltipText = microButtonTooltipTextWrapper(COLLECTIONS, "TOGGLECOLLECTIONS");
    EJMicroButton.tooltipText = microButtonTooltipTextWrapper(ENCOUNTER_JOURNAL, "TOGGLEENCOUNTERJOURNAL");
    StoreMicroButton.tooltipText = getTranslationOrDefault(BLIZZARD_STORE);
end
