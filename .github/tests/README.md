# Kopflose Prüfung des Umschmiede-Planers

`reforge_engine_test.lua` stellt `modules/reforge_engine.lua` gegen eine **rohe
Gewalt über alle Kombinationen** einer kleinen Aufstellung. Das ist der Beleg
für den Satz, der über der Datei steht: *der Maßstab ist ReforgeLite.* Ein
Suchlauf, der „ungefähr auch" umschmiedet, ist kein Fortschritt — also wird
nachgewiesen, dass er dasselbe findet wie das vollständige Durchprobieren.

Geprüft werden ausserdem die drei Stellen, an denen ein Fehler Gold kostet oder
den Lauf stehenlässt: die **laufende Nummer** je Paar (alle 56, gegen die Regel
des Clients nachgerechnet), das **Lesen des Umschmiedewerts aus dem Item-Link**
auf beiden Wegen (Zerlegung durch den Client und Rückfall über die
Feldposition), und die **Umwandlung von Waffenkunde in Zaubertreffer**, die auf
beiden Seiten der Rechnung stehen muss.

Alles, was sonst der Client beantwortet, steht im Testlauf als Attrappe. Er
läuft mit einem gewöhnlichen Lua 5.1 und braucht kein Spiel:

```bash
lua5.1 .github/tests/reforge_engine_test.lua .
```

Rückgabewert 0 heisst bestanden. Der Ordner liegt unter `.github/`, weil die
Release-Workflows genau den aus dem Addon-ZIP heraushalten — ein Testlauf
gehört nicht in den Addon-Ordner eines Spielers.

## Sim-Gewichte

`statweights_test.lua` prüft `modules/statweights.lua`. Der Kern ist nicht
„liest es das Format", sondern **liest es dieselben Zahlen in jeder Gestalt**:
Ausgabezeichenkette, bloße Paarliste, kopierte Werte-Tabelle, JSON-Zeile und
deutsch getippt müssen alle dieselbe Gewichtung ergeben. Ein Import, der nur
eine Gestalt versteht, geht kaputt, sobald die Quelle ihre Ausgabe umstellt —
und das merkt niemand ausser dem, der sich wundert, warum seine Gewichtung
zur Hälfte fehlt.

Dazu die Stellen, an denen ein Fehler still bleibt: das Komma zwischen Ziffern
(„Krit 0,68" darf nicht *Krit 0* werden), Zweiwortnamen („Crit Rating"),
fremde Schlüssel, die die Skalierung nicht verzerren dürfen, negative Gewichte
— und strukturell, dass die Datei kein fremdes Addon anfasst.

```bash
lua5.1 .github/tests/statweights_test.lua .
```

## Simmen bereitstellen

`simexport_test.lua` prüft `modules/simexport.lua`. Die Seite tut fast nichts —
und genau deshalb muss ihre Auskunft stimmen: sie behauptet, ob ein zweites
Programm den aktuellen Stand sieht, und **das kann man im Spiel nicht
nachsehen**. Steht dort „aktuell", wo „veraltet" richtig wäre, öffnet die
Companion den Sim mit der Ausrüstung von gestern, und niemand merkt es.

Geprüft werden die vier Zustände, die zu vier verschiedenen Handlungen führen
(kein Addon, abgeschaltet, nichts gemeldet, veraltet), die Suche nach dem
neuesten Export über **alle** AceDB-Profile hinweg, und der Stups an den
fremden Exporter: er darf scheitern, ohne etwas mitzureissen, und gemeldet
wird das *Ergebnis* — hat sich der Zeitstempel bewegt? — und nicht der Versuch.

```bash
lua5.1 .github/tests/simexport_test.lua .
```

## Verzauberungserkennung

`enchant_scan_test.lua` prüft, welche Verzauberung `modules/charakter.lua` auf
einem angelegten Gegenstand erkennt. Dieselbe Fehlerklasse ist dreimal
ausgeliefert worden und nahm jedes Mal denselben Ausgang: eine **Wertzeile des
Gegenstands** stand als Verzauberung da, samt der Marke „(ID … abweichend)" an
einem korrekt verzauberten Teil (2.0.0.3 Handschuhe, 2.0.1.0 Handgelenke,
2.9.0.1 Waffe).

Der Lauf stellt echte Tooltips gegen die Erkennung: die gemeldete Waffe mit
*Windweise*, dieselbe Waffe mit einem absichtlich falsch geschriebenen
Datenbanknamen (**die Erkennung darf nicht an unserer Übersetzung hängen** —
das war der Fehler), Handgelenke mit einer Wertverzauberung zwischen
vierstelligen Gegenstandswerten und einer Umschmiedezeile, die grünen
Beschriftungen des Clients („Benutzen:", „Ausgerüstet:"), und den Fall, in dem
gar keine Verzauberungszeile dasteht — dort wird nichts eingesetzt.

```bash
lua5.1 .github/tests/enchant_scan_test.lua .
```

## QE Live (der Heiler-Weg)

`qelive_test.lua` prüft `modules/qelive.lua` und `data/qelive.lua`. Diese
Dateien **schreiben** ein fremdes Format, und das ist die Sorte Fehler, die
nirgends auffällt: QE Live nimmt einen falsch gebauten Text an, zeigt eine
Ausrüstung, und nur wer nachzählt, sieht, dass drei Teile fehlen. Es gibt
keine Fehlermeldung, an der man das erkennen könnte — dieselbe Fehlerklasse
wie die laufende Nummer des Umschmieders und die Feldnummern in
`core/wowsims_link.py` drüben.

Geprüft wird deshalb gegen **QE Lives eigene Regel** statt gegen unsere
Annahme darüber: dass die Gegenstände ab Zeile neun beginnen (eine Kopfzeile
zu wenig verschluckt den ersten — das führt der Lauf vor, statt es zu
behaupten), dass `gem_id`/`enchant_id` nicht als Gegenstandsnummer gelesen
werden, und dass im ersten Feld einer Zeile keine Nummer stehen darf, weil
es drüben übersprungen wird.

Dazu die Gewichte: skaliert wird mit derselben Rechnung wie eine eingefügte
Sim-Ausgabe, und eine als **Lücke** geführte Zahl darf nicht in den Vorschlag
geraten (beide Priester tragen bei QE Live `haste: 0`, und eine 0 hiesse hier
„egal"). Ein zugestellter Sim-Vorschlag hat Vorrang — er ist zu diesem
Charakter gerechnet, die QE-Zahlen gelten für die Spezialisierung.

Dieselben Zahlen hält `tests/test_qelive.py` in WeintCompanion.

```bash
lua5.1 .github/tests/qelive_test.lua .
```
