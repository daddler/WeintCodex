--------------------------------------------------
-- WeintCodex :: Rotationstrainer-Prioritätenlisten
-- Mists of Pandaria Classic
--
-- Datengrundlage: etablierte MoP-Classic-Single-Target-Prioritäten
-- (Community-Standard, wie auch data/spec_profiles.lua mit
-- "Quelle: wowhead.com/mop-classic" zitiert). Bewusst vereinfacht:
--   * nur Single-Target, keine AoE-/Cleave-Sonderregeln
--   * kein volles SimC/Hekili-APL (keine Verschachtelung, kein
--     Cooldown-Pooling) - siehe modules/rotationtrainer.lua
--   * Aura-/Prozentwerte sind Best-Effort und wurden nicht am
--     Live-Client verifiziert; beim ersten Ingame-Test (/wc training)
--     prüfen und bei Bedarf nachziehen.
--
-- Struktur pro Spec (Schlüssel wie WeintCodex_SpecProfiles):
--   { spell = SpellID, <Bedingung> }
-- Von oben nach unten geprüft; die erste Regel, deren Bedingung erfüllt
-- ist UND deren Spell gerade bekannt und nicht auf Cooldown ist, gilt
-- als "erwartete Aktion". Jede Liste endet mit einer always-Regel als
-- Filler, damit es immer eine erwartete Aktion gibt.
--
-- Bedingungen (genau ein Feld pro Regel, neben always):
--   always        = true              -- immer gültig (Filler, letzte Regel)
--   execute       = ZielHP-Prozent     -- nur unterhalb dieser Ziel-Lebenspunkte
--   buffPresent   = AuraSpellID        -- Buff auf dem Spieler aktiv
--   buffMissing   = AuraSpellID        -- Buff auf dem Spieler NICHT aktiv
--   debuffPresent = AuraSpellID        -- eigener Debuff auf dem Ziel aktiv
--   debuffMissing = AuraSpellID        -- eigener Debuff auf dem Ziel NICHT aktiv
--   power         = { type = "RAGE"|"ENERGY"|"FOCUS"|"MANA"|
--                             "RUNIC_POWER"|"CHI"|"HOLY_POWER",
--                      atLeast = Zahl }
--
-- Namen/Icons werden zur Laufzeit über GetSpellInfo/GetSpellTexture
-- aufgelöst, nicht gespeichert - dieselbe Doktrin wie
-- WeintCodex_GetGemName (gems.lua) und data/bis.lua.
--------------------------------------------------

