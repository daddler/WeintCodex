# Gruppencheck (`modules/groupcheck.lua`)

Eigener Navigationspunkt unter *Raid* (seit 2.4.0.0, auch `/wc gruppe`):
Verzauberungen und Sockel **aller** Gruppen- bzw. Raidmitglieder auf einer
Seite. Beantwortet die zwei Fragen, die vor einem Pull zählen und die man
sonst 24 Mal einzeln stellt.

**Die Seite zählt, sie bewertet nicht** — das ist die tragende Entscheidung
und keine Sparmassnahme. Für den eigenen Charakter entscheidet
`modules/charakter.lua`, ob eine Verzauberung die *richtige* ist; dafür
braucht es Spec-Profil, Caps und den Item-Tooltip. Nichts davon ist für
einen fremden Spieler zu haben: die Spec eines Inspizierten meldet der
Client in MoP nicht verlässlich, und ein Tooltip-Scan über 16 Slots mal 25
Spieler wäre eine Zumutung für den Client. „Sockel leer" ist unstrittig,
„falscher Stein" wäre ein Vorwurf — deshalb steht in der Kopfzeile
*fehlt/leer* und nicht *optimal*.

Alles, was die Seite liest, steckt im **Item-Link** (Verzauberungs-ID,
Steine) plus `GetItemStats` für die eingebauten Sockelplätze. Die
Bausteine kommen aus `modules/charakter.lua` (`ParseItemLink`,
`ScanItemSockets`, `ClassifyEquipLoc`, `OffhandEnchSlot`, exportiert genau
dafür) — eine zweite Fassung wäre die Doppelpflege, an der die
Verzauberungserkennung schon einmal gescheitert ist (siehe
`gearing.md`, Werteabgleich). `ScanItemSockets` liefert
deshalb einen zweiten Wert: ob der Client die Basisdaten des Gegenstands
überhaupt hatte.

Seit 2.5.0.0 liest `ScanItemSockets` die **Reihenfolge** der Sockel am
Tooltip des Grundgegenstands — der Gruppencheck schaltet das über den
dritten Parameter (`wantColors = false`) ausdrücklich ab. Er zählt nur
belegte Sockel und braucht keine Farben; 16 Slots mal 25 Spieler wären
genau der Tooltip-Scan, den sich diese Seite verboten hat.

Vier Regeln, die nicht Geschmack sind:

- **Ringe zählen nicht mit.** Ringe darf nur verzaubern, wer den Beruf
  selbst geskillt hat, und den Beruf eines fremden Spielers kann der
  Client nicht melden. `EnchantSlotFor` baut den Slot deshalb selbst auf,
  statt `ResolveEnchSlot` zu benutzen.
- **Nicht erreichbar ist kein Befund.** Zu weit weg, offline, andere Phase
  — diese Zeilen bleiben leer, sagen warum und zählen **nicht** als
  geprüft. `Summary()` führt „ohne Befund", „mit Befund" und „nicht
  geprüft" getrennt.
- **Die Schlange läuft einzeln.** Der Server beantwortet immer nur eine
  Inspektion; ein Eintrag nach dem anderen, Zeitüberschreitung 2 s, Pause
  0,7 s. Ein Marker (`runToken`) entwertet die Zeitüberschreitung, sobald
  `INSPECT_READY` früher da war. **Vor jedem Auslesen wird der Name der
  Einheit erneut gegen den Eintrag der Schlange geprüft** — die Gruppe kann
  sich während des Laufs ändern, `raid7` ist dann jemand anders.
- **Neuzeichnen ist entprellt** (2 s während eines Laufs). Der Fortschritt
  trägt solange die Schaltfläche in der Titelleiste, die nichts kostet.

Der Tab trägt bewusst **kein** `feature`: die Seite liest ausschliesslich
die Ausrüstung der Leute, die gerade neben einem stehen — dieselbe
Auskunft, die jeder Client über „Untersuchen" ohnehin gibt.

