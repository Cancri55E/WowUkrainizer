--- @type string, WowUkrainizerInternals
local _, ns = ...;

-- WowUkrainizerCheckButtonMixin
do
    WowUkrainizerCheckButtonMixin = { BehaveAsRadioButton = false }

    function WowUkrainizerCheckButtonMixin:OnClick()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
        local checked = self:GetChecked()
        if (not checked and self.BehaveAsRadioButton) then
            self:SetChecked(true)
            return
        end
        self:SetOption(checked)
        self:GetParent():OnCheckButtonChecked(self, checked);
    end

    function WowUkrainizerCheckButtonMixin:SetOption(checked)
        local optionName = self:GetAttribute("optionName")
        if (optionName) then
            ns.SettingsProvider.SetOption(_G[optionName], checked)
        end
    end

    function WowUkrainizerCheckButtonMixin:EnableHook()
        self:Enable()
        self.Text:SetTextColor(WOW_UKRAINIZER_WHITE_COLOR.r, WOW_UKRAINIZER_WHITE_COLOR.g,
            WOW_UKRAINIZER_WHITE_COLOR.b)
    end

    function WowUkrainizerCheckButtonMixin:DisableHook()
        self:Disable()
        self.Text:SetTextColor(WOW_UKRAINIZER_DISABLED_COLOR.r, WOW_UKRAINIZER_DISABLED_COLOR.g,
            WOW_UKRAINIZER_DISABLED_COLOR.b)
    end
end

-- WowUkrainizerUrlFrameMixin
do
    local wizardTooltip = CreateFrame("GameTooltip", "WowUkrainizer-Wizard-Tooltip", UIParent, "GameTooltipTemplate")


    WowUkrainizerUrlFrameMixin = CreateFromMixins(CallbackRegistryMixin);
    WowUkrainizerUrlFrameMixin._url = ""

    local function OnUrlEnter(self)
        wizardTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        wizardTooltip:SetText("Виділити")
        wizardTooltip:AddLine("Натисніть, щоб виділити цю URL-адресу.", 1, 1, 1)
        wizardTooltip:Show()
    end

    local function OnUrlLeave(_)
        wizardTooltip:Hide()
    end

    local function OnCopyUrlBoxEnter(self)
        wizardTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        wizardTooltip:SetText("Копіювати")
        wizardTooltip:AddLine("Натисніть |cffffcc00CTRL+C|r, щоб скопіювати текст.", 1, 1, 1)
        wizardTooltip:AddLine("Натисніть |cffffcc00ESC|r, щоб скасувати.", 1, 1, 1)
        wizardTooltip:Show()
    end

    local function OnCopyUrlBoxLeave(_)
        wizardTooltip:Hide()
    end

    local function OnCopyUrlBoxFocusGained(self)
        self:HighlightText()
        self:SetCursorPosition(0)
    end

    local function OnCopyUrlBoxFocusLost(self)
        self:GetParent().Url:Show()
        self:Hide()
    end

    local function OnCopyUrlBoxTextChanged(self)
        self:SetText(self:GetParent()._url)
        OnCopyUrlBoxFocusGained(self)
    end

    function WowUkrainizerUrlFrameMixin:OnMouseDown()
        self.CopyUrlBox:Show()
        self.CopyUrlBox:SetFocus()

        self.Url:Hide()
    end

    function WowUkrainizerUrlFrameMixin:OnLoad()
        self.CopyUrlBox:SetAutoFocus(true)
        self.CopyUrlBox:SetFontObject("WowUkrainizerFramePrimaryTextFont")
        self.CopyUrlBox:SetHeight(14)
        self.CopyUrlBox:SetJustifyH("LEFT")
        self.CopyUrlBox:SetJustifyV("TOP")
        self.CopyUrlBox:SetTextInsets(2, 1, 1, 1)

        self.CopyUrlBox:SetScript("OnEnter", OnCopyUrlBoxEnter)
        self.CopyUrlBox:SetScript("OnLeave", OnCopyUrlBoxLeave)
        self.CopyUrlBox:SetScript("OnTextChanged", OnCopyUrlBoxTextChanged)
        self.CopyUrlBox:SetScript("OnEnterPressed", self.CopyUrlBox.ClearFocus)
        self.CopyUrlBox:SetScript("OnEscapePressed", self.CopyUrlBox.ClearFocus)
        self.CopyUrlBox:SetScript("OnEditFocusLost", OnCopyUrlBoxFocusLost)
        self.CopyUrlBox:SetScript("OnEditFocusGained", OnCopyUrlBoxFocusGained)

        self.Url:SetScript("OnEnter", OnUrlEnter)
        self.Url:SetScript("OnLeave", OnUrlLeave)
    end

    function WowUkrainizerUrlFrameMixin:SetValue(title, url, titleWidth)
        self._url = url;
        self.Url:SetText(url)

        self.Title:SetText(title)
        if (titleWidth) then
            self.Title:SetWidth(titleWidth)
        end

        self.CopyUrlBox:SetText(self._url)
        self.CopyUrlBox:SetWidth(self.Url:GetStringWidth() + 16);

        local multiLine = ((self.Url:GetStringHeight() > 14) and true) or false
        self.CopyUrlBox:SetMultiLine(multiLine)
    end
end

-- WowUkrainizerInfoFrameMixin
do
    WowUkrainizerInfoFrameMixin = CreateFromMixins(CallbackRegistryMixin);

    function WowUkrainizerInfoFrameMixin:SetInfo(title, text, titleWidth, textWidth)
        self.Title:SetText(title)
        if (titleWidth) then
            self.Title:SetWidth(titleWidth)
        end
        self.Info:SetText(text)
        self.Info:SetTextColor(WOW_UKRAINIZER_WHITE_COLOR.r, WOW_UKRAINIZER_WHITE_COLOR.g,
            WOW_UKRAINIZER_WHITE_COLOR.b)
        if (textWidth) then
            self.Info:SetWidth(textWidth)
        end
    end
end
