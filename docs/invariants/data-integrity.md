# Data-integrity invariants

Cross-cutting rules that hold across every system in this addon. If you
touch gear, sync, or any inbound/outbound message, re-check this list.

## `unknown` ≠ `0` / `false`, everywhere

This addon draws the line between "measured" and "not measured" in dozens
of places, and getting it wrong turns a data gap into a false finding:

- **Sockets:** `ScanItemSockets` returns a second value — whether the
  client had the item's base data at all. Without it, "0 Sockel" would be
  a claim about the addon's item cache, not the armor. `socketsKnown`
  travels through the gear-alert and character scan for this reason.
- **Headroom (caps/tempo/reforge):** `headroom == nil` means "no
  statement" — the addon does not know the current value or no ladder
  rung is reachable. Never treated as 0 remaining.
- **`stars == 0` (WeintTV/Academy, mirrored from Companion):** means "no
  data", not "bad". Zero-star ratings are excluded from averages and from
  the weakest-area pick, never counted as a failing grade.
- **`at == -1`:** no known timestamp, never second 0.
- **Encounter lockouts:** a missing lockout entry can mean either "not
  killed" or "server hasn't sent raid info yet" — `RefreshFromLockout`
  only ever sets `cleared = true`, never clears it, for exactly this
  reason.
- **BiS lists:** `WeintCodex.BiS.GetSummary(specKey)` returns a second
  value saying whether a list is maintained for the spec at all, so "0
  offen" is never claimed where nothing was checked.
- **Gear-alert:** `SlotVerdict` has three outcomes, not two — a
  not-yet-cached item is not the same as an item with nothing wrong.

## Code is authority for what the client can answer

Learned across five releases of socket-evaluation bugs (see
`../history/gearing-lessons.md`): **anything the client itself can report
(socket order, socket-bonus active/inactive, gem colour, upgrade level,
reforge value) must be read from the client, never derived or
guessed-and-cross-checked-after-the-fact.** A cross-check is fine as a
fallback; a guess used as the primary source is not.

## One calculation per question, never two

The recurring root cause behind nearly every multi-release bug chain in
this addon (socket recommendation, reforge planning, enchant grading) is
**the same question answered by two independent code paths that
eventually disagree**. The fix is always structural, never a clamp: route
every caller through one function (`PlanItem` for gems, `RE.CapOutlook()`/
`CapContext()` for caps, `Rationale()` for explanations, `ScanCharacter()`
for gear state). When adding a new caller for "what should this
socket/enchant/reforge be", check whether an existing single source of
truth already answers it before writing a second implementation.

## Validation functions run at login and are advisory, not corrective

`WeintCodex_ValidateSpecData()`, `WeintCodex_ValidateBiSData()`,
`WeintCodex_ValidateGemWeights()`, `WeintCodex_ValidateEnchantWeights()`,
`WeintCodex_ValidateBreakpointData()`, `WeintCodex_ValidateReforgeData()`,
`WeintCodex_ValidateRotationData(specKey)`, `WeintCodex_ValidateQELiveData()`
— all are drift guards between hand-maintained data tables that can go
stale independently (an enchant ID renamed by Blizzard, a gem weight that
contradicts its own curated list, a stat-key spelling mismatch). Their
findings are **data questions for a human**; the code must never try to
silently correct or paper over what they report.

## Diagnostic slash commands exist because these bug classes are invisible from outside

`/wc sockel`, `/wc tempo`, `/wc umschmieden prüfen`, `/wc vz zeilen`,
`/wc vz`, `/wc alarm berufe`, `/wc kalender`, `/wc simmen prüfen`, `/wc qe
prüfen`, `/wc einkauf prüfen` all print every intermediate value a
calculation used. This is not verbosity for its own sake: several distinct
root causes (a wrong data-table entry, a silent client answer, a stale
cache, a self-set player override) produce the *identical* visible symptom
("wrong gem recommended"), and without printing the intermediate numbers
that symptom is not diagnosable from a bug report alone.

## SavedData is written directly, never into a freshly created fallback table

`SetBossNoteColumn` once carried `if not WeintCodex.SavedData then
WeintCodex.SavedData = {} end` as a defensive fallback — exactly the kind
of line that never fails loudly. WoW only persists the variables declared
in the `.toc`; a fresh table created at runtime is never written to disk.
The user types, the field shows the text, and after the next login it is
gone — indistinguishable from "an update deleted my notes". Never add a
silent fallback that creates a new table in place of `WeintCodex_SavedData`.

## WoW only writes SavedVariables at logout/`/reload`

An addon cannot flush data mid-session; a crash or force-quit loses
everything since login. This bounds what any addon-side guarantee can
promise, and is why WeintCompanion checks the file's mtime/size
immediately before replacing it and backs up SavedVariables on every
update (see `../../../WeintCompanion/CLAUDE.md`).
