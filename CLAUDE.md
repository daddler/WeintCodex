# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

WeintCodex is a World of Warcraft **Mists of Pandaria Classic** (Interface `50504`) addon: a raid guide & guild intelligence system (boss guides, raid roster/calendar, character/twink management, materials tracking, WeakAura distribution). It's one part of an ecosystem with two sibling repos:

- **WeintCodex** – this repo, the in-game addon (Lua)
- **WeintCompanion** – desktop app that installs/updates the addon and bridges it to Discord
- **WeintCodex Bot** – the Discord bot backend

Comments and in-game UI text are in German; Lua identifiers are in English/mixed. There is no build step, package manager, or test suite — this is pure WoW addon Lua, loaded directly by the game client per `WeintCodex.toc`.

## Working with this codebase

There are no commands to run — verification happens by loading the addon in-game (`/wc` or `/weintcodex` toggles the main window) and watching for Lua errors. A local Lua 5.1 install (`luac5.1 -p <file>`) catches syntax errors before that, which is worth doing for every changed file since there's no other safety net. `WeintCodex.toc` defines load order; when adding a new file it must be added there in the right place (libraries → core → data → modules) or it silently won't load. Bump `## Version` in the `.toc` and `WeintCodex.Version` in `core/main.lua` together when cutting a release — they're currently `1.1.0.0` and should stay in sync since the desktop Companion compares them against `SavedVariables` for the update check.

### Releases

Two workflows in `.github/workflows/` build the distributable ZIP by rsync-ing the repo (minus `.git`/`.github`/`README.md`/`LICENSE`) into a `WeintCodex/` folder and zipping it:
- `Manual Release` (`workflow_dispatch`) creates the tag + GitHub release + ZIP in one step.
- `Pack and Attach Addon to Release` runs on `release: published` and attaches the ZIP to an already-created release.

Both pass tag/notes through `env:` rather than direct `${{ }}` interpolation into shell — preserve that pattern if you touch these workflows, it's there specifically to avoid shell injection via release notes content.

## Architecture

### Global namespace, no module system

Everything hangs off the global `WeintCodex` table. Each module does `WeintCodex.X = {}` and adds its API to that; there's no `require`/`import` — load order in the `.toc` is the only dependency mechanism, so a module can only safely reference `WeintCodex.Other` if `other.lua` is listed earlier. `WeintCodex_SavedData` (session-persistent, per-account `SavedVariables`) holds all addon data: `bossData`, `raidWednesday`/`raidThursday`, `materialData`, `guildBankCache`, `rosterNameOverrides`, `twinks`, `encounterProgress`, `weakAuras`, `academy`, `weinttv`, `access` (the access profile, see below), window geometry, minimap position. `raidData` is initialized in `core/main.lua` but dead — nothing ever reads or writes it; the live keys are `raidWednesday`/`raidThursday`.

### UI structure

`core/ui.lua` defines the theme (a dark "Codex" amber palette in `WeintCodex.Colors`, `C` locally) and builds the main frame/icon-rail/content-panel/inspector-column chrome. `core/navigation.lua` is a tab system: each entry in its `tabs` table (charakter, bossguides, raids, materials, calendar, weakauras, weinttv, import — three of them carrying a `feature` for access gating) maps to a module that renders into the shared `ContentPanel` when selected, plus an `Inspector` side column (`WeintCodex.Navigation.SetInspector`) for contextual detail. `core/search.lua` provides cross-module search; `core/minimap.lua` uses `LibDBIcon`/`LibDataBroker` (in `libs/`) for the minimap button.

### Data vs. logic split

`data/` holds static reference tables (`BossData.lua`, `bis.lua`, `spec_profiles.lua`, `enchants.lua`, `gems.lua`, `gem_stats.lua`, `data/weakauras/*.lua` per class) that `modules/` consumes. `main.lua` calls `WeintCodex_ValidateSpecData()` and `WeintCodex_ValidateBiSData()` on login as drift guards — if `spec_profiles.lua` references an enchant/gem ID that no longer exists in `enchants.lua`/`gems.lua`, or `bis.lua` references a boss/slot name that doesn't exist, it warns. Keep IDs and names in these files consistent when editing gear/spec/BiS data.

