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

`statweights_test.lua` prüft `modules/statweights.lua`: das Zerlegen einer
Pawn-Zeichenkette, die Skalierung auf die Hausskala, doppelte Schreibweisen
desselben Werts, fremde Schlüssel (die die Skalierung **nicht** verzerren
dürfen), negative Gewichte und die Ablehnungen. Eine fremde Zeichenkette zu
zerlegen ist genau die Sorte Rechnung, die man ausserhalb des Spiels prüfen
können muss — ein Muster, das ein Feld verschluckt, fällt im Spiel erst auf,
wenn jemand mit einer halben Gewichtung rechnet.

```bash
lua5.1 .github/tests/statweights_test.lua .
```
