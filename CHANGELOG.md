# Changelog

Alle nennenswerten Änderungen an WeintCodex werden hier festgehalten. Format lose an [Keep a Changelog](https://keepachangelog.com/) angelehnt; Versionsnummern folgen dem bisherigen 4-teiligen Schema (`MAJOR.MINOR.PATCH.BUILD`), nicht SemVer.

## [2.6.0.0] – 2026-08-25

### Neu
- **Ein Einstellungsbereich im Addon — jede Option als Schalter statt als Befehl.** Bis hierher gab es für keine einzige Einstellung dieses Addons eine Schaltfläche. Ob der Ausrüstungs-Alarm überhaupt meldet, ob er einen Ton spielt, ob sich der Rotationshelfer an der Puppe von selbst öffnet, ob das Minimap-Symbol da ist — all das hing an `/wc alarm ton`, an einem Fenster, das man erst öffnen musste, um es abschalten zu können, oder an gar nichts. Ein Slash-Befehl ist die Bedienung für den, der ihn schon kennt; wer ihn nicht kennt, erfährt nie, dass es die Einstellung gibt. Neuer Navigationspunkt *System › Einstellungen* mit fünf Seiten: **Fenster & Ansicht**, **Ausrüstungs-Alarm**, **Rotationshelfer**, **Diagnose** und **Zugriff & Daten**
- **Zu jedem Slash-Befehl gibt es jetzt einen Knopf.** `/wc alarm an|aus|ton|erinnern|erneut|jetzt|test|bewegen|berufe`, `/wc training|stop|check|id`, `/wc vz`, `/wc vz zeilen`, `/wc sockel`, `/wc access`, `/wc access reset`, `/wc tour` — alle bleiben bestehen (im Raid ist der Befehl der schnellere Weg), aber keiner ist mehr die einzige Bedienung. Der Tooltip jedes Knopfes nennt den zugehörigen Befehl, damit die Seite auch der Ort ist, an dem man ihn kennenlernt
- **`/wc einstellungen`** (auch `/wc optionen`) öffnet die Seite — der einzige Befehl, den man sich noch merken müsste
- **Schalter und Regler als Bausteine** (`WeintCodex.CreateToggle`, `WeintCodex.CreateSlider` in `core/ui.lua`). Beides gab es vorher nur als Eigenbau im Rotationshelfer, weil sonst nirgends etwas umzuschalten war. Ein Schalter hält **keinen** eigenen Stand: er liest über `get` und schreibt über `set`, die Wahrheit bleibt in den SavedData des jeweiligen Moduls
- **Zwei Einstellungen zum Fensterverhalten**, die es vorher nicht gab: *Mit Esc schließen* und *Über allen anderen Fenstern halten*
- **Fenstergröße als Regler** (70 – 120 %) samt *Größe zurücksetzen*. Die Skalierung stand bisher nur in den SavedData
- **Ton testen** auf der Alarmseite und **`/wc alarm tontest`**: spielt den Warnton sofort und schreibt in den Chat, *welcher* Klang des Spiels das war. Ohne diese Auskunft ist „ich höre nichts“ von außen nicht von „Lautstärke steht auf 0“ zu unterscheiden — und genau daran lag es, dass der stumme Alarm so lange unbemerkt blieb. Dieselbe Zeile steht auch unter `/wc alarm`

### Behoben
- **Das Hauptfenster ließ sich nicht mit Esc schließen.** Dafür muss der *globale* Name des Frames in `UISpecialFrames` stehen; er existiert seit jeher (`WeintCodexMainFrame`), war dort aber nie eingetragen. Jetzt ist er es — abschaltbar, falls jemand es anders will
- **Das Hauptfenster lag über allem, was der Client sonst öffnet.** Es stand fest auf `FULLSCREEN_DIALOG` und damit über Taschen, Charakterbogen, Handelsfenster und selbst über Blizzards eigenen Bestätigungsdialogen. Zusammen mit dem fehlenden Esc ergab das ein Fenster, das man nur über sein eigenes Kreuz wieder loswird und das solange jede andere Oberfläche verdeckt. Vorgabe ist jetzt `HIGH`: darüber liegen die Dialoge des Spiels, darunter die Weltfenster — und wer es anders will, schaltet es an
- **Der Ausrüstungs-Alarm hat nie einen Ton gespielt.** Es gab ihn von Anfang an, die Einstellung stand auf „an“, der Code lief sauber durch — und es passierte nichts. Beide Aufrufformen sind auf dem Client, auf dem Mists Classic läuft, tot: `PlaySoundFile("Sound\\Interface\\RaidWarning.wav")` scheitert, weil Pfade *in* die Spieldaten seit der Umstellung auf CASC nicht mehr auflösbar sind (`PlaySoundFile` kennt nur noch Dateien aus einem Addon-Ordner oder eine FileDataID), und `PlaySound("RaidWarning")` scheitert, weil `PlaySound` eine **numerische** SoundKit-ID will — der Kit-Name als Zeichenkette war die Form des alten 5.x-Clients. Beides stand in `pcall`, und niemand sah den Rückgabewert an: **ein Rückfallweg, dessen Zweige alle schweigend scheitern können, ist kein Rückfallweg** (dieselbe Lehre wie beim Nitrobooster in 2.4.1.2). Die ID kommt jetzt aus der Tabelle des **Clients** (`SOUNDKIT`, die Zahl daneben nur als Rückfall), der Rückgabewert wird ausgewertet, und schweigt ein Klang, wird der nächste probiert. Gespielt wird auf dem Master-Kanal — der Alarm meldet eine Lücke, die einen ganzen Raidabend kostet
- **`/wc alarm test` lief mit einem Lua-Fehler auf, wenn gerade nichts offen war.** Der erfundene Ersatzbefund trug kein `perks`-Feld, und `Headline()` liest bei genau einem Eintrag `#e.perks`. Der Fehler traf also ausgerechnet den Fall, für den die Testmeldung da ist: einen Charakter ohne echten Befund. Die Beispielzeile hat jetzt dieselbe Form wie eine echte

### Geändert
- **Die fünf Schalter des Rotationshelfers stehen an beiden Stellen** — im Helferfenster wie bisher und zusätzlich in den Einstellungen. Sie lesen und schreiben denselben Speicher, und wer an einer Stelle umschaltet, sieht es sofort an der anderen. Dasselbe für den Ausrüstungs-Alarm: ein Slash-Befehl bei offener Einstellungsseite zieht die Schalter nach
- **Der Spalten-Umschalter der Bossnotizen ist auch eine Einstellung** (*Notizen zweispaltig*). Derselbe Speicher wie der Umschalter in der Kopfzeile des Notizfeldes; das Zusammenführen von Spalte 2 nach Spalte 1 übernimmt weiterhin das Feld selbst beim nächsten Aufbau
- **Wer den Signalton einschaltet, hört ihn sofort** — an der Schaltfläche wie über `/wc alarm ton`. Eine Einstellung für einen Ton, die man erst beim nächsten Befund hört, lässt sich nicht prüfen
- `GA.Command` ruft nur noch die neue API auf (`GA.SetOption`, `GA.CheckNow`, `GA.ForgetAcks`, `GA.ResetPosition`, `GA.ShowTest`), damit Schalter und Befehl nicht zwei Wege durch denselben Zustand nehmen

### Technisch
- `WeintCodex.ApplyWindowBehaviour()` / `WeintCodex.WindowBehaviour()` in `core/ui.lua` sind die eine Stelle für Ebene und Esc. `UISpecialFrames` trägt **Namen**, keine Frames: der Eintrag wird per Zeichenkette gesucht und entfernt, und er darf nur einmal drinstehen, sonst läuft `CloseSpecialWindows` zweimal über denselben Frame
- Neu in `SavedData.window`: `escClose` (Vorgabe an) und `topmost` (Vorgabe aus). Beide werden ausdrücklich über `== nil` vorbelegt und nicht über `or` — sonst ließe sich `escClose` nie abschalten
- `modules/settings.lua` baut sein Seitengerüst **einmal** und tauscht nur den Inhalt: WoW gibt Frames nie wieder frei, und ein frischer Bildlaufrahmen je Reiterklick wäre eine Sammlung, die nur wächst. Die Größe des Bildlauffelds kommt aus Ankern statt aus einer Messung — dieselbe Falle wie beim Detailbereich
- Der Navigationseintrag trägt bewusst **kein** `feature`: eine gesperrte Einstellungsseite versperrte genau den Weg, über den man den Alarm abstellt, wenn einen die Sperre erst gestört hat
- Die Navigationsspalte ist damit bei 676 px von 684 verfügbaren (kleinstes Fenster, abzüglich Titelleiste und Kontozeile). Die Rechnung steht als Kommentar über der `tabs`-Tabelle — der nächste Eintrag passt nicht mehr ohne Bildlauf
- Neue APIs: `GA.GetOption/SetOption/AckCount/CheckNow/ForgetAcks/ResetPosition/ShowTest/PlaySignal/SoundNote`, `RotationTrainer.GetOption/SetOption/IsShown/ClearMuted`, `Minimap.IsShown/SetShown`, `Navigation.ActivateIndex`

## [2.5.0.0] – 2026-08-25

### Behoben
- **Die Sockelreihenfolge war erfunden — das ist die Wurzel, an der die Sockelseite seit fünf Releases hängt.** `GetItemStats` liefert nur **Anzahlen** je Sockelfarbe (`EMPTY_SOCKET_RED = 1`), niemals die Reihenfolge der Sockel im Gegenstand. Gezählt wurde trotzdem in einer eigenen festen Folge (meta → rot → gelb → blau → prisma), und der erste Stein des Item-Links wurde dem ersten so entstandenen Sockel zugeordnet. Bei jedem Gegenstand mit zwei verschieden gefärbten Sockeln konnten Stein und Sockelfarbe damit vertauscht sein — und seit 2.3.0.1 hängt an genau dieser Achse **alles**: aus welcher Liste die Empfehlung kommt, ob der Stein den Sockelbonus auslöst und was die Zeile darüber behauptet. Es reproduzierte exakt das Symptom, das 2.3.0.1 beheben sollte („gelber Stein im blauen Sockel als Optimal"), nur aus einer Quelle, die keine Ausgabe je genannt hat. **Gefragt wird jetzt der Client:** der Tooltip des *Grundgegenstands* (`item:<id>`, ohne Steine und Verzauberung) listet alle Sockel leer und in echter Reihenfolge; erkannt an den Konstanten des Clients (`EMPTY_SOCKET_*`) und nie an eigenem Text
- **„Sockelbonus aktiv?" wurde hergeleitet, obwohl der Client es hinschreibt.** Geschlossen wurde aus den Farben der eingesetzten Steine — eine Herleitung mit drei Unbekannten (unsere Farbtabelle, die Sockelfarbe, deren Reihenfolge), von denen zwei nachweislich danebenlagen. Der Client zeichnet die Sockelbonuszeile **grün**, wenn der Bonus anliegt, und grau, wenn nicht; gelesen wurde diese Zeile ohnehin schon, nur ihre Farbe nicht
- **Auf Gegenständen mit blauem Sockel galt der Sockelbonus für die halbe Belegschaft pauschal als wertlos.** 21 von 39 Spec-Profilen führen unter `blau` ausschliesslich Treffer- oder Waffenkundesteine. Sobald jemand am Cap stand — im Raid also immer — fiel deren Vergleichswert auf 0, das Matchen kostete rechnerisch die volle Wertung und das Addon empfahl flächendeckend Umsockeln. Betroffen waren u. a. alle Jäger, alle Schurken, Frost- und Unheilig-Todesritter, Verstärker, Windwandler, Wildheit und alle drei Hexenmeister- und Magier-Specs. Nachgerechnet am Feuermagier am Zaubertrefferkap: Bonus +180 Krit = 14.760 gegen Kosten 16.000 — alt „lohnt sich nicht", jetzt wird ein farblich passender Stein gefunden und der Bonus gehalten
- **Ein Cap war eine Klippe statt eines Verlaufs.** Ein Stein wurde **ganz** verworfen, sobald er irgendeinen übercappten Wert lieferte — ein *Stechender Dioptas* (160 Krit + 160 Treffer) ist am Trefferkap aber immer noch 160 Krit wert. Zusammen mit der Schwelle von 0,25 Prozentpunkten kippte das ganze Item-Urteil an einem Viertelprozentpunkt. Gezählt wird jetzt je Wert nur noch bis zum Cap
- **Juwelier-Schlangenaugen wurden Leuten empfohlen, die den Beruf nicht haben** — und schlimmer: als Listeneintrag hoben sie den Bezugswert für *alle anderen* Steine um die Hälfte an (480 statt 320). Ein völlig korrekter 320er Stein fiel dadurch von „ok" auf „falsch". Empfohlen werden sie jetzt nur mit dem Beruf und höchstens zwei über den ganzen Charakter (die Zahl steht in `data/professions.lua` und wird von dort gelesen)
- **Zwei Zeilen derselben Seite mit „85 %" meinten nicht dasselbe** — einmal gemessen am prismatischen Anker, einmal am besten Stein der Farbliste. Es gibt jetzt genau eine Bezugsgrösse je Zeile: den Stein, den der Plan für genau diesen Sockel empfiehlt
- **Ohne Gegenstandsdaten wurde trotzdem geurteilt.** Kannte der Client das Item noch nicht, standen alle seine Steine als prismatische „Zusatzsockel" da, gemessen an der falschen Liste — und anders als beim Verzauberungspfad wurde die Nachlieferung nicht einmal vorgemerkt, es zeichnete also auch nichts die Seite neu. Solche Zeilen sagen jetzt „Gegenstandsdaten noch nicht geladen" und füllen sich von selbst
- **Jäger wurden dauerhaft unter dem Waffenkunde-Cap geführt.** Fernkampfangriffe können in MoP weder pariert noch ausgewichen werden — Waffenkunde tut für einen Jäger nichts. Alle drei Profile trugen trotzdem einen 7,5-%-Cap, und die Karte meldete ein Defizit, das niemand schliessen kann und soll

### Geändert
- **Statt drei gekoppelter Heuristiken rechnet eine Funktion.** `EvaluateSocketBonus` (für die Bonuszeile), `PickGemRecommendation` (für die Empfehlungsspalte) und `EvaluateGem` (für das Urteil) leiteten jede für sich noch einmal her, welchen Stein wir nehmen würden. Jede Fehlermeldung seit 2.0.0.3 war eine weitere Klammer, die sie synchron halten sollte. `PlanItem` vergleicht jetzt einmal je Gegenstand die beiden Strategien *Farben matchen* und *Bonus ignorieren*; Empfehlung, Steinurteil und Bonuszeile lesen alle aus demselben Ergebnis und **können** sich nicht mehr widersprechen
- **Die Steinfarbe kommt vom Client, nicht aus unserer Tabelle** — dieselbe Regel, die für Verzauberungen seit 2.0.0.3 gilt und hier umgekehrt stand. Die Unterklasse des Gegenstands *ist* die Farbe: am Client abzulesen, lokalisierungsfrei, driftet nicht. Unsere Farbspalte ist nur noch Rückfall für den kalten Cache
- **Der Schutzkrieger bekommt für gelbe Sockel keinen blauen Stein mehr empfohlen.** An erster Stelle stand dort der *Perfekte geschickte Alexandrit*, in `data/gems.lua` als grün geführt — er trägt aber Treffer und Ausdauer, beides blaue Werte, und Grün ist in MoP je *ein* gelber und *ein* blauer Wert. Ein blauer Stein löst keinen gelben Sockelbonus aus; die Empfehlung warf ihn weg. Unabhängig davon sagen die Gewichte desselben Profils, dass der *Imposante Dioptas* 96 % mehr bringt
- **`orange`/`lila`/`grün` sind keine toten Listen mehr.** Es sind Steinfarben, keine Sockelfarben, und sie waren damit unerreichbar — 78 Listen, die autoritativ aussahen und nie gelesen wurden. Der Planer zieht jetzt aus allen Listen eines Profils die Steine, die die Farbe eines Sockels bedienen, wenn er den Sockelbonus halten will

### Neu
- **`/wc sockel`** — je Gegenstand die gelesene Sockelfolge **mit ihrer Quelle** (Tooltip oder blosse Zählung), die Bonuszeile mit ihrer Farbe, beide Planvarianten mit ihren Wertungen und der Cap-Spielraum vor und nach jedem Gegenstand. Genau das fehlte: in keiner Ausgabe stand je, in welcher Reihenfolge die Sockel gelesen wurden — dieselbe Überlegung wie bei `/wc vz zeilen` und `/wc alarm berufe`
- **`WeintCodex_ValidateGemWeights()`** prüft beim Login die Steindaten gegen sich selbst, wie es `WeintCodex_ValidateEnchantWeights()` seit 2.3.1.0 für Verzauberungen tut: Farbe gegen Werte (rot = Primärwert, Waffenkunde, Parieren; gelb = Krit, Tempo, Meisterschaft, Ausweichen; blau = Ausdauer, Willenskraft, Treffer), ob am Cap überhaupt ein farblich passender Stein mit Wertung übrig bleibt, Steine ohne Eintrag in `gem_stats.lua`, Farben mit ausschliesslich Juwelier-Steinen, und Profile, deren Gewichte ihrer eigenen ersten Empfehlung widersprechen. Fünf offene Reihenfolgefragen meldet sie derzeit (Heilig-Priester, Heilig-Paladin, Wildheit, Windwandler) — die sind Aussagen über das Spiel und bleiben absichtlich unangetastet

### Technisch
- Der Kandidatentopf **ersetzt die kuratierten Listen nicht, er ergänzt sie** — und zwar nur für die Farbbedingung, und nur wenn es überhaupt einen Sockelbonus zu halten gibt. Frei nach Wertung gereiht würde er Jägern einen Kritstein statt eines Beweglichkeitssteins empfehlen: deren Profil wiegt Krit mit 80 gegen Beweglichkeit 100, die eigene Liste sagt aber Beweglichkeit. Wo Gewichte und Liste sich widersprechen, entscheidet weiter die Liste — und der Validator meldet den Widerspruch
- Der Cap-Spielraum wird über die Slots **verbraucht**. Ohne das bekäme jeder Sockel denselben Restweg zum Cap gutgeschrieben und die Seite empföhle zehn Treffersteine für eine Lücke, die einer schliesst
- Die Sockelfolge je Grundgegenstand wird gemerkt: sie ändert sich nie, und die Charakterseite scannt bei jedem Ausrüstungswechsel alle 16 Slots neu
- Der **Gruppencheck** überspringt den Tooltip-Weg (dritter Parameter `false`). Er zählt nur belegte Sockel und braucht keine Farben; 16 Slots mal 25 Spieler wären genau die Zumutung für den Client, die sich jene Seite ausdrücklich verboten hat
- `ScoreStats` und `FirstUncappedGem` sind entfallen, `SocketBonusActive` und `PickGemRecommendation` ebenso — ihre Aufgaben stecken in `GemValue` und `PlanItem`

## [2.4.1.2] – 2026-08-24

### Behoben
- **Der Ingenieurs-Gürtel wurde weiterhin als „Nitrobooster fehlt" gemeldet, obwohl der Booster drauflag.** Die Annahme dahinter war schlicht falsch: der Nitrobooster landet **nicht** im Verzauberungsfeld des Item-Links. `/wc alarm berufe` hat das am gemeldeten Charakter belegt — der angelegte Gürtel trägt im Tooltip „Benutzen: Erhöht 5 Sek. lang Euer Lauftempo enorm", und derselbe Gürtel meldete „keine Verzauberung im Item-Link". Ein Signal, das für den einzigen Fall, für den es gebaut wurde, nichts sieht, ist kein Signal
- **Gefragt wird jetzt zusätzlich am Tooltip, und zwar über die Differenz:** trägt der *angelegte* Gegenstand eine „Benutzen:"-Zeile, die sein *Grundgegenstand* nicht hat, wurde etwas angebracht. Das kommt weiterhin ohne Namen und ohne IDs aus — die Beschriftung stammt aus der Konstanten des Clients (`ITEM_SPELL_TRIGGER_ONUSE`), nicht aus einer Tabelle von uns. Steine und Aufwertungsgrade stören dabei nicht, die fügen keine „Benutzen:"-Zeile hinzu
- **Eine „Benutzen:"-Zeile, die schon dem Grundgegenstand gehört, zählt nicht als Bastelei** — sonst gälte jeder Gürtel mit eigenem Effekt als versorgt
- **Ist der Tooltip noch nicht lesbar, wird nichts behauptet**, sondern ein paar Sekunden später nachgefasst — dieselbe Regel wie überall sonst in dieser Datei

### Technisch
- Der billige Weg bleibt vorn: steht im Verzauberungsfeld des Item-Links etwas, ist auf einem Gürtel ohnehin nur die Bastelei des Ingenieurs möglich, und es wird kein Tooltip gelesen. Der Tooltip-Vergleich läuft nur, wenn der Link nichts sagt — also genau im Fehlerfall
- **Die Testabdeckung trug den Fehler mit.** Sie prüfte den erfolgreichen Pfad ausschliesslich mit einem Verzauberungswert im Link (`item:89241:4223:…`) — also mit einer Annahme, die für diesen Perk nie gegolten hat. Es gibt jetzt fünf Fälle mit einer Tooltip-Attrappe: Bastelei am Tooltip erkannt trotz leerem Link, ohne Zeile bleibt es ein Befund, eine Zeile des Grundgegenstands zählt nicht, unlesbarer Tooltip behauptet nichts, und der Link-Weg trägt weiterhin für sich allein
- `/wc alarm berufe` nennt jetzt beide Wege im Klartext („keine Verzauberung im Item-Link, aber eine Benutzen-Zeile, die der Grundgegenstand nicht hat"), damit die nächste Abweichung wieder in einem Befehl sichtbar ist statt in einer Vermutung

## [2.4.1.1] – 2026-08-24

### Behoben
- **Der Ingenieurs-Gürtel hiess im Alarm „Nitrobeschleuniger" — im deutschen Client heisst er *Nitrobooster*.** Das Rezept lautet „Ingenieurskunst: Nitrobooster"; ein Text, der einen Gegenstand anders nennt als das Spiel, schickt den Leser beim Suchen ins Leere. Auf die *Erkennung* hatte der Name keinen Einfluss — verglichen wird der Verzauberungswert des Item-Links, nie ein Name (siehe den Kopf von `data/professions.lua`) —, aber die Meldung war dadurch trotzdem irreführend
- **Die Nitrobooster brauchen laut Rezept Fertigkeit 400, nicht 500.** Die pauschale Untergrenze von 500 hätte jeden Ingenieur zwischen 400 und 500 stumm über eine Lücke gelassen, die er hätte schliessen können. Jede Vergünstigung darf die Vorgabe jetzt über ein eigenes `minSkill` unterbieten; die Synapsenfedern stehen umgekehrt auf 550

### Neu
- **`/wc alarm berufe` sagt, *was* gelesen wurde** — je Vergünstigung den angelegten Gegenstand (als anklickbarer Link), den Verzauberungswert aus seinem Item-Link, die Sockelzahlen, die Zahl der Schlangenaugen, dazu das Urteil *genutzt / offen / nicht feststellbar*. Auch Berufe ohne hinterlegte Vergünstigung werden mit ihrer Skill-Line-ID genannt. Genau das fehlte, als der Alarm einem Ingenieur „Nitrobooster fehlt" an einen Gürtel schrieb, auf dem der Tinker lag: von aussen war nicht zu unterscheiden, ob die Erkennung danebengreift oder ob schlicht ein zweiter, unverzauberter Gürtel angelegt war. Dieselbe Überlegung wie bei `/wc vz zeilen` — diese Fehlerklasse ist ohne Ausgabe der Rohdaten nicht diagnostizierbar

### Technisch
- Die Entscheidung je Vergünstigung liegt jetzt in **einer** Funktion (`PerkState`), aus der sowohl der Alarm als auch `/wc alarm berufe` lesen. Zwei Fassungen derselben Frage wären genau die Doppelpflege, an der die Verzauberungserkennung in diesem Addon schon einmal gescheitert ist
- Die Testabdeckung hatte eine Lücke, die den Verdacht überhaupt erst offen liess: **jeder Testlink trug die Verzauberung 0**, der erfolgreiche Pfad war also nie geprüft. Es gibt jetzt einen Test mit einem echten MoP-Item-Link samt Nitrobooster (`item:89241:4223:…`) — er bestätigt, dass der Wert korrekt gelesen wird und kein Befund entsteht — plus die Gegenprobe und beide Seiten der Fertigkeitsgrenze

## [2.4.1.0] – 2026-08-24

### Geändert
- **Weggeklickt heisst jetzt fünf Minuten Ruhe, nicht für immer.** Danach erinnert der Ausrüstungs-Alarm wieder, solange die Lücke offen ist — sonst vergisst man sie schlicht. Dauerhaft still wird er, wenn die Lücke behoben ist, oder über `/wc alarm aus`
- **Vier Anlässe bringen die Erinnerung zurück:** ein Zonenwechsel, der Ruhebereich, der Instanzeingang und ein Zeitgeber. Den Zeitgeber braucht es für den Fall, der sonst durchfällt — wer beim Taschensortieren an der Bank stehen bleibt, wechselt weder Zone noch Ruhestatus
- **Aber nur, wenn man gerade nichts anderes macht.** Kampf, Bosskampf, tot, Flugroute, Fahrzeug, Zaubern, Haustierkampf — und Bewegung. Wer läuft, reitet oder fliegt, ist unterwegs und nicht bei der Ausrüstung; dadurch landet die Erinnerung von selbst in dem Moment, in dem man irgendwo stehen bleibt, und das ist genau der, in dem man etwas tun kann
- **Der Instanzeingang übergeht die Quittung.** Er ist der letzte Moment, in dem sich die Lücke noch schliessen lässt, und danach zählt sie eine Stunde lang bei jedem Pull mit. Eine Untergrenze von einer Minute bleibt trotzdem stehen, damit ein zweiter Ladebildschirm die Meldung nicht Sekunden nach dem Wegklicken zurückbringt
- `/wc alarm ruhe` heisst jetzt `/wc alarm erinnern` (der alte Name funktioniert weiter) und schaltet **alle** Erinnerungen, nicht nur die im Ruhebereich. Vier einzelne Schalter wären vier Fragen an den Nutzer, wo er nur eine hat

### Behoben
- **Die Gürtelschnalle verschwand in der Sockelzahl.** Ein Gürtel ohne Schnalle und mit einem leeren Sockel meldete „2 Sockel leer" — und wer das las, wusste nicht, dass er dafür erst eine *Ewige Gürtelschnalle* kaufen muss. Ein leerer Sockel und ein fehlender Sockelplatz sind zwei verschiedene Besorgungen; sie stehen jetzt nebeneinander („Gürtelschnalle fehlt · 1 Sockel leer") und werden nirgends mehr zusammengezählt

### Neu
- **Berufsvergünstigungen zählen mit, wenn der Charakter den Beruf hat** (`data/professions.lua`). Was nur dieser Beruf kann und ungenutzt ist, wird zum eigenen Befund:
  - **Ingenieurskunst** — der Gürtel. Ihn kann in MoP ausser dem Ingenieur niemand verzaubern, weshalb der normale Ausrüstungscheck den Slot gar nicht kennt: die Lücke war bisher unsichtbar
  - **Schmiedekunst** — je ein Zusatzsockel an Handschuhen und Armschienen, behandelt wie die Gürtelschnalle
  - **Juwelenschleifen** — die Schlangenaugen, gezählt („Schlangenauge: 0 von 2 eingesetzt")
  - **Verzauberkunst** — die beiden Ringverzauberungen, wie bisher über den vorhandenen Check
- **Handschuhe, Umhang, Armschienen und Schultern bekommen einen Hinweis statt eines Befunds.** Diese Slots kann jeder verzaubern; ob dort schon die stärkere Berufsvariante liegt, ist ohne verlässliche Verzauberungs-IDs nicht zu beantworten, und „du könntest was Besseres tragen" wäre das Urteil, das dieses Modul nicht fällt. Fehlt die Verzauberung aber ganz, nennt eine eigene Zeile, was der Beruf zusätzlich hergibt — Synapsenfedern, Stickerei, Fellbesatz, Geheime Inschrift
- `/wc alarm` nennt im Status, welche Berufsvergünstigungen für diesen Charakter erkannt wurden. Ohne das ist von aussen nicht zu unterscheiden, ob der Beruf nicht erkannt wurde oder ob gerade nichts offen ist

### Technisch
- **Aus `data/professions.lua` wird kein Name und keine Verzauberungs-ID jemals verglichen.** Alle Namen dort sind reiner Anzeigetext; entschieden wird ausschliesslich über Zählbares — liegt auf dem Slot überhaupt eine Verzauberung, ist der Zusatzsockel belegt, wie viele Juwelierssteine stecken drin. Das ist die Lehre aus `data/enchants.lua`: jene IDs sind von Hand gepflegt, am Client nicht auflösbar und von Blizzard mitten in MoP umbenannt worden. Eine Meldung, die an so einer ID hinge, wäre eine Meldung über unsere Tabellenpflege
- Erkannt werden Berufe über die Skill-Line-ID, nie über den Namen (der Client ist lokalisiert) — dieselbe Regel wie bei `HasEnchanting()`. Neue Berufe sind eine Tabellenzeile
- Ab Fertigkeit 500 (`WeintCodex_ProfessionMinSkill`). Wer den Beruf gerade erst angefangen hat, kann nichts davon herstellen, und eine Meldung darüber wäre ein Mangel, den er nicht beheben kann
- Der Zusatzsockel der Schmiedekunst hat dieselbe Unschärfe wie die Gürtelschnalle: ein angebrachter, aber leerer Sockel ist vom nicht angebrachten nicht zu unterscheiden, weil `GetItemStats` nur die Sockel des Grundgegenstands kennt. Der Text sagt das (»fehlt oder ist leer«), statt sich für eine der beiden Lesarten zu entscheiden
- Die zwölf Juwelier-Steine tragen in `data/gems.lua` jetzt `jcOnly = true`, statt aus dem Anzeigetext „(nur Juweliere)" herausgelesen zu werden
- Alle vier Erinnerungsanlässe laufen durch **eine** Schleuse (`AmbientCheck`), damit der „nur wenn man nichts anderes macht"-Vorbehalt und die Kostenbremse (frühestens alle fünf Minuten eine ungefragte Prüfung — jede liest je Gegenstand den Tooltip) an einer Stelle stehen und nicht an vieren
- Quittungen speichern den Zeitpunkt statt eines „ja". Eine Quittung ohne Zeitpunkt (so schrieb 2.4.0.2) gilt als abgelaufen — die richtige Richtung: nach dem Update erinnert der Alarm einmal, statt eine alte Zustimmung für immer weiterzutragen

## [2.4.0.2] – 2026-08-24

### Geändert
- **Der Ausrüstungs-Alarm bleibt stehen, bis man ihn wegklickt.** Bisher verschwand er nach neun Sekunden von selbst — genau in der Zeit, in der man auf die Taschen schaut, das Teil aus dem Handelsfenster nimmt oder gerade lädt. Eine Meldung, die man verpassen kann, ist für diesen Zweck keine
- **Und das Wegklicken ist die Antwort, nicht nur das Schliessen eines Fensters.** Wer sie weggeklickt hat, bekommt *genau diesen* Befund nicht wieder zu sehen — weder beim nächsten Betreten eines Ruhebereichs noch beim nächsten Anlegen desselben Teils, und auch nicht nach einem `/reload`. Der Umweg über eine wiederkehrende Erinnerung, die man jedes Mal erneut wegklickt, wäre genau die Belästigung, die einen dazu bringt, das Ganze abzuschalten
- **Ändert sich der Befund, meldet er sich wieder.** Die Quittung hängt an Art und Anzahl (`Verzauberung fehlt` + `2 Sockel leer`), nicht am Slot: wer die Handschuhe verzaubert und dabei den Sockel leer lässt, hat einen anderen Befund als vorher und sieht ihn auch. Behobene Quittungen werden bei jedem Lauf verworfen — sonst bliebe der Slot Wochen später stumm, wenn er wieder offen ist
- **Beim Pull weicht eine stehende Meldung.** Eine Fläche mitten im Bild während eines Bosskampfes ist das, was einen dazu bringt, das Ganze abzuschalten. Quittiert wird dabei nicht: nach dem Kampf wird neu geprüft, und steht der Befund noch, steht auch die Meldung wieder da
- `/wc alarm erneut` hebt das Wegklicken auf — der Rückweg, ohne den eine einmal quittierte Lücke für immer stumm bliebe und die einzige Abhilfe in den SavedData stünde. `/wc alarm` zählt im Status mit, wie viele Befunde weggeklickt sind

### Entfernt
- `/wc alarm dauer <sek>` und die Einstellung `duration`. Eine Anzeigedauer gibt es nicht mehr; ein Schalter, der nichts mehr schaltet, ist schlimmer als keiner

## [2.4.0.1] – 2026-08-24

### Neu
- **Ausrüstungs-Alarm: eine grosse Einblendung, wenn ein frisch angelegtes Teil weder verzaubert noch versockelt ist.** Bildschirmmitte, Signalton, verschwindet nach ein paar Sekunden von selbst — die Bauform, die man von den Bossmods kennt, weil sie genau das leistet, was hier fehlte: eine Meldung, die man *nicht* übersieht. Ein neuer Gegenstand ist der einzige Moment, in dem man die Lücke ohne Nachschauen bemerken kann; bis dahin stand sie auf der Charakterseite, die man dafür erst hätte öffnen müssen
- **Dieselbe Meldung als Erinnerung, sobald man einen Ruhebereich betritt.** Der Ruhebereich ist kein beliebiger Auslöser, sondern der einzige sinnvolle: dort steht der Verzauberer, dort ist die Bank, dort lässt sich das erledigen. Vor dem Pull davon zu erfahren nützt niemandem. Höchstens einmal alle 15 Minuten — wer zwischen Bank, Auktionshaus und Verzauberer hin und her läuft, löst das Ereignis sonst am laufenden Band aus
- **Linksklick öffnet die passende Charakterseite** — Sockel, wenn nur Steine fehlen, sonst Verzauberungen. Rechtsklick blendet aus. `/wc alarm bewegen` stellt die Meldung zum Verschieben stehen; die Position wird gespeichert
- `/wc alarm` schaltet an und aus (`an`/`aus`), den Ton (`ton`), die Erinnerung im Ruhebereich (`ruhe`), die Anzeigedauer (`dauer 12`) und prüft auf Zuruf (`jetzt`). Der Hinweis auf `/wc alarm aus` steht in der Meldung selbst — eine Einblendung, die man nur über die Dokumentation wieder loswird, ist eine Zumutung

### Geändert
- **Der Alarm zählt, er bewertet nicht.** Gemeldet wird ausschliesslich „Verzauberung fehlt" und „Sockel leer" — dieselbe Zurückhaltung wie im Gruppencheck und aus demselben Grund: beides ist unstrittig, „nicht ideal" wäre eine Meinung. Eine bildschirmfüllende Meldung über eine Meinung schaltet man nach dem dritten Mal ab, und danach sieht man auch die echten Lücken nicht mehr. Ob eine Verzauberung zur Spec passt, sagt weiterhin nur die Charakterseite, wo man es in Ruhe liest
- **Erst ab Selten (blau).** Der Weg von 85 auf 90 besteht aus grünen Gegenständen, die niemand verzaubert; sie zu melden wäre formal richtig und praktisch nur Lärm
- Die Onboarding-Tour hat eine Seite mehr (Ausrüstungs-Alarm) — eine Meldung, die von selbst aufgeht, sollte man beim ersten Start einmal angekündigt bekommen, samt dem Befehl, der sie wieder abschaltet

### Technisch
- `modules/gearalert.lua` führt **keine eigene Prüfung**: was offen ist, beantwortet `WeintCodex.Charakter.Scan()` — dieselbe Slotliste, dieselbe Auflösung des Verzauberungs-Topfes (inklusive „Ringe nur mit Verzauberkunst") und dieselbe Sockelerkennung wie die Charakterseite. Gelesen wird daraus aber nur `enchId == nil` bzw. `socket.gemId == nil` und **nicht** der bewertete `status`: der ist `neutral`, sobald das Spec-Profil für den Slot keine Empfehlung führt, und ein fehlender Stein bleibt ein fehlender Stein, auch wenn das Profil zu diesem Sockel nichts zu sagen hat
- `ScanCharacter()` schreibt `socketsKnown` an jede Sockelzeile. Kannte der Client die Basisdaten des Gegenstands nicht, sind die eingebauten Sockel unbekannt und übrig bliebe nur die geratene Gürtelschnalle. Die Charakterseite nimmt das hin — ihr Cache ist warm, und sie zeigt eine Zeile, keine Einblendung; ein Alarm darf sich darauf nicht stützen
- Vier Sperren, jede gegen einen konkreten Fehlalarm: nichts vor `PLAYER_ENTERING_WORLD` plus Vorlauf (bei `PLAYER_LOGIN` sind weder Spec noch Item-Cache verlässlich, und `PLAYER_EQUIPMENT_CHANGED` feuert beim Anmelden und nach jedem Ladebildschirm für angelegte Gegenstände, ohne dass jemand etwas angelegt hätte); nichts über einen Gegenstand, dessen Basisdaten fehlen, sondern ein Nachfassen ein paar Sekunden später; nichts unterhalb von Selten; nichts im Kampf. Was im Kampf anfällt, wird nach `PLAYER_REGEN_ENABLED` **neu geprüft** statt aus dem Gedächtnis gezeichnet — zwischen Pull und Ende kann sich die Ausrüstung geändert haben
- Der Scan ist entprellt (2,5 s): er liest je Gegenstand den Tooltip, und beim Umsockeln feuert `PLAYER_EQUIPMENT_CHANGED` mehrfach hintereinander. Beim Anlegen wird nur über die Slots gemeldet, die seitdem gewechselt haben; die Erinnerung im Ruhebereich nennt alles Offene
- Die Sperrfrist der Erinnerung liegt als Zeitstempel in den SavedData und nicht in einer Laufzeitvariablen: `GetTime()` beginnt nach jedem `/reload` von vorn, und dann käme sie genau dann wieder, wenn man das Addon gerade neu geladen hat
- Die Fläche bleibt **eckig**. Die Eckmasken aus `core/ui.lua` brauchen die Farbe des Untergrunds, und hinter dieser Einblendung liegt die Spielwelt — dieselbe Begründung, aus der auch das Hauptfenster keine runden Ecken hat

## [2.4.0.0] – 2026-08-23

### Behoben
- **Jägern wurde dauerhaft „Nebenhand: Kein Gegenstand angelegt" gemeldet.** Ein Jäger trägt in MoP seine Distanzwaffe in der Haupthand, und der Nebenhand-Slot ist für ihn schlicht nicht benutzbar — der Hinweis war ein Mangel, den er gar nicht beheben konnte. Geprüft wurde bis dahin nur auf `INVTYPE_2HWEAPON`, und ein Bogen heisst `INVTYPE_RANGED`. Der Anlegeplatz allein reicht dafür aber nicht: `INVTYPE_RANGEDRIGHT` tragen sowohl Schusswaffen und Armbrüste (belegen beide Hände) als auch Zauberstäbe (tun es nicht — ein Caster mit Zauberstab hat sehr wohl eine Nebenhand). Entschieden wird jetzt über die Waffen-Unterklasse; sind die Item-Daten noch nicht im Cache, bleibt der Hinweis aus und der Scan wird nachgeholt, statt „kein Gegenstand angelegt" über unseren eigenen Cache zu behaupten

### Neu
- **Gruppencheck: Verzauberungen und Sockel der ganzen Gruppe auf einer Seite.** Neuer Navigationspunkt unter *Raid* (auch über `/wc gruppe`). Er inspiziert der Reihe nach jedes Gruppen- bzw. Raidmitglied und zeigt je Zeile, wie viele Verzauberungen fehlen und wie viele Sockel leer sind — samt Liste der betroffenen Slots im Tooltip und im Detailbereich rechts. Die Filterleiste schaltet zwischen *Alle Mitglieder* und *Nur mit Befund*; sortiert wird nach Befund, oben steht also, was jemanden interessiert
- **Die Seite zählt, sie bewertet nicht.** „Verzauberung fehlt" und „Sockel leer" sind unstrittig; „falscher Stein" wäre ein Vorwurf, und für den fehlt bei fremden Spielern alles, was ihn tragen könnte — die Spec meldet der Client beim Inspizieren nicht verlässlich, und ein Tooltip-Scan über 16 Slots mal 25 Spieler wäre eine Zumutung für den Client. Ob eine Verzauberung zur Spec passt, entscheidet weiterhin nur die Charakterseite und nur für den eigenen Charakter
- **Ringe zählen nicht mit.** Ringe darf nur verzaubern, wer den Beruf selbst geskillt hat, und den Beruf eines fremden Spielers kann der Client nicht melden. Ein Nicht-Verzauberer bekäme sonst dauerhaft zwei erfundene Mängel
- **Nicht erreichbar ist kein Befund.** Wer zu weit weg, offline oder in einer anderen Phase ist, lässt sich nicht inspizieren. Diese Zeilen sagen das und zählen nicht als geprüft — eine Übersicht, die Ungeprüftes als geprüft zählt, ist schlimmer als gar keine
- **WeakAuras: grüner Haken an jeder Aura, die schon installiert ist.** Links in der Zeile, dazu im Tooltip, ob das Paket vollständig oder nur teilweise vorhanden ist. Die Schaltfläche rechts sagt danach *Neu importieren* statt *Installieren* — und *Aktualisieren*, wenn eine andere Fassung vermerkt ist als die angebotene. Der Detailbereich zählt „installiert: 7 / 9"

### Geändert
- **Der Clear-Status ist charakterbezogen.** Ein Schlachtzugs-Lockout gehört in MoP dem einzelnen Charakter, nicht dem Konto: der Main hat Immerseus gelegt, der Twink steht am Mittwoch trotzdem vor einem vollen Raid. Bis 2.3.1.0 lag der Fortschritt kontoweit, jeder Twink sah also den Stand des zuletzt gespielten Charakters. Der Lockout-Import konnte das nicht heilen — er setzt Kills, aber er nimmt keine zurück, weil ein fehlender Eintrag genauso gut „Server hat die Raid-Info noch nicht geschickt" heissen kann. Die bisherigen Daten wandern einmalig auf den gerade eingeloggten Charakter; alle anderen holen sich ihren Kill-Stand binnen Sekunden selbst aus der Lockout-API
- Der Fortschrittsbalken der Bossguides nennt im Tooltip den Charakter, dessen Stand er zeigt. Ohne das ist „0 %" auf dem Twink nicht von einem Fehler zu unterscheiden
- Die Onboarding-Tour hat eine Seite mehr (Gruppencheck)

### Technisch
- `modules/groupcheck.lua`: eigene Inspektionsschlange über `NotifyInspect`/`INSPECT_READY`, **ein Eintrag nach dem anderen** mit Zeitüberschreitung (2 s) und Pause (0,7 s). Der Server beantwortet immer nur eine Inspektion, und zu schnelles Nachfassen liefert die Daten des vorigen Spielers. Vor jedem Auslesen wird der Name der Einheit erneut gegen den Eintrag der Schlange geprüft: die Gruppe kann sich während des Laufs ändern, `raid7` ist dann jemand anders, und eine Zeile mit fremder Ausrüstung zu füllen wäre ein Vorwurf an den Falschen
- Die Seite liest ausschließlich aus dem Item-Link (Verzauberungs-ID, Steine) plus `GetItemStats` für die eingebauten Sockelplätze — keine Tooltip-Scans. Die Bausteine dafür kommen aus `modules/charakter.lua` (`ParseItemLink`, `ScanItemSockets`, `ClassifyEquipLoc`, `OffhandEnchSlot`), eine zweite Fassung wäre die Doppelpflege, an der die Verzauberungserkennung schon einmal gescheitert ist
- `ScanItemSockets()` gibt jetzt zusätzlich zurück, ob der Client die Basisdaten des Gegenstands überhaupt hatte. Ohne sie kennt die Funktion die eingebauten Sockel nicht — beim eigenen Charakter fällt das kaum auf, bei fremden sehr wohl, und „0 Sockel" wäre dort eine Aussage über unseren Item-Cache statt über die Rüstung
- Neuzeichnen ist entprellt (2 s während eines Laufs): WoW gibt Frames nie wieder frei, und ein Neuaufbau je Mitglied setzt ausserdem die Bildlaufposition zurück, während jemand darin liest. Den Fortschritt trägt solange die Schaltfläche in der Titelleiste
- `SavedData.encounterProgress.characters["Name-Realm"][instanz]` löst die bisherige kontoweite Ablage ab. Die alten Zweige sind am Inhalt erkennbar (`bosses`/`resetStamp`) und werden beim ersten Zugriff verschoben — an einer Merkerzahl erkannt bliebe die Migration nicht richtig, wenn eine alte und eine neue Addonversion sich abwechseln
- `waIds` in `data/weakauras/*.lua` trägt die Anzeigenamen, unter denen WeakAuras die jeweilige Aura führt. Sie stecken im Importstring und sind von aussen nicht zu erraten — die mitgelieferten Pakete heissen „Fojji - Warrior UI [MoP]", die Zeile heisst „Krieger". Wie sie aus dem String zu ziehen sind, steht im Kopf von `data/weakauras/init.lua`. Für zugestellte Auren, deren Namen niemand kennen kann, merkt sich das Addon stattdessen, welche Anzeigen der Import über diese Seite tatsächlich angelegt hat (Differenz vor/nach dem Klick, aufgelöst beim nächsten Aufbau der Seite)
- Der Unterschied trägt bis in die Bewertung: die kuratierte Liste enthält nur Wurzeleinträge, da müssen alle da sein; die beobachtete enthält auch jede Unteraura, dort genügt eine. Ist WeakAuras gar nicht geladen, sagt die Zeile nichts — „nicht installiert" wäre dann eine Aussage über unser Unwissen
- `WeintCodex.Navigation.GoToTab(tabId)` ist jetzt öffentlich, damit Slash-Befehle einen Bereich so öffnen können, als hätte jemand in der Spalte geklickt

## [2.3.1.0] – 2026-08-21

### Behoben
- **Einem korrekt verzauberten Elementarschamanen wurde seine Stiefelverzauberung als Mangel gemeldet.** Unter *Handlungsbedarf* stand „Füße: Verzauberung nicht ideal -> Pandarenpfoten", während auf den Stiefeln *Großes Tempo* lag. Dahinter steckten zwei Fehler, und der zweite ist der eigentliche. Erstens war *Stiefel - Pandarenpfoten* in `data/enchants.lua` mit **175 Meisterschaft** eingetragen; die Verzauberung gibt **140** (bestätigt am deutschen Gegenstand 74718). Zweitens — und das ist der Punkt — kannte die Empfehlungsliste für die Füße pro Spec nur *eine* der beiden Verzauberungen. In MoP stehen dort aber zwei gleichermassen vertretbare zur Wahl: 140 Meisterschaft **plus Lauftempo** gegen 175 Tempo. Welche besser ist, hängt an Tempo-Breakpoints, die das Addon nicht kennen kann — es sieht weder die Raidbuffs noch die Reforge-Absicht. Eine der beiden als „nicht ideal" zu melden, behauptet ein Wissen, das nicht da ist. Jetzt stehen beide in der Liste; wer eine davon trägt, liest „Optimal"
- **Wer Pandarenpfoten trug, bekam zusätzlich „schwächere Stufe" zu lesen.** Der Werteabgleich hielt die tatsächlichen 140 Meisterschaft gegen die falschen 175 der Datenbank und stufte die Verzauberung als die zu niedrige Variante ein — eine Beanstandung an einer Verzauberung, an der nichts auszusetzen war
- **Der Kopf des Ausrüstungs-Checks widersprach der Liste darunter.** Oben stand „Alles versorgt · Verzauberungen, Sockel und Caps sind sauber", die Karte hiess „Handlungsbedarf", ihr Vermerk sagte „nichts offen" — und darunter stand trotzdem ein Punkt. Alle drei waren für sich richtig und zusammen unlesbar: gezählt wurden nur Mängel (Prio 1–3), angezeigt wurden auch Hinweise (Prio 4). Beide Zahlen werden jetzt geführt und benannt. Gibt es nur Hinweise, heisst die Karte *Feinabstimmung*, der Vermerk nennt „1 Hinweis" statt „nichts offen", und der Kopf sagt „Keine Mängel · 1 Hinweis zur Feinabstimmung"
- **25 Spec-Profile führten für die Füße eine Empfehlung, die ihren eigenen `statWeights` widersprach.** Der falsche Wert von oben steckt dahinter: mit 175 statt 140 sahen Pandarenpfoten und Großes Tempo wie derselbe Wert aus, also gewann in jedem Profil schlicht der höher gewichtete Stat. Alle Stiefellisten sind neu gesetzt (Regel im Kopf von `data/spec_profiles.lua`), und drei Handschuh-Listen standen in der Reihenfolge verkehrt herum: Heilig-Paladin führte Tempo (7.650) vor Meisterschaft (12.750), Nebelwirker umgekehrt, Blut-Todesritter empfahl Tempo statt Meisterschaft

### Geändert
- Der Kopf von `data/spec_profiles.lua` sagt jetzt ausdrücklich, was `bestEnchants` ist: **keine Rangliste mit einem Sieger, sondern die Menge der vertretbaren Verzauberungen.** Der erste Eintrag ist nur das, was auf ein noch unverzaubertes Teil gehört; alles, was nicht drinsteht, meldet das Addon als Mangel — und ein Mangel muss einer sein. Dazu die Stiefel-Regel im Klartext, samt der Begründung, warum das Lauftempo einen Wertungsunterschied von einem Viertel aufwiegt (genau der Abstand zwischen 140 und 175)

### Technisch
- **`WeintCodex_ValidateEnchantWeights()`** (`data/spec_profiles.lua`, aufgerufen beim Login neben den drei bestehenden Prüfungen) gleicht die Empfehlungslisten gegen die Gewichte desselben Profils ab. Genau diese Lücke hat den Fehlbericht möglich gemacht: die Listen sind von Hand gepflegt und wurden mit nichts verglichen. Geprüft wird **Vollständigkeit** (was mehr als die Hälfte der ersten Empfehlung wert ist, muss mit in der Liste stehen) und **Reihenfolge** (die erste darf nicht um mehr als ein Viertel geschlagen werden)
- Der Wächter vergleicht **nur, wo der Vergleich trägt**: Verzauberungen desselben Slots mit genau *einem* Sekundärwert, der für diese Spec nicht auf ein Cap läuft. Primärwerte, Ausdauer und Ausweichwerte bleiben draussen — für sie sind die Gewichte Prioritäten und keine Umrechnungskurse, und „240 Ausdauer × 100 schlägt 160 Stärke × 45" wäre Arithmetik ohne Aussage. Ein naiver Vergleich über alle Slots meldet 43 Treffer, die grosse Mehrheit davon Unsinn; diese Fassung meldet im Ist-Zustand null und schlägt bei beiden Gegenproben an (alter Wert 175 wieder eingesetzt, bzw. eine der beiden Stiefelverzauberungen aus einer Casterliste entfernt)
- Mehrfach vergebene IDs derselben Verzauberung (74715/4426 „Großes Tempo", 4422/4424, 4423/4892, 4432/4434) zählen für den Wächter als ein Eintrag — sonst meldete er eine Lücke, wo dieselbe Verzauberung unter ihrer anderen ID längst gelistet ist
- Die Companion-Nachricht `character_sheet` trägt je Mangel weiterhin die Priorität mit; die Trennung Mangel/Hinweis lässt sich dort also ohne Vertragsänderung nachziehen

## [2.3.0.1] – 2026-08-20

### Behoben
- **Ein gelber Stein galt in einem blauen Sockel als „Optimal".** Gemeldet an einem Furor-Krieger: im Sockel der Zweihandwaffe steckte ein *Glatter Goldberyll*, die Zeile trug das grüne Häkchen, und direkt darüber stand „Sockelbonus: +60 Stärke — genutzt (Farbe matchen)". Zusammen behaupteten die beiden Zeilen etwas, das es im Spiel nicht gibt: ein gelber Stein aktiviert keinen blauen Sockel. Die Ursache waren zwei verschiedene Fragen, die dieselbe Variable benutzten — *welcher Stein gehört hier hinein* beantwortet die Farbe des **Sockels**, *löst er den Bonus aus* die Farbe des **Steins**. Die Bewertung fragte nach der Steinfarbe und verglich den gelben Kritstein deshalb mit der Empfehlung für gelbe Sockel, in der er an erster Stelle steht — daher die 100 %. Gemessen wird jetzt gegen die Sockelfarbe, also gegen genau die Liste, aus der auch die Empfehlung in derselben Zeile kommt
- **Die Sockelbonus-Zeile sagte die Empfehlung und klang wie eine Tatsache.** „genutzt (Farbe matchen)" stand dort, sobald das Matchen sich *rechnerisch lohnt* — was tatsächlich in den Sockeln steckt, hatte auf diesen Text keinen Einfluss. Der Zustand wird jetzt an den angelegten Steinen abgelesen („aktiv (Farben passen)" bzw. „nicht aktiv — Steinfarbe passt nicht zum Sockel"), und die Empfehlung steht als eigene Aussage daneben („bewusst ignoriert — reiner Primärstein ist stärker"). Ist die Farbe eines Steins nicht bestimmbar, sagt die Zeile nichts über den Zustand, statt ihn zu raten
- **Am Trefferkap widersprachen sich Entscheidung und Empfehlung.** Der beste blaue Stein des Furor-Kriegers ist *Stechender Dioptas* (+160 Krit, +160 Treffer); unter dem Trefferkap schlägt er den reinen Kritstein, Matchen ist also gratis und der Bonus geschenkt. Am Kap ist seine halbe Wertung wertlos — die Sockelbonus-Entscheidung rechnete das nicht mit und erklärte das Matchen weiter für lohnend, während die Empfehlungszeile darunter wegen desselben Caps längst den *Glatten Goldberyll* vorschlug. Beide Seiten rechnen jetzt mit gecappten Werten: für den gemeldeten Fall (blauer Sockel, +60 Stärke, Treffer am Kap) kostet Matchen 8.400 Wertung und bringt 6.000 — der reine Kritstein gewinnt, und das Fenster sagt es an beiden Stellen gleich
- **Die Meldung „Verzauberungs-ID 4416 (Handgelenke) passt nicht zur Datenbank" war ein Fehlalarm.** Angelegt war die richtige Verzauberung; der Client nennt sie nur anders, als sie in `data/enchants.lua` steht. Eine Tooltip-Zeile **mit** Werten, zu der kein Eintrag des Slots passt, widerspricht der Tabelle wirklich — dafür ist die Warnung da, falsch zugeordnete IDs gab es mehrfach. Eine reine **Namenszeile** widerspricht ihr nicht: sie sagt nur, dass wir den Client-Namen dieser ID nicht kennen, und der Name ist das unzuverlässigste Feld der Datei (von Hand gepflegt, am Client nicht auflösbar, von Blizzard mitten in MoP umbenannt). Die Zeile vermerkt das jetzt leise mit „(Name so nicht in der Datenbank)", statt einen Mangel zu behaupten, den es nicht gibt
- **Die Handgelenks-Beweglichkeit stand mit 170 statt 180 in der Datenbank** — dieselbe Altlast, die bei der Handgelenks-Stärke schon einmal korrigiert wurde. In MoP geben die Handgelenke auf allen drei Primärwerten 180; nur die Sekundärwertung bleibt bei 170

### Geändert
- `/wc vz` nennt zu jedem Stein die **Steinfarbe und die Sockelfarbe** und markiert, wenn beide nicht zusammenpassen. Diese Fehlerklasse war von aussen nicht diagnostizierbar: die Sockelfarbe stand in keiner Ausgabe
- Die blaue Steinliste der beiden Krieger-DPS-Specs endet jetzt auf *Gezackter Dioptas* (+160 Krit, +120 Ausdauer). Am Trefferkap sind die beiden Einträge davor wertlos, und ohne einen Stein ohne Treffer hätte die Sockelbonus-Entscheidung überhaupt keinen Vergleichswert — sie erklärte Matchen dann pauschal für wertlos statt es auszurechnen

### Technisch
- `SOCKET_ACCEPTS` + `GemMatchesSocket()` (`modules/charakter.lua`) beantworten die Farbfrage an einer Stelle: die MoP-Mischfarben zählen für beide Grundfarben, Prisma- und Einfachsteine für alles. `GemColor()` liest die Farbe aus `data/gems.lua` und fällt auf die Unterklasse des Gegenstands zurück (Steine sind Klasse 3, ihre Unterklasse **ist** die Farbe) — damit sind auch Steine erfasst, die in der Datendatei fehlen, ohne von der Übersetzung abzuhängen. Unbekannte Farbe liefert `nil` und wertet nichts ab
- `FirstUncappedGem()` ist die eine Stelle, an der „welcher Stein dieser Liste läuft nicht in einen gecappten Stat" beantwortet wird. `EvaluateSocketBonus()` und `PickGemRecommendation()` benutzen sie beide — vorher hatte nur die Empfehlung diese Prüfung, und genau darin bestand der Widerspruch
- Die Menge der übercappten Stats wird in `ScanCharacter()` direkt nach `BuildCapStates()` gebildet, nicht mehr erst im Overcap-Pass danach. Das Markieren der einzelnen Zeilen bleibt dort, wo es hingehört; die Entscheidung braucht nur die Menge, und die steht schon vorher fest
- `EvaluateSocketBonus()` liefert `worthwhile` (Empfehlung) und `active` (Zustand) getrennt zurück. Sie zu einer Aussage zu verschmelzen war der Anzeigefehler
- Die Schlüssel von `bestGems` sind **Sockelfarben**, nicht Steinfarben: MoP-Gegenstände haben nur rote, gelbe, blaue, Meta- und Prismasockel. Die Einträge `orange`/`lila`/`grün` waren nur über den Fehler oben erreichbar. Der Kopf von `data/spec_profiles.lua` sagt das jetzt, samt der Regel, dass die Liste bis zum Ende tragen muss

## [2.3.0.0] – 2026-08-19

### Behoben
- **„Anmeldungen abrufen" holte nie neue Anmeldungen – es konnte gar nicht.** Der Knopf löst ein `/reload` aus, und genau das war der Fehler: WoW schreibt seine gespeicherten Variablen beim `/reload` **zuerst aus dem Arbeitsspeicher zurück in die Datei** und liest sie erst danach wieder ein. Alles, was die WeintCompanion in der Zwischenzeit zugestellt hatte, war damit gelöscht, bevor das Addon es sehen konnte. Zurück kam der Stand vom Login – jedes Mal. Schlimmer noch: die Companion merkt sich, was sie zuletzt geschickt hat, und schickt einen unveränderten Roster kein zweites Mal, die zerstörte Zustellung war also **weg**. Die Anmeldeliste konnte so tage- bis wochenalt sein, ohne dass irgendwo etwas fehlte. Die Zustellung liegt jetzt zusätzlich in einer Datei im Addon-Ordner, die WoW bei jedem `/reload` neu ausführt und **niemals zurückschreibt**. Braucht **WeintCompanion 2.3.0**
- **Eigene Twinks standen an den Plätzen echter Spieler.** Beim Login trug das Addon ungefragt den gerade eingeloggten Charakter in eine offene Anmeldezeile ein, sobald dessen Klasse zu genau einer passte – dauerhaft und für das ganze Konto. Der eine Krieger, der sich noch nicht zugeordnet hat, ist aber nicht deshalb man selbst, weil man gerade auf einem Krieger spielt. Über mehrere Twinks hinweg sammelten sich so mehrere eigene Charaktere im Roster, und weil die Zeile danach als „aufgelöst" galt, lud der Kalender **den eigenen Twink ein und den echten Spieler nicht** – ohne dass irgendwo eine Einladung fehlte. Das Addon rät hier nicht mehr. Zugeordnet wird über den Bot (`/weintcharakter setzen`), die Seite *Charakterzuordnung* der Companion oder das Stift-Symbol in der Zeile
- **Der Kalender-Eintrag enthielt nur den Ersteller.** `C_Calendar.EventInvite` trägt niemanden sofort ein – es lässt den Namen erst vom Server auflösen. Das anschließende Speichern im selben Durchlauf sicherte deshalb einen Termin, in dem noch keine einzige Einladung stand; und weil der Knopf danach unverändert dastand, erzeugte jeder weitere Klick einen weiteren leeren Termin. Der Ablauf ist jetzt zweigeteilt: *Einladungen vorbereiten* legt den Entwurf an und verschickt die Einladungen, der Knopf zählt mit, wie viele der Server bestätigt hat („Eintrag speichern (21/22)"), und erst der zweite Klick speichert
- Namen, die der Server nicht findet, werden **beim Namen genannt** statt still zu fehlen. Bisher zählte jede abgeschickte Einladung als gelungen, auch die ins Leere

### Neu
- **Die Anmeldeliste sagt, wie alt sie ist.** Bisher stand dort nur das Raiddatum – also der Tag, an dem der Raid stattfindet. Ein zwei Wochen alter Stand für den kommenden Mittwoch sah damit exakt aus wie ein frischer. Jetzt steht daneben „Zugestellt 19.08. 14:20 · vor 3 Stunden", grün bis einen Tag, gelb bis eine Woche, danach rot. Dieselbe Zeile steht über der Einladungsvorschau des Kalenders, weil das die Stelle ist, an der man wissen will, ob man gleich die richtigen Leute einlädt
- Die Inspektorspalte der Raidseite zählt die Anmeldungen **ohne Zuordnung** getrennt aus – das ist die Zahl, um die der Kalender-Einlauf kleiner ausfällt

### Geändert
- Gespeicherte Namenskorrekturen aus früheren Versionen werden **einmalig zurückgesetzt** und beiseitegelegt (`rosterNameOverridesLegacy`, es geht nichts verloren). Bis 2.2.0.0 schrieb die automatische Selbst-Erkennung in denselben Topf wie das Stift-Symbol; hinterher war eine Angabe des Nutzers nicht mehr von einer Vermutung des Addons zu unterscheiden, und die falschen wären sonst nie wieder weggegangen. Das Addon sagt es einmal im Chat
- *Raiddaten löschen* holt die zuletzt zugestellten Anmeldungen beim nächsten `/reload` wieder herein, statt sie unerreichbar zu machen

### Technisch
- `data/companion_live.lua` ist die neue Live-Brücke: eine Lua-Datei im Addon-Ordner, die die Companion schreibt und WoW nur liest. `ProcessInbox()` liest beide Quellen und **bevorzugt die Brücke** – sie ist per Konstruktion der jüngere Stand; die Inbox wird dann ungelesen geleert, weil beides einzuarbeiten jeden Import doppelt melden würde. Fehlt die Brücke (ältere Companion, Addon frisch entpackt), bleibt es beim bisherigen Weg. Voller Vertrag in `docs/live-bridge.md` drüben
- Das Addon merkt sich in `SavedData.companionLive.lastStamp`, welchen Stand es eingearbeitet hat, und überspringt einen unveränderten – es kann die Datei nicht leeren, und ohne diese Marke meldete jeder `/reload` denselben Import erneut
- `CompanionAtLeast()` liest die Versionsmarke bevorzugt aus der Brücke: sie steht in einer Datei, die WoW nur liest, während die Marke in der Inbox vom `/reload` überschrieben worden sein kann
- `WeintCodex.Raids.Freshness(data)` ist die eine Stelle, an der „wie alt ist dieser Stand" beantwortet wird; `importedAt` setzt `ProcessImport` in `modules/sync.lua` bei jedem Einarbeiten. Fehlt es (Stand aus einer älteren Version), heisst es „Stand unbekannt" statt einer geratenen Zahl
- Eine manuelle Namenskorrektur ist jetzt eine Tabelle (`{ name, at }`) statt einer blanken Zeichenkette – damit ist eine Angabe des Nutzers dauerhaft von einer Vermutung unterscheidbar. `rosterNameOverridesLegacy` steht in `GUILD_KEYS` und wird bei `/wc access reset` mit gelöscht
- Beide Hälften des Kalender-Ablaufs hängen weiterhin an einem echten Klick – die Kette zum Hardware-Ereignis, ohne die es `CreatePlayerEvent`/`EventInvite`/`AddEvent` nicht gibt, bleibt damit intakt. Die Bestätigungszählung dazwischen ist reines Lesen und läuft deshalb im Timer
- Die Einladungsliste wird **vor** dem Speichern gelesen. Danach ist der Entwurf geschlossen, und die Meldung nähme ihre Zahlen genau in dem Moment, in dem sie keine mehr hat

## [2.2.0.0] – 2026-08-19

### Neu
- **Eine WeakAura, die jemand für die Gilde freigegeben hat, taucht hier von selbst auf.** 2.1.0.0 brachte den Weg von der Companion ins eigene WeintCodex; er half genau einer Person – der, die die Aura getippt hat. Seit die WeintCompanion sie zusätzlich in eine gemeinsame Bibliothek beim Discord-Bot stellen kann, holt sie sich jede verknüpfte Companion ab und liefert sie hier ein. Nach dem nächsten `/reload` steht sie in derselben Liste wie die eigenen und die mitgelieferten und wird mit demselben Knopf installiert. Braucht **WeintCompanion 2.2.0**
- **Die Zeile sagt, welche der drei Herkünfte gilt.** Unter dem Namen steht „WeintCodex" (mit dem Addon geliefert), „Companion · <Autor>" (vom eigenen Schreibtisch) oder „Gilde · <Autor>" (jemand hat sie für alle freigegeben) – letzteres in Grün. Der Unterschied ist genau der, den man braucht, wenn die Aura nicht stimmt: bei einer Gildenaura ist jemand dafür ansprechbar
- Die Inspektorspalte zählt beide Quellen getrennt („aus der Companion", „aus der Gilde"), sobald es etwas zu zählen gibt

### Technisch
- Getragen wird die Herkunft vom optionalen Feld `scope` der Nachricht `weakaura_library`. **Fehlt es, gilt „vom eigenen Schreibtisch"** – eine ältere Companion schickt es nicht, und ohne diese Annahme trüge nach einem Addon-Update schlagartig jede Aura die falsche Herkunft. In die andere Richtung gilt dasselbe: ein älteres Addon liest das Feld nicht und verhält sich unverändert
- `WeintCodex.WeakAuras.Catalog()` meldet als `origin` jetzt auch `guild`. Die Companion vergleicht dafür ausdrücklich auf `addon` statt „alles außer companion" – sonst zählte eine Gildenaura dort als mitgeliefert
- Das Addon spricht weiterhin **nicht** mit dem Bot. Eigene und Gildenauren mischt die Companion und stellt sie als *eine* Liste zu; der Vertrag steht unverändert in `docs/weakaura-bridge.md` drüben

## [2.1.0.0] – 2026-08-18

### Neu
- **WeakAuras lassen sich jetzt über die WeintCompanion nachtragen – ohne Addon-Update.** Bis hierher gab es genau einen Weg, eine Aura in WeintCodex zu bekommen: eine Lua-Datei unter `data/weakauras/` anlegen, sie in die `.toc` eintragen, eine Version schneiden, ein Release veröffentlichen und warten, bis alle es installiert haben. Für eine Aura, die zum nächsten Mittwoch gebraucht wird, ist das kein Weg. In der Companion gibt es dafür jetzt den Bereich **WeakAuras**: Name, Rubrik, Version, Beschreibung und der Export-String aus WeakAuras werden eingetragen, ein Klick auf *Fertig* legt die Aura ab – und nach dem nächsten `/reload` steht sie ingame in derselben Liste wie die mitgelieferten und wird mit demselben Knopf installiert. Braucht **WeintCompanion 2.1.0**
- **Auch eine vorhandene Aura lässt sich ersetzen, mitgelieferte eingeschlossen.** Beim Zusammenführen der beiden Quellen gewinnt die zugestellte Fassung bei gleicher Kennung. Genau darin besteht das Aktualisieren: ohne diese Regel stünde die Aura zweimal in der Liste, und niemand wüsste, welche der beiden gilt. Ein zugestellter Eintrag ohne eigenes Symbol übernimmt das der Aura, die er ersetzt – eine aktualisierte Zeile soll nicht plötzlich anders aussehen
- **Jede Zeile sagt, woher sie kommt.** Unter dem Namen steht „WeintCodex" oder „Companion · <Autor>". Eine nachgetragene Aura sah sonst genau aus wie eine mitgelieferte, und wer den Import nicht selbst eingetragen hat, konnte nicht wissen, wen er zu fragen hat, wenn sie nicht stimmt

### Geändert
- Das Addon meldet der Companion beim Login, **welche Auren es kennt** (`weakaura_catalog`). Ohne diese Meldung könnte die Companion nur die Auren auflisten, die sie selbst angelegt hat – die mitgelieferten stecken als Lua-Tabellen im Addon-Ordner und sind von aussen nicht zu sehen. Der Importstring ist bewusst **nicht** dabei: das Krieger-Paket allein sind rund 56 kB, und zum Auflisten und Ersetzen braucht ihn niemand. Die Nachricht bleibt wie `character_report` und `character_sheet` auf dem Rechner des Spielers und geht den Bot nichts an
- Eine Rubrik ohne Einträge zeigt jetzt einen Satz statt einer leeren Fläche unter drei Spaltenköpfen. Bis hierher konnte das nicht vorkommen, weil jede Rubrik mitgelieferte Auren hatte; sobald die Companion mitspielt, kann es das

### Technisch
- `WeintCodex.WeakAuras.Entries()` (`modules/weakauras.lua`) ist die eine Stelle, an der die mitgelieferten Auren aus `WeintCodex.WeakAuraData` und die zugestellten aus `SavedData.weakAuraLibrary` zusammenkommen. `EntriesFor(category)` und `Catalog()` lesen ausschliesslich daraus, die Anzeige rechnet also nichts eigenes
- Eine zugestellte Zeile mit unbekannter Rubrik landet unter *Utility* statt zu verschwinden (`NormalizeCategory`) – dieselbe Regel wie in `normalize_category()` der Companion. Unsichtbar wäre der schlechtere Ausgang
- `WeintCodex.Navigation.CurrentTab()` gibt es neu: `activeTab` war eine Dateilokale, ein Modul konnte also nicht erfahren, ob es gerade sichtbar ist
- `SavedData.weakAuraLibrary` steht bewusst **nicht** in `GUILD_KEYS` (`core/access.lua`) und überlebt `/wc access reset` – WeakAuras sind nicht gildenintern, dieselbe Entscheidung wie beim Import-Typ `WA` in `modules/sync.lua`. Der ältere Bot-Import `WCIMPORT:WA:` bleibt unverändert; er trägt nur Metadaten und liegt unter einem eigenen Schlüssel
- Der vollständige Vertrag beider Nachrichten steht in `docs/weakaura-bridge.md` der Companion

## [2.0.1.1] – 2026-08-18

### Behoben
- **Auf den Handgelenken stand „Meisterschaft", verzaubert war „+180 Stärke".** Gemeldet an einem Furor-Krieger: die Zeile trug zusätzlich „ID 4415 abweichend – /wc vz", wurde nur als *OK* gewertet, und empfohlen wurde weiterhin *Außergewöhnliche Stärke* — also genau das, was bereits drauflag. Der Grund war kein Zahlenfehler, sondern die Reihenfolge der Erkennung: bevor irgendeine Größenordnung geprüft wird, fragt der Scan „ist dieser Text der Name einer Verzauberung dieses Slots?" — und der Namensvergleich arbeitet bewusst mit Enthaltensein, damit Client-Präfixe wie „Nebenhand - " nicht stören. Die Handgelenks-Verzauberung heißt in unserer Tabelle schlicht **„Meisterschaft"**, und genau dieses Wort steht auch in der Wertzeile des Gegenstands („+894 Meisterschaft"). Der Gegenstandswert gewann damit auf dem sichersten Rang gegen die echte Verzauberungszeile zwei Zeilen tiefer. **Eine Zeile, die mit „+Zahl" beginnt, wird jetzt nie mehr über ihren Text identifiziert, sondern ausschließlich über ihre Werte.** Dieselbe Falle lauerte bei „Präzision" (Umhang), „Verschwimmen" und „Koloss" — alle vier Namen sind Stat- oder Effektwörter, die in Gegenstandszeilen vorkommen können
- **Hinter jeder Brustrüstung stand ein „(?)".** Die Verzauberung *Glorreiche Werte* nennt keinen einzelnen Wert, sondern „+80 alle Werte" — eine Zeile, die der Parser nicht lesen konnte. Weil eine Zeile mit Zahl, aber ohne lesbaren Wert seit 2.0.0.4 verworfen wird (zu Recht: sie ist unverstanden), fand der Scan auf der Brust überhaupt keine Verzauberungszeile und fiel auf den ungeprüften Datenbankeintrag zurück. Die Zeile wird jetzt gelesen und auf alle fünf Grundwerte verteilt
- **Zwei Handschuh-Verzauberungs-IDs standen falsch in der Datenbank.** Am Live-Client bestätigt: ID 4432 liegt auf Handschuhen mit **+170 Stärke** (stand als Meisterschaft), ID 4430 auf Handschuhen mit **+170 Meisterschaft** (stand als Tempo, und zwar unter *Füße*). Korrekt verzauberte Handschuhe bekamen deshalb „ID 4432 abweichend" zu lesen. Die Empfehlungslisten aller Spezialisierungen sind mitgezogen, ihre Bedeutung bleibt unverändert

### Geändert
- **Sockelempfehlung für Waffen und Furor: der Sockelbonus wird wieder mitgenommen.** Auf Gegenständen mit kleinem Bonus („Sockelbonus: +60 kritischer Trefferwert") riet das Addon zum Umsockeln des Hybridsteins auf einen reinen Kritstein — obwohl die Rechnung dagegen steht. Ein Sockel bringt in MoP entweder 160 Primär- oder 320 Sekundärwert, ein Hybridstein 80 + 160; damit hängt die Entscheidung allein am Verhältnis Krit:Stärke, und erst ab 0,8 gewinnt der reine Stein. Hinterlegt waren 0,80 (Waffen) und 0,82 (Furor) — für Plattennahkampf in MoP deutlich zu hoch, tatsächlich entspricht 320 Krit etwa 160 Stärke. Die Werte liegen jetzt dort, und der Bonus wird gehalten. Betrifft nur die Bewertung, nicht die Empfehlungslisten selbst
- **Schutzkrieger (defensiv): Meisterschaft steht vor Parieren und Ausweichen.** Beim Schutzkrieger ist Meisterschaft *kritischer Block* — sie verdoppelt den Blockwert und wirkt auf jeden geblockten Treffer, während Ausweichen und Parieren abnehmenden Erträgen unterliegen und nur zufällig greifen. Sie stand als schwächster der drei Werte in der Gewichtung, weshalb die Sockelseite in gelben Sockeln einen reinen Ausweichstein empfahl. Empfohlen wird dort jetzt der grüne Meisterschafts-/Ausdauerstein, der beide Werte bringt und den Sockelbonus ebenso hält

### Technisch
- `LooksLikeStatValueLine` in `modules/charakter.lua` ist die neue Trennlinie zwischen den beiden Erkennungswegen des Verzauberungs-Scans: Weg A liest Namen, Weg B liest Zahlen. `EnchantNamesMatch` lehnt Wertzeilen deshalb grundsätzlich ab — die Prüfung greift damit an einer Stelle für alle Aufrufer (Kandidatenbewertung, ID-Korrektur, Empfehlungsabgleich)
- `SM.AllStatsLine` (`modules/stat_match.lua`) erkennt die „alle Werte"-Zeile über eine Markerliste („alle werte", „zu allen werten", „all stats" plus die Client-Globale, falls vorhanden) und verteilt den Wert auf Stärke/Beweglichkeit/Intelligenz/Ausdauer/Willenskraft. Fehlt der Marker, ändert sich nichts — die Erweiterung kann nicht in bestehende Zeilen hineinregieren
- `4434` bleibt als zweite Stärke-ID in `data/enchants.lua` stehen (gleicher Name, gleiche Werte — wie 4422/4424 beim Umhang), damit eine Fundstelle richtig aufgelöst statt als unbekannt gemeldet wird

## [2.0.1.0] – 2026-08-17

### Neu
- **Anmeldungen ohne Charakternamen sind jetzt sichtbar – vor dem Kalender-Eintrag, nicht danach.** Der Bot kannte den echten WoW-Namen eines Mitspielers nur, wenn dieser die Companion verknüpft **und** seine Twinkverwaltung gepflegt hatte. Für alle anderen – Gildenfremde, die die Companion nur bedingt nutzen können, und jeden, der die Twinkverwaltung noch nicht durchgearbeitet hat – schickte er den Discord-Anzeigenamen. Ingame gibt es diesen Namen nicht: `C_Calendar.EventInvite` lief ins Leere, meldete das aber nicht, und die Einladung zählte sogar als erfolgreich mit. Die Lücke fiel damit frühestens am leeren Kalender auf. Der Bot sagt jetzt zu jeder Zeile, woher ihr Name stammt, und das Addon zieht daraus drei Konsequenzen:
  - In der **Anmeldeliste** steht so eine Zeile in gedämpfter Schrift mit Fragezeichen und dem Hinweis „Discord-Name · kein Charakter" statt in Klassenfarbe. Ein Platzhalter sah bisher aus wie ein Charakter
  - Die **Vorschau im Kalender** zählt „21 von 25" statt „25 gesamt" und nennt die Zahl der offenen Zuordnungen. Die Zahl, der man vertraut, stimmt jetzt mit der Zahl der tatsächlichen Einladungen überein
  - Der **Kalender-Eintrag** überspringt diese Zeilen und nennt sie beim Namen, statt eine Einladung abzuschicken, die nie ankommt. Eine sichtbar fehlende Einladung ist besser als eine, die stillschweigend verschwindet
- **Nachtragen geht an zwei Stellen.** Dauerhaft für alle künftigen Raids in Discord mit dem neuen Befehl `/weintcharakter setzen` (Raidleitung; `/weintcharakter liste` zeigt vorab, wer noch offen ist) – oder wie bisher für den eigenen Client über das Stift-Symbol in der Anmeldeliste

### Behoben
- **Die Selbst-Erkennung in der Anmeldeliste gab bei zwei Mitspielern derselben Klasse auf.** Sie setzt den eigenen Charakternamen automatisch ein, wenn genau ein Kandidat der eigenen Klasse übrig bleibt – bei zweien tat sie gar nichts. Steht für einen davon inzwischen ein echter Charaktername fest, kommt er als „ich" nicht mehr in Frage; gewertet werden jetzt nur noch die ungeklärten Zeilen
- **Ein Discord-Anzeigename mit Doppelpunkt, Komma oder Pipe zerlegte die Anmeldeliste.** Diese drei Zeichen sind die Feldtrenner des Importformats, und der Anzeigename wanderte ungeprüft hinein: ein Komma machte aus einer Zeile zwei Spieler, ein Doppelpunkt verschob den Kopf der Nachricht samt Datum und Titel. Behoben auf Bot-Seite, wirkt ohne Addon-Update

### Technisch
- Das WCIMPORT-Format der Raidanmeldung trägt ein sechstes Feld je Spieler: die Herkunft des Namens (`raidlead` / `companion` / `discord`). Bewusst ein neues Feld statt einer Umbelegung des freien Notizfelds – die Änderung ist damit in beide Richtungen additiv: ein älteres Addon liest nur bis Feld fünf und verhält sich unverändert, dieses Addon behandelt ein fehlendes sechstes Feld wie einen echten Charakternamen. Ein Bot-Update allein ändert also nichts, ein Addon-Update allein auch nicht
- `WeintCodex.Raids.IsResolved(p)` ist der eine Ort, an dem „steht hier ein echter Charaktername" beantwortet wird; Anmeldeliste, Kalender-Vorschau und Einladungslauf lesen ihn. Eine manuelle Korrektur über das Stift-Symbol gilt darin als aufgelöst, ein fehlendes Feld ebenfalls

## [2.0.0.4] – 2026-08-17

### Behoben
- **Der Ausrüstungs-Check las weiterhin einen Gegenstandswert als die angelegte Verzauberung.** Gemeldet an zwei Zeilen desselben Charakters: auf Handschuhen, die exakt die empfohlene *Großes Tempo* (+170 Tempo) tragen, stand „+1.201 Meisterschaft"; auf dem Umhang mit *Überragende kritische Trefferwertung* (+180 kritischer Trefferwert) stand „+991 Parieren". Beide Zeilen trugen zusätzlich „ID abweichend – /wc vz" und wurden nur als *OK* statt *Optimal* gewertet, obwohl genau die empfohlene Verzauberung darauflag. Drei Ursachen, die zusammen dieses Bild ergaben:
  - **Die Stat-Schlüsselwörter kannten nur die Langformen** („Tempowertung", „Meisterschaftswertung"). Die Annahme war, dass die Kurzformen des Clients allein am Gegenstand vorkommen und deshalb von selbst aus dem Parser fallen — ein bequemer Filter, der die falsche Hälfte erwischt: der Client schreibt die Verzauberung genauso kurz wie den Gegenstandswert („+170 Tempo"). Unlesbar waren damit **beide** Zeilen, und die Auswahl fiel auf einen Gleichstand zurück, den die obere gewann — die des Gegenstands. Nebenwirkung derselben Lücke: für Sekundärwert-Verzauberungen lieferte der Werteabgleich nie Werte, lief für sie also komplett leer, und auch der Sockelbonus („Sockelbonus: +180 kritischer Trefferwert") wurde nicht erkannt
  - **Die deutsche Tausendergruppierung wurde nicht gelesen.** Aus „+1.201 Meisterschaft" wurde die Zahl 1. Damit sah jeder vierstellige Gegenstandswert aus wie eine Verzauberung, und die Plausibilitätsgrenze, die genau diesen Unterschied prüfen soll, lief ins Leere
  - **Ein Lua-Idiom, das nie tat, was dastand.** Die Einstufung einer unlesbaren Zeile lautete `text:find("%+%d") and nil or 4` — das ergibt in Lua immer 4, weil der mittlere Zweig `nil` ist und deshalb stets das `or` greift. Gemeint war „verwerfen", geschrieben stand „mittlerer Rang für alles"
- **Umgeschmiedete Gegenstandswerte konnten als Verzauberung durchgehen.** „+298 Parieren (Umgeschmiedet aus Waffenkunde)" liegt mit knapp 300 Punkten mitten im plausiblen Bereich einer Verzauberung und war über die Größenordnung nicht auszusortieren. Solche Zeilen nennen ihre Herkunft im Text und werden jetzt daran erkannt
- **Passt keine Tooltip-Zeile zu einem bekannten Eintrag, wird nicht mehr geraten.** Bisher konnte eine beliebige Zeile plausibler Größenordnung als Verzauberung einspringen. Steht in `data/enchants.lua` ein Eintrag zu dieser ID und passt keine Zeile dazu, ist nicht die Datenbank falsch, sondern der Scan gescheitert — dann steht ihr Name da statt einer geratenen Gegenstandszeile
- **Das Changelog-Fenster nach einem Update ließ sich nicht scrollen.** Der Text war ein fester Textblock auf dem Fenster: was nicht hineinpasste, wurde nicht abgeschnitten, sondern lief unten heraus und war unerreichbar. Sichtbar wurde das erst bei einem Sammelupdate über mehrere Versionen — also genau dann, wenn es am meisten zu lesen gibt. Das Fenster wächst jetzt mit dem Text (bis 620 px, damit es auch im kleinsten Hauptfenster vollständig liegt) und scrollt darüber hinaus, per Mausrad oder schlanker Leiste

### Neu
- **`/wc vz zeilen`** gibt zu jedem angelegten Gegenstand jede Tooltipzeile aus, mit Farbe und den daraus gelesenen Werten. Dass eine Gegenstandszeile als Verzauberung gelesen wird, war von außen bisher nicht zu klären: welche Zeilen der Client überhaupt schreibt und was der Parser aus ihnen macht, stand in keiner Ausgabe. `/wc vz` bleibt die kurze Fassung zum Melden

### Technisch
- `WeintCodex.CreateScrollArea` reagiert auf das Mausrad. `UIPanelScrollFrameTemplate` bringt in dieser Clientfassung keinen eigenen Radhandler mit; ohne ihn blieb allein das Ziehen des 8 px schmalen Reglers. Gilt für alle sieben Bildlauffelder des Addons, nicht nur für das Changelog-Popup

## [2.0.0.3] – 2026-08-17

### Behoben
- **Eine korrekt verzauberte Rüstung wurde als „nicht ideal" gemeldet, wenn ihre Verzauberungs-ID in `data/enchants.lua` falsch stand.** Die Bewertung kannte bis hierher genau zwei Fragen: steht die ID in der Empfehlungsliste, und heißt die Verzauberung so wie eine Empfehlung. Beides sind Angaben aus einer von Hand gepflegten Tabelle – MoP-Verzauberungs-IDs lassen sich am Client nicht ableiten, mehrere Einträge tragen bis heute einen `verify`-Marker, und Blizzard hat die deutschen Bezeichnungen seit MoP-Release mehrfach geändert. Eine falsche Zeile in dieser Tabelle reichte damit aus, damit das Addon einen Mangel behauptet, den es nicht gibt. Neu ist deshalb ein dritter Weg, der ohne Tabelle auskommt: **der Werteabgleich.** Gefragt wird nicht mehr „wie heißt das", sondern „welche Werte bringt das" – und ob das dieselben sind wie bei der Empfehlung. Deckungsgleich heißt optimal, unabhängig davon, was unsere Tabelle über die ID denkt
- **Der Tooltip-Scan hielt gelegentlich den Primärwert des Gegenstands selbst für die Verzauberung.** Item-Sekundärwerte zeigt der Client in Kurzform („Kritischer Trefferwert"), die der Scan nicht kennt und deshalb überspringt – die **Primärwerte** aber („Ausdauer", „Beweglichkeit", „Stärke", „Intelligenz") heißen auf dem Gegenstand genauso wie in einer Verzauberung. Der Scan nahm die erste grüne Zeile, deren Statschlüssel zum Datenbankeintrag passten, und das war auf einem Stärke-Teil mit Stärke-Verzauberung die Item-Zeile weiter oben. In der Liste stand dann „+1300 Stärke" als Verzauberung, dazu die Chat-Warnung, die ID passe nicht zur Datenbank. Die Kandidatenzeilen werden jetzt gewichtet – Namenstreffer vor Wertetreffer vor bloßer Überschneidung – und die echte Verzauberung gewinnt
- **Steine ohne Eintrag in `data/gem_stats.lua` waren ein blinder Fleck.** Sie landeten unbesehen auf „ok (unbekannt)", zählten nicht gegen die Caps und flossen nicht in die Sockelbonus-Entscheidung ein. Fehlt ein Stein jetzt in der Datendatei, holt das Addon seine Werte beim Spielclient (`GetItemStats`, lokalisierungsfrei; ersatzweise der Tooltip). Eine Lücke in der Datei ist damit nur noch eine fehlende Zeile Dokumentation, kein fehlendes Urteil
- **Eine veraltete Zahl in `data/enchants.lua` machte die Verzauberung „unbekannt".** Die Zuordnung über Slot und Werte verlangte den Wert auf die Einheit genau – die Handgelenks-Stärke stand jahrelang als 170 statt der tatsächlichen 180 und war damit wertgenau betrachtet nichts, obwohl Slot und Stat eindeutig auf genau diesen Eintrag zeigten. Es gibt jetzt einen zweiten, toleranten Durchgang; angezeigt und gerechnet wird danach trotzdem mit den Werten aus dem Tooltip, nicht mit unseren

### Neu
- **Verzauberungen mit *mehr* Wert als die Empfehlung zählen als optimal.** Die selbst herstellbaren „Geheimen Inschriften" der Inschriftler tragen dieselben Statschlüssel wie die kaufbare Empfehlung, nur höher. Sie als „nicht ideal" zu melden, war grotesk – bisher rettete sie nur ein Stichwortabgleich auf den Tiernamen („Ochsenhorn"), der ohne Namenszeile im Tooltip ins Leere lief
- **Wertgleiche Steine unter anderer ID gelten als die Empfehlung** – Juwelier-Schliffe, „perfekte" Varianten und die von Blizzard mitten in MoP Classic umbenannten Grundsteine (*Zinnoberonyx → Aragonit*, *Urdiamant → Bergkristall*)
- **Die Zeile sagt, warum sie so eingestuft ist.** Kommt das Urteil aus dem Werteabgleich statt aus einem ID-Treffer, steht der Grund dahinter: *werte-identisch*, *stärkere Stufe*, *schwächere Stufe*. Ein „Optimal" bei einer Verzauberung, die namentlich nicht die Empfehlung ist, wäre sonst genau der nächste Fehlerbericht. „Schwächere Stufe" steht aus demselben Grund auch im Handlungsbedarf, statt des bisherigen „Verzauberung nicht ideal"
- **`/wc vz` nennt zu jeder Verzauberung und jedem Stein die gemessenen Werte** und markiert, wo die Datenbank davon abweicht (`DB: strength=170 -> better`) bzw. wo ein Stein dort ganz fehlt. Das ist die Ausgabe, mit der sich die betroffene Zeile korrigieren lässt

### Technisch
- Neue Datei `modules/stat_match.lua` (`WeintCodex.StatMatch`), lädt vor `modules/charakter.lua`. Sie hält den Werteabgleich (`CompareStats` mit den vier Urteilen `equal`/`better`/`weaker`/`partial`, `SameFamily`, `MatchAgainstList`) und die Statquellen (`EnchantStats`, `GemStats`). Die deutschen Stat-Schlüsselwörter und ihre drei Parser sind aus `modules/charakter.lua` hierher gezogen – zwei Kopien wären genau die Doppelpflege, an der die Erkennung schon einmal gescheitert ist
- **Verglichen wird nie über Wertungen.** Zwei Verzauberungen mit gleicher gewichteter Wertung, aber verschiedenen Stats sind nicht dasselbe: 170 Tempo ist nicht 170 Meisterschaft. Nur deckungsgleiche Statschlüssel zählen als Treffer – sonst würde der Abgleich neue Fehler erzeugen statt alte zu beheben
- Proc-Verzauberungen (Lied des Windes, Jadegeist, DK-Runen) haben bewusst keine Werte; für sie liefert `SM.EnchantStats` `nil`, und der Abgleich hält sich vollständig heraus
- Steine, deren Basisdaten beim Scan noch nicht im Client-Cache lagen, reihen sich in dieselbe Nachlieferungsliste ein wie die Verzauberungen (`GET_ITEM_INFO_RECEIVED`) – ein frisch eingesetzter Stein bliebe sonst bis zum nächsten manuellen Neuaufbau „unbekannt"

## [2.0.0.2] – 2026-08-13

### Behoben
- **Die Navigationsspalte war unbeschriftet.** Jeder Eintrag legte seine Beschriftung an, bekam aber nie einen Text gesetzt – übrig blieb eine Reihe aus zehn Symbolen, also genau die Leiste, die 2.0 ablösen sollte. Die Spalte schreibt jetzt aus, was sie öffnet: *Übersicht, Bossguides, Raids, Kalender, WeintTV, Charakter, Academy, Materialien, WeakAuras, Import*. Zahl und Statuspunkt am rechten Rand haben ihren Platz behalten, die Beschriftung endet davor
- **„Heute geplant" auf der Startseite zeigte „0/8" und keine Bossnamen** – und blieb auch nach einem Raidabend mit gelegten Bossen dabei. Die Startseite las den Fortschritt selbst aus den SavedVariables, und zwar zweifach falsch: der Zweig ist positionsbasiert (`bosses[<Index>]` mit dem Feld `cleared`), gelesen wurde aber über `pairs()` nach einem Feld `killed`, das es dort nie gab. Die linke Zahl war deshalb immer 0, die rechte die Anzahl der *berührten* Bosse statt der 14 der Instanz, und die Zeilen darunter trugen Encounter-Indizes als Namen. Der Fortschritt kommt jetzt aus `modules/bossguides.lua`, wo Instanz und Bossreihenfolge liegen: „8/14 gelegt" samt den nächsten offenen Bossen mit Namen, und der Lockout wird beim Öffnen der Startseite nachgezogen – auch ohne den Bossguide einmal geöffnet zu haben
- **Die Werte-Summen der Ausrüstung standen als „+18◊◊056"** statt „+18 056". Das schmale Leerzeichen wurde vor dem Umdrehen der Ziffernfolge eingesetzt – `string.reverse` dreht Bytes, nicht Zeichen, und aus den zwei Bytes des Leerzeichens wurde dabei eine ungültige Folge, für die der Client zwei Ersatzkästchen zeichnet. Betroffen war jede so gesetzte Zahl
- **Auf der Charakter-Übersicht verdeckten „Verzauberungen öffnen" und „Sockel öffnen" den Hinweis „Scan bei Itemwechsel"** in derselben Fußzeile. Die Breite der beiden Schaltflächen steht erst nach ihrer Beschriftung fest; sie wird jetzt gegen den Platz gerechnet, und passt der Hinweis nicht daneben, rückt er eine Zeile darunter

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
