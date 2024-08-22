--- @type string, WowUkrainizerInternals
local _, ns = ...;

local colors = {
    red = { 0.902, 0.035, 0.369, 1.0 },
    green = { 0.271, 0.561, 0.094, 1.0 },
    blue = { 0.188, 0.412, 0.996, 1.0 },
    purple = { 0.541, 0.212, 0.706, 1.0 },
    legendary = { 0.922, 0.502, 0, 1.0 },
}

local localFrame = CreateFrame("Frame", nil, UIParent)
localFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")

WowUkrainizerChangelogsFrameMixin = {}

function WowUkrainizerChangelogsFrameMixin:OnLoad()
    self.items = ns._db.Changelogs

    self:SetUserPlaced(true)
    self:SetResizeBounds(535, 400, 535, UIParent:GetHeight())

    self.scrollFrame.update = function() self:RefreshLayout(); end

    HybridScrollFrame_SetDoNotHideScrollBar(self.scrollFrame, true);
end

function WowUkrainizerChangelogsFrameMixin:OnShow()
    HybridScrollFrame_CreateButtons(self.scrollFrame, "WowUkrainizerChangelogEntryTemplate");
    self:RefreshLayout();
end

function WowUkrainizerChangelogsFrameMixin:RefreshLayout()
    ---@param changelog ChangelogEntry
    local function _updateButton(button, itemIndex, changelog)
        button:SetID(itemIndex);

        if (changelog.title ~= nil) then
            button.Title:SetText("Версія " .. changelog.version .. " - " .. changelog.title)
        else
            button.Title:SetText("Версія " .. changelog.version)
        end
        button.Date:SetText(changelog.date)
        button.CheckMark:SetVertexColor(unpack(colors[changelog.color]));
        button.TypeBackground:SetColorTexture(unpack(colors[changelog.color]));
        button.Type:SetText(changelog.type)
        button.Author:SetText("Автор: " .. changelog.author)
        button.Text:SetText(changelog.description)

        button:SetWidth(self.scrollFrame.scrollChild:GetWidth());
        button:SetHeight(math.floor(button.Text:GetHeight() + 80));
    end

    local offset = HybridScrollFrame_GetOffset(self.scrollFrame)
    local totalChanglogsCount = #self.items

    local totalHeight = 0
    for itemIndex = 1, totalChanglogsCount do
        self.CalculatedTextHook:SetText(self.items[itemIndex].description)
        totalHeight = totalHeight + math.floor(self.CalculatedTextHook:GetHeight() + 80)
    end

    local shownHeight = 0
    local scrollFrameHeight = self.scrollFrame:GetHeight()
    local counter = 1
    for buttonIndex, button in pairs(self.scrollFrame.buttons) do
        local indexPlusOffset = buttonIndex + offset;
        if indexPlusOffset <= totalChanglogsCount and shownHeight < scrollFrameHeight then
            _updateButton(button, offset + counter, self.items[offset + counter])
            shownHeight = shownHeight + button:GetHeight()
            counter = counter + 1
            button:Show();
        else
            button:Hide();
        end
    end

    HybridScrollFrame_Update(self.scrollFrame, totalHeight, shownHeight);
end

function WowUkrainizerChangelogsFrameMixin:ToggleUI()
    if not self:IsVisible() then
        self:Show()
    else
        self:Hide()
    end
end
