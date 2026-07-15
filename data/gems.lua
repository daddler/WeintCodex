--------------------------------------------------
-- WeintCodex :: Gems
-- Mists of Pandaria Classic (Item Level 90)
-- Quelle: https://www.wowhead.com/mop-classic/de/items/gems
--
-- WICHTIG: Die Anzeige-Namen werden zur Laufzeit bevorzugt
-- über GetItemInfo() vom Spielclient geholt — das ist immer
-- die offizielle deutsche Lokalisierung. Die Namen hier sind
-- nur Fallback, solange das Item noch nicht im Client-Cache ist.
--
-- ERKENNTNIS (07/2026): Blizzard hat die deutsche Lokalisierung
-- der Edelstein-Grundnamen zwischenzeitlich geändert. Die alten
-- Namen unten sind bei manchen Spielern schon der Vorstellung
-- nach falsch. gem_stats.lua wurde bereits auf die neuen Namen
-- umgestellt, gems.lua war seitdem inkonsistent - hier jetzt
-- nachgezogen. Die Item-IDs selbst sind unverändert, nur die
-- Bezeichnung wurde umbenannt:
--   Zinnoberonyx    -> Aragonit
--   Urzeitrubin     -> Rubellit
--   Sonnenglanz     -> Goldberyll
--   Flussherz       -> Chrysokoll
--   Kaiseramethyst  -> Kunzit
--   Wildjade        -> Dioptas
--
-- ERKENNTNIS (07/2026, Nutzerabgleich Wowhead MoP Classic DE):
-- Auch die Meta-/Legendär-Steine wurden umbenannt — "Urdiamant"
-- heißt jetzt "Bergkristall", teils mit geändertem Adjektiv:
--   Kapazitiver Urdiamant   -> Geladener Bergkristall     (95346)
--   Unbezähmbarer Urdiamant -> Unbeugsamer Bergkristall   (95344)
--   Widerhallender Urdiamant-> Widerscheinender Bergkristall (76886)
--   Asketischer Urdiamant   -> Strenger Bergkristall      (76895)
-- Weitere geänderte Grundsteinnamen (gleiche IDs):
--   Starrer Chrysokoll  -> Massiver Chrysokoll   (76636)
--   Blitzender Rubellit -> Scheinender Rubellit  (76695)
-- Die restlichen Meta-Namen (95347/95345/76884/76885/76888) werden
-- beim jeweiligen Klassen-Audit bestätigt und dann nachgezogen.
--
-- Deutsche Grundsteine (MoP, aktuell):
--   Meta   = Bergkristall         Rot    = Rubellit
--   Gelb   = Goldberyll           Blau   = Chrysokoll
--   Orange = Aragonit             Lila   = Kunzit
--   Grün   = Dioptas              JC     = Schlangenauge
--------------------------------------------------

