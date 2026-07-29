# Changelog

Alle nennenswerten Änderungen an WeintCodex werden hier festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/) angelehnt; Versionsnummern folgen dem bisherigen 4-teiligen Schema (`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

## [1.0.0.2] – 2026-07-29

Sammelfix für gemeldete Fehlempfehlungen auf den Charakter-Seiten „Verzauberungen" und „Sockel".

### Behoben
- Angelegte Verzauberungen wurden bei falsch zugeordneten Verzauberungs-IDs gar nicht erkannt: Der Tooltip-Scan verlangte, dass die gefundene Zeile zu genau dem Datenbankeintrag passt, den er eigentlich korrigieren sollte. Betroffene Slots zeigten die falsche Verzauberung mit „(?)" und empfahlen die Verzauberung, die bereits angelegt war (gemeldet für Furor-Krieger-Handschuhe mit „+170 Stärke")
- Item-eigene Werte, Umschmiede- und Steinzeilen werden jetzt sicher von der Verzauberungszeile unterschieden – über einen Abgleich mit dem Tooltip desselben Items ohne Steine und Verzauberung
- Sockelempfehlungen berücksichtigten nur `bestGems[<Sockelfarbe>]`, obwohl Mischfarben den Sockelbonus genauso aktivieren (Lila/Orange passen in Rot, Grün/Lila in Blau). Dadurch wirkte Farb-Matchen systematisch zu teuer und Sockelboni wurden zu oft verworfen
- Die Sockelbonus-Entscheidung läuft jetzt nach der Cap-Prüfung: Für einen bereits treffergecappten Charakter werden Treffer-Steine nicht mehr als Match-Kandidaten eingerechnet
- Eingesetzte Steine wurden gegen die Liste ihrer *eigenen* Steinfarbe bewertet statt gegen das, was in diesem Sockel richtig wäre
- Die echte Sockelreihenfolge wird aus dem Item-Tooltip gelesen; bei Items mit gemischten Sockelfarben saß der Stein bisher unter der falschen Sockelfarbe
- Zahnrad-Sockel (Ingenieurskunst) werden als eigene Sockelfarbe erkannt statt als Zusatzsockel
- Willenskraft-Steine wurden für Eulen-Druiden, Schatten-Priester und Elementar-Schamanen weiter empfohlen, obwohl der Zaubertreffer-Cap (Willenskraft zählt mit) längst erreicht war: Der Cap-Filter kannte nur den Stat „Trefferwertung", nicht seinen Willenskraft-Alias, und gab pro Farbliste einzeln auf statt über alle passenden Farben hinweg nach einer cap-freien Alternative zu suchen

### Geändert
- Off-Color-Empfehlungen sind jetzt als solche markiert. In WoW passt jeder Stein in jeden Sockel (außer Meta) – die Farbe entscheidet nur, ob der Sockelbonus zählt, und der braucht *alle* Sockel passend. Schlägt ein stärkerer Stein den Bonus, steht das mit Zahlen da, statt wie ein Fehler auszusehen
- Die Verdikt-Zeile zum Sockelbonus nennt den tatsächlichen Abstand beider Strategien. Der alte Text „reiner Primärstein stärker" stimmte für die meisten Specs nicht – der Universalstein ist dort ein reiner Sekundärstein
- Vergelter-Paladin: „Kraftvoller Dioptas" (Tempo + Ausdauer) als Blau-/Grün-Kandidat ergänzt. Alle bisherigen Kandidaten für blaue Sockel waren treffer-lastig und damit wertlos, sobald der 7,5%-Cap steht
- Die Datenprüfung beim Login deckt jetzt auch `gem_stats.lua` ab – ein dort fehlender Stein bewertete still mit 0 und wurde nie empfohlen

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
