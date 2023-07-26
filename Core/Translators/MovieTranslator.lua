local _, ns = ...;

local untranslatedDataStorage = ns.UntranslatedDataStorage:new()
local aceHook = LibStub("AceHook-3.0")
local GetMovieSubtitle = ns.DbContext.Subtitles.GetMovieSubtitle

local translator = class("MovieTranslator", ns.Translators.BaseTranslator)
ns.Translators.MovieTranslator = translator

function translator:initialize()
    ns.Translators.BaseTranslator.initialize(self)

    local trans = self
    trans.currentMovieId = 0

    aceHook:RawHook("MovieFrame_PlayMovie", function(movieFrame, movieID)
        trans.currentMovieId = tonumber(movieID)
        aceHook.hooks["MovieFrame_PlayMovie"](movieFrame, movieID)
    end, true)

    MovieFrame:HookScript("OnMovieShowSubtitle", function(_, text)
        if (trans.currentMovieId ~= 0) then
            untranslatedDataStorage:GetOrAdd("MovieSubtitles", trans.currentMovieId, text)
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