## Ausrüstungs-Alarm (`modules/gearalert.lua`)

Grosse Einblendung in Bildschirmmitte (seit 2.4.0.1), wenn ein frisch
angelegtes Teil weder verzaubert noch versockelt ist — und dieselbe
Meldung als Erinnerung beim Betreten eines Ruhebereichs. Die Bauform ist
die der Bossmods, weil sie genau das leistet, was der Charakterseite
fehlt: eine Meldung, die man nicht übersieht. Der Ruhebereich ist dabei
kein beliebiger zweiter Auslöser, sondern der einzige sinnvolle — dort
steht der Verzauberer, dort ist die Bank.

**Sie bleibt stehen, bis man sie wegklickt** (seit 2.4.0.2), und das
Wegklicken heisst „gesehen": es verschafft **fünf Minuten Ruhe**
(`ACK_LIFETIME`, seit 2.4.1.0 — davor galt es für immer). Danach erinnert
der Alarm erneut, solange die Lücke offen ist. Dauerhaft still wird er,
wenn die Lücke behoben ist — oder über `/wc alarm aus`.

Vier Anlässe bringen die Erinnerung zurück, alle durch **eine** Schleuse
(`AmbientCheck`): Zonenwechsel, Ruhebereich, Instanzeingang und ein
Zeitgeber (der Zeitgeber deckt den Fall ab, der sonst durchfällt: wer beim
Taschensortieren an der Bank stehen bleibt, wechselt weder Zone noch
Ruhestatus). Kostenbremse: frühestens alle fünf Minuten eine ungefragte
Prüfung, denn jede liest je Gegenstand den Tooltip.

**Aber nur, wenn man gerade nichts anderes macht** (`PlayerIsBusy`): Kampf,
Bosskampf, tot, Flugroute, Fahrzeug, Zaubern, Haustierkampf — und
Bewegung.

**Der Instanzeingang ist der einzige Anlass, der die Quittung übergeht**
(`force`) — der letzte Moment, in dem sich die Lücke noch schliessen
lässt, danach zählt sie eine Stunde lang bei jedem Pull mit. `MIN_REPEAT`
(60 s) bleibt auch dort als Boden stehen. Übergangen wird sie seit 2.6.0.3
nur beim **wirklichen** Betreten (`PLAYER_ENTERING_WORLD` feuert auch beim
Anmelden und nach `/reload`, und ein Neuladen mitten im Schlachtzug ist
kein Eingang).

**Und in einer Instanz ist der Eingang seit 2.6.0.3 auch der letzte
Anlass** (`InInstance`). Der Vorbehalt „nur, wenn man gerade nichts
anderes macht" liest im Raid genau den Augenblick nach dem Pull als
ruhigen Moment; also sprang die Meldung nach **jedem** Kampf wieder auf.
Drinnen bleiben deshalb genau zwei Meldungen — der Eingang (einmal,
innerhalb von `INSTANCE_ENTRY_GRACE` = 120 s) und was man selbst auslöst
(frisch angelegter Gegenstand oder `/wc alarm jetzt`). Eine gewichene
Meldung ist damit **nicht** quittiert: geklickt hat niemand.

`SavedData.gearAlert.acked`, drei Dinge nicht Geschmack:

- **Der Schlüssel trägt Art und Anzahl, nicht nur den Slot** (`10|E|2|-`).
  Gespeichert wird der **Zeitpunkt**, nicht ein „ja"; eine Quittung ohne
  Zeitpunkt gilt als abgelaufen.
- **`PruneAcks` läuft gegen das vollständige Ergebnis von `Collect()`, vor
  jeder Filterung — und nur bei warmem Cache.** Ein ungecachter Gegenstand
  fehlt in der Liste, sein Befund sähe damit behoben aus, die Quittung
  wäre weg und die Meldung käme kurz darauf wieder.
