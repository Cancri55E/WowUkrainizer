--- @type string, WowUkrainizerInternals
local _, ns = ...;

local colors = {
    red = { 0.902, 0.035, 0.369, 1.0 },
    green = { 0.271, 0.561, 0.094, 1.0 },
    blue = { 0.188, 0.412, 0.996, 1.0 },
    purple = { 0.541, 0.212, 0.706, 1.0 },
    legendary = { 0.922, 0.502, 0, 1.0 },
}

WowUkrainizerChangelogEntryMixin = {}

function WowUkrainizerChangelogEntryMixin:InitilizeButton(elementData, index)
    local function SetTextToFit(fontString, text, maxWidth, multiline)
        fontString:SetHeight(200);
        fontString:SetText(text);

        fontString:SetWidth(maxWidth);
        if not multiline then
            fontString:SetWidth(fontString:GetStringWidth());
        end

        fontString:SetHeight(fontString:GetStringHeight());
    end

    if (elementData.title ~= nil) then
        self.Title:SetText("Версія " .. elementData.version .. " - " .. elementData.title)
    else
        self.Title:SetText("Версія " .. elementData.version)
    end
    self.Date:SetText(elementData.date)
    self.CheckMark:SetVertexColor(unpack(colors[elementData.color]));
    self.TypeBackground:SetColorTexture(unpack(colors[elementData.color]));
    self.Type:SetText(elementData.type)
    self.Author:SetText("Автор: " .. elementData.author)

    SetTextToFit(self.Text, elementData.description, self:GetParent():GetWidth() - 32, true)

    self:SetWidth(self:GetParent():GetWidth());
    self:SetHeight(math.floor(self.Text:GetHeight() + 80));
    self:Show();
end

WowUkrainizerChangelogsFrameMixin = {}

function WowUkrainizerChangelogsFrameMixin:SetupChangelogs()
    local parent = self.ScrollFrame.ScrollChild

    local buttons = {};
    for index, data in ipairs(ns._db.Changelogs) do
        local button = CreateFrame("Frame", "WowUkrainizerChangeLogEntry" .. index, parent, "WowUkrainizerChangelogEntryButtonTemplate", index);
        button:InitilizeButton(data, index);

        table.insert(buttons, button);

        if (index == 1) then
            button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -4)
        else
            button:SetPoint("TOPLEFT", buttons[index - 1], "BOTTOMLEFT", 0, -8)
        end
    end
end

function WowUkrainizerChangelogsFrameMixin:OnShow()
    DevTool:AddData(self.ScrollFrame.ScrollChild)
end

function WowUkrainizerChangelogsFrameMixin:OnLoad()
    self:SetupChangelogs();
    self.ScrollFrame:UpdateScrollChildRect();
end

function WowUkrainizerChangelogsFrameMixin:ToggleUI()
    if not self:IsVisible() then
        self:Show()
    else
        self:Hide()
    end
end
