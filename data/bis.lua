--------------------------------------------------
-- WeintCodex :: BiS-Listen (Best in Slot)
-- Mists of Pandaria Classic - Schlacht um Orgrimmar
--
-- Wird im Bossguide in der rechten Spalte unter den Notizen angezeigt:
-- beim Öffnen eines Bosses sieht man sofort, ob dieser Boss ein BiS-Item
-- für die eigene Spec droppt und ob man es bereits trägt.
--
--------------------------------------------------
-- STRUKTUR
--
-- WeintCodex_BiS[<SPEC_KEY>] = { <Eintrag>, <Eintrag>, ... }
--
-- <SPEC_KEY> ist derselbe Schlüssel wie in spec_profiles.lua
-- (WARRIOR_ARMS, PALADIN_HOLY, ...). Die *_OFFENSIVE-Varianten der
-- Tanks bekommen KEINE eigene Liste - Def- und Off-Spielstil tragen
-- dieselbe Ausrüstung.
--
-- Ein Eintrag:
--   {
--       id       = 105679,                     -- PFLICHT: Item-ID
--       slot     = "Kopf",                     -- PFLICHT: siehe SLOT-LISTE
--       boss     = "Garrosh Höllschrei",       -- PFLICHT: siehe BOSS-LISTE
--       variants = { 105028, 104398 },         -- optional
--       note     = "Tier 16",                  -- optional
--   }
--
-- id       Item-ID der angestrebten BiS-Variante (in der Regel die
--          höchste Schwierigkeit, die man realistisch anstrebt).
--          Der Anzeigename wird NICHT hier gepflegt, sondern zur
--          Laufzeit per GetItemInfo geholt - damit stimmt er immer
--          mit der Client-Sprache überein (gleiche Doktrin wie
--          WeintCodex_GetGemName in gems.lua).
--
-- slot     Logischer Slot. Bewusst "Finger"/"Schmuck" ohne Nummer:
--          ein BiS-Ring ist nicht auf Ringplatz 1 oder 2 festgelegt.
--          Die Zuordnung auf die echten Inventarslots übernimmt
--          modules/bis.lua.
--
-- boss     Name des Bosses, der das Item droppt. Muss EXAKT einem
--          Schlüssel aus WeintCodex_BossData entsprechen (deutsche
--          Schreibweise inkl. Umlaute). Darf auch eine Liste sein,
--          wenn dasselbe Item bei mehreren Bossen fällt:
--              boss = { "Malkorok", "General Nazgrim" }
--
-- variants Item-IDs derselben Rüstung in anderen Schwierigkeitsgraden.
--          In MoP haben LFR / Flex / Normal / Heroisch eigene IDs.
--          Trägt man eine dieser Varianten, zeigt die Liste einen
--          gelben Hinweis statt des grünen Hakens: man hat das Item
--          im Prinzip, will aber noch auf die bessere Version würfeln.
--
-- note     Freitext, wird klein unter dem Itemnamen angezeigt
--          (z.B. "Tier 16", "nur mit 4er-Bonus").
--
--------------------------------------------------
-- SLOT-LISTE (gültige Werte für slot)
--
--   Kopf, Hals, Schultern, Umhang, Brust, Handgelenke, Hände,
--   Taille, Beine, Füße, Finger, Schmuck, Haupthand, Nebenhand
--
--------------------------------------------------
-- BOSS-LISTE (gültige Werte für boss)
--
--   Immerseus
--   Die gefallenen Beschützer
--   Norushen
--   Sha des Stolzes
--   Galakras
--   Eiserner Koloss
--   Dunkelschamanen
--   General Nazgrim
--   Malkorok
--   Die Schätze Pandarias
--   Thok der Blutdürstige
--   Belagerungsingenieur Rußschmied
--   Die Getreuen der Klaxxi
--   Garrosh Höllschrei
--
-- Vertippt man sich bei Slot oder Boss, meldet sich beim Einloggen
-- WeintCodex_ValidateBiSData() im Chat (siehe Dateiende).
--------------------------------------------------

