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
--   bestGems     = { [Sockelfarbe] = { id1, id2, ... } }
--                  -> Schlüssel: meta, rot, gelb, blau, orange, lila,
--                     grün, prismatic. Alle IDs gelten als "optimal".
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
        statWeights = {
            strength = 100, hit = 88, expertise = 85,
            crit = 80, mastery = 65, haste = 55, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },       -- Tanzender Stahl / Elementarkraft
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },       -- Krit zuerst, dann Präzision (Treffer)
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4434 },
            Beine        = { 4823 },
            ["Füße"]     = { 4429, 4428 },       -- Pandarenpfoten, dann Große Präzision
        },
        -- Krit ist der beste Sekundärstat -> überall Glatter Goldberyll.
        -- Sockelboni matchen, wenn sie sich lohnen: Rot -> Gravierter
        -- Aragonit (Str+Krit), Blau -> Stechender Dioptas (Krit+Treffer).
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76661, 76693, 76696 },  -- match: Gravierter Aragonit; Präziser Rubellit (Waffenkunde-Cap); Klobiger
            gelb      = { 76697, 83146 },         -- Glatter Goldberyll (Krit) / JC-Schlangenauge
            blau      = { 76641, 76636 },         -- Stechender Dioptas (match); Massiver Chrysokoll (Treffer-Cap)
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
        statWeights = {
            strength = 100, hit = 88, expertise = 85,
            crit = 82, mastery = 62, haste = 58, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },       -- Krit zuerst, dann Präzision (Treffer)
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4434 },
            Beine        = { 4823 },
            ["Füße"]     = { 4429, 4428 },       -- Pandarenpfoten, dann Große Präzision
        },
        -- Krit überall; 1 Krit ~ 1,07 Stärke. Sockelboni matchen, wenn
        -- sie sich lohnen: Rot -> Gravierter Aragonit, Blau -> Stechender Dioptas.
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76661, 76693, 76696 },
            gelb      = { 76697, 83146 },
            blau      = { 76641, 76636 },
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
            { stat = "expertise",                pct = 7.5, note = "Hard-Cap 15% (Parieren) optional" },
        },
        statWeights = {
            stamina = 100, hit = 90, expertise = 88, parry = 70,
            strength = 60, dodge = 55, mastery = 45, crit = 20, haste = 15,
        },
        bestEnchants = {
            Waffe        = { 4444, 4445 },        -- Tanzender Stahl (Fallback: Koloss)
            Schultern    = { 4805 },
            Brust        = { 4420, 4419 },        -- Defensiv: Überragende Ausdauer
            Umhang       = { 74711 },             -- Großer Schutz (+200 Ausdauer)
            Handgelenke  = { 4411, 4415 },        -- Meisterschaft
            ["Hände"]    = { 4432, 4431 },        -- Defensiv: Überragende Meisterschaft
            Beine        = { 4824 },              -- Eisenschuppenbeinrüstung
            ["Füße"]     = { 4429, 4426 },        -- Pandarenpfoten
        },
        -- Defensiv (Ausdauer-Fokus): Gediegener Chrysokoll überall.
        -- Sockelboni matchen, wenn lohnend: Rot -> Kunzit des Verteidigers,
        -- Orange -> Bruchfester Aragonit, Grün -> Perfekter Alexandrit.
        bestGems = {
            meta      = { 76895, 95344 },
            rot       = { 76690, 76695, 76691 },  -- Kunzit d. Verteidigers (Parieren+Ausdauer); Parieren; Str+Ausdauer
            gelb      = { 76589, 76698 },         -- Perfekter Alexandrit (Treffer+Ausdauer); Ausweichen
            blau      = { 76639, 76636 },         -- Gediegener Chrysokoll (Ausdauer); Massiver (Treffer)
            orange    = { 76664 },                -- Bruchfester Aragonit (Parieren+Ausweichen)
            lila      = { 76690, 76683 },         -- Kunzit d. Verteidigers; Fixierender (Parieren+Treffer)
            ["grün"]  = { 76589, 76656 },         -- Perfekter Alexandrit; Imposanter (Meister+Ausdauer)
            prismatic = { 76639 },                -- Ausdauer universell
        },
        gemNote = "Defensiv: Ausdauer überall (Gediegener Chrysokoll), nach 7,5% Treffer/Waffenkunde Parieren/Ausweichen. Sockelbonus nur matchen, wenn er sich lohnt.",
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },        -- Großes Tempo
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 4426 },        -- Pandarenpfoten
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
            Schultern    = { 4805 },
            Brust        = { 4420, 4419 },        -- Überragende Ausdauer
            Umhang       = { 74711 },             -- Großer Schutz
            Handgelenke  = { 4411, 4415 },        -- Meisterschaft
            ["Hände"]    = { 4432, 4431 },        -- Überragende Meisterschaft
            Beine        = { 4824 },              -- Eisenschuppenbeinrüstung
            ["Füße"]     = { 4429, 4426 },        -- Pandarenpfoten
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
            ["Hände"]    = { 4434, 4433 },
            Beine        = { 4823 },
            ["Füße"]     = { 74715, 4428 },       -- Großes Tempo (Boots-Haste)
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
        caps = {
            { stat = "hit",       typ = "ranged", pct = 7.5 },
            { stat = "expertise",                 pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88, expertise = 85,
            crit = 75, haste = 68, mastery = 60, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4699, 4700, 4443 },  -- Zielfernrohre!
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },
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
        gemNote = "Beweglichkeit überall (Feingeschliffener Rubellit / Tödlicher Aragonit). Jäger brauchen 7,5% Treffer UND 7,5% Waffenkunde.",
    },

    HUNTER_MARKSMANSHIP = {
        role = "RANGED",
        caps = {
            { stat = "hit",       typ = "ranged", pct = 7.5 },
            { stat = "expertise",                 pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88, expertise = 85,
            crit = 80, haste = 65, mastery = 55, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4699, 4700, 4443 },
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },
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
        gemNote = "Beweglichkeit > Krit. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
    },

    HUNTER_SURVIVAL = {
        role = "RANGED",
        caps = {
            { stat = "hit",       typ = "ranged", pct = 7.5 },
            { stat = "expertise",                 pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 88, expertise = 85,
            crit = 70, haste = 62, mastery = 50, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4699, 4700, 4443 },
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },
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
        gemNote = "Beweglichkeit > Krit > Tempo > Meisterschaft (Einzelziel). Meisterschaft stärker im AoE. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
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
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },        -- Präzision (Treffer)
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },
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
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },        -- Präzision (Treffer)
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },
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
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },        -- Präzision (Treffer)
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4432, 4433 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4432, 4433 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 4426 },
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
            { stat = "expertise",                pct = 7.5, note = "Hard-Cap 15% (Parieren) optional" },
        },
        -- "Most Defensive"-Prioritätsreihe: Ausdauer > Meisterschaft > Parieren >
        -- Stärke > Treffer/Waffenkunde(7,5%) > Tempo > Ausweichen > Krit.
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
            ["Hände"]    = { 4433, 4431 },        -- Großes Tempo
            Beine        = { 4823, 4824 },        -- Zornbalgbeinrüstung
            ["Füße"]     = { 74715, 4426 },       -- Großes Tempo (Boots-Haste)
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
        gemNote = "Defensiv: Ausdauer > Meisterschaft (Blutschild) > Parieren > Stärke, nach Treffer/Waffenkunde-Cap.",
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
            ["Hände"]    = { 4434, 4433 },
            Beine        = { 4823 },
            ["Füße"]     = { 4429, 4428 },        -- Pandarenpfoten
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
            ["Hände"]    = { 4434, 4433 },
            Beine        = { 4823 },
            ["Füße"]     = { 4429, 4428 },        -- Pandarenpfoten
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },        -- Großes Tempo
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4826, 4825 },
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4826, 4825 },
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4805, 4806 },
            Brust        = { 4419, 4420 },
            Umhang       = { 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431, 4433 },
            Beine        = { 4824, 4822 },
            ["Füße"]     = { 4426, 4425, 4428 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4432, 4433 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 74715, 4429 },       -- Großes Tempo (Boots-Haste)
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
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4826, 4825 },        -- Großer himmelblauer/zerulanblauer Zauberfaden (Krit)
            ["Füße"]     = { 4429, 4426 },
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
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },        -- Präzision (Treffer)
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431 },              -- Überragende Waffenkunde
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4428 },
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
            Schultern    = { 4805, 4806 },
            Brust        = { 4419, 4420 },
            Umhang       = { 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4431, 4433 },
            Beine        = { 4824, 4822 },
            ["Füße"]     = { 4426, 4425, 4428 },
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
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]    = { 4432, 4433 },
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 4426 },
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
            { stat = "expertise",                pct = 7.5, note = "Hard-Cap 15% (Parieren) empfohlen" },
        },
        statWeights = {
            hit = 100, expertise = 98, crit = 90, parry = 62,
            dodge = 58, strength = 54, mastery = 48, haste = 40, stamina = 35,
        },
        bestEnchants = {
            Waffe        = { 4444, 4445 },
            Schultern    = { 4803, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },       -- Offensiv: Krit
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4431, 4434 },
            Beine        = { 4823, 4824 },
            ["Füße"]     = { 74715, 4428 },       -- Offensiv: Großes Tempo (Boots-Haste)
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
        gemNote = "Offensiv: Krit überall nach 7,5% Treffer/Waffenkunde. Sockelbonus nur matchen, wenn er sich lohnt.",
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
            Schultern    = { 4803, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4415 },
            ["Hände"]    = { 4431, 4434 },        -- Offensiv: Überragende Waffenkunde
            Beine        = { 4823, 4824 },
            ["Füße"]     = { 74715, 4428 },       -- Großes Tempo (Boots-Haste)
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
            { stat = "expertise",                pct = 7.5, note = "Hard-Cap 15% (Parieren) empfohlen" },
        },
        -- "Offensive"-Prioritätsreihe: Treffer/Waffenkunde(7,5%) > Krit >
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
            ["Füße"]     = { 74715, 4426 },       -- Großes Tempo (Boots-Haste)
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
        gemNote = "Offensiv: Nach Treffer/Waffenkunde-Cap Krit > Tempo. Meisterschaft ist hier der schwächste Stat.",
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
            Schultern    = { 4806, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4431 },
            Beine        = { 4822, 4824 },
            ["Füße"]     = { 4425, 4428 },
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
            Schultern    = { 4806, 4805 },
            Brust        = { 4420, 4419 },        -- Überragende Ausdauer
            Umhang       = { 74711 },             -- Großer Schutz
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4431 },
            Beine        = { 4822, 4824 },
            ["Füße"]     = { 4425, 4428 },
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
        print("|cffC8763A[WeintCodex]|r |cffff5555Datenprüfung: "
            .. #problems .. " ungültige ID-Referenz(en):|r")
        for _, msg in ipairs(problems) do
            print("  |cffff9900" .. msg .. "|r")
        end
    end
    return problems
end
