# Gearing: Sockel, Verzauberungen, Umschmieden, Tempo-Schwellen, BiS

Diese Datei ist **ein** zusammenhängendes System, nicht mehrere: Sockel,
Verzauberungen und Umschmieden rechnen miteinander (siehe eigener Abschnitt
unten), teilen sich einen `headroom`-Spielraum, und dieselbe Klasse von
Fehler (zwei unabhängige Rechnungen für dieselbe Frage) hat jeden Teil davon
schon einmal getroffen. Lies diese Datei komplett, wenn du an Sockeln,
Verzauberungen, Umschmieden, Tempo-Schwellen, BiS-Listen oder der
Steinempfehlung arbeitest.

## Data vs. logic split

`data/` holds static reference tables (`BossData.lua`, `bis.lua`,
`spec_profiles.lua`, `enchants.lua`, `gems.lua`, `gem_stats.lua`,
`breakpoints.lua`, `data/weakauras/*.lua` per class) that `modules/`
consumes. `main.lua` calls `WeintCodex_ValidateSpecData()` and
`WeintCodex_ValidateBiSData()` on login as drift guards — if
`spec_profiles.lua` references an enchant/gem ID that no longer exists in
`enchants.lua`/`gems.lua`, or `bis.lua` references a boss/slot name that
doesn't exist, it warns. Keep IDs and names in these files consistent when
editing gear/spec/BiS data.

`statWeights` in `spec_profiles.lua` looks like decoration and is not: it
decides whether the Sockel page tells a player to keep or break a socket
bonus. A socket gives either 160 primary or 320 secondary, a hybrid 80 +
160, so the decision reduces to one ratio — for plate melee, the pure crit
gem only beats hybrid + bonus once crit is worth **0.8 strength or more per
point**. The warrior DPS profiles carried 0.80/0.82 through 2.0.1.0 and
therefore recommended re-gemming away from a bonus the maths says to keep
(in MoP 320 crit ≈ 160 strength, i.e. ~0.5). A weight is a statement about
the game, not a knob to tune until the list looks right; change one and
re-check the socket-bonus verdicts, not just the ordering.

Denselben Fehler in die andere Richtung trug `MONK_WINDWALKER` bis 2.7.2.0:
Meisterschaft stand auf 55 und damit deutlich unter Krit (68), während die
eigene gelbe Steinliste den Meisterschafts-Stein an erster Stelle führt.
Gemeldet wurde es als „falsche Werte beim Windläufer" — und es war beides,
ein zu niedriges Gewicht und der Widerspruch, den
`WeintCodex_ValidateGemWeights()` genau dafür meldet.

**A weight never overrides a curated list, though.** Several profiles'
weights contradict their own `bestGems`: `HUNTER_MARKSMANSHIP` weighs crit
80 against agility 100, so 320 crit (25,600) outscores 160 agility (16,000)
while its own `prismatic` list says the agility gem. Ranking a candidate
pool purely by weight would therefore tell every hunter to gem crit. Where
the two disagree the **list decides**, and `WeintCodex_ValidateGemWeights()`
reports the contradiction at login rather than letting it quietly decide
anything.

**Through 2.9.2.0 that sentence was true only of the candidate *pool*, not
of the recommendation.** `BestCandidate` was a plain argmax over the
candidates; the list narrowed the set and the weight always decided which
of them won — so `bestGems[socketColor][1]`, which the header of
`data/spec_profiles.lua` calls "was auf einen leeren Sockel dieser Farbe
gehört", carried nothing. Reported on a feral druid who had checked three
sockets by hand: in all three the right answer stood in his own profile
list, and in all three the weight overrode it. The rule now is the one
`PreferredEnchantId` already implemented for enchants — **the first usable
entry wins, and it is only passed over when it scores 0** (at a cap, past a
haste breakpoint, or because the reforge plan supplies the stat anyway).
Two details that are not taste: **each strategy has its own curated list**
(`CandidateList` — MATCH asks `bestGems[socketColor]`, IGNORE asks
`bestGems.prismatic`, which is exactly what a prismatic socket is), because
with only one of them under the rule a single inflated weight could still
overrule the list by way of the strategy choice; and `GemPool` iterates a
fixed key order instead of `pairs`, since two equally good gems are not the
same gem and the choice between them must not depend on how Lua happened to
sort the table. `plan.listed` carries per socket where the pick came from —
the row and `/wc sockel` say it, because "from the list" and "computed"
send you to different files when something looks wrong.

**And `statWeights` are values PER POINT, not rank positions.** A socket
gives either 160 primary or 320 secondary, a hybrid 80 + 160 — so a
secondary weighted above **half** the primary makes every gem *without* the
primary stat beat every gem with it. In MoP 320 secondary ≈ 160 primary,
i.e. ~0.5, the same number the warrior comment above arrives at from the
other side. At the time of writing **all 39 profiles** sit above that line;
only `DRUID_FERAL` has been re-derived (mastery was 90 against agility 100,
and its hit/expertise sat *behind* mastery, which no guide says). That is
deliberately not mass-corrected: a weight is a statement about the game,
and thirty-eight of them are not to be guessed in one pass. For the
*recommendation* the curated list now absorbs it; for the **verdict on an
equipped gem** it does not — an inflated secondary still leaves a correct
gem reading "nur ok". `.github/tests/gem_plan_test.lua` pins the reported
case, both causes separately, and the cap counter-check.

## Der Zielzustand aus dem Sim (`modules/targetgear.lua`, seit 3.0.2.0)

**Alles unter dieser Überschrift ist die Antwort auf eine Frage, die
dieses Addon zweimal beantwortet hat.** Aus `statWeights` und den
kuratierten Listen leitet es ab, welcher Stein in welchen Sockel gehört
und was wohin umgeschmiedet wird — eine vollständige Optimierung neben
der, die im Sim längst gelaufen ist. Die gemeldeten Fehlgriffe bei
Steinen sind fast alle von dieser Sorte: nicht „die Rechnung ist
falsch", sondern *es wird überhaupt gerechnet*. Die halbe Datei über
dieser Zeile ist die Geschichte davon.

Seit 3.0.2.0 gilt deshalb, wo ein Sim-Ergebnis vorliegt:

> **wowsims trifft die Optimierungsentscheidung. WeintCodex
> interpretiert sie, vergleicht sie mit dem Iststand und stellt sie
> verständlich dar.**

Der volle Wire-Vertrag (drei Gestalten, Feldbedeutungen, Zuordnung über
`SLOT_IDS`, die 0-Regel) steht drüben und ist dort autoritativ:
`../WeintCompanion/docs/target-gear-bridge.md`. Hier steht nur, was in
*diesem* Repo daran hängt.

### Die Rangfolge, und sie gilt in genau dieser Richtung

```
1. Handauswahl des Spielers   (nur Umschmieden, RE.SetManual)
2. Zielzustand aus dem Sim    (modules/targetgear.lua)
3. eigene Rechnung            (PlanItem / der Umschmiede-Suchlauf)
```

Die Handauswahl steht **vor** dem Sim, und das ist keine Inkonsequenz:
wer im Umschmiede-Fenster „hier will ich Meisterschaft" gesagt hat, hat
das *nach* dem Simmen gesagt und weiss an dieser Stelle mehr — dieselbe
Begründung, aus der sie auch den Suchlauf schlägt. Bei den Sockeln gibt
es keine Handauswahl; dort ist der Sim die oberste Instanz.

**Verglichen wird nie, wer „besser" ist.** Ein Gewicht gegen ein
Sim-Ergebnis zu stellen hiesse, dem Gewicht das letzte Wort zu geben —
und die Gewichte sind der Grund, aus dem hier überhaupt jemals falsch
geraten wurde (siehe der ganze Anfang dieser Datei).

### Wo es eingreift — und wo ausdrücklich nicht

- **`PlanItem` bekommt einen eigenen Zweig**, vor den beiden Strategien
  MATCH und IGNORE. Liegt für **genau diesen** Gegenstand ein
  Zielzustand vor, sind `plan.gems` die Zielsteine, `plan.listed[i]` ist
  `"sim"`, und `plan.source` ist `"sim"`. Kein zweiter Planer daneben:
  es wechselt die **Quelle** der Empfehlung, nicht die Stelle, an der
  sie entsteht. Empfehlung, Steinurteil (`EvaluateGem`) und Bonuszeile
  lesen weiterhin alle aus demselben `plan` und können sich deshalb
  nach wie vor nicht widersprechen.
- **Gerechnet wird trotzdem zweierlei**, und beides beschreibt die
  Empfehlung, statt sie zu ändern: die **Wertung** je Stein
  (`plan.value`, daran misst `EvaluateGem` den angelegten Stein — ohne
  sie stünde überall „0 %") und der **Spielraum** (`plan.room`; die
  nächsten Slots müssen mit dem rechnen, was der Sim hier schon
  verbraucht).
- **`plan.match` wird aus den Farben der Zielsteine abgelesen**, nicht
  behauptet: hält der Zielzustand den Sockelbonus? Das ist eine Aussage
  über den **vorgeschlagenen** Zustand; `plan.active` daneben bleibt
  das, was der Client über den **angelegten** meldet. Ist eine
  Steinfarbe unbekannt, bleibt `plan.match` `nil` — keine Aussage.
  Sockelboni reisen nicht mit, weil sie im Ergebnis bereits *verrechnet*
  sind: welche Steine der Sim gesetzt hat, sagt implizit, ob er den
  Bonus halten wollte.
- **`ItemOptions` im Umschmiede-Planer** macht die Ziel-Umschmiedung zur
  **einzigen** Möglichkeit des Slots — genau wie eine Handauswahl. Sie
  wird also nicht sofort ausgeführt: der Suchlauf plant um sie herum,
  die Seite zeigt sie, und *Alles umschmieden* führt sie mit aus. Es
  gibt weiterhin genau **einen** Ausführungsweg mit seiner
  Kostenrechnung und seiner Fehlermeldung.
- **Die Plan-Kennung trägt die Ziel-Kennung mit** (`PlanSignature`).
  Ohne sie bliebe nach einer neuen Zustellung der Plan von vorher
  stehen — die Ausrüstung hat sich ja nicht geändert —, und das frische
  Sim-Ergebnis täte sichtbar nichts. Derselbe Fehler, den die eigene
  Priorisierung und die Handauswahl schon hatten.
- **Verzauberungen bleiben, wo sie sind.** Der Zielzustand trägt sie
  mit, das Addon wertet sie **nicht** aus. Die bestehende
  Verzauberungslogik funktioniert; sie zu ersetzen war nicht das
  Problem, und ein Bereich, den man nicht braucht, wird nicht angefasst.

### Der Rückfall ist per Sockel, nicht per Ausrüstung

Zurück auf Stufe 3 fällt genau das, was Stufe 2 nicht abdeckt — **nie
das ganze Teil wegen eines Sockels, nie die ganze Ausrüstung wegen
eines Teils**:

| Fall | Folge |
|---|---|
| Kein Zielzustand für diese Spec | alles wie bisher |
| Ziel gehört einem anderen Charakter | gilt nicht, mit Begründung |
| Anderer Gegenstand im Platz (veraltet) | dieser **Platz** rechnet selbst |
| Ziel nennt diesen Platz nicht | dieser **Platz** rechnet selbst |
| Ziel nennt weniger Sockel als das Teil (Gürtelschnalle) | dieser **Sockel** rechnet selbst |
| 0 an dieser Sockelposition | dieser **Sockel** rechnet selbst |
| Umschmiedung am Teil nicht zulässig | dieser **Platz** rechnet selbst, die Zeile sagt es |
| `/wc ziel aus` | alles wie bisher |

