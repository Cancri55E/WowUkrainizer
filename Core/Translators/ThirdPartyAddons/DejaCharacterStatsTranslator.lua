--- @type string, WowUkrainizerInternals
local _, ns = ...;

local IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION = ns.IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION

local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation

local GetTranslatedSpellName = ns.DbContext.Spells.GetTranslatedSpellName
local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName
local GetTranslatedGossipText = ns.DbContext.Gossips.GetTranslatedGossipText
local GetTranslatedGossipOptionText = ns.DbContext.Gossips.GetTranslatedGossipOptionText
local GetTranslatedQuestTitle = ns.DbContext.Quests.GetTranslatedQuestTitle
local GetTranslatedQuestData = ns.DbContext.Quests.GetTranslatedQuestData
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString
local CreateSwitchTranslationButton = ns.QuestFrameUtil.CreateSwitchTranslationButton
local CreateMtIconTexture = ns.QuestFrameUtil.CreateMtIconTexture
local CreateWowheadButton = ns.QuestFrameUtil.CreateWowheadButton

local immersionTitleOriginal, immersionTextOriginal, immersionObjectivesTextOriginal

local immersionFrameSwitchTranslationButton, immersionFrameMTIcon, immersionWowheadButton

---@class DejaCharacterStatsTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

ns.TranslationsManager:AddTranslator(translator)
