# Soll ich dir hier helfen? (`core/optin.lua`, seit 2.7.2.0)

WeintCodex meldet sich von selbst: Ausrüstungs-Alarm, Rotationshelfer,
Umschmieder-Fenster, Einkaufsliste am Auktionshaus. Auf dem Charakter, den
man spielt, ist das der Sinn. Auf einem Zweitcharakter ist es Lärm.

**Gefragt wird nach der Hilfe, nicht nach dem Addon** (korrigiert in
2.7.4.0). Bis dahin lautete die Frage, ob WeintCodex „mitreden" darf —
beschreibt, was das Addon *tut*, nicht was der Spieler *davon hat*.
Gefragt wird deshalb nach der Sache — **Verzauberungen, Sockelsteine,
Umschmieden** —, denn das sind die drei Entscheidungen, bei denen das
Addon von selbst etwas sagt. **Beide Antworten stehen mit ihren Folgen in
der Frage**, Ja wie Nein. Derselbe Wortlaut steht unter *Einstellungen →
Fenster & Ansicht*.

**Die Frage wird gestellt, nicht geraten.** Ob ein Charakter ein Twink
ist, kann das Addon nicht wissen; jede Rateregel läge irgendwann daneben.
Einmal gefragt, Antwort behalten (`SavedData.optIn.chars[<Charakter>]`).

**Geholfen wird erst ab Stufe 90 und ab einer Gegenstandsstufe**
(`OI.Scope()`, seit 3.3.0.2; `SavedData.optIn.minIlvl`, ab Werk 520). Bis
3.3.0.1 waren die beiden Schwellen nur ein Vorbehalt gegen die **Frage**,
und weil eine unbeantwortete Frage hier „ja" heisst, kam dabei das
Gegenteil heraus: **auf jedem Charakter unterhalb der Schwelle wurde nie
gefragt, also galt „ja", also kam die volle ungefragte Hilfe** — der
Ausrüstungs-Alarm verlangte auf einem Twink der Stufe 42 Verzauberungen
für Ausrüstung, die am selben Abend wieder abgelegt ist. Gemeldet wurde
genau das. Dieselbe Rechnung entscheidet deshalb beides; eine zweite
Fassung der Schwelle wäre der Rückfall in denselben Zustand.

**Ein „Ja" überstimmt die Schwellen nicht.** Wer unter Stufe 90 spielt,
bekommt nichts von selbst, auch wenn er die Frage bejaht hat — die
Gegenstandsstufe ist dafür der Regler, die Höchststufe nicht. Sichtbar ist
das: unter dem Schalter steht, was gerade gilt und warum
(`OI.ScopeText()`, dieselbe Zeile in `/wc alarm`, in der Diagnose der
Einkaufsliste und in der Frage selbst).

**Unbekannt ist keine 0.** Eine Gegenstandsstufe von 0 ist eine Aussage
über den Ladezustand — solange sie dasteht, kommt nichts von selbst (der
Grund heisst `pending`; der Ausrüstungs-Alarm sieht über seinen Zeitgeber
ohnehin wieder nach). Kennt der Client die Auskunft überhaupt nicht (die
Funktion fehlt), entfällt die betreffende Schwelle ganz, statt das Addon
stillzulegen. Gefragt wird ausserdem nicht bei `PLAYER_LOGIN` — dort
meldet der Client die Gegenstandsstufe oft noch als 0.

**Was „Nein" heisst, steht in der Frage.** Nicht „das Addon ist aus": `/wc`
öffnet es weiterhin vollständig, `/wc alarm jetzt` eingeschlossen. Nein
heisst: hier wird kein Gespräch angefangen.

`OI.Active()` ist die eine Stelle, an der das beantwortet wird
(Schwellen **und** Antwort); vier Flächen lesen sie. **Im Zweifel ja** —
ohne Antwort, ohne Namen verhält sich das Addon wie vor 2.7.2.0, dieselbe
Zurückhaltung wie bei `Can()` in `core/access.lua`. Daneben steht
`OI.Answer()`: die gespeicherte Antwort **ohne** die Schwellen, mit genau
einem zusätzlichen Leser — dem Schalter auf der Einstellungsseite. Stünde
dort `Active()`, wäre er auf jedem Twink aus, ohne dass jemand ihn
ausgeschaltet hat, und das Anschalten bliebe folgenlos.

Geprüft wird die Schwellenrechnung kopflos in
`.github/tests/optin_test.lua` — im Spiel ist sie nicht nachzuprüfen: „es
kommt keine Meldung" sieht bei einem abgewählten Charakter, einem zu
niedrigen Charakter und einer Ausrüstung ohne Lücke gleich aus.

## Einkaufsliste (`modules/shoppinglist.lua`, seit 2.7.2.0)

**Sie rechnet nichts.** Gelesen wird `WeintCodex.Charakter.Scan()`;
gezählt und zusammengefasst wird hier.

**Was drauf kommt, ist ein Einkauf und kein Befund:** leerer Sockel, ein
Stein mit dem Urteil *falsch* oder *über Cap*, eine fehlende Verzauberung.
Ein Stein mit dem Urteil *ok* steht auf der Sockelseite. Zeilen ohne
Basisdaten (`socketsKnown == false`) kommen nicht drauf.

