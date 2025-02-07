--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GetTranslatedQuestTitle = ns.DbContext.Quests.GetTranslatedQuestTitle

---@class DialogueUITranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

local function Initialize()
    hooksecurefunc(DUIQuestFrame, "UpdateQuestTitle", function(frame)
        local title = frame.FrontFrame.Header.Title
        title:SetText(GetTranslatedQuestTitle(frame.questID));
    end)
end

function translator:Init()
    Initialize()
end

ns.TranslationsManager:AddTranslator(translator)
