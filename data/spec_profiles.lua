--------------------------------------------------
-- WeintCodex :: Spec Profiles
-- Mists of Pandaria Classic
-- Quelle: https://www.wowhead.com/mop-classic/de
--
-- Struktur pro Spec:
--   role         = "MELEE" | "RANGED" | "CASTER" | "HEALER" | "TANK"
--   caps         = { { stat="hit", typ="melee|ranged|spell", pct=7.5 },
--                    { stat="expertise", pct=7.5 } }
--                  -> Wird live gegen den Charakterbogen geprüft.
--                     Steine/Verzauberungen mit diesem Stat werden als
--                     "Über Cap" markiert, wenn das Cap überschritten ist.
--   statWeights  = { stat = Gewicht 0..100 }
--                  -> Bewertet JEDEN Stein (auch nicht gelistete).
--   bestEnchants = { [Slot] = { id1, id2, ... } }  (id1 = beste)
--                  -> JEDE ID DER LISTE GILT ALS OPTIMAL. Die Liste ist
--                     keine Rangliste mit einem Sieger, sondern die Menge
--                     der vertretbaren Verzauberungen; id1 ist nur das,
--                     was auf ein noch unverzaubertes Teil gehört. Was
--                     nicht drinsteht, meldet das Addon als Mangel — und
--                     ein Mangel muss einer sein.
--
--   STIEFEL: die eine Stelle, an der MoP zwischen zwei gleich guten
--   Verzauberungen wählen lässt, und die Quelle des Fehlerberichts vom
--   21.08.2026 ("Stiefel VZ passt nicht, BiS sagt großes Tempo").
--   Es gibt genau vier: Verschwimmen (140 Bewegl. + Lauftempo),
--   Pandarenpfoten (140 Meist. + Lauftempo), Großes Tempo (175 Tempo)
--   und Große Präzision (175 Treffer, cap-getrieben).
--     * Beweglichkeits-Specs nehmen Verschwimmen: Primärwert und
--       Lauftempo in einem, dagegen kommt kein Sekundärwert an.
--     * Für alle anderen steht 140 Meisterschaft gegen 175 Tempo. Die
--       25 % mehr Wertung sind nicht die ganze Rechnung — Pandarenpfoten
--       trägt das Lauftempo, das in keinem Gewicht steht und das die
--       Guides ausdrücklich als Ausgleich nennen (Arkanmagier,
--       Dämonologie, Krieger: dort ist Pandarenpfoten die Empfehlung,
--       obwohl Tempo nach Wertung vorn läge). Deshalb: Reihenfolge nach
--       Gewicht × Wertung, wobei das Lauftempo einen Tempo-Vorsprung bis
--       zu einem Viertel aufwiegt — ein Viertel, weil genau das der
--       Abstand zwischen 140 und 175 Wertung ist. Und BEIDE stehen in
--       der Liste, solange die schwächere mindestens die Hälfte der
--       stärkeren wert ist.
--   Der Grund für das "beide": ob Tempo oder Meisterschaft besser ist,
--   hängt an Tempo-Breakpoints, die das Addon nicht kennen kann (es sieht
--   keine Raidbuffs und keine Reforge-Absicht). Eine der beiden als
--   "nicht ideal" zu melden, behauptet ein Wissen, das nicht da ist —
--   genau daran ist der gemeldete Elementarschamane hängengeblieben.
--   bestGems     = { [Schlüssel] = { id1, id2, ... } }
--                  -> Schlüssel: meta, rot, gelb, blau, prismatic
--                     (SOCKELfarben) sowie orange, lila, grün
--                     (STEINfarben, siehe unten). Alle IDs gelten als
--                     vertretbar; id1 ist, was auf einen leeren Sockel
--                     dieser Farbe gehört.
--                  -> rot/gelb/blau/prismatic sind SOCKELfarben: MoP-
--                     Gegenstände haben nur rote, gelbe, blaue, Meta- und
--                     Prismasockel. Die Liste beantwortet "was gehört in
--                     einen Sockel dieser Farbe" — ein farblich passender
--                     Mischstein darf und soll dort stehen (blau -> grüner
--                     Dioptas).
--                  -> orange/lila/grün beantworten diese Frage NICHT (es
--                     gibt keine orangen Sockel). Bis 2.5.0.0 waren sie
--                     deshalb schlicht unerreichbar — 78 Listen, die
--                     autoritativ aussahen und nie gelesen wurden. Seit
--                     2.5.0.0 haben sie eine Aufgabe: der Planer zieht aus
--                     ALLEN Listen des Profils die Steine, die die Farbe
--                     eines Sockels bedienen, wenn er den Sockelbonus
--                     halten will. Ein lila Stein (rot+blau) ist damit ein
--                     Kandidat für rote und blaue Sockel. Was hier steht,
--                     wird also benutzt — aber die Farbe des Steins
--                     entscheidet, wo, und die liest das Addon am Client
--                     (Unterklasse des Gegenstands), nicht an diesem
--                     Schlüssel.
--                  -> REIHENFOLGE IST RANGFOLGE. Die Liste muss NICHT mehr
--                     "bis zum Ende tragen": bis 2.5.0.0 nahm die
--                     Sockelbonus-Entscheidung den ersten Stein, der in
--                     KEINEN gecappten Stat läuft, und ohne einen solchen
--                     galt Farb-Matchen pauschal als wertlos. 21 von 39
--                     Profilen hielten diese Regel nicht ein. Jetzt zählt
--                     ein Stein am Cap einfach nur noch mit dem, was
--                     ausserhalb des Caps liegt (GemValue in
--                     modules/charakter.lua), und der Planer sucht
--                     notfalls im ganzen Profil weiter.
--   gemNote      = Freitext-Hinweis für die Sockel-Seite
--------------------------------------------------