- **Quittiert wird nur beim Klick.** `PLAYER_REGEN_DISABLED` blendet die
  stehende Meldung ebenfalls aus, ist aber keine Aussage darüber, ob
  jemand den Befund gesehen hat. Deshalb liegt das Quittieren in
  `GA.Dismiss`, nicht in `GA.Hide`.

`/wc alarm erneut` wirft alle Quittungen weg.

**Der Alarm zählt, er bewertet nicht** — dieselbe Regel wie im
Gruppencheck, hier aus Rücksicht: „nicht ideal" wäre eine Meinung.

**Der Ton kam nie an, und niemand konnte es sehen.** Beide alten
Aufrufformen (`PlaySoundFile`, `PlaySound("RaidWarning")`) sind auf dem
Client, auf dem Mists Classic läuft, tot, und beide standen in `pcall`
ohne den Rückgabewert anzusehen. Seit 2.6.0.0: die ID kommt aus der
Tabelle des **Clients** (`SOUNDKIT`), `willPlay == false` heisst „hat nicht
geklungen" und probiert den nächsten Klang, gespielt wird auf **Master**,
und was tatsächlich gespielt wurde, steht in `/wc alarm` und unter „Ton
testen" (`/wc alarm tontest`).

**Eine eigene Prüfung führt die Datei nicht.** Was offen ist, beantwortet
`WeintCodex.Charakter.Scan()` — dieselbe Slotliste, dieselbe Auflösung des
Verzauberungs-Topfes, dieselbe Sockelerkennung. Gelesen wird daraus aber
nur `enchId == nil` bzw. `socket.gemId == nil` und **nie** der bewertete
`status`.

Vier Sperren, jede für einen konkreten Fehlalarm: nichts vor
`PLAYER_ENTERING_WORLD` plus Vorlauf; nichts über einen Gegenstand ohne
Basisdaten (`SlotVerdict` kennt drei Ausgänge, nicht zwei; `socketsKnown`
an jeder Sockelzeile); nichts unterhalb von Selten (`MIN_QUALITY = 3`);
nichts im Kampf (eine schon stehende Meldung weicht ihm, nach
`PLAYER_REGEN_ENABLED` läuft `RunCheck` neu statt aus dem Gedächtnis zu
zeichnen).

**Drei Sorten Befund, die nie zusammengezählt werden.** Fehlende
Verzauberung, leerer Sockel, fehlender Sockelplatz (Gürtelschnalle,
Schmiede-Zusatzsockel) und ungenutzte Berufsvergünstigung stehen
nebeneinander.

**Berufsvergünstigungen (`data/professions.lua`, seit 2.4.1.0).** Vier
Arten: `exclusive` (Ingenieurs-Gürtel), `socket` (Schmiedekunst-
Zusatzsockel), `gems` (Schlangenaugen der Juweliere, gezählt) und `hint`.
Erkannt wird ein angebrachter Nitrobooster **nicht** über den
Verzauberungsteil des Item-Links (der steht dort nicht), sondern über die
Differenz am Tooltip: trägt der *angelegte* Gegenstand eine „Benutzen:"-
Zeile, die sein *Grundgegenstand* nicht hat. **Kein Name und keine
Verzauberungs-ID daraus wird je verglichen** — entschieden wird
ausschliesslich über Zählbares. Erkannt werden Berufe über die
Skill-Line-ID, nie über den Namen, ab Fertigkeit 500 (überschreibbar je
Vergünstigung über `minSkill`). `PerkState` ist die eine Funktion, aus der
sowohl der Alarm als auch `/wc alarm berufe` lesen.

Beim Anlegen wird nur über die Slots gemeldet, die seitdem gewechselt
haben (`pendingSlots`); die Erinnerungen nennen alles Offene. Beide Klicks
quittieren; Linksklick öffnet zusätzlich die passende Charakterseite,
Rechtsklick schliesst nur. Abschalten über `/wc alarm aus`, Erinnerungen
einzeln über `/wc alarm erinnern`.
