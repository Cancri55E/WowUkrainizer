local _, ns = ...;

local GenerateUuid = ns.CommonExtensions.GenerateUuid
local GetMovieSubtitle = ns.DbContext.Subtitles.GetMovieSubtitle
local GetCinematicSubtitle = ns.DbContext.NpcDialogs.GetCinematicSubtitle
local GetUnitNameOrDefault = ns.DbContext.Units.GetUnitNameOrDefault

local eventHandler = ns.EventHandler:new()

local translator = class("MovieTranslator", ns.Translators.BaseTranslator)
ns.Translators.MovieTranslator = translator

function translator:initialize()
    ns.Translators.BaseTranslator.initialize(self)

    local instance = self
    instance.currentMovieId = 0
    instance.untranslatedDataStorage = ns.UntranslatedDataStorage:new()

    eventHandler:Register(function(event, movieID)
        if (event == "PLAY_MOVIE") then
            instance.playMovie = true
            instance.playCinematic = false
            instance.movieID = movieID
        else
            instance.playMovie = false
            instance.movieID = nil
        end
    end, "PLAY_MOVIE", "STOP_MOVIE")

    eventHandler:Register(function(event)
        instance.movieID = nil
        if (event == "CINEMATIC_START") then
            instance.playMovie = false
            instance.playCinematic = true
            instance.cinematicUuid = GenerateUuid()
            instance.subtitleOrder = 0
        else
            instance.playCinematic = false
            instance.cinematicUuid = ''
            instance.subtitleOrder = -1
        end
    end, "CINEMATIC_START", "CINEMATIC_STOP")

    eventHandler:Register(function(_, message, sender)
        local function translateMessage()
            if (instance.playCinematic) then
                return GetCinematicSubtitle(message)
            elseif (instance.playMovie) then
                return GetMovieSubtitle(message)
            else
                return message
            end
        end

        local translatedMessage = translateMessage()
        local body = translatedMessage
        if sender then
            local translatedSender = GetUnitNameOrDefault(sender)
            body = format(SUBTITLE_FORMAT, translatedSender, translatedMessage);
        end

        if (instance.playMovie and instance.movieID ~= 0) then
            instance.untranslatedDataStorage:GetOrAdd("MovieSubtitles", instance.movieID, message)
        end
        if (instance.playCinematic) then
            if (translatedMessage == message) then
                local untranslatedData = instance.untranslatedDataStorage:GetOrAdd("NpcMessages", sender, message)
                untranslatedData.cinematicUuid = instance.cinematicUuid
                untranslatedData.subtitleOrder = instance.subtitleOrder
            end
            instance.subtitleOrder = instance.subtitleOrder + 1
        end

        local fontString
        for _, value in pairs(SubtitlesFrame.Subtitles) do
            if (value:IsShown()) then
                fontString = value
            end
        end

        if (not fontString) then return end

        fontString:SetText(body)
    end, "SHOW_SUBTITLE")

    hooksecurefunc("MovieFrame_PlayMovie", function(_, movieID)
        instance.playMovie = true
        instance.playCinematic = false
        instance.movieID = movieID
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

    for _, region in ipairs({ CinematicFrame.closeDialog:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            if (region:GetText() == _G["CONFIRM_CLOSE_CINEMATIC"]) then
                region:SetText("Ви впевнені, що хочете закрити це відео?")
            end
        end
    end

    for i = 1, CinematicFrame.closeDialog:GetNumChildren() do
        local element = select(i, CinematicFrame.closeDialog:GetChildren())
        if (element and element["GetText"] and element["SetText"]) then
            if (element:IsObjectType("Button")) then
                if (element:GetText() == "Yes") then
                    element:SetText("Так")
                elseif (element:GetText() == "No") then
                    element:SetText("Ні")
                end
            end
        end
    end
end
