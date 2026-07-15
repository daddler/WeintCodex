--------------------------------------------------
-- WeintCodex :: Enchants
-- Mists of Pandaria Classic
-- Quelle: https://www.wowhead.com/mop-classic/de
--
-- Struktur:
--   [enchantId] = {
--       name  = "Deutscher Anzeigename",
--       slot  = "Waffe|Schultern|Brust|Umhang|Handgelenke|Hände|Beine|Füße",
--       stats = { hit = 180, ... },  -- numerisch, für Cap-Check & Bewertung
--       verify = true,               -- Name/ID noch in-game gegenprüfen (**)
--   }
--
-- HINWEIS ZU NAMEN: Für ANGELEGTE Verzauberungen liest das
-- Charakter-Modul den Namen direkt aus dem Item-Tooltip
-- ("Verzaubert: ...") — das ist immer die offizielle deutsche
-- Lokalisierung. Die Namen hier werden für EMPFEHLUNGEN genutzt.
--
-- DATENPFLEGE: In-game "/wc vz" eingeben — das druckt für jedes
-- angelegte Teil die Verzauberungs-ID + den offiziellen Namen und
-- markiert Abweichungen zur Datenbank. Damit lassen sich Einträge
-- mit verify=true zeilengenau korrigieren.
--
-- BEWERTUNG BEI FALSCHER/FEHLENDER ID: Die Engine gleicht
-- zusätzlich den Tooltip-Namen mit den Empfehlungen ab — stimmt
-- der Name (oder bei Schultern das Inschrift-Tier, z.B.
-- "Geheime Inschrift des Ochsenhorns" der Inschriftler), zählt
-- die Verzauberung trotzdem als optimal.
--------------------------------------------------

