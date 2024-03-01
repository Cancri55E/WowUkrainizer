--- @class WowUkrainizerInternals
local ns = select(2, ...);

local GenerateUuid = ns.CommonUtil.GenerateUuid
local GetTranslatedMovieSubtitle = ns.DbContext.Subtitles.GetTranslatedMovieSubtitle
local GetTranslatedCinematicSubtitle = ns.DbContext.NpcDialogs.GetTranslatedCinematicSubtitle
local GetTranslatedUnitName = ns.DbContext.Units.GetTranslatedUnitName

local eventHandler = ns.EventHandlerFactory.CreateEventHandler()
local settingsProvider = ns:GetSettingsProvider()
local untranslatedDataStorage = ns:GetUntranslatedDataStorage()

---@class SubtitlesTranslator : BaseTranslator
---@field playCinematic boolean
---@field playMovie boolean
---@field movieID integer?
---@field cinematicUuid string?
---@field subtitleOrder integer
local translator = setmetatable({
    playCinematic = false,
    playMovie = false,
    movieID = nil,
    cinematicUuid = nil,
    subtitleOrder = -1
}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return settingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_SUBTITLES_OPTION)
end

function translator:Init()
    local instance = self --[[@as SubtitlesTranslator]]

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
                return GetTranslatedCinematicSubtitle(message)
            elseif (instance.playMovie) then
                return GetTranslatedMovieSubtitle(message)
            else
                return message
            end
        end

        local translatedMessage = translateMessage()
        local body = translatedMessage
        if sender then
            local translatedSender = GetTranslatedUnitName(sender)
            body = format(SUBTITLE_FORMAT, translatedSender, translatedMessage);
        end

        if (instance.playMovie and instance.movieID and instance.movieID ~= 0) then
            untranslatedDataStorage:GetOrAdd("MovieSubtitles", tostring(instance.movieID), message)
        end
        if (instance.playCinematic) then
            if (translatedMessage == message) then
                local untranslatedData = untranslatedDataStorage:GetOrAdd("NpcMessages", sender, message)
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

ns.TranslationsManager:AddTranslator(translator)