WeintCodex_BiS = {

    --------------------------------------------------
    -- KRIEGER
    --------------------------------------------------

    -- ####################################################################
    -- # BEISPIELDATEN - NOCH NICHT GEPFLEGT                              #
    -- #                                                                  #
    -- # Die folgenden drei Specs enthalten Platzhalter-Eintraege, damit  #
    -- # sich Anzeige, Haken und Tooltip in-game testen lassen. Die       #
    -- # Item-IDs sind NICHT verifiziert - im Spiel steht dort also       #
    -- # moeglicherweise ein ganz anderer Gegenstand. Alle Eintraege      #
    -- # sind mit note = "PLATZHALTER" markiert und beim Eintragen der    #
    -- # echten BiS-Liste ersatzlos zu loeschen.                          #
    -- ####################################################################

    WARRIOR_ARMS = {
        { slot = "Schmuck", boss = "Malkorok",          id = 105113, note = "PLATZHALTER" },
        { slot = "Kopf",    boss = "Garrosh Höllschrei", id = 105679, note = "PLATZHALTER" },
        { slot = "Finger",  boss = "Immerseus",          id = 105673, note = "PLATZHALTER" },
    },

    WARRIOR_FURY = {},

    WARRIOR_PROTECTION = {
        { slot = "Schmuck", boss = "Immerseus", id = 105111, note = "PLATZHALTER" },
    },

    --------------------------------------------------
    -- PALADIN
    --------------------------------------------------

    PALADIN_HOLY        = {},
    PALADIN_PROTECTION  = {},

    PALADIN_RETRIBUTION = {
        { slot = "Schmuck", boss = "Thok der Blutdürstige", id = 105110, note = "PLATZHALTER" },
        { slot = "Brust",   boss = "Die Getreuen der Klaxxi", id = 105672, note = "PLATZHALTER" },
    },

    --------------------------------------------------
    -- JÄGER
    --------------------------------------------------

    HUNTER_BEASTMASTERY  = {},
    HUNTER_MARKSMANSHIP  = {},
    HUNTER_SURVIVAL      = {},

    --------------------------------------------------
    -- SCHURKE
    --------------------------------------------------

    ROGUE_ASSASSINATION = {},
    ROGUE_COMBAT        = {},
    ROGUE_SUBTLETY      = {},

    --------------------------------------------------
    -- PRIESTER
    --------------------------------------------------

    PRIEST_DISCIPLINE = {},
    PRIEST_HOLY       = {},
    PRIEST_SHADOW     = {},

    --------------------------------------------------
    -- TODESRITTER
    --------------------------------------------------

    DEATHKNIGHT_BLOOD  = {},
    DEATHKNIGHT_FROST  = {},
    DEATHKNIGHT_UNHOLY = {},

    --------------------------------------------------
    -- SCHAMANE
    --------------------------------------------------

    SHAMAN_ELEMENTAL   = {},
    SHAMAN_ENHANCEMENT = {},
    SHAMAN_RESTORATION = {},

    --------------------------------------------------
    -- MAGIER
    --------------------------------------------------

    MAGE_ARCANE = {},
    MAGE_FIRE   = {},
    MAGE_FROST  = {},

    --------------------------------------------------
    -- HEXENMEISTER
    --------------------------------------------------

    WARLOCK_AFFLICTION  = {},
    WARLOCK_DEMONOLOGY  = {},
    WARLOCK_DESTRUCTION = {},

    --------------------------------------------------
    -- MÖNCH
    --------------------------------------------------

    MONK_BREWMASTER = {},
    MONK_MISTWEAVER = {},
    MONK_WINDWALKER = {},

    --------------------------------------------------
    -- DRUIDE
    --------------------------------------------------

    DRUID_BALANCE     = {},
    DRUID_FERAL       = {},
    DRUID_GUARDIAN    = {},
    DRUID_RESTORATION = {},
}

--------------------------------------------------
-- GÜLTIGE SLOT-NAMEN
-- Auch von modules/bis.lua genutzt, damit die Slot-Namen nur an
-- einer Stelle definiert sind.
--------------------------------------------------

WeintCodex_BiSSlots = {
    "Kopf", "Hals", "Schultern", "Umhang", "Brust",
    "Handgelenke", "Hände", "Taille", "Beine", "Füße",
    "Finger", "Schmuck", "Haupthand", "Nebenhand",
}

--------------------------------------------------
-- DRIFT-SCHUTZ
--
-- Wird beim Login aus core/main.lua aufgerufen (neben
-- WeintCodex_ValidateSpecData). Prüft, dass jeder Eintrag eine
-- Item-ID hat und dass Slot- und Bossnamen wirklich existieren -
-- ein Tippfehler im Bossnamen würde sonst still dazu führen, dass
-- das Item bei keinem Boss auftaucht.
--------------------------------------------------

function WeintCodex_ValidateBiSData()
    if type(WeintCodex_BiS) ~= "table" then return end

    local problems = {}

    local validSlots = {}
    for _, slotName in ipairs(WeintCodex_BiSSlots) do
        validSlots[slotName] = true
    end

    -- Ist BossData (noch) nicht geladen, wird der Bossname nicht geprüft,
    -- statt fälschlich jeden Eintrag zu bemängeln.
    local bossData = WeintCodex_BossData

    for specKey, entries in pairs(WeintCodex_BiS) do

        if WeintCodex_SpecProfiles and not WeintCodex_SpecProfiles[specKey] then
            problems[#problems + 1] = string.format(
                "%s: Spec-Schlüssel existiert nicht in spec_profiles.lua", specKey)
        end

        if type(entries) ~= "table" then
            problems[#problems + 1] = string.format(
                "%s: Eintragsliste ist keine Tabelle", specKey)
        else

            for index, entry in ipairs(entries) do

                if type(entry.id) ~= "number" then
                    problems[#problems + 1] = string.format(
                        "%s #%d: keine gültige Item-ID", specKey, index)
                end

                if not validSlots[entry.slot] then
                    problems[#problems + 1] = string.format(
                        "%s #%d: unbekannter Slot '%s'",
                        specKey, index, tostring(entry.slot))
                end

                if bossData then
                    local bossList = entry.boss
                    if type(bossList) == "string" then bossList = { bossList } end

                    if type(bossList) ~= "table" then
                        problems[#problems + 1] = string.format(
                            "%s #%d: kein Boss angegeben", specKey, index)
                    else
                        for _, bossName in ipairs(bossList) do
                            if not bossData[bossName] then
                                problems[#problems + 1] = string.format(
                                    "%s #%d: Boss '%s' existiert nicht in BossData.lua",
                                    specKey, index, tostring(bossName))
                            end
                        end
                    end
                end

            end

        end

    end

    if #problems > 0 then
        print("|cffC8763A[WeintCodex]|r |cffff5555BiS-Daten unvollständig:|r")
        for _, problem in ipairs(problems) do
            print("  |cffaaaaaa" .. problem .. "|r")
        end
    end

    return problems
end
