--- @class WowUkrainizerInternals
local ns = select(2, ...);

local UpdateTextWithTranslation = ns.FontStringUtil.UpdateTextWithTranslation
local GetWhatsNewFrameInfo = ns.DbContext.Frames.GetWhatsNewFrameInfo
local GetTranslatedGlobalString = ns.DbContext.GlobalStrings.GetTranslatedGlobalString

---@class SplashFrameTranslator : BaseTranslator
local translator = setmetatable({}, { __index = ns.BaseTranslator })

function translator:IsEnabled()
    return true
end

local function SaveToIngameDataCache(clientVersion, screenInfo)
    local splashFrameCategory
    if (screenInfo.screenType == Enum.SplashScreenType.WhatsNew) then
        splashFrameCategory = ns.IngameDataCacher:GetOrAddCategory({ "splash_frame", "whats_new", clientVersion })
    elseif (screenInfo.screenType == Enum.SplashScreenType.SeasonRollOver) then
        splashFrameCategory = ns.IngameDataCacher:GetOrAddCategory({ "splash_frame", "season_roll_over", clientVersion })
    end
    ns.IngameDataCacher:GetOrAddToCategory(splashFrameCategory, "name", {
        header = screenInfo.header,
        topLeftFeatureTitle = screenInfo.topLeftFeatureTitle,
        topLeftFeatureDesc = screenInfo.topLeftFeatureDesc,
        bottomLeftFeatureTitle = screenInfo.bottomLeftFeatureTitle,
        bottomLeftFeatureDesc = screenInfo.bottomLeftFeatureDesc,
        rightFeatureTitle = screenInfo.rightFeatureTitle,
        rightFeatureDesc = screenInfo.rightFeatureDesc,
    })
end

function translator:Init()
    UpdateTextWithTranslation(SplashFrame.BottomCloseButton.Text, GetTranslatedGlobalString)
    UpdateTextWithTranslation(SplashFrame.RightFeature.StartQuestButton.Text, GetTranslatedGlobalString)
    hooksecurefunc(SplashFrame, "SetupFrame", function(frame, screenInfo)
        if (not screenInfo) then return end
        UpdateTextWithTranslation(frame.Header, GetTranslatedGlobalString)

        if (screenInfo.screenType == Enum.SplashScreenType.SeasonRollOver) then return end

        local clientVersion = GetBuildInfo()
        local translatedScreenInfo = GetWhatsNewFrameInfo(clientVersion)
        if (not translatedScreenInfo) then return end

        frame.Label:SetText(translatedScreenInfo.header);
        frame.TopLeftFeature:Setup(translatedScreenInfo.topLeftFeatureTitle, translatedScreenInfo.topLeftFeatureDesc);
        frame.BottomLeftFeature:Setup(translatedScreenInfo.bottomLeftFeatureTitle, translatedScreenInfo.bottomLeftFeatureDesc);
        frame.RightFeature.Title:SetText(translatedScreenInfo.rightFeatureTitle);
        frame.RightFeature.Description:SetText(translatedScreenInfo.rightFeatureDesc);
    end)
end

ns.TranslationsManager:AddTranslator(translator)
