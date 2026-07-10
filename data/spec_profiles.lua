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
            Umhang       = { 4421, 4422 },
            Handgelenke  = { 4412 },
            ["Hände"]    = { 4434 },
            Beine        = { 4823 },
            ["Füße"]     = { 4428, 4429 },
        },
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76696, 83141 },
            gelb      = { 76697, 76699 },
            blau      = { 76684 },
            orange    = { 76661, 76669, 76674 },
            lila      = { 76684, 76691 },
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Stärke > Krit. Erst 7,5% Treffer + 7,5% Waffenkunde, dann Krit sockeln.",
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
            Umhang       = { 4421, 4422 },
            Handgelenke  = { 4412 },
            ["Hände"]    = { 4434 },
            Beine        = { 4823 },
            ["Füße"]     = { 4428, 4429 },
        },
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76696, 83141 },
            gelb      = { 76697, 76699 },
            blau      = { 76684 },
            orange    = { 76661, 76669 },
            lila      = { 76684, 76691 },
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Stärke > Krit. Beide Waffen Tanzender Stahl. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
    },

    WARRIOR_PROTECTION = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5, note = "Hard-Cap 15% (Parieren) optional" },
        },
        statWeights = {
            mastery = 95, hit = 90, expertise = 90, stamina = 85,
            parry = 65, dodge = 60, strength = 40, crit = 15, haste = 15,
        },
        bestEnchants = {
            Waffe        = { 4445, 4446, 4444 },  -- Koloss / Lied des Flusses
            Schultern    = { 4805 },
            Brust        = { 4419, 4420 },
            Umhang       = { 4421 },
            Handgelenke  = { 4411, 4412 },
            ["Hände"]    = { 4431, 4432 },
            Beine        = { 4824 },
            ["Füße"]     = { 4426, 4428 },
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
        gemNote = "Treffer/Waffenkunde-Cap, dann Meisterschaft (Schildblock) > Parieren/Ausweichen.",
    },

    --------------------------------------------------
    -- PALADIN
    --------------------------------------------------

    PALADIN_HOLY = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, spirit = 85, haste = 72, mastery = 68,
            crit = 50, stamina = 10,
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
            orange    = { 76668, 76660, 76672 },
            lila      = { 76686 },
            ["grün"]  = { 76651, 76645 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Willenskraft. Heiler brauchen kein Trefferwertungs-Cap.",
    },

    PALADIN_PROTECTION = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5, note = "Hard-Cap 15% (Parieren) optional" },
        },
        statWeights = {
            hit = 95, expertise = 95, haste = 82, mastery = 80,
            stamina = 75, parry = 50, dodge = 45, strength = 40, crit = 20,
        },
        bestEnchants = {
            Waffe        = { 4445, 4446, 4444 },
            Schultern    = { 4805 },
            Brust        = { 4419, 4420 },
            Umhang       = { 4421 },
            Handgelenke  = { 4411, 4412 },
            ["Hände"]    = { 4431, 4433 },
            Beine        = { 4824 },
            ["Füße"]     = { 4426, 4428 },
        },
        bestGems = {
            meta      = { 76895, 95344 },
            rot       = { 76695, 76693 },
            gelb      = { 76700, 76699 },
            blau      = { 76639 },
            orange    = { 76674, 76669 },
            lila      = { 76690, 76684 },
            ["grün"]  = { 76656, 76643 },
            prismatic = { 76639, 76695 },
        },
        gemNote = "Control-Tank: Treffer/Waffenkunde-Cap ist Priorität 1, danach Tempo/Meisterschaft.",
    },

    PALADIN_RETRIBUTION = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            strength = 100, hit = 90, expertise = 88,
            haste = 80, mastery = 70, crit = 65, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },
            Handgelenke  = { 4412 },
            ["Hände"]    = { 4434, 4433 },
            Beine        = { 4823 },
            ["Füße"]     = { 4428, 4429 },
        },
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76696, 83141 },
            gelb      = { 76699, 76697 },
            blau      = { 76684 },
            orange    = { 76669, 76661, 76674 },
            lila      = { 76684, 76691 },
            ["grün"]  = { 76642, 76641 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Stärke > Tempo. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
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
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4430, 4428 },
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
        gemNote = "Beweglichkeit überall. Jäger brauchen 7,5% Treffer UND 7,5% Waffenkunde.",
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
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4430, 4428 },
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
            mastery = 72, crit = 68, haste = 60, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4699, 4700, 4443 },
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4430, 4428 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76700, 76697 },
            blau      = { 76680 },
            orange    = { 76670, 76666 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76643, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit > Meisterschaft. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
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
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4430, 4428 },
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
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4430, 4428 },
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
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4430, 4428 },
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
        gemNote = "Beweglichkeit > Tempo. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
    },

    --------------------------------------------------
    -- PRIESTER
    --------------------------------------------------

    PRIEST_DISCIPLINE = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, spirit = 82, mastery = 72, haste = 62,
            crit = 58, stamina = 10,
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
        gemNote = "Intelligenz > Willenskraft > Meisterschaft (Schilde). Kein Treffer-Cap nötig.",
    },

    PRIEST_HOLY = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, spirit = 80, haste = 72, mastery = 65,
            crit = 50, stamina = 10,
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
            orange    = { 76668, 76660, 76672 },
            lila      = { 76686 },
            ["grün"]  = { 76651, 76645 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Willenskraft > Tempo. Kein Treffer-Cap nötig.",
    },

    PRIEST_SHADOW = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15, spiritZaehlt = true },
        },
        statWeights = {
            intellect = 100, hit = 92, spirit = 88, haste = 85,
            crit = 62, mastery = 60, stamina = 5,
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
            lila      = { 76682, 76686 },
            ["grün"]  = { 76642, 76651 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo. 15% Zaubertreffer — Willenskraft zählt dank Zwielichtgleichgewicht als Treffer!",
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
        statWeights = {
            mastery = 100, hit = 90, expertise = 88, stamina = 80,
            strength = 45, parry = 60, dodge = 55, crit = 15, haste = 20,
        },
        bestEnchants = {
            Waffe        = { 3368, 3847 },        -- Gefallener Kreuzfahrer / Steinhautgargoyle
            Schultern    = { 4805 },
            Brust        = { 4419, 4420 },
            Umhang       = { 4421 },
            Handgelenke  = { 4411, 4412 },
            ["Hände"]    = { 4431, 4432 },
            Beine        = { 4824 },
            ["Füße"]     = { 4426, 4428 },
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
        gemNote = "Meisterschaft (Blutschild) ist Hauptstat nach Treffer/Waffenkunde-Cap.",
    },

    DEATHKNIGHT_FROST = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            strength = 100, hit = 90, expertise = 88,
            mastery = 78, haste = 72, crit = 65, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 3368, 3370 },        -- Fallen Crusader / Razorice (bei Dual-Wield)
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },
            Handgelenke  = { 4412 },
            ["Hände"]    = { 4434, 4433 },
            Beine        = { 4823 },
            ["Füße"]     = { 4428, 4429 },
        },
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76696, 83141 },
            gelb      = { 76700, 76697 },
            blau      = { 76684 },
            orange    = { 76674, 76669 },
            lila      = { 76684, 76691 },
            ["grün"]  = { 76643, 76641 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Stärke > Meisterschaft. Dual-Wield: Gefallener Kreuzfahrer + Razorice.",
    },

    DEATHKNIGHT_UNHOLY = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            strength = 100, hit = 90, expertise = 88,
            haste = 78, mastery = 72, crit = 65, stamina = 5,
        },
        bestEnchants = {
            Waffe        = { 3368 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421, 4422 },
            Handgelenke  = { 4412 },
            ["Hände"]    = { 4434, 4433 },
            Beine        = { 4823 },
            ["Füße"]     = { 4428, 4429 },
        },
        bestGems = {
            meta      = { 76886, 95346 },
            rot       = { 76696, 83141 },
            gelb      = { 76699, 76697 },
            blau      = { 76684 },
            orange    = { 76669, 76674 },
            lila      = { 76684, 76691 },
            ["grün"]  = { 76642, 76641 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Stärke > Tempo/Meisterschaft. Rune: Gefallener Kreuzfahrer.",
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
            intellect = 100, hit = 92, spirit = 88, haste = 82,
            mastery = 75, crit = 60, stamina = 5,
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
            orange    = { 76668, 76672 },
            lila      = { 76682, 76686 },
            ["grün"]  = { 76642, 76651 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "15% Zaubertreffer Pflicht — Willenskraft zählt dank Elementarpräzision als Treffer.",
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
            ["Hände"]    = { 4432, 4433 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4430, 4428 },
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
            intellect = 100, spirit = 85, haste = 70, mastery = 68,
            crit = 50, stamina = 10,
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
            orange    = { 76668, 76660, 76672 },
            lila      = { 76686 },
            ["grün"]  = { 76651, 76645 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Willenskraft (Mana-Regeneration). Kein Treffer-Cap nötig.",
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
            intellect = 100, hit = 92, haste = 80, mastery = 75,
            crit = 60, spirit = 10, stamina = 5,
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
            blau      = { 76682, 76636 },
            orange    = { 76668, 76672 },
            lila      = { 76682 },
            ["grün"]  = { 76642, 76641 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz-Stacking. 15% Zaubertreffer Pflicht — überschüssigen Treffer aussockeln!",
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
            intellect = 100, hit = 92, haste = 80, mastery = 72,
            crit = 58, spirit = 10, stamina = 5,
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
            blau      = { 76682, 76636 },
            orange    = { 76668, 76672 },
            lila      = { 76682 },
            ["grün"]  = { 76642, 76641 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo. 15% Zaubertreffer Pflicht.",
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
            intellect = 100, hit = 92, mastery = 80, haste = 75,
            crit = 55, spirit = 10, stamina = 5,
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
            blau      = { 76682, 76636 },
            orange    = { 76672, 76668 },
            lila      = { 76682 },
            ["grün"]  = { 76643, 76642 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Meisterschaft. 15% Zaubertreffer Pflicht.",
    },

    WARLOCK_DEMONOLOGY = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15 },
        },
        statWeights = {
            intellect = 100, hit = 92, mastery = 80, haste = 72,
            crit = 58, spirit = 10, stamina = 5,
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
            blau      = { 76682, 76636 },
            orange    = { 76672, 76668 },
            lila      = { 76682 },
            ["grün"]  = { 76643, 76642 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Meisterschaft (Besessenheit). 15% Zaubertreffer Pflicht.",
    },

    WARLOCK_DESTRUCTION = {
        role = "CASTER",
        caps = {
            { stat = "hit", typ = "spell", pct = 15 },
        },
        statWeights = {
            intellect = 100, hit = 92, crit = 78, mastery = 72,
            haste = 65, spirit = 10, stamina = 5,
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
            gelb      = { 76697, 76700 },
            blau      = { 76682, 76636 },
            orange    = { 76660, 76672 },
            lila      = { 76682 },
            ["grün"]  = { 76641, 76643 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Krit (Verheerung/Glutbildung). 15% Zaubertreffer Pflicht.",
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
            intellect = 100, spirit = 80, haste = 72, mastery = 60,
            crit = 55, stamina = 10,
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
            orange    = { 76668, 76660, 76672 },
            lila      = { 76686 },
            ["grün"]  = { 76651, 76645 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Willenskraft > Tempo. Kein Treffer-Cap nötig.",
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
            ["Füße"]     = { 4425, 4430, 4428 },
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
        gemNote = "Beweglichkeit > Tempo. Beide Waffen Tanzender Stahl. Caps: 7,5% Treffer / 7,5% Waffenkunde.",
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
            Beine        = { 4825, 4826 },
            ["Füße"]     = { 4429, 4426 },
        },
        bestGems = {
            meta      = { 76885, 95347 },
            rot       = { 76694, 83150 },
            gelb      = { 76699, 76700 },
            blau      = { 76682, 76636, 76638 },
            orange    = { 76668, 76660 },
            lila      = { 76682, 76686 },
            ["grün"]  = { 76642, 76651 },
            prismatic = { 76694, 83150 },
        },
        gemNote = "Intelligenz > Tempo (Breakpoints!). Willenskraft zählt als Zaubertreffer (15% Cap).",
    },

    DRUID_FERAL = {
        role = "MELEE",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            agility = 100, hit = 75, expertise = 72,
            crit = 78, mastery = 70, haste = 60, stamina = 10,
        },
        bestEnchants = {
            Waffe        = { 4444, 4443 },
            Schultern    = { 4806 },
            Brust        = { 4419 },
            Umhang       = { 4422, 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]    = { 4433, 4432 },
            Beine        = { 4822 },
            ["Füße"]     = { 4425, 4430, 4428 },
        },
        bestGems = {
            meta      = { 76884, 95346 },
            rot       = { 76692, 83151 },
            gelb      = { 76697, 76700 },
            blau      = { 76680 },
            orange    = { 76658, 76670 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76641, 76643 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Beweglichkeit überall. Treffer/Waffenkunde weniger kritisch als bei anderen Melees.",
    },

    DRUID_GUARDIAN = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            agility = 88, hit = 85, expertise = 85, crit = 75,
            mastery = 70, stamina = 80, haste = 30, dodge = 40,
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
        gemNote = "Beweglichkeit/Krit (Wilde Verteidigung) nach Treffer/Waffenkunde-Cap.",
    },

    DRUID_RESTORATION = {
        role = "HEALER",
        caps = {},
        statWeights = {
            intellect = 100, spirit = 82, mastery = 72, haste = 70,
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
        gemNote = "Intelligenz > Willenskraft > Meisterschaft (Lebensblüte). Kein Treffer-Cap nötig.",
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
            hit = 100, expertise = 98, strength = 90, mastery = 70,
            crit = 55, haste = 40, stamina = 35, parry = 25, dodge = 20,
        },
        bestEnchants = {
            Waffe        = { 4444, 4445 },
            Schultern    = { 4803, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]    = { 4431, 4434 },
            Beine        = { 4823, 4824 },
            ["Füße"]     = { 4428, 4426 },
        },
        bestGems = {
            meta      = { 76886, 76895 },
            rot       = { 76696, 83141 },
            gelb      = { 76697, 76700 },
            blau      = { 76684 },
            orange    = { 76661, 76674 },
            lila      = { 76684, 76681 },
            ["grün"]  = { 76641, 76643 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Offensiv: Nach Hit/Waffenkunde-Cap Stärke stacken. Mehr Bedrohung & DPS.",
    },

    PALADIN_PROTECTION_OFFENSIVE = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5, note = "Hard-Cap 15% (Parieren) empfohlen" },
        },
        statWeights = {
            hit = 100, expertise = 98, haste = 88, strength = 80,
            mastery = 70, crit = 40, stamina = 35, parry = 20, dodge = 15,
        },
        bestEnchants = {
            Waffe        = { 4444, 4445 },
            Schultern    = { 4803, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]    = { 4433, 4431 },
            Beine        = { 4823, 4824 },
            ["Füße"]     = { 4428, 4429 },
        },
        bestGems = {
            meta      = { 76886, 76895 },
            rot       = { 76696, 83141 },
            gelb      = { 76699, 76700 },
            blau      = { 76684 },
            orange    = { 76669, 76674 },
            lila      = { 76684, 76681 },
            ["grün"]  = { 76642, 76643 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Offensiv (Haste-Tank): Hit/Waffenkunde-Cap, dann Tempo für Heiligenmacht.",
    },

    DEATHKNIGHT_BLOOD_OFFENSIVE = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5, note = "Hard-Cap 15% (Parieren) empfohlen" },
        },
        statWeights = {
            hit = 100, expertise = 98, strength = 88, mastery = 75,
            haste = 50, crit = 45, stamina = 35, parry = 25, dodge = 20,
        },
        bestEnchants = {
            Waffe        = { 3368, 3847 },
            Schultern    = { 4803, 4805 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]    = { 4431, 4434 },
            Beine        = { 4823, 4824 },
            ["Füße"]     = { 4428, 4426 },
        },
        bestGems = {
            meta      = { 76886, 76895 },
            rot       = { 76696, 83141 },
            gelb      = { 76697, 76700 },
            blau      = { 76684 },
            orange    = { 76661, 76674 },
            lila      = { 76684, 76681 },
            ["grün"]  = { 76641, 76643 },
            prismatic = { 76696, 83141 },
        },
        gemNote = "Offensiv: Stärke nach Hit/Waffenkunde-Cap. Meisterschaft bleibt wertvoll (Blutschild).",
    },

    MONK_BREWMASTER_OFFENSIVE = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            hit = 100, expertise = 98, agility = 90, crit = 70,
            haste = 60, mastery = 55, stamina = 30, dodge = 15,
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
            rot       = { 76692, 83151 },
            gelb      = { 76697, 76699 },
            blau      = { 76680 },
            orange    = { 76658, 76666 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Offensiv: Beweglichkeit + Krit nach Hit/Waffenkunde-Cap.",
    },

    DRUID_GUARDIAN_OFFENSIVE = {
        role = "TANK",
        caps = {
            { stat = "hit",       typ = "melee", pct = 7.5 },
            { stat = "expertise",                pct = 7.5 },
        },
        statWeights = {
            hit = 100, expertise = 98, agility = 90, crit = 78,
            mastery = 55, haste = 40, stamina = 30, dodge = 15,
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
            rot       = { 76692, 83151 },
            gelb      = { 76697, 76699 },
            blau      = { 76680 },
            orange    = { 76658, 76666 },
            lila      = { 76680, 76687 },
            ["grün"]  = { 76641, 76642 },
            prismatic = { 76692, 83151 },
        },
        gemNote = "Offensiv: Beweglichkeit + Krit (Wut-Generierung) nach Hit/Waffenkunde-Cap.",
    },

}