WeintCodex_Rotations = {

    --------------------------------------------------
    -- KRIEGER
    --------------------------------------------------

    WARRIOR_ARMS = {
        { spell = 5308,   execute = 20 },                                   -- Vernichtungsstoß
        { spell = 86346 },                                                  -- Koloss-Verwüstung (CD)
        { spell = 12294 },                                                  -- Wuchtschlag (CD)
        { spell = 7384,   buffPresent = 60503 },                            -- Übermacht (Blutgeschmack-Prozz)
        { spell = 772,    debuffMissing = 772 },                            -- Verwunden
        { spell = 1464,   always = true },                                  -- Wirbelschlag (Filler)
    },

    WARRIOR_FURY = {
        { spell = 5308,   execute = 20 },                                   -- Vernichtungsstoß
        { spell = 85288,  buffPresent = 12880 },                            -- Wutender Schlag (bei Erzürnen)
        { spell = 23881 },                                                  -- Blutdurst (CD)
        { spell = 100130 },                                                 -- Wilder Hieb
        { spell = 78,     always = true },                                  -- Heroischer Schlag (Filler)
    },

    --------------------------------------------------
    -- PALADIN
    --------------------------------------------------

    PALADIN_RETRIBUTION = {
        { spell = 24275,  execute = 20 },                                   -- Hammer des Zorns
        { spell = 85256,  power = { type = "HOLY_POWER", atLeast = 3 } },   -- Templerurteil
        { spell = 35395 },                                                  -- Kreuzritteransturm (CD)
        { spell = 20271 },                                                  -- Urteil (CD)
        { spell = 879,    always = true },                                  -- Exorzismus (Filler)
    },

    --------------------------------------------------
    -- JÄGER
    --------------------------------------------------

    HUNTER_BEASTMASTERY = {
        { spell = 61006,  execute = 20 },                                   -- Todesschuss
        { spell = 34026 },                                                  -- Kommando (CD)
        { spell = 77767,  always = true },                                  -- Kobraschuss (Filler)
    },

    HUNTER_MARKSMANSHIP = {
        { spell = 61006,  execute = 20 },                                   -- Todesschuss
        { spell = 53209 },                                                  -- Chimärenschuss (CD)
        { spell = 19434 },                                                  -- Gezielter Schuss
        { spell = 56641,  always = true },                                  -- Zielsicherer Schuss (Filler)
    },

    HUNTER_SURVIVAL = {
        { spell = 61006,  execute = 20 },                                   -- Todesschuss
        { spell = 53301 },                                                  -- Explosivschuss (CD)
        { spell = 3674,   debuffMissing = 3674 },                           -- Schwarzer Pfeil
        { spell = 77767,  always = true },                                  -- Kobraschuss (Filler)
    },

    --------------------------------------------------
    -- SCHURKE
    --------------------------------------------------

    ROGUE_ASSASSINATION = {
        { spell = 79140 },                                                  -- Vendetta (CD)
        { spell = 32645,  power = { type = "ENERGY", atLeast = 35 } },      -- Envenom
        { spell = 1943,   debuffMissing = 1943 },                           -- Innere Blutung
        { spell = 5374,   always = true },                                  -- Verstümmeln (Filler)
    },

    ROGUE_COMBAT = {
        { spell = 51690 },                                                  -- Mordserie (CD)
        { spell = 84617,  debuffMissing = 84617 },                          -- Aufschlussreicher Hieb
        { spell = 2098,   debuffPresent = 84617 },                          -- Ausweiden
        { spell = 1752,   always = true },                                  -- Meuchelschlag (Filler)
    },

    ROGUE_SUBTLETY = {
        { spell = 1943,   debuffMissing = 1943 },                           -- Innere Blutung
        { spell = 2098,   power = { type = "ENERGY", atLeast = 35 } },      -- Ausweiden
        { spell = 16511,  debuffMissing = 16511 },                          -- Häморrhagie
        { spell = 53,     always = true },                                  -- Meucheln (Filler)
    },

    --------------------------------------------------
    -- PRIESTER
    --------------------------------------------------

    PRIEST_SHADOW = {
        { spell = 32379,  execute = 20 },                                   -- Schattenwort: Tod
        { spell = 34914,  debuffMissing = 34914 },                          -- Vampirberührung
        { spell = 589,    debuffMissing = 589 },                            -- Schattenwort: Schmerz
        { spell = 8092 },                                                   -- Gedankenschlag (CD)
        { spell = 15407,  always = true },                                  -- Gedankenschinden (Filler)
    },

    --------------------------------------------------
    -- TODESRITTER
    --------------------------------------------------

    DEATHKNIGHT_FROST = {
        { spell = 45477,  debuffMissing = 59921 },                          -- Frostberührung (Frostfieber)
        { spell = 45462,  debuffMissing = 55078 },                          -- Pestschlag (Blutpest)
        { spell = 49020,  buffPresent = 51124 },                            -- Vernichten (Todesmaschine)
        { spell = 49143,  power = { type = "RUNIC_POWER", atLeast = 40 } }, -- Frostschlag
        { spell = 49020,  always = true },                                 -- Vernichten (Filler)
    },

    DEATHKNIGHT_UNHOLY = {
        { spell = 45477,  debuffMissing = 59921 },                          -- Frostberührung (Frostfieber)
        { spell = 45462,  debuffMissing = 55078 },                          -- Pestschlag (Blutpest)
        { spell = 55090,  always = true },                                 -- Geißelstoß / Scourge Strike (Hauptschaden, mit Verderbnis-/Todesrunen)
        { spell = 85948,  always = true },                                 -- Fäulnisschlag (mit Blut-/Frostrunen, wenn Geißelstoß nicht bereit)
        { spell = 47541,  power = { type = "RUNIC_POWER", atLeast = 40 } }, -- Todesspirale (Runenmacht-Dump)
    },

    --------------------------------------------------
    -- SCHAMANE
    --------------------------------------------------

    SHAMAN_ELEMENTAL = {
        { spell = 51505,  debuffPresent = 8050 },                           -- Lavasturm (mit Flammenschock)
        { spell = 8050,   debuffMissing = 8050 },                           -- Flammenschock
        { spell = 8042 },                                                   -- Erdschock (CD)
        { spell = 403,    always = true },                                  -- Blitzschlag (Filler)
    },

    SHAMAN_ENHANCEMENT = {
        { spell = 17364 },                                                  -- Sturmschlag (CD)
        { spell = 60103 },                                                  -- Lavaklinge (CD)
        { spell = 73680 },                                                  -- Elemente entfesseln (CD)
        { spell = 403,    always = true },                                  -- Blitzschlag (Filler)
    },

    --------------------------------------------------
    -- MAGIER
    --------------------------------------------------

    MAGE_ARCANE = {
        { spell = 5143,   buffPresent = 79683 },                            -- Arkane Geschosse (Geschossbarrage)
        { spell = 44425,  buffPresent = 36032 },                            -- Arkanes Sperrfeuer (4 Ladungen)
        { spell = 30451,  always = true },                                  -- Arkaner Explosionsschub (Filler)
    },

    MAGE_FIRE = {
        { spell = 11366,  buffPresent = 48108 },                            -- Pyroschlag (Hitzestoß)
        { spell = 11129 },                                                  -- Verbrennung (CD)
        { spell = 108853 },                                                 -- Inferno-Explosion (CD)
        { spell = 133,    always = true },                                  -- Feuerball (Filler)
    },

    MAGE_FROST = {
        { spell = 30455,  buffPresent = 44544 },                            -- Eislanze (Frostfinger)
        { spell = 84714 },                                                  -- Frostkugel (CD)
        { spell = 116,    always = true },                                  -- Frostblitz (Filler)
    },

    --------------------------------------------------
    -- HEXENMEISTER
    --------------------------------------------------

    WARLOCK_AFFLICTION = {
        { spell = 1120,   execute = 20 },                                   -- Seele entziehen
        { spell = 980,    debuffMissing = 980 },                            -- Qual
        { spell = 172,    debuffMissing = 172 },                            -- Verderben
        { spell = 30108,  debuffMissing = 30108 },                          -- Unbeständiges Leiden
        { spell = 103103, always = true },                                  -- Bösartiger Griff (Filler)
    },

    WARLOCK_DEMONOLOGY = {
        { spell = 105174 },                                                 -- Hand Gul'dans (CD)
        { spell = 172,    debuffMissing = 172 },                            -- Verderben
        { spell = 686,    always = true },                                  -- Schattenblitz (Filler)
    },

    WARLOCK_DESTRUCTION = {
        { spell = 116858 },                                                 -- Chaosblitz (CD/Spender)
        { spell = 17962 },                                                  -- Auflodern (CD)
        { spell = 348,    debuffMissing = 348 },                            -- Auslöschung
        { spell = 29722,  always = true },                                  -- Versengen (Filler)
    },

    --------------------------------------------------
    -- MÖNCH
    --------------------------------------------------

    MONK_WINDWALKER = {
        { spell = 107428 },                                                 -- Tritt der aufgehenden Sonne (CD)
        { spell = 113656, power = { type = "CHI", atLeast = 3 } },          -- Fäuste der Wut
        { spell = 100784, power = { type = "CHI", atLeast = 2 } },          -- Ohnmachtstritt
        { spell = 100780, always = true },                                  -- Tigerhandfläche (Filler)
    },

    --------------------------------------------------
    -- DRUIDE
    --------------------------------------------------

    DRUID_BALANCE = {
        { spell = 78674 },                                                  -- Sternensturz (CD)
        { spell = 8921,   debuffMissing = 8921 },                           -- Mondfeuer
        { spell = 93402,  debuffMissing = 93402 },                          -- Sonnenfeuer
        { spell = 2912,   always = true },                                  -- Sternenfeuer (Filler)
    },

    DRUID_FERAL = {
        { spell = 22568,  execute = 25 },                                   -- Reißende Bisswunde
        { spell = 1079,   debuffMissing = 1079 },                           -- Zerreißen
        { spell = 1822,   debuffMissing = 1822 },                           -- Aufschlitzen
        { spell = 5217 },                                                   -- Tigerwut (CD)
        { spell = 5221,   always = true },                                  -- Zerfetzen (Filler)
    },

}