WeintCodex_SpecProfiles = {

    --------------------------------------------------
    -- KRIEGER
    --------------------------------------------------

    WARRIOR_ARMS = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        -- SEKUNDÄRWERTE GEGEN STÄRKE — die Zahl entscheidet über Sockelboni.
        -- Ein Sockelstein bringt entweder 160 Primär- oder 320 Sekundärwert,
        -- ein Hybridstein 80 + 160. Damit hängt "Farbe matchen oder nicht"
        -- allein am Verhältnis Krit:Stärke: erst ab 0,8 wird der reine
        -- Kritstein stärker als Hybridstein + Sockelbonus. Bis 2.0.1.0
        -- standen hier 0,80 (Arms) bzw. 0,82 (Furor) — damit riet das Addon
        -- auf Gegenständen mit kleinem Bonus zum Umsockeln, obwohl der
        -- Bonus rechnerisch überwog. In MoP liegt Krit für Plattennahkampf
        -- bei gut der Hälfte von Stärke (320 Krit ≈ 160 Stärke), und genau
        -- da liegen die Werte jetzt.
        statWeights = {
            strength = 100, hit = 88, expertise = 85,
            crit = 58, mastery = 47, haste = 42, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },       -- Tanzender Stahl / Elementarkraft
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },       -- Krit zuerst, dann Präzision (Treffer)
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4432 },
            Beine        = { 4823 },
            ["Füße"]     = { 4429, 74715, 4426, 4428 },  -- Meist. 6.580 / Tempo 7.350 — Lauftempo entscheidet (so auch die Guides)
            Ring         = { 84578 },
        },
        -- Krit ist der beste Sekundärstat -> überall Glatter Goldberyll.
        -- Sockelboni matchen, wenn sie sich lohnen: Rot -> Gravierter
        -- Aragonit (Str+Krit), Blau -> Stechender Dioptas (Krit+Treffer).
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76661, 76693, 76696 },  -- match: Gravierter Aragonit; Präziser Rubellit (Waffenkunde-Cap); Klobiger
            gelb      = { 76697, 83146 },         -- Glatter Goldberyll (Krit) / JC-Schlangenauge
            -- Am Trefferkap sind beide wertlos — Gezackter Dioptas
            -- (Krit+Ausdauer) ist dann der einzige Stein, der einen blauen
            -- Sockel noch bedient, ohne in den Cap zu laufen. Ohne diesen
            -- dritten Eintrag hätte die Sockelbonus-Entscheidung gar keinen
            -- Vergleichswert und erklärte Matchen pauschal für wertlos.
            blau      = { 76641, 76636, 76652 },  -- Stechender Dioptas (match); Massiver Chrysokoll (Treffer-Cap); Gezackter Dioptas (am Cap)
            orange    = { 76661 },                -- Gravierter Aragonit (Str+Krit)
            lila      = { 76684 },                -- Geätzter Kunzit (Str+Treffer, situativ)
            ["grün"]  = { 76641 },                -- Stechender Dioptas (Krit+Treffer)
            prismatic = { 76697, 83146 },         -- Krit universell
        },
        gemNote = "Krit überall (Glatter Goldberyll). Erst 7,5% Treffer + 7,5% Waffenkunde. Sockelbonus nur matchen, wenn er sich lohnt.",
    },

    WARRIOR_FURY = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        -- Verhältnis wie bei Waffen (s.o.): Krit ≈ halbe Stärke je Punkt,
        -- damit Hybridstein + Sockelbonus den reinen Kritstein schlägt.
        statWeights = {
            strength = 100, hit = 88, expertise = 85,
            crit = 60, mastery = 46, haste = 44, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },       -- Krit zuerst, dann Präzision (Treffer)
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4432 },
            Beine        = { 4823 },
            ["Füße"]     = { 4429, 74715, 4426, 4428 },  -- Meist. 6.440 / Tempo 7.700 — Lauftempo entscheidet (so auch die Guides)
            Ring         = { 84578 },
        },
        -- Krit ist der beste Sekundärstat, aber NICHT wertvoller als Stärke:
        -- 320 Krit ≈ 160 Stärke. Deshalb Hybridsteine, sobald ein Sockel-
        -- bonus daran hängt, und der reine Kritstein nur dort, wo keiner
        -- verloren geht (Zusatzsockel, gelbe Sockel).
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76661, 76693, 76696 },
            gelb      = { 76697, 83146 },
            -- Dritter Eintrag wie beim Waffen-Krieger: am Trefferkap
            -- tragen weder Stechender Dioptas noch Massiver Chrysokoll
            -- noch etwas bei. Gemeldet an genau diesem Fall — blauer
            -- Sockel mit +60 Stärke Bonus, Treffer am Cap: Matchen kostet
            -- dann 8.400 Wertung und bringt 6.000, der reine Kritstein
            -- gewinnt. Die Entscheidung soll das ausrechnen können.
            blau      = { 76641, 76636, 76652 },
            orange    = { 76661 },
            lila      = { 76684 },
            ["grün"]  = { 76641 },
            prismatic = { 76697, 83146 },
        },
        gemNote = "Krit überall (Glatter Goldberyll). Beide Waffen Tanzender Stahl. Erst 7,5% Treffer + 7,5% Waffenkunde. Sockelbonus nur matchen, wenn er sich lohnt.",
    },

    WARRIOR_PROTECTION = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 15, note = "Hard-Cap 15% (Parieren)" },
        },
        -- Meisterschaft ist beim Schutzkrieger KRITISCHER BLOCK, nicht ein
        -- Ausweichwert unter anderen: sie verdoppelt den Blockwert und wirkt
        -- damit auf jeden geblockten Treffer, während Parieren/Ausweichen
        -- abnehmenden Erträgen unterliegen und nur zufällig greifen. Sie
        -- stand hier bis 2.0.1.0 mit 45 unter beiden — deshalb empfahl die
        -- Sockelseite in gelben Sockeln einen reinen Ausweichstein statt
        -- eines Meisterschafts-/Ausdauersteins.
        statWeights = {
            stamina = 100, hit = 90, expertise = 88, mastery = 72,
            parry = 62, strength = 58, dodge = 55, crit = 20, haste = 15,
        },
        bestEnchants = {
            Waffe        = { 4444, 4445 },        -- Tanzender Stahl (Fallback: Koloss)
            Nebenhand    = { 89737 },             -- Schild: Großes Parieren
            Schultern    = { 4805 },
            Brust        = { 4420, 4419 },        -- Defensiv: Überragende Ausdauer
            Umhang       = { 74711 },             -- Großer Schutz (+200 Ausdauer)
            Handgelenke  = { 4411, 4415 },        -- Meisterschaft
            ["Hände"]    = { 4430, 4431 },        -- Defensiv: Überragende Meisterschaft
            Beine        = { 4824 },              -- Eisenschuppenbeinrüstung
            ["Füße"]     = { 4429 },  -- Meist. 10.080 / Tempo 2.625 — die andere ist wirklich falsch
            Ring         = { 84578, 84577 },      -- Stärke, alternativ Ausdauer
        },
        -- Defensiv (Ausdauer-Fokus): Gediegener Chrysokoll überall.
        -- Sockelboni matchen, wenn lohnend: Rot -> Kunzit des Verteidigers,
        -- Orange -> Bruchfester Aragonit, Grün -> Perfekter Alexandrit.
        bestGems = {
            meta      = { 76895, 95344 },
            rot       = { 76690, 76695, 76691 },  -- Kunzit d. Verteidigers (Parieren+Ausdauer); Parieren; Str+Ausdauer
            -- Gelber Sockel: der Stein muss gelb ODER grün sein (grün =
            -- gelb+blau), sonst geht der Sockelbonus verloren. Ein reiner
            -- Ausweichstein war hier bis 2.0.1.0 die zweite Wahl, obwohl
            -- der grüne Meisterschafts-/Ausdauerstein beide Werte bringt,
            -- die dem Schutzkrieger etwas nützen — er steht jetzt davor.
            --
            -- 2.5.0.0: der *Perfekte geschickte Alexandrit* (76589) stand
            -- hier an erster Stelle und ist damit die Empfehlung für jeden
            -- gelben Sockel gewesen. Er trägt Treffer + Ausdauer — beides
            -- blaue Werte, die Kombination kann kein grüner Schliff sein
            -- (siehe die Notiz am Eintrag in data/gems.lua). Ein blauer
            -- Stein löst keinen gelben Sockelbonus aus, die Empfehlung warf
            -- ihn also weg. Unabhängig davon sagen die Gewichte dieses
            -- Profils selbst, dass der Imposante Dioptas 96 % mehr bringt
            -- (Meisterschaft 72 gegen Treffer 90 am 7,5-%-Cap) — zwei Gründe,
            -- die auf denselben Stein zeigen.
            gelb      = { 76656, 76698 },         -- Imposanter Dioptas (Meister+Ausdauer); Subtiler Goldberyll (Ausweichen)
            blau      = { 76639, 76636 },         -- Gediegener Chrysokoll (Ausdauer); Massiver (Treffer)
            orange    = { 76664 },                -- Bruchfester Aragonit (Parieren+Ausweichen)
            lila      = { 76690, 76683 },         -- Kunzit d. Verteidigers; Fixierender (Parieren+Treffer)
            ["grün"]  = { 76589, 76656 },         -- Perfekter Alexandrit; Imposanter (Meister+Ausdauer)
            prismatic = { 76639 },                -- Ausdauer universell
        },
        gemNote = "Defensiv: Ausdauer überall (Gediegener Chrysokoll), nach 7,5% Treffer / 15% Waffenkunde Parieren/Ausweichen. Sockelbonus nur matchen, wenn er sich lohnt.",
    },

    --------------------------------------------------
    -- PALADIN
    --------------------------------------------------

    PALADIN_HOLY = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, spirit = 90, mastery = 75, crit = 55,
            haste = 45, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4430, 4433 },  -- Meist. 12.750 / Tempo 7.650
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 74715, 4426 },  -- Meist. 10.500 / Tempo 7.875
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95345 },         -- Brennender / Mutiger Bergkristall
            rot       = { 76694, 83150 },         -- Glänzender Rubellit (Int)
            gelb      = { 76700, 76699 },         -- Frakturierter (Meister) / Spiegelnder (Tempo, Ewige Flamme)
            blau      = { 76686, 76638 },         -- Geläuterter Kunzit (Int+Wille); Funkelnder (Wille)
            orange    = { 76672 },                -- Kunstvoller Aragonit (Int+Meister)
            lila      = { 76686 },                -- Geläuterter Kunzit
            ["grün"]  = { 76645, 76651 },         -- Meditativer (Wille+Meister); Geladener
            prismatic = { 76694, 83150 },         -- Intelligenz universell
        },
        gemNote = "Intelligenz-Basis, Meisterschaft bester Durchsatz-Sekundärstat > Krit > Tempo (Tempo nur für Breakpoints). Sockelboni mit Int-Hybriden matchen.",
    },

    PALADIN_PROTECTION = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 15, note = "Hard-Cap 15% (Waffenkunde) — Control-Paladin" },
        },
        statWeights = {
            hit = 100, expertise = 98, mastery = 80, stamina = 80,
            haste = 65, parry = 55, dodge = 55, strength = 45, crit = 20,
        },
        bestEnchants = {
            Waffe        = { 4446, 4445 },        -- Flussgesang (River's Song)
            Nebenhand    = { 89737 },             -- Schild: Großes Parieren
            Schultern    = { 4805 },
            Brust        = { 4420, 4419 },        -- Überragende Ausdauer
            Umhang       = { 74711 },             -- Großer Schutz
            Handgelenke  = { 4411, 4415 },        -- Meisterschaft
            ["Hände"]    = { 4430, 4433, 4431 },  -- Meist. 13.600 / Tempo 11.050
            Beine        = { 4824 },              -- Eisenschuppenbeinrüstung
            ["Füße"]     = { 4429, 74715, 4426 },  -- Meist. 11.200 / Tempo 11.375 — Lauftempo entscheidet
            Ring         = { 84578, 84577 },      -- Stärke, alternativ Ausdauer
        },
        -- Control-Tank: Waffenkunde-Hardcap (15%) + Treffer zuerst, dann
        -- Meisterschaft/Ausdauer. Sockelboni (Waffk./Treffer/Tempo/Ausdauer) matchen.
        bestGems = {
            meta      = { 95344, 76886 },         -- Unbeugsamer (def); Widerscheinender (non-leg)
            rot       = { 76693, 76695 },         -- Präziser Rubellit (Waffk.-Cap); Parieren
            gelb      = { 76700, 76699 },         -- Frakturierter (Meister def); Spiegelnder (Tempo)
            blau      = { 76639, 76636 },         -- Gediegener (Ausdauer def); Massiver (Treffer)
            orange    = { 76671, 76667 },         -- Schneidender (Waffk.+Meister); Tückischer (Waffk.+Tempo)
            lila      = { 76681, 76690 },         -- Akkurater (Waffk.+Treffer); Kunzit d. Verteidigers
            ["grün"]  = { 76642, 76643 },         -- Blitzender (Tempo+Treffer); Mentors
            prismatic = { 76700, 76693 },         -- Meisterschaft / Waffenkunde
        },
        gemNote = "Control-Tank: 15% Waffenkunde-Hardcap + 7,5% Treffer zuerst, dann Meisterschaft/Ausdauer. Sockelboni matchen.",
    },

    PALADIN_RETRIBUTION = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            hit = 95, expertise = 92, haste = 90, strength = 85,
            mastery = 80, crit = 50, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },       -- Präzision (Treffer), dann Krit
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4432, 4433 },
            Beine        = { 4823 },
            ["Füße"]     = { 74715, 4426, 4429, 4428 },  -- Meist. 11.200 / Tempo 15.750
            Ring         = { 84578 },
        },
        -- Tempo bis 50% Gesamt-Tempo, danach Meisterschaft. Sockelboni
        -- lohnen fast immer (starke Tempo-/Meister-Hybride je Farbe).
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76667, 76693, 76696 },  -- Tückischer (Waffk.+Tempo, match); Präziser (Waffk.-Cap); Klobiger
            gelb      = { 76699, 76700 },         -- Spiegelnder (Tempo <50%); Frakturierter (Meister >50%)
            blau      = { 76684, 76636 },         -- Geätzter (Str+Treffer); Massiver (Treffer-Cap)
            orange    = { 76667, 76671 },         -- Tückischer (Waffk.+Tempo); Schneidender (Waffk.+Meister)
            lila      = { 76684 },                -- Geätzter Kunzit
            ["grün"]  = { 76642, 76643 },         -- Blitzender (Tempo+Treffer); Mentors (Treffer+Meister)
            prismatic = { 76699, 76700 },         -- Tempo universell (bis 50%, dann Meister)
        },
        gemNote = "Tempo bis 50% (Spiegelnder Goldberyll), danach Meisterschaft. Erst 7,5% Treffer/Waffenkunde. Sockelboni matchen (Hybride Tückischer/Blitzender).",
    },

    --------------------------------------------------
    -- JÄGER (kein Fernkampf-Slot in MoP —
    -- Zielfernrohr gehört auf die Waffe!)
    --------------------------------------------------

    HUNTER_BEASTMASTERY = {
        role = "RANGED",
        -- JAEGER HABEN KEINEN WAFFENKUNDE-CAP. Fernkampfangriffe koennen
        -- in MoP weder pariert noch ausgewichen werden - Waffenkunde tut
        -- fuer einen Jaeger nichts. Bis 2.5.0.0 stand hier ein Cap von
        -- 7,5 % samt Gewicht 85, und die Waffenkunde-Karte meldete jedem
        -- Jaeger dauerhaft ein Defizit ("es fehlen ca. N Wertung"), das er
        -- nicht schliessen konnte und nicht schliessen sollte.
        caps = {
            { stat = "hit",       typ = "ranged", pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88,
            crit = 75, haste = 68, mastery = 60, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4699, 4700, 4443 },  -- Zielfernrohre!
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 14.000 / Meist. 8.400
            Ring         = { 84575 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76697, 76699 },
            blau      = { 76680 },
            orange    = { 76658, 76666 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit überall (Feingeschliffener Rubellit / Tödlicher Aragonit). Cap: 7,5% Treffer — Waffenkunde bringt Fernkämpfern nichts.",
    },

    HUNTER_MARKSMANSHIP = {
        role = "RANGED",
        -- JAEGER HABEN KEINEN WAFFENKUNDE-CAP. Fernkampfangriffe koennen
        -- in MoP weder pariert noch ausgewichen werden - Waffenkunde tut
        -- fuer einen Jaeger nichts. Bis 2.5.0.0 stand hier ein Cap von
        -- 7,5 % samt Gewicht 85, und die Waffenkunde-Karte meldete jedem
        -- Jaeger dauerhaft ein Defizit ("es fehlen ca. N Wertung"), das er
        -- nicht schliessen konnte und nicht schliessen sollte.
        caps = {
            { stat = "hit",       typ = "ranged", pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88,
            crit = 80, haste = 65, mastery = 55, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4699, 4700, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 14.000 / Meist. 7.700
            Ring         = { 84575 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76697, 76699 },
            blau      = { 76680 },
            orange    = { 76658, 76666 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit > Krit. Cap: 7,5% Treffer (Waffenkunde zählt für Fernkampf nicht).",
    },

    HUNTER_SURVIVAL = {
        role = "RANGED",
        -- JAEGER HABEN KEINEN WAFFENKUNDE-CAP. Fernkampfangriffe koennen
        -- in MoP weder pariert noch ausgewichen werden - Waffenkunde tut
        -- fuer einen Jaeger nichts. Bis 2.5.0.0 stand hier ein Cap von
        -- 7,5 % samt Gewicht 85, und die Waffenkunde-Karte meldete jedem
        -- Jaeger dauerhaft ein Defizit ("es fehlen ca. N Wertung"), das er
        -- nicht schliessen konnte und nicht schliessen sollte.
        caps = {
            { stat = "hit",       typ = "ranged", pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88,
            crit = 70, haste = 62, mastery = 50, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4699, 4700, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 14.000 / Meist. 7.000
            Ring         = { 84575 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76697, 76700 },
            blau      = { 76680 },
            orange    = { 76658, 76670 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76643, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit > Krit > Tempo > Meisterschaft (Einzelziel). Meisterschaft stärker im AoE. Cap: 7,5% Treffer (Waffenkunde zählt für Fernkampf nicht).",
    },

    --------------------------------------------------
    -- SCHURKE
    --------------------------------------------------

    ROGUE_ASSASSINATION = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88, expertise = 85,
            mastery = 75, haste = 70, crit = 60, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },        -- Präzision (Treffer)
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 14.000 / Meist. 10.500
            Ring         = { 84575 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76700, 76699 },
            blau      = { 76680 },
            orange    = { 76670, 76666 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76643, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit > Meisterschaft (Gifte). Caps: 7,5% Treffer / 7,5% Waffenkunde.",
    },

    ROGUE_COMBAT = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88, expertise = 85,
            haste = 78, mastery = 65, crit = 58, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },        -- Präzision (Treffer)
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 14.000 / Meist. 9.100
            Ring         = { 84575 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76699, 76700 },
            blau      = { 76680 },
            orange    = { 76666, 76658 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76642, 76641 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit > Tempo. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
    },

    ROGUE_SUBTLETY = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88, expertise = 85,
            haste = 75, crit = 65, mastery = 60, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },        -- Präzision (Treffer)
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 14.000 / Meist. 8.400
            Ring         = { 84575 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76699, 76697 },
            blau      = { 76680 },
            orange    = { 76666, 76658 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76642, 76641 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit > Tempo > Krit. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
    },

    --------------------------------------------------
    -- PRIESTER
    --------------------------------------------------

    PRIEST_DISCIPLINE = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, spirit = 80, crit = 78, mastery = 65,
            haste = 35, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4430, 4433 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 74715, 4426 },  -- Meist. 9.100 / Tempo 6.125
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76888, 95345 },
            rot       = { 76694, 83150 },
            gelb      = { 76700, 76699 },
            blau      = { 76686, 76638 },
            orange    = { 76660, 76672, 76668 },
            lila      = { 76686 },
            ["grün"]  = { 76645, 76651 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Krit ≈ Willenskraft > Meisterschaft. Tempo ist unser schwächster Stat. Kein Treffer-Cap nötig.",
    },

    PRIEST_HOLY = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, spirit = 85, crit = 70, mastery = 60,
            haste = 35, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4430, 4433 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 74715, 4426 },  -- Meist. 8.400 / Tempo 6.125
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76888, 95345 },
            rot       = { 76694, 83150 },
            gelb      = { 76699, 76700 },
            blau      = { 76686, 76638 },
            orange    = { 76660, 76668, 76672 },
            lila      = { 76686 },
            ["grün"]  = { 76651, 76645 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Willenskraft > Krit > Meisterschaft. Tempo (außerhalb von Breakpoints) ist unser schwächster Stat. Kein Treffer-Cap nötig.",
    },

    PRIEST_SHADOW = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15, spiritZaehlt = true },
        },
        statWeights = {
            intellect = 100, haste = 90, hit = 85, spirit = 82,
            crit = 65, mastery = 62, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 74715, 4426, 4429 },  -- Meist. 8.680 / Tempo 15.750
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76699, 76700 },
            blau      = { 76682, 76636, 76638 },
            orange    = { 76668, 76660 },
            lila      = { 76686, 76682 },
            ["grün"]  = { 76651, 76642 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo (unser bester Stat) > Krit ≈ Meisterschaft. 15% Zaubertreffer — Willenskraft zählt dank Zwielichtgleichgewicht als Treffer!",
    },

    --------------------------------------------------
    -- TODESRITTER
    --------------------------------------------------

    DEATHKNIGHT_BLOOD = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 15, note = "Hard-Cap 15% (Parieren)" },
        },
        -- "Most Defensive"-Prioritätsreihe: Ausdauer > Meisterschaft > Parieren >
        -- Stärke > Treffer(7,5%)/Waffenkunde(15%) > Tempo > Ausweichen > Krit.
        statWeights = {
            stamina = 100, mastery = 90, parry = 80, strength = 70,
            hit = 65, expertise = 63, haste = 45, dodge = 40, crit = 25,
        },
        bestEnchants = {
            Waffe        = { 3368, 3847 },        -- Gefallener Kreuzfahrer / Steinhautgargoyle
            Schultern    = { 4803 },              -- Große Inschrift des Tigerzahns
            Brust        = { 4419, 4420 },
            Umhang       = { 4422, 4421 },        -- Überragender kritischer Trefferwert
            Handgelenke  = { 4411, 4415 },
            ["Hände"]    = { 4430, 4431 },  -- Meist. 15.300 / Tempo 7.650
            Beine        = { 4823, 4824 },        -- Zornbalgbeinrüstung
            ["Füße"]     = { 4429, 74715, 4426 },  -- Meist. 12.600 / Tempo 7.875
            Ring         = { 84578, 84577 },      -- Stärke, alternativ Ausdauer
        },
        bestGems = {
            meta      = { 76895, 95344 },
            rot       = { 76695, 76693 },
            gelb      = { 76700, 76698 },
            blau      = { 76639 },
            orange    = { 76674 },
            lila      = { 76690, 76691 },
            ["grün"]  = { 76656, 76643 },
            prismatic = { 76639, 76695 },
        },
        gemNote = "Defensiv: Ausdauer > Meisterschaft (Blutschild) > Parieren > Stärke, nach Treffer(7,5%)/Waffenkunde(15%)-Cap.",
    },

    DEATHKNIGHT_FROST = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            strength = 100, hit = 90, expertise = 88,
            mastery = 85, crit = 70, haste = 45, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 3368, 3370 },        -- Fallen Crusader / Razorice (bei Dual-Wield)
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4432, 4433 },
            Beine        = { 4823 },
            ["Füße"]     = { 4429, 74715, 4426, 4428 },  -- Meist. 11.900 / Tempo 7.875
            Ring         = { 84578 },
        },
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76696, 83141 },
            gelb      = { 76700, 76697 },
            blau      = { 76684 },
            orange    = { 76671, 76674 },         -- Schneidender Aragonit (Waffk.+Meister)
            lila      = { 76684, 76691 },
            ["grün"]  = { 76643, 76641 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Stärke > Meisterschaft > Krit > Tempo (schwächster Stat). Dual-Wield: Gefallener Kreuzfahrer + Rune des schneidenden Eises.",
    },

    DEATHKNIGHT_UNHOLY = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            strength = 100, hit = 90, expertise = 88,
            crit = 75, haste = 65, mastery = 40, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 3368 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4432, 4433 },
            Beine        = { 4823 },
            ["Füße"]     = { 74715, 4426, 4428 },  -- Meist. 5.600 / Tempo 11.375 — die andere ist wirklich falsch
            Ring         = { 84578 },
        },
        -- Ab ~ilvl 540 lohnt sich Krit mehr als reine Stärke-Sockelung.
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76696, 83141 },
            gelb      = { 76697, 76699 },
            blau      = { 76684 },
            orange    = { 76659, 76661 },         -- Listiger Aragonit (Waffk.+Krit)
            lila      = { 76684, 76691 },
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Stärke > Krit (ab ~ilvl 540) > Tempo > Meisterschaft (schwächster Stat). Rune: Gefallener Kreuzfahrer.",
    },

    --------------------------------------------------
    -- SCHAMANE
    --------------------------------------------------

    SHAMAN_ELEMENTAL = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15, spiritZaehlt = true },
        },
        statWeights = {
            intellect = 100, hit = 92, spirit = 88, mastery = 85,
            haste = 75, crit = 60, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 74715, 4426 },  -- Meist. 11.900 / Tempo 13.125 — Lauftempo entscheidet
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76700, 76699 },
            blau      = { 76682, 76636, 76638 },
            orange    = { 76672, 76668 },
            lila      = { 76682, 76686 },
            ["grün"]  = { 76645, 76642 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Meisterschaft (wirkt wie Tempo) > Tempo > Krit. 15% Zaubertreffer Pflicht — Willenskraft zählt dank Elementarpräzision als Treffer.",
    },

    SHAMAN_ENHANCEMENT = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88, expertise = 85,
            mastery = 78, haste = 68, crit = 60, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 14.000 / Meist. 10.920
            Ring         = { 84575 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76700, 76699 },
            blau      = { 76680 },
            orange    = { 76670, 76666 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76643, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit > Meisterschaft. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
    },

    SHAMAN_RESTORATION = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, haste = 85, crit = 65, mastery = 55,
            spirit = 35, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },        -- Großes Tempo
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 74715, 4426, 4429 },  -- Meist. 7.700 / Tempo 14.875
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76888, 95345 },
            rot       = { 76694, 83150 },
            gelb      = { 76699, 76700 },
            blau      = { 76686, 76638 },
            orange    = { 76668, 76660, 76672 },
            lila      = { 76686 },
            ["grün"]  = { 76651, 76645 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo (Breakpoints: 2017/3379) > Krit > Meisterschaft. Willenskraft ist ab ~5000 kaum noch nötig (Glyphe Tellurische Ströme).",
    },

    --------------------------------------------------
    -- MAGIER
    --------------------------------------------------

    MAGE_ARCANE = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15 },
        },
        statWeights = {
            intellect = 100, hit = 92, mastery = 85, haste = 75,
            crit = 60, spirit = 10, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 4429, 74715, 4426 },  -- Meist. 11.900 / Tempo 13.125 — Lauftempo entscheidet
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76700, 76699 },
            blau      = { 76682, 76636 },
            orange    = { 76672, 76668 },         -- Kunstvoller Aragonit (Int+Meister)
            lila      = { 76682 },
            ["grün"]  = { 76643, 76642 },         -- Dioptas des Mentors (Treffer+Meister)
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Meisterschaft (skaliert mit ungenutztem Mana) > Tempo > Krit. 15% Zaubertreffer Pflicht — überschüssigen Treffer aussockeln!",
    },

    MAGE_FIRE = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15 },
        },
        statWeights = {
            intellect = 100, hit = 92, crit = 82, haste = 70,
            mastery = 60, spirit = 10, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4826, 4825 },
            ["Füße"]     = { 74715, 4426, 4429 },  -- Meist. 8.400 / Tempo 12.250
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76697, 76699 },
            blau      = { 76682, 76636 },
            orange    = { 76660, 76668 },
            lila      = { 76682 },
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Krit. 15% Zaubertreffer Pflicht.",
    },

    MAGE_FROST = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15 },
        },
        statWeights = {
            intellect = 100, hit = 92, haste = 80, crit = 65,
            mastery = 50, spirit = 10, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 74715, 4426 },  -- Meist. 7.000 / Tempo 14.000 — die andere ist wirklich falsch
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76699, 76700 },
            blau      = { 76682, 76636 },
            orange    = { 76668, 76672 },
            lila      = { 76682 },
            ["grün"]  = { 76642, 76641 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo > Krit > Meisterschaft (schwächster Stat mit früher Ausrüstung, steigt später über Krit). 15% Zaubertreffer Pflicht.",
    },

    --------------------------------------------------
    -- HEXENMEISTER
    --------------------------------------------------

    WARLOCK_AFFLICTION = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15 },
        },
        statWeights = {
            intellect = 100, hit = 92, haste = 85, mastery = 75,
            crit = 55, spirit = 10, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 74715, 4426, 4429 },  -- Meist. 10.500 / Tempo 14.875
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76699, 76700 },         -- Spiegelnder Goldberyll (Tempo)
            blau      = { 76682, 76636 },
            orange    = { 76668, 76672 },         -- Tollkühner Aragonit (Int+Tempo)
            lila      = { 76682 },
            ["grün"]  = { 76642, 76643 },         -- Blitzender Dioptas (Tempo+Treffer)
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo (Softcap ~13737) > Meisterschaft > Krit (schwächster Stat). 15% Zaubertreffer Pflicht.",
    },

    WARLOCK_DEMONOLOGY = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15 },
        },
        statWeights = {
            intellect = 100, hit = 92, haste = 82, mastery = 75,
            crit = 58, spirit = 10, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 74715, 4426, 4429 },  -- Meist. 10.500 / Tempo 14.350 — Guides nennen Pandarenpfoten (Tempo zählt nur am Breakpoint), beide gültig
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76700, 76699 },
            blau      = { 76682, 76636 },
            orange    = { 76672, 76668 },
            lila      = { 76682 },
            ["grün"]  = { 76643, 76642 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo (Breakpoints ~3036/12,5% & ~8064/25%) > Meisterschaft (Besessenheit) > Krit (schwächster Stat). 15% Zaubertreffer Pflicht.",
    },

    WARLOCK_DESTRUCTION = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15 },
        },
        statWeights = {
            intellect = 100, hit = 92, mastery = 85, haste = 70,
            crit = 45, spirit = 10, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4826, 4825 },
            ["Füße"]     = { 4429, 74715, 4426 },  -- Meist. 11.900 / Tempo 12.250 — Lauftempo entscheidet
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76700, 76697 },         -- Frakturierter Goldberyll (Meister)
            blau      = { 76682, 76636 },
            orange    = { 76672, 76660 },         -- Kunstvoller Aragonit (Int+Meister)
            lila      = { 76682 },
            ["grün"]  = { 76643, 76641 },         -- Dioptas des Mentors (Treffer+Meister)
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Meisterschaft (Glutsturm, verstärkt Emberzauber) > Tempo > Krit (teuerster Stat). 15% Zaubertreffer Pflicht.",
    },

    --------------------------------------------------
    -- MÖNCH
    --------------------------------------------------

    MONK_BREWMASTER = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            mastery = 90, hit = 88, expertise = 88, agility = 85,
            stamina = 80, crit = 60, haste = 40, dodge = 30,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4805, 4804 },
            Brust        = { 4419, 4420 },
            Umhang       = { 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431, 4433 },
            Beine        = { 4824, 4822 },
            ["Füße"]     = { 4429, 4425, 74715, 4426, 4428 },  -- Bewegl. 11.900 / Meist. 12.600 / Tempo 7.000
            Ring         = { 84575, 84577 },      -- Beweglichkeit, alternativ Ausdauer
        },
        bestGems = {
            meta      = { 76895, 95344 },
            rot       = { 76692, 83151 },
            gelb      = { 76700, 76697 },
            blau      = { 76639 },
            orange    = { 76670 },
            lila      = { 76687, 76680 },
            ["grün"]  = { 76656, 76643 },
            prismatic = { 76639, 76692 },
        },
        gemNote = "Treffer/Waffenkunde-Cap, dann Meisterschaft (Ausweichen/Abwehr) und Krit (Schwungvolles Fass).",
    },

    MONK_MISTWEAVER = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, spirit = 80, haste = 72, crit = 58,
            mastery = 35, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },  -- Tempo 12.240 / Meist. 5.950
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 74715, 4426 },  -- Meist. 4.900 / Tempo 12.600 — die andere ist wirklich falsch
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76888, 95345 },
            rot       = { 76694, 83150 },
            gelb      = { 76699, 76700 },
            blau      = { 76686, 76638 },
            orange    = { 76660, 76668, 76672 },  -- Machtvoller Aragonit (Int+Krit)
            lila      = { 76686 },
            ["grün"]  = { 76651, 76645 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Willenskraft (bis Manakomfort) > Tempo (Breakpoint) > Krit. Meisterschaft ist nahezu wirkungslos (Gabe der Schlange). Kein Treffer-Cap nötig.",
    },

    MONK_WINDWALKER = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88, expertise = 85,
            haste = 75, crit = 68, mastery = 55, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 14.000 / Meist. 7.700
            Ring         = { 84575 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76700, 76699 },         -- Frakturierter Goldberyll (Meisterschaft)
            blau      = { 76636 },                -- Massiver Chrysokoll (reiner Treffer)
            orange    = { 76666, 76658 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76642, 76641 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit > Tempo > Krit ≈ Meisterschaft (seit Patch 5.2 aufgewertet). Beide Waffen Tanzender Stahl. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
    },

    --------------------------------------------------
    -- DRUIDE
    --------------------------------------------------

    DRUID_BALANCE = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15, spiritZaehlt = true },
        },
        statWeights = {
            intellect = 100, hit = 92, spirit = 88, haste = 82,
            crit = 62, mastery = 60, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 74715, 4426, 4429 },  -- Meist. 8.400 / Tempo 14.350
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76699, 76697 },
            blau      = { 76682, 76636, 76638 },
            orange    = { 76668, 76660 },
            lila      = { 76686, 76682 },         -- Geläuterter Kunzit
            ["grün"]  = { 76651, 76642 },         -- Geladener Dioptas (Tempo+Willenskraft)
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo (Breakpoints, Softcap 24,22%) > Krit > Meisterschaft (schwächster Stat). Willenskraft zählt als Zaubertreffer (15% Cap).",
    },

    DRUID_FERAL = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        -- Meisterschaft (Blutungsschaden) ist stärker als Krit und
        -- arguably sogar wichtiger als Treffer/Waffenkunde-Cap.
        statWeights = {
            agility = 100, mastery = 90, hit = 75, expertise = 72,
            crit = 65, haste = 55, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },        -- Präzision (Treffer)
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 14.000 / Meist. 12.600
            Ring         = { 84575 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76697, 76700 },
            blau      = { 76680 },
            orange    = { 76670, 76658 },         -- Versierter Aragonit (Agi+Meister)
            lila      = { 76680, 76687 },
            ["grün"]  = { 76641, 76643 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit > Meisterschaft (unser bester unbegrenzter Sekundärstat, mehr Blutungsschaden) > Krit > Tempo.",
    },

    DRUID_GUARDIAN = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 15, note = "Hard-Cap 15% Waffenkunde (laut Guide Ziel, nicht nur 7,5%)" },
        },
        -- Ausdauer > Treffer/Waffenkunde-Cap > Krit (Wut-Generierung/Rache) >
        -- Beweglichkeit > Tempo > Meisterschaft (nur reduziert phys. Schaden, kaum priorisieren).
        statWeights = {
            stamina = 100, hit = 90, expertise = 88, crit = 75,
            agility = 55, haste = 35, dodge = 30, mastery = 15,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4805, 4804 },
            Brust        = { 4419, 4420 },
            Umhang       = { 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431, 4433 },
            Beine        = { 4824, 4822 },
            ["Füße"]     = { 4425, 4429, 4428 },  -- Bewegl. 7.700 / Meist. 2.100
            Ring         = { 84575, 84577 },      -- Beweglichkeit, alternativ Ausdauer
        },
        bestGems = {
            meta      = { 76895, 95344 },
            rot       = { 76692, 83151 },
            gelb      = { 76697, 76700 },
            blau      = { 76639 },
            orange    = { 76658, 76670 },
            lila      = { 76687, 76680 },
            ["grün"]  = { 76652, 76656 },
            prismatic = { 76639, 76692 },
        },
        gemNote = "Ausdauer > Treffer(7,5%)/Waffenkunde(15%) > Krit (Wut-Generierung). Meisterschaft nie priorisieren, außer maximale Verteidigung nötig.",
    },

    DRUID_RESTORATION = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, haste = 85, spirit = 70, mastery = 70,
            crit = 45, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4442, 4441 },
            Nebenhand    = { 74729 },             -- Schild/Beihand: Mächtige Intelligenz
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4430 },  -- Tempo 14.450 / Meist. 11.900 — wie bei den Stiefeln
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 74715, 4426, 4429 },  -- Meist. 9.800 / Tempo 14.875
            Ring         = { 84576 },
        },
        bestGems = {
            meta      = { 76888, 95345 },
            rot       = { 76694, 83150 },
            gelb      = { 76700, 76699 },
            blau      = { 76686, 76638 },
            orange    = { 76672, 76668, 76660 },
            lila      = { 76686 },
            ["grün"]  = { 76645, 76651 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo (Breakpoints) > Willenskraft ≈ Meisterschaft (Lebensblüte) > Krit. Kein Treffer-Cap nötig.",
    },

    --------------------------------------------------
    -- OFFENSIVE TANK-PROFILE (Spielstil: Offensiv)
    -- Fokus: Treffer/Waffenkunde-Cap, dann Schadensstats
    -- statt reiner Überlebenswerte.
    --------------------------------------------------

    WARRIOR_PROTECTION_OFFENSIVE = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 15, note = "Hard-Cap 15% (Parieren) empfohlen" },
        },
        statWeights = {
            hit = 100, expertise = 98, crit = 90, parry = 62,
            dodge = 58, strength = 54, mastery = 48, haste = 40, stamina = 35,
        },
        bestEnchants = {
            Waffe        = { 4444, 4445 },
            Nebenhand    = { 89737 },             -- Schild: Großes Parieren
            Schultern    = { 4803, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },       -- Offensiv: Krit
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4431, 4432 },
            Beine        = { 4823, 4824 },
            ["Füße"]     = { 4429, 74715, 4426, 4428 },  -- Meist. 6.720 / Tempo 7.000 — Lauftempo entscheidet
            Ring         = { 84578, 84577 },      -- Stärke, alternativ Ausdauer
        },
        -- Offensiv: Krit überall nach Hit/Waffenkunde-Cap. Sockelboni
        -- matchen, wenn sie sich lohnen (Rot -> Listiger Aragonit).
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76659, 76693, 76696 },  -- Listiger Aragonit (Waffenkunde+Krit); Präziser; Klobiger
            gelb      = { 76697, 83146 },         -- Glatter Goldberyll (Krit)
            blau      = { 76641, 76636 },
            orange    = { 76659 },                -- Listiger Aragonit
            lila      = { 76684 },
            ["grün"]  = { 76641 },                -- Stechender Dioptas
            prismatic = { 76697, 83146 },         -- Krit universell
        },
        gemNote = "Offensiv: Krit überall nach 7,5% Treffer / 15% Waffenkunde. Sockelbonus nur matchen, wenn er sich lohnt.",
    },

    PALADIN_PROTECTION_OFFENSIVE = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 15, note = "Hard-Cap 15% (Waffenkunde) empfohlen" },
        },
        statWeights = {
            hit = 100, expertise = 98, haste = 90, crit = 70,
            strength = 55, mastery = 45, stamina = 40, parry = 30, dodge = 25,
        },
        bestEnchants = {
            Waffe        = { 4444, 4445 },
            Nebenhand    = { 89737 },             -- Schild: Großes Parieren
            Schultern    = { 4803, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4431, 4432 },        -- Offensiv: Überragende Waffenkunde
            Beine        = { 4823, 4824 },
            ["Füße"]     = { 74715, 4426, 4428 },  -- Meist. 6.300 / Tempo 15.750 — die andere ist wirklich falsch
            Ring         = { 84578, 84577 },      -- Stärke, alternativ Ausdauer
        },
        -- Offensiv: Waffenkunde-Hardcap + Treffer, dann Tempo/Krit (Rache-DPS).
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76667, 76693, 76696 },  -- Tückischer (Waffk.+Tempo); Präziser; Klobiger
            gelb      = { 76699, 76700 },         -- Spiegelnder (Tempo); Frakturierter (Meister)
            blau      = { 76636, 76639 },         -- Massiver (Treffer); Gediegener (Ausdauer)
            orange    = { 76667, 76671 },         -- Tückischer; Schneidender
            lila      = { 76681, 76684 },         -- Akkurater (Waffk.+Treffer); Geätzter (Str+Treffer)
            ["grün"]  = { 76642, 76643 },         -- Blitzender; Mentors
            prismatic = { 76699, 76700 },         -- Tempo universell
        },
        gemNote = "Offensiv: 15% Waffenkunde-Hardcap + 7,5% Treffer, dann Tempo/Krit. Sockelboni matchen.",
    },

    DEATHKNIGHT_BLOOD_OFFENSIVE = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 15, note = "Hard-Cap 15% (Parieren) empfohlen" },
        },
        -- "Offensive"-Prioritätsreihe: Treffer(7,5%)/Waffenkunde(15%) > Krit >
        -- Tempo > Parieren > Ausweichen > Stärke > Ausdauer > Meisterschaft (schwächster Stat).
        statWeights = {
            hit = 100, expertise = 98, crit = 85, haste = 75,
            parry = 55, dodge = 50, strength = 45, stamina = 25, mastery = 20,
        },
        bestEnchants = {
            Waffe        = { 3368, 3847 },
            Schultern    = { 4803, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },        -- Überragender kritischer Trefferwert
            Handgelenke  = { 4411, 4415 },
            ["Hände"]    = { 4433, 4431 },        -- Großes Tempo
            Beine        = { 4823, 4824 },
            ["Füße"]     = { 74715, 4426 },  -- Meist. 2.800 / Tempo 13.125 — die andere ist wirklich falsch
            Ring         = { 84578, 84577 },      -- Stärke, alternativ Ausdauer
        },
        bestGems = {
            meta      = { 76886, 76895 },
            rot       = { 76696, 83141 },
            gelb      = { 76697, 76700 },
            blau      = { 76684 },
            orange    = { 76659, 76661 },         -- Listiger Aragonit (Waffk.+Krit)
            lila      = { 76684, 76681 },
            ["grün"]  = { 76641, 76643 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Offensiv: Nach Treffer(7,5%)/Waffenkunde(15%)-Cap Krit > Tempo. Meisterschaft ist hier der schwächste Stat.",
    },

    MONK_BREWMASTER_OFFENSIVE = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        -- Priorität: Treffer/Waffenkunde(Cap) > Tempo (bis ~4000) > Krit >
        -- Tempo (über 4000) > Meisterschaft (nur Minimum für Ausgewogenheit nötig).
        statWeights = {
            hit = 100, expertise = 98, agility = 90, haste = 75,
            crit = 65, mastery = 35, stamina = 30, dodge = 15,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4804, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4431 },
            Beine        = { 4822, 4824 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 12.600 / Meist. 4.900
            Ring         = { 84575, 84577 },      -- Beweglichkeit, alternativ Ausdauer
        },
        bestGems = {
            meta      = { 76884, 76895 },
            rot       = { 76693, 76692 },         -- Präziser Rubellit (Waffenkunde-Cap)
            gelb      = { 76699, 76697 },         -- Spiegelnder Goldberyll (Tempo)
            blau      = { 76680 },
            orange    = { 76667, 76659 },         -- Tückischer Aragonit (Waffk.+Tempo)
            lila      = { 76681, 76680 },         -- Akkurater Kunzit (Waffk.+Treffer)
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Offensiv: Nach Hit/Waffenkunde-Cap Tempo (bis ~4000) > Krit. Meisterschaft nur im nötigen Minimum, Rest in Krit/Tempo.",
    },

    DRUID_GUARDIAN_OFFENSIVE = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 15, note = "Hard-Cap 15% Waffenkunde (laut Guide Ziel, nicht nur 7,5%)" },
        },
        statWeights = {
            hit = 100, expertise = 98, crit = 85, agility = 60,
            haste = 45, stamina = 25, dodge = 15, mastery = 15,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4804, 4805 },
            Brust        = { 4420, 4419 },        -- Überragende Ausdauer
            Umhang       = { 74711 },             -- Großer Schutz
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4431 },
            Beine        = { 4822, 4824 },
            ["Füße"]     = { 4425, 4428 },  -- Bewegl. 8.400 / Meist. 2.100
            Ring         = { 84575, 84577 },      -- Beweglichkeit, alternativ Ausdauer
        },
        bestGems = {
            meta      = { 76884, 76895 },
            rot       = { 76693, 76692 },         -- Präziser Rubellit (Waffenkunde-Cap)
            gelb      = { 76697, 76699 },
            blau      = { 76636, 76639 },         -- Massiver Chrysokoll (reiner Treffer)
            orange    = { 76659, 76658 },         -- Listiger Aragonit (Waffk.+Krit)
            lila      = { 76681, 76680 },         -- Akkurater Kunzit (Waffk.+Treffer)
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Offensiv: Nach Treffer(7,5%)/Waffenkunde(15%)-Cap Krit (Wut-Generierung) > Beweglichkeit > Tempo.",
    },

}

