# Changelog

Alle nennenswerten Änderungen an WeintCodex werden hier festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/) angelehnt; Versionsnummern folgen dem bisherigen 4-teiligen Schema (`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

## [2.0.0.1] – 2026-08-13

### Behoben
- **Umlaute in gesperrten Versalien wurden als leere Kästchen gezeichnet** – aus „ÜBERSICHT" wurde „□□BERSICHT", aus „NÄCHSTER RAID" ein „N□□CHSTER RAID", aus „3 ENGPÄSSE" ein „3 ENGP□□SSE". Die Sperrung fügte ihre Haarspatie zwischen je zwei **Bytes** ein statt zwischen je zwei **Zeichen**; ein Umlaut besteht in UTF-8 aus zwei Bytes und zerfiel dabei in zwei ungültige Hälften, für die der Client je ein Kästchen zeichnet. Betroffen war jede Überzeile, jeder Chip, jede Reiterleiste und die Brotkrumenzeile. Aus demselben Grund endete der abgeschnittene Text auf der Startseite mit einem Kästchen („… 15.0% □…"): auch das Kürzen zählte Bytes. Beides zählt jetzt Zeichen, ebenso das Kürzen langer Itemnamen im Ausrüstungs-Check
- **Versalien machten aus „ä/ö/ü" kein „Ä/Ö/Ü".** `string.upper` arbeitet byteweise und lässt alles über ASCII unangetastet – „Fläschchen" wurde zu „FLäSCHCHEN". Kleingeschriebene Umlaute werden jetzt richtig umgesetzt; „ß" bleibt bewusst „ß", weil „SS" die Zeile länger machen würde, als der Aufrufer sie gemessen hat
- **Auf der Charakter-Übersicht liefen die Kennzahlenkarten aus der Seite heraus** – „Trefferwertung (Nahkampf)" war abgeschnitten, „Waffenkunde" gar nicht mehr zu sehen. Zwei Ursachen: die Seite maß ihre Breite, **bevor** der Detailbereich rechts eingeblendet war, rechnete also mit 372 px zu viel; und vier Karten nebeneinander lassen der längsten Beschriftung keinen Platz. Der Detailbereich steht jetzt vor der Messung fest, und die Karten stehen in zwei Spalten: oben Verzauberungen und Sockel & Steine, darunter Trefferwertung und Waffenkunde
- **In der Materialtabelle fehlte der gelbe Balken** – zu sehen waren nur grün und rot, die mittlere Stufe („ok", ≥ 30 % vom Soll) blieb leer. Rille und Füllung lagen beide auf derselben Zeichenebene, womit nicht festgelegt war, welche der beiden gleich großen Flächen oben liegt. Sie liegen jetzt in getrennten Ebenen, die Füllung trägt denselben hellen Ton wie die Zahl daneben, und die Rille ist wieder sichtbar – ein leerer Balken soll als leer lesbar sein und nicht als fehlender

## [2.0.0.0] – 2026-08-12

### Geändert
- **Das Addon trägt die Designsprache von WeintCompanion 2.0.** Grundlage ist der Entwurf „Adson neu – Seiten" (Richtung 1a): Flächen `#0A0A0C` / `#08080A`, Karten ohne Rahmen mit 1-px-Oberkante statt Kästen, Bernstein `#D4A24A` nur noch dort, wo es etwas bedeutet, Inter für gesetzten Text und JetBrains Mono für Zahlen und Kennwerte, Raster 4/8/12/16/24/32. Die Farbnamen der alten Palette bleiben alle gültig und zeigen auf die neuen Werte – rund 140 Aufrufstellen nennen Farben beim Namen, ein entfernter Name wäre ungefärbter Text und damit ein Fehler, den man erst im Spiel sieht
- **Aus der 64-px-Symbolleiste wird eine ausgeschriebene Navigationsspalte (232 px)** mit den Gruppen *Raid*, *Charakter* und *Gilde*. Einträge tragen Zahl oder Statuspunkt aus echtem Zustand; am Fuß steht der angemeldete Charakter samt Companion-Stand. Ein gesperrter Bereich dunkelt jetzt Symbol **und** Beschriftung ab – das frühere Plättchen unten links war die Krücke einer Leiste, in der außer dem Symbol nichts da war, was den Zustand zeigen konnte
- **Die Startseite beantwortet den Abend, nicht das Menü.** Handlungskarte zum nächsten Raid, darunter drei Spalten: was an der eigenen Ausrüstung offen ist, welche Bosse anstehen, wie es um die Gildenbank steht, unten eine Systemzeile zum Stand der letzten Companion-Lieferung. Die acht Modulkacheln sind entfallen – die Navigationsspalte schreibt dieselben Bereiche aus, eine zweite Liste derselben Namen war genau das Menü, das der Entwurf ablöst
- **Die Unternavigation jeder Seite sitzt als Reiterleiste unter dem Titel** statt in einer eigenen Fensterspalte. `BuildSidebar` bleibt als API bestehen und entscheidet selbst: Reiterleiste für kurze, flache Listen, Listenspalte innerhalb der Seite, sobald Einträge Portrait, Statuszeile oder Gruppen tragen. Vierzehn Bosse mit Bild und „erledigt/offen" sind keine Reiter
- **Die Inspector-Spalte ist Teil der Seite geworden** (rechte Spalte, 372 px, wie im Entwurfsraster `1fr 372px`) und erscheint nur noch, wenn es wirklich etwas zu zeigen gibt. Vorher stand sie auch leer im Fenster. `Navigation.SetInspector` und alle neun aufrufenden Module bleiben unverändert – der Inhaltsbereich schrumpft, die Module merken davon nichts
- **Die Academy ist ein eigener Navigationspunkt.** Sie hing bis 1.3.3.3 in der Charakter-Unternavigation; ihre drei Ansichten sind jetzt die Reiterleiste ihrer eigenen Seite. Ebenso ist die Übersicht ein Navigationspunkt statt nur Startzustand
- **Jeder Seitenkopf entsteht jetzt an einer Stelle** (`WeintCodex.PageHead`): Eyebrow, Titel, Unterzeile, rechts die Kennzahlen in Mono. Vorher baute ihn jede Seite selbst, und im Ergebnis standen drei Titelformen nebeneinander – bernsteinfarbene 19er bei WeintTV, Academy, Verzauberungen, Sockeln, Werteverteilung, Priorisierung und Twinkverwaltung, neutrale 22er bei Raids und Materialien, neutrale 26er beim Kalender. Ein Seitentitel ist Beschriftung und kein Befund; Bernstein trägt in dieser Sprache Bedeutung, und sieben Seiten trugen es als Ornament
- Die Charakter-Unterseiten hängen ihren Inhalt an **eine** Kopfhöhe (`HEAD_H`) statt an eine fünfmal einzeln notierte 52. Der Spielstil-Umschalter setzte bei 44 an und lief damit in die Spec-Zeile hinein – mit der gemeinsamen Zahl kann das nicht mehr auseinanderlaufen
- Abschnittsüberschriften des Kalenders („Event-Details", „Einladungen", „Einzuladende Spieler") sind gesperrte Mono-Versalien wie überall sonst, statt bernsteinfarbener Fließschrift. Ebenso neutral: die Beschriftung des Spielstil-Umschalters und die Slotnamen der Sockelseite. Farbe behalten hat, was einen Zustand trägt – der aktive Spielstil, die Rollenhaken der Einladung, die empfohlene Verzauberung

### Nicht übernommen
- Das Hauptfenster bleibt eckig. Die Eckmasken färben sich auf den Untergrund — hinter dem Fenster liegt die Spielwelt, deren Farbe niemand kennt

### Neu
- **Der Kalender hat eine Monatsansicht** (Entwurf 2d): 7×6-Raster mit Wochentagszeile, Monatsnavigation und *Heute*, Termine als Zeilen in der Tageszelle, Klick auf einen Tag zeigt seine Termine im Detailbereich. Sie kommt **neben** das Einladungsformular, nicht an dessen Stelle — die Reiterleiste schaltet zwischen *Monat*, *Mittwoch* und *Donnerstag*, und das Formular ist unverändert geblieben. Termine stammen aus den beiden eigenen Raidterminen der `SavedData` und, wo der Client sie hergibt, zusätzlich aus dem Spielkalender über `C_Calendar`. Letzteres ist bewusst nur Anreicherung: das Lesen der Blizzard-Kalenderdaten hängt am Ladezustand des Kalenders und ist in MoP Classic nicht zugesichert, läuft deshalb vollständig in `pcall` — fällt es aus, steht das Raster trotzdem, nur mit den Raidterminen allein. `SetAbsMonth` wird nicht verwendet, das würde den Monat der Blizzard-Kalenderoberfläche global umstellen
- Gemeinsames Baukasten-Vokabular in `core/ui.lua` für die neue Sprache: `CreateSurface` (Karte mit Verlauf und Oberkante), `Chip`, `StatusDot`, `Eyebrow`, `MonoNumber`, `CreateButton`, `CreateSegmentedControl`, `CreateMeter`, `RowLine`
- Inter (Regular/Medium/SemiBold/Bold) und JetBrains Mono Bold liegen unter `media/fonts` (SIL OFL 1.1). Die Navigationssymbole sind aus den Vektorpfaden des Entwurfs vorgerendert, weil WoW zur Laufzeit keine Pfade zeichnet

### Technisch
- **Runde Ecken ohne `border-radius`:** WoW-Frames können keinen Radius. Vier Viertelkreis-Masken (`media/ui/corner.tga`) in der Farbe des Untergrunds stanzen die Ecke aus; eine einzige 32×32-Textur deckt jeden Radius ab, weil die Form maßstabsunabhängig ist. Zweierpotenz, weil der Client keine andere Texturgröße lädt. Das Hauptfenster bleibt bewusst eckig – hinter ihm liegt die Spielwelt, deren Farbe niemand kennt
- **Verläufe laufen andersherum:** `SetGradient("VERTICAL", min, max)` geht von unten nach oben, CSS `linear-gradient(180deg, …)` von oben nach unten. Die Farben werden deshalb getauscht übergeben (`ApplyVerticalGradient`)
- `DrawBorder` verankert seine Kanten an zwei Punkten, statt sie aus `GetWidth()`/`GetHeight()` zur Bauzeit zu rechnen. Chips und Lösch-Schaltflächen bestimmen ihre Breite erst nach dem Rahmen aus der Textbreite – mit den alten Maßen wären ihre Kanten 0 breit gewesen
- Detailbereich, Unternavigationsspalte und Reiterleiste beschneiden den Inhalt über **einen** gemeinsamen Rechenweg. Je Aufrufer eigene `ClearAllPoints`/`SetPoint` wäre genau der Fehler, den man erst sieht, wenn zwei davon gleichzeitig aktiv sind

## [1.3.3.3] – 2026-08-11

### Behoben
- **Der Ausrüstungs-Check verlangte bei Tank-Kriegern und -Todesrittern nur 7,5% Waffenkunde, obwohl 15% der eigentliche Zielwert ist.** Wer den korrekten Wert erreicht hatte, bekam „über dem Cap – X Wertung verschwendet. Umsockeln!" angezeigt und wurde aufgefordert, richtig gesockelte Steine wieder zu entfernen. `WARRIOR_PROTECTION` und `DEATHKNIGHT_BLOOD` (samt ihrer Offensiv-Varianten) trugen den 15%-Hardcap bereits als Notiz im Cap-Eintrag, prüften aber weiterhin gegen 7,5% – anders als `PALADIN_PROTECTION`/`DRUID_GUARDIAN`, wo derselbe Wert schon korrekt hinterlegt war. Alle vier Profile jetzt auf 15% angeglichen
- **Bereits angelegte Verzauberungen wurden als „nicht ideal" gemeldet, wenn ihr Tooltip-Name ein Kategorie-Präfix trägt** (z. B. „Schild - Großes Parieren" statt „Großes Parieren"). Der Namensabgleich verlangte exakte Gleichheit; ein neuer Enthaltensein-Check erkennt jetzt auch Verzauberungen mit Slot-Präfix korrekt als optimal – betroffen waren u. a. Umhang, Füße und Nebenhand bei Tank-Profilen

## [1.3.3.2] – 2026-08-11

### Geändert
- **Jedes Release trägt jetzt seine eigene Änderungsliste.** Releases wurden bisher von Hand mit leerem Notizfeld angelegt; WeintCompanion zeigte deshalb unter *Addon & Updates* dauerhaft „Keine Änderungen gefunden.", obwohl dieser Changelog immer gepflegt wurde. Der Release-Text auf GitHub entsteht jetzt direkt aus diesem Abschnitt (`.github/scripts/release_notes.py`), und ein Tag ohne passenden Eintrag – oder mit abweichender Versionsnummer in `.toc`, `core/main.lua` oder `data/changelog.lua` – lässt den Build abbrechen, statt ein Release ohne Beschreibung zu veröffentlichen

## [1.3.3.1] – 2026-08-11

### Neu
- **Das Addon meldet der Companion den Ausrüstungsstand des angemeldeten Charakters** (neue Nachricht `character_sheet`). Damit sind „Meine Charaktere" und „Vorbereitung" auf dem Desktop nicht mehr leer: je Charakter Gegenstandsstufe, geprüfte Verzauberungen und Sockel, offene BiS-Plätze und die konkreten Mängel in der Reihenfolge, in der dieses Addon sie bewertet. Braucht **WeintCompanion 2.0.1**; ältere Versionen bekommen die Nachricht gar nicht erst geschickt
- Wie `character_report` und `dummy_practice_session` bleibt sie auf dem Rechner des Spielers und geht den Discord-Bot nichts an – es ist die eigene Ausrüstung, kein Gildenwissen. Bewusst ein eigener Nachrichtentyp: alles, was an die bestehende `character`-Meldung angehängt würde, wäre ein Bot-Vertrag
- `WeintCodex.BiS.GetSummary(specKey)` beantwortet erstmals „wie weit bin ich insgesamt" statt nur „droppt hier etwas für mich". Gezählt wird **je Slot**, nicht je Eintrag – eine BiS-Liste führt für Finger und Schmuck mehrere Einträge, und wer einen davon trägt, hat den Platz nicht halb offen. Ist für eine Spec keine Liste gepflegt, sagt die Übersicht das, statt „0 offen" zu behaupten

### Geändert
- Gemeldet wird beim Betreten der Welt (nach 8 s) und entprellt nach jedem Ausrüstungs-, Berufs- oder Spec-Wechsel – **nicht** bei `PLAYER_LOGIN`: dort steht weder die Spezialisierung fest noch sind die Item-Daten im Client-Cache, ein Scan zu diesem Zeitpunkt meldete eine halb leere Ausrüstung als Befund. Gesendet wird nur, wenn sich am Ergebnis etwas geändert hat
- Die Versionsprüfung gegenüber der Companion kennt jetzt auch die dritte Stelle. 2.0.0 war bereits draußen und kennt die neue Nachricht nicht – „mindestens 2.0" hätte genau die Version eingeschlossen, die daran scheitert

## [1.3.3.0] – 2026-08-10

### Behoben
- **Academy und WeintTV zeigten manchmal einen alten oder einen völlig fremden Charakter.** Ursache war nicht ein Fehler, sondern dass es vier voneinander unabhängige Antworten auf „wer bin ich" gab – die Auswahlbox der Companion, deren gespeicherte Auswahl, das ausgewertete Profil und der angemeldete Charakter – und nichts davon miteinander abgeglichen wurde. Die einzige verlässliche Quelle, der angemeldete Charakter, wurde nirgends gefragt
- **Die gelieferte Auswertung schlug den angemeldeten Charakter.** `modules/academy.lua` las den Namen aus derselben Nutzlast, die es anzeigte, und konnte eine Abweichung deshalb prinzipiell nicht bemerken. Jetzt zählt `UnitName("player")`, und nur der
- **Bewertung und Katalog lagen kontoweit auf einem einzigen Platz.** Jeder Twink bekam die Bewertung des Mains vorgesetzt, mitsamt dessen Namen, Klasse und Trainingsplan. Beides liegt jetzt je Charakter; bestehende Daten wandern beim ersten Login unter ihren Charakter, es geht nichts verloren
- **„Nur ich" in WeintTV verglich Namen roh und schreibweisengenau** und zeigte bei null Treffern stillschweigend den ganzen Raid. Verglichen wird jetzt ohne Rücksicht auf Realm-Zusatz und Gross-/Kleinschreibung, und der Rückfall auf den ganzen Raid steht als Hinweis über der Tabelle statt gar nicht

### Neu
- **Das Addon meldet der Companion beim Login, wer angemeldet ist** (neue Nachricht `character_report`). Die Charakterauswahl auf dem Desktop folgt dem von selbst, statt sie zu raten. Bewusst ein eigener Nachrichtentyp, der den Rechner nie verlässt – die bestehende `character`-Meldung geht an den Discord-Bot und bleibt unverändert. Braucht **WeintCompanion 1.7.0**; ältere Versionen bekommen die Nachricht gar nicht erst geschickt
- Liegt für den angemeldeten Charakter keine Auswertung vor, nennt die Academy den Charakter, für den die Companion zuletzt ausgewertet hat – statt entweder nichts zu sagen oder fremde Zahlen als eigene auszugeben
- Neue Datei `core/names.lua`: der eine Ort, an dem „ist das derselbe Charakter" beantwortet wird. Ein fehlender Realm gilt dabei als Platzhalter, nicht als Widerspruch – der Client kennt nur den nackten Namen, WarcraftLogs qualifiziert nur realmfremde Zeilen

### Geändert
- `/wc access reset` löscht jetzt auch die gelieferten Auswertungen der alten Community. Die selbst gesetzten Haken im Lernfortschritt bleiben – sie sind eigene Daten, weder gildenintern noch aus fremden Raids abgeleitet

## [1.3.2.3] – 2026-08-07

### Geändert
- **Das Notizfeld der Bossguides entscheidet die Ansicht nicht mehr selbst.** In der Kopfzeile sitzt ein Umschalter „1 Spalte / 2 Spalten" – eine Spalte für längeren Fliesstext, zwei für den schnellen Überblick. Die Wahl gilt für alle Bosse und bleibt über den Reload erhalten
- **Läuft der Text zum ersten Mal über, fragt das Feld selbst nach**, ob zwei Spalten oder Scrollen gewünscht sind. Bewusst als Einblendung im Feld statt als Popup, damit sie das Tippen nicht unterbricht – und nur ein einziges Mal, danach bleibt der Umschalter
- Beim Wechsel auf eine Spalte wandert der Inhalt der zweiten ans Ende der ersten. Sonst läge er unerreichbar in den gespeicherten Daten und man hielte seine Notizen für verloren
- Das Feld ist gewachsen (150 → 210 px) und zeigt jetzt Fokusrahmen, Platzhaltertext und Zeichenzahl. Die breite Blizzard-Bildlaufleiste ist einer 8 px schmalen Anzeige gewichen – bei zwei Spalten waren von 137 px Spaltenbreite sonst kaum 110 px für Text übrig

## [1.3.2.2] – 2026-08-07

### Geändert
- Notizfeld bei den Bossguides scrollt jetzt, statt Text unten aus dem sichtbaren Bereich laufen zu lassen, und ist zweispaltig für den schnellen Überblick
- Schutzpaladin-BiS: der fehlende Ring „Siegelring der Vergessenen Könige" (Schätze Pandarias) ergänzt

## [1.3.2.1] – 2026-08-06

### Geändert
- WeakAura-String für das Bosspaket „SuO Bosspaket 01-08" auf v3.0.4 aktualisiert
- WeakAura-String für das Bosspaket „SuO Bosspaket 09-14" auf v3.0.8 aktualisiert

## [1.3.2.0] – 2026-08-05

### Geändert
- **Eine Übungssitzung zählt erst ab drei Minuten.** Bisher genügten 30 Sekunden, um eine Sitzung an WeintCompanion zu melden und damit die Tage-Serie im Trainingsplan zu füttern – dafür ist eine halbe Minute an der Puppe kein Training. Alles darunter bleibt sichtbar bewertet, wird aber nicht mehr weitergegeben
- **Eine kurze Kampfpause beendet die Sitzung nicht mehr.** An der Puppe fällt man schon durch einen Zielwechsel oder eine Ressourcenpause für ein paar Sekunden aus dem Kampf; bisher wurde in dem Moment abgerechnet, drei Minuten am Stück wären damit kaum je zusammengekommen. Kommt der Kampf binnen 20 Sekunden zurück, läuft dieselbe Sitzung weiter – die Pause selbst zählt weder für die Dauer noch für die Auslastung
- Das Fenster sagt jetzt, wo die Sitzung steht: die Fußzeile zeigt „01:12 / 03:00" bis zur Mindestdauer und danach die Laufzeit, während einer Pause den Countdown bis zum Abschluss. Auf der Bewertungsseite steht, was noch fehlt bzw. ob die Sitzung gemeldet wurde
- **Bewertung und Einstellungen sind jetzt eine beschriftete Reiterleiste** unter der Kopfzeile („LISTE · BEWERTUNG · EINSTELLUNGEN") statt zweier einzelner Zeichen („%" und „=") neben dem Schließen-Kreuz. Sie waren dort nur im Tooltip beschriftet, und welche Seite gerade offen war, stand nirgends. Gleiches Muster wie der Rollen-Umschalter in den Bossguides

## [1.3.1.0] – 2026-08-04

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

## [1.3.0.2] – 2026-08-04

### Behoben
- **Rotationstrainer**: stürzte beim Verschieben am Titelbalken ab. Der Ziehen-Handler der Kopfzeile schrieb die Fensterposition nach `SavedData.rotationTrainer.pos`, ohne die Tabelle vorher anzulegen – anders als der Handler des Fensters selbst direkt darüber
- **Unheilig-Todesritter**: der Prioritätenliste fehlte Geißelstoß, die Hauptschadensfähigkeit im Einzelziel, komplett. Fäulnisschlag stand dadurch als einziger Filler da. Geißelstoß ist jetzt davor eingeordnet (Geißelstoß → Fäulnisschlag → Todesspirale)

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