--------------------------------------------------
-- DRIFT-SCHUTZ
--
-- Analog WeintCodex_ValidateSpecData/WeintCodex_ValidateBiSData: warnt,
-- wenn eine Rotationsliste eine Spec referenziert, die es in
-- spec_profiles.lua nicht (mehr) gibt.
--------------------------------------------------

function WeintCodex_ValidateRotationData()
    if type(WeintCodex_Rotations) ~= "table" then return end

    local problems = {}

    for specKey, rules in pairs(WeintCodex_Rotations) do

        if WeintCodex_SpecProfiles and not WeintCodex_SpecProfiles[specKey] then
            problems[#problems + 1] = string.format(
                "%s: Spec-Schlüssel existiert nicht in spec_profiles.lua", specKey)
        end

        if type(rules) ~= "table" or #rules == 0 then
            problems[#problems + 1] = string.format(
                "%s: keine gültige Regelliste", specKey)
        else
            local hasAlways = false
            for index, rule in ipairs(rules) do
                if type(rule.spell) ~= "number" then
                    problems[#problems + 1] = string.format(
                        "%s Regel #%d: keine gültige Spell-ID", specKey, index)
                end
                if rule.always then hasAlways = true end
            end
            if not hasAlways then
                problems[#problems + 1] = string.format(
                    "%s: keine always-Regel als Filler vorhanden", specKey)
            end
        end

    end

    if #problems > 0 then
        print("|cffC8763A[WeintCodex]|r |cffff5555Datenprüfung (Rotationen): "
            .. #problems .. " Problem(e):|r")
        for _, msg in ipairs(problems) do
            print("  |cffff9900" .. msg .. "|r")
        end
    end
    return problems
end
