# Sim-Gewichte übernehmen (`modules/statweights.lua`, seit 2.7.3.0)

**Ein Sim im Spiel wird es nicht geben, und das ist eine Entscheidung.**
Ein brauchbarer wäre eine eigene Spielsimulation; einer, der nur so
aussieht, wäre schlimmer als keiner. Was ein Sim liefert und was hier
fehlte, sind die **Wertegewichte** — genau die Schnittstelle, mit der das
Addon ohnehin rechnet (Sockel, Verzauberungen, Umschmieden). Quelle:
[wowsims.com/mop](https://www.wowsims.com/mop/).

**Kein fremdes Addon, und im Normalfall auch kein festes Format**
(korrigiert in 2.7.3.1). Der Normalweg liest **Wertepaare**: ein Wertname,
dann eine Zahl. Das ist der robustere Weg, nicht der bequemere — ein
Muster für *ein* Ausgabeformat geht kaputt, sobald jene Seite ihre Ausgabe
umstellt.

Sechs Dinge daran sind nicht Geschmack:

- **Die Datei zerlegt und rechnet, sie zeichnet nicht.**
  `.github/tests/statweights_test.lua` stellt dieselben Zahlen in fünf
  Gestalten gegen den Paarleser, hält eine echte Sim-Ausgabe gegen den
  zweiten Leseweg und prüft strukturell, dass kein fremdes Addon angefasst
  wird.
- **Der Import füllt die Felder, er speichert nicht.** Die Seite wird
  danach ausdrücklich **nicht** neu gezeichnet.
- **Skaliert wird auf „größtes Gewicht = 100"** (die Skala der
  Spec-Profile). **Fremde Schlüssel dürfen dabei nicht mitzählen.**
- **Das Komma wird am ganzen Text entschieden, nicht an der einzelnen
  Stelle** (Tausendertrennzeichen vs. Nachkommastelle).
- **Mehrere Schreibweisen desselben Werts werden nicht addiert**
  (`SpellHitRating` neben `HitRating`) — dieselbe Lehre wie bei den
  `ITEM_MOD`-Schlüsseln in `modules/stat_match.lua`.
- **Was nicht übernommen wurde, wird gesagt** — unbekannte Namen und
  negative Gewichte.

**Seit 2.7.4.0 gibt es einen ZWEITEN Leseweg, und er ist als einziger im
Addon an *ein* fremdes Format gebunden** (`SW.ParseSim`): die
*Suggest-Reforges*-Ausgabe von wowsims.com/mop. Dort stehen **keine
Wertnamen**, nur eine bloße Zahlenreihe — die Position entscheidet.

- **Er muss laut scheitern.** Geprüft wird die **Länge** der Reihe (22
  Werte, 16 abgeleitete), bevor ein einziger Wert übernommen wird —
  dieselbe Fehlerklasse wie die laufende Nummer des Umschmieders.
- **Trägt der Text eine Sim-Ausgabe, wird der Paarleser nicht hilfsweise
  probiert.**
- **Die Positionstabelle ist belegt, nicht abgeschrieben** (Gegenprobe an
  einer echten Ausgabe: Blut-Todesritter, Platz 8 = Waffenkunde-Grenze
  5100 Wertung = 15 % bei 340 Wertung/Prozent, deckt sich mit dem
  Spec-Profil).
- **Grenzen und Klasse werden GEMELDET, nicht angewendet.** Der Vergleich
  liest `CapContext()`, rechnet nichts nach. Die Klasse steht mit in der
  Ausgabe.

**Seit 2.8.0.0 muss niemand mehr etwas kopieren** — WeintCompanion 2.5.0
nimmt die Ausgabe entgegen und schickt sie herüber. Zwei Wege: die
Addon-Brücke (`stat_weights`-Inbox, gelesen bei Login/`/reload`) und
`WCIMPORT:SW:` (wirkt ohne Neuladen). Voller Vertrag:
`../../../WeintCompanion/docs/stat-weights-bridge.md`.

Fünf Regeln (`SavedData.statWeights`):

- **Was ankommt, ist ein VORSCHLAG und keine Einstellung** — füllt Felder,
  wird erst auf Klick wirksam.
- **`seen` je Spec hält fest, was erledigt ist** — übernommen *oder*
  verworfen. Kennung hängt am **Inhalt**.
- **Verwerfen ist eine eigene Handlung**, ohne zu speichern.
- **Von Hand eingefügt wird immer angeboten** (`force`).
- **`SW.ParseTransfer` liegt hier**, nicht in `modules/sync.lua` — das
  Zerlegen einer fremden Zeichenkette muss ohne Spiel prüfbar sein.

