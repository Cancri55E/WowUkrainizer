# Architecture — WowUkrainizer

This document describes the internal architecture of the WowUkrainizer addon in detail.

---

## Boot sequence

The addon initializes in a strict order defined by `WowUkrainizer.xml`:

```
WowUkrainizer.xml
  ├── libs/_manifest.xml        (1) Third-party libraries
  ├── Database/_manifest.xml    (2) Translation data tables
  ├── Core/_manifest.xml        (3) All addon logic
  └── WowUkrainizer.lua         (4) Entry point
```

Within **Core/** the load order is (`Core/_manifest.xml`):

```
Globals.lua                     Constants, colors, setting option names
Extensions/_manifest.xml        Lua utility extensions (StringUtil, etc.)
EventHandler.lua                Event handler factory
UntranslatedDataStorage.lua     Tracks strings without translations
IngameDataCacher.lua            Per-character runtime cache
SettingsProvider.lua            User settings with defaults
StringNormalizer.lua            WoW markup extraction/restoration
DbContext.lua                   Repository layer over Database/
Utils/_manifest.xml             Domain-specific helpers
Subscribers/_manifest.xml       Event-driven hooks
Translators/_manifest.xml       All translators
Frames/_manifest.xml            UI frames (Settings, Wizard, etc.)
```

**Runtime initialization** (in `WowUkrainizer.lua`):

1. `ADDON_LOADED` → `initializeAddon()`
   - Creates SettingsProvider and UntranslatedDataStorage
   - Registers Ukrainian fonts with LibSharedMedia
   - Sets up minimap icon via LibDataBroker + LibDBIcon
   - Creates UI frames (WarningFrame, ChangelogsFrame, InstallerFrame)
2. `PLAYER_LOGIN` → `OnPlayerLogin()`
   - Captures player info (name, realm, race, class, gender)
   - Initializes IngameDataCacher
   - Creates settings UI category
   - Calls `TranslationsManager:Init()` — starts all enabled translators
   - Shows installer wizard or changelog if needed
3. `setGameFonts()` — applies custom Ukrainian fonts to 60+ WoW UI elements

---

## Core support modules

### Globals.lua

Shared constants used across the addon:
- **Colors**: `WHITE`, `GREEN`, `DISABLED`, `SECONDARY_TEXT`
- **Setting option names**: 30+ `WOW_UKRAINIZER_*` constants
- **Font paths**: Ukrainian-adapted Friz Quadrata TT and Morpheus

### EventHandler.lua

Factory (`ns.EventHandlerFactory`) that creates event handler objects:
- `Register(callback, ...)` — register a callback for one or more WoW events
- `Unregister(callback, ...)` — remove callbacks
- `UnregisterAll()` — clear all subscriptions
- Internally creates a hidden frame for WoW event dispatch

### SettingsProvider.lua

Centralized settings management via `WowUkrainizer_Options` saved variable:
- 30+ default options (font, translation toggles, tooltip switches)
- `ResetToDefault()` — reset all except changelog tracking
- `GetFontSettings()` — returns font configuration (default / adapted / custom)
- `ShouldShowChangelog()` / `ShouldShowInstallerWizard()` — first-run logic
- Integrates with LibSharedMedia-3.0 for custom font selection

### IngameDataCacher.lua

Per-character caching layer stored in `_G.WowUkrainizerData.Cache`:
- Groups data by character hash (name + realm)
- Tracks player name, realm, class, spec, build date
- `GetOrAddCategory(categories)` — create nested category chains
- `GetOrAdd(categories, data, metadata)` — cache with player/build tracking

### UntranslatedDataStorage.lua

Tracks strings that have no translation, stored in `_G.WowUkrainizerData.UntranslatedData`:
- `GetOrAdd(category, subCategory, data)` — get or create untranslated entries
- Records game build for each item
- Singleton with lazy initialization

### StringNormalizer.lua

Extracts and restores inline WoW formatting separately from translation:
- `NormalizeStringAndExtractNumerics(text)` — strips `|cHEXCOLOR|r` color codes, `|T...|t` texture icons, numeric values
- `ReconstructStringWithNumerics(str, numbers)` — restores extracted data with Ukrainian declension support

---

## DbContext.lua — the Repository pattern

This is the largest core file (769 lines). It implements a **Repository pattern** over `Database/` tables.

### BaseRepository

All repositories share base methods:
- `_getValue(data, str)` — look up by `GetHash(str)`
- `_getNameValue(data, str)` — look up by `GetNameHash(str)`
- `_getFormattedValue(data, str, ...)` — look up + `string.format`

### Triple-hash system

Three hash algorithms for different string categories (defined in `StringExtensions.lua`):

| Hash function | Normalization | Use case |
|---------------|---------------|----------|
| `GetHash(str)` | Aggressive: lowercase, remove punctuation, replace spaces with `_` | General strings, quest text |
| `GetNameHash(str)` | Preserve case, keep some punctuation | Unit names, spell names |
| `GetPersonalizedStringHash(str)` | Normalize `$n/$p/$r/$c` placeholders before hashing | NPC dialog with player references |

### Repository types

| Repository | Tables used | Key features |
|------------|-------------|--------------|
| **Units** | UnitNames, UnitSubnames, UnitTypes, UnitRanks | Name + subname + type/rank translation |
| **Player** | Classes, Races, Roles | Gender/case support (7 grammatical cases) |
| **Spells** | SpellNames, SpellDescriptions, SpellAttributes | Name, description, attribute translation |
| **Frames** | SplashFrameData | "What's New" info for splash screens |
| **Subtitles** | MovieSubtitles | Cinematic subtitle translation |
| **NpcDialogs** | DialogTexts | Personalization: replaces `$n` (name), `$p` (player), `$r` (race), `$rs` (short race), `$c` (class) with Ukrainian declensions |
| **Gossips** | GossipTitles, GossipOptions | NPC gossip menus |
| **Quests** | Quests, QuestObjectives, MTQuests, MTQuestObjectives | Full quest data with machine translation fallback |
| **ZoneTexts** | ZoneTexts | Zone/subzone names |
| **GlobalStrings** | GlobalStrings | WoW UI strings |
| **Items** | Items, ItemAttributes | Item names, descriptions, attributes |
| **Factions** | Factions | Faction name translation |

### Player personalization

NpcDialogs repository handles Blizzard's placeholder system:
- `$n` / `$N` — player name
- `$p` / `$P` — player name (alternate)
- `$r` / `$R` — race name (with grammatical case)
- `$rs` / `$Rs` — short race name
- `$c` / `$C` — class name (with grammatical case)

Ukrainian grammar requires 7 cases (nominative, genitive, dative, accusative, locative, instrumental, vocative) for proper declension of race/class names in dialog text.

### Machine translation fallback

Quests repository checks `ns._db.Quests` first; if not found and MT is enabled via settings, falls back to `ns._db.MTQuests`. The MT flag is exposed to the UI so users see which translations are machine-generated.

---

## Extensions (Core/Extensions/)

Stateless utility modules attached to the `ns` namespace.

### StringUtil (`StringExtensions.lua`, 279 lines)

The most-used utility. Key functions:
- **Hashing**: `GetHash()`, `GetNameHash()`, `GetPersonalizedStringHash()` (see triple-hash above)
- **String ops**: `Trim()`, `Split()`, `EndsWith()`, `StartsWith()`
- **Placeholders**: `ExtractNumericValues()` / `InsertNumericValues()` — extract numbers from translated text and reinsert with declension
- **Cyrillic**: `Uft8Upper()` — Ukrainian-aware uppercase (`ї→Ї`, `і→І`, `є→Є`, `ґ→Ґ`)
- **Grammar**: `DeclensionWord(number, singular, plural, genitivePlural)` — Ukrainian plural forms
- **Search**: `ReplaceWholeWordNocase()` — case-insensitive word boundary replacement

### FontStringUtil (`FontStringExtensions.lua`)

- `SetText(fontString, text)` — set text while preserving WoW color codes
- `UpdateTextWithTranslation(fontString, translateFunc)` — translate + apply in one step

### CommonUtil (`CommonExtensions.lua`)

- `GenerateUUID()` — unique ID generation
- `TableSearch(table, value)` — linear search
- `SafeApiCall(func, ...)` — pcall wrapper for WoW API calls

### GameApiUtil (`GameApiExtensions.lua`)

- `GetPlayerMapPosition()` — wrapped WoW map position API

---

## The Translator pattern (Core/Translators/)

### Overview

Every translation area has its own Translator class. All translators:
1. Inherit from `BaseTranslator` (or `BaseTooltipTranslator`)
2. Override `IsEnabled()` and `Init()`
3. Self-register via `ns.TranslationsManager:AddTranslator(translator)` at file end

### BaseTranslator

Minimal base class with only two methods:
```lua
function baseTranslator:IsEnabled()
    return false  -- Override to enable
end

function baseTranslator:Init()
    -- Override to set up hooks/events
end
```

Inheritance via metatables: `setmetatable({}, { __index = ns.BaseTranslator })`

### TranslationsManager

Simple coordinator:
- `AddTranslator(translator)` — registers a translator in the ordered list
- `Init()` — iterates all translators, calls `Init()` on those where `IsEnabled()` returns `true`

### Translator types

There are 5 distinct translator patterns in the codebase:

#### Type 1: Simple hook translators

Hook into UI element updates and apply translations directly.

**Examples**: `MainFrameTranslator`, `ZoneTextTranslator`, `UIErrorsTranslator`

```lua
function translator:Init()
    UpdateTextWithTranslation(someFrame.Text, GetTranslatedGlobalString)
    hooksecurefunc(frame, "OnUpdate", function() ... end)
end
```

#### Type 2: Event-driven stateful translators

Maintain internal state and react to WoW events via `EventHandlerFactory`.

**Examples**: `NpcMessageTranslator`, `SubtitlesTranslator`, `NameplateAndUnitFrameTranslator`

```lua
local translator = setmetatable({
    talkingHeadUuid = nil,
    playCinematic = false,
}, { __index = ns.BaseTranslator })

function translator:Init()
    local instance = self  -- Closure to capture self
    eventHandler:Register(function(...)
        instance.talkingHeadUuid = ...
    end, "EVENT_NAME")
end
```

#### Type 3: Tooltip translators (template method pattern)

Inherit from `BaseTooltipTranslator` (which itself inherits from `BaseTranslator`). Uses the Template Method pattern.

**Examples**: `ItemTooltipTranslator`, `SpellTooltipTranslator`, `UnitTooltipTranslator`, `MacroTooltipTranslator`

**BaseTooltipTranslator provides:**
- `Init()` — sets up `TooltipDataProcessor.AddTooltipPostCall()`
- `TooltipCallback()` — lifecycle: parse → translate → apply
- `AddFontStringToIndexLookup()` — font string index cache

**Subclasses override:**
- `ParseTooltip(tooltip, tooltipData)` — extract tooltip structure
- `TranslateTooltipInfo(tooltipInfo)` — translate the parsed structure

```lua
local translator = setmetatable(
    { tooltipDataType = Enum.TooltipDataType.Item },
    { __index = ns.BaseTooltipTranslator }
)
```

#### Type 4: Frame-specific translators

Hook into specific Blizzard frames, often waiting for `ADDON_LOADED` to ensure the frame exists.

**Examples**: all files in `Frames/` subdirectory (`PaperDollFrameTranslator`, `ClassTalentsFrameTranslator`, `SpellbookFrameTranslator`, etc.)

```lua
function translator:Init()
    eventHandler:Register(function(_, name)
        if name == "Blizzard_PlayerSpells" then
            hooksecurefunc(PlayerSpellsFrame, "UpdateFrameTitle", ...)
        end
    end, "ADDON_LOADED")
end
```

#### Type 5: Third-party addon translators

Conditionally hook into other addons (e.g., Immersion, DejaCharacterStats). May be stubs awaiting future implementation.

**Examples**: `ImmersionTranslator` (full), `DejaCharacterStatsTranslator` (stub)

### Settings integration

Translators that can be toggled use this pattern:
```lua
function translator:IsEnabled()
    return ns.SettingsProvider.GetOption(WOW_UKRAINIZER_TRANSLATE_XXX_OPTION)
end
```

Always-enabled translators return `true` directly.

### MoneyTranslator

`MoneyTranslator` in the `Tooltips/` folder is an outlier — it translates gold/silver/copper display formatting rather than actual tooltips, but follows the same base class structure.

---

## The Subscriber pattern (Core/Subscribers/)

An observer pattern for intercepting WoW UI function calls without modifying originals.

### BaseSubscriber

Singleton base class:
- `GetInstance()` — returns the single instance (lazy-created)
- `Subscribe(ownerRegion, callbackFunc)` — register a callback for a specific owner/key
- `InitializeSubscriber()` — abstract, subclass must implement the hook

Internally uses `hooksecurefunc()` for non-invasive secure hooks.

### StaticPopupSubscriber

Hooks `StaticPopup_Show()`. When a popup appears, checks subscriptions against the `which` parameter and invokes matching callbacks.

```lua
-- Usage from a translator:
local subscriber = ns.StaticPopupSubscriber:GetInstance()
subscriber:Subscribe("QUEST_GREETING", function(dialog, arg1, arg2, data)
    -- Translate the popup dialog contents
end)
```

### DropdownDescriptionSubscriber

Hooks `Menu.PopulateDescription()`. Watches for dropdown population on specific owner regions and calls callbacks with `rootDescription`.

```lua
local subscriber = ns.DropdownDescriptionSubscriber:GetInstance()
subscriber:Subscribe(someFrame, function(rootDescription)
    -- Translate dropdown menu entries
end)
```

---

## Utils (Core/Utils/)

Domain-specific helpers used by translators.

| File | Lines | Purpose |
|------|-------|---------|
| `SpellTooltipUtil.lua` | 481 | Complex spell tooltip parsing: name, rank, resources, cast time, cooldown, range, passive/upgrade flags, talent chains. Used by `SpellTooltipTranslator`. |
| `QuestFrameUtil.lua` | 69 | Creates MT icon, translation toggle button, and Wowhead link button for quest frames. |
| `TooltipUtil.lua` | 34 | `OnUpdateTooltip()` — batch-update tooltip left/right text while preserving colors. |
| `ZoneFrameUtil.lua` | 35 | `GetTranslatedPvpText()` — translates zone control text (sanctuary, contested, etc.) with faction genitive. |
| `SelectedIconFrameTranslationUtil.lua` | 43 | Hooks icon selector frames and integrates with `DropdownDescriptionSubscriber`. |

---

## UI Frames (Core/Frames/)

Each frame is a `.xml` + `.lua` pair (except CommonFrames which provides shared mixins).

| Frame | Purpose |
|-------|---------|
| **CommonFrames** | Shared UI components: `WowUkrainizerCheckButtonMixin` (checkbox with option binding, radio-button mode), `WowUkrainizerUrlFrameMixin` (clickable URL with tooltip) |
| **SettingsFrame** | Two-tab settings panel: module toggles + font settings. Shows reload warning when needed. |
| **WizardFrame** | Multi-step first-run installer (780 lines Lua). Feature selection, font setup. |
| **ChangelogsFrame** | Changelog display with HTML-like rendering. |
| **WarningFrame** | Simple modal dialog for settings-save warnings. |

---

## Libraries (libs/)

Third-party libraries loaded first via `libs/_manifest.xml`:

| Library | Purpose |
|---------|---------|
| **LibStub** | Library version management / loader |
| **CallbackHandler-1.0** | Event callback system |
| **Ace3** | Addon framework: AceAddon, AceGUI, AceHook, AceConfig (Registry, Dialog, Cmd) |
| **AceGUI-3.0-SharedMediaWidgets** | Font/background/border/sound/statusbar pickers |
| **LibSharedMedia-3.0** | Shared font/media registration across addons |
| **LibDataBroker-1.1** | Launcher/minimap protocol |
| **LibDBIcon-1.0** | Minimap button management |
| **LibUIDropDownMenu** | Dropdown menu replacement (avoids taint) |
| **TaintLess** | Anti-taint protection for protected function hooks |
