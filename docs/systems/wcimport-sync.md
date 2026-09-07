# Bot import protocol (`modules/sync.lua`)

Codex-Parser-Seite des WCIMPORT-Protokolls. Voller, autoritativer Vertrag
(Bot-Erzeugung, alle Typen, Feldbedeutungen, `source`/`status`/`lineup`,
die drei Fehler des Kalender-Einladungslaufs): `../../../WeintCompanion/docs/
wcimport-protocol.md`. Diese Datei hält nur die Codex-lokalen Fakten, die
dort nicht stehen.

A second, independent channel: the Discord bot generates a
`WCIMPORT:<TYPE>:<payload>` string via bot slash commands (`/export
boss|raidwed|raidthu|mat|wa`), which the player pastes into the in-game
Import dialog (`/wc import`, or `WeintCodex.Sync.QuickImport(str)`). Each
`<TYPE>` (`BOSS`, `RAIDWED`/`RAIDTHU`/legacy `RAID`, `MAT`, `WA`) has its
own hand-rolled colon/pipe/comma-delimited parser in `sync.lua`
(`ParseBossImport`, `ParseRaidImport`, `ParseMatImport`, `ParseWAImport`)
— these are position-based string formats, not JSON, so field order
matters and is documented in the file header comment. `ProcessImport`
dispatches by type tag and writes results straight into
`WeintCodex.SavedData`, then calls the owning module's
`Refresh`/`ResolveNames`/`RefreshDay` to update the UI.

The type tag may carry an optional community suffix —
`WCIMPORT:RAIDWED@<id>:<payload>` — read by splitting the tag *after* the
envelope match and *before* `:upper()`. Do not widen the envelope regex to
parse it: it already captures `RAIDWED@1234` whole because `@` isn't `:`,
and touching it risks all five position-based formats. A tag from another
community is rejected, and every guild-internal type additionally requires
the feature that gates its display (`IMPORT_FEATURE`); `WA` is free.

Seit 2.8.0.0 gibt es einen sechsten Typ, und er ist der einzige, der
**nicht aus Discord** kommt: `SW` trägt die Wertegewichte aus einem Sim und
wird von WeintCompanion erzeugt (siehe `stat-weights-qelive.md`).
Er steht aus demselben Grund wie `WA` nicht in `IMPORT_FEATURE`, und sein
Parser liegt in `modules/statweights.lua`, nicht hier.
