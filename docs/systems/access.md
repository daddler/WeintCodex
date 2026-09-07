# Zugriffsprofile & Freigaben (`core/access.lua`)

**This is data hygiene and UX, not a security boundary.**
`WeintCodex_SavedData` is an editable Lua file on the player's disk —
anyone can set `features["materials.view"] = true` by hand. Its job is: a
non-guild raider's Companion never mixes two guilds' data, nobody sees a UI
full of numbers that don't concern them, and nothing guild-internal leaves
a client that isn't entitled to send it.

Only the Discord bot *could* enforce more, by refusing to emit a payload a
role isn't entitled to — and it currently does not. So the system delivers
exactly the three things above and nothing further; **it does not provide
confidentiality.** Say so in any doc or comment you write about this
system — that framing is the whole point. The role→feature mapping lives
in WeintCompanion, which puts it on the player's disk too, under the same
caveat for the same reason.

`core/access.lua` loads between `core/ui.lua` (it needs `Colors`/
`CreateCard` and the navigation column, still reachable under the legacy
name `IconRail`) and `core/navigation.lua`. It must **never** capture
`WeintCodex.Navigation` in a file-local, since that file loads later —
access it inside function bodies only.

WeintCompanion (**1.4.0 or newer**) delivers an `access_profile` inbox
message with `community`, `identity`, `tier`, `tierLabel`, `roles`,
`features`, `issuedAt`/`expiresAt`, `companionVersion` and an optional
free-text `notice`. Full schema and binding rules: `../../../WeintCompanion/
docs/access-profile-bridge.md`. `community.id` is a **string** — a Discord
snowflake as a Lua 5.1 number stringifies to `1.23e+18` and would never
compare equal to the Companion's decimal string.

- **One community per client.** The first profile binds; a profile or
  message from another community is *rejected*, never re-bound. `/wc
  access reset` (two-step, requires `/wc access reset bestaetigen`) unbinds
  **and deletes** the guild-internal keys — otherwise the previous guild's
  rosters, materials and tactics would sit there when the client rebinds,
  which is exactly the mixing this system exists to prevent.
- **`Can(featureKey)` order:** no profile → `true` (a client that never
  got a profile behaves exactly as before, that's deliberate); expired
  beyond grace → only `STALE_FEATURES`; explicit `features[key]` boolean
  wins; otherwise the `TIER_FEATURES` fallback matrix; unknown tier → deny
  plus one loud chat warning. Only real booleans count in `features`, so
  `"true"` or `1` fall through to the matrix instead of silently allowing.
  The nine keys are `raids.view`, `raids.edit`, `calendar.view`,
  `calendar.invite`, `materials.view`, `materials.scan`,
  `bossguides.tips`, `weinttv.raid`, `loot.report`. **The matrix must
  never grant `calendar.view` without `raids.view`** — the calendar reads
  the roster for its invite preview. (Companion's `access_roles.py`
  `TIER_FEATURES` must mirror this exactly, same invariant stated from the
  other side.)
- **Expiry** is `fresh` → `grace` (14 days, full rights, visible warning)
  → `expired`. Expired keeps *read* access to what is already on disk and
  instead blocks ingest (`IngestAllowed()`) and every write/outbound
  capability. Hiding data the player already has would be theatre; locking
  a raider out of Wednesday's roster because the desktop app didn't run
  for three weeks would be a support ticket.
- **UI rule: lock, don't hide.** Only `raids`/`materials`/`calendar` carry
  a `feature` in `navigation.lua`'s `tabs`; the rest gate inside their page
  so their neutral half stays open. `SwitchTo` is the single choke point
  (covers the rail, `GoToTab`, dashboard tiles/stats and `core/search.lua`)
  and routes denied tabs to `ShowAccessLock`. `/wc import` and the
  dashboard's Import button bypass it on purpose — that tab is never
  locked, and the real gate for the data sits in `ProcessImport`. Icon
  colour goes through `TintIcon`, because `SetTabActive`/`OnEnter`/
  `OnLeave` would otherwise overwrite the locked tint.
- Gated capabilities that are easy to miss when adding features:
  `Companion.Send` refuses `loot`/`materials` without the role (so callers
  must tolerate a `nil` return), `ApplyFilter` in `weinttv.lua` must not
  fall back to all raid rows when the filter is *forced*, and dashboard
  helpers return a locked marker rather than `0`.
