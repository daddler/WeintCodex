# Changelog

Alle nennenswerten Änderungen an WeintCodex werden hier festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/) angelehnt; Versionsnummern folgen dem bisherigen 4-teiligen Schema (`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

## [1.0.1.0] – 2026-08-03

### Behoben
- Verzauberungs-Check zeigte unabhängig von der Ausrüstung `8/8`. Die Nebenhand wurde über die Gegenstandsklasse erkannt (`classID == 2`), wodurch Schilde (Klasse 4 = Rüstung) und Beihand-Gegenstände stillschweigend aus der Wertung fielen. Die Erkennung läuft jetzt über `itemEquipLoc` und unterscheidet Waffe, Schild und Beihand-Gegenstand
- Der Nenner `8` bei angelegtem Zweihänder stimmte nur zufällig (Slot 17 ist dann leer) – eine echte Zweihänder-Erkennung gab es nicht. `IsTwoHander` macht den Fall jetzt explizit
- Eine noch nicht im Client-Cache liegende Nebenhandwaffe fiel dauerhaft aus dem Nenner. Sie wird jetzt für die Nachlieferung vorgemerkt (`GET_ITEM_INFO_RECEIVED`) und beim Neuscan berücksichtigt

### Neu
- Schild- und Nebenhand-Verzauberungen in `data/enchants.lua` (Großes Parieren, Mächtige Intelligenz) samt Empfehlungen bei den 19 Specs, die überhaupt einen Schild oder Beihand-Gegenstand tragen können. Schildgebundene Empfehlungen werden ausgeblendet, wenn dort kein Schild steckt
- Ringverzauberungen, aber nur für Verzauberer – erkannt über die Skill-Line 333 statt über den lokalisierten Berufsnamen. `SKILL_LINES_CHANGED` löst einen Neuscan aus
- Hinweis „Nebenhand: Kein Gegenstand angelegt“ bei angelegter Einhandwaffe. Bewusst nur als Hinweis und nicht als fehlende Verzauberung, sonst würde die Quote lügen
- **WeintTV** als eigener Tab: Tiefenanalyse des zuletzt von WeintCompanion ausgewerteten Pulls – erhaltener und vermeidbarer Schaden (inkl. „Was tun“-Hinweis), Wirkungsdauern, Aktivzeit, Laufwege, Cooldown-Nutzung, Unterbrechungen und Mechanikfehler. Umschaltbar zwischen „Nur ich“ und „Ganzer Raid“
- **WeintAcademy** als Unterseiten unter *Charakter*: Lernzentrum mit Bewertung je Bereich, Trainingsplan mit Lektionsschritten und Erledigt-Haken, sowie Lektionskatalog zum Ein- und Ausblenden
- Academy-Lektionen sind über die globale Suche auffindbar

### Geändert
- Die Companion-Inbox (`WeintCompanionInboxDB`) versteht drei neue Nachrichtentypen: `academy_catalog`, `academy_state` und `weinttv_report`. Deren Nutzlast ist eine verschachtelte Lua-Tabelle statt einer Zeichenkette; `raid_import` bleibt unverändert. Eine fehlerhafte Nachricht reißt die restliche Warteschlange nicht mehr mit
- Ingame gesetzte Erledigt-Haken und Katalog-Ausschlüsse gehen als Zustandsnachricht `academy` an WeintCompanion zurück
- `CreateScrollArea` und die Zahlen-/Zeitformate liegen jetzt in `core/ui.lua` und werden von Charakter, WeintTV und Academy gemeinsam genutzt

### Hinweise
- Ein Live-Dashboard ist ingame technisch ausgeschlossen: WoW liest `SavedVariables` nur beim Login bzw. `/reload` ein. WeintTV und Academy zeigen deshalb immer den Stand der letzten Lieferung, was in der Kopfzeile auch so benannt wird
- Die Verzauberungs-IDs der neuen Schild-, Nebenhand- und Ringeinträge sind als Platzhalter mit `verify = true` hinterlegt und per `/wc vz` gegenzuprüfen. Die Bewertung selbst läuft über den Tooltip-/Namensabgleich und ist davon nicht betroffen
- Damit die neuen Bereiche Daten erhalten, muss WeintCompanion die drei Nachrichtentypen befüllen – das ist Folgearbeit im Companion-Repo. Ohne Daten zeigen beide Bereiche einen erklärenden Leerzustand

## [1.0.0.5] – 2026-08-03

### Behoben
- Loot-Logging wird nur noch im Raid-Kontext aktiv: erforderlich sind gleichzeitig eine Raidgruppe, eine Raidinstanz (`instanceType == "raid"`) und aktivierter Meisterlooter (`GetLootMethod() == "master"`). Dungeons, Szenarien, Schlachtfelder, Worldbosse und Loot außerhalb von Instanzen erzeugen keine `#loot`-Meldungen mehr
- Die Prüfung greift zusätzlich beim verzögerten Nachmelden (Item-Info-Retry), damit ein Drop nicht doch noch gemeldet wird, wenn der Spieler die Instanz verlässt oder die Lootregel wechselt

## [1.0.0.4] – 2026-08-03

### Behoben
- BiS-Daten: Füße-Eintrag für Schutz-Paladin ergänzt (fehlte komplett) sowie für Schutz-Krieger und Blut-Todesritter korrigiert – Sporen des Wolfsreiters droppen bei den Dunkelschamanen, nicht bei den Schätzen Pandarias bzw. Immerseus

## [1.0.0.3] – 2026-07-29

Konsolidierungs-Release: der Feature-Branch mit sämtlichen bisherigen Änderungen (Onboarding-Tour, BiS-Listen, Positionierungsbilder, Best-Try-Anzeige – siehe Einträge unten) wurde vollständig auf `main` gemergt. Funktional keine Neuerungen gegenüber 1.0.0.0, der Versionssprung markiert den Abschluss dieses Release-Batches und synchronisiert `main` mit dem tatsächlich ausgelieferten Stand.

### Intern
- Versionsnummer in `WeintCodex.toc` und `core/main.lua` synchronisiert (1.0.0.1 → 1.0.0.3)
- `data/changelog.lua`-Eintrag ergänzt, damit das Update-Popup bestehenden Nutzern den Sprung korrekt anzeigt

## [1.0.0.0] – 2026-07-27

Erster offizieller Release. Funktional identisch zu 0.9.9.38 – der Versionssprung markiert den Abschluss der Beta-Phase, keine Breaking Changes.

### Neu
- README.md mit Funktionsübersicht, Ökosystem-Erklärung (Companion/Bot) und Installationsanleitung
- CHANGELOG.md (dieses Dokument)
- Addon-Tour beim ersten Start: kurzer, mehrseitiger Rundgang durch alle Bereiche (Charakter, Bossguides, Raids, Materialien, Kalender, WeakAuras, Import)
- Update-Popup, das bei neuen Versionen automatisch anzeigt, was sich geändert hat (`/wc tour` zeigt die Tour jederzeit erneut)

### Intern
- CLAUDE.md-Versionsreferenz aktualisiert

## [0.9.9.36] – [0.9.9.38] – 2026-07-27

### Neu
- Optionaler „Aufstellung"-Abschnitt (Positionierungsbilder) für Bossguides, als anklickbares Thumbnail mit Lightbox
- Positionierungsbilder für alle 14 SoO-Bosse verdrahtet, inkl. Erklärtexte aus dem Discord-Bot
- Mehrere Positionierungsbilder pro Boss möglich (eigener `Positioning`-Asset-Ordner)

### Behoben
- BiS-Daten: Klaxxi-Zuordnung und Eule-Bossliste korrigiert

## [0.9.9.30] – [0.9.9.35] – 2026-07-25 – 2026-07-26

### Neu
- Echte Best-in-Slot-Liste aus PDF eingepflegt, inkl. Fallback für Offensiv-Tankspecs
- BiS-Liste im Bossguide-Inspector angezeigt
- „Best Try" pro Boss in den Bossguides
- Boss-Fortschritts- und Verzauberungsanzeige korrigiert

### Verbessert
- Validierungslogik für Verzauberungstext-Parsing erweitert
- Kommentare zu Item-Stats und Parsing-Logik präzisiert
- `StatsMatch`-Funktion vereinfacht
- Edit-Box-Handling in `raids.lua` refaktoriert
- Namensüberschreibung wird vor dem Neuaufbau der Raidanzeige angewendet

### Behoben
- Stärke-Wert für Verzauberung 4415 korrigiert

## [0.9.9.20] – [0.9.9.25] – 2026-07-21 – 2026-07-23

### Neu
- Loot-Erfassung ohne RCLootCouncil
- Sockelsteine werden im Gildenbankscan erfasst und für den Companion-Export vorbereitet
- Twinkverwaltung meldet Charakterauswahl sofort an die Companion-App

### Behoben
- Verzauberungsanzeige zeigte Live-Tooltip-Namen statt DB-Namen
- Verzauberungs-IDs 4804/4806 (Schulter-Inschriften) waren vertauscht
- Verzauberungs-ID 4426 (Füße) war fälschlich als Pandarenschritt/-pfoten geführt
- Hartcodierte Versionsanzeige in `main.lua` nachgezogen

---

Ältere Versionen sind nicht im Detail dokumentiert (Historie beginnt mit 0.9.9.20). Frühere Stände lassen sich bei Bedarf aus der Git-Historie rekonstruieren.
