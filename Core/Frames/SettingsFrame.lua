local _, ns = ...;

local WOW_UKRAINIZER_SETTING_FRAME_WARNING_TEXT =
[[Увага!
Зміни в налаштуваннях будуть застосовані тільки після перезавантаження інтерфейсу або виконання команди /reload.
Будь ласка, зверніть увагу, що без цього кроку нові налаштування не вступлять в силу.]]

WowUkrainizerSettingsFrameMixin = {}

function WowUkrainizerSettingsFrameMixin:OnLoad()
    local PaneBackdrop = {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 5, bottom = 3 }
    }
    self.SettingsFrame:SetBackdrop(PaneBackdrop)
    self.SettingsFrame:SetFrameStrata(self:GetFrameStrata(), self:GetFrameLevel() + 1)
    self.SettingsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    self.SettingsFrame:SetBackdropBorderColor(0.4, 0.4, 0.4)

    self.WarningFrame:SetBackdrop(PaneBackdrop)
    self.WarningFrame:SetFrameStrata(self:GetFrameStrata(), self:GetFrameLevel() + 1)
    self.WarningFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    self.WarningFrame:SetBackdropBorderColor(0.4, 0.4, 0.4)

    self.WarningFrame.WarningText:SetText(WOW_UKRAINIZER_SETTING_FRAME_WARNING_TEXT)

    self.Version:SetText(ns.CommonData.VesionStr)

    PanelTemplates_SetNumTabs(self, 2)
    PanelTemplates_SetTab(self, 1)
    self:ChangeTab(1)
end

function WowUkrainizerSettingsFrameMixin:SelectTab(tabButton)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    self:ChangeTab(tabButton:GetID());
end

function WowUkrainizerSettingsFrameMixin:ChangeTab(tabID)
    PanelTemplates_SetTab(self, tonumber(tabID));
    if tabID == 1 then
        self.SettingsFrame.SettingsScrollFrame.SettingsScrollChildFrame.ModuleSettingsFrame:Show()
        self.SettingsFrame.SettingsScrollFrame.SettingsScrollChildFrame.TooltipSettingsFrame:Show()
        self.SettingsFrame.SettingsScrollFrame.SettingsScrollChildFrame.FontSettingsFrame:Hide()
    elseif tabID == 2 then
        self.SettingsFrame.SettingsScrollFrame.SettingsScrollChildFrame.ModuleSettingsFrame:Hide()
        self.SettingsFrame.SettingsScrollFrame.SettingsScrollChildFrame.TooltipSettingsFrame:Hide()
        self.SettingsFrame.SettingsScrollFrame.SettingsScrollChildFrame.FontSettingsFrame:Show()
    end
end

function WowUkrainizerSettingsFrameMixin:ShowChangelogs()
    ns.Frames["ChangelogsFrame"]:ToggleUI()
end
