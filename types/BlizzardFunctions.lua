---@meta
-- Blizzard-owned global functions used by the addon.
-- Signatures are strict where known; loose `fun(...)` with TODO otherwise.

-- Tooltip helpers
---@return GameTooltip
function GetAppropriateTooltip() end

---@param frame Frame
---@return Frame
function GetAppropriateTopLevelParent(frame) end

---@param tooltip GameTooltip
function GameTooltip_Hide(tooltip) end

---@param tooltip GameTooltip
---@param parent Frame?
function GameTooltip_SetDefaultAnchor(tooltip, parent) end

---@param tooltip GameTooltip
---@param title string
---@param color ColorMixin?
---@param wrap boolean?
function GameTooltip_SetTitle(tooltip, title, color, wrap) end

---@param tooltip GameTooltip
---@param text string
---@param wrap boolean?
---@param leftOffset number?
function GameTooltip_AddBodyLine(tooltip, text, wrap, leftOffset) end

---@param tooltip GameTooltip
---@param text string
function GameTooltip_AddErrorLine(tooltip, text) end

---@param tooltip GameTooltip
---@param text string
function GameTooltip_AddInstructionLine(tooltip, text) end

---@param tooltip GameTooltip
---@param text string
---@param color ColorMixin
function GameTooltip_AddColoredLine(tooltip, text, color) end

-- TODO: tighten signatures below
function GameTooltip_ShowCompareItem(...) end
function GameTooltip_CheckAddQuestTimeToTooltip(...) end
function SharedTooltip_SetBackdropStyle(...) end

function QuestUtils_AddQuestTagLineToTooltip(...) end
function QuestUtils_GetNumPartyMembersOnQuest(...) end
function QuestUtils_GetReplayQuestDecoration(...) end
function QuestUtils_GetDisabledQuestDecoration(...) end
function QuestUtils_GetQuestTagAtlas(...) end
function QuestUtils_DecorateQuestText(...) end

function QuestInfo_Display(...) end
function QuestFrameProgressPanel_OnShow(...) end
function QuestMapFrame_GetFocusedQuestID(...) end

-- UIDropDownMenu
---@param info table
---@param level integer?
function UIDropDownMenu_AddButton(info, level) end

function UIDropDownMenu_SetWidth(...) end
function UIDropDownMenu_SetButtonWidth(...) end
function UIDropDownMenu_JustifyText(...) end
function UIDropDownMenu_SetSelectedID(...) end
function UIDropDownMenu_CreateInfo() end
function UIDropDownMenu_Initialize(...) end
function UIDropDownMenu_SetText(...) end
function UIDropDownMenu_SetAnchor(...) end
function UIDropDownMenu_SetSelectedValue(...) end
function ToggleDropDownMenu(...) end

-- Panel templates
function PanelTemplates_GetSelectedTab(...) end
function PanelTemplates_SetNumTabs(...) end
function PanelTemplates_SetTab(...) end

-- Static popup
function StaticPopup_Show(...) end
function StaticPopup_Resize(...) end
function StaticPopup_HideExclusive(...) end
function StaticPopup_FindVisible(...) end
function StaticPopup_GetDialog(...) end

-- Spellbook
function SpellBook_GetSpellBookSlot(...) end

-- UI / misc
function ReloadUI() end
function ExecuteFrameScript(...) end
---@param texture Texture
---@param desaturate boolean?
function SetDesaturation(texture, desaturate) end
---@param name string
---@return any
function getglobal(name) end
---@param unit string
---@return string?, string?
function GetUnitName(unit, showServerName) end
function GenerateClosure(...) end
function CreateMinimalSliderFormatter(...) end
function CreateScrollBoxListLinearView(...) end
function CreateDataProvider(...) end
function CreateAnchor(...) end

function OpenColorPicker(...) end
function ColorPicker_GetPreviousValues(...) end

function InterfaceOptions_AddCategory(...) end
function InterfaceOptionsFrame_OpenToCategory(...) end
function ChatFrame_AddMessageEventFilter(...) end

function CompactUnitFrame_UpdateName(...) end
---@param frame Frame
---@return boolean
function ShouldShowName(frame) end
---@return boolean
function ShouldShowMawBuffs() end

---@param money integer
---@param separateThousands boolean?
---@return string
function GetMoneyString(money, separateThousands) end
function MoneyFrame_Update(...) end
function FormatBindingKeyIntoText(...) end
function PaperDollFrame_SetLabelAndText(...) end

function MovieFrame_PlayMovie(...) end
function MovieFrame_OnShow(...) end
function MicroButtonTooltipText(...) end
function ItemSocketingFrame_OnLoad(...) end
function GearSetButton_OnEnter(...) end

-- HybridScrollFrame helpers
function HybridScrollFrame_SetDoNotHideScrollBar(...) end
function HybridScrollFrame_CreateButtons(...) end
function HybridScrollFrame_Update(...) end
function HybridScrollFrame_GetButtons(...) end
function HybridScrollFrame_GetOffset(...) end

-- NavBar
function NavBar_OverflowItemOnClick(...) end
function NavBar_ClearTrailingButtons(...) end
