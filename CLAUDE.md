# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

WeintCodex is a World of Warcraft **Mists of Pandaria Classic** (Interface `50504`) addon: a raid guide & guild intelligence system (boss guides, raid roster/calendar, character/twink management, materials tracking, WeakAura distribution). It's one part of an ecosystem with two sibling repos:

- **WeintCodex** – this repo, the in-game addon (Lua)
- **WeintCompanion** – desktop app that installs/updates the addon and bridges it to Discord
- **WeintCodex Bot** – the Discord bot backend

Comments and in-game UI text are in German; Lua identifiers are in English/mixed. There is no build step, package manager, or test suite — this is pure WoW addon Lua, loaded directly by the game client per `WeintCodex.toc`.

## Working with this codebase

There are no commands to run — verification happens by loading the addon in-game (`/wc` or `/weintcodex` toggles the main window) and watching for Lua errors. A local Lua 5.1 install (`luac5.1 -p <file>`) catches syntax errors before that, which is worth doing for every changed file since there's no other safety net. `WeintCodex.toc` defines load order; when adding a new file it must be added there in the right place (libraries → core → data → modules) or it silently won't load. Bump `## Version` in the `.toc` and `WeintCodex.Version` in `core/main.lua` together when cutting a release — they're currently `1.0.0.0` and should stay in sync since the desktop Companion compares them against `SavedVariables` for the update check.

### Releases

Two workflows in `.github/workflows/` build the distributable ZIP by rsync-ing the repo (minus `.git`/`.github`/`README.md`/`LICENSE`) into a `WeintCodex/` folder and zipping it:
- `Manual Release` (`workflow_dispatch`) creates the tag + GitHub release + ZIP in one step.
- `Pack and Attach Addon to Release` runs on `release: published` and attaches the ZIP to an already-created release.

Both pass tag/notes through `env:` rather than direct `${{ }}` interpolation into shell — preserve that pattern if you touch these workflows, it's there specifically to avoid shell injection via release notes content.

## Architecture

### Global namespace, no module system

Everything hangs off the global `WeintCodex` table. Each module does `WeintCodex.X = {}` and adds its API to that; there's no `require`/`import` — load order in the `.toc` is the only dependency mechanism, so a module can only safely reference `WeintCodex.Other` if `other.lua` is listed earlier. `WeintCodex_SavedData` (session-persistent, per-account `SavedVariables`) holds all addon data: `bossData`, `raidData`/`raidWednesday`/`raidThursday`, `materialData`, `twinks`, `encounterProgress`, `weakAuras`, window geometry, minimap position.

### UI structure

`core/ui.lua` defines the theme (a dark "Codex" amber palette in `WeintCodex.Colors`, `C` locally) and builds the main frame/icon-rail/content-panel/inspector-column chrome. `core/navigation.lua` is a tab system: each entry in its `tabs` table (charakter, bossguides, raids, materials, calendar, weakauras, import) maps to a module that renders into the shared `ContentPanel` when selected, plus an `Inspector` side column (`WeintCodex.Navigation.SetInspector`) for contextual detail. `core/search.lua` provides cross-module search; `core/minimap.lua` uses `LibDBIcon`/`LibDataBroker` (in `libs/`) for the minimap button.

### Data vs. logic split

`data/` holds static reference tables (`BossData.lua`, `bis.lua`, `spec_profiles.lua`, `enchants.lua`, `gems.lua`, `gem_stats.lua`, `data/weakauras/*.lua` per class) that `modules/` consumes. `main.lua` calls `WeintCodex_ValidateSpecData()` and `WeintCodex_ValidateBiSData()` on login as drift guards — if `spec_profiles.lua` references an enchant/gem ID that no longer exists in `enchants.lua`/`gems.lua`, or `bis.lua` references a boss/slot name that doesn't exist, it warns. Keep IDs and names in these files consistent when editing gear/spec/BiS data.

### BiS lists (`data/bis.lua` + `modules/bis.lua`)

`data/bis.lua` holds `WeintCodex_BiS`, a per-spec table (keys match `WeintCodex_SpecProfiles` in `spec_profiles.lua`, e.g. `WARRIOR_ARMS`) of `{ id, slot, boss, variants?, note? }` entries — item name is deliberately not stored, it's resolved at runtime via `GetItemInfo` so it always matches the client's language (same doctrine as `WeintCodex_GetGemName` in `gems.lua`). `modules/bis.lua` builds a boss→spec index from that once and exposes `WeintCodex.BiS.GetForBoss(bossName, specKey)`, which checks only *equipped* gear (no bag/bank scan) and classifies each entry `have`/`variant`/`open`. Tank specs playing offensive stance (`*_OFFENSIVE` profile keys) have no data of their own — `GetForBoss` falls back to the base spec key since gear is identical between styles. `modules/bossguides.lua` renders the result as a scrollable `itemlist` block (`core/navigation.lua`) in the Inspector, under the boss notes.

### Companion bridge (bidirectional sync)

The addon and WeintCompanion communicate only through two Lua tables in the shared `SavedVariables` file (`WeintCodex.lua`), never directly over the network:

- **Outbound** (`WeintCompanionDB`, written by `modules/companion.lua` via `WeintCodex.Companion.Send(messageType, payload)`): a `queue` of `{id, created, version, type, payload}` messages. "State" message types (`materials`, `character`, `calendar` — see `STATE_MESSAGES`) replace any existing queued message of the same type instead of appending, since only the latest state matters. WeintCompanion's `SyncManager` drains this queue and clears entries it successfully delivers.
- **Inbound** (`WeintCompanionInboxDB`, written by WeintCompanion's `InboxWriter`): processed once per login via `WeintCodex.Companion.ProcessInbox()` (called from the `ADDON_LOADED` handler in `core/main.lua`), e.g. for `raid_import` messages pushed down from the Discord bot's roster export.

`WeintCodex.Companion.ReportCharacter()` fires on every `PLAYER_LOGIN` to tell the Companion/bot which real WoW character+realm is currently logged in (used for calendar-invite class/name resolution — Discord identity alone isn't enough).

### Bot import protocol (`modules/sync.lua`)

A second, independent channel: the Discord bot generates a `WCIMPORT:<TYPE>:<payload>` string via bot slash commands (`/export boss|raidwed|raidthu|mat|wa`), which the player pastes into the in-game Import dialog (`/wc import`, or `WeintCodex.Sync.QuickImport(str)`). Each `<TYPE>` (`BOSS`, `RAIDWED`/`RAIDTHU`/legacy `RAID`, `MAT`, `WA`) has its own hand-rolled colon/pipe/comma-delimited parser in `sync.lua` (`ParseBossImport`, `ParseRaidImport`, `ParseMatImport`, `ParseWAImport`) — these are position-based string formats, not JSON, so field order matters and is documented in the file header comment. `ProcessImport` dispatches by type tag and writes results straight into `WeintCodex.SavedData`, then calls the owning module's `Refresh`/`ResolveNames`/`RefreshDay` to update the UI.

### Libraries

`libs/` vendors `LibStub`, `CallbackHandler-1.0`, `LibDataBroker-1.1`, `LibDBIcon-1.0` — standard WoW addon ecosystem libraries, used only for the minimap button/data-broker integration in `core/minimap.lua`. Don't hand-edit vendored library code; replace the file wholesale if it needs updating.
