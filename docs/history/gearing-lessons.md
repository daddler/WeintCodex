# Gearing: die Fehlerhistorie in einem Bild

Diese Datei ist ein **Index**, keine zweite Fassung — die vollständigen,
mit ihrer Begründung verwobenen Absätze stehen in `../systems/gearing.md`
und werden hier nicht wiederholt. Zweck: einen schnellen Überblick zu
geben, *welche* Fehlerklasse wann auftrat, damit man die passende
Detailstelle in `gearing.md` gezielt aufschlägt, statt die ganze Datei zu
lesen, wenn man nur die Chronik braucht.

## Sockelbewertung: fünf Releases, eine wiederkehrende Ursache

Die tragende Lehre der ganzen Datei: **was der Client beantworten kann,
darf nie geraten werden.** Fünf Releases haben genau diese Regel an
verschiedenen Stellen gelernt, jedes Mal ohne die vorherigen zu
korrigieren:

1. **1.3.3.3 / 2.0.0.3 / 2.0.1.1** — frühe Korrekturen an einzelnen
   gemeldeten Fällen, ohne die gemeinsame Ursache zu erreichen.
2. **2.3.0.1** — Sockelreihenfolge fest verdrahtet (meta → rot → gelb →
   blau → prismatisch) statt vom Tooltip gelesen; reproduzierte später
   genau das Symptom, das sie beheben sollte.
3. **2.5.0.0** — Sockelreihenfolge endlich vom Tooltip des
   Grundgegenstands gelesen, gegen `EMPTY_SOCKET_*` abgeglichen.
4. **2.7.0.0** — drei unabhängige Rechnungen (`EvaluateSocketBonus`,
   `PickGemRecommendation`, `EvaluateGem`) zu einer (`PlanItem`)
   zusammengeführt; gleichzeitig Umschmieden eingeführt und mit Sockeln
   verzahnt (ein `headroom`, nicht zwei Töpfe).
5. **2.9.4.0** — der Spielraum wurde ohne die eigenen Steine gemessen
   (Rückkopplungsschleife behoben, siehe `PlanningHeadroom` in
   `gearing.md`).

Details, Zahlen und die genaue Fehlerkette je Release: `../systems/
gearing.md`, Abschnitt „Sockel: der Client liefert die Fakten".

## Umschmieden: von der ersten Fassung zur fixpunktfähigen Planung

- **2.7.0.0** — Erstversion, ReforgeLite-kompatible dynamische
  Programmierung, BETA.
- **2.7.0.1 / 2.7.0.2** — Koroutine lief dem Umschmieder davon (ein
  Ereignis wurde für einen Auftrag erwartet, kam aber mehrfach); auf
  Item-Link-Bestätigung mit Zeitschranke statt auf Ereigniszahl umgestellt.
- **2.7.1.0 / 2.7.1.1** — Waffenkunde-Umwandlung ergänzt; `_SHORT`-Fehler
  in `ITEM_MOD_MAP` behoben (sechs von acht umschmiedbaren Werten fielen
  vorher lautlos aus jeder Antwort).
- **2.7.5.0** — Plan war kein Fixpunkt (jeder Aufruf konnte eine andere,
  gleich gute Verteilung liefern und kostete erneut Gold); `Value` als
  eine Zielgröße mit Bonus-fürs-Sobleiben eingeführt.
- **3.0.0.0** — Kap-Jagd ohne Ende behoben (`RE.NoteChase`/`ChaseStalled`);
  Handauswahl und Wunschwert als Spielereingaben ergänzt.

Details: `../systems/gearing.md`, Abschnitt „Umschmieden".

## Werteabgleich / Verzauberungserkennung: dreimal derselbe Fehler

**Ein Item-Stat-Wert, als Verzauberung ausgegeben** — identisch in
**2.0.0.3, 2.0.1.0 und 2.9.0.1**, jedes Mal mit derselben sichtbaren Folge
(ein korrekt verzauberter Charakter wird als falsch gemeldet), aus
unterschiedlichen Code-Ursachen (Filterregel verstand nur volle
Statnamen; Rangfolge liess Namenszeilen vor Zahlenzeilen gewinnen;
statlose DB-Einträge fielen fälschlich in den schwächsten Rang).
`.github/tests/enchant_scan_test.lua` ist der Offline-Wächter dagegen.
Details: `../systems/gearing.md`, Abschnitt „Werteabgleich".

## Verzauberungs-IDs: der Namensabgleich hat den Widerspruch zugedeckt

**3.0.0.2** — gemeldet am Verstärker-Schamanen (Stiefel: *Verschwimmen*
mit der Marke „ID 4428 abweichend"; Handschuhe: *Waffenkunde* empfohlen,
wo *Meisterschaft* hingehört). Der Abgleich der ganzen Tabelle gegen die
MoP-Spieldaten fand sieben falsche Einträge — drei davon haben
Empfehlungen für alle 39 Profile verdreht (Stiefel, Handschuhe, Umhang).

Zwei Lehren, die über diesen Fall hinausreichen:

1. **Zwei IDs mit demselben Namen im selben Slot waren nie „die Regel",
   sondern immer ein Symptom.** Alle vier so beschriebenen Paare
   (4422/4424, 4423/4892, 4430/4433, 4432/4434) waren falsch zugeordnete
   IDs. Weil beide Einträge denselben *Namen* trugen, hat der
   Namensabgleich in `ResolveEnchant` den Widerspruch abgefangen — die
   Anzeige stimmte, und genau deshalb ist keiner der drei Fehler je als
   „ID abweichend" aufgefallen. Sichtbar wurden sie nur an der
   Empfehlung: die Liste führte zweimal dasselbe und liess dafür eine
   echte Verzauberung weg. Seit 3.0.0.2 prüft
   `.github/tests/gem_plan_test.lua` auf Doppeleinträge je Slot.
2. **Ein einzelner Nutzerbericht belegt eine ID, widerlegt aber keine.**
   Aus „Handschuhe mit Meisterschaft tragen die 4430" wurde 2.0.1.0 der
   Eintrag 4430 = Meisterschaft — und der spätere Bericht (4433 =
   Meisterschaft, 2.6.0.3) wurde daneben als *zweite* ID eingetragen,
   statt den ersten in Frage zu stellen. Wo zwei Berichte sich
   widersprechen, braucht es eine dritte, vollständige Quelle; für
   Verzauberungen ist das die Verzauberungstabelle der Spieldaten (siehe
   Kopf von `data/enchants.lua`).

## Warum diese Datei existiert

Die Lehre aus den ersten drei Ketten ist dieselbe: **zwei unabhängige
Rechnungen für dieselbe Frage laufen irgendwann auseinander.** Jede
Fehlerklasse oben endete mit derselben Abhilfe — eine einzige Stelle, die
alle Aufrufer teilen (`PlanItem`, `RE.Value`, `RankEnchantCandidate`).
Wer eine neue Rechnung für „welcher Stein/welche Verzauberung/welche
Umschmiedung ist richtig" hinzufügen will, sollte zuerst prüfen, ob eine
der bestehenden Single-Source-of-Truth-Funktionen die Frage nicht schon
beantwortet — siehe `../invariants/data-integrity.md`.