### BiS lists (`data/bis.lua` + `modules/bis.lua`)

`data/bis.lua` holds `WeintCodex_BiS`, a per-spec table (keys match `WeintCodex_SpecProfiles` in `spec_profiles.lua`, e.g. `WARRIOR_ARMS`) of `{ id, slot, boss, variants?, note? }` entries — item name is deliberately not stored, it's resolved at runtime via `GetItemInfo` so it always matches the client's language (same doctrine as `WeintCodex_GetGemName` in `gems.lua`). `modules/bis.lua` builds a boss→spec index from that once and exposes `WeintCodex.BiS.GetForBoss(bossName, specKey)`, which checks only *equipped* gear (no bag/bank scan) and classifies each entry `have`/`variant`/`open`. Tank specs playing offensive stance (`*_OFFENSIVE` profile keys) have no data of their own — `GetForBoss` falls back to the base spec key since gear is identical between styles. `modules/bossguides.lua` renders the result as a scrollable `itemlist` block (`core/navigation.lua`) in the Inspector, under the boss notes.

### Companion bridge (bidirectional sync)

The addon and WeintCompanion communicate only through two Lua tables in the shared `SavedVariables` file (`WeintCodex.lua`), never directly over the network:

- **Outbound** (`WeintCompanionDB`, written by `modules/companion.lua` via `WeintCodex.Companion.Send(messageType, payload)`): a `queue` of `{id, created, version, type, payload}` messages. "State" message types (`materials`, `character`, `calendar`, `academy` — see `STATE_MESSAGES`) replace any existing queued message of the same type instead of appending, since only the latest state matters. WeintCompanion's `SyncManager` drains this queue and clears entries it successfully delivers.
- **Inbound** (`WeintCompanionInboxDB`, written by WeintCompanion's `InboxWriter`): processed once per login via `WeintCodex.Companion.ProcessInbox()` (called from the `ADDON_LOADED` handler in `core/main.lua`). `INBOX_HANDLERS` in `companion.lua` dispatches by `message.type`: `raid_import` carries a `WCIMPORT` string and goes to `WeintCodex.Sync.QuickImport`, while `access_profile`, `academy_catalog`, `academy_state` and `weinttv_report` carry **nested Lua tables** and are stored in `WeintCodex.SavedData.access` / `.academy` / `.weinttv`. Each handler runs in `pcall`, so one malformed message cannot strand the rest of the queue. The full payload schemas are documented in the header comment of `modules/companion.lua` (and for `access_profile` in `core/access.lua`).

`ProcessInbox` runs in **two passes**: first every `access_profile`, then everything else. Without that ordering, the very batch that a first-time profile is supposed to gate would still slip through. In the second pass a message whose optional `message.community` differs from the binding is dropped (counted in `SavedData.access.rejections`, one summary warning). Dropped messages are still wiped along with the rest — keeping them would repeat the warning every login and, worse, let weeks-old data from a previous community be accepted after a legitimate `/wc access reset`.

The inbox is read **only at login/reload** — WoW never re-reads `SavedVariables` at runtime. Anything built on it is therefore a report of the last delivery, never a live view; both `weinttv.lua` and `academy.lua` say so in their headers and in the UI.

`WeintCodex.Companion.ReportCharacter()` fires on every `PLAYER_LOGIN` to tell the Companion/bot which real WoW character+realm is currently logged in (used for calendar-invite class/name resolution — Discord identity alone isn't enough).

### Zugriffsprofile & Freigaben (`core/access.lua`)

**This is data hygiene and UX, not a security boundary.** `WeintCodex_SavedData` is an editable Lua file on the player's disk — anyone can set `features["materials.view"] = true` by hand. Its job is: a non-guild raider's Companion never mixes two guilds' data, nobody sees a UI full of numbers that don't concern them, and nothing guild-internal leaves a client that isn't entitled to send it.

Only the Discord bot *could* enforce more, by refusing to emit a payload a role isn't entitled to — and it currently does not. So the system delivers exactly the three things above and nothing further; **it does not provide confidentiality.** Say so in any doc or comment you write about this system — that framing is the whole point. The role→feature mapping lives in WeintCompanion, which puts it on the player's disk too, under the same caveat for the same reason.

`core/access.lua` loads between `core/ui.lua` (it needs `Colors`/`CreateCard`/`IconRail`) and `core/navigation.lua`. It must **never** capture `WeintCodex.Navigation` in a file-local, since that file loads later — access it inside function bodies only.

WeintCompanion (**1.4.0 or newer**) delivers an `access_profile` inbox message with `community`, `identity`, `tier`, `tierLabel`, `roles`, `features`, `issuedAt`/`expiresAt`, `companionVersion` and an optional free-text `notice`. The full schema and the binding rules are in the file's header comment. `community.id` is a **string** — a Discord snowflake as a Lua 5.1 number stringifies to `1.23e+18` and would never compare equal to the Companion's decimal string.

- **One community per client.** The first profile binds; a profile or message from another community is *rejected*, never re-bound. `/wc access reset` (two-step, requires `/wc access reset bestaetigen`) unbinds **and deletes** the guild-internal keys — otherwise the previous guild's rosters, materials and tactics would sit there when the client rebinds, which is exactly the mixing this system exists to prevent.
- **`Can(featureKey)` order:** no profile → `true` (a client that never got a profile behaves exactly as before, that's deliberate); expired beyond grace → only `STALE_FEATURES`; explicit `features[key]` boolean wins; otherwise the `TIER_FEATURES` fallback matrix; unknown tier → deny plus one loud chat warning. Only real booleans count in `features`, so `"true"` or `1` fall through to the matrix instead of silently allowing. The nine keys are `raids.view`, `raids.edit`, `calendar.view`, `calendar.invite`, `materials.view`, `materials.scan`, `bossguides.tips`, `weinttv.raid`, `loot.report`. The matrix must never grant `calendar.view` without `raids.view` — the calendar reads the roster for its invite preview.
- **Expiry** is `fresh` → `grace` (14 days, full rights, visible warning) → `expired`. Expired keeps *read* access to what is already on disk and instead blocks ingest (`IngestAllowed()`) and every write/outbound capability. Hiding data the player already has would be theatre; locking a raider out of Wednesday's roster because the desktop app didn't run for three weeks would be a support ticket.
- **UI rule: lock, don't hide.** Only `raids`/`materials`/`calendar` carry a `feature` in `navigation.lua`'s `tabs`; the rest gate inside their page so their neutral half stays open. `SwitchTo` is the single choke point (covers the rail, `GoToTab`, dashboard tiles/stats and `core/search.lua`) and routes denied tabs to `ShowAccessLock`. `/wc import` and the dashboard's Import button bypass it on purpose — that tab is never locked, and the real gate for the data sits in `ProcessImport`. Icon colour goes through `TintIcon`, because `SetTabActive`/`OnEnter`/`OnLeave` would otherwise overwrite the locked tint.
- Gated capabilities that are easy to miss when adding features: `Companion.Send` refuses `loot`/`materials` without the role (so callers must tolerate a `nil` return), `ApplyFilter` in `weinttv.lua` must not fall back to all raid rows when the filter is *forced*, and dashboard helpers return a locked marker rather than `0`.

### Bot import protocol (`modules/sync.lua`)

A second, independent channel: the Discord bot generates a `WCIMPORT:<TYPE>:<payload>` string via bot slash commands (`/export boss|raidwed|raidthu|mat|wa`), which the player pastes into the in-game Import dialog (`/wc import`, or `WeintCodex.Sync.QuickImport(str)`). Each `<TYPE>` (`BOSS`, `RAIDWED`/`RAIDTHU`/legacy `RAID`, `MAT`, `WA`) has its own hand-rolled colon/pipe/comma-delimited parser in `sync.lua` (`ParseBossImport`, `ParseRaidImport`, `ParseMatImport`, `ParseWAImport`) — these are position-based string formats, not JSON, so field order matters and is documented in the file header comment. `ProcessImport` dispatches by type tag and writes results straight into `WeintCodex.SavedData`, then calls the owning module's `Refresh`/`ResolveNames`/`RefreshDay` to update the UI.

The type tag may carry an optional community suffix — `WCIMPORT:RAIDWED@<id>:<payload>` — read by splitting the tag *after* the envelope match and *before* `:upper()`. Do not widen the envelope regex to parse it: it already captures `RAIDWED@1234` whole because `@` isn't `:`, and touching it risks all five position-based formats. A tag from another community is rejected, and every guild-internal type additionally requires the feature that gates its display (`IMPORT_FEATURE`); `WA` is free.

### Onboarding-Tour & Update-Changelog (`core/onboarding.lua` + `data/changelog.lua`)

`core/onboarding.lua` zeigt neuen Nutzern beim allerersten Login eine mehrseitige Feature-Tour (eine Seite pro Navigations-Tab) und bestehenden Nutzern nach einem Versionswechsel ein Popup mit dem, was sich geändert hat. Beide Modi teilen sich dasselbe Overlay-Fenster über `WeintCodex.MainFrame` (analog zu `modules/dialog.lua`). Getrackt wird das über `WeintCodex.SavedData.onboarding.lastSeenVersion`: `nil` → volle Tour, abweichend von `WeintCodex.Version` → Changelog-Popup mit allen Einträgen aus `data/changelog.lua` seit der zuletzt gesehenen Version, gleich → nichts. Aufgerufen wird `WeintCodex.Onboarding.Check()` aus dem `PLAYER_LOGIN`-Handler in `core/main.lua`; `/wc tour` ruft die Tour manuell erneut auf (zum Testen).

`data/changelog.lua` (`WeintCodex_ChangelogData`, neueste Version zuerst) ist eine separate, laufzeit-lesbare Kurzfassung von `CHANGELOG.md` – beide müssen bei jedem Release von Hand gepflegt werden, das eine ersetzt das andere nicht.

### WeintTV & Academy (`modules/weinttv.lua`, `modules/academy.lua`)

Slimmed-down in-game versions of the two WeintCompanion desktop features, for players on a single monitor. They need **WeintCompanion 1.3.0 or newer** — that is the version which builds and delivers the three payloads (`addon/addon_payloads.py`, `core/addon_analysis_sync.py` over there). Both are **pure renderers**: every judgement (avoidable vs. unavoidable damage, movement in metres, cooldown efficiency, the six star ratings, the training-plan order) is computed in the Companion and arrives finished over the inbox. Nothing is recalculated here, so desktop and addon cannot disagree.

- `modules/weinttv.lua` is its own nav tab (registered in the three usual places in `core/navigation.lua`: `tabs`, `SwitchTo`, `dashboardTiles`). Six table pages plus a "Nur ich / Ganzer Raid" toggle in `TitleBarActions`. The per-page entry points are exported on `WeintCodex.WeintTV` for deep links, same pattern as `WeintCodex.Charakter.ShowEnchants`.
- `modules/academy.lua` deliberately has **no** tab — it hangs in the *Charakter* sidebar (`WeintCodex.Charakter.Show`), because ratings and lessons belong to the character. Since it renders into the shared `ContentPanel` from outside `charakter.lua`, it calls `WeintCodex.Charakter.LeaveView()` so the equipment watcher does not redraw a Charakter page over it.

Two conventions inherited from the Companion must not be broken: `stars == 0` means *no data*, not *bad* (zero ratings are excluded from the average and from the weakest-area pick), and `at == -1` means *no timestamp known*, not second 0. Lesson progress is stored per character as **exclusions**, not inclusions, so newly delivered lessons are active without a migration. The log result (`results`) and the player's own checkbox (`completed`) are never written into each other — a lesson counts as done if either applies.

### Libraries

`libs/` vendors `LibStub`, `CallbackHandler-1.0`, `LibDataBroker-1.1`, `LibDBIcon-1.0` — standard WoW addon ecosystem libraries, used only for the minimap button/data-broker integration in `core/minimap.lua`. Don't hand-edit vendored library code; replace the file wholesale if it needs updating.
