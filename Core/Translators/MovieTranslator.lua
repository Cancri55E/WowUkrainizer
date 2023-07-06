local _, ns = ...;

local aceHook = LibStub("AceHook-3.0")
local GetMovieSubtitle = ns.DbContext.Subtitles.GetMovieSubtitle

local translator = class("MovieTranslator", ns.Translators.BaseTranslator)
ns.Translators.MovieTranslator = translator

local function addSubtitleToUntranslatedData(self, row)
    local function isValueInTable(t, value) -- TODO: Move to extension
        for _, v in ipairs(t) do
            if v == value then
                return true
            end
        end
        return false
    end

    local movieId = self.currentMovieId
    if (not _G.WowUkrainizerData) then _G.WowUkrainizerData = {} end
    if (not _G.WowUkrainizerData.UntranslatedData) then _G.WowUkrainizerData.UntranslatedData = {} end
    if (not _G.WowUkrainizerData.UntranslatedData.MovieSubtitles) then _G.WowUkrainizerData.UntranslatedData.MovieSubtitles = {} end
    if (not _G.WowUkrainizerData.UntranslatedData.MovieSubtitles[movieId]) then _G.WowUkrainizerData.UntranslatedData.MovieSubtitles[movieId] = {} end

    local categoryTable = _G.WowUkrainizerData.UntranslatedData.MovieSubtitles[movieId]

    if (not isValueInTable(categoryTable, row)) then table.insert(categoryTable, row) end
end

function translator:initialize()
    ns.Translators.BaseTranslator.initialize(self)

    local currentTranslator = self
    currentTranslator.currentMovieId = 0

    aceHook:RawHook("MovieFrame_PlayMovie", function(movieFrame, movieID)
        currentTranslator.currentMovieId = tonumber(movieID)
        aceHook.hooks["MovieFrame_PlayMovie"](movieFrame, movieID)
    end, true)

    MovieFrame:HookScript("OnMovieShowSubtitle", function(_, text)
        if (currentTranslator.currentMovieId ~= 0) then
            addSubtitleToUntranslatedData(currentTranslator, text)
        end
        MovieFrameSubtitleString:SetText(GetMovieSubtitle(text))
    end)

    for _, region in ipairs({ MovieFrame.CloseDialog:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            if (region:GetText() == _G["CONFIRM_CLOSE_CINEMATIC"]) then
                region:SetText("Ви впевнені, що хочете закрити це відео?")
            end
        end
    end
    MovieFrame.CloseDialog.ConfirmButton:SetText("Так")
    MovieFrame.CloseDialog.ResumeButton:SetText("Ні")
end
