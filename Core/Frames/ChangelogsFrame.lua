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
    local function SetTextToFit(fontString, text, maxWidth)
        fontString:SetHeight(200);
        fontString:SetText(text);
        fontString:SetWidth(maxWidth);
        fontString:SetHeight(fontString:GetStringHeight());
    end

    local versionText = "Версія " .. elementData.version .. " |cff9A97B9(" .. elementData.date .. ")|r"
    if (elementData.title ~= nil) then
        versionText = versionText .. " - " .. elementData.title
    end
    self.Title:SetText(versionText)
    self.CheckMark:SetVertexColor(unpack(colors[elementData.sections[1].color]));

    local contentWidth = self:GetParent():GetWidth() - 32
    local previousAnchor = self.Title
    local sectionsHeight = 0

    for i, section in ipairs(elementData.sections) do
        local typeText = self:CreateFontString(nil, "OVERLAY", "ChangelogEntryButton_TypeTextFont")
        local sectionTopOffset = (i == 1) and -18 or -24
        typeText:SetPoint("TOPLEFT", previousAnchor, "BOTTOMLEFT", 4, sectionTopOffset)
        typeText:SetText(section.type)

        local typeBg = self:CreateTexture(nil, "BACKGROUND")
        typeBg:SetColorTexture(unpack(colors[section.color]))
        typeBg:SetPoint("TOPLEFT", typeText, "TOPLEFT", -6, 6)
        typeBg:SetPoint("BOTTOMRIGHT", typeText, "BOTTOMRIGHT", 6, -6)

        local typeLine = self:CreateTexture(nil, "BACKGROUND")
        typeLine:SetHeight(2)
        typeLine:SetColorTexture(unpack(colors[section.color]))
        typeLine:SetPoint("LEFT", typeBg, "BOTTOMRIGHT", 0, 1)
        typeLine:SetPoint("RIGHT", self, "RIGHT", -16, 0)

        local authorText = self:CreateFontString(nil, "OVERLAY", "ChangelogEntryButton_SecondaryBoldTextFont")
        authorText:SetPoint("TOPLEFT", typeText, "TOPRIGHT", 10, 0)
        authorText:SetText("Автор: " .. section.author)

        local descText = self:CreateFontString(nil, "OVERLAY", "ChangelogEntryButton_TextFont")
        descText:SetJustifyH("LEFT")
        descText:SetWordWrap(true)
        descText:SetPoint("TOPLEFT", typeText, "BOTTOMLEFT", -4, -12)
        SetTextToFit(descText, section.description, contentWidth)

        sectionsHeight = sectionsHeight + math.abs(sectionTopOffset) + typeText:GetHeight() + 12 + descText:GetHeight()
        previousAnchor = descText
    end

    local headerHeight = 6 + self.Title:GetHeight()
    self:SetWidth(self:GetParent():GetWidth());
    self:SetHeight(math.floor(headerHeight + sectionsHeight + 10));
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

function WowUkrainizerChangelogsFrameMixin:OnLoad()
    self:SetupChangelogs();
    self.ScrollFrame:UpdateScrollChildRect();
end

function WowUkrainizerChangelogsFrameMixin:OnShow()
    self:SetSize(800, 600)
end

function WowUkrainizerChangelogsFrameMixin:ToggleUI()
    if not self:IsVisible() then
        self:Show()
    else
        self:Hide()
    end
end
