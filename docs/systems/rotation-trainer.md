# Rotationshelfer (`data/rotations.lua` + `modules/rotation_engine.lua` +
`modules/rotationtrainer.lua`)

Freistehendes Fenster mit der Prioritätenliste der aktuellen Spec, das
sich an einer Trainingspuppe von selbst öffnet (`/wc training` sonst).
Anders als der Rest des Addons ist das **keine reine Anzeige gelieferter
Daten**, sondern eine eigene Live-Engine – die Companion hat keine
Combatlog-Auswertung, und die Inbox wird nur bei Login gelesen.

Die drei Dateien sind strikt getrennt und müssen es bleiben:
`data/rotations.lua` beschreibt *was* gilt, `rotation_engine.lua`
entscheidet, `rotationtrainer.lua` zeichnet nur. Die Engine lädt vor dem
Trainer (`.toc`) und kennt keine Farben und keine Frames.

- **Sortierung statt Marker.** `RE.Evaluate(specKey)` verteilt jede Regel
  auf einen Topf (`ready` → `resource` → `waiting` → `blocked` → `unknown`)
  und sortiert danach. Dass eine gedrückte Fähigkeit nach unten wandert,
  ist kein Sondereffekt, sondern fällt aus dieser Sortierung heraus: sie
  ist im selben Moment mindestens für den GCD nicht verfügbar. `RE.NoteCast`
  merkt sie zusätzlich für die GCD-Dauer vor, damit das ohne Wartezeit auf
  die Server-Antwort passiert.
- **Der GCD zählt als „bereit".** Der GCD kommt aus
  `GetSpellCooldown(61304)` mit einer Schätzung aus Zauberhast als
  Rückfallweg.
- **Jede Bedingung erzeugt ihren eigenen Begründungstext** (mit
  Live-Zahlen), auch die nicht erfüllte. Neue Bedingungen müssen deshalb
  einen Text in `Checks` mitbringen, und `CHECK_ORDER` legt fest, welcher
  Grund gewinnt.
- **Bewertung rangbasiert** (`RE.Session`): Rang 1 = 1.0, Rang 2 = 0.65,
  Rang 3 = 0.35, sonst 0.15. Gewertet wird nur, was in `rules` steht.
  Gewichtung: Priorität 60 %, GCD-Auslastung 20 %, Aura-Laufzeit 20 %
  (ohne überwachte Auren 80/20). Geprüft wird gegen die Rangliste **vor**
  dem Zauber plus die vom Takt davor.
- `Evaluate` liefert immer dieselbe Tabelle zurück (10 Hz, kein Müll für
  den GC). Wer den Zustand aufheben will, zieht `RE.RankList(plan, into)` –
  der Trainer hält davon zwei und tauscht sie pro Takt.
- Die Companion-Nachricht `dummy_practice_session` behält ihre sieben
  Felder; `compliancePercent` trägt jetzt die Gesamtnote. Voller Vertrag:
  `../../../WeintCompanion/docs/academy-and-practice-bridge.md`.
- **Erst drei Minuten sind eine Sitzung.** `MIN_SESSION_SECONDS` (180) ist
  die Untergrenze, unter der nichts gemeldet wird — bewertet und angezeigt
  wird trotzdem. **Dieselbe Zahl steht in `core/academy_dummy_sync.py` der
  Companion und muss dort gleich bleiben.** Damit drei Minuten überhaupt
  erreichbar sind, beendet `PLAYER_REGEN_ENABLED` die Sitzung nicht mehr
  sofort, sondern erst nach `RESUME_WINDOW` (20 s) ohne Kampf.
- Liste, Bewertung und Einstellungen hängen an einer beschrifteten
  Reiterleiste unter der Kopfzeile (Segmented Control), nicht an zwei
  Zeichen-Buttons in der Kopfzeile. Der wechselnde Inhalt beginnt bei
  `CONTENT_TOP`, nicht bei `HEADER_H`.
- Spell-IDs sind das Hauptrisiko dieser Dateien (MoP-IDs, nicht am Client
  verifizierbar). Eine unbekannte ID verschwindet nicht still: die Zeile
  bleibt sichtbar mit „nicht erlernt", `WeintCodex_ValidateRotationData(specKey)`
  löst beim Login jede ID der eigenen Spec auf, und `/wc training check`
  gibt die ganze Liste mit Client-Namen aus.
