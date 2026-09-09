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

## Mehrere Umschläge in einem Text (seit 3.1.2.0)

Aus **einem** Sim-Lauf kommen **zwei** Auskünfte (`SW` und `TG`). Sie
einzeln einfügen zu müssen hieß: zweimal einfügen, zweimal auf
*Importieren* — und der zweite blieb regelmäßig liegen, was man einer
Empfehlung nicht ansieht. `Sync.ProcessImportText()` sitzt deshalb jetzt
vor `ProcessImport()` und ist der einzige Eingang für beide Aufrufer
(EditBox-Knopf und `QuickImport`).

Drei Dinge daran sind nicht Geschmack:

- **Zerlegt wird an `WCIMPORT:`, nicht an Zeilenumbrüchen.** Eine
  Nutzlast darf selbst welche enthalten (eine abgeschriebene Werteliste);
  ein Umschlag beginnt dagegen nachweislich mit diesem Wort.
- **Ein einzelner String verhält sich exakt wie vorher** — derselbe
  Rückgabewert, dieselbe Meldung, derselbe Fehlertext. Alles andere wäre
  eine zweite Fassung des Importwegs, die bei der ersten Änderung
  auseinanderläuft.
- **Teilerfolg gilt als Fehler** (`false`). Die Oberfläche lässt das
  Eingabefeld dann stehen; `SW` und `TG` *ersetzen* beide, ein zweiter
  Versuch richtet also keinen Schaden an — ein geleertes Feld hätte den
  misslungenen Teil verloren.

`.github/tests/sync_test.lua` pinnt beide Richtungen.

## Der offene Sim-Lauf (`modules/simexport.lua`, seit 3.1.2.0)

**Das Addon kann nicht nachsehen, ob etwas in der Warteschlange liegt** —
prinzipiell nicht. WoW liest seine SavedVariables beim Laden *einmal*,
und `data/companion_live.lua` ist eine Lua-Datei, die beim Laden
ausgeführt wird; beides beantwortet „liegt da was?" erst *nach* einem
Neuladen, und dann ist die Frage schon beantwortet. Dateizugriff und Netz
hat ein Addon nicht.

Die Nachfrage ist deshalb eine **Erwartung**, kein Befund, und sie hängt
am einzigen Signal, das es dafür gibt: dem Klick auf *Bereitstellen*.
`SE.NoteProvided()` schreibt `awaitingAt` **vor** dem Reload (danach sind
die SavedVariables schon geschrieben), `ScheduleAwaitCheck()` sieht 150 s
nach dem Anmelden einmal nach, `SE.AwaitingFor()` lässt den Zustand nach
zwei Stunden verfallen. Beendet wird er von **beiden** Wegen
(`INBOX_HANDLERS.stat_weights`/`.target_gear` und der Importweg über die
Zwischenablage) über `SE.NoteArrival()` — welcher es war, ist für die
Frage danach ohne Belang.

**Kein modaler Dialog**: wer zurückkommt, steht vielleicht schon im
Kampf. Ein Kasten am Rand ist eine Auskunft, ein Fenster im Weg eine
Aufforderung — und *Später* beendet den Lauf endgültig, weil ein Kasten,
der wiederkommt, ebenfalls eine Aufforderung wäre.

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


## Zwei Typen kommen NICHT vom Bot

`SW` (Sim-Gewichte) und `TG` (Zielausrüstung) baut **WeintCompanion**
selbst aus einem Sim-Ergebnis. Beide sind der Weg **ohne** `/reload`:
dieselben Angaben reisen auch über die Addon-Brücke, die aber erst beim
nächsten Laden gelesen wird — und wer im Raid oder vor dem Umschmieder
steht, lädt nicht neu.

Beide stehen deshalb **nicht** in `IMPORT_FEATURE`: ein Sim-Ergebnis
gehört dem eigenen Charakter und ist nichts Gildeninternes, gleiche
Entscheidung wie bei `WA`.

Und beide werden **nicht in dieser Datei zerlegt**, sondern in dem
Modul, dem sie gehören (`SW.ParseTransfer` in `modules/statweights.lua`,
`TG.ParseTransfer` in `modules/targetgear.lua`). Das Zerlegen einer
fremden Zeichenkette ist die Sorte Rechnung, die der Testlauf ohne Spiel
prüfen können muss; `sync.lua` nimmt nur den Umschlag ab und bringt den
Spieler auf die Seite, auf der die Wirkung steht.

`TG` trägt als einziger Typ ein **viertes** Trennzeichen: die Steine
eines Gegenstands hängen mit `-` aneinander, weil `:`, `,` und `|` schon
vergeben sind. Sie sind Ziffern, ein Bindestrich kann darin nicht
vorkommen. Voller Vertrag:
`../../../WeintCompanion/docs/target-gear-bridge.md`.
