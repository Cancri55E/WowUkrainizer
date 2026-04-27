---@meta
-- Blizzard-owned mixin tables, utility namespaces, and singleton data tables.
-- Typed as `table` (or `ColorMixin` where known) — shapes are intentionally loose
-- because most of these are consumed via `CreateFromMixins` or direct field access.

-- Talent / spec mixins
---@type table
ClassTalentFrameMixin = nil
---@type table
ClassSpecContentFrameMixin = nil
---@type table
ClassTalentSpecTabMixin = nil
---@type table
ClassTalentCurrencyDisplayMixin = nil
---@type table
TalentDisplayMixin = nil
---@type table
TalentButtonUtil = nil
---@type table
TalentFrameGateMixin = nil
---@type table
PvPTalentSlotButtonMixin = nil
---@type table
WarmodeButtonMixin = nil

-- Professions / micro-button mixins
---@type table
ProfessionsUnlearnButtonMixin = nil
---@type table
TalentMicroButtonMixin = nil
---@type table
QuestLogMicroButtonMixin = nil

-- Tooltip / dropdown mixins
---@type table
TooltipBackdropTemplateMixin = nil
---@type table
DropDownMenuButtonMixin = nil
---@type table
TooltipComparisonManager = nil

-- Utility / framework mixins
---@type table
TutorialHelper = nil
---@type table
CallbackRegistryMixin = nil
---@type table
MapCanvasDataProviderMixin = nil
---@type table
MinimalSliderWithSteppersMixin = nil
---@type table
SettingsSliderOptionsMixin = nil
---@type table
SettingsCallbackRegistry = nil
---@type table
EditModeSettingSliderMixin = nil
---@type table
EventUtil = nil
---@type table
POIButtonUtil = nil
---@type table
ScrollUtil = nil
---@type table
ScrollBoxConstants = nil
---@type table
AnchorUtil = nil
---@type table
GridLayoutMixin = nil
---@type table
LinkUtil = nil
---@type table
FlagsUtil = nil

-- Loot journal
---@type table
LootJournalItemSetsMixin = nil
---@type table
LootJournalItemSetButtonMixin = nil

-- Model scene
---@type table
ModelSceneControlButtonMixin = nil

-- Quest / spell utils
---@type table
QuestUtil = nil
---@type table
SpellSearchUtil = nil
---@type table
PagedContentFrameBaseMixin = nil
---@type table
WorldMapNavBarButtonMixin = nil

-- Menu API (10.x+)
---@type table
Menu = nil
---@type table
MenuUtil = nil
---@type table
MenuVariants = nil

-- Settings API
---@type table
Settings = nil

-- Blizzard singleton data tables
---@type table
TooltipDataProcessor = nil
---@type table
QUEST_TRACKER_MODULE = nil
---@type table
CAMPAIGN_QUEST_TRACKER_MODULE = nil
---@type table<string, function>
SlashCmdList = nil
---@type table
EventRegistry = nil
---@type string[]
UISpecialFrames = nil
---@type table
StaticPopupDialogs = nil
---@type table
SOUNDKIT = nil
---@type table<string, ColorMixin>
RAID_CLASS_COLORS = nil
---@type table
MICRO_BUTTONS = nil
---@type table
QUEST_TAG_DUNGEON_TYPES = nil
---@type table
WORLD_QUEST_TYPE_DUNGEON_TYPES = nil

-- Color mixins (global Color instances)
---@type ColorMixin
NORMAL_FONT_COLOR = nil
---@type ColorMixin
HIGHLIGHT_FONT_COLOR = nil
---@type ColorMixin
GRAY_FONT_COLOR = nil
---@type ColorMixin
RED_FONT_COLOR = nil
---@type ColorMixin
GREEN_FONT_COLOR = nil
---@type ColorMixin
DISABLED_FONT_COLOR = nil
---@type ColorMixin
TOOLTIP_DEFAULT_COLOR = nil
---@type ColorMixin
TOOLTIP_DEFAULT_BACKGROUND_COLOR = nil
