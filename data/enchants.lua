--------------------------------------------------
-- WeintCodex :: Enchants
-- Mists of Pandaria Classic
-- Quelle: https://www.wowhead.com/mop-classic/de
--
-- Struktur:
--   [enchantId] = {
--       name  = "Anzeigename",
--       slot  = "Waffe|Schultern|Brust|Umhang|Handgelenke|Hände|Beine|Füße",
--       stats = { hit = 180, ... },  -- numerisch, für Cap-Check & Bewertung
--       verify = true,               -- ID noch in-game gegenprüfen (**)
--   }
--
-- HINWEIS: IDs mit verify=true bitte in-game per
--   /dump select(2, GetItemInfo(GetInventoryItemLink("player", SLOT)))
--   bzw. Wowhead MoP-Classic verifizieren.
--------------------------------------------------

WeintCodex_Enchants = {

    --------------------------------------------------
    -- WAFFE (MoP-Verzauberungen)
    --------------------------------------------------

    [4441] = { name = "Lied des Windes",     slot = "Waffe" },                    -- Windsong (Proc: 1500 Krit/Tempo/Meisterschaft)
    [4442] = { name = "Jadegeist",           slot = "Waffe" },                    -- Jade Spirit (Proc: 1650 Int)
    [4443] = { name = "Elementarkraft",      slot = "Waffe" },                    -- Elemental Force (Elementarschaden-Proc)
    [4444] = { name = "Tanzender Stahl",     slot = "Waffe" },                    -- Dancing Steel (Proc: 1650 Stärke/Beweglichkeit)
    [4445] = { name = "Koloss",              slot = "Waffe" },                    -- Colossus (Absorb-Proc, Tank)
    [4446] = { name = "Lied des Flusses",    slot = "Waffe" },                    -- River's Song (Ausweichen-Proc, Tank)

    --------------------------------------------------
    -- WAFFE: Todesritter-Runenverzierungen
    --------------------------------------------------

    [3368] = { name = "Rune des gefallenen Kreuzfahrers", slot = "Waffe", isDkRune = true },
    [3370] = { name = "Rune der Rasierklinge",            slot = "Waffe", isDkRune = true },  -- Razorice
    [3847] = { name = "Rune des Steinhautgargoyles",      slot = "Waffe", isDkRune = true },
    [3369] = { name = "Rune des Aschenbringers (alt)",    slot = "Waffe", isDkRune = true, verify = true },

    --------------------------------------------------
    -- WAFFE: Zielfernrohre (Ingenieurskunst, für Jäger)
    -- In MoP gibt es keinen Fernkampf-Slot mehr — das
    -- Zielfernrohr sitzt auf der Waffe (Slot 16).
    --------------------------------------------------

    [4699] = { name = "Lord Blastingtons Optik des Schreckens", slot = "Waffe", verify = true },
    [4700] = { name = "Spiegeloptik",                            slot = "Waffe", verify = true },
    [4099] = { name = "Mörder-Optik (alt)",                      slot = "Waffe", verify = true },
    [4166] = { name = "Scharfes Zielfernrohr (alt)",             slot = "Waffe", verify = true },

    --------------------------------------------------
    -- SCHULTERN (Inschriftenkunde, Große Inschriften)
    --------------------------------------------------

    [4803] = { name = "Große Tigerzahninschrift",       slot = "Schultern", stats = { strength = 200, crit = 100 } },
    [4804] = { name = "Große Kranichschwingeninschrift", slot = "Schultern", stats = { intellect = 200, crit = 100 } },
    [4805] = { name = "Große Ochsenhorninschrift",       slot = "Schultern", stats = { stamina = 300, dodge = 100 } },
    [4806] = { name = "Große Tigerklaueninschrift",      slot = "Schultern", stats = { agility = 200, crit = 100 } },

    --------------------------------------------------
    -- BRUST
    --------------------------------------------------

    [4419] = { name = "Glorreiche Werte",     slot = "Brust", stats = { strength = 80, agility = 80, intellect = 80, stamina = 80, spirit = 80 } },
    [4420] = { name = "Überragende Ausdauer", slot = "Brust", stats = { stamina = 300 } },

    --------------------------------------------------
    -- UMHANG
    --------------------------------------------------

    [4421] = { name = "Große Präzision",                      slot = "Umhang", stats = { hit = 180 } },
    [4422] = { name = "Überragende Kritische Trefferwertung", slot = "Umhang", stats = { crit = 180 } },
    [4424] = { name = "Überlegene Kritische Trefferwertung",  slot = "Umhang", stats = { crit = 180 }, verify = true },
    [4892] = { name = "Überlegene Intelligenz",               slot = "Umhang", stats = { intellect = 180 } },

    --------------------------------------------------
    -- HANDGELENKE
    --------------------------------------------------

    [4411] = { name = "Meisterschaft",             slot = "Handgelenke", stats = { mastery = 170 } },
    [4412] = { name = "Außergewöhnliche Stärke",   slot = "Handgelenke", stats = { strength = 170 } },
    [4414] = { name = "Überragende Intelligenz",   slot = "Handgelenke", stats = { intellect = 180 } },
    [4416] = { name = "Große Beweglichkeit",       slot = "Handgelenke", stats = { agility = 170 } },

    --------------------------------------------------
    -- HÄNDE
    --------------------------------------------------

    [4431] = { name = "Überlegene Waffenkunde",   slot = "Hände", stats = { expertise = 170 } },
    [4432] = { name = "Überlegene Meisterschaft", slot = "Hände", stats = { mastery = 170 } },
    [4433] = { name = "Große Tempowertung",       slot = "Hände", stats = { haste = 170 } },
    [4434] = { name = "Überragende Stärke",       slot = "Hände", stats = { strength = 170 } },

    --------------------------------------------------
    -- BEINE (Lederverarbeitung / Schneiderei)
    --------------------------------------------------

    [4822] = { name = "Schattenlederbeinrüstung",              slot = "Beine", stats = { agility = 285, crit = 165 } },
    [4823] = { name = "Zornbalgbeinrüstung",                   slot = "Beine", stats = { strength = 285, crit = 165 } },
    [4824] = { name = "Eisenschuppenbeinrüstung",              slot = "Beine", stats = { stamina = 430, dodge = 165 } },
    [4825] = { name = "Großer perlmuttfarbener Zauberfaden",   slot = "Beine", stats = { intellect = 285, spirit = 165 }, verify = true },
    [4826] = { name = "Großer zerulanischer Zauberfaden",      slot = "Beine", stats = { intellect = 285, crit = 165 }, verify = true },

    --------------------------------------------------
    -- FÜSSE
    --------------------------------------------------

    [4425] = { name = "Verschwommene Geschwindigkeit", slot = "Füße", stats = { agility = 140 }, verify = true },
    [4426] = { name = "Pandarenschritt",               slot = "Füße", stats = { mastery = 140 } },
    [4428] = { name = "Große Präzision",               slot = "Füße", stats = { hit = 175 } },
    [4429] = { name = "Große Tempowertung",            slot = "Füße", stats = { haste = 175 } },
    [4430] = { name = "Große Beweglichkeit",           slot = "Füße", stats = { agility = 140 }, verify = true },

}

--------------------------------------------------
-- Hilfsfunktion: Enchant-Name ermitteln
--------------------------------------------------
function WeintCodex_GetEnchantName(enchantId)
    if not enchantId then return "—" end
    local ench = WeintCodex_Enchants and WeintCodex_Enchants[enchantId]
    if ench and ench.name then return ench.name end
    return "Unbekannte Verzauberung (ID: " .. tostring(enchantId) .. ")"
end
