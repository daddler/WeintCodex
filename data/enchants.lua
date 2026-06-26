--------------------------------------------------
-- WeintCodex :: Enchants
-- Mists of Pandaria Classic
-- Quelle: https://www.wowhead.com/mop-classic/de
--
-- HINWEIS: IDs mit (**) bitte per /script DEFAULT_CHAT_FRAME:AddMessage(...)
--   oder Wowhead MoP-Classic verifizieren.
--------------------------------------------------

WeintCodex_Enchants = {

    --------------------------------------------------
    -- Waffen (Standard)
    --------------------------------------------------

    [3368] = { name = "Tanzender Stahl",      slot = "Waffe" },
    [4441] = { name = "Jadegeist",             slot = "Waffe" },

    --------------------------------------------------
    -- Todesritter – Runenverzierungen
    -- IDs bitte in-game per Itemlink verifizieren (**)
    --------------------------------------------------

    [3369] = { name = "Runenverzierung: Gefallener Kreuzfahrer",  slot = "Waffe", isDkRune = true },

    --------------------------------------------------
    -- Schultern
    --------------------------------------------------

    [4803] = { name = "Große Inschrift des Tigerzahns",    slot = "Schultern" },
    [4804] = { name = "Große Inschrift der Kranichschwinge",  slot = "Schultern" },
    [4805] = { name = "Große Inschrift des Ochsenhorns",     slot = "Schultern" },
    [4806] = { name = "Große Inschrift der Tigerklaue",      slot = "Schultern" },

    --------------------------------------------------
    -- Brust
    --------------------------------------------------

    [4419] = { name = "Überragende Werte",  slot = "Brust" },
    [4420] = { name = "Glorreiche Werte",   slot = "Brust" },

    --------------------------------------------------
    -- Umhang
    --------------------------------------------------

    [4421] = { name = "Große Präzision",                       slot = "Umhang" },
    [4422] = { name = "Überragende Kritische Trefferwertung",  slot = "Umhang" },
    [4424] = { name = "Überlegene Kritische Trefferwertung",   slot = "Umhang" },
    [4892] = { name = "Überlegene Intelligenz",                slot = "Umhang" },

    --------------------------------------------------
    -- Handgelenke
    --------------------------------------------------

    [4411] = { name = "Große Tempowertung",          slot = "Handgelenke" },
    [4412] = { name = "Außergewöhnliche Stärke",     slot = "Handgelenke" },
    [4414] = { name = "Überragende Intelligenz",     slot = "Handgelenke" },
    [4416] = { name = "Große Beweglichkeit",         slot = "Handgelenke" },

    --------------------------------------------------
    -- Handschuhe
    --------------------------------------------------

    [4431] = { name = "Große Expertise",          slot = "Hände" },
    [4432] = { name = "Überlegene Meisterschaft", slot = "Hände" },
    [4433] = { name = "Große Tempowertung",       slot = "Hände" },
    [4434] = { name = "Überragende Stärke",       slot = "Hände" },

    --------------------------------------------------
    -- Beine
    --------------------------------------------------

    [4822] = { name = "Schattlederbeinschutz",       slot = "Beine" },
    [4823] = { name = "Zornbalgbeinrüstung",          slot = "Beine" },
    [4824] = { name = "Drachenschuppenbeinschutz",   slot = "Beine" },

    --------------------------------------------------
    -- Füße
    --------------------------------------------------

    [4426] = { name = "Pandarenpfoten",           slot = "Füße" },
    [4428] = { name = "Große Präzision",          slot = "Füße" },
    [4429] = { name = "Pandarenpfoten",    slot = "Füße" },
    [4430] = { name = "Große Beweglichkeit",      slot = "Füße" },

    --------------------------------------------------
    -- Fernkampf (Jäger-Scope / Ingenieur)
    -- IDs bitte in-game per Itemlink verifizieren (**)
    --------------------------------------------------

    [4099] = { name = "Mörder-Optik",              slot = "Fernkampf" },
    [4166] = { name = "Scharfe Zielfernrohr",      slot = "Fernkampf" },

}

function WeintCodex_GetEnchantName(enchantId)
    if not enchantId then return "—" end
    local ench = WeintCodex_Enchants and WeintCodex_Enchants[enchantId]
    if ench and ench.name then return ench.name end
    return "Unbekannte Verzauberung (ID: " .. tostring(enchantId) .. ")"
end
