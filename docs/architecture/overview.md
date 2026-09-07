# Architecture overview

## Global namespace, no module system

Everything hangs off the global `WeintCodex` table. Each module does
`WeintCodex.X = {}` and adds its API to that; there's no `require`/`import`
— load order in the `.toc` is the only dependency mechanism, so a module
can only safely reference `WeintCodex.Other` if `other.lua` is listed
earlier. `WeintCodex_SavedData` (session-persistent, per-account
`SavedVariables`) holds all addon data: `bossData`, `raidWednesday`/
`raidThursday`, `materialData`, `guildBankCache`, `rosterNameOverrides`,
`twinks`, `encounterProgress` (per character since 2.4.0.0 — see
`../systems/encounter-tracking.md`), `weakAuras`, `academy`, `weinttv`,
`reforge`, `statWeights`, `access`, `window`, minimap position. `raidData`
is initialized in `core/main.lua` but dead — nothing ever reads or writes
it; the live keys are `raidWednesday`/`raidThursday`.

## UI structure

`core/ui.lua` defines the theme and builds the chrome; `core/navigation.lua`
is the tab system. Each entry in its `tabs` table (uebersicht, bossguides,
raids, gruppencheck, calendar, weinttv, charakter, academy, materials,
weakauras, import, settings — three carrying a `feature` for access
gating) maps to a module that renders into the shared `ContentPanel`.
`core/search.lua` provides cross-module search; `core/minimap.lua` uses
`LibDBIcon`/`LibDataBroker` (in `libs/`) for the minimap button.

Since **2.0.0.0** the surface follows the WeintCompanion 2.0 design
language (source of truth: the `Adson neu – Seiten` design doc, direction
1a). What that changed structurally, and why the changes are not
cosmetic:

- **Two columns, not four.** Title bar 40 + navigation column 232 +
  content. The old icon rail (64) / sub-nav (240) / content / inspector
  (340) split is gone. Navigation entries are written out and grouped
  *Raid* / *Charakter* / *Gilde*.
- **The inspector is part of the page**, not a window column: right-hand
  372 px, shown *only* when there are blocks. `Navigation.SetInspector`
  and all nine calling modules are unchanged — `ContentPanel` shrinks
  instead. A page that derives sizes from `ContentPanel:GetWidth()` must
  call `SetInspector` **before** it measures, or anchor both edges instead
  of computing a width.
- **`BuildSidebar(title, items)` survives as the API** and picks its own
  form: a segmented control under the page title for short flat lists, a
  list column inside the page as soon as entries carry a portrait, a
  status line or groups. Fourteen bosses with artwork and "down/open" are
  not tabs.
- **Detail region, sub-nav column and tab strip inset the content through
  one shared code path** (`SetDetailShown` / `SetSubNavWidth` /
  `SetSubNavTop` in `core/ui.lua`). Per-caller `ClearAllPoints`/`SetPoint`
  is exactly the bug you only see when two of them are active at once.
- **Every page head comes from `WeintCodex.PageHead`** — eyebrow, title,
  optional subline, mono stats on the right. Returns the frame with
  `.Title`/`.Sub`/`.Stats[key]` and `.Height`. A page title is a label,
  not a finding, so it never carries amber. Pieces anchor *to each other*
  rather than to computed Y values.

Four WoW-specific translations in `core/ui.lua` that are not taste:

- **Text is UTF-8, Lua 5.1 counts bytes.** Every operation that touches
  display text *per character* has its own UTF-8-aware version (`Spaced`,
  `WeintCodex.Upper`, `WeintCodex.Truncate`, `Utf8Len`, `Utf8Sub`), and
  **no caller may use `string.upper`, `#` or `:sub` on German display
  text**. `ß` deliberately stays `ß`: "SS" would make a line wider than
  its caller measured.
- **Radius.** Frames have none. Four quarter-circle masks
  (`media/ui/corner.tga`) tinted to the colour *behind* the card punch the
  corners out. The main window deliberately stays square: behind it is
  the game world, whose colour nothing can know.
- **Gradient direction.** `SetGradient("VERTICAL", min, max)` runs
  bottom→top, CSS `linear-gradient(180deg, …)` top→bottom.
  `ApplyVerticalGradient` swaps them; do not "fix" it.
- **`DrawBorder` anchors its edges at two points** rather than computing
  from `GetWidth()` at build time.

Every colour name of the v1 palette still resolves, now pointing at the
new values: ~140 `ColorText` call sites name colours as strings, and a
removed name returns *unstyled text* rather than an error.

## Libraries

`libs/` vendors `LibStub`, `CallbackHandler-1.0`, `LibDataBroker-1.1`,
`LibDBIcon-1.0` — standard WoW addon ecosystem libraries, used only for
the minimap button/data-broker integration in `core/minimap.lua`. Don't
hand-edit vendored library code; replace the file wholesale if it needs
updating.
