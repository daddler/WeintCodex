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
-- Deutsche Grundsteine (MoP):
--   Meta   = Urdiamant            Rot    = Urzeitrubin
--   Gelb   = Sonnenglanz          Blau   = Flussherz
--   Orange = Zinnoberonyx         Lila   = Kaiseramethyst
--   Grün   = Wildjade             JC     = Schlangenauge
--------------------------------------------------

WeintCodex_Gems = {

    --------------------------------------------------
    -- META: Legendäre Urdiamanten (Wrathion-Questreihe)
    --------------------------------------------------

    [95347] = { name = "Finsterer Urdiamant",       color = "meta", stats = "+324 kritische Trefferwertung, Chance auf 30% Zaubertempo (Caster-DPS)" },
    [95345] = { name = "Mutiger Urdiamant",         color = "meta", stats = "+324 Willenskraft, Chance auf manafreie Zauber (Heiler)" },
    [95346] = { name = "Kapazitiver Urdiamant",     color = "meta", stats = "+324 kritische Trefferwertung, lädt Blitzentladung auf (Nahkampf/Fernkampf)" },
    [95344] = { name = "Unbezähmbarer Urdiamant",   color = "meta", stats = "+324 Ausdauer, Chance auf 20% Schadensverringerung (Tank)" },

    --------------------------------------------------
    -- META: Urdiamanten (kaufbar)
    --------------------------------------------------

    [76884] = { name = "Agiler Urdiamant",           color = "meta", stats = "+216 Beweglichkeit, +3% kritischer Schaden" },
    [76885] = { name = "Brennender Urdiamant",       color = "meta", stats = "+216 Intelligenz, +3% kritischer Schaden" },
    [76886] = { name = "Widerhallender Urdiamant",   color = "meta", stats = "+216 Stärke, +3% kritischer Schaden" },
    [76895] = { name = "Asketischer Urdiamant",      color = "meta", stats = "+432 Ausdauer, +2% Rüstung aus Gegenständen" },
    [76888] = { name = "Revitalisierender Urdiamant", color = "meta", stats = "+432 Willenskraft, +3% kritische Heilung" },

    --------------------------------------------------
    -- ROT (Urzeitrubin): 160 Primär / 320 Sekundär
    --------------------------------------------------

    [76692] = { name = "Feingeschliffener Urzeitrubin", color = "rot", stats = "+160 Beweglichkeit" },
    [76693] = { name = "Präziser Urzeitrubin",          color = "rot", stats = "+320 Waffenkunde" },
    [76694] = { name = "Glänzender Urzeitrubin",        color = "rot", stats = "+160 Intelligenz" },
    [76695] = { name = "Blitzender Urzeitrubin",        color = "rot", stats = "+320 Parierwertung" },
    [76696] = { name = "Kühner Urzeitrubin",            color = "rot", stats = "+160 Stärke" },

    --------------------------------------------------
    -- GELB (Sonnenglanz): 320 Sekundär
    --------------------------------------------------

    [76697] = { name = "Glatter Sonnenglanz",      color = "gelb", stats = "+320 kritische Trefferwertung" },
    [76698] = { name = "Subtiler Sonnenglanz",     color = "gelb", stats = "+320 Ausweichwertung" },
    [76699] = { name = "Flinker Sonnenglanz",      color = "gelb", stats = "+320 Tempowertung" },
    [76700] = { name = "Zerbrochener Sonnenglanz", color = "gelb", stats = "+320 Meisterschaftswertung" },

    --------------------------------------------------
    -- BLAU (Flussherz)
    --------------------------------------------------

    [76636] = { name = "Starres Flussherz",    color = "blau", stats = "+320 Trefferwertung" },
    [76638] = { name = "Funkelndes Flussherz", color = "blau", stats = "+320 Willenskraft" },
    [76639] = { name = "Gediegenes Flussherz", color = "blau", stats = "+240 Ausdauer" },

    --------------------------------------------------
    -- ORANGE (Zinnoberonyx): 80 Primär + 160 Sekundär
    --------------------------------------------------

    [76658] = { name = "Tödlicher Zinnoberonyx",    color = "orange", stats = "+80 Beweglichkeit, +160 kritische Trefferwertung" },
    [76672] = { name = "Kunstvoller Zinnoberonyx",  color = "orange", stats = "+80 Intelligenz, +160 Meisterschaftswertung" },
    [76660] = { name = "Machtvoller Zinnoberonyx",  color = "orange", stats = "+80 Intelligenz, +160 kritische Trefferwertung" },
    [76670] = { name = "Versierter Zinnoberonyx",   color = "orange", stats = "+80 Beweglichkeit, +160 Meisterschaftswertung" },
    [76661] = { name = "Gravierter Zinnoberonyx",   color = "orange", stats = "+80 Stärke, +160 kritische Trefferwertung" },
    [76668] = { name = "Tollkühner Zinnoberonyx",   color = "orange", stats = "+80 Intelligenz, +160 Tempowertung" },
    [76669] = { name = "Wilder Zinnoberonyx",       color = "orange", stats = "+80 Stärke, +160 Tempowertung" },
    [76666] = { name = "Gewandter Zinnoberonyx",    color = "orange", stats = "+80 Beweglichkeit, +160 Tempowertung" },
    [76674] = { name = "Fachkundiger Zinnoberonyx", color = "orange", stats = "+80 Stärke, +160 Meisterschaftswertung" },

    --------------------------------------------------
    -- LILA (Kaiseramethyst): 80 Primär + 160 Sekundär
    --                        bzw. 120 Ausdauer bei Hybrid
    --------------------------------------------------

    [76682] = { name = "Verschleierter Kaiseramethyst",    color = "lila", stats = "+80 Intelligenz, +160 Trefferwertung" },
    [76687] = { name = "Veränderlicher Kaiseramethyst",    color = "lila", stats = "+80 Beweglichkeit, +120 Ausdauer" },
    [76690] = { name = "Kaiseramethyst des Verteidigers",  color = "lila", stats = "+160 Parierwertung, +120 Ausdauer" },
    [76691] = { name = "Stattlicher Kaiseramethyst",       color = "lila", stats = "+80 Stärke, +120 Ausdauer" },
    [76686] = { name = "Geläuterter Kaiseramethyst",       color = "lila", stats = "+80 Intelligenz, +160 Willenskraft" },
    [76680] = { name = "Glitzernder Kaiseramethyst",       color = "lila", stats = "+80 Beweglichkeit, +160 Trefferwertung" },
    [76681] = { name = "Akkurater Kaiseramethyst",         color = "lila", stats = "+160 Waffenkunde, +160 Trefferwertung" },
    [76684] = { name = "Geätzter Kaiseramethyst",          color = "lila", stats = "+80 Stärke, +160 Trefferwertung" },

    --------------------------------------------------
    -- GRÜN (Wildjade): 160 + 160 Sekundär
    --                  bzw. 120 Ausdauer bei Hybrid
    --------------------------------------------------

    [76652] = { name = "Gezackte Wildjade",     color = "grün", stats = "+160 kritische Trefferwertung, +120 Ausdauer" },
    [76654] = { name = "Kraftvolle Wildjade",   color = "grün", stats = "+160 Tempowertung, +120 Ausdauer" },
    [76656] = { name = "Imposante Wildjade",    color = "grün", stats = "+160 Meisterschaftswertung, +120 Ausdauer" },
    [76643] = { name = "Wildjade des Mentors",  color = "grün", stats = "+160 Trefferwertung, +160 Meisterschaftswertung" },
    [76642] = { name = "Blitzende Wildjade",    color = "grün", stats = "+160 Tempowertung, +160 Trefferwertung" },
    [76641] = { name = "Stechende Wildjade",    color = "grün", stats = "+160 kritische Trefferwertung, +160 Trefferwertung" },
    [76640] = { name = "Neblige Wildjade",      color = "grün", stats = "+160 Willenskraft, +160 kritische Trefferwertung" },
    [76645] = { name = "Meditative Wildjade",   color = "grün", stats = "+160 Willenskraft, +160 Meisterschaftswertung" },
    [76651] = { name = "Geladene Wildjade",     color = "grün", stats = "+160 Tempowertung, +160 Willenskraft" },

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