**Die angelegten Umschmiedungen der Ausgabe werden bewusst nicht
gelesen.** Ein zweiter, eingelesener Plan neben `modules/reforge_engine.lua`
wäre die Doppelung, an der die Sockelbewertung über fünf Releases
gescheitert ist.

**Eingabefeld ist seit 2.8.0.0 zu sehen** (`InspectorInput`, Form `lines`:
Fläche über die volle Breite, Beschriftung, Hinweis, Knopf darunter). Enter
fügt eine Zeile ein statt auszulösen; ein Klick auf die Fläche setzt den
Cursor hinein; `keepText` lässt den Text beim Neueinlesen stehen.

## Die Ausrüstung an den Sim (`modules/simexport.lua`, seit 2.9.0.0)

Geschrieben vom **WowSimsExporter** (fremdes Addon), gelesen von der
Companion, aus derselben Datei. Dazwischen steht genau eine Tatsache: WoW
schreibt seine SavedVariables nur beim Neuladen und beim Ausloggen.

- **Sie liest ein fremdes Addon — und zwar nur das Datum.** Aus `WSEDB`
  kommen Name und Zeitstempel des letzten Exports, nie sein Inhalt.
- **Der Zeitstempel beim Anmelden ist die eigentliche Auskunft** — in
  diesem Moment ist der Speicher nachweislich dasselbe wie die Festplatte.
- **Der Stups darf scheitern, das Neuladen nicht** (`pcall` um
  `OnCharacterChanged`).
- **Vier Gründe, vier Sätze**: kein Addon, Addon abgeschaltet, nie
  exportiert, exportiert aber noch nicht auf der Festplatte.
- **Der neueste Eintrag wird über alle AceDB-Profile gesucht.**

`/wc simmen prüfen` druckt jede Zwischenzahl aus. Voller Vertrag:
`../../../WeintCompanion/docs/wowsims-exporter-bridge.md`.

## Heiler simmen woanders: QE Live (`data/qelive.lua` + `modules/qelive.lua`,
seit 2.9.1.0)

Für Heiler ist wowsims die falsche Adresse — geplant wird auf
questionablyepic.com/live (QE Live), dessen „Classic" derzeit MoP ist und
alle sechs Heiler führt. *Charakter → Simmen* ist eine Seite mit zwei
Zweigen; `QE.Entry(profileKey)` entscheidet welchen (gefragt wird „führt
QE Live diese Spec", nicht „ist das ein Heiler").

**QE Live gibt keine charakterbezogene Gewichtung heraus** — sein *Top
Gear* antwortet mit einem Ausrüstungssatz, nicht mit Zahlen je Wert; die
Vorgabegewichte im Quelltext sind für jeden Spieler dieselben. Und es gibt
**keine Adresse, die eine Ausrüstung trägt** — der Importtext geht über die
Zwischenablage (`QE.BuildExport`).

**Diese Datei SCHREIBT ein fremdes Format und muss laut scheitern.**
`QE.HEADER_LINES` (8, QE Live überspringt genau die ersten acht Zeilen
fest) steht als benannte Zahl da; `QE.ReadBack` liest den fertigen Text
mit QE Lives eigener Regel zurück und `QE.Export` vergleicht die Zahl der
Gegenstände, bevor der Text herausgeht.

**Die Ausrüstung wird nicht neu gerechnet** — Aufwertungsstufe
(`RE.UpgradeLevel`) und Link-Felder (`RE.LinkParts`) kommen aus
`modules/reforge_engine.lua`.

**Die Rohzahlen stehen in der Datendatei, die Skalierung passiert im
Code** (`SW.Normalize`, dieselbe Rechnung wie bei einer eingefügten
Sim-Ausgabe).

**Eine Null ist dort keine Aussage, sondern eine Lücke** (`gaps`). Beide
Priester führen Tempo mit 0 bei QE Live — eine 0 hiesse bei uns „egal",
worauf der Umschmiede-Planer das Tempo restlos wegschmiedete. Solche Werte
werden **nicht** übernommen; das Feld behält den Wert des Spec-Profils.

**Der Vorschlag entsteht beim Zeichnen von *Priorisierung*, nicht beim
Login** (Spec bei `PLAYER_LOGIN` unzuverlässig). **Ein zugestellter
Sim-Vorschlag gewinnt** über die QE-Zahlen. Kennung hängt am Inhalt *und*
am `stand` der Datendatei.

`WeintCodex_ValidateQELiveData()` ist der Drift-Wächter. `/wc qe prüfen`
druckt jede Zwischenzahl aus.
