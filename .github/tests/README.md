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