WeintCodex_Enchants = {

    --------------------------------------------------
    -- WAFFE (MoP-Verzauberungen)
    --------------------------------------------------

    [4441] = { name = "Lied des Windes",  slot = "Waffe" },   -- Windsong (Proc: 1500 Krit/Tempo/Meisterschaft)
    [4442] = { name = "Jadegeist",        slot = "Waffe" },   -- Jade Spirit (Proc: 1650 Intelligenz)
    [4443] = { name = "Elementarkraft",   slot = "Waffe" },   -- Elemental Force (Elementarschaden-Proc)
    [4444] = { name = "Tanzender Stahl",  slot = "Waffe" },   -- Dancing Steel (Proc: 1650 Stärke ODER Beweglichkeit)
    [4445] = { name = "Koloss",           slot = "Waffe" },   -- Colossus (Absorbschild-Proc, Tank)
    [4446] = { name = "Lied des Flusses", slot = "Waffe" },   -- River's Song (Ausweich-Proc, Tank)

    --------------------------------------------------
    -- WAFFE: Todesritter-Runenverzierungen
    --------------------------------------------------

    [3368] = { name = "Rune des gefallenen Kreuzfahrers",     slot = "Waffe", isDkRune = true },
    [3370] = { name = "Rune des Klingeneises (Razorice)",     slot = "Waffe", isDkRune = true, verify = true },
    [3847] = { name = "Rune des Steinhautgargoyles",          slot = "Waffe", isDkRune = true },

    --------------------------------------------------
    -- WAFFE: Zielfernrohre (Ingenieurskunst, für Jäger)
    -- In MoP gibt es keinen Fernkampf-Slot mehr — das
    -- Zielfernrohr sitzt auf der Waffe (Slot 16).
    --------------------------------------------------

    [4699] = { name = "Lord Blastingtons Zielfernrohr des Schreckens", slot = "Waffe", verify = true },
    [4700] = { name = "Spiegelzielfernrohr",                            slot = "Waffe", verify = true },
    [4099] = { name = "Zielfernrohr (älteres Modell)",                  slot = "Waffe", verify = true },
    [4166] = { name = "Scharfes Zielfernrohr (älteres Modell)",         slot = "Waffe", verify = true },

    --------------------------------------------------
    -- SCHULTERN (Inschriftenkunde, Große Inschriften)
    --
    -- Inschriftler-exklusiv gibt es zusätzlich die stärkeren
    -- "Geheimen Inschriften" (selbst erstellbar, gebunden).
    -- Deren IDs sind hier nicht hinterlegt — die Engine erkennt
    -- sie am Tooltip-Namen (gleiches Tier wie die Empfehlung)
    -- und wertet sie als optimal. Wer die IDs per /wc vz
    -- ermittelt, kann sie hier als eigene Einträge ergänzen.
    --------------------------------------------------

    [4803] = { name = "Große Inschrift des Tigerzahns",      slot = "Schultern", stats = { strength = 200, crit = 100 } },
    [4804] = { name = "Große Inschrift der Kranichschwinge", slot = "Schultern", stats = { intellect = 200, crit = 100 } },
    [4805] = { name = "Große Inschrift des Ochsenhorns",     slot = "Schultern", stats = { stamina = 300, dodge = 100 } },
    [4806] = { name = "Große Inschrift der Tigerklaue",      slot = "Schultern", stats = { agility = 200, crit = 100 } },

    --------------------------------------------------
    -- BRUST
    --------------------------------------------------

    [4419] = { name = "Glorreiche Werte",     slot = "Brust", stats = { strength = 80, agility = 80, intellect = 80, stamina = 80, spirit = 80 } },
    [4420] = { name = "Überragende Ausdauer", slot = "Brust", stats = { stamina = 300 } },

    --------------------------------------------------
    -- UMHANG
    --------------------------------------------------

    [4421] = { name = "Präzision",                            slot = "Umhang", stats = { hit = 180 } },  -- WoWHead: "Formel: Umhang - Präzision" (item 84568)
    [4422] = { name = "Überragende kritische Trefferwertung", slot = "Umhang", stats = { crit = 180 } },  -- WoWHead: "Enchant Cloak - Superior Critical Strike" (spell 104404)
    -- ACHTUNG: 4424 hat denselben Stat-Wert (crit 180) wie 4422 unter
    -- anderem Namen - laut WoWHead ist "Greater Critical Strike"
    -- (spell 74247) ein älteres/niedrigeres Cata-Enchant, kein MoP-
    -- Gegenstück. Vermutlich veraltet/Duplikat - per /wc vz prüfen
    -- und ggf. entfernen.
    [4424] = { name = "Überlegene kritische Trefferwertung",  slot = "Umhang", stats = { crit = 180 }, verify = true },
    [4892] = { name = "Überragende Intelligenz",              slot = "Umhang", stats = { intellect = 180 } },
    -- HINWEIS: Schlüssel = Wowhead-Item-ID (74711), nicht die Link-Enchant-ID.
    -- Für die Bewertung reicht der Name-Abgleich (Tooltip "Verzaubert: Großer
    -- Schutz"); echte Enchant-ID bei Bedarf per /wc vz bestätigen.
    [74711] = { name = "Großer Schutz",                      slot = "Umhang", stats = { stamina = 200 }, verify = true },  -- Tank (Umhang-Ausdauer)

    --------------------------------------------------
    -- HANDGELENKE
    --------------------------------------------------

    [4411] = { name = "Meisterschaft",           slot = "Handgelenke", stats = { mastery = 170 } },
    -- ID korrigiert (User-Bericht per In-Game-Tooltip): "Außergewöhnliche
    -- Stärke" zeigte sich unter ID 4412 als "Unbekannte Verzauberung",
    -- während der Nutzer die Verzauberung tatsächlich unter ID 4415
    -- trägt. 4412 war also die falsche ID und wurde ersetzt.
    [4415] = { name = "Außergewöhnliche Stärke", slot = "Handgelenke", stats = { strength = 170 } },
    [4414] = { name = "Erstklassige Intelligenz", slot = "Handgelenke", stats = { intellect = 180 } },  -- WoWHead: "Armschiene - Erstklassige Intelligenz" (item 74703)
    [4416] = { name = "Große Beweglichkeit",     slot = "Handgelenke", stats = { agility = 170 } },

    --------------------------------------------------
    -- HÄNDE
    --------------------------------------------------

    [4431] = { name = "Überragende Waffenkunde",   slot = "Hände", stats = { expertise = 170 } },
    [4432] = { name = "Überragende Meisterschaft", slot = "Hände", stats = { mastery = 170 } },
    [4433] = { name = "Großes Tempo",              slot = "Hände", stats = { haste = 170 } },  -- WoWHead: "Handschuhe - Großes Tempo" (item 74719)
    [4434] = { name = "Erstklassige Stärke",       slot = "Hände", stats = { strength = 170 } },  -- WoWHead: "Handschuhe - Erstklassige Stärke" (item 74721)

    --------------------------------------------------
    -- BEINE (Lederverarbeitung / Schneiderei)
    --------------------------------------------------

    [4822] = { name = "Schattenlederbeinrüstung",            slot = "Beine", stats = { agility = 285, crit = 165 } },
    [4823] = { name = "Zornbalgbeinrüstung",                 slot = "Beine", stats = { strength = 285, crit = 165 } },
    [4824] = { name = "Eisenschuppenbeinrüstung",            slot = "Beine", stats = { stamina = 430, dodge = 165 } },
    [4825] = { name = "Großer perlmuttfarbener Zauberfaden", slot = "Beine", stats = { intellect = 285, spirit = 165 }, verify = true },
    [4826] = { name = "Großer zerulanblauer Zauberfaden",    slot = "Beine", stats = { intellect = 285, crit = 165 }, verify = true },

    --------------------------------------------------
    -- FÜSSE
    --------------------------------------------------

    [4425] = { name = "Verschwimmen",                  slot = "Füße", stats = { agility = 140 } },  -- WoWHead: "Stiefel - Verschwimmen" (item 74717, Blurred Speed)
    [4426] = { name = "Pandarenschritt",               slot = "Füße", stats = { mastery = 140 } },
    [4428] = { name = "Große Präzision",               slot = "Füße", stats = { hit = 175 }, verify = true },  -- exakten Namen per /wc vz prüfen
    -- Korrigiert (User-Bericht per In-Game-Tooltip): 4429 wurde bisher
    -- als "Großes Tempo" (Haste) geführt, ist laut Tooltip tatsächlich
    -- "Pandarenpfoten" (Meisterschaft + geringe Bewegungsgeschwindigkeit)
    -- - vermutlich eine zweite, spätere Enchant-ID für denselben Effekt
    -- wie 4426 (Pandarenschritt). Meisterschaftswert vom bisherigen
    -- (falschen) Haste-Tier übernommen und noch nicht exakt bestätigt.
    [4429] = { name = "Pandarenpfoten",                slot = "Füße", stats = { mastery = 175 }, verify = true },
    -- Boots-Tempo (bestätigt via Nutzer/Wowhead). Schlüssel = Item-ID
    -- (74715); Bewertung über Name-Abgleich ("Verzaubert: Großes Tempo").
    [74715] = { name = "Großes Tempo",                 slot = "Füße", stats = { haste = 175 }, verify = true },
    -- ACHTUNG: Laut WoWHead gibt es in MoP nur 4 Stiefel-Verzauberungen
    -- (Präzision/Treffer, Tempo, Verschwimmen, Pandarenschritt) - kein
    -- separates reines "Beweglichkeit"-Enchant für Füße. User-Bericht
    -- legt nahe, dass diese ID tatsächlich die Hände-Tempo-Verzauberung
    -- ist (zeigt sich bei Handschuhen mit +170 Tempo fälschlich als
    -- "Große Beweglichkeit") - vermutlich eine zweite Enchant-ID für
    -- denselben Effekt wie 4433 (Hände - Großes Tempo). Slot/Name/Stat
    -- entsprechend umgestellt, noch per /wc vz final zu bestätigen.
    [4430] = { name = "Großes Tempo",                  slot = "Hände", stats = { haste = 170 }, verify = true },

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