Der Rückfall für einen einzelnen Sockel stellt bewusst die
**IGNORE**-Frage („was ist hier am stärksten") und nicht die
MATCH-Frage: über den Sockelbonus hat der Sim bereits entschieden,
indem er die übrigen Sockel gefüllt hat, und eine zweite Bonus-Abwägung
für einen einzelnen Sockel widerspräche ihr.

**Eine 0 im Ziel ist eine Lücke, keine Aussage.** Sie heisst „der Sim
nennt für diesen Sockel keinen Stein" und ausdrücklich nicht „dieser
Sockel soll leer bleiben" — sie entsteht auch dann, wenn im Sim schlicht
nichts eingestellt war, und daraus eine Empfehlung *nimm deinen Stein
wieder heraus* zu machen wäre der teure Irrtum in der falschen
Richtung. Dieselbe Linie wie `headroom == nil`. Im Draht bleibt sie
trotzdem stehen: dort hält sie die Position.

### Der eingefügte String wird gezeigt, bevor er gilt (seit 3.0.3.0)

Eine Sim-**Gewichtung** wird hingelegt und wirkt erst auf Klick (siehe
`docs/systems/stat-weights-qelive.md`), weil sie für *jede* Ausrüstung
gilt und damit ihren Zusammenhang überlebt: eine, die sich nach einem
Login von selbst geändert hätte, wäre von einem Fehler nicht zu
unterscheiden.

Bis 3.0.2.3 galt ein **Zielzustand** dagegen sofort, mit dieser
Begründung: er wirkt nur dort, wo noch genau das Teil steckt, mit dem
gesimmt wurde, entschieden hat der Spieler schon auf dem Desktop, und
jede betroffene Zeile sagt, woher sie kommt.

**Diese Begründung war nur halb richtig**, und der gemeldete Fall zeigt
wo: sie erklärt, warum nicht gefragt werden muss, ob der Spieler das
*will* — nicht aber, woher er wissen soll, **was** eintrifft. Ein
Import, der „15 Plätze" meldet und danach an sechs davon sichtbar nichts
tut (weil dort inzwischen ein anderes Teil steckt), ist von einem
kaputten Import nicht zu unterscheiden. Genau so wurde er auch gemeldet.

Der Weg über den **Import-Dialog** (`WCIMPORT:TG:` eingefügt) zeigt
deshalb erst ein Fenster: Herkunft, Zählung, und Platz für Platz
angelegt gegen Ziel — inklusive der Plätze, die *nicht* gelten, und dem
Satz, dass Steine von Hand eingesetzt werden müssen. Abgelegt wird
nichts, bis *Übernehmen* geklickt ist; *Abbrechen* lässt den
bestehenden Stand unberührt.

Zwei Dinge daran sind nicht Geschmack:

- **Gefragt wird mit `TG.Compare()`, derselben Rechnung, die `/wc ziel`
  ausgibt.** Zwei Fassungen von „angelegt gegen Ziel" wären zwei
  Gelegenheiten auseinanderzulaufen, und ausgerechnet hier fiele das
  niemandem auf: beide Ausgaben sähen plausibel aus, egal was drinsteht.
- **Das Fenster entscheidet nicht selbst.** Es bekommt einen Rückruf und
  ruft ihn auf Klick auf; abgelegt wird in `modules/sync.lua` über
  `TG.Accept()`. Es gibt weiterhin genau **einen** Weg, auf dem ein Ziel
  in die Ablage kommt.

**Die Zustellung über die Addon-Brücke fragt weiterhin nicht** (Login
bzw. `/reload`, `INBOX_HANDLERS.target_gear`). Dort hat der Spieler den
Knopf gerade auf dem Desktop gedrückt, und ein Modal beim Einloggen
wäre die falsche Stelle für eine Rückfrage.

**Sie zeigt seit 3.2.0.1 aber, was angekommen ist** — ein zweites
Fenster, `TG.ShowArrival()`, informativ statt fragend: keine
*Übernehmen*/*Abbrechen*-Wahl, nur *Verstanden*, denn die Entscheidung
ist längst gefallen. Es teilt sich die Platz-für-Platz-Liste mit dem
Bestätigungsfenster (`FillCompareArea()`, aus `TG.ShowConfirm`
herausgezogen — zwei Fassungen derselben Fuellschleife liefen sonst
auseinander), zeigt zusätzlich die Gewichtung als eigene Zeile, wenn
eine dabei war, und fasst **beide** Auskünfte eines Sim-Laufs in
**einem** Fenster zusammen statt in zweien: `modules/simexport.lua`s
`SE.BeginArrival()`/`SE.EndArrival()` rahmen die ganze Login-
Warteschlange, nicht jede Inbox-Nachricht einzeln.

**Gezeigt wird nur, wenn vorher ein Sim-Lauf offen war**
(`SE.AwaitingFor()` vor dem ersten `NoteArrival()` dieses Logins) —
sonst poppte bei jedem Login mit wartenden Nachrichten ein Fenster auf,
auch für eine Gewichtung von vor drei Tagen, die man längst kennt.
Genau der Knopf *Jetzt neu laden* im Kasten, der nach *Bereitstellen*
erscheint (`docs/systems/wcimport-sync.md`, Abschnitt *Der offene
Sim-Lauf*), ist der Weg, der diesen Zustand herstellt.

Unabhängig vom Weg gilt weiter: **jede betroffene Zeile sagt es** — „so
steht es in deinem Sim-Ergebnis" an der Sockelzeile wie an der
Umschmiede-Zeile. `/wc sockel` nennt die Quelle je Sockel als eine von
dreien: *AUS DEM SIM-ZIEL*, *aus der Profilliste*, *nach Wertung*. Die
drei raten zu Verschiedenem, wenn etwas nicht stimmt — beim ersten sieht
man im Sim nach, beim zweiten in `data/spec_profiles.lua`, beim dritten
in den Gewichten.

### Was das Addon über den Zielzustand NICHT weiss

**Ob im Sim wirklich ein Optimierungslauf lief.** Der Sim schreibt
heraus, was gerade eingestellt ist; wer importiert und sofort
exportiert, bekommt seinen Ausgangszustand zurück. Prüfen lässt sich
das nur auf dem Desktop, neben der gemeldeten angelegten Ausrüstung —
und dort geschieht es auch (`compare()` in `core/target_gear.py`
drüben, die Seite sagt „Achtung: das ist Stück für Stück dasselbe, was
du gerade trägst"). Im Spiel gibt es diese Auskunft nicht: hier ist ein
Zielzustand ein Zielzustand.

**Aus welchem Lauf er stammt, weiss es seit 3.2.0.0 — und ob die
Gewichtung daneben aus demselben stammt.** Beide Einträge tragen die
Kennung des Sim-Laufs (`entry.run`), und `/wc ziel` sagt es, wenn sie
auseinanderfallen: eine Gewichtung von gestern neben einem Zielzustand
von heute sieht im Spiel aus wie ein stimmiges Ergebnis und ist eine
Aussage über zwei verschiedene Ausrüstungen. Ein leeres Feld ist gültig
(jede ältere Companion, jeder von Hand getippte String) und wird nicht
zu einer Behauptung. Voller Vertrag:
`../../../WeintCompanion/docs/sim-run.md`.

`/wc ziel` ist der Befehl dazu, aus demselben Grund wie `/wc sockel`
und `/wc vz zeilen`: ein veraltetes Ziel, ein Ziel für den falschen
Charakter, eine verschobene Sockelfolge, eine Gewichtung aus einem
anderen Lauf und ein Sim, der es wirklich so wollte, sehen von aussen
identisch aus. Er druckt, was geliefert wurde, für wen es gilt, aus
welchem Lauf, und Platz für Platz den Iststand gegen das Ziel.
`.github/tests/targetgear_test.lua` hält die Sockelreihenfolge, den
Meta-Sockel, die Lücke, das veraltete Ziel, Ring 1 gegen Ring 2, die
vier Umschmiede-Fälle und die beiden angehängten Abschnitte fest.

## Sockel: der Client liefert die Fakten, eine Rechnung entscheidet

Everything about socket evaluation is downstream of one rule, learned the
hard way over five releases (1.3.3.3, 2.0.0.3, 2.0.1.1, 2.3.0.1, 2.5.0.0):
**what the client can answer is never derived.** Each of those releases
fixed a reported case without reaching the cause, because two of the inputs
were guesses:

- **Socket order.** `GetItemStats` returns *counts* per colour
  (`EMPTY_SOCKET_RED = 1`), never the item's socket sequence. Through
  2.4.1.2 `ScanItemSockets` counted them in its own fixed order (meta → red
  → yellow → blue → prismatic) and paired gem 1 with the first socket so
  produced — so on any item with two differently coloured sockets, gem and
  socket colour could be swapped. Since 2.3.0.1 *everything* hangs on that
  axis, so it reproduced precisely the symptom 2.3.0.1 was meant to end.
  The order now comes from the tooltip of the **base item** (`item:<id>`,
  no gems/enchant/upgrade — a filled socket shows its gem's stats instead
  of the socket line), matched against the client's own `EMPTY_SOCKET_*`
  constants. `GetItemStats` stays as cross-check and fallback; when they
  disagree the tooltip wins and `/wc sockel` prints both.
- **Whether the bonus is active.** The client draws the
  `ITEM_SOCKET_BONUS` line **green** when it applies and grey when it
  doesn't. `ScanSocketBonus` was already reading that line — just not its
  colour.
- **Gem colour.** `GemColor` asks the client's item subclass *first* and
  our `data/gems.lua` colour only for a cold cache. It was the other way
  round, and the table is provably wrong at least once: 76589 is filed
  `grün` but carries hit + stamina, both blue stats — green is one yellow
  plus one blue. As the first entry of `WARRIOR_PROTECTION.gelb` it
  recommended a blue gem for a yellow socket.

**One calculation per item, not three.** `EvaluateSocketBonus`,
`PickGemRecommendation` and `EvaluateGem` each re-derived "which gem would
we pick", and every fix was another clamp to keep them in sync
(`FirstUncappedGem` was 2.3.0.1's, and it never covered `EvaluateGem`'s own
reference). Two rows on the same page reading "85 %" did not mean the same
thing. `PlanItem` now compares two strategies (MATCH the colours vs. IGNORE
the bonus) once per item; the recommendation, the per-gem verdict and the
bonus line all read from that result and *cannot* disagree. `plan.match` is
our advice, `plan.active` is what the client reports — never state one as
the other.

**Seit 2.7.0.0 speist eine dritte Quelle denselben Spielraum: der
Umschmiede-Plan** — siehe *Sockel, Verzauberungen und Umschmieden rechnen
miteinander* weiter unten. Und jede Empfehlung dieser Seite trägt seither
ihre Begründung an der Zeile.

**Caps are headroom, not a cliff.** `GemValue(stats, weights, headroom)`
counts each stat only up to its cap, so a *Stechender Dioptas* (160 crit +
160 hit) keeps its crit half at the hit cap instead of being discarded
whole. The budget is **consumed** across slots — otherwise every socket is
credited the same remaining distance to the cap and the page recommends
ten hit gems for a gap one closes. Because of this, a colour list no longer
has to "carry to the end": 21 of 39 profiles never did, and at the cap
their blue list scored 0, which made the addon call the socket bonus
worthless on *every* item with a blue socket. Seit 2.6.2.0 speist eine
zweite Quelle denselben Topf — die Tempo-Schwellen, siehe unten; für den
Planer ist das dieselbe Frage und deshalb ausdrücklich **ein** `headroom`
und nicht zwei Rechnungen nebeneinander.

**Und der Spielraum wird ohne die eigenen Steine gemessen — sonst ist der
Plan kein Fixpunkt (seit 2.9.4.0).** Gemeldet als „wenn man das, was
WeintCodex vorschlägt, durchzieht, ist beim nächsten Scan wieder ein
anderer Vorschlag" — teils mit dem Urteil *über Cap* auf genau dem Stein,
den die Seite selbst empfohlen hatte. Die Ursache ist eine **Rückkopplung**
und keine Ungenauigkeit: der Spielraum kam aus der Kampfwertung des
Clients, und die **enthält** die angelegten Steine; geplant wurden die
Sockel aber, als wären sie leer. Damit dreht sich ein Kreis, und jede Runde
davon kostet Steine — leere Sockel 5,0 % / Kap 7,5 % → Spielraum 850 →
Treffersteine; umgesetzt 7,8 % → Spielraum 0 → andere Steine; umgesetzt
5,0 % → Spielraum 850 → wieder Treffersteine. Dieselbe Fehlerklasse, die
der Umschmiede-Planer in 2.7.5.0 hatte, nur dass sie hier nicht Gold
kostet, sondern Vertrauen.

**Aufgelöst wird sie über den Maßstab, nicht über einen Merker.** Ein Bonus
für „so lassen" wäre ein zweites Regelwerk neben der Rechnung; richtig ist,
die Ausgangslage so zu messen, wie der Planer sie annimmt — als Charakter
mit **leeren Sockeln**: `Spielraum = Abstand zum Kap − Überschuss + Beitrag
der angelegten Steine`. Das ist genau die Regel, aus der
`modules/reforge_engine.lua` die angelegten Umschmiedungen aus der
Kampfwertung herausrechnet, bevor er neu plant („alles so lassen" ergibt
exakt wieder den Istwert). Der **aktive Sockelbonus gehört zum Abzug** — ob
er anliegt, entscheidet der Plan (MATCH gegen IGNORE), er ist damit Teil
dessen, was neu vergeben wird —, und ein Gegenstand **ohne Basisdaten zählt
nicht mit**: was der Client nicht gemeldet hat, ist keine 0.

Vier Folgen, und keine ist Geschmack: die Rechnung steht seither an
**einer** Stelle (`PlanningHeadroom`) statt zweimal — `ScanCharacter` und
`DumpSockets` hatten sie je für sich, und damit rechnete ausgerechnet die
Diagnose mit anderen Zahlen als das, was sie erklären soll; `ScanCharacter`
liest die Sockel **einmal vorweg** und verwendet sie in der Schleife
wieder, denn der Abzug muss stehen, bevor der erste Gegenstand geplant
wird, und ein zweiter Durchlauf wäre ein zweiter Tooltip-Scan über die
ganze Ausrüstung; der **Overcap-Pass bleibt am Iststand**, weil „was liegt
an?" die andere Frage ist als „was gehört hinein?" und nur für die zweite
der steinfreie Maßstab der richtige ist; und die Seite **sagt das auch**
(`Rationale`), denn wer den Iststand und einen davon abweichenden
Spielraum nebeneinander sieht, hält das eine für einen Fehler des anderen.
`.github/tests/gem_plan_test.lua` prüft es als **Verhalten** und nicht als
Punktzahl — planen, den Plan wie das Spiel anwenden, neu planen —, und mit
der alten Rechnung fällt der Lauf durch und reproduziert den gemeldeten
Kreis.

**The candidate pool supplements the curated lists, it does not replace
them.** `bestGems[socketColor] ∪ bestGems.prismatic` is the normal
candidate set. Only when there is a bonus to keep does the planner also
draw colour-matching gems from the profile's other lists — that is the way
out when the colour list is exhausted at the cap, and it is the only
reason `orange`/`lila`/`grün` are no longer dead keys (they are *gem*
colours; there are no orange sockets). Without that guard a hunter got an
orange hybrid recommended for a bonus-free red socket, because the
profile's weights rate it above its own curated pick.

**`jcOnly` gems are gated on the profession and capped at two** (the
number lives in `data/professions.lua`). Left in the list unconditionally
they raised the reference value for every other gem by half (480 vs 320),
which is how a perfectly good 320 gem scored "falsch" for someone without
Jewelcrafting.

**Das Kontingent gilt je SOCKEL, und die zweite Listenstelle ist kein
schlechterer Rang (beides korrigiert in 3.0.0.0).** Gemeldet als „ich habe
zwei berufsspezifische Steine angelegt, aber mir wird empfohlen noch zwei
anzulegen — geht aber nicht, sind nur zwei möglich", mit einem Bildschirm,
auf dem drei Schlangenaugen im Plan standen. Zwei Fehler, und sie zeigen in
entgegengesetzte Richtungen:

- **Gezählt wurde je Gegenstand.** `ctx.allowJC` stand für ein ganzes
  Ausrüstungsteil fest und wurde erst *danach* nachgezogen, also konnte ein
  Teil mit zwei Sockeln zwei Schlangenaugen bekommen, obwohl nur noch eines
  übrig war — und `ctx.jcLeft` lief auf −1, ohne dass es irgendwo auffiel.
  Abgezählt wird jetzt in `Run()` je Sockel, **jeder Strategiedurchlauf mit
  seinem eigenen Zähler** (nur die Gewinnerin verbraucht wirklich; nähmen
  sie sich gegenseitig etwas weg, hinge das Ergebnis daran, welche zuerst
  gerechnet hat), und der Rest wird bei 0 geklemmt.
- **Und seit 2.9.3.0 wurde gar keines mehr vorgeschlagen.** In allen 64
  Profileinträgen steht das Schlangenauge an **zweiter** Stelle seiner
  Farbliste. Seit die Liste eine Rangfolge *ist* (siehe `BestCandidate`),
  gewinnt der erste Eintrag, sobald er über 0 liegt — bei einem Primärwert
  also immer. Gemeint war die zweite Stelle aber nie als „schlechter": sie
  ist der Rückfall für alle **ohne** den Beruf. Die Schlangenaugen sind in
  MoP durchweg die doppelte Stufe derselben Farbe (320 statt 160 primär,
  480 statt 320 sekundär) — da ist nichts abzuwägen. `BestCandidate`
  behandelt sie deshalb als **bessere Stufe** und nicht als Rang: die Liste
  entscheidet weiterhin, *welcher Wert* in den Sockel gehört, die
  Berufsstufe wird nur genommen, wenn sie den Listenplatz auch schlägt (am
  Cap ist sie 0 wert, und dann bleibt der gewöhnliche Stein stehen).

Die **Zuteilung folgt der Reihenfolge der Ausrüstungsplätze** — die ersten
Sockel, an denen ein Schlangenauge etwas bringt, bekommen sie. Das ist
ausdrücklich eine Näherung und keine Optimierung über den ganzen Charakter:
innerhalb einer Farbe ist der Gewinn überall derselbe (+160 desselben
Werts) und die Reihenfolge damit bedeutungslos, über zwei Farben hinweg
kann sie danebenliegen. Eine echte Zuteilung bräuchte einen zweiten
Durchlauf über die ganze Ausrüstung.

Die **Zahl gehört an die Zeile** (`plan.jcIndex`, „Schlangenauge 1 von 2")
und in den Detailbereich („Schlangenaugen 2 von 2"). „Begrenzte Zahl" nennt
keinen nächsten Schritt — wer zwei gesetzt hat und einen dritten
vorgeschlagen bekommt, sucht den Fehler bei sich. `.github/tests/gem_plan_test.lua`
prüft **beide** Hälften als Verhalten (mehrere Gegenstände nacheinander mit
demselben Kontext planen und zählen): mit der alten Rechnung meldet der
Lauf „3 von 2" und ein Kontingent von −1, und ohne die zweite Hälfte wäre
„nie mehr als zwei" mit null trivial erfüllt.

**Without item data, nothing is judged.** A cold cache used to leave every
gem of an item standing as a prismatic "Zusatzsockel", measured against the
wrong list, with no redelivery noted and therefore no redraw. Such rows now
say so and fill in by themselves.

**Und die Seite bittet um Rückmeldung (seit 3.0.0.0).** Die
Steinempfehlung ist der Teil dieses Addons, an dem am häufigsten etwas
daneben liegt, und die Ursachen sind fast immer *Daten* und nicht Code: ein
Gewicht im Spec-Profil, eine kuratierte Steinliste, ein Sonderfall bei
Sockelbonus oder Cap. Keine dieser Sorten fällt von hier aus auf — ein
falscher Vorschlag sieht von aussen genauso aus wie ein richtiger, über den
man sich wundert. Der Block hängt an `gemExtras` in `ShowGems` und **nicht**
in `Rationale()`, das sich drei Seiten teilen: nur die Sockelseite trägt
ihn, auf jede Seite geschrieben wäre er Zierrat, den niemand mehr liest. Er
steht *neben* der Begründung und nicht darin, weil wer dort liest gerade
den Verdacht hat, dass etwas nicht stimmt — der einzige Moment, in dem
jemand eine Rückmeldung schreibt. Und er nennt, **was** in eine brauchbare
Meldung gehört (Spec, Slot, vorgeschlagener gegen erwarteten Stein, die
Ausgabe von `/wc sockel`); sonst kommt „die Sockel sind falsch" an, und
damit ist nichts anzufangen.

`/wc sockel` prints the socket sequence with its source, the bonus line
with its colour, both plan variants with their scores and the cap headroom
before and after each item — this class of bug is not diagnosable from
outside without it, the same reason `/wc vz zeilen` and `/wc alarm berufe`
exist. `WeintCodex_ValidateGemWeights()` is the gem-side counterpart to
`WeintCodex_ValidateEnchantWeights()`; its findings are data questions for
a human, not something the code should paper over.

## Tempo-Schwellen (`data/breakpoints.lua`, seit 2.6.2.0)

Bis 2.6.1.1 kannte das Addon genau zwei Grenzen — Trefferwertung und
Waffenkunde. Beide sind **Decken**: darüber ist jeder Punkt nachweislich
wertlos, und `headroom` rechnet damit. Tempo hat keine Decke, sondern eine
**Treppe**, und deshalb konnte der Planer nicht wissen, wann ein
Tempostein nichts mehr bringt. Gemeldet wurde genau das: „es wird immer
noch ein Tempostein vorgeschlagen, obwohl man am Cap ist".

**Die Stufen werden gerechnet, nicht abgeschrieben.** In MoP kürzt Tempo
den Tickabstand, nicht die Laufzeit; damit ist `Ticks = round(Laufzeit ×
(1 + Tempo) / Grundabstand)` und die Stufe für den N-ten Tick liegt fest
bei `(N − 0,5) × Abstand / Laufzeit − 1`. In der Datendatei stehen deshalb
**nur Laufzeit und Grundabstand** je Effekt — zwei Zahlen, die jeder im
Zauberbuch nachsieht. Eine Tabelle abgeschriebener Wertungszahlen („3.043
Tempo") wäre das Gegenteil: sie gilt für eine Ausrüstungsstufe, eine
Buffkombination und einen Guide, und niemand sähe ihr an, ob sie noch
stimmt. `WeintCodex_BreakpointLadder()` erzeugt die ganze Treppe daraus;
`WeintCodex_ValidateBreakpointData()` meldet beim Login, wenn Laufzeit und
Abstand keine ganze Grundtickzahl ergeben.

**Ein Eintrag in dieser Datei ist selbst eine Aussage:** für diese Spec ist
Tempo ein Schwellenwert, und hinter der letzten erreichbaren Stufe gehört
es umgeschmiedet. Für eine Spec, deren Tempo vor allem Zauberzeit und
Ressourcen bringt, wäre dieselbe Aussage falsch — solche Specs stehen
deshalb **nicht** darin, und für sie ändert sich nichts. Eine fehlende Spec
ist kein Versäumnis, sondern die ehrlichere Auskunft (dieselbe Regel wie
bei den Rotationslisten der Tankspecs). Die Laufzeiten tragen `verify =
true`: sie sind am Client nicht geprüft, werden trotzdem benutzt (wie in
`data/enchants.lua`), und `/wc tempo` druckt zu jeder Stufe ihre Herleitung
aus.

**Nicht „welche Stufe ist die richtige", sondern „ist die nächste
überhaupt zu erreichen".** Welche Stufe man anpeilt, hängt an Ausrüstung,
Guide und Raidbuffs — eine hineingeschriebene Wunschzahl wäre genau die
Handpflege, an der `data/enchants.lua` schon zweimal gescheitert ist.
Ausrechnen lässt sich dagegen die **Reichweite**: 40 % eines
Sekundärwerts je Gegenstand (Umschmieden) plus die freien Sockel. Daraus
folgt das Ziel:

- Liegt eine Stufe in Reichweite, ist die **höchste** davon das Ziel —
  Tempo zählt bis dorthin, und der Planer darf Tempo empfehlen. Bewusst
  die höchste und nicht die nächste: geplant wird die ganze Ausrüstung auf
  einmal, und wer nur bis zur nächsten Stufe rechnet, hört nach einem
  einzigen Stein auf.
- Liegt keine mehr drin, ist die zuletzt erreichte Stufe das Ende:
  Spielraum 0, und was darüber liegt, gehört umgeschmiedet. Das ist der
  Fall aus dem Fehlerbericht.
- Ist noch keine Stufe erreicht **und** keine in Reichweite, wird
  **nichts** behauptet — Tempo bleibt ungedeckelt. `headroom == nil` heisst
  „keine Aussage", und dasselbe gilt, wenn der Client den Istwert nicht
  meldet.

Die Reichweite ist absichtlich eine **Obergrenze**: eine zu große lässt die
Stufe als erreichbar gelten und ändert dann gar nichts, eine zu kleine
würde Tempo kappen, das noch etwas bringt. Von zwei Irrtümern ist das der
harmlose.

**Und der Spieler behält das letzte Wort.** Auf *Werteverteilung & Caps*
trägt jede Sprosse einen Knopf *als Ziel*, dazu *Automatisch* und
*Schwellen aus* (`SavedData.statTargets[<Profilschlüssel>]`, neben
`customWeights` und aus demselben Grund nicht in `GUILD_KEYS`). Wer eine
Stufe über einen Schmuckproc erreicht, weiß mehr als diese Rechnung — und
dann sagt die Seite auch „selbst gesetzt" statt „nicht erreichbar"; beides
in einen Satz zu gießen hieße, dem Spieler seine eigene Entscheidung als
Unerreichbarkeit zu verkaufen.

Vier Umsetzungsdetails, die nicht Geschmack sind:

- **Decken und Treppe speisen denselben `headroom`.** Für den Planer ist
  es dieselbe Frage — wieviel Wertung bringt in diesem Stat überhaupt noch
  etwas —, und zwei Rechnungen nebeneinander wären genau die Doppelung, aus
  der Empfehlung und Urteil auseinanderlaufen (die Lehre aus `PlanItem`).
  `/wc sockel` liest beide, sonst rechnete die Diagnose mit anderen Zahlen
  als die Seite.
- **Der Buff-Faktor wird herausgerechnet.** Der Charakterbogen meldet den
  Gesamtwert (inklusive Raidbuffs), die Kampfwertung nur ihren eigenen
  Anteil, und Buffs wirken multiplikativ. Wer den Abstand zur nächsten
  Stufe — einen Gesamtwert — mit der reinen Wertungsumrechnung
  multipliziert, verlangt zu viel Wertung. Der Faktor fällt aus den beiden
  Zahlen heraus, die der Client ohnehin meldet.
- **„Über Cap" und „hinter der Schwelle" sind zwei Texte** (`capKind` an
  der Zeile): über dem Trefferkap ist die Wertung wertlos, hinter der
  letzten erreichbaren Tempo-Stufe bringt sie nur keinen Tick mehr. Ein
  Text für beides wäre für einen der beiden Fälle falsch.
- **Eine Verzauberungsliste wird nur umgereiht, wenn die erste komplett
  ins Leere läuft.** „Etwas weniger wert" ist kein Grund, eine kuratierte
  Liste umzusortieren — dieselbe Regel wie beim Kandidatentopf der Steine.
  Proc-Verzauberungen haben bewusst keine Werte und werden nie verdrängt,
  und das **Urteil** über eine angelegte Verzauberung ändert sich nie: was
  in der Liste steht, bleibt optimal. Nur der Vorschlag wechselt.

**Jeder Cap-Befund nennt das Umschmieden.** Bis 2.6.1.1 endete er mit
„Umsockeln!" — die halbe Antwort und meist die teurere: Wertung über einer
Grenze steht nicht falsch *im* Stein, sie steht im falschen Stat. Die
Texte nennen jetzt die Menge, die daneben liegt, und wohin damit
(`BestReforgeTarget`: der höchstgewichtete Sekundärwert, der nicht selbst
an einer Grenze steht; ohne Kandidaten wird kein Ziel genannt statt eines
erfunden).

`/wc tempo` ist der Befehl dazu, aus demselben Grund wie `/wc sockel` und
`/wc vz zeilen`: eine falsche Laufzeit in der Datendatei, ein stummer
Client, eine zu groß geschätzte Reichweite und ein selbst gesetztes Ziel
sehen von außen identisch aus. Er druckt jede Zwischenzahl — welche
Client-Funktion geantwortet hat, den Anteil aus Wertung, den Buff-Faktor,
die Umschmiede-Reserve und je Stufe ihre Herleitung.

## Umschmieden (`data/reforge.lua` + `data/reforge_scaling.lua` +
`modules/reforge_engine.lua` + `modules/reforge.lua`, seit 2.7.0.0, BETA)

Seit 2.6.2.0 sagt jeder Cap-Befund, *wohin* mit der Wertung, die über
einer Grenze steht. Tun konnte man es nirgends — die Frage „welcher Wert
gehört auf welchem Teil verschoben" beantwortete kein Bildschirm, und die
meisten haben sie in einem zweiten Addon beantwortet. Vier Dateien, strikt
getrennt wie beim Rotationshelfer: `data/reforge.lua` beschreibt, was
feststeht, `data/reforge_scaling.lua` trägt die Spieldaten für die
Aufwertungsstufen, `reforge_engine.lua` rechnet, `reforge.lua` zeichnet
(Unterseite *Charakter → Umschmieden* plus ein freistehendes Fenster beim
Umschmieder).

**Der Maßstab ist ReforgeLite, und das ist eine Vorgabe, keine
Verbeugung.** ReforgeLite liefert seit Cataclysm verlässliche Ergebnisse;
ein zweites Werkzeug, das „ungefähr auch" umschmiedet, ist kein
Fortschritt, sondern ein zweiter Ratgeber, dem man nicht trauen kann. Drei
Dinge folgen daraus:

- **Der Suchlauf ist derselbe** — eine vollständige dynamische
  Programmierung über die beiden Werte, an denen eine Grenze hängt (siehe
  unten), keine gierige Näherung.
- **Die Itemwerte sind exakt** — `data/reforge_scaling.lua` trägt dieselben
  Spieldaten (Budget je Gegenstandsstufe, Statverteilung je Vorlage), aus
  denen ReforgeLite rechnet. Ein Teil auf 4/4 trägt gut 16 % mehr Wertung;
  wer das überschlägt, liegt bei jedem Betrag um denselben Prozentsatz
  daneben.
- **Die Umwandlungen sind vollständig** — Willenskraft als Zaubertreffer,
  **Waffenkunde als Zaubertreffer**, die Sonderfälle des Nebelwirkers und
  die Menschen-Willenskraft. Das sind Spielregeln, keine Feinheiten: ohne
  die Waffenkunde-Umwandlung wäre Waffenkunde für einen Magier ein toter
  Wert, den der Planer wegschmiedet — obwohl sie direkt in sein Trefferkap
  läuft.

Nachgewiesen wird das nicht durch Behauptung: der Testlauf unter
`.github/tests/` (`lua5.1 .github/tests/reforge_engine_test.lua .`, braucht
kein Spiel) stellt den Planer gegen eine **rohe Gewalt über alle
Kombinationen** — inklusive des Falls, in dem sich am Kap erst die zweite
Änderung lohnt und eine gierige Suche davor stehenbleibt —, und er trifft
dasselbe Ergebnis. Geprüft werden dort ausserdem die drei Stellen, an denen
ein Fehler Gold kostet oder den Lauf stehenlässt: die laufende Nummer für
alle 56 Paare, gegen die Regel des Clients von Hand nachgerechnet; das
Lesen des Umschmiedewerts auf beiden Wegen; und die Waffenkunde-Umwandlung,
die auf **beiden** Seiten der Rechnung stehen muss. Der Ordner liegt unter
`.github/`, weil die Release-Workflows genau den aus dem Addon-ZIP heraushalten.

**Die laufende Nummer ist der einzige Fehler dieser Dateien, der Gold
kostet.** `C_Reforge.ReforgeItem` kennt keine Statnamen, sondern nimmt die
Position in der Liste der für *diesen* Gegenstand zulässigen Umschmiedungen
— und die entsteht, indem der Client seine eigene Paartabelle von oben nach
unten durchgeht und jedes Paar mitzählt, dessen Quelle der Gegenstand trägt
und dessen Ziel er nicht trägt. Steht unsere Paartabelle auch nur an einer
Stelle anders herum, schmiedet *Alles umschmieden* etwas anderes, als auf
der Seite steht, und das fällt erst am Ergebnis auf. Sie wird deshalb aus
der Regel **erzeugt** und nicht abgetippt (für jede Quelle jedes Ziel ausser
sich selbst, 8 × 7 = 56, Umschmiedewert `112 + Nummer`). Aus demselben Grund
prüft `WeintCodex_ValidateReforgeData()` beim Login auch, dass die
Statnummern in `data/reforge_scaling.lua` dieselben sind — wären sie
verschoben, bekäme jeder aufgewertete Gegenstand lautlos die Werte eines
anderen Wertes zugeschrieben. Und ist ein Paar für den Gegenstand nicht
zulässig, kommt **keine** Nummer zurück statt der Nummer einer anderen
Umschmiedung.

**Der Suchlauf: erst vollständig, dann nachpoliert.** Alles ausser den
Grenzwerten ist an jedem Gegenstand linear und fällt deshalb in eine
einzige Punktzahl zusammen; nur an einer Grenze ist es das nicht, weil
Wertung über dem Ziel nichts mehr bringt. Genau diese (höchstens zwei)
Achsen bilden den Zustandsraum der dynamischen Programmierung. **Eine
gierige Suche findet hier nachweislich nicht das Optimum:** am Kap lohnt
sich häufig erst die zweite Änderung, und wer Slot für Slot das jeweils
Beste nimmt, bleibt davor stehen. Zwei Achsen reichen — in
`data/spec_profiles.lua` hat keine Spec mehr als zwei Grenzen, und keine
der sieben Specs mit Tempo-Treppe hat mehr als ein Kap daneben. Weil der
Zustandsraum gerastert ist (sonst wäre er zu gross), rechnet danach eine
zweite Stufe mit den **exakten** Summen weiter: erst jeder Slot einzeln,
dann je zwei zusammen. Sie kann nur verbessern und räumt die Rasterreste
weg.

**Ein Pflicht-Kap schlägt die Punktzahl.** Unter dem Trefferkap gehen
Schläge daneben — das ist keine Abwägung. Deshalb trennt `target[stat].require`
die beiden Sorten Ziel: ein Kap aus dem Spec-Profil **muss** erreicht
werden, wenn es irgend geht, auch wenn jede Umschmiedung dorthin Punkte
kostet (der Fall, in dem Krit höher gewichtet ist als Treffer); eine
Tempo-Stufe ist dagegen ein Angebot. Ist das Kap ausser Reichweite, wird es
nicht zum Vorwand, die ganze Ausrüstung in einen wertlosen Wert zu
schmieden — dann zählt wieder die Punktzahl.

**Ein Plan muss ein Fixpunkt sein — sonst kostet er jedes Mal erneut Gold
(seit 2.7.5.0).** Der Umschmieder verlangt seine Gebühr für **jede**
Änderung, auch für eine, die nichts bringt. Bis 2.7.4.0 rechnete der
Planer jeden Plan von Grund auf neu und bevorzugte den Iststand nirgends —
und weil er mit Wertungen arbeitet, die er nur auf ein paar Punkte genau
kennt (Aufwertungsstufe hochgerechnet, Buff-Faktor herausgerechnet, jede
Umschmiedung gerundet), reichte **eine Wertung Abweichung je Teil**, damit
derselbe Charakter beim nächsten Aufruf eine andere, gleich gute
Verteilung bekam. Gemeldet wurde das als „sechs bis zehn Durchläufe sind
normal, mehrere tausend Gold statt drei-, vierhundert bei ReforgeLite". Der
offline nachgestellte Fall: aus 1 Runde / 12 Umschmiedungen wurden **5
Runden / 25 Umschmiedungen**, und eine der Runden verschlechterte die
Verteilung dabei nachweislich (580540 → 580180 Punkte).

Aufgelöst wird das über **eine** Zielgröße statt über eine Sonderregel:
`Value` ist Bewertung **plus** ein Bonus für jedes Teil, das bleiben darf,
und alle drei Stufen messen daran. Zwei Zahlen tragen sie, und beide sind
Aussagen über das Spiel:

- **`CAP_SLACK` (40 Wertung)** — ab wann eine Grenze als erreicht gilt.
  Bei 340 Wertung je Prozent ist das gut ein Zehntel Prozentpunkt
  Trefferchance. Vorher stand dort **ein** Punkt, und weil ein verfehltes
  Pflicht-Kap jede Punktzahl schlägt, hat ein einziger Punkt Rückstand vier
  Teile bewegt. `RE.CapOutlook()` benutzt dieselbe Toleranz — sonst hielte
  die Sockelseite eine Grenze für offen, die der Planer abgehakt hat.
- **`WORTH_RATING` (10 Wertung im höchstgewichteten Wert)** — was eine
  einzelne Umschmiedung mindestens bringen muss. Weniger, als jede echte
  Verbesserung bringt (eine Umschmiedung bewegt 100–400 Wertung), und
  mehr, als das Rauschen der Rundungen je erzeugt.

**Stufe 3 (`DropNotWorthIt`) ist deshalb kein zweites Regelwerk**, sondern
ein letzter Schritt bergauf auf genau dieser Größe: zurückgenommen wird,
wenn `s >= score - worth`, und das ist dieselbe Ungleichung wie „Bonus dazu,
Punktzahl weg". Die **billigste** Änderung geht zuerst und danach wird neu
gefragt — an einem Kap hängen Änderungen voneinander ab, und ein einzelner
Durchgang findet die Reihenfolge nicht. Und **der Suchlauf hängt nicht
mehr an der Reihenfolge von `pairs`**: zwei gleich gute Verteilungen sind
nicht gleich teuer, also darf die Wahl zwischen ihnen nicht davon abhängen,
wie Lua seine Tabelle gerade sortiert hat.

Nachgewiesen wird das nicht durch Behauptung: der Testlauf prüft seit
2.7.5.0 **Verhalten** und nicht nur Punktzahlen — planen, den Plan wie das
Spiel anwenden, neu planen, und das auch mit einer Wertung Abweichung je
Teil. Mit den alten Zahlen schlägt diese Prüfung fehl, mit den neuen steht
sie bei einer Runde. Die rohe Gewalt misst dabei gegen `RE.Value` und
`RE.CAP_SLACK` statt gegen eine eigene Zielgröße: ein Test mit eigener
Regel bestätigt nur sich selbst. Und **nach einem sauberen Lauf ist der
nächste Plan die Probe aufs Exempel** — verlangt er noch Änderungen, steht
das im Chat, statt als nächster Vorschlag zu erscheinen, den man arglos
anklickt.

**Die Jagd auf ein Kap muss ein Ende haben (seit 3.0.0.0).** Gemeldet als
„das Umschmieden ist immer noch zu teuer im Gegensatz zu ReforgeLite". Ein
Pflicht-Kap steht in `CapMisses` **lexikografisch vor** der Bewertung —
richtig, denn unter dem Trefferkap gehen Schläge daneben —, aber damit
kann der Bonus fürs Sobleiben es nie aufwiegen: der Planer bewegt dafür
beliebig viele Teile, beliebig oft. Und er trifft nicht immer, weil er
seine Itemwerte nur so genau kennt, wie die Aufwertungsstufe hochgerechnet
und der Buff-Faktor herausgerechnet ist. Landet der Charakter nach dem
Lauf knapp unter dem Kap, sieht der nächste Plan wieder eine Lücke, bewegt
das nächste Teil, landet wieder daneben — und **jede Runde kostet den
vollen Satz Gebühren**. Offline nachgestellt: bei 40 Wertung Abweichung je
Teil werden aus 1 Runde / 12 Umschmiedungen **9 Runden / 21 Umschmiedungen**.
Genau das ist der Unterschied zu ReforgeLite: dort stimmen die Zahlen auf
den Punkt, und ein zweiter Lauf sagt „nichts zu tun".

**Eine grössere Toleranz löst das nicht, und das ist nachgemessen.** Über
`CAP_SLACK` 40/60/85/120/170 gegen Abweichungen von 40 bis 120 Wertung je
Teil hält jede Toleranz unter ihrem eigenen Wert und keine darüber. Der
Fehler ist nach oben nicht begrenzt, die Toleranz schon — über ihr fängt
sie an, ein echtes Kap zu verfehlen. **Gebremst wird deshalb über den
Fortschritt**, dieselbe Regel wie beim Einladungslauf in
`modules/calendar.lua`: wer auf eine Frist wartet, macht aus „noch nicht
fertig" eine Tatsachenbehauptung; wer auf Fortschritt wartet, hört auf,
wenn keiner mehr kommt. `RE.NoteChase` hält nach einem Lauf den
verbliebenen Abstand je Pflicht-Kap fest; ist er beim nächsten Plan nicht
um mindestens `CAP_SLACK` kleiner geworden, setzt `ChaseStalled` dessen
`require` auf `false` — das Kap zählt weiter zur Bewertung, es schlägt sie
nur nicht mehr, und damit gewinnt der Bonus fürs Sobleiben.

Vier Einzelheiten, und keine ist Geschmack: der Merker liegt in den
**SavedData** (ein `/reload` mitten im Raid darf die Jagd nicht von vorn
beginnen lassen); die Kennung ist eine **Ausrüstungs**-Kennung
(`GearSignature` — welche Teile mit welcher Aufwertungsstufe) und nicht
`Signature()`, denn der Umschmiedewert steht im Item-Link und die
Kampfwertungen ändern sich nach jedem Lauf, eine Kennung daraus wäre nach
genau einem Lauf ungültig und die Bremse träte nie in Kraft; vermerkt wird
**nur nach einem Lauf, den das Addon selbst gefahren hat**, weil ein Plan,
den niemand angeklickt hat, kein Versuch ist; und die Bremse **sagt sich
an** (*Nicht weiter verfolgt* im Detailbereich, mit dem Rückweg `/wc
umschmieden frei`) — ein Kap, das der Planer nicht mehr verfolgt, sieht von
aussen genauso aus wie eines, das er vergessen hat.

**Gerechnet wird in Häppchen.** Ein voller Satz von sechzehn Teilen sind
rund 350 ms; ein Addon, das den Client dafür stehenlässt, ist genau das,
was man abschaltet. Der Lauf ist eine Koroutine, die nach **Zeit** anhält
(8 ms, gemessen an `debugprofilestop`) und nicht nach einer festen
Schrittzahl — die wäre auf einem schnellen Rechner Verschwendung und auf
einem langsamen ein Ruckler. Solange gerechnet wird, sagen Seite und
Fenster genau das; `RE.OnPlanReady` meldet das Ergebnis, und dann zeichnen
sie sich neu.

Vier Regeln, die nicht Geschmack sind:

- **Es gibt weiterhin nur EINE Rechnung für „wieviel bringt dieser Wert
  noch".** Caps und Tempo-Treppe stehen in `modules/charakter.lua`, speisen
  dort den Spielraum der Sockelplanung, und `/wc tempo` druckt ihre
  Herleitung aus. Der Planer rechnet sie **nicht** nach, sondern liest
  `scan.caps`, `scan.breakpoints` und `scan.profile.statWeights` aus
  `WeintCodex.Charakter.Scan()`. Genau hier weicht er von ReforgeLite ab,
  und zwar mit Absicht: dort trägt der Nutzer Gewichte und Kapgrenzen von
  Hand ein, hier stehen sie schon im Spec-Profil und werden bereits von
  zwei anderen Seiten benutzt. Zwei Rechnungen nebeneinander wären genau
  die Doppelung, an der die Sockelbewertung über fünf Releases gescheitert
  ist (siehe `PlanItem`). Aus derselben Regel folgt, dass der Suchlauf
  **keine erfundene Cap-Prämie** braucht: bewertet wird Gewicht mal
  Wertung, aber nur bis zum Ziel.
- **Die Summen kommen vom Charakterbogen, die Einzelbeträge vom
  Gegenstand.** Ausgangspunkt ist die Kampfwertung des Clients, aus der die
  angelegten Umschmiedungen herausgerechnet werden; bewegt wird darauf mit
  den Beträgen aus den Itemdaten. Damit stimmt die Summe immer, und
  „alles so lassen" ergibt exakt wieder den Istwert. **Was der Client
  dabei nicht selbst hineinrechnet, wird hineingerechnet** (seit 2.7.1.0):
  `GetCombatRating(Zaubertreffer)` weiß nichts von der Waffenkunde, die bei
  Zauberspecs in dasselbe Kap läuft — der Suchlauf rechnet die Umwandlung
  aber an jeder Umschmiedung mit. Damit standen zwei Größen nebeneinander,
  die dasselbe messen sollten: eine Ausgangslage *ohne* die vorhandene
  Waffenkunde und Änderungen *mit* ihr, und wer Waffenkunde wegschmiedete,
  verlor Treffer, den die Ausgangslage nie gutgeschrieben hatte. Aufgelöst
  wird das wie in ReforgeLite auf der Seite des Istwerts; das Ziel ist
  „Istwert plus Abstand" und verschiebt sich um denselben Betrag mit, der
  **Abstand** aus `modules/charakter.lua` bleibt also unverändert.
  Willenskraft steht bewusst nicht dabei: wo sie als Zaubertreffer zählt,
  weist der Charakterbogen sie bereits aus, und ein zweites Mal wäre
  doppelt.
- **Itemwerte kommen aus dem Item-Link, hochgerechnet auf die
  Aufwertungsstufe.** `GetItemStats` meldet daraus die Werte des
  Gegenstands selbst — ohne Stein, ohne Verzauberung, ohne die angelegte
  Umschmiedung, aber auch ohne die Aufwertung. Die kommt aus
  `data/reforge_scaling.lua` (Budget × Anteil der Vorlage); nur wenn der
  Gegenstand dort fehlt, bleibt die Budgetkurve 1,15 je 15 Stufen als
  Näherung — und `/wc umschmieden prüfen` sagt je Zeile, welcher der
  beiden Wege benutzt wurde. Zusätzlich wird gegen `GetItemStats("item:<id>")`
  gegengeprüft: melden Link und blanker Grundgegenstand verschiedene
  Wertemengen, stünde die Frage „welche Umschmiedung ist überhaupt
  zulässig" falsch — die Diagnose weist es aus.
- **Der Umschmiedewert wird beim CLIENT erfragt, nicht im Link gesucht**
  (seit 2.7.1.0). Er steht in einem Feld des Item-Links, dessen Position
  sich zwischen Clientständen verschoben hat — und der Client zerlegt Links
  selbst: `GetItemInfoFromHyperlink` liefert die Optionsliste,
  `LinkUtil.SplitLinkOptions` teilt sie auf, der Umschmiedewert ist dort
  das zehnte Feld. Genau diesen Weg geht ReforgeLite seit Jahren, und er
  ist der Grund, warum es diese Fehlerklasse dort nicht gibt. Darunter
  bleiben als Rückfallweg die in 2.7.0.2 eingeführten: die am Tooltip
  gelernte Position dieser Sitzung, dann der Bereich, in dem der Wert bei
  den bekannten Ständen liegt (10…16), und — wenn der Client den
  Gegenstand über `REFORGED` als umgeschmiedet ausweist — der ganze Link,
  wobei nur ein **eindeutiger** Treffer gelernt wird. Gültig ist ein Wert
  nur, wenn er in der Paartabelle steht; das ist die Prüfung, die alle
  Wege teilen. **Warum das tragend ist:** trifft keine Position zu, fällt
  das nirgends auf — das Addon hält dann *jeden* Gegenstand für nicht
  umgeschmiedet, der Plan sieht vernünftig aus, der Umschmieder arbeitet,
  und nur die Bestätigung nach einem Auftrag kommt nie an. Genau daran ist
  der Lauf in 2.7.0.1 beim ersten Gegenstand hängengeblieben. **Und jede
  Antwort wird am Link gemerkt** (`RE.ForgetLinks` wirft den Speicher weg):
  der Link trägt den Umschmiedewert selbst, der Speicher ist damit von
  selbst richtig — und er ist nötig, nicht bequem, denn während eines
  Laufs fragt das Fenster viermal je Sekunde je Zeile nach, und ohne ihn
  hing daran im schlechtesten Fall ein Tooltip-Scan. Gegengeprüft wird an
  der eigenen Zeichenkette des Clients (`REFORGED`). **Diese Gegenprobe
  widerspricht, sie verbietet nicht:** ein Widerspruch steht an der Zeile
  und in der Diagnose, die Zeile bleibt planbar. Was der Umschmieder
  anlegt, hängt an der laufenden Nummer und die allein an den Werten des
  Grundgegenstands — eine falsch gelesene *angelegte* Umschmiedung macht
  die Beträge ungenau, nicht den Auftrag falsch. Und stimmte unsere Lesart
  von `REFORGED` einmal nicht, wäre das Werkzeug auf einen Schlag für
  jeden umgeschmiedeten Gegenstand tot; eine Prüfung, die im Zweifel alles
  abschaltet, ist keine.

**Und der Spieler bestimmt selbst mit (seit 2.10.0.0).** Der Planer
entscheidet nach den Gewichten des Spec-Profils; wer einem Guide folgt,
einen Wert für einen bestimmten Kampf braucht oder schlicht anders spielt,
weiß an dieser Stelle mehr als diese Rechnung. Bis 2.9.4.0 gab es dafür
nur die Sperre, und die kann genau eines: den **Iststand** festhalten.
„Ich will hier Meisterschaft" war damit nur von Hand am Umschmieder zu
haben — und beim nächsten Plan stand es wieder anders da. Zwei Wege, und
sie greifen verschieden weit:

- **Die Handauswahl je Teil** (`SavedData.reforge.manual[slot]`, im Fenster
  unter *Alle Teile*) ist eine **Eingabe in den Plan, kein Weg daran
  vorbei**: `ItemOptions` macht sie zur einzigen Möglichkeit dieses Slots,
  der Suchlauf plant um sie herum, und der bestehende Lauf führt sie mit
  aus. Damit bleibt es bei **einem** Ausführungsweg samt seinem Warten auf
  die Bestätigung, seiner Kostenrechnung und seiner Unterscheidung „nicht
  durchgekommen" gegen „etwas anderes angekommen" — ein zweiter daneben
  hätte all das nachbauen müssen, und die Fehlerklassen dieser Datei
  entstehen genau dort, wo etwas zweimal steht. Nebenbei lässt sie sich
  dadurch auch fernab des Umschmieders setzen. `false` heißt „hier soll
  gar nicht umgeschmiedet werden" und ist von `nil` („keine Handauswahl")
  zu unterscheiden; `RE.SetManual` löscht eine bestehende Sperre, weil
  beide dasselbe meinen und die Sperre den Iststand festhielte. Passt sie
  nicht zu dem Teil, das im Slot liegt, wird sie **ignoriert und an der
  Zeile gemeldet** — sie zu löschen wäre ein Schreiben mitten im Planen,
  und der Spieler sähe nie, dass seine Entscheidung weg ist. Und sie steht
  in `Signature()`: ohne das gäbe `GetPlan` den zwischengespeicherten Plan
  zurück, und die Wahl täte sichtbar nichts (derselbe Fehler, den die
  eigene Priorisierung schon einmal hatte).
- **Der Wunschwert** (`SavedData.statFavor[<Profilschlüssel>]`) rückt einen
  Wert an die erste Stelle. Er ist eine **Gewichtsvorgabe** und liegt
  deshalb in derselben Kette, die „welches Gewicht gilt" beantwortet
  (`ApplyFavor` in `modules/charakter.lua`, letzte Schicht auch über einer
  eigenen Gewichtung) — er wirkt damit auf Steine und Verzauberungen mit,
  und das ist Absicht: ein Wunschwert nur fürs Umschmieden wäre eine
  zweite Gewichtung neben der ersten. **Warum 100 gegen 80 und nicht 100
  gegen 99:** der Suchlauf nimmt eine Umschmiedung nur an, wenn sie über
  `WORTH_RATING` liegt; ausgerechnet braucht der Wunschwert je nach
  bewegter Wertung 3–6 % Vorsprung, damit eine Umschmiedung zu ihm
  überhaupt darüber kommt. Ein Punkt Vorsprung sieht in der Liste nach
  einer Entscheidung aus und bewirkt nichts. Gestaucht werden nur die
  umschmiedbaren Sekundärwerte — ein Primärwert lässt sich nicht
  umschmieden und entscheidet in einem Sockel die Steinwahl mit. Ein Wert,
  den das Profil mit 0 führt, wird **nicht** nach vorn gerückt: das wäre
  eine Aussage über das Spiel, die dieses Addon nicht trifft, und die
  Oberfläche bietet ihn deshalb auch nicht an.

**Ein Bedienelement, das man erst durch Überfahren als solches erkennt,
hat man nie gefunden (korrigiert in 3.0.0.0).** Der Wunschwert stand im
Fenster als blosser Text am rechten Rand — mono 10, gedämpft, ohne Fläche
und ohne Rand —, und das Einzige, was ihn von einer Auskunft trennte, war
der Farbwechsel beim Überfahren. Genau so wurde er gemeldet: man sieht ihn
kaum, und man hält ihn nicht für anklickbar. Man fährt nur über das, wovon
man schon annimmt, dass dort etwas ist. Er ist jetzt ein Feld wie jedes
andere (Fläche, Rahmen, Eckmasken, Chevron, `Eyebrow`-Aufschrift darüber,
Bernstein wenn gesetzt); `Paint(hovered)` ist die **eine** Stelle, an der
gesetzt/leer und überfahren/ruhend dieselbe Fläche färben, und die Breite
bleibt **fest**, damit der Klickpunkt nicht mit dem Inhalt wandert. Dafür
gibt `WeintCodex.DrawBorder` seine vier Kanten seither als Tabelle zurück —
additiv, jeder bestehende Aufrufer ignoriert den Rückgabewert, und wer
einen Rahmen umfärbt, hatte sonst keinen Zugriff darauf.

`RE.Choices(item)` ist dabei die Regel des Clients an **einer** Stelle
(jede Quelle, die der Gegenstand trägt, auf jedes Ziel, das er nicht
trägt): `ItemOptions` rechnet darauf seine Beträge, das Fenster bietet
dieselbe Liste an, `RE.ForgeIndex` zählt in derselben Reihenfolge ab. Der
Testlauf hält die beiden in **beide** Richtungen gegeneinander — böten sie
Verschiedenes an, ließe sich etwas wählen, für das es keine laufende
Nummer gibt, oder schlimmer: die einer anderen Umschmiedung. Das Fenster
hat dafür vier Ansichten (Plan / Alle Teile / Auswahl / Wunschwert) statt
Ausklapplisten: es ist 340 px breit, und eine Liste, die sich mitten darin
aufklappt, schiebt alles darunter weg — beim Umschmieder kostet ein
Fehlklick Gold. Während eines Laufs fallen die Auswahlansichten auf den
Plan zurück, und die Gewichte für die Sortierung kommen aus dem
festgehaltenen `plan.ctx` statt aus `CapContext()`, das über die ganze
Ausrüstung liefe (das Fenster zeichnet sich viermal je Sekunde neu). `/wc
umschmieden frei` ist der Rückweg für alles auf einmal, und `/wc
umschmieden prüfen` druckt Wunschwert und Handauswahlen mit aus — von
aussen sieht ein von Hand gesetzter Slot aus, als hätte der Suchlauf ihn
gewählt.

**Das Werkzeug ist ab Werk AUS** (`SavedData.reforge.options.enabled`,
Schalter unter *Einstellungen → Umschmieden*), und der Hinweis auf den
Entwicklungsstand steht an allen drei Stellen — Einstellung, Seite,
Fenster —, nicht nur an einer. Es gibt Gold aus, und die *Datenlage*
(Spec-Gewichte, Cap-Prozentsätze) ist am laufenden Client nicht geprüft;
ein Beta-Werkzeug, das von selbst mitredet, ist der Grund, warum man
Addons abschaltet. Der Navigationseintrag hängt deshalb in der
Charakter-Seitenleiste und erscheint dort nur, wenn der Schalter an ist:
ein ausgegrauter Reiter verspricht etwas, das nicht da ist. (Er hängt
ausserdem dort und nicht in der Navigationsspalte, weil die bei 676 von
684 px steht — siehe der Kommentar über der `tabs`-Tabelle.)

Dazu drei Umsetzungsdetails: **während eines Laufs wird nicht neu
geplant** (nach jedem Teil ändert sich der Item-Link, und ein Planer, der
mitten im Lauf seine Meinung ändert, schmiedet das nächste Teil anders als
in der Liste, auf die geklickt wurde — die Haken kommen trotzdem aus dem
Link und sind damit der echte Stand); die **Kennung für „neu rechnen"
wird billig gebildet**, aus Links, Sperren, Spec, den acht Kampfwertungen
und den *wirksamen Gewichten samt selbst gesetzten Schwellenzielen*, weil
das Fenster während eines Laufs nach jedem Gegenstand nachfragt — die
Gewichte fehlten bis 2.7.2.0 darin, und deshalb tat die eigene
Priorisierung beim Umschmieden sichtbar nichts: was den Suchlauf steuert,
muss in seiner Kennung stehen, sonst ist der Zwischenspeicher eine Antwort
auf eine andere Frage; und das **Neuzeichnen ist entprellt** (1,5 s), weil
`PLAYER_EQUIPMENT_CHANGED` beim Umsockeln mehrfach feuert und jeder
Seitenaufbau Frames anlegt, die WoW nie wieder freigibt.

Der Lauf selbst ist eine Koroutine, die nach jedem Auftrag anhält — der
Server gibt den Takt vor, dieselbe Bauform wie in ReforgeLite.

**Gewartet wird auf die Bestätigung, aber nie ohne Ausweg** (seit 2.7.0.1,
korrigiert in 2.7.0.2). Der Lauf wartet je Gegenstand darauf, dass der
Item-Link die neue Umschmiedung trägt — höchstens drei Sekunden, dann geht
er weiter. **Eine Wartebedingung, deren Ausbleiben nicht von einem Fehler
zu unterscheiden ist, darf den Lauf nicht anhalten:** kann das Addon die
Bestätigung gar nicht sehen, käme er sonst über den ersten Gegenstand nie
hinaus. Am Ende wird nachgesehen und beim Namen genannt, was nicht
durchgekommen ist. **Jeder Gegenstand bekommt höchstens einen Auftrag je
Lauf** — ein zweiter könnte ein zweites Mal Gold kosten, wenn der erste
doch noch ankommt; wer es erneut versuchen will, klickt erneut.
`RF.runLog` hält fest, was geschickt und was danach gelesen wurde; `/wc
umschmieden prüfen` druckt es samt aller Link-Felder aus.

**Der ursprüngliche Grund (2.7.0.1).** Bis dahin ging der Lauf nach
*jedem* Aufwachen zum nächsten Gegenstand weiter. Das setzt voraus, dass
auf einen Auftrag genau ein Ereignis kommt, und diese Annahme hält nicht:
das Einlegen in den Umschmieder meldet sich ebenso wie das Umschmieden
selbst. Der Lauf lief dem Umschmieder damit davon — und der ist
beschäftigt, solange ein Auftrag läuft, sodass alles, was in dieser Zeit
hereinkommt, auf den Boden fällt. Irgendwann kam gar kein Ereignis mehr,
die Koroutine stand still, und der Knopf hiess bis zum nächsten `/reload`
„Abbrechen". Jetzt wird nach dem Auftrag gewartet, bis der **Item-Link**
die neue Umschmiedung wirklich trägt; ein Ereignis ist nur noch ein Anlass
nachzusehen, und ein eigener Takt (0,25 s) sieht ausserdem von sich aus
nach. Dieselbe Lehre wie beim Kalender-Invite: gewartet wird auf
Fortschritt, nicht auf eine Frist. **Nachgeschickt wird nichts** — ein
zweiter Auftrag für denselben Gegenstand könnte ein zweites Mal Gold
kosten, wenn der erste doch noch ankommt.

**Und der Rückgabewert von `coroutine.resume` wird gelesen.** Ein Fehler
mitten im Lauf liess die Koroutine tot zurück, ohne dass irgendetwas davon
zu sehen war: `forgeCo` blieb gesetzt, der Knopf stand auf „Abbrechen",
und die Zeitschranke war beim Aufwachen bereits entschärft worden. Genau
der stille Rückfallweg, den es hier nicht geben darf — dieselbe Lehre wie
beim Signalton in `modules/gearalert.lua`. Die Zeitschranke wird deshalb
nur noch entschärft, wenn tatsächlich fortgesetzt wird, und sie hängt an
der **Zeit** statt an einer Zahl von Aufwachern (Ereignisse kommen in
Schüben und hätten eine Schrittzahl in Sekundenbruchteilen aufgebraucht).

**Die Zahlen im Fenster kommen aus dem Iststand, nicht aus dem Plan:**
wieviele Teile noch offen sind und was die noch kosten, je Zeile am
Item-Link gefragt — so wie der Haken davor. Die Summe vom Anfang
stehenzulassen war die zweite Hälfte desselben Fehlerberichts. Und ein
Klick, der auf einen noch rechnenden Plan trifft, wird eingelöst, sobald
der steht (solange er frisch ist und der Umschmieder offen steht) — sonst
tut der erste Klick nach einem Abbruch sichtbar nichts. Ein Klick auf eine
Zeile der Seite **sperrt** den Slot (`SavedData.reforge.locked`), für
Ausrüstung, die aus einem Grund so bleiben soll, den diese Rechnung nicht
kennt; gesperrte Slots behalten in jedem Startpunkt ihren Iststand, sonst
hiesse „nicht anfassen" in Wahrheit „zurücksetzen".

**„Nicht durchgekommen" und „etwas anderes angekommen" sind zwei
Antworten** (seit 2.7.1.1), und sie raten zu Verschiedenem: das eine ist
ein zweiter Klick wert, das andere ist ein Fehler in unserer Rechnung und
gehört gemeldet — nachgeschickt wird dort ausdrücklich nichts. Bis dahin
stand beides unter derselben Zeile, und genau deshalb sah der
Schlüsselfehler oben nach einem Zeitproblem aus. Der Lauf vergleicht am
Ende die *angelegte* Umschmiedung mit der geplanten **und** mit der von
vorher; nur wenn sich nichts bewegt hat, ist der Auftrag verschluckt
worden.

`/wc umschmieden prüfen` ist der Befehl dazu, aus demselben Grund wie `/wc
sockel` und `/wc tempo`: eine Empfehlung, die daneben liegt, sieht von
aussen bei einem falsch geratenen Link-Feld, einer verpassten
Aufwertungsstufe, einer fehlenden Umwandlung, einem falschen Gewicht und
einem falsch gelesenen Cap völlig gleich aus. Er druckt jede Zwischenzahl
— gelesene Itemwerte und die des blanken Grundgegenstands, Aufwertungsstufe
mit ihrer Quelle (Tabelle oder Näherung), Umwandlungen, Verstärkungsfaktoren,
die Suchachsen, das gerechnete Ziel je Wert und die laufende Nummer, die
der Umschmieder bekäme.

## Sockel, Verzauberungen und Umschmieden rechnen miteinander (seit
2.7.0.0)

**Umschmieden kostet Gold, ein Sockel ist einmalig.** Ein Sockel lässt
sich einmal vergeben; Umschmieden bewegt 40 % eines Sekundärwerts je
Gegenstand und lässt sich jederzeit zurücknehmen. Wer einen Sockel
benutzt, um ein Kap zu füllen, das das Umschmieden ohnehin füllt,
verschenkt den Sockel — und genau das hat die Sockelseite bis 2.7.0.0
getan. Sie rechnete mit dem Abstand zum Kap, den sie *gerade* sah, und
empfahl deshalb Treffersteine für eine Lücke, die das Umschmieden umsonst
schliesst. Das ist die häufigste Sorte falscher Sockelempfehlung.

**Es bleibt bei EINEM Spielraum.** `headroom` in `ScanCharacter` ist
weiterhin die eine Antwort auf „wieviel bringt dieser Wert noch" — jetzt
nur richtig gemessen: nicht „wieviel fehlt bis zum Kap", sondern „wieviel
fehlt **nach** dem Umschmieden". Ein zweiter Topf neben dem ersten wäre
genau die Doppelung, an der die Sockelbewertung über fünf Releases
gescheitert ist. Aus derselben Quelle speist sich die
Verzauberungsempfehlung (`PreferredEnchantId`), und derselbe Wert begrenzt
den Verschwendungs-Topf des Overcap-Passes: ein Stein über dem Cap gilt
nicht mehr als verschwendet, wenn der Plan den Überschuss ohnehin
verschiebt — er steht dann nicht falsch *im Stein*, er ist der
Ausgangspunkt jener Rechnung.

**Der Kreis wird über den Zuschnitt aufgelöst, nicht über einen Merker.**
`WeintCodex.Charakter.CapContext()` liefert Spec-Profil, Caps und
Tempo-Treppe **ohne** den Ausrüstungs-Scan — das ist alles, was der Planer
braucht. Die Sockelplanung liest umgekehrt `RE.CapOutlook()`. Riefe der
Planer den vollen Scan, riefe der Scan wieder ihn.

`RE.CapOutlook()` kennt drei Zurückhaltungen, und jede ist eine Aussage
über unser Wissen: nur ein **fertiger** Plan zählt (während gerechnet
wird, gibt es keine Auskunft — ein halber Plan ist keine), nur ein Plan
zur **aktuellen** Ausrüstung (Kennungsvergleich; ein Plan von vor drei
Gegenständen beschreibt eine Ausrüstung, die es nicht mehr gibt), und es
wird dabei **nie** gerechnet (die Funktion läuft mitten im Scan). Ist der
Planer aus, kommt `nil` und alles verhält sich wie vor 2.7.0.0.

**Daraus folgt eine Reihenfolge, und sie steht auf der Seite:** erst
umschmieden, dann sockeln. Ohne diesen Satz sieht „Krit" auf einem
Charakter weit unter dem Trefferkap nach Willkür aus. `/wc sockel` druckt
den Ausblick mit aus — sonst rechnete die Diagnose mit anderen Zahlen als
die Seite.

## Jede Empfehlung sagt, warum (seit 2.7.0.0) — und woraus sie folgt (seit
2.7.1.0)

Eine Empfehlung ist das eine, die Begründung das andere. Wer „Glatter
Goldberyll" liest, weiss nicht, ob das an seiner Spec hängt, an einem Kap
oder an einem Sockelbonus — und ohne diese Auskunft bleibt ihm nur, es zu
glauben oder es zu lassen. Beides ist schlecht: geglaubte Empfehlungen
fallen beim ersten Zweifel um, und eine, die man nicht nachvollziehen
kann, ist von einer falschen nicht zu unterscheiden.

- **Die Begründung wird abgelesen, nicht dazuerfunden.** Jeder Halbsatz in
  `ExplainGem` entspricht einer Verzweigung, die in `PlanItem` tatsächlich
  gefallen ist: welcher Wert die Wertung angeführt hat, welcher höher
  gewichtete dabei ausgeschieden ist und warum, wie die
  Sockelbonus-Entscheidung ausgegangen ist. Deshalb entsteht sie **in
  `PlanItem`** und nicht in der Zeichenfunktion — ein Text, der in der
  Anzeige noch einmal hergeleitet wird, ist eine zweite Rechnung, und die
  läuft irgendwann auseinander.
- **„Zählt nicht mehr" hat drei Gründe und drei Texte** (`BlockedReason`):
  *Grenze erreicht*, *hinter der Tempo-Schwelle*, *das erledigt das
  Umschmieden*. Ein Text für alle drei wäre für zwei davon falsch.
- **Zwei Fragen, zwei Begründungen:** warum diese Empfehlung
  (`recReason`), und was am angelegten Stein ist (`reason`). „Bringt 72 %
  der Wertung des empfohlenen Steins" ist ein Befund; „Tempo zählt hier
  nicht mehr — die Wertung liegt brach" ist eine Auskunft.
- **Sie steht in der Zeile, nicht im Tooltip.** Ein Tooltip ist der Ort
  für Einzelheiten, die man nachschlägt; die Frage „warum dieser Stein"
  hat man dagegen genau dann, wenn man die Zeile liest — und wer erst
  darauf zeigen muss, kommt gar nicht auf die Idee, dass es eine Antwort
  gibt.
- Für die Begründungen gilt die **Kurzform** der Statnamen (`StatShort`,
  aus `data/reforge.lua`): „kritische Trefferwertung (Gewicht 58) ist hier
  der stärkste Wert" liest sich niemand zu Ende.

**Die Zeile beantwortet damit „warum dieser Stein" — nicht „warum
überhaupt so".** Genau die zweite Frage blieb offen: woher die Gewichte
kommen, welche Grenzen gerade gelten, was das Umschmieden davon schon
abnimmt, in welcher Reihenfolge die drei Seiten ineinandergreifen. Ohne
diese Ebene bleibt es beim Glauben oder Lassen, und ein Krit-Stein auf
einem Charakter weit unter dem Trefferkap sieht nach Willkür aus.

`WeintCodex.Charakter.Rationale(page)` ist deshalb die Begründungsebene
*über* den Zeilen, und sie steht auf allen drei Seiten im Detailbereich:
Spezialisierung, die vier am höchsten gewichteten Werte mit ihren Zahlen,
jede Grenze und Schwelle mit dem, was noch fehlt oder schon darüber
liegt, was auf dieser Seite überhaupt entschieden wird, und die
Reihenfolge (erst umschmieden, dann sockeln, dann verzaubern) samt der
Grenzen, die der Umschmiede-Plan von selbst schließt.

Fünf Dinge daran sind nicht Geschmack:

- **Sie rechnet nichts.** Gelesen werden `CapContext()` und
  `RE.CapOutlook()`, formuliert wird, was dort schon steht. Eine zweite
  Rechnung für den Erklärtext liefe irgendwann anders aus als die erste —
  und dann widerspräche die Begründung der Empfehlung, die sie begründet.
  Dieselbe Regel, aus der es `PlanItem` und `Raids.ShouldInvite()` gibt.
- **Eine Quelle für drei Seiten.** Verzauberungen, Sockel und Umschmieden
  erklären sich aus denselben Zahlen; drei Fassungen davon wären drei
  Gelegenheiten auseinanderzulaufen. Sie liegt deshalb in
  `modules/charakter.lua` (dort stehen Profil und Grenzen) und wird von
  `modules/reforge.lua` beim Namen gerufen.
- **Der Detailbereich rollt** (seit 2.7.1.0, `InspectorBody`), und der
  Blocktyp `text` misst seine Höhe (`InspectorText`), beides in
  `core/navigation.lua`. Die Spalte war eine feste Fläche — was nicht
  hineinpasste, lief unten aus dem Fenster heraus, unerreichbar und
  ausgerechnet dann, wenn am meisten dasteht; dieselbe Falle und dieselbe
  Abhilfe wie beim Changelog-Popup in `core/onboarding.lua`, samt der
  Regel, dass eine Leiste ohne Bildlauf ausgeblendet wird. Die 10 px der
  Leiste gehen von `INSPECTOR_CONTENT_W` ab, als Zahl und nicht als
  Messung: die Blöcke entstehen, bevor der Rahmen seine endgültige Größe
  meldet.
- **`InspectorCard` rechnet mit festen 15 px je Zeile** und kann deshalb
  keinen umbrechenden Satz tragen; eine geschätzte Höhe fällt genau dann
  auf, wenn der Text am längsten ist, und dann liegt der nächste Block
  darüber. Dieselbe Regel wie bei den Begründungszeilen der Sockel- und
  Verzauberungsseite — und aus demselben Grund misst seit 2.7.1.0 auch die
  Planzeile in `modules/reforge.lua` ihre Höhe, statt die Begründung
  rechtsbündig in eine Zeile zu quetschen.
- **Zurückhaltung bleibt Zurückhaltung.** Kein Profil, keine Grenze, kein
  fertiger Umschmiede-Plan: dann sagt das Feld genau das, statt eine
  Auskunft zu erfinden. `RE.CapOutlook()` rechnet dabei nie selbst (siehe
  dort).

## Werteabgleich (`modules/stat_match.lua`)

Loads **before** `modules/charakter.lua` and is the answer to a class of
bug that kept coming back: a correctly enchanted character being told its
gear was wrong. Enchant grading used to ask two questions, and both read
from `data/enchants.lua` — is the enchant ID in the recommendation list,
and does its name match one. MoP enchant IDs cannot be derived from the
client, the table is hand-maintained (several entries still carry `verify
= true`), and Blizzard renamed the German enchant and gem strings mid-
expansion. One wrong line there was enough for the addon to claim a
defect that did not exist.

Wo die Verzauberungs-ID selbst nicht zu belegen ist, steht der Eintrag
unter der **Itemnummer** der Verzauberungsformel (`74715` Stiefel-Tempo,
`74711` Umhang-Ausdauer, seit 2.6.0.3 `74719` Handschuh-Tempo, seit
3.3.0.1 `74716` Stiefel-Treffer). Erkannt
wird er dann über Slot + Werte bzw. den Namen, nie über die Nummer — und
ohne ihn hätte die betroffene Spec gar keine Empfehlung mehr, was
schlechter ist als eine unbelegte ID. Umgekehrt gilt: **zwei IDs für
dieselbe Verzauberung sind dort die Regel, nicht die Ausnahme** (4422/4424
Umhang, 4432/4434 und 4433/4430 Hände, seit 3.3.0.1 4425/4428 Füße); in
die Empfehlungslisten kommt nur eine davon, den Rest fängt der
Werteabgleich als *werte-identisch* ab.

Die 4428 ist dabei der Beleg dafür, dass eine geratene Nummer teurer ist
als eine fehlende: sie stand als *Große Präzision* in der Tabelle und in
zwanzig Empfehlungslisten, gehört am Client aber dem *Verschwimmen*. Jeder
richtig verzauberte Stiefel las deshalb „(ID 4428 abweichend – /wc vz)",
und in den sieben Stärkeprofilen (Krieger, Paladin, Todesritter) galt
*Verschwimmen* über diese ID als optimal, obwohl Beweglichkeit dort
nichts bringt. Die *Große Präzision* hat seitdem gar keine belegte ID mehr —
sie steht unter ihrer Formelnummer und wartet auf ein `/wc vz` von
jemandem, der sie trägt.

`WeintCodex.StatMatch` asks a third question that needs no table of ours:
**which stats does the thing actually grant, and are they the same ones
the recommendation grants?** The player's values come from the item
tooltip, the recommendation's from `SM.EnchantStats`/`SM.GemStats` (data
file, or the client when the data file has a gap). `SM.CompareStats`
returns one of `equal` / `better` / `weaker` / `partial` / `different`;
`equal` and `better` count as "the recommendation is on" — `better`
because the profession-exclusive tiers (the scribes' *Geheime Inschrift*)
carry the same stat keys with higher numbers, and reporting those as "not
ideal" is absurd.

**Die Schlüssel von `GetItemStats` sind die Namen der `ITEM_MOD_*`-
Konstanten, und ihre Schreibweise ist nicht einheitlich.** Der Client
hängt `_SHORT` nur an die Grundwerte, an Willenskraft und an die
Meisterschaft; `dodge`, `parry`, `hit`, `crit`, `haste` und `expertise`
meldet er **ohne**. `ITEM_MOD_MAP` trug bis 2.7.1.1 überall `_SHORT` —
sechs der acht umschmiedbaren Werte fielen damit aus jeder Antwort heraus,
und zwar lautlos: ein unbekannter Schlüssel liefert keinen Fehler, sondern
eine kürzere Tabelle. Die Sockelseite kam trotzdem durch (`SM.GemStats`
fällt für Steine auf den Tooltip zurück), der Umschmiede-Planer nicht — er
**zählt** an genau diesen Werten ab, welche Umschmiedungen für einen
Gegenstand zulässig sind, und diese Zahl geht als laufende Nummer an den
Umschmieder. Von acht Aufträgen kamen drei richtig an; die übrigen fünf
legten etwas anderes an und sahen von aussen aus wie „nicht durchgekommen".
Maßgeblich ist die Liste aus ReforgeLite (am laufenden Client belegt);
aufgeschrieben werden **beide** Schreibweisen, weil der Client immer nur
eine davon schickt. `SM.ValidateStatKeys()` prüft beim Login gegen die
globalen Konstanten des Clients, ob wir für jeden der acht Werte eine
bekannte Schreibweise haben, und `NormalizeItemStats` sammelt jeden
Schlüssel, den es nicht zuordnen kann — `/wc umschmieden prüfen` druckt
ihn aus. Ohne diese beiden ist ein Tabellenfehler dieser Art von aussen
nicht von einem Zeitproblem zu unterscheiden.

**Und diese Zuordnung steht an genau EINER Stelle.** Sie stand an dreien
— in `NormalizeItemStats`, in `StatsFromItemAPI` und noch einmal als
`STAT_LABELS`/`STAT_ORDER` in `modules/charakter.lua` —, alle drei mit
demselben `_SHORT`-Fehler, und die Korrektur in 2.7.1.1 erreichte nur zwei
davon: die *Werte-Summen der Ausrüstung* zeigten danach weiter nur
Primärwert, Ausdauer, Meisterschaft und Rüstung. Der Testlauf prüft das
deshalb **strukturell** und nicht nur am Verhalten: ausser
`modules/stat_match.lua` darf keine Datei die Wertungsschlüssel des
Clients selbst aufzählen. Die Rüstung ist die eine Ausnahme
(`RESISTANCE0_NAME`) — nicht umschmiedbar, in keinem Spec-Profil
gewichtet, gehört aber in eine Summe der Ausrüstung, und wird deshalb
neben dem Werteabgleich aus derselben Antwort gelesen.

Four rules that are not taste:

- **Never compare via `statWeights`.** Two enchants with the same weighted
  score but different stats are not the same enchant: 170 haste is not
  170 mastery. Only identical stat key sets count as a match — a
  score-based check would manufacture new errors while fixing old ones.
- **Proc enchants have no stats on purpose** (Lied des Windes, Jadegeist,
  DK runes). `SM.EnchantStats` returns `nil` for them and the comparison
  stays out of it entirely; their value is in the proc, not in numbers.
- **The tooltip wins over the table, but only where it actually read
  something.** `PreferredEnchantStats` hands back the DB entry when the
  scan found a strict subset of its keys (the client abbreviates part of
  multi-stat enchants and the parser drops those), and the tooltip in
  every other case — including when the number differs. That is how the
  wrist-strength 170-vs-180 staleness became visible instead of turning
  the enchant into "unknown". The mirror of that rule: **where the
  tooltip read no values at all, it contradicts nothing.** A line with
  numbers that fits no entry of the slot really does contradict the
  table, and the chat warning is for exactly that; a pure *name* line that
  we do not recognise says only that we lack the client's spelling — and
  the name is the least reliable field in `data/enchants.lua`
  (hand-maintained, not derivable from the client, renamed by Blizzard
  mid-expansion). Warning about it produced the "Verzauberungs-ID 4416
  (Handgelenke) passt nicht zur Datenbank" report on a correctly enchanted
  character. `ResolveEnchant` marks that case `unknownName` instead: the
  row shows the client's name with a quiet "(Name so nicht in der
  Datenbank)", the numbers keep coming from the DB entry, and `/wc vz`
  still prints the mismatch for whoever maintains the table.
- **Item stat lines look exactly like enchants — all of them, not just
  the primaries.** They sit *above* the enchant's line in the tooltip, so
  taking the first plausible green line reported "+1300 Stärke" as the
  enchant on a strength item. Candidate lines are ranked instead
  (`RankEnchantCandidate`: name hit → stat hit → key overlap → plausible
  magnitude), and among equal ranks the last line wins only at the
  weakest rank, because that is where the enchant sits.

  Through 2.0.0.3 this rule carried a rider that was simply false: that
  the client abbreviates item *secondary* stats ("Kritischer Trefferwert")
  and those therefore fall out of the parser by themselves. The client
  abbreviates the **enchant's** line by exactly the same rule — a gloves
  enchant reads "+170 Tempo", a cloak enchant "+180 kritischer
  Trefferwert". `SM.STAT_KEYWORDS` knowing only the long forms did not
  filter item lines; it made *both* lines unreadable, which cost the
  Werteabgleich every secondary-stat enchant (and the socket bonus with
  it) and dropped the choice onto a tie that the topmost line won. That is
  how a correctly enchanted character was told "+1.201 Meisterschaft" sat
  on its gloves. **A filter that works by not understanding something is
  not a filter.** What separates the two is now stated positively:
  - the numbers, read correctly — `SM.ParseNumber` handles the German
    thousands dot, without which "+1.201 Meisterschaft" is the number 1
    and `MAX_ENCHANT_VALUE` (600) never fires,
  - reforge lines naming their origin in the text ("+298 Parieren
    (Umgeschmiedet aus Waffenkunde)") — those land mid-range and
    magnitude cannot catch them,
  - and above all a hit in `data/enchants.lua` by slot + stats, which
    outranks everything else.

  The rank order itself carried the next instance of the same bug through
  2.0.1.0, and it is the reason the two reading paths are now separated
  by a hard rule: **a line that starts with "+number" is never identified
  by its text.** Rank 1 ("this text is the name of an enchant for this
  slot") is checked *before* any magnitude test, and the name comparison
  is deliberately a containment check so client prefixes ("Nebenhand - ")
  don't break it. Four DB entries are named after a stat or an effect —
  "Meisterschaft" (wrist), "Präzision" (cloak), "Verschwimmen", "Koloss" —
  so the item's own "+894 Meisterschaft" scored the *safest* rank and beat
  the real "+180 Stärke" two lines below it. `EnchantNamesMatch` therefore
  rejects value lines outright (`LooksLikeStatValueLine`), which fixes
  every caller at once: candidate ranking, the ID correction in
  `ResolveEnchant`, and the recommendation comparison in `EvaluateEnchant`.
  Weg A reads names, Weg B reads numbers — mixing them was the defect, not
  a missing special case.

  Not every enchant line names a single stat: *Glorreiche Werte* reads
  "+80 alle Werte". `SM.AllStatsLine` spreads that across the five base
  stats, because a line with a number but no readable value is (rightly)
  discarded — without it the scan found no enchant line on any chest
  piece at all and fell back to the unverified DB name with a "(?)".

  The weakest rank ("plausible magnitude, nothing more") applies **only
  when the DB knows nothing about that ID.** If there is an entry and no
  line matches it, the scan failed rather than the table being wrong, and
  the DB name is the honest answer instead of a guessed item line. `/wc vz
  zeilen` prints every tooltip line with its colour and parsed stats —
  this class of bug is not diagnosable from the outside without it.

  Through 2.9.0.0 the code did not implement that sentence: it read `if
  dbStats then return nil end`, and an entry *without* stats is exactly
  the case the weakest rank was never meant for. All thirteen stat-less
  entries of `data/enchants.lua` are weapon procs, DK runes and scopes —
  **lines with no numbers at all**, so no value line can ever be them. On
  any enchanted weapon the item's own mastery or hit value fell under
  `MAX_ENCHANT_VALUE` and was printed as the enchant, complete with "(ID …
  abweichend)" on a correctly enchanted weapon.

  **A name line must not hang on our own translation, either.** The other
  half of the same bug: `LooksLikeEnchantText` let a digit-free green line
  through only if its text stood *letter for letter* in
  `data/enchants.lua`. That is precisely the wrong field to lean on — the
  enchant names there are hand-maintained, not resolvable from the
  client, and renamed by Blizzard mid-expansion; two of the six weapon
  enchants were translated from English instead of copied from the client
  ("Lied des Windes"/"Lied des Flusses" for **Windweise**/**Flussgesang**,
  which exist nowhere in the game). Where our entry says the enchant
  carries no stats, the scan now knows what to look for without the name:
  a green line with no digits that is not one of the client's own labels
  (`ITEM_SPELL_TRIGGER_ONUSE`/`ONEQUIP` — green, digit-free, and the
  item's). Which of them it is stays a question for the ranking; a name
  hit still beats everything. A client name we do not know then shows up
  as the row's `unknownName` case, which is the honest answer, not a
  warning.

  `.github/tests/enchant_scan_test.lua` is the offline guard for this —
  `WeintCodex.Charakter.ResolveEnchant` is exported for it. The whole
  calculation reads nothing but tooltip text, and it has now shipped
  wrong three times with the identical outcome (2.0.0.3, 2.0.1.0, 2.9.0.1):
  an **item stat line printed as the enchant**. In game that surfaces only
  when somebody sends a screenshot of their character panel.

The same layer removed the blind spot on gems: a gem missing from
`data/gem_stats.lua` used to land on "ok (unknown)", counted against
nothing and fed no cap check. `SM.GemStats` falls back to `GetItemStats`
(keyed by `ITEM_MOD_*` constant names, so locale-independent) and then to
a tooltip parse. A gem whose base data was not cached yet joins the same
`GET_ITEM_INFO_RECEIVED` redelivery list as the enchants rather than being
cached as "nothing found".

Whenever the verdict comes from this layer rather than from an ID hit,
the row says so (*werte-identisch* / *stärkere Stufe* / *schwächere Stufe*)
— an unexplained "Optimal" on an enchant that is not named like the
recommendation is the next bug report. `/wc vz` prints the measured stats
for every enchant and gem plus where the database disagrees; that output
is what the affected line gets corrected from.

## BiS lists (`data/bis.lua` + `modules/bis.lua`)

`data/bis.lua` holds `WeintCodex_BiS`, a per-spec table (keys match
`WeintCodex_SpecProfiles` in `spec_profiles.lua`, e.g. `WARRIOR_ARMS`) of
`{ id, slot, boss, variants?, note? }` entries — item name is deliberately
not stored, it's resolved at runtime via `GetItemInfo` so it always
matches the client's language (same doctrine as `WeintCodex_GetGemName` in
`gems.lua`). `modules/bis.lua` builds a boss→spec index from that once and
exposes `WeintCodex.BiS.GetForBoss(bossName, specKey)`, which checks only
*equipped* gear (no bag/bank scan) and classifies each entry `have`/
`variant`/`open`. Tank specs playing offensive stance (`*_OFFENSIVE`
profile keys) have no data of their own — `GetForBoss` falls back to the
base spec key since gear is identical between styles. `modules/bossguides.lua`
renders the result as a scrollable `itemlist` block (`core/navigation.lua`)
in the Inspector, under the boss notes.

`WeintCodex.BiS.GetSummary(specKey)` (`modules/bis.lua`) exists for it:
`GetForBoss` answers "does something for me drop here", the summary
answers "how far along am I overall". It counts **per slot, not per
entry** — a BiS list carries several entries for Finger and Schmuck, and
wearing one of them does not leave the slot half open — and returns a
second value saying whether a list is maintained for the spec at all, so
"0 offen" is never claimed where nothing was checked.

## Verwandt

- Sim-Gewichte übernehmen (wowsims/QE Live) und die Ausrüstung an den Sim
  senden speisen `statWeights` und die Umschmiede-Ziele mit → siehe
  `stat-weights-qelive.md`.
- Wie das Addon lokal mit Companion darüber spricht (`stat_weights`-Inbox,
  `WCIMPORT:SW`) → `../../../WeintCompanion/docs/stat-weights-bridge.md`.
- Die 5+ Release lange Fehlerhistorie der Sockelbewertung, komprimiert →
  `../history/gearing-lessons.md`.