**Mit einer Ausnahme seit 3.1.0.0: was der Sim tauschen will.** Ein *ok*
ist eine Abwägung — das gilt für **unsere** Wertung. Nennt der Zielzustand
für diesen Sockel einen anderen Stein, ist nichts mehr abzuwägen: die
Entscheidung ist auf dem Desktop gefallen, und was fehlt, ist der Stein.
Seit 3.0.3.1 ist genau das der Status solcher Sockel (`ok`, nicht mehr
`optimal` — siehe `docs/systems/gearing.md`), also käme ohne diese
Ausnahme ein Zielzustand an, den man nirgends einkaufen kann. Die Zeile
erkennt es an `row.fromSim`; `optimal` bleibt draußen (der Zielstein
steckt schon drin, per ID oder als wertgleicher Schliff), `neutral`
ebenfalls.

**Und sie sucht selbst** — der Klick ist das Hardware-Ereignis. **Findet
der Client die Felder nicht, sagt die Zeile das** und nennt den Namen.
Für Verzauberungen wird der Name aus `data/enchants.lua` gesucht (in MoP
handeln Verzauberer über Pergamente, die im AH wie die Verzauberung
heissen).

**Welches Auktionshaus dieser Client führt, wird ihn gefragt** (seit
2.7.3.2). Die Seite hing von 2.7.2.0 bis 2.7.3.1 lautlos fest an
`AuctionFrame` (5.4.8-Client) — Mists Classic hat das überarbeitete
`AuctionHouseFrame`. Drei Regeln:

- **Das Ereignis ist die Auskunft, nicht das Fenster** (`AUCTION_HOUSE_SHOW`
  genügt zum Aufgehen; die Position ist danach eine reine Frage, keine
  Bedingung mehr).
- **Angestossen wird die Suche über das Skript am Suchfeld selbst**
  (`OnEnterPressed`) — die Namen der Suchfunktionen dahinter haben sich
  zwischen den Auktionshäusern geändert, das Feld nicht.
- **Ein Fenster ohne Ankerpunkt zeichnet der Client nicht** — `Build()`
  hat jetzt einen ab Werk, wie das Umschmieder-Fenster.

`/wc einkauf prüfen` ist der Diagnosebefehl.

## Am Sockelfenster (`modules/socketing.lua`, seit 3.1.0.0)

Dieselbe Überlegung wie bei der Einkaufsliste, einen Schritt später:
**die Auskunft gehört an den Ort, an dem gehandelt wird.** Wer vor der
offenen Sockelmaske steht, weiß bei drei Sockeln in einem Teil nicht mehr
auswendig, welcher der beiden ähnlich heißenden Schliffe wohin gehört —
das ist keine Nachlässigkeit, sondern normal.

**Sie rechnet nichts.** Gelesen wird `WeintCodex.Charakter.Scan()`;
dargestellt werden die Zeilen des gerade offenen Platzes, sortiert nach
`socket.index`. Die Reihenfolge ist die ganze Aussage — dieselbe Regel wie
im Zielzustand selbst.

**Welches Teil offen ist, sagt zuerst das Spiel.**
`GetSocketItemInfo()` gibt Name, Symbol und Qualität heraus, aber nicht
den Ausrüstungsplatz. `SocketInventoryItem(slot)` und
`SocketContainerItem(...)` werden deshalb mit `hooksecurefunc` mitgehört —
die erste merkt sich Platz **und Herkunft**, die zweite merkt „Tasche".

