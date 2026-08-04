# Changelog

Alle nennenswerten Änderungen an WeintCodex werden hier festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/) angelehnt; Versionsnummern folgen dem bisherigen 4-teiligen Schema (`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

## [1.4.0.0] – 2026-08-04

### Neu
- **Rotationshelfer** (bisher „Rotationstrainer"): die Prioritätenliste sortiert sich jetzt live um, statt eine feste Liste mit einem Marker zu sein. Oben steht, was jetzt fällig ist; wer eine Fähigkeit drückt, sieht sie im selben Moment nach unten wandern und die nächste aufsteigen. Die Zeilen gleiten dabei an ihren neuen Platz, sie springen nicht
- Jede Zeile sagt, **warum** sie steht, wo sie steht: „Blutpest steht noch 14s", „Wut 34/60", „keine Unheilige Rune", „3/5 Kombopunkte" – mit den echten Zahlen aus dem laufenden Kampf
- „Jetzt"-Karte über der Liste: die fällige Fähigkeit groß mit Symbol, Begründung, Tastenkürzel aus deinen Aktionsleisten und einer Vorschau auf die nächsten drei
- Eigene Leiste für große Cooldowns und Fähigkeiten ohne globale Abklingzeit (Heroischer Stoß, Blutmal). Sie werden **nie** bewertet – an der Puppe einen Zweiminuten-Cooldown liegen zu lassen ist keine Fehlleistung
- Bewertungsseite im Fenster: Note von S bis E, die drei Teilwertungen als Balken, die häufigsten Fehlgriffe („3× Wilder Hieb statt Blutdurst") und die Dots mit der schwächsten Laufzeit
- Einstellungen direkt im Fenster (automatisch an der Puppe öffnen, kurze Liste, Cooldown-Leiste, Tastenkürzel, Fenster festsetzen). Rechtsklick auf eine Zeile schaltet sie stumm – gedacht für Fähigkeiten, die dem eigenen Talentaufbau fehlen
- `/wc training check` listet jede Regel der eigenen Spec mit Zauber-ID, Client-Namen und Gelernt-Status auf; `/wc training id` meldet die NPC-ID des Ziels, damit weitere Trainingspuppen ergänzt werden können

### Geändert
- **Die Bewertung ist rangbasiert statt richtig/falsch.** Wer die zweitbeste Fähigkeit drückt, bekommt Teilpunkte statt einer Null. Zauber, die nicht zur Rotation gehören (Tränke, Cooldowns, Fremdzauber), zählen gar nicht mehr mit, und wenn gerade nichts wirkbar war, zählt der Zauber neutral – in einer Ressourcenpause gibt es keine falsche Taste
- Bewertet wird gegen den Zustand **vor** dem Zauber, zusätzlich gegen den Takt davor. Eine richtige Entscheidung zählt damit nicht mehr als Fehler, nur weil ein Dot zwischen Tastendruck und Server-Antwort abgelaufen ist
- Die Gesamtnote wiegt drei Dinge: Priorität (60 %), Auslastung der globalen Abklingzeit (20 %) und Laufzeit der überwachten Dots und Buffs (20 %). Hat eine Spec nichts zu überwachen, gehen die 20 % an die Priorität
- Kanalisierte Zauber (Gedankenschinden, Bösartiger Griff, Seele entziehen) werden jetzt erfasst; bisher fielen sie je nach Client aus der Wertung
- `data/rotations.lua` hat ein neues Format: mehrere Bedingungen pro Regel, Erneuerungsfenster für Dots („fehlt oder läuft in unter 4s aus"), Runenbedarf für Todesritter, Kombopunkte, Ressourcengrenzen und Oder-Verknüpfungen. Die Zwangs-`always`-Regel als Filler ist weg – „gerade ist nichts fällig" ist ein ehrlicher Zustand und wird als solcher angezeigt
- Alle 23 Schadensspecs wurden gegen den MoP-Stand nachgezogen. Mehrere Listen waren unvollständig: Schatten ohne Verschlingende Seuche, Gleichgewicht ohne Zorn und ohne Eklipsen-Unterscheidung, Vergeltung ohne Inquisition, Wildheit ohne Wildes Brüllen, Frost-Todesritter ohne Seelenschnitter
- Die an WeintCompanion gemeldete Prozentzahl ist jetzt die gewichtete Gesamtnote statt der reinen Trefferquote. Das Nachrichtenformat bleibt unverändert, damit die Tage-Serie dort weiterrechnet

### Behoben
- Während der globalen Abklingzeit galt jede Fähigkeit als „nicht bereit". Die Liste war dadurch nach jedem Tastendruck rund anderthalb Sekunden lang leer – also genau dann, wenn man auf sie schaut
- Mehrere Zauber-IDs stammten aus Wrath/Cataclysm und lösten im MoP-Client nie auf, die Zeile blieb dadurch stumm (unter anderem Todesschuss, Frostfieber, Tigerhandfläche/Stoß, Verstümmeln). `/wc training check` meldet solche Fälle künftig selbst
- Die Trefferquote zählte jeden Zauber mit, auch Tränke, Aufrufe und Fremdzauber

### Intern
- Neues Modul `modules/rotation_engine.lua` (geladen vor `modules/rotationtrainer.lua`) trennt Auswertung und Bewertung von der Darstellung; der Trainer zeichnet nur noch
- `WeintCodex_ValidateRotationData()` prüft zusätzlich die Regelarten und löst für die eigene Spec jede Zauber-ID gegen den Client auf

## [1.3.0.1] – 2026-08-04

### Behoben
- **Rotationstrainer**: erkannte im Schrein der Zwei Monde/Sieben Sterne (MoP-Hauptstädte) keine Trainingspuppen, weil `DUMMY_NPC_IDS` nur die alte Vanilla-Puppe (`2673`) aus den klassischen Hauptstädten kannte. Die MoP-Puppen (`67127` sowie die große Übungsziel-Variante `31146`) sind jetzt ergänzt, das Fenster öffnet sich dort wieder automatisch

## [1.3.0.0] – 2026-08-04

### Neu
- **Rotationstrainer**: kleines, frei verschiebbares Fenster mit der Prioritätenliste der aktuellen Spec (`modules/rotationtrainer.lua`, Daten in `data/rotations.lua`). Zeigt live, welche Fähigkeit als nächstes fällig ist und markiert jeden Zauber, der dazu passt oder nicht – deckt alle 23 DPS-Specs ab (Single-Target, vereinfachte Priorität statt vollem Rotations-Solver)
- Öffnet sich automatisch, wenn das Ziel eine bekannte Trainingspuppe ist; `/wc training` startet und beendet es manuell an jedem beliebigen Ziel
- Verzahnt mit der Academy: eine abgeschlossene Übungssitzung geht als neue Nachricht `dummy_practice_session` an WeintCompanion. Wer an drei Tagen in Folge eine Mindest-Trefferquote erreicht, bekommt den passenden Trainingsplan-Punkt dort automatisch abgehakt

### Intern
- Neuer Drift-Guard `WeintCodex_ValidateRotationData()` (analog zu den bestehenden Spec-/BiS-Prüfungen) warnt, wenn eine Rotationsliste eine unbekannte Spec referenziert oder keine Filler-Regel besitzt

## [1.2.0.0] – 2026-08-04

### Neu
- **Zugriffsprofile**: WeintCompanion fragt die Discord-Rolle des Spielers ab und liefert sie als neue Inbox-Nachricht `access_profile` ans Addon. Daraus ergibt sich, welche Bereiche und Aktionen offenstehen. Damit kann WeintCompanion auch an Raider weitergegeben werden, die nicht in der Gilde sind
- Das Addon verknüpft sich mit **genau einer Community**. Nachrichten und Import-Strings einer anderen Community werden abgewiesen statt zusammengeführt – genau der Fall, der bisher dagegen sprach, die Desktop-App außerhalb der Gilde zu verteilen
- Neun Freigaben steuern die gildeninternen Funktionen: `raids.view`, `raids.edit`, `calendar.view`, `calendar.invite`, `materials.view`, `materials.scan`, `bossguides.tips`, `weinttv.raid`, `loot.report`. Der Bot schickt sie ausdrücklich mit; für nicht mitgeschickte Schlüssel greift eine Rangtabelle im Addon, damit eine neue Discord-Rolle kein Addon-Update braucht
- Gesperrte Bereiche verschwinden nicht, sondern sind erkennbar gesperrt: abgedunkeltes Icon in der Leiste, Begründung im Tooltip und eine Seite, die Rang, Community und Grund nennt
- Der eigene Rang steht als Marke am unteren Rand der Icon-Leiste und als erste Zeile im Gilden-Puls des Dashboards
- `/wc access` zeigt das vollständige Profil (Community, Rang, Discord-Rollen, Gültigkeit, alle Freigaben, verworfene Fremdnachrichten). `/wc access reset` hebt die Verknüpfung nach einer Rückfrage auf
- Import-Strings dürfen hinter dem Typ eine Community-Kennung tragen: `WCIMPORT:RAIDWED@123456789012345678:...`

### Geändert
- Die Companion-Inbox wird in zwei Durchgängen verarbeitet: zuerst die Zugriffsprofile, danach alles andere. Sonst würde beim erstmaligen Verknüpfen genau der Schwung Daten noch durchrutschen, den das gelieferte Profil sperrt
- Ausgehende Nachrichten tragen die verknüpfte Community als Feld `community`; Loot- und Gildenbank-Meldungen werden ohne passende Rolle nicht mehr eingereiht
- Dashboard und Gilden-Puls zeigen bei gesperrten Bereichen „Gesperrt“ statt einer Zahl, und der Engpass-Punkt am Materialien-Tab bleibt aus – eine `0` wäre eine Aussage über Daten, die man nicht sehen darf
- Die Erststart-Tour überspringt Seiten zu Bereichen, die nicht freigegeben sind
- Bei erzwungenem „Nur ich“-Filter in WeintTV bleibt eine Tabelle leer, statt wie bisher auf alle Raidzeilen zurückzufallen, wenn der eigene Name in einem Abschnitt nicht vorkommt

### Intern
- Neues Modul `core/access.lua` (geladen zwischen `core/ui.lua` und `core/navigation.lua`) bündelt Profil, Bindung, Freigabeentscheidung und die Sperrtexte
- Die Icon-Farbe der Navigationsleiste läuft über einen gemeinsamen Helfer, weil sonst Aktiv-, Hover- und Verlassen-Zustand die Sperrdarstellung gegenseitig überschreiben würden
- Der Community-Tag wird durch Aufteilen des Typfelds gelesen; die bestehende Erkennung der Import-Hülle bleibt unangetastet, damit keines der fünf Formate betroffen ist

### Hinweise
- **Das ist keine Sicherheitsgrenze.** `WeintCodex_SavedData` ist eine editierbare Lua-Datei auf dem Rechner des Spielers; jeder kann dort eine Freigabe von Hand setzen, und die Zuordnung Rolle → Freigaben liegt in WeintCompanion, also ebenfalls auf dem Spieler-Rechner. Der Nutzen ist genau zweierlei: die Community-Bindung verhindert, dass sich die Daten zweier Gilden vermischen, und die Freigaben halten die Oberfläche ehrlich. **Vertraulichkeit leistet das nicht** – dafür müsste der Discord-Bot eine unberechtigte Nutzlast gar nicht erst ausliefern, was er derzeit nicht tut
- Für die Rollenabfrage wird **WeintCompanion ab 1.4.0** benötigt – erst diese Version stellt das Profil zu
- Das neue `community`-Feld an ausgehenden Nachrichten ist eine Ergänzung der Warteschlangen-Struktur und muss mit WeintCompanion abgestimmt sein, bevor ausgeliefert wird
- Clients **ohne** geliefertes Profil verhalten sich unverändert wie in 1.1.0.0: alle Bereiche offen, keine Rangmarke, keine zusätzlichen Meldungen
- `/wc access reset` löscht die gildeninternen Daten (Raidanmeldungen, Namenskorrekturen, Materialien, Gildenbank-Zwischenspeicher, vom Bot gelieferte Taktiknotizen, letzte WeintTV-Auswertung). Ohne dieses Löschen bliebe beim Wechsel der Bestand der vorherigen Gilde liegen. Eigene Daten (Twinks, Fortschritt, Academy, WeakAuras, Notizen) bleiben erhalten
- Das Gildenroster in der Twinkverwaltung ist bewusst **nicht** gesperrt: es kommt über die Blizzard-API aus der WoW-Gilde des Clients und ist keine Information aus unserem Discord

## [1.1.0.0] – 2026-08-03

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
- Für WeintTV und die Academy wird **WeintCompanion ab 1.3.0** benötigt – erst diese Version stellt die Auswertung zu. Ohne gelieferte Daten zeigen beide Bereiche einen erklärenden Leerzustand statt leerer Tabellen

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
