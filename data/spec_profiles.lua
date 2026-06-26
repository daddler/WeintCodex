--------------------------------------------------
-- WeintCodex :: Spec Profiles
-- Mists of Pandaria Classic
-- Quelle: https://www.wowhead.com/mop-classic/de
--
-- Struktur pro Spec:
--   bestEnchants[slotName] = { id1, id2, ... }
--     -> geordnet: id1 = absolut beste, id2 = Alternative
--   bestGems[socketColor]  = { id1, id2, ... }
--     -> geordnet: id1 = JC-Beste (wenn vorhanden), id2 = reguläre Beste
--   gemNote = "Freitext-Hinweis"
--------------------------------------------------

WeintCodex_SpecProfiles = {

    --------------------------------------------------
    -- WARRIOR
    --------------------------------------------------

    WARRIOR_ARMS = {
        bestEnchants = {
            Waffe        = { 4444, 3368 },   -- Koloss / Tanzender Stahl
            Schultern    = { 4803 },          -- Große Tigerklaueninschrift
            Brust        = { 4419 },          -- Überragende Werte
            Umhang       = { 4421 },          -- Große Präzision
            Handgelenke  = { 4412 },          -- Außergewöhnliche Stärke
            ["Hände"]        = { 4434 },          -- Überragende Stärke
            Beine        = { 4822 },          -- Schattlederbeinschutz
            ["Füße"]         = { 4428 },          -- Große Präzision
        },
        bestGems = {
            meta      = { 76886 },            -- Donnernder Prismatischer Diamant
            rot       = { 83141, 76696 },     -- Kühnes Schlangenaugen / Kühner Primordialrubin
            gelb      = { 76697, 76700 },     -- Blutiger Zinnoberonyx / Gebrochener Sonnenglanz
            blau      = { 76688, 76639 },     -- Kräftiger Kaiserlicher Amethyst / Standhaftes Flussherz
            orange    = { 76667, 76669 },     -- Blutiger Zinnoberonyx / Böser Zinnoberonyx
            lila      = { 76688 },            -- Kräftiger Kaiserlicher Amethyst
            ["grün"]      = { 76657 },            -- Ruhiger Wilder Jade
            prismatic = { 83141, 76696 },
        },
        gemNote = "Alle roten Sockel: Stärke. Sockelbonus nur mitnehmen wenn +10 Stärke oder mehr.",
    },

    WARRIOR_FURY = {
        bestEnchants = {
            Waffe        = { 4444, 3368 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]        = { 4434 },
            Beine        = { 4822 },
            ["Füße"]         = { 4428 },
        },
        bestGems = {
            meta      = { 76886 },
            rot       = { 83141, 76696 },
            gelb      = { 76697, 76700 },     -- Aufgewühlter Zinnoberonyx / Gebrochener Sonnenglanz
            blau      = { 76688, 76639 },
            orange    = { 76669, 76667 },
            lila      = { 76688 },
            ["grün"]      = { 76657 },
            prismatic = { 83141, 76696 },
        },
        gemNote = "Alle roten Sockel: Stärke. Sockelbonus bei +10 Stärke mitnehmen.",
    },

    WARRIOR_PROTECTION = {
        bestEnchants = {
            Waffe        = { 4444 },          -- Koloss
            Schultern    = { 4805 },          -- Große Ochsenhorninschrift
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]        = { 4431 },          -- Große Expertise
            Beine        = { 4824 },          -- Drachenschuppenbeinschutz
            ["Füße"]         = { 4426 },          -- Pandarenpfoten
        },
        bestGems = {
            meta      = { 76895 },            -- Herber Prismatischer Diamant
            rot       = { 76695 },
            gelb      = { 76700 },            -- Gebrochener Sonnenglanz (Meisterschaft)
            blau      = { 76639 },            -- Standhaftes Flussherz
            orange    = { 76657 },
            lila      = { 76688 },            -- Wächter Kaiserlicher Amethyst
            ["grün"]      = { 76657 },
            prismatic = { 76639 },
        },
        gemNote = "Priorität: Trefferwertung/Waffenkunde cap, dann Meisterschaft > Parierchance/Ausweichen.",
    },

    --------------------------------------------------
    -- PALADIN
    --------------------------------------------------

    PALADIN_HOLY = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },    -- Jadegeist / Elementarkraft
            Schultern    = { 4804 },          -- Große Kranichflügelinschrift
            Brust        = { 4419 },
            Umhang       = { 4892 },          -- Überlegene Intelligenz
            Handgelenke  = { 4414 },          -- Überragende Intelligenz
            ["Hände"]        = { 4432 },          -- Überlegene Meisterschaft
            Beine        = { 4823 },          -- Perlmuttbeinschutz
            ["Füße"]         = { 4429 },          -- Pandaren-Schritttempo
        },
        bestGems = {
            meta      = { 76888 },            -- Belebender Prismatischer Diamant
            rot       = { 83150, 76694 },     -- Scharlachrotes Schlangenauge / Scharlachroter Primordialrubin
            gelb      = { 76699, 76700 },     -- Rascher Sonnenstrahl / Frakturierter Sonnenstrahl
            blau      = { 76680, 76638 },     -- Glitzernder Kaiserlicher Amethyst / Funkelndes Flussherz
            orange    = { 76660, 76668 },
            lila      = { 76680 },
            ["grün"]      = { 76657 },
            prismatic = { 83150, 76694 },
        },
        gemNote = "Intelligenz > Meisterschaft/Tempo. Heilige Paladine brauchen kein Trefferwertungscap.",
    },

    PALADIN_PROTECTION = {
        bestEnchants = {
            Waffe        = { 4444 },
            Schultern    = { 4805 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]        = { 4431 },
            Beine        = { 4824 },
            ["Füße"]         = { 4426 },
        },
        bestGems = {
            meta      = { 76895 },
            rot       = { 76695 },            -- Blinkender Primordialrubin (Parierchance)
            gelb      = { 76700 },
            blau      = { 76639 },
            orange    = { 76667 },
            lila      = { 76688 },
            ["grün"]      = { 76657 },
            prismatic = { 76695 },
        },
        gemNote = "Trefferwertung/Waffenkunde halten. Parierchance > Ausweichen, Meisterschaft sekundär.",
    },

    PALADIN_RETRIBUTION = {
        bestEnchants = {
            Waffe        = { 4444, 3368 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]        = { 4434 },
            Beine        = { 4822 },
            ["Füße"]         = { 4428 },
        },
        bestGems = {
            meta      = { 76886 },
            rot       = { 83141, 76696 },
            gelb      = { 76697, 76700 },
            blau      = { 76688, 76639 },
            orange    = { 76667, 76669 },
            lila      = { 76688 },
            ["grün"]      = { 76657 },
            prismatic = { 83141, 76696 },
        },
        gemNote = "Stärke überall. Cap: 7.5% Treffer, 15% Waffenkunde (Hit/Expertise).",
    },

    --------------------------------------------------
    -- HUNTER
    --------------------------------------------------

    HUNTER_BEASTMASTERY = {
        bestEnchants = {
            Waffe        = { 4443, 4441 },    -- Elementarkraft / Jadegeist
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422 },          -- Überragende Kritische Trefferwertung
            Handgelenke  = { 4416 },          -- Große Beweglichkeit
            ["Hände"]        = { 4433 },          -- Große Tempowertung
            Beine        = { 4823 },
            ["Füße"]         = { 4430 },
            Fernkampf    = { 4099, 3851 },        -- Mörder-Optik / Treffsichere Visierung (*)          -- Große Beweglichkeit
        },
        bestGems = {
            meta      = { 76884 },            -- Wendiger Prismatischer Diamant
            rot       = { 83144, 76885 },     -- Feines Schlangenaugen / Feiner Primordialrubin
            gelb      = { 76699, 76700 },     -- Rasanter Zinnoberonyx / Rascher Sonnenglanz
            blau      = { 76687, 76639 },     -- Gedeihlicher Kaiserlicher Amethyst / Standhaftes Flussherz
            orange    = { 76668, 76666 },
            lila      = { 76687 },
            ["grün"]      = { 76711 },
            prismatic = { 83144, 76885 },
        },
        gemNote = "Beweglichkeit überall. 7.5% Treffsicherheit-Cap für Fernkampf beachten.",
    },

    HUNTER_MARKSMANSHIP = {
        bestEnchants = {
            Waffe        = { 4443, 4441 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4433 },
            Beine        = { 4823 },
            ["Füße"]         = { 4430 },
            Fernkampf    = { 4099, 3851 },        -- Mörder-Optik / Treffsichere Visierung (*)
        },
        bestGems = {
            meta      = { 76884 },
            rot       = { 83144, 76885 },
            gelb      = { 76699, 76700 },
            blau      = { 76687, 76639 },
            orange    = { 76668, 76666 },
            lila      = { 76687 },
            ["grün"]      = { 76711 },
            prismatic = { 83144, 76885 },
        },
        gemNote = "Beweglichkeit > Kritische Trefferwertung. Schussgefechtskundschaft passiv +10% Treffsicherheit.",
    },

    HUNTER_SURVIVAL = {
        bestEnchants = {
            Waffe        = { 4443, 4441 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4433 },
            Beine        = { 4823 },
            ["Füße"]         = { 4430 },
            Fernkampf    = { 4099, 3851 },        -- Mörder-Optik / Treffsichere Visierung (*)
        },
        bestGems = {
            meta      = { 76884 },
            rot       = { 83144, 76885 },
            gelb      = { 76699, 76700 },     -- Gewandter Zinnoberonyx / Meisterschaft
            blau      = { 76687, 76639 },
            orange    = { 76666 },
            lila      = { 76687 },
            ["grün"]      = { 76657 },
            prismatic = { 83144, 76885 },
        },
        gemNote = "Beweglichkeit > Meisterschaft. Überlebensinstinkt: Meisterschaft stärker als bei anderen Hunter-Specs.",
    },

    --------------------------------------------------
    -- ROGUE
    --------------------------------------------------

    ROGUE_ASSASSINATION = {
        bestEnchants = {
            Waffe        = { 4443 },          -- Elementarkraft
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4433 },
            Beine        = { 4823 },
            ["Füße"]         = { 4430 },
        },
        bestGems = {
            meta      = { 76884 },
            rot       = { 83144, 76885 },
            gelb      = { 76699, 76697 },     -- Rasanter Zinnoberonyx / Glatter Sonnenglanz
            blau      = { 76687, 76639 },
            orange    = { 76668, 76666 },
            lila      = { 76687 },
            ["grün"]      = { 76649 },
            prismatic = { 83144, 76885 },
        },
        gemNote = "Beweglichkeit überall. Bei Meisterschaft-Priorität: Gewandten Zinnoberonyx für gelbe Sockel.",
    },

    ROGUE_COMBAT = {
        bestEnchants = {
            Waffe        = { 3368, 4443 },    -- Tanzender Stahl primär / Elementarkraft
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4433 },
            Beine        = { 4823 },
            ["Füße"]         = { 4430 },
        },
        bestGems = {
            meta      = { 76884 },
            rot       = { 83144, 76885 },
            gelb      = { 76699, 76700 },
            blau      = { 76687, 76639 },
            orange    = { 76668, 76666 },
            lila      = { 76687 },
            ["grün"]      = { 76711 },
            prismatic = { 83144, 76885 },
        },
        gemNote = "Haupthand: Tanzender Stahl. Nebenhand: Elementarkraft. Tempo cap: 37.5%.",
    },

    ROGUE_SUBTLETY = {
        bestEnchants = {
            Waffe        = { 4443, 3368 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4433 },
            Beine        = { 4823 },
            ["Füße"]         = { 4430 },
        },
        bestGems = {
            meta      = { 76884 },
            rot       = { 83144, 76885 },
            gelb      = { 76699, 76697 },
            blau      = { 76687, 76639 },
            orange    = { 76668, 76666 },
            lila      = { 76687 },
            ["grün"]      = { 76649 },
            prismatic = { 83144, 76885 },
        },
        gemNote = "Beweglichkeit > Kritische Trefferwertung. Haupthand: Elementarkraft.",
    },

    --------------------------------------------------
    -- PRIEST
    --------------------------------------------------

    PRIEST_DISCIPLINE = {
        bestEnchants = {
            Waffe        = { 4441 },          -- Jadegeist
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76888 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },     -- Brennender Zinnoberonyx / Gebrochener Sonnenglanz
            blau      = { 76680, 76638 },
            orange    = { 76668, 76660 },
            lila      = { 76680 },
            ["grün"]      = { 76657 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Meisterschaft > Tempo. Heilpriester brauchen kein Trefferwertungscap.",
    },

    PRIEST_HOLY = {
        bestEnchants = {
            Waffe        = { 4441 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76888 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },     -- Tempo wichtig für Heiligen Priester
            blau      = { 76680, 76638 },
            orange    = { 76668, 76660 },
            lila      = { 76680 },
            ["grün"]      = { 76657 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Tempo > Meisterschaft. Heiliger Priester profitiert mehr von Tempo.",
    },

    PRIEST_SHADOW = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76885 },            -- Brennender Prismatischer Diamant
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },
            blau      = { 76638, 76639 },     -- Ruhiges Flussherz (Geisteskraft) / Ausdauer
            orange    = { 76668, 76660 },
            lila      = { 76700 },            -- Verschobener Kaiserlicher Amethyst
            ["grün"]      = { 76711 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Tempo. Geisteskraft für blaue Sockel falls kein Hit-Cap nötig.",
    },

    --------------------------------------------------
    -- DEATH KNIGHT
    --------------------------------------------------

    DEATHKNIGHT_BLOOD = {
        bestEnchants = {
            Waffe        = { 3369, 4444 },    -- Rune: Gefallener Kreuzritter / Koloss (*),
            Schultern    = { 4805 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]        = { 4431 },
            Beine        = { 4824 },
            ["Füße"]         = { 4426 },
        },
        bestGems = {
            meta      = { 76895 },
            rot       = { 76695 },
            gelb      = { 76700 },
            blau      = { 76639 },
            orange    = { 76667 },
            lila      = { 76688 },
            ["grün"]      = { 76657 },
            prismatic = { 76639 },
        },
        gemNote = "Blut-DK: Meisterschaft ist Hauptstat nach Trefferwertung/Waffenkunde-Caps.",
        statWeights = {
            mastery   = 100,
            strength  = 90,
            expertise = 85,
            hit       = 85,
            parry     = 60,
            dodge     = 60,
            stamina   = 40,
            crit      = 20,
            haste     = 15,
        },
    },

    DEATHKNIGHT_FROST = {
        bestEnchants = {
            Waffe        = { 3370, 3368, 4444 }, -- Rune: Razorice (MH) / Tanzender Stahl / Koloss (**)
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]        = { 4434 },
            Beine        = { 4822 },
            ["Füße"]         = { 4428 },
        },
        bestGems = {
            meta      = { 76886 },
            rot       = { 83141, 76696 },
            gelb      = { 76697, 76700 },
            blau      = { 76688, 76639 },
            orange    = { 76667, 76669 },
            lila      = { 76688 },
            ["grün"]      = { 76657 },
            prismatic = { 83141, 76696 },
        },
        gemNote = "Stärke überall. Zwei Tanzender Stahl auf beiden Waffen (Dual-Wield).",
        statWeights = {
            strength  = 100,
            mastery   = 95,
            hit       = 90,
            expertise = 90,
            haste     = 80,
            crit      = 70,
            stamina   = 5,
        },
    },

    DEATHKNIGHT_UNHOLY = {
        bestEnchants = {
            Waffe        = { 3369, 4444, 3368 }, -- Rune: Gefallener Kreuzritter / Koloss (*),
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4412 },
            ["Hände"]        = { 4434 },
            Beine        = { 4822 },
            ["Füße"]         = { 4428 },
        },
        bestGems = {
            meta      = { 76886 },
            rot       = { 83141, 76696 },
            gelb      = { 76697, 76700 },
            blau      = { 76688, 76639 },
            orange    = { 76667, 76669 },
            lila      = { 76688 },
            ["grün"]      = { 76657 },
            prismatic = { 83141, 76696 },
        },
        gemNote = "Stärke > Meisterschaft. Unheilig profitiert stark von Meisterschaft (Schattenschaden).",
        statWeights = {
            strength  = 100,
            mastery   = 95,
            hit       = 90,
            expertise = 90,
            haste     = 80,
            crit      = 70,
            stamina   = 5,
        },
    },

    --------------------------------------------------
    -- SHAMAN
    --------------------------------------------------

    SHAMAN_ELEMENTAL = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76885 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },
            blau      = { 76636, 76639 },     -- Trefferwertung bis Cap, dann Ausdauer
            orange    = { 76668, 76660 },
            lila      = { 76700 },
            ["grün"]      = { 76711 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Meisterschaft > Tempo. Trefferwertung: 15% (1742 Rating) pflicht.",
    },

    SHAMAN_ENHANCEMENT = {
        bestEnchants = {
            Waffe        = { 3368, 4443 },    -- Tanzender Stahl / Elementarkraft
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4433 },
            Beine        = { 4823 },
            ["Füße"]         = { 4430 },
        },
        bestGems = {
            meta      = { 76884 },
            rot       = { 83144, 76885 },
            gelb      = { 76699, 76700 },
            blau      = { 76687, 76639 },
            orange    = { 76668, 76666 },
            lila      = { 76687 },
            ["grün"]      = { 76711 },
            prismatic = { 83144, 76885 },
        },
        gemNote = "Beweglichkeit überall. Verbesserungs-Schamane nutzt Tanzender Stahl (MH) + Elementarkraft (OH).",
    },

    SHAMAN_RESTORATION = {
        bestEnchants = {
            Waffe        = { 4441 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76888 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },
            blau      = { 76680, 76638 },
            orange    = { 76668, 76660 },
            lila      = { 76680 },
            ["grün"]      = { 76657 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Meisterschaft > Tempo. Willenskraft für blaue Sockel (Mana-Regen).",
    },

    --------------------------------------------------
    -- MAGE
    --------------------------------------------------

    MAGE_ARCANE = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76885 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },     -- Tempo für Arkan-Magier
            blau      = { 76638, 76639 },
            orange    = { 76668, 76660 },
            lila      = { 76700 },
            ["grün"]      = { 76711 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Meisterschaft. Arkan profitiert extrem von Intelligenz-Stacking.",
    },

    MAGE_FIRE = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76885 },
            rot       = { 83145, 76888 },
            gelb      = { 76698, 76697 },     -- Heller Zinnoberonyx / Kritische Trefferwertung
            blau      = { 76638, 76639 },
            orange    = { 76674, 76668 },
            lila      = { 76700 },
            ["grün"]      = { 76649 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Kritische Trefferwertung. Feuer-Magier profitiert stark von Kritischem Treffer.",
    },

    MAGE_FROST = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76885 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },
            blau      = { 76638, 76639 },
            orange    = { 76668, 76660 },
            lila      = { 76700 },
            ["grün"]      = { 76711 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Meisterschaft > Tempo. Frost-Magier: Meisterschaft stärkt Eiszapfen.",
    },

    --------------------------------------------------
    -- WARLOCK
    --------------------------------------------------

    WARLOCK_AFFLICTION = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76885 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },
            blau      = { 76638, 76639 },
            orange    = { 76668, 76660 },
            lila      = { 76700 },
            ["grün"]      = { 76711 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Tempo/Meisterschaft. Gebrechen: Meisterschaft > Tempo.",
    },

    WARLOCK_DEMONOLOGY = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76885 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },
            blau      = { 76638, 76639 },
            orange    = { 76668, 76660 },
            lila      = { 76700 },
            ["grün"]      = { 76711 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Meisterschaft. Dämonologie: Meisterschaft stärkt Besessene Form.",
    },

    WARLOCK_DESTRUCTION = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76885 },
            rot       = { 83145, 76888 },
            gelb      = { 76698, 76697 },     -- Kritische Trefferwertung für Zerstörung
            blau      = { 76638, 76639 },
            orange    = { 76674, 76668 },
            lila      = { 76700 },
            ["grün"]      = { 76649 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Kritische Trefferwertung. Zerstörung: Kritischer Treffer wichtig für Verheeren.",
    },

    --------------------------------------------------
    -- MONK
    --------------------------------------------------

    MONK_BREWMASTER = {
        bestEnchants = {
            Waffe        = { 3368, 4444 },
            Schultern    = { 4805 },
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4431 },
            Beine        = { 4824 },
            ["Füße"]         = { 4426 },
        },
        bestGems = {
            meta      = { 76884 },
            rot       = { 76885 },
            gelb      = { 76700 },
            blau      = { 76639 },
            orange    = { 76657 },
            lila      = { 76687 },
            ["grün"]      = { 76657 },
            prismatic = { 76885 },
        },
        gemNote = "Beweglichkeit > Meisterschaft. Meisterschaft stärkt Schütteln & Dämpfung.",
    },

    MONK_MISTWEAVER = {
        bestEnchants = {
            Waffe        = { 4441 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76888 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },
            blau      = { 76680, 76638 },
            orange    = { 76668, 76660 },
            lila      = { 76680 },
            ["grün"]      = { 76657 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Tempo. Nebel-Weber: Meisterschaft stärkt Heilschlangen.",
    },

    MONK_WINDWALKER = {
        bestEnchants = {
            Waffe        = { 3368, 4443 },    -- Tanzender Stahl auf beiden
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4433 },
            Beine        = { 4823 },
            ["Füße"]         = { 4430 },
        },
        bestGems = {
            meta      = { 76884 },
            rot       = { 83144, 76885 },
            gelb      = { 76699, 76700 },
            blau      = { 76687, 76639 },
            orange    = { 76668, 76666 },
            lila      = { 76687 },
            ["grün"]      = { 76711 },
            prismatic = { 83144, 76885 },
        },
        gemNote = "Beweglichkeit > Kritische Trefferwertung. Windläufer: Beide Waffen Tanzender Stahl.",
    },

    --------------------------------------------------
    -- DRUID
    --------------------------------------------------

    DRUID_BALANCE = {
        bestEnchants = {
            Waffe        = { 4441, 4443 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76885 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },
            blau      = { 76638, 76639 },
            orange    = { 76668, 76660 },
            lila      = { 76700 },
            ["grün"]      = { 76711 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Meisterschaft/Tempo. Gleichgewicht: Meisterschaft stärkt Eclipse.",
    },

    DRUID_FERAL = {
        bestEnchants = {
            Waffe        = { 3368, 4443 },
            Schultern    = { 4803 },
            Brust        = { 4419 },
            Umhang       = { 4422 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4433 },
            Beine        = { 4823 },
            ["Füße"]         = { 4430 },
        },
        bestGems = {
            meta      = { 76884 },
            rot       = { 83144, 76885 },
            gelb      = { 76699, 76697 },
            blau      = { 76687, 76639 },
            orange    = { 76668, 76666 },
            lila      = { 76687 },
            ["grün"]      = { 76649 },
            prismatic = { 83144, 76885 },
        },
        gemNote = "Beweglichkeit überall. Wild-Druide: Kritische Trefferwertung sekundär.",
    },

    DRUID_GUARDIAN = {
        bestEnchants = {
            Waffe        = { 3368, 4444 },
            Schultern    = { 4806 },          -- Große Tigerfanginschrift
            Brust        = { 4419 },
            Umhang       = { 4421 },
            Handgelenke  = { 4416 },
            ["Hände"]        = { 4432 },
            Beine        = { 4824 },
            ["Füße"]         = { 4426 },
        },
        bestGems = {
            meta      = { 76896 },            -- Eiserner Prismatischer Diamant
            rot       = { 83151, 76692 },
            gelb      = { 76700 },
            blau      = { 76639 },
            orange    = { 76657 },
            lila      = { 76687 },
            ["grün"]      = { 76657 },
            prismatic = { 76885 },
        },
        gemNote = "Beweglichkeit > Meisterschaft. Wächter-Druide: Meisterschaft stärkt Bärenbiss-Schild.",
    },

    DRUID_RESTORATION = {
        bestEnchants = {
            Waffe        = { 4441 },
            Schultern    = { 4804 },
            Brust        = { 4419 },
            Umhang       = { 4892 },
            Handgelenke  = { 4414 },
            ["Hände"]        = { 4432 },
            Beine        = { 4823 },
            ["Füße"]         = { 4429 },
        },
        bestGems = {
            meta      = { 76888 },
            rot       = { 83145, 76888 },
            gelb      = { 76699, 76700 },
            blau      = { 76680, 76638 },
            orange    = { 76668, 76660 },
            lila      = { 76680 },
            ["grün"]      = { 76657 },
            prismatic = { 83145, 76888 },
        },
        gemNote = "Intelligenz > Meisterschaft. Wiederherstellungs-Druide: Meisterschaft stärkt Lebensblüte.",
    },

      --------------------------------------------------
      -- OFFENSIVE TANK PROFILE (Spielstil: Offensiv)
      --   Fokus: Trefferrating/Waffenkunde zuerst,
      --   dann Schadensstat statt Überlebenswert.
      --------------------------------------------------

      WARRIOR_PROTECTION_OFFENSIVE = {
          bestEnchants = {
              Waffe        = { 4444, 3368 },
              Schultern    = { 4803 },
              Brust        = { 4419 },
              Umhang       = { 4421 },
              Handgelenke  = { 4412 },
              ["Hände"]    = { 4434 },
              Beine        = { 4822 },
              ["Füße"]     = { 4428 },
          },
          bestGems = {
              meta      = { 76886 },
              rot       = { 83141, 76696 },
              gelb      = { 76697, 76700 },
              blau      = { 76688, 76639 },
              orange    = { 76667, 76669 },
              lila      = { 76688 },
              ["grün"]  = { 76657 },
              prismatic = { 83141, 76696 },
          },
          gemNote = "Offensiv: Stärke stacken nach Hit+Expertise-Cap. Mehr Bedrohung/DPS.",
      },

      PALADIN_PROTECTION_OFFENSIVE = {
          bestEnchants = {
              Waffe        = { 4444, 3368 },
              Schultern    = { 4803 },
              Brust        = { 4419 },
              Umhang       = { 4421 },
              Handgelenke  = { 4412 },
              ["Hände"]    = { 4434 },
              Beine        = { 4822 },
              ["Füße"]     = { 4428 },
          },
          bestGems = {
              meta      = { 76886 },
              rot       = { 83141, 76696 },
              gelb      = { 76697, 76700 },
              blau      = { 76688, 76639 },
              orange    = { 76667, 76669 },
              lila      = { 76688 },
              ["grün"]  = { 76657 },
              prismatic = { 83141, 76696 },
          },
          gemNote = "Offensiv: Stärke/Waffenkunde-Cap. Mehr Heiliger Schaden und Bedrohung.",
      },

      DEATHKNIGHT_BLOOD_OFFENSIVE = {
          bestEnchants = {
              Waffe        = { 3369, 3368, 4444 },
              Schultern    = { 4803 },
              Brust        = { 4419 },
              Umhang       = { 4421 },
              Handgelenke  = { 4412 },
              ["Hände"]    = { 4434 },
              Beine        = { 4822 },
              ["Füße"]     = { 4428 },
          },
          bestGems = {
              meta      = { 76886 },
              rot       = { 83141, 76696 },
              gelb      = { 76697, 76700 },
              blau      = { 76688, 76639 },
              orange    = { 76667, 76669 },
              lila      = { 76688 },
              ["grün"]  = { 76657 },
              prismatic = { 83141, 76696 },
          },
          gemNote = "Offensiv: Stärke nach Hit+Exp-Cap. Gefallener Kreuzritter + mehr DPS-Stats.",
      },

      MONK_BREWMASTER_OFFENSIVE = {
          bestEnchants = {
              Waffe        = { 3368, 4443 },
              Schultern    = { 4803 },
              Brust        = { 4419 },
              Umhang       = { 4422 },
              Handgelenke  = { 4416 },
              ["Hände"]    = { 4433 },
              Beine        = { 4823 },
              ["Füße"]     = { 4430 },
          },
          bestGems = {
              meta      = { 76884 },
              rot       = { 83144, 76885 },
              gelb      = { 76699, 76697 },
              blau      = { 76687, 76639 },
              orange    = { 76668, 76666 },
              lila      = { 76687 },
              ["grün"]  = { 76711 },
              prismatic = { 83144, 76885 },
          },
          gemNote = "Offensiv: Beweglichkeit+Tempo. Hit+Exp-Cap zuerst, dann Krit-Trefferwertung.",
      },

      DRUID_GUARDIAN_OFFENSIVE = {
          bestEnchants = {
              Waffe        = { 3368, 4443 },
              Schultern    = { 4803 },
              Brust        = { 4419 },
              Umhang       = { 4422 },
              Handgelenke  = { 4416 },
              ["Hände"]    = { 4433 },
              Beine        = { 4823 },
              ["Füße"]     = { 4430 },
          },
          bestGems = {
              meta      = { 76884 },
              rot       = { 83144, 76885 },
              gelb      = { 76697, 76699 },
              blau      = { 76687, 76639 },
              orange    = { 76658, 76666 },
              lila      = { 76687 },
              ["grün"]  = { 76649 },
              prismatic = { 83144, 76885 },
          },
          gemNote = "Offensiv: Beweglichkeit+Kritische Trefferwertung. Wächter als Off-Tank/Damage.",
      },
  
}
