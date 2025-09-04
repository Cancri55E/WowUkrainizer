local ns = select(2, ...);

local GetTranslatedQuestTitle = ns.DbContext.Quests.GetTranslatedQuestTitle;
local GetTranslatedQuestData = ns.DbContext.Quests.GetTranslatedQuestData;

_G.WowUkrainizer_GetTranslatedQuestTitle = GetTranslatedQuestTitle;
_G.WowUkrainizer_GetTranslatedQuestData = GetTranslatedQuestData;