--------------------------------------------------
-- DATEN-VALIDATOR (Drift-Schutz)
-- Prüft beim Laden, ob jede in den Spec-Profilen referenzierte
-- Verzauberungs-/Stein-ID auch in enchants.lua / gems.lua existiert.
-- Verhindert, dass gelöschte/umbenannte IDs (wie früher 4412)
-- unbemerkt als "Unbekannt (ID …)" in Empfehlungen auftauchen.
-- Wird von core/main.lua bei PLAYER_LOGIN aufgerufen, wenn alle
-- Datentabellen geladen sind. Gibt nur bei Problemen etwas aus.
--------------------------------------------------

--------------------------------------------------
-- WÄCHTER: Empfehlung gegen die eigenen Gewichte
--
-- Der Anlass ist der Bericht vom 21.08.2026: einem korrekt verzauberten
-- Elementarschamanen wurde seine Stiefelverzauberung als Mangel gemeldet.
-- Dahinter stand ein falscher Wert in data/enchants.lua (Pandarenpfoten
-- mit 175 statt 140 Meisterschaft) — und niemand konnte das sehen, weil
-- die Empfehlungsliste von Hand gepflegt wird und mit den statWeights
-- desselben Profils nirgends abgeglichen wurde. Genau das passiert hier.
--
-- Verglichen wird NUR, wo der Vergleich wirklich trägt: Verzauberungen
-- desselben Slots, die genau EINEN Sekundärwert geben, der für diese Spec
-- nicht auf ein Cap läuft. Primärwerte (Stärke/Beweglichkeit/Intelligenz),
-- Ausdauer und Ausweichwerte bleiben aussen vor — für sie sind die
-- Gewichte Prioritäten und keine Umrechnungskurse, ein Vergleich "240
-- Ausdauer × 100 schlägt 160 Stärke × 45" wäre reine Arithmetik ohne
-- Aussage. Deshalb steigt die Prüfung auch aus, sobald die erste
-- Empfehlung selbst kein solcher Sekundärwert-Eintrag ist.
--
-- Zwei Aussagen werden geprüft:
--   1) VOLLSTÄNDIGKEIT — was mehr als die Hälfte der ersten Empfehlung
--      wert ist, muss mit in der Liste stehen. Alles, was fehlt, meldet
--      das Addon dem Spieler als Mangel; ein Mangel muss einer sein.
--   2) REIHENFOLGE — die erste Empfehlung darf nicht um mehr als ein
--      Viertel geschlagen werden. Ein Viertel, weil genau das der
--      Abstand zwischen 140 und 175 Wertung ist: darunter entscheiden
--      Lauftempo und Tempo-Breakpoints, und beides kennt dieses Modell
--      nicht.
--
-- Mehrfach vergebene IDs derselben Verzauberung (74715/4426 "Großes
-- Tempo", 4422/4424, 4423/4892, 4432/4434) zählen als ein Eintrag —
-- sonst meldete der Wächter eine Lücke, wo dieselbe Verzauberung unter
-- ihrer anderen ID längst gelistet ist.
--------------------------------------------------

local COMPARABLE_STATS = { mastery = true, haste = true, crit = true }

-- Träger des Lauftempos. Für den Vergleich sind sie normale Einträge; die
-- Toleranz von 25 % gilt ohnehin für jede erste Empfehlung, weil das
-- Modell in diesem Abstand nichts zu sagen hat.
local ORDER_TOLERANCE    = 1.25
local COMPLETENESS_RATIO = 0.5

-- Genau ein Sekundärwert? Dann Name des Stats und Höhe zurückgeben.
local function SingleSecondary(entry)
    if not entry or not entry.stats then return nil end
    local statKey, statValue, count = nil, nil, 0
    for k, v in pairs(entry.stats) do
        statKey, statValue, count = k, v, count + 1
    end
    if count ~= 1 or not COMPARABLE_STATS[statKey] then return nil end
    return statKey, statValue
end

function WeintCodex_ValidateEnchantWeights()
    local enchants = WeintCodex_Enchants or {}
    local problems = {}

    for specKey, profile in pairs(WeintCodex_SpecProfiles) do
        local weights = profile.statWeights
        if weights and profile.bestEnchants then

            -- Gecappte Stats dieser Spec. Willenskraft zählt mit, wo sie
            -- als Treffer gilt (Elementarpräzision, Ausgeglichenheit der
            -- Macht) - sonst wäre sie hier ein freier Sekundärwert.
            local capped = {}
            for _, cap in ipairs(profile.caps or {}) do
                capped[cap.stat] = true
                if cap.spiritZaehlt then capped.spirit = true end
            end

            for slot, list in pairs(profile.bestEnchants) do
                local firstEntry = enchants[list[1]]
                local firstStat, firstValue = SingleSecondary(firstEntry)

                if firstStat and not capped[firstStat] then
                    local firstScore = firstValue * (weights[firstStat] or 0)

                    -- Was ist bereits gelistet - nach Name, nicht nach ID.
                    local listed = {}
                    for _, id in ipairs(list) do
                        local e = enchants[id]
                        if e and e.name then listed[e.name] = true end
                    end

                    -- Und dieselbe Verzauberung nur einmal melden: "Großes
                    -- Tempo" steht unter 74715 UND 4426 in der Tabelle.
                    local reported = {}

                    for id, entry in pairs(enchants) do
                        if entry.slot == slot then
                            local statKey, statValue = SingleSecondary(entry)
                            if statKey and not capped[statKey] then
                                local score = statValue * (weights[statKey] or 0)

                                if reported[entry.name] then
                                    -- schon gemeldet, andere ID derselben Verzauberung
                                elseif score > firstScore * ORDER_TOLERANCE then
                                    reported[entry.name] = true
                                    problems[#problems + 1] = string.format(
                                        "%s / %s: erste Empfehlung %s liegt hinter %s (%d zu %d)",
                                        specKey, tostring(slot),
                                        tostring(firstEntry.name), tostring(entry.name),
                                        firstScore, score)
                                elseif not listed[entry.name]
                                       and score > firstScore * COMPLETENESS_RATIO then
                                    reported[entry.name] = true
                                    problems[#problems + 1] = string.format(
                                        "%s / %s: %s (%d) fehlt in der Liste - wird dem Spieler als Mangel gemeldet",
                                        specKey, tostring(slot),
                                        tostring(entry.name), score)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if #problems > 0 then
        print("|cffD4A24A[WeintCodex]|r |cffff5555Datenprüfung: "
            .. #problems .. " Empfehlung(en) widersprechen den eigenen Gewichten:|r")
        for _, msg in ipairs(problems) do
            print("  |cffff9900" .. msg .. "|r")
        end
    end
    return problems
end

--------------------------------------------------
-- STEINDATEN GEGEN SICH SELBST PRÜFEN
--
-- Für Verzauberungen gibt es diese Prüfung seit 2.3.1.0
-- (WeintCodex_ValidateEnchantWeights). Für Steine gab es sie nicht — und
-- genau die Lücken, die sie gefunden hätte, sind es, an denen die
-- Sockelseite über fünf Releases hinweg falsch bewertet hat:
--
--   * 21 von 39 Profilen führen unter `blau` ausschliesslich Treffer- oder
--     Waffenkundesteine. Am Cap war deren Wertung 0, und bis 2.5.0.0
--     erklärte das Addon den Sockelbonus damit auf jedem Gegenstand mit
--     blauem Sockel für wertlos. Der Kopf dieser Datei verlangt seit
--     2.3.0.1, dass die Liste "bis zum Ende trägt" — nichts prüfte es.
--   * `data/gems.lua` behauptet Farben, die aus den Werten nicht folgen
--     können (76589: "grün" mit Treffer + Ausdauer, beides blaue Werte).
--   * Ein Juwelier-Schlangenauge als einzige Empfehlung einer Farbe ist
--     für alle Nicht-Juweliere gar keine Empfehlung.
--   * Und ein Profil, dessen Gewichte seiner eigenen ersten Empfehlung
--     widersprechen, hat entweder die falsche Liste oder das falsche
--     Gewicht — beides will man wissen, bevor jemand es meldet.
--
-- Gemeldet, nicht repariert: eine Zahl in diesen Dateien ist eine Aussage
-- über das Spiel, und die trifft ein Mensch.
--------------------------------------------------

-- MoP-Farbalgebra, abgelesen an den Grundschliffen des Spiels:
--   rot  Bold/Delicate/Brilliant (Primärwert), Precise (Waffenkunde),
--        Flashing (Parieren)
--   gelb Smooth (Krit), Quick (Tempo), Fractured (Meisterschaft),
--        Subtle (Ausweichen)
--   blau Solid (Ausdauer), Sparkling (Willenskraft), Rigid (Treffer)
-- Die Mischfarben tragen je einen Wert aus beiden Töpfen.
local GEM_STAT_COLOR = {
    strength = "rot", agility = "rot", intellect = "rot",
    expertise = "rot", parry = "rot",
    crit = "gelb", haste = "gelb", mastery = "gelb", dodge = "gelb",
    stamina = "blau", spirit = "blau", hit = "blau",
}

local MIXED_COLOR = {
    orange   = { rot = true, gelb = true },
    lila     = { rot = true, blau = true },
    ["grün"] = { gelb = true, blau = true },
}

-- Bedient ein Stein DIESER Farbe einen Sockel JENER Farbe? Dieselbe Regel
-- wie SOCKET_ACCEPTS in modules/charakter.lua — hier noch einmal, weil
-- data/ nicht auf modules/ zugreifen darf (Ladereihenfolge der .toc).
local SOCKET_ACCEPTS_DATA = {
    rot  = { rot = true,  orange = true, lila = true },
    gelb = { gelb = true, orange = true, ["grün"] = true },
    blau = { blau = true, lila = true,   ["grün"] = true },
}

local function ColorServesSocket(gemColor, socketColor)
    if not gemColor then return false end
    if gemColor == "prismatic" or gemColor == "einfach" then return true end
    local accepts = SOCKET_ACCEPTS_DATA[socketColor]
    return (accepts and accepts[gemColor]) == true
end

function WeintCodex_ValidateGemWeights()
    local gems     = WeintCodex_Gems or {}
    local gemStats = WeintCodex_GemStats or {}
    local problems = {}

    -- 1) Farbe gegen Werte (data/gems.lua gegen data/gem_stats.lua)
    for id, gem in pairs(gems) do
        local stats = gemStats[id]
        local color = gem.color
        if stats and color and color ~= "meta" and color ~= "prismatic"
           and color ~= "einfach" then
            local buckets = {}
            for stat in pairs(stats) do
                local b = GEM_STAT_COLOR[stat]
                if b then buckets[b] = true end
            end
            local allowed = MIXED_COLOR[color]
            if allowed then
                -- Mischfarbe: MUSS beide Grundtöpfe bedienen.
                for b in pairs(buckets) do
                    if not allowed[b] then
                        problems[#problems + 1] = string.format(
                            "gems.lua %d (%s): Farbe %s, liefert aber %s-Werte",
                            id, tostring(gem.name), color, b)
                    end
                end
                local n = 0
                for _ in pairs(buckets) do n = n + 1 end
                if n < 2 then
                    local only = next(buckets)
                    problems[#problems + 1] = string.format(
                        "gems.lua %d (%s): Farbe %s verlangt zwei Grundfarben,"
                        .. " die Werte sind aber nur %s",
                        id, tostring(gem.name), color, tostring(only))
                end
            else
                for b in pairs(buckets) do
                    if b ~= color then
                        problems[#problems + 1] = string.format(
                            "gems.lua %d (%s): Farbe %s, liefert aber %s-Werte",
                            id, tostring(gem.name), color, b)
                    end
                end
            end
        end
    end

    -- 2) Profile
    for specKey, profile in pairs(WeintCodex_SpecProfiles) do
        local best    = profile.bestGems
        local weights = profile.statWeights
        if best and weights then
            local capped = {}
            for _, cap in ipairs(profile.caps or {}) do
                capped[cap.stat] = true
                if cap.spiritZaehlt then capped.spirit = true end
            end

            local function Score(id, ignoreCapped)
                local st = gemStats[id]
                if not st then return nil end
                local total = 0
                for stat, value in pairs(st) do
                    if not (ignoreCapped and capped[stat]) then
                        total = total + value * (weights[stat] or 0)
                    end
                end
                return total
            end

            for _, color in ipairs({ "rot", "gelb", "blau", "prismatic" }) do
                local list = best[color]
                if list and #list > 0 then
                    -- a) Fehlt ein Stein in gem_stats.lua? (ValidateSpecData
                    --    prüft nur gegen gems.lua)
                    for _, id in ipairs(list) do
                        if not gemStats[id] then
                            problems[#problems + 1] = string.format(
                                "%s / %s: Stein-ID %d fehlt in gem_stats.lua",
                                specKey, color, id)
                        end
                    end

                    -- b) Bleibt am Cap überhaupt ein Stein übrig, der die
                    --    Farbe dieses Sockels bedient?
                    --
                    --    Bis 2.5.0.0 zählte dafür nur die Farbliste selbst,
                    --    und 21 von 39 Profilen führen unter `blau` nur
                    --    Treffer- oder Waffenkundesteine — am Cap fiel deren
                    --    Wertung auf 0 und der Sockelbonus galt pauschal als
                    --    wertlos. Der Planer sucht inzwischen im ganzen Topf
                    --    des Profils nach einem farblich passenden Stein,
                    --    also wird auch hier der Topf gefragt. Und gefragt
                    --    wird, was der Planer fragt: bleibt am Cap noch
                    --    WERTUNG übrig? Nicht mehr "gibt es einen Stein ganz
                    --    ohne gecappten Stat" — ein Hybridstein behält seine
                    --    andere Hälfte, das ist der Sinn des Spielraums.
                    if next(capped) and color ~= "prismatic" then
                        local free = false
                        for listColor, other in pairs(best) do
                            if listColor ~= "meta" then
                                for _, id in ipairs(other) do
                                    local st = gemStats[id]
                                    local gemColor = gems[id] and gems[id].color
                                    if st and ColorServesSocket(gemColor, color) then
                                        local left = Score(id, true)
                                        if left and left > 0 then free = true end
                                    end
                                end
                            end
                        end
                        if not free then
                            problems[#problems + 1] = string.format(
                                "%s / %s: am Cap bleibt im ganzen Profil kein"
                                .. " farblich passender Stein - der Sockelbonus"
                                .. " ist dort nicht zu halten",
                                specKey, color)
                        end
                    end

                    -- c) Nur Juwelier-Steine ist fuer alle anderen nichts.
                    local nonJc = false
                    for _, id in ipairs(list) do
                        if not (gems[id] and gems[id].jcOnly) then nonJc = true end
                    end
                    if not nonJc then
                        problems[#problems + 1] = string.format(
                            "%s / %s: nur Juwelier-Steine empfohlen",
                            specKey, color)
                    end

                    -- d) Widerspricht das Profil seiner eigenen ersten
                    --    Empfehlung? Gerechnet ohne die gecappten Stats,
                    --    weil die am Cap ohnehin nichts beitragen.
                    --    Nur der staerkste Widerspruch je Liste: sonst
                    --    meldet eine Liste mit drei besseren Eintraegen
                    --    dreimal dasselbe.
                    local firstId = list[1]
                    local firstScore = Score(firstId, true)
                    if firstScore and firstScore > 0 then
                        local worstId, worstScore = nil, firstScore * 1.25
                        for _, id in ipairs(list) do
                            local s = Score(id, true)
                            if s and s > worstScore
                               and not (gems[id] and gems[id].jcOnly) then
                                worstId, worstScore = id, s
                            end
                        end
                        if worstId then
                            problems[#problems + 1] = string.format(
                                "%s / %s: %s steht vorn, %s ist nach den"
                                .. " eigenen Gewichten aber %.0f%% besser",
                                specKey, color,
                                tostring(gems[firstId] and gems[firstId].name or firstId),
                                tostring(gems[worstId] and gems[worstId].name or worstId),
                                (worstScore / firstScore - 1) * 100)
                        end
                    end
                end
            end
        end
    end

    if #problems > 0 then
        print("|cffD4A24A[WeintCodex]|r |cffff5555Steinprüfung: "
            .. #problems .. " Befund(e):|r")
        for _, msg in ipairs(problems) do
            print("  |cffff9900" .. msg .. "|r")
        end
    end
    return problems
end

function WeintCodex_ValidateSpecData()
    local enchants = WeintCodex_Enchants or {}
    local gems     = WeintCodex_Gems or {}
    local problems = {}

    for specKey, profile in pairs(WeintCodex_SpecProfiles) do
        if profile.bestEnchants then
            for slot, list in pairs(profile.bestEnchants) do
                for _, id in ipairs(list) do
                    if not enchants[id] then
                        problems[#problems + 1] = string.format(
                            "%s / Verzauberung %s: ID %d fehlt in enchants.lua",
                            specKey, tostring(slot), id)
                    end
                end
            end
        end
        if profile.bestGems then
            for color, list in pairs(profile.bestGems) do
                for _, id in ipairs(list) do
                    if not gems[id] then
                        problems[#problems + 1] = string.format(
                            "%s / Sockel %s: Stein-ID %d fehlt in gems.lua",
                            specKey, tostring(color), id)
                    end
                end
            end
        end
    end

    if #problems > 0 then
        print("|cffD4A24A[WeintCodex]|r |cffff5555Datenprüfung: "
            .. #problems .. " ungültige ID-Referenz(en):|r")
        for _, msg in ipairs(problems) do
            print("  |cffff9900" .. msg .. "|r")
        end
    end
    return problems
end