**Der Haken fängt aber nicht alle Wege** (Ursache der Meldung „es kommt
kein Fenster", behoben in 3.1.1.0). Er fängt genau die zwei, die durch Lua
führen. Der Weg, den fast jeder geht — Stein aufnehmen, auf das Teil
klicken —, führt nicht durch Lua: der Client öffnet das Fenster selbst,
`SocketInventoryItem` wird nie gerufen. 3.1.0.0 hat daraufhin gar nichts
angezeigt.

**Rückfall über das Teil selbst, aber ohne zu raten.** Der ursprüngliche
Einwand bleibt gültig (Ring 1 und Ring 2 können dasselbe Teil sein), also
wird gezählt statt gesucht:

| Fund | Ergebnis |
|---|---|
| genau ein angelegter Platz mit diesem Namen | der ist es |
| mehrere | über die Steine unterscheiden, die **jetzt** im Fenster stecken (`GetExistingSocketLink`) — und nur, wenn genau einer passt |
| immer noch mehrere | `mehrdeutig`, keine Wahl |
| keiner | `tasche` |

Die Steine im Fenster sind dabei ausdrücklich **nur** ein
Unterscheidungsmerkmal, nie eine Grundlage: während man die Maske füllt,
ändert sich diese Liste, das angelegte Teil aber erst beim Klick auf
*Sockeln*.

**Die Herkunft ist kein Beiwerk.** Meldet der Haken „Tasche", wird gar
nicht erst gesucht — sonst bekäme ein Ring im Beutel die Empfehlung des
gleichnamigen angelegten Rings.

**Gegenprobe statt Vertrauen:** ein gemerkter Platz gilt nur, wenn der
Name aus `GetSocketItemInfo()` zu dem Teil passt, das dort steckt. Sonst
zählt er nicht — eine Empfehlung für das falsche Teil wäre schlimmer als
keine.

**Ein leeres Fenster begründet sich.** In den Fällen `tasche` und
`mehrdeutig` steht statt der Empfehlung ein Satz, warum hier nichts steht.
Das ist keine Ausrede, sondern dieselbe Linie wie `stars == 0`: eine
Anzeige, die im Zweifel gar nicht erscheint, ist von einer kaputten nicht
zu unterscheiden — genau der Weg, auf dem 3.1.0.0 als „geht nicht"
zurückkam. Dieselbe Linie gilt für fehlende Basisdaten: dann steht dort
*„noch nicht geladen"* und nicht *„keine Empfehlung"*. `/wc sockelfenster`
nennt Haken und Ermittlung getrennt, damit sich die beiden Wege
auseinanderhalten lassen.

**Einmal rechnen je geöffnetem Teil.** `SOCKET_INFO_UPDATE` feuert bei
jedem Stein, den man in die Maske legt; ein voller Ausrüstungsscan je
Ereignis wäre an der teuersten Stelle die häufigste Rechnung. Das Ergebnis
wird gemerkt und bei `SOCKET_INFO_CLOSE` bzw. `PLAYER_EQUIPMENT_CHANGED`
verworfen. Das Panel entsteht erst beim ersten Ereignis:
`ItemSocketingFrame` gehört zu `Blizzard_ItemSocketingUI` und wird
nachgeladen — ist es beim allerersten Sockeln noch nicht da, versucht
`Refresh()` es einmal 0,2 s später erneut, statt ausgerechnet die erste
Sockelung stumm zu lassen.

**Die Sockelfarbe steht in jeder Zeile** (`SocketColorLabel` aus
`modules/charakter.lua`, keine zweite Tabelle). Im Fenster liegen die
Sockel nebeneinander und unterscheiden sich nur an ihrer Farbe; „Sockel 2"
allein zwingt zum Abzählen, und dabei verzählt man sich.

**Einsetzen kann das Addon nicht** — das ist eine geschützte Handlung des
Spielers. Die Zeile zeigt den Stein und seinen Tooltip; hineinziehen muss
man ihn selbst, und die Fußzeile sagt das auch.

`/wc sockelfenster` zeigt den Zustand samt gemerktem und bestätigtem
Platz, `/wc sockelfenster an|aus` schaltet um (auch in den Einstellungen).

## Einstellungen (`modules/settings.lua`)

Eigener Navigationspunkt unter *System* (seit 2.6.0.0, auch `/wc
einstellungen`): **jede** Option des Addons als Schalter. **Ein
Slash-Befehl ist die Bedienung für den, der ihn schon kennt** — wer ihn
nicht kennt, erfährt nie, dass es die Einstellung gibt. Alle Befehle
bleiben trotzdem bestehen. Sechs Reiter: *Fenster & Ansicht*,
*Ausrüstungs-Alarm*, *Rotationshelfer*, *Umschmieden* (Beta, ab Werk
**aus**), *Diagnose*, *Zugriff & Daten*.

Vier Regeln:

- **Die Seite hält keinen eigenen Stand.** Jeder Schalter liest/schreibt
  in die SavedData des jeweiligen Moduls — wo eine Einstellung woanders
  schon eine Bedienung hat (Trainerfenster-Schalter, Bossnotizen-
  Spaltenumschalter), ist es derselbe Speicher, und beide Seiten ziehen
  sich gegenseitig nach.
- **Der Navigationseintrag trägt bewusst kein `feature`.**
- **Das Seitengerüst entsteht einmal** (`EnsurePage`), gewechselt wird nur
  der Inhalt.
- **Das zweistufige Zurücksetzen des Zugriffsprofils wird bei jedem
  Neuaufbau entschärft** (`resetArmed`), sonst löscht der erste Klick nach
  einem Reiterwechsel sofort.

`WeintCodex.CreateToggle`/`CreateSlider` liegen in `core/ui.lua`. Die
Navigationsspalte ist bei 676 px von 684 verfügbaren — der nächste Eintrag
passt nicht mehr ohne Bildlauf.

### Fensterverhalten (`SavedData.window`)

`WeintCodex.ApplyWindowBehaviour()` in `core/ui.lua` liest
`SavedData.window.escClose` (Vorgabe an) und `.topmost` (Vorgabe aus).
Vorgabeebene `HIGH`. `UISpecialFrames` trägt **Namen, keine Frames** — der
Eintrag (`WeintCodexMainFrame`) wird per Zeichenkette gesucht und entfernt,
darf nur einmal drinstehen. Beide Schlüssel werden in `core/main.lua`
ausdrücklich über `== nil` vorbelegt, nicht über `or` — sonst ließe sich
`escClose` nie abschalten.
