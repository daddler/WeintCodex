# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository. It is a **router**, not a knowledge base:
detailed system documentation lives under `docs/` and is loaded on demand
via the task-routing table below, not kept permanently in context.

## What this is

WeintCodex is a World of Warcraft **Mists of Pandaria Classic** (Interface
`50504`) addon: a raid guide & guild intelligence system (boss guides,
raid roster/calendar, character/twink management, materials tracking,
WeakAura distribution).

Comments and in-game UI text are in German; Lua identifiers are in
English/mixed. There is no build step, package manager, or test suite for
the addon itself — pure WoW addon Lua, loaded directly by the game client
per `WeintCodex.toc`. An offline Lua 5.1 test suite exists under
`.github/tests/` (see `docs/development/releases.md`).

## Role in the ecosystem

WeintCodex is one of three sibling repos that together form the Weint
ecosystem:

```
WeintCodex (this repo, in-game Lua)
    ↕ SavedVariables file (no network)          ↔  WeintCompanion (desktop app)
                                                        ↕ HTTP :8765
    ← clipboard (WCIMPORT string)                ←  WeintCodex Bot (Discord bot)
```

- **WeintCodex** (this repo) — the in-game addon. Judges gear/rotation
  correctness; the desktop app never re-derives what this repo decides.
- **WeintCompanion** — installs/updates this addon, bridges it to Discord,
  and is the **authoritative host for every cross-repo data contract** (see
  routing table below — most "how does X sync" answers live in
  `../WeintCompanion/docs/*.md`, a sibling checkout).
- **WeintCodex Bot** — Discord bot backend; talks to this addon only
  indirectly, via a `WCIMPORT:` string a player pastes in, or via
  WeintCompanion relaying it.

**This addon never talks to the bot or the network directly.** Everything
arrives either through `WeintCodex_SavedData`/`WeintCompanionDB`/
`WeintCompanionInboxDB` (the SavedVariables files WeintCompanion also
reads/writes) or through a copy-pasted `WCIMPORT:` string.

## Critical invariants (always relevant, keep in mind for any change)

- **UTF-8 vs. Lua byte-wise string functions.** Never use `string.upper`,
  `#`, or `:sub` on German display text — use `Spaced`/`WeintCodex.Upper`/
  `WeintCodex.Truncate`/`Utf8Len`/`Utf8Sub` from `core/ui.lua`. Details:
  `docs/architecture/overview.md`.
- **`unknown` ≠ `0`/`false`.** Sockets without base data, `headroom ==
  nil`, `stars == 0`, `at == -1`, a missing lockout entry — none of these
  may be treated as a measured zero or a negative finding anywhere in the
  codebase. Full list: `docs/invariants/data-integrity.md`.
- **What the client can answer is never derived or guessed.** Socket
  order, socket-bonus active state, gem colour, reforge value — read from
  the client, cross-check as fallback only. Five releases of bugs came
  from breaking this rule (`docs/history/gearing-lessons.md`).
- **One calculation per question, never two independent ones.** The
  recurring root cause of nearly every multi-release bug chain in this
  addon. Route through the existing single source of truth (`PlanItem`,
  `RE.CapOutlook()`/`CapContext()`, `Rationale()`, `ScanCharacter()`)
  before adding a new one. Details: `docs/invariants/data-integrity.md`.
- **`statWeights` are values PER POINT, not rank positions**, and **a
  weight never overrides a curated gem/enchant list** — the list decides
  which item is recommended, the weight only scores it. Full rule:
  `docs/systems/gearing.md`.
- **Never write to a freshly created fallback table instead of
  `WeintCodex_SavedData`.** WoW only persists variables declared in the
  `.toc`; a silent fallback loses data with no error. Details:
  `docs/invariants/data-integrity.md`.
- **`WeintCodex.toc` load order is the only dependency mechanism.** A
  module can only reference `WeintCodex.Other` if `other.lua` loads
  earlier; a new file must be added to the `.toc` in the right place
  (libraries → core → data → modules) or it silently won't load.
- **Bump `## Version` in `.toc` and `WeintCodex.Version` in
  `core/main.lua` together**, and the release tag must be exactly `v` +
  that version — see `docs/development/releases.md` for what breaks
  otherwise.

## Development workflow

No build step. Verify by loading the addon in-game (`/wc` toggles the
window) and watching for Lua errors; run `luac5.1 -p <file>` on every
changed file first (no other safety net exists). See
`docs/development/releases.md` for the release process, the three-places
version/changelog rule, and the player-facing patch-note style rules
(these also govern the onboarding tour and any other in-game or
Companion-visible text).

## Task routing — read only what the task needs

| Task touches… | Read |
|---|---|
| Sockel, Verzauberungen, Umschmieden, Tempo-Schwellen, BiS, Steinempfehlung | `docs/systems/gearing.md` (the whole file — it's one interconnected system) |
| "warum war das mal kaputt" bei Sockel/Umschmieden/Werteabgleich | `docs/history/gearing-lessons.md` |
| UI-Struktur, Theme, `core/ui.lua`, Navigationsspalte, PageHead | `docs/architecture/overview.md` |
| Companion-Sync allgemein (Inbox/Outbound-Nachrichten, `ProcessInbox`) | `docs/systems/companion-bridge.md` |
| Zugriffsprofile / `core/access.lua` | `docs/systems/access.md` + `../WeintCompanion/docs/access-profile-bridge.md` |
| WeakAuras | `docs/systems/weakauras.md` + `../WeintCompanion/docs/weakaura-bridge.md` |
| Gruppencheck oder Ausrüstungs-Alarm | `docs/systems/groupcheck-gearalert.md` |
| Encounter-Fortschritt, Lockouts, Bossnotizen | `docs/systems/encounter-tracking.md` |
| Rotationshelfer, ingame WeintTV/Academy, "wer bin ich" | `docs/systems/rotation-trainer.md` + `../WeintCompanion/docs/academy-and-practice-bridge.md` |
| Sim-Gewichte (wowsims/QE Live), Umschmiede-Export | `docs/systems/stat-weights-qelive.md` + `../WeintCompanion/docs/stat-weights-bridge.md` + `../WeintCompanion/docs/wowsims-exporter-bridge.md` |
| Onboarding-Tour, Update-Changelog-Popup | `docs/systems/onboarding-changelog.md` |
| Einkaufsliste, Opt-in-Frage, Einstellungsseite, Fensterverhalten | `docs/systems/ui-notes-shoppinglist-optin.md` |
| WCIMPORT-Import (`/wc import`, Bot-Slash-Commands) | `docs/systems/wcimport-sync.md` + `../WeintCompanion/docs/wcimport-protocol.md` |
| Raid-Anmeldeliste, Kalender-Invite, `source`/`status`/`lineup` | `../WeintCompanion/docs/wcimport-protocol.md` |
| Charakterzuordnung (`/weintcharakter`), WeintAdmin-Backup | `../WeintCompanion/docs/character-links-and-admin-bridge.md` |
| Companion-Authentifizierung/Token | `../WeintCompanion/docs/companion-auth.md` |
| Release schneiden, Changelog, Patchnote-Stil | `docs/development/releases.md` |
| Datenintegrität allgemein, Validate*-Funktionen, `unknown ≠ 0` | `docs/invariants/data-integrity.md` |

Cross-repo tasks (something touches Codex **and** Companion **and/or**
Bot): read this table's Companion-doc pointers first — they are the
authoritative contract for the wire format, and the Codex-local docs above
only add what's specific to this repo's implementation.
