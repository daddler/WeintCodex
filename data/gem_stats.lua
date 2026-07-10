--------------------------------------------------
-- WeintCodex :: Gem Stats
-- Numerische Statwerte für die automatische Bewertung.
--
-- WICHTIG: Diese Tabelle muss zu data/gems.lua passen —
-- jeder Stein aus WeintCodex_Gems hat hier einen Eintrag.
-- Stat-Schlüssel (identisch zu statWeights in spec_profiles.lua):
--   strength, agility, intellect, stamina, spirit,
--   crit, haste, mastery, hit, expertise, dodge, parry
--------------------------------------------------

WeintCodex_GemStats = {

    --------------------------------------------------
    -- META (legendäre Bergkristalle, SoO)
    -- Prozent-Procs werden nicht bewertet, nur der Grundwert.
    --------------------------------------------------

    [95347] = { crit = 324 },        -- Finsterer Bergkristall (Caster-DPS)
    [95345] = { intellect = 324 },   -- Mutiger Bergkristall (Heiler)
    [95346] = { crit = 324 },        -- Geladener Bergkristall (Nahkampf/Fernkampf)
    [95344] = { stamina = 324 },     -- Unbeugsamer Bergkristall (Tank)

    --------------------------------------------------
    -- META (Bergkristalle)
    --------------------------------------------------

    [76884] = { agility = 216 },     -- Agiler Bergkristall
    [76885] = { intellect = 216 },   -- Brennender Bergkristall
    [76886] = { strength = 216 },    -- Widerscheinender Bergkristall
    [76895] = { stamina = 432 },     -- Strenger Bergkristall (Tank)
    [76888] = { spirit = 432 },      -- Belebender Bergkristall (Heiler)

    --------------------------------------------------
    -- ROT (Rubellit): 160 Primärstat / 320 Sekundärstat
    --------------------------------------------------

    [76692] = { agility = 160 },
    [76693] = { expertise = 320 },
    [76694] = { intellect = 160 },
    [76695] = { parry = 320 },
    [76696] = { strength = 160 },

    --------------------------------------------------
    -- GELB (Goldberyll): 320 Sekundärstat
    --------------------------------------------------

    [76697] = { crit = 320 },
    [76698] = { dodge = 320 },
    [76699] = { haste = 320 },
    [76700] = { mastery = 320 },

    --------------------------------------------------
    -- BLAU (Chrysokoll)
    --------------------------------------------------

    [76636] = { hit = 320 },
    [76638] = { spirit = 320 },
    [76639] = { stamina = 240 },

    --------------------------------------------------
    -- ORANGE (Aragonit): 80 Primär + 160 Sekundär
    --------------------------------------------------

    [76658] = { agility = 80,  crit = 160 },
    [76672] = { intellect = 80, mastery = 160 },
    [76660] = { intellect = 80, crit = 160 },
    [76670] = { agility = 80,  mastery = 160 },
    [76661] = { strength = 80, crit = 160 },
    [76668] = { intellect = 80, haste = 160 },
    [76669] = { strength = 80, haste = 160 },
    [76666] = { agility = 80,  haste = 160 },
    [76674] = { strength = 80, mastery = 160 },

    --------------------------------------------------
    -- LILA (Kunzit): 80 Primär + 160 Sekundär
    --                bzw. 120 Ausdauer bei Hybrid
    --------------------------------------------------

    [76682] = { intellect = 80, hit = 160 },
    [76687] = { agility = 80,  stamina = 120 },
    [76690] = { parry = 160,   stamina = 120 },
    [76691] = { strength = 80, stamina = 120 },
    [76686] = { intellect = 80, spirit = 160 },
    [76680] = { agility = 80,  hit = 160 },
    [76681] = { expertise = 160, hit = 160 },
    [76684] = { strength = 80, hit = 160 },

    --------------------------------------------------
    -- GRÜN (Dioptas): 160 + 160 Sekundär
    --                 bzw. 120 Ausdauer bei Hybrid
    --------------------------------------------------

    [76652] = { crit = 160,    stamina = 120 },
    [76654] = { haste = 160,   stamina = 120 },
    [76656] = { mastery = 160, stamina = 120 },
    [76643] = { hit = 160,     mastery = 160 },
    [76642] = { haste = 160,   hit = 160 },
    [76641] = { crit = 160,    hit = 160 },
    [76640] = { spirit = 160,  crit = 160 },
    [76645] = { spirit = 160,  mastery = 160 },
    [76651] = { haste = 160,   spirit = 160 },

    --------------------------------------------------
    -- JUWELIER-EXKLUSIV (Serpentin):
    -- 320 Primärstat / 480 Sekundärstat
    --------------------------------------------------

    [83141] = { strength = 320 },
    [83142] = { haste = 480 },
    [83143] = { mastery = 480 },
    [83144] = { hit = 480 },
    [83145] = { dodge = 480 },
    [83146] = { crit = 480 },
    [83147] = { expertise = 480 },
    [83148] = { stamina = 480 },
    [83149] = { spirit = 480 },
    [83150] = { intellect = 320 },
    [83151] = { agility = 320 },
    [83152] = { parry = 480 },
}
