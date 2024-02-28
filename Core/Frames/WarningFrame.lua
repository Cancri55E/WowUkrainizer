--- @type string, WowUkrainizerInternals
local _, ns = ...;

WowUkrainizerWarningFrameMixin = {}

function WowUkrainizerWarningFrameMixin:ShowWarning(title, msg, height)
    if (title) then
        self.Title:SetText(title)
    end

    if (msg) then
        self.Message:SetText(msg)
    end

    if (height) then
        self:SetHeight(height)
    end

    self:Show()
end