- Tank-Profile (`*_OFFENSIVE`) haben bewusst **keine** Liste und fallen
  auch nicht auf die Basis-Spec zurück — anders als bei der Ausrüstung
  (`modules/bis.lua`) wäre die falsche Rotation schlechter als gar keine.

## WeintTV & WeintAcademy im Spiel (`modules/weinttv.lua`, `modules/academy.lua`)

Slimmed-down in-game versions of the two WeintCompanion desktop features,
for players on a single monitor. Need **WeintCompanion 1.3.0 or newer**.
Both are **pure renderers**: every judgement (avoidable vs. unavoidable
damage, movement in metres, cooldown efficiency, the six star ratings, the
training-plan order) is computed in the Companion and arrives finished
over the inbox — nothing is recalculated here (voller Vertrag:
`../../../WeintCompanion/docs/academy-and-practice-bridge.md`).

- `modules/weinttv.lua` is its own nav tab. Six table pages plus a "Nur
  ich / Ganzer Raid" toggle in `TitleBarActions`.
- `modules/academy.lua` **has its own tab since 2.0.0.0** (until 1.3.3.3 it
  hung in the *Charakter* sidebar, because ratings and lessons belong to
  the character). It still calls `WeintCodex.Charakter.LeaveView()` when
  rendering into the shared `ContentPanel` — otherwise the equipment
  watcher redraws a Charakter page over it. Load-bearing, not legacy.

Two conventions inherited from the Companion must not be broken: `stars ==
0` means *no data*, not *bad*, and `at == -1` means *no timestamp known*,
not second 0. Lesson progress is stored per character as **exclusions**,
not inclusions. The log result (`results`) and the player's own checkbox
(`completed`) are never written into each other.

**Seit 3.0.0.0 sagt die Kopfzeile, welchen Kampf sie bewertet** — Boss,
Schwierigkeit, Pull, Ausgang, Durchschnittsnote — als fertiger Satz
`encounterText` von `gui/widgets/tv/encounter_meta.py` drüben, **nicht**
hier nachgebaut. Und „0 von 0 Lektionen erledigt" steht nirgends mehr.

### Wer ist „ich"? (`core/names.lua`)

Bis 1.3.2.3 schlug **die gelieferte Identität den eingeloggten Charakter**
— jeder Twink sah die Auswertung des Mains. `core/names.lua` (lädt direkt
nach `core/main.lua`, vor `core/ui.lua`) ist der eine Ort, an dem „ist das
derselbe Charakter" beantwortet wird. **Ein fehlender Realm ist ein
Platzhalter, kein Widerspruch.** Dieselben drei Regeln stehen drüben in
`analyzer/names.py`; weichen sie ab, ist „ich" im Spiel jemand anderes als
„ich" auf dem Desktop.

- **WeintTV löst die Identität selbst auf.** `ResolveMe()` sucht im
  raidweiten Bericht den eingeloggten Charakter und nimmt **die
  Schreibweise des Berichts**; nur wenn er nicht vorkommt, bleibt
  `report.me`. `ApplyFilter` liefert `fellBack`: der stille Rückfall „0
  Treffer → ganzer Raid" war der Grund, warum die falsche Identität so
  lange unbemerkt blieb.
- **Die Academy liegt je Charakter.**
  `SavedData.academy.states[<Charakter>]` / `.catalogs[…]` /
  `.lastCharacter`. **Nie wird eine fremde Auswertung als eigene
  gezeichnet.** `character == "-"` gilt als unbeschriftet und landet beim
  eingeloggten Charakter.
- **Der Katalog trägt keine Identität**, zwischengelegt als
  `store.pendingCatalog` und von der unmittelbar folgenden
  `academy_state`-Nachricht übernommen (Kopplung in beiden Dateien
  kommentiert, siehe `companion-bridge.md`).
- **`/wc access reset`** löscht gezielt `states`/`catalogs`/
  `lastCharacter`. `academy` steht bewusst **nicht** in `GUILD_KEYS`.
