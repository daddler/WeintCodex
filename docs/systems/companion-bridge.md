# Companion bridge (bidirectional sync)

The addon and WeintCompanion communicate only through two Lua tables in the
shared `SavedVariables` file (`WeintCodex.lua`), never directly over the
network:

- **Outbound** (`WeintCompanionDB`, written by `modules/companion.lua` via
  `WeintCodex.Companion.Send(messageType, payload)`): a `queue` of `{id,
  created, version, type, payload}` messages. "State" message types
  (`materials`, `character`, `calendar`, `academy` — see `STATE_MESSAGES`)
  replace any existing queued message of the same type instead of
  appending, since only the latest state matters. WeintCompanion's
  `SyncManager` drains this queue and clears entries it successfully
  delivers.
- **Inbound** (`WeintCompanionInboxDB`, written by WeintCompanion's
  `InboxWriter`): processed once per login via
  `WeintCodex.Companion.ProcessInbox()` (called from the `ADDON_LOADED`
  handler in `core/main.lua`). `INBOX_HANDLERS` in `companion.lua`
  dispatches by `message.type`: `raid_import` carries a `WCIMPORT` string
  and goes to `WeintCodex.Sync.QuickImport` (see `wcimport-sync.md`), while
  `access_profile`, `academy_catalog`, `academy_state`, `weinttv_report`,
  `weakaura_library`, (since 2.8.0.0) `stat_weights` and (since 3.0.2.0)
  `target_gear` carry **nested Lua tables** and are stored in
  `WeintCodex.SavedData.access` / `.academy` / `.weinttv` /
  `.weakAuraLibrary` / `.statWeights` / `.targetGear`. Each handler runs in
  `pcall`, so one malformed message cannot strand the rest of the queue.

  `stat_weights` and `target_gear` are the two that come from
  **WeintCompanion itself** rather than from the bot — both are read out of
  a wowsims run for one character. They differ in one deliberate way:
  a weight set is *offered* and takes effect on a click, a target state
  simply *applies* (it can only act where the very item it was simmed
  with is still equipped, and every affected row names the sim as its
  source). See `gearing.md`, section *Der Zielzustand aus dem Sim*.
  Full payload schemas: header comment of `modules/companion.lua` (and for
  `access_profile` in `core/access.lua`). Full cross-repo contracts for
  each of these live in `../../../WeintCompanion/docs/*.md` — see the
  routing table in the root `CLAUDE.md`.

`ProcessInbox` runs in **two passes**: first every `access_profile`, then
everything else. Without that ordering, the very batch that a first-time
profile is supposed to gate would still slip through. In the second pass a
message whose optional `message.community` differs from the binding is
dropped (counted in `SavedData.access.rejections`, one summary warning).
Dropped messages are still wiped along with the rest — keeping them would
repeat the warning every login and, worse, let weeks-old data from a
previous community be accepted after a legitimate `/wc access reset`.

The inbox is read **only at login/reload** — WoW never re-reads
`SavedVariables` at runtime. Anything built on it is therefore a report of
the last delivery, never a live view; both `weinttv.lua` and `academy.lua`
say so in their headers and in the UI.

## Local-only outbound messages (never forwarded to the bot)

Two different messages fire on every `PLAYER_LOGIN`, and confusing them is
easy:

- `WeintCodex.Companion.ReportCharacter()` sends the **whole twink list**
  (`name|class|realm,…`) onward to the Discord bot, for calendar-invite
  class/name resolution. It carries **no marker for which of them is
  currently logged in**.
- `WeintCodex.Companion.ReportLoggedInCharacter()` (since 1.3.3.0) answers
  exactly that question, as its own type `character_report`, handled
  locally by the Companion and **never forwarded to the bot** — the same
  pattern as `dummy_practice_session`. Deliberately not an extension of
  `character`: anything hung on that message becomes a bot contract. It
  only sends when `WeintCompanionInboxDB.companionVersion` is ≥ 1.7.0
  (written by `InboxWriter.send_batch()` on every write, including an
  empty one) — an older Companion would route the unknown type into its
  generic branch, POST it to the bot, fail, never remove it and log an
  error every five seconds. `character_report` is in `STATE_MESSAGES`, so
  at most one ever exists.

A third message answers the gear question, since 1.3.3.1:

- `WeintCodex.Companion.ReportCharacterSheet()` sends `character_sheet` —
  item level, per-slot enchant/gem status, the counts, the open BiS slots
  and the ready-made defect texts of the logged-in character. Local like
  the two above. Full contract: `../../../WeintCompanion/docs/
  character-sheet-bridge.md`.

Four things about it that are not taste:

- **This addon judges, the Companion draws.** Which enchant is optimal,
  which gem sits wrong and which stat is over cap is decided by
  `ScanCharacter()` in `modules/charakter.lua`, where spec profiles, caps,
  socket bonuses and the real item tooltip exist. That is the exact reverse
  of WeintTV/Academy, and for the same reason: two evaluations of one fact
  drift apart, and then game and desktop contradict each other.
- **Not at `PLAYER_LOGIN`.** Neither the specialization nor the client's
  item cache is reliable there, and a scan at that moment reports
  half-empty gear as a *finding*. The watcher in `companion.lua` fires on
  `PLAYER_ENTERING_WORLD` (8 s) and debounced (3 s) on equipment/profession/
  spec changes, and only sends when the payload actually changed — a full
  scan reads every item's tooltip, and `PLAYER_EQUIPMENT_CHANGED` fires
  repeatedly while regemming.
- **`CompanionAtLeast()` grew an optional `patch` argument** for this. The
  message needs Companion 2.0.1 and 2.0.0 was already shipped, so "at
  least 2.0" would have included exactly the version that does not know
  the type.
- **The payload is flat and positional** (`~` sections, `;` records, `|`
  fields) because `addon/sync_reader.py` on the other side reads outbound
  payloads as a single string; nested tables exist only in the inbound
  direction. `CleanField()` strips the three separators plus `"`, `\` and
  newlines from anything client-supplied — an item name could otherwise
  take the structure apart, and a backslash would break the Lua string the
  Companion writes the surviving queue back into.

## Companion-local practice/progress messages

`dummy_practice_session` (Rotationshelfer) and the `academy`-state return
path also never reach the bot. Full detail: `../../../WeintCompanion/docs/
academy-and-practice-bridge.md`; the Codex-side trigger conditions are in
`rotation-trainer.md`.

## Verwandt

- Zugriffsprofile: `access.md` + `../../../WeintCompanion/docs/
  access-profile-bridge.md`
- WeakAuras: `weakauras.md` + `../../../WeintCompanion/docs/
  weakaura-bridge.md`
- Sim-Gewichte: `stat-weights-qelive.md` + `../../../WeintCompanion/
  docs/stat-weights-bridge.md`
- Live-Brücke (`companion_live.lua`, überlebt `/reload`): `../../
  WeintCompanion/docs/live-bridge.md`
- WowSimsExporter-Weiterleitung: `../../../WeintCompanion/docs/
  wowsims-exporter-bridge.md`
