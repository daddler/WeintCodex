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

**Gefragt wird erst ab einer Gegenstandsstufe**
(`SavedData.optIn.minIlvl`, ab Werk 520), und nicht bei `PLAYER_LOGIN`
(meldet die Gegenstandsstufe oft noch als 0).

**Was „Nein" heisst, steht in der Frage.** Nicht „das Addon ist aus": `/wc`
öffnet es weiterhin vollständig, `/wc alarm jetzt` eingeschlossen. Nein
heisst: hier wird kein Gespräch angefangen.

`OI.Active()` ist die eine Stelle, an der das beantwortet wird; vier
Flächen lesen sie. **Im Zweifel ja** — ohne Antwort, ohne Namen verhält
sich das Addon wie vor 2.7.2.0, dieselbe Zurückhaltung wie bei `Can()` in
`core/access.lua`.

## Einkaufsliste (`modules/shoppinglist.lua`, seit 2.7.2.0)

**Sie rechnet nichts.** Gelesen wird `WeintCodex.Charakter.Scan()`;
gezählt und zusammengefasst wird hier.

**Was drauf kommt, ist ein Einkauf und kein Befund:** leerer Sockel, ein
Stein mit dem Urteil *falsch* oder *über Cap*, eine fehlende Verzauberung.
Ein Stein mit dem Urteil *ok* steht auf der Sockelseite. Zeilen ohne
Basisdaten (`socketsKnown == false`) kommen nicht drauf.

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
