--------------------------------------------------
-- WeintCodex :: Enchants
-- Mists of Pandaria Classic
-- Quelle: https://www.wowhead.com/mop-classic/de
--
-- Struktur:
--   [enchantId] = {
--       name  = "Deutscher Anzeigename",
--       slot  = "Waffe|Nebenhand|Schultern|Brust|Umhang|Handgelenke|Hände|Beine|Füße|Ring",
--       stats = { hit = 180, ... },  -- numerisch, für Cap-Check & Bewertung
--       verify = true,               -- Name/ID noch in-game gegenprüfen (**)
--   }
--
-- HINWEIS ZU NAMEN: Für ANGELEGTE Verzauberungen liest das
-- Charakter-Modul die Verzauberung direkt aus dem Item-Tooltip
-- ("Verzaubert: ..." bzw. die grüne Effektzeile "+170 ...") — das
-- ist immer die offizielle deutsche Lokalisierung. Widerspricht der
-- Tooltip dem Eintrag hier, gewinnt der Tooltip: das Modul sucht dann
-- den Eintrag desselben Slots mit exakt passendem Stat+Wert und rechnet
-- ab da mit dem (siehe ResolveEnchant in modules/charakter.lua). Die
-- Namen hier werden für EMPFEHLUNGEN genutzt.
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
    [3370] = { name = "Rune des schneidenden Eises",          slot = "Waffe", isDkRune = true },  -- Razorice, bestätigt (PDF-Abgleich)
    [3847] = { name = "Rune des Steinhautgargoyles",          slot = "Waffe", isDkRune = true },

    --------------------------------------------------
    -- WAFFE: Zielfernrohre (Ingenieurskunst, für Jäger)
    -- In MoP gibt es keinen Fernkampf-Slot mehr — das
    -- Zielfernrohr sitzt auf der Waffe (Slot 16).
    --------------------------------------------------

    [4699] = { name = "Fürst von Schmetternichs Todeszielfernrohr", slot = "Waffe" },  -- bestätigt (Lord Blastington's Scope of Doom)
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

    -- ACHTUNG: 4804/4806 waren vertauscht (Live-Client bestätigt per
    -- /wc vz: ID 4806 = "+200 Intelligenz und +100 krit." = Kranichschwinge,
    -- nicht Tigerklaue) — am 2026-07-21 korrigiert, siehe auch die
    -- entsprechend angepassten Empfehlungen in spec_profiles.lua.
    [4803] = { name = "Große Inschrift des Tigerzahns",      slot = "Schultern", stats = { strength = 200, crit = 100 } },
    [4804] = { name = "Große Inschrift der Tigerklaue",      slot = "Schultern", stats = { agility = 200, crit = 100 } },
    [4805] = { name = "Große Inschrift des Ochsenhorns",     slot = "Schultern", stats = { stamina = 300, dodge = 100 } },
    [4806] = { name = "Große Inschrift der Kranichschwinge", slot = "Schultern", stats = { intellect = 200, crit = 100 } },

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
    -- 4423 fehlte bisher komplett (zeigte "Unbekannt (ID 4423)" im Charakter-Fenster).
    -- Lückenlos zwischen 4422 (Umhang-Krit) und 4424 (Umhang-Krit-Duplikat) einsortiert;
    -- passt zur "Enchant Cloak - Superior Intellect" (spell 104403, Formel-Item 84569) aus
    -- derselben 5.2-Formel-Reihe (Präzision/Krit/Intellekt). ID per /wc vz in-game bestätigen.
    [4423] = { name = "Überragende Intelligenz",              slot = "Umhang", stats = { intellect = 180 }, verify = true },
    -- Übersetzungsfehler behoben (User-Bericht per In-Game-Tooltip): 4424
    -- ist keine ältere/andere Verzauberung, sondern derselbe Enchant wie
    -- 4422 ("Überragende kritische Trefferwertung") — die frühere Vermutung
    -- eines veralteten Cata-Duplikats war falsch. Name korrigiert, damit der
    -- Namensabgleich in charakter.lua ihn als optimal erkennt.
    [4424] = { name = "Überragende kritische Trefferwertung", slot = "Umhang", stats = { crit = 180 } },
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
    -- Wert korrigiert 2026-07-25: Live-Tooltip zeigt +180 Stärke (nicht 170).
    [4415] = { name = "Außergewöhnliche Stärke", slot = "Handgelenke", stats = { strength = 180 } },
    [4414] = { name = "Erstklassige Intelligenz", slot = "Handgelenke", stats = { intellect = 180 } },  -- WoWHead: "Armschiene - Erstklassige Intelligenz" (item 74703)
    [4416] = { name = "Große Beweglichkeit",     slot = "Handgelenke", stats = { agility = 170 } },

    --------------------------------------------------
    -- HÄNDE
    --------------------------------------------------

    -- IDs 4430/4432 am Live-Client korrigiert (zwei unabhängige
    -- Nutzerberichte, jeweils per Item-Tooltip):
    --   * Handschuhe mit "Überragender Meisterschaft" tragen im Item-Link
    --     die ID 4430 (der Eintrag stand deshalb bis 2.0.1.0 fälschlich
    --     als "Großes Tempo" unter FÜSSE weiter unten).
    --   * Handschuhe mit "+170 Stärke" tragen die ID 4432 — die stand hier
    --     als Meisterschaft, weshalb jede korrekt mit Stärke verzauberte
    --     Hand die Marke "(ID 4432 abweichend)" bekam.
    -- 4434 bleibt als zweite Stärke-ID stehen (gleicher Name, gleiche
    -- Werte — wie 4422/4424 beim Umhang): fällt sie irgendwo auf, wird sie
    -- richtig aufgelöst statt als unbekannt gemeldet.
    [4430] = { name = "Überragende Meisterschaft", slot = "Hände", stats = { mastery = 170 } },
    [4431] = { name = "Überragende Waffenkunde",   slot = "Hände", stats = { expertise = 170 } },
    [4432] = { name = "Erstklassige Stärke",       slot = "Hände", stats = { strength = 170 } },
    [4433] = { name = "Großes Tempo",              slot = "Hände", stats = { haste = 170 } },  -- WoWHead: "Handschuhe - Großes Tempo" (item 74719)
    [4434] = { name = "Erstklassige Stärke",       slot = "Hände", stats = { strength = 170 }, verify = true },

    --------------------------------------------------
    -- BEINE (Lederverarbeitung / Schneiderei)
    --------------------------------------------------

    [4822] = { name = "Schattenlederbeinrüstung",            slot = "Beine", stats = { agility = 285, crit = 165 } },
    [4823] = { name = "Zornbalgbeinrüstung",                 slot = "Beine", stats = { strength = 285, crit = 165 } },
    [4824] = { name = "Eisenschuppenbeinrüstung",            slot = "Beine", stats = { stamina = 430, dodge = 165 } },
    [4825] = { name = "Großer perlmuttfarbener Zauberfaden", slot = "Beine", stats = { intellect = 285, spirit = 165 }, verify = true },
    [4826] = { name = "Großer himmelblauer Zauberfaden",     slot = "Beine", stats = { intellect = 285, crit = 165 } },  -- bestätigt (Nutzer-Feedback), korrekter Name statt "zerulanblau"

    --------------------------------------------------
    -- FÜSSE
    --------------------------------------------------

    [4425] = { name = "Verschwimmen",                  slot = "Füße", stats = { agility = 140 } },  -- WoWHead: "Stiefel - Verschwimmen" (item 74717, Blurred Speed)
    -- Korrigiert (User-Bericht per In-Game-Tooltip, Item "Sporen des
    -- Wolfsreiters"/105033): 4426 stand bisher fälschlich als
    -- "Pandarenschritt" (Meisterschaft). Der Live-Link des Items trägt
    -- diese ID tatsächlich für eine mit "Großes Tempo" (Haste) verzauberte
    -- Stiefel - selbes Tempo-Tier wie 74715. Bestätigt auch durch bereits
    -- bestehende Empfehlungslisten in spec_profiles.lua, die 4426 an
    -- mehreren Stellen bereits als Tempo-Alternative zu 74715 führten.
    [4426] = { name = "Großes Tempo",                  slot = "Füße", stats = { haste = 175 }, verify = true },
    [4428] = { name = "Große Präzision",               slot = "Füße", stats = { hit = 175 }, verify = true },  -- exakten Namen per /wc vz prüfen
    -- "Pandarenpfoten" (Meisterschaft + geringe Bewegungsgeschwindigkeit).
    [4429] = { name = "Pandarenpfoten",                slot = "Füße", stats = { mastery = 175 }, verify = true },
    -- Boots-Tempo (bestätigt via Nutzer/Wowhead), selber Effekt wie 4426.
    -- Schlüssel = Item-ID (74715); Bewertung über Name-Abgleich
    -- ("Verzaubert: Großes Tempo").
    [74715] = { name = "Großes Tempo",                 slot = "Füße", stats = { haste = 175 }, verify = true },
    -- HINWEIS: 4430 stand hier bis 2.0.1.0 als zweite Hände-Tempo-ID und
    -- steht jetzt im HÄNDE-Block als "Überragende Meisterschaft" — der
    -- Nutzerbericht, der schon damals dagegen sprach (Handschuhe mit
    -- Meisterschaft trugen diese ID), ist inzwischen die belastbarere
    -- Angabe. Laut WoWHead gibt es in MoP nur 4 Stiefel-Verzauberungen
    -- (Präzision/Treffer, Tempo, Verschwimmen, Pandarenpfoten) - kein
    -- separates reines "Beweglichkeit"-Enchant für Füße.

    --------------------------------------------------
    -- NEBENHAND (Schild UND Beihand-Gegenstand)
    --
    -- In MoP ist der Nebenhand-Slot für JEDEN Gegenstandstyp
    -- verzauberbar, nicht nur fuer Waffen:
    --   * "Nebenhand - Mächtige Intelligenz" passt laut Wowhead
    --     ausdrücklich auf Schild UND "In Nebenhand gehalten"
    --     (Zauberbuch/Kugel/Totem) - Zauber 104445, +165 Intelligenz.
    --   * "Schild - Großes Parieren" passt nur auf Schilde
    --     (Zauber 130758, +170 Parieren, 5.4-Neuzugang).
    -- Ein reines Meisterschafts-/Ausdauer-Schildenchant auf MoP-Niveau
    -- gibt es nicht - die alten WotLK/Cata-Formeln sind wertlos und
    -- deshalb hier bewusst nicht hinterlegt.
    --
    -- SCHLÜSSEL: Fuer diese beiden ist die Link-Enchant-ID noch nicht
    -- bestätigt; hinterlegt sind die Gegenstands-IDs der Verzauberungs-
    -- rolle (74729 bzw. 89737), analog zu 74711/74715 weiter oben. Die
    -- Bewertung läuft ohnehin über den Tooltip-/Namensabgleich in
    -- ResolveEnchant, ein ID-Irrtum verfälscht die Anzeige also nicht.
    -- Per "/wc vz" die echten IDs ermitteln und hier eintragen.
    --------------------------------------------------

    [74729] = { name = "Mächtige Intelligenz", slot = "Nebenhand", stats = { intellect = 165 }, verify = true },
    [89737] = { name = "Großes Parieren",      slot = "Nebenhand", stats = { parry = 170 },    verify = true, nurSchild = true },

    --------------------------------------------------
    -- RINGE (Verzauberkunst-exklusiv)
    --
    -- Nur Verzauberer können ihre eigenen Ringe verzaubern. Das
    -- Charakter-Modul blendet die Ring-Zeilen deshalb aus, wenn der
    -- Beruf nicht geskillt ist (siehe HasEnchanting in charakter.lua) -
    -- sonst hätten Nicht-Verzauberer dauerhaft zwei "fehlende"
    -- Verzauberungen im Check.
    --
    -- SCHLÜSSEL: wie oben Platzhalter-IDs (Formel-Gegenstände
    -- 84575-84578), bis die Link-Enchant-IDs per "/wc vz" bestätigt
    -- sind. Zauber-IDs zur Kontrolle: 103461 Beweglichkeit,
    -- 103462 Intelligenz, 103463 Ausdauer.
    --------------------------------------------------

    [84575] = { name = "Große Beweglichkeit", slot = "Ring", stats = { agility  = 160 }, verify = true },
    [84576] = { name = "Große Intelligenz",   slot = "Ring", stats = { intellect = 160 }, verify = true },
    [84577] = { name = "Große Ausdauer",      slot = "Ring", stats = { stamina  = 240 }, verify = true },
    [84578] = { name = "Große Stärke",        slot = "Ring", stats = { strength = 160 }, verify = true },

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