WeintCodex_Gems = {

    --------------------------------------------------
    -- META: Legendäre Urdiamanten (Wrathion-Questreihe)
    --------------------------------------------------

    [95347] = { name = "Finsterer Urdiamant",       color = "meta", stats = "+324 kritische Trefferwertung, Chance auf 30% Zaubertempo (Caster-DPS)" },
    [95345] = { name = "Mutiger Urdiamant",         color = "meta", stats = "+324 Willenskraft, Chance auf manafreie Zauber (Heiler)" },
    [95346] = { name = "Geladener Bergkristall",     color = "meta", stats = "+324 kritische Trefferwertung, lädt Blitzentladung auf (Nahkampf/Fernkampf)" },
    [95344] = { name = "Unbeugsamer Bergkristall",   color = "meta", stats = "+324 Ausdauer, Chance auf 20% Schadensverringerung (Tank)" },

    --------------------------------------------------
    -- META: Urdiamanten (kaufbar)
    --------------------------------------------------

    [76884] = { name = "Agiler Urdiamant",           color = "meta", stats = "+216 Beweglichkeit, +3% kritischer Schaden" },
    [76885] = { name = "Brennender Urdiamant",       color = "meta", stats = "+216 Intelligenz, +3% kritischer Schaden" },
    [76886] = { name = "Widerscheinender Bergkristall", color = "meta", stats = "+216 Stärke, +3% kritischer Schaden" },
    [76895] = { name = "Strenger Bergkristall",         color = "meta", stats = "+432 Ausdauer, +2% Rüstung aus Gegenständen" },
    [76888] = { name = "Revitalisierender Urdiamant", color = "meta", stats = "+432 Willenskraft, +3% kritische Heilung" },

    --------------------------------------------------
    -- ROT (Rubellit): 160 Primär / 320 Sekundär
    --------------------------------------------------

    [76692] = { name = "Feingeschliffener Rubellit", color = "rot", stats = "+160 Beweglichkeit" },
    [76693] = { name = "Präziser Rubellit",          color = "rot", stats = "+320 Waffenkunde" },
    [76694] = { name = "Glänzender Rubellit",        color = "rot", stats = "+160 Intelligenz" },
    [76695] = { name = "Scheinender Rubellit",       color = "rot", stats = "+320 Parierwertung" },
    [76696] = { name = "Klobiger Rubellit",          color = "rot", stats = "+160 Stärke" },

    --------------------------------------------------
    -- GELB (Goldberyll): 320 Sekundär
    --------------------------------------------------

    [76697] = { name = "Glatter Goldberyll",       color = "gelb", stats = "+320 kritische Trefferwertung" },
    [76698] = { name = "Subtiler Goldberyll",      color = "gelb", stats = "+320 Ausweichwertung" },
    [76699] = { name = "Spiegelnder Goldberyll",   color = "gelb", stats = "+320 Tempowertung" },
    [76700] = { name = "Frakturierter Goldberyll", color = "gelb", stats = "+320 Meisterschaftswertung" },

    --------------------------------------------------
    -- BLAU (Chrysokoll)
    --------------------------------------------------

    [76636] = { name = "Massiver Chrysokoll",   color = "blau", stats = "+320 Trefferwertung" },
    [76638] = { name = "Funkelnder Chrysokoll", color = "blau", stats = "+320 Willenskraft" },
    [76639] = { name = "Gediegener Chrysokoll", color = "blau", stats = "+240 Ausdauer" },

    --------------------------------------------------
    -- ORANGE (Aragonit): 80 Primär + 160 Sekundär
    --------------------------------------------------

    [76658] = { name = "Tödlicher Aragonit",    color = "orange", stats = "+80 Beweglichkeit, +160 kritische Trefferwertung" },
    [76672] = { name = "Kunstvoller Aragonit",  color = "orange", stats = "+80 Intelligenz, +160 Meisterschaftswertung" },
    [76660] = { name = "Machtvoller Aragonit",  color = "orange", stats = "+80 Intelligenz, +160 kritische Trefferwertung" },
    [76670] = { name = "Versierter Aragonit",   color = "orange", stats = "+80 Beweglichkeit, +160 Meisterschaftswertung" },
    [76661] = { name = "Gravierter Aragonit",   color = "orange", stats = "+80 Stärke, +160 kritische Trefferwertung" },
    [76668] = { name = "Tollkühner Aragonit",   color = "orange", stats = "+80 Intelligenz, +160 Tempowertung" },
    [76669] = { name = "Wilder Aragonit",       color = "orange", stats = "+80 Stärke, +160 Tempowertung" },
    [76666] = { name = "Gewandter Aragonit",    color = "orange", stats = "+80 Beweglichkeit, +160 Tempowertung" },
    [76674] = { name = "Fachkundiger Aragonit", color = "orange", stats = "+80 Stärke, +160 Meisterschaftswertung" },
    [76659] = { name = "Listiger Aragonit",     color = "orange", stats = "+160 Waffenkunde, +160 kritische Trefferwertung" },
    [76664] = { name = "Bruchfester Aragonit",  color = "orange", stats = "+160 Parierwertung, +160 Ausweichwertung" },

    --------------------------------------------------
    -- LILA (Kunzit): 80 Primär + 160 Sekundär
    --                bzw. 120 Ausdauer bei Hybrid
    --------------------------------------------------

    [76682] = { name = "Verschleierter Kunzit",    color = "lila", stats = "+80 Intelligenz, +160 Trefferwertung" },
    [76687] = { name = "Veränderlicher Kunzit",    color = "lila", stats = "+80 Beweglichkeit, +120 Ausdauer" },
    [76690] = { name = "Kunzit des Verteidigers",  color = "lila", stats = "+160 Parierwertung, +120 Ausdauer" },
    [76691] = { name = "Stattlicher Kunzit",       color = "lila", stats = "+80 Stärke, +120 Ausdauer" },
    [76686] = { name = "Geläuterter Kunzit",       color = "lila", stats = "+80 Intelligenz, +160 Willenskraft" },
    [76680] = { name = "Glitzernder Kunzit",       color = "lila", stats = "+80 Beweglichkeit, +160 Trefferwertung" },
    [76681] = { name = "Akkurater Kunzit",         color = "lila", stats = "+160 Waffenkunde, +160 Trefferwertung" },
    [76684] = { name = "Geätzter Kunzit",          color = "lila", stats = "+80 Stärke, +160 Trefferwertung" },
    [76683] = { name = "Fixierender Kunzit",       color = "lila", stats = "+160 Parierwertung, +160 Trefferwertung" },

    --------------------------------------------------
    -- GRÜN (Dioptas): 160 + 160 Sekundär
    --                  bzw. 120 Ausdauer bei Hybrid
    --------------------------------------------------

    [76652] = { name = "Gezackter Dioptas",     color = "grün", stats = "+160 kritische Trefferwertung, +120 Ausdauer" },
    [76654] = { name = "Kraftvoller Dioptas",   color = "grün", stats = "+160 Tempowertung, +120 Ausdauer" },
    [76656] = { name = "Imposanter Dioptas",    color = "grün", stats = "+160 Meisterschaftswertung, +120 Ausdauer" },
    [76643] = { name = "Dioptas des Mentors",   color = "grün", stats = "+160 Trefferwertung, +160 Meisterschaftswertung" },
    [76642] = { name = "Blitzender Dioptas",    color = "grün", stats = "+160 Tempowertung, +160 Trefferwertung" },
    [76641] = { name = "Stechender Dioptas",    color = "grün", stats = "+160 kritische Trefferwertung, +160 Trefferwertung" },
    [76640] = { name = "Nebliger Dioptas",      color = "grün", stats = "+160 Willenskraft, +160 kritische Trefferwertung" },
    [76645] = { name = "Meditativer Dioptas",   color = "grün", stats = "+160 Willenskraft, +160 Meisterschaftswertung" },
    [76651] = { name = "Geladener Dioptas",     color = "grün", stats = "+160 Tempowertung, +160 Willenskraft" },
    [76589] = { name = "Perfekter geschickter Alexandrit", color = "grün", stats = "+160 Trefferwertung, +120 Ausdauer" },

    --------------------------------------------------
    -- JUWELIER-EXKLUSIV (Schlangenauge):
    -- 320 Primär / 480 Sekundär, nur für Juweliere
    --------------------------------------------------

    [83141] = { name = "Kühnes Schlangenauge",            color = "rot",  stats = "+320 Stärke (nur Juweliere)" },
    [83142] = { name = "Flinkes Schlangenauge",           color = "gelb", stats = "+480 Tempowertung (nur Juweliere)" },
    [83143] = { name = "Zerbrochenes Schlangenauge",      color = "gelb", stats = "+480 Meisterschaftswertung (nur Juweliere)" },
    [83144] = { name = "Starres Schlangenauge",           color = "blau", stats = "+480 Trefferwertung (nur Juweliere)" },
    [83145] = { name = "Subtiles Schlangenauge",          color = "gelb", stats = "+480 Ausweichwertung (nur Juweliere)" },
    [83146] = { name = "Glattes Schlangenauge",           color = "gelb", stats = "+480 kritische Trefferwertung (nur Juweliere)" },
    [83147] = { name = "Präzises Schlangenauge",          color = "rot",  stats = "+480 Waffenkunde (nur Juweliere)" },
    [83148] = { name = "Gediegenes Schlangenauge",        color = "blau", stats = "+480 Ausdauer (nur Juweliere)" },
    [83149] = { name = "Funkelndes Schlangenauge",        color = "blau", stats = "+480 Willenskraft (nur Juweliere)" },
    [83150] = { name = "Glänzendes Schlangenauge",        color = "rot",  stats = "+320 Intelligenz (nur Juweliere)" },
    [83151] = { name = "Feingeschliffenes Schlangenauge", color = "rot",  stats = "+320 Beweglichkeit (nur Juweliere)" },
    [83152] = { name = "Blitzendes Schlangenauge",        color = "rot",  stats = "+480 Parierwertung (nur Juweliere)" },
}

--------------------------------------------------
-- Hilfsfunktion: Gem-Name ermitteln
-- Bevorzugt IMMER den lokalisierten Client-Namen
-- (GetItemInfo) — der ist garantiert korrekt übersetzt.
-- Fallback: eigene Datenbank, solange das Item noch
-- nicht im Client-Cache ist.
--------------------------------------------------
function WeintCodex_GetGemName(gemId)
    if not gemId then return "—" end
    local name = GetItemInfo and GetItemInfo(gemId)
    if name and name ~= "" then return name end
    local gem = WeintCodex_Gems[gemId]
    if gem and gem.name then return gem.name end
    return "Unbekannter Stein (ID: " .. tostring(gemId) .. ")"
end

--------------------------------------------------
-- Hilfsfunktion: Ist Gem in der Akzeptanzliste?
--------------------------------------------------
function WeintCodex_IsGemAccepted(gemId, acceptedList)
    if not gemId or not acceptedList then return false end
    for _, id in ipairs(acceptedList) do
        if id == gemId then return true end
    end
    return false
end
