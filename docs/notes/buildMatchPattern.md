# `buildMatchPattern(fmt)` — deep dive

**File:** `Core/Translators/Tooltips/SpellTooltipTranslator.lua`
**Purpose:** Convert a Blizzard format string (e.g. `"Max %d Charges"`) into an anchored Lua match pattern (`"^Max (%d+) Charges$"`) with one capture per placeholder.

---

## Why it exists

Blizzard exposes localized format constants like `"Rank %s/%s"` or `"%s (%d/%d)"`. The spell tooltip translator needs to **recognize** those shapes in parsed tooltip lines and **extract** the runtime values (rank numbers, talent names). A hand-written pattern per constant would bit-rot across WoW patches — this helper derives the pattern mechanically from the constant itself.

## Real Blizzard inputs in this file

All 7 callers feed real GlobalStrings:

| Constant | Value |
| --- | --- |
| `TALENT_BUTTON_TOOLTIP_RANK_FORMAT` | `"Rank %s/%s"` |
| `TALENT_BUTTON_TOOLTIP_RANK_NO_MAX_FORMAT` | `"Rank %s"` |
| `TALENT_BUTTON_TOOLTIP_REPLACED_BY_FORMAT` | `"Replaced by %s"` |
| `REPLACES_SPELL` | `"Replaces %s"` |
| `SPELL_MAX_CHARGES` | `"Max %d Charges"` |
| `TALENT_BUTTON_TOOLTIP_CAPSTONE_TRACK_TITLE_FORMAT` | `"%s (%d/%d)"` |
| `TOOLTIP_TALENT_RANK_CAPSTONE` | `"Rank %d"` |

## Placeholder semantics

| Placeholder | Capture | Notes |
| --- | --- | --- |
| `%s` (all but last) | `(.-)` | Lazy — minimum expansion |
| `%s` (last) | `(.+)` | Greedy — at least one char |
| `%d` | `(%d+)` | One-or-more digits |

### Why two flavors for `%s`

Two adjacent greedy captures create backtracking ambiguity on inputs with repeats. Lazy-first + greedy-last is unambiguous and deterministic.

Example: `"Rank %s/%s"` → `"^Rank (.-)/(.+)$"`. For `"Rank 2/5"` the first lazy capture stops at the earliest `/`, the last greedy capture takes everything remaining.

## Walkthrough — `"%s (%d/%d)"` (the trickiest input)

| step | cursor | segment | emitted | parts so far |
| --- | --- | --- | --- | --- |
| 1 | pos=1 | `%s` (the only one → "last") | `(.+)` | `(.+)` |
| 2 | pos=3 | literal `" ("` → escape `(` | ` %(` | `(.+) %(` |
| 3 | pos=5 | `%d` | `(%d+)` | `(.+) %((%d+)` |
| 4 | pos=7 | literal `"/"` | `/` | `(.+) %((%d+)/` |
| 5 | pos=8 | `%d` | `(%d+)` | `(.+) %((%d+)/(%d+)` |
| 6 | pos=10 | literal `")"` → escape `)` | `%)` | `(.+) %((%d+)/(%d+)%)` |

Final: `^(.+) %((%d+)/(%d+)%)$`. For `"Fireball (2/5)"` → captures `"Fireball"`, `"2"`, `"5"`.

## Escape set

Extracted to a module-level constant so the two `gsub` call sites can't drift apart:

```lua
-- Matches any Lua pattern magic character: ( ) . % + - * ? [ ] ^ $
local LUA_MAGIC_CHAR_PATTERN = "([%(%)%.%%%+%-%*%?%[%]%^%$])"
```

Captures: `( ) . % + - * ? [ ] ^ $` — the canonical 12 Lua pattern specials.

Historical note: a prior version omitted `%]` and duplicated the class inline at both call sites. `]` was latent (not active), because `]` is only special *inside* a character class and the helper always escapes `[` as `%[`, so no class is ever opened in the output. Adding `%]` brings the escape set to the full canonical list; pulling the class into a constant prevents the two sites from drifting.

## Algorithm shape

```
while cursor not at end:
    find next %s and next %d from cursor
    pick nearest placeholder
    if none:
        escape remaining literal → emit
        break
    if literal text precedes placeholder:
        escape → emit
    if %s:
        emit "(.-)" or "(.+)" depending on seenS vs totalS
    else:
        emit "(%d+)"
    advance cursor past placeholder
anchor with "^" … "$"
```

## Failure modes / invariants

- Input must be a string (no `nil` guard; caller responsibility).
- `%%` (literal percent) is not specially handled — it would be seen as two chars `%` and `%`, and the lone `%` gets escaped to `%%`. If Blizzard ever adds `%%` to a relevant constant, revisit. None of the 7 current inputs contain `%%`.
- No support for `%1`–`%9` positional args, `%f`, `%x`, etc. `%s` and `%d` are sufficient for the spell tooltip domain.
- Output always wraps in `^…$` — use only for full-line matching, not substring search.

## Annotation

```lua
---@param fmt string  Blizzard format string with `%s` / `%d` placeholders.
---@return string pattern  Anchored Lua match pattern.
```
