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
--          (z.B. "Tier 16", "Quelle unsicher").
--
--------------------------------------------------
-- SLOT-LISTE (gültige Werte für slot)
--
--   Kopf, Hals, Schultern, Umhang, Brust, Handgelenke, Hände,
--   Taille, Beine, Füße, Finger, Schmuck, Haupthand, Nebenhand
--
-- Der Slot "Umhang" taucht bewusst in keinem Eintrag auf: in MoP SoO
-- ist jeder Umhang eine Belohnung der legendären Questreihe, kein
-- Bossloot - er kann also nie "hier droppt das" beantworten.
--
--------------------------------------------------
-- BOSS-LISTE (gültige Werte für boss)
--
--   Immerseus
--   Die gefallenen Beschützer
--   Norushen
--   Sha des Stolzes
--   Galakras
--   Eisener Koloss
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
--
-- Mehrere Encounter haben benannte Unterbosse (z.B. droppt "General
-- Nazgrim" nichts selbst - der Kampf heißt so, die NPCs sind Sun
-- Zartherz/Rook Steinzeh/Skeer der Blutsucher etc.). Solche Quellen
-- wurden beim Eintragen auf den Encounter-Namen konsolidiert:
--   Sun Zartherz, Rook Steinzeh, Skeer der Blutsucher,
--     "The Fallen Protectors"          -> Die gefallenen Beschützer
--   Erdbrecher Haromm, Wellenbinderin Kardris, "Kor'kron Dark Shaman"
--                                       -> Dunkelschamanen
--   Kil'ruk der Windschnitter, "Paragons of the Klaxxi"
--                                       -> Die Getreuen der Klaxxi
--   Amalgam der Verderbnis (Phase von Norushen selbst)
--                                       -> Norushen
--
-- Items ohne konkreten SoO-Boss (Legendäre Questreihe, Zeitlose Insel,
-- Thron des Donners, Tortos) und Einträge ohne verifizierte Item-ID
-- wurden nicht übernommen - sie können in keiner Bossguide-Seite
-- auftauchen bzw. verletzen den Pflichtfeld-Vertrag oben. Das betrifft
-- u.a. praktisch die komplette Liste von DRUID_BALANCE (dort war jede
-- Quelle im Ausgangsmaterial nur generisch "Schlacht um Orgrimmar"
-- ohne konkreten Boss) - die Spec bleibt deshalb absichtlich leer.
--------------------------------------------------

WeintCodex_BiS = {

    --------------------------------------------------
    -- KRIEGER
    --------------------------------------------------

    WARRIOR_ARMS = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99206 },
        { slot = "Hals",        boss = "Malkorok",                        id = 103917 },
        { slot = "Schultern",   boss = "Garrosh Höllschrei",              id = 105642 },
        { slot = "Brust",       boss = "Dunkelschamanen",                 id = 103737 },
        { slot = "Handgelenke", boss = "Norushen",                        id = 103740 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99198 },
        { slot = "Taille",      boss = "Eisener Koloss",                  id = 103788 },
        { slot = "Beine",       boss = "Malkorok",                        id = 105067 },
        { slot = "Füße",        boss = "Sha des Stolzes",                 id = 103878 },
        { slot = "Finger",      boss = "Dunkelschamanen",                 id = 103798 },
        { slot = "Finger",      boss = "Dunkelschamanen",                 id = 103796 },
        { slot = "Schmuck",     boss = "Galakras",                        id = 102298 },
        { slot = "Schmuck",     boss = "Thok der Blutdürstige",           id = 105609 },
        { slot = "Haupthand",   boss = "Garrosh Höllschrei",              id = 103649 },
    },

    WARRIOR_FURY = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99206 },
        { slot = "Hals",        boss = "Malkorok",                        id = 103917 },
        { slot = "Schultern",   boss = "Garrosh Höllschrei",              id = 105642 },
        { slot = "Brust",       boss = "Dunkelschamanen",                 id = 103737 },
        { slot = "Handgelenke", boss = "Norushen",                        id = 103740 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99198 },
        { slot = "Taille",      boss = "Dunkelschamanen",                 id = 103932 },
        { slot = "Beine",       boss = "Malkorok",                        id = 105067 },
        { slot = "Füße",        boss = "Sha des Stolzes",                 id = 103878 },
        { slot = "Finger",      boss = "Dunkelschamanen",                 id = 103798 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 103896 },
        { slot = "Schmuck",     boss = "Galakras",                        id = 102298 },
        { slot = "Schmuck",     boss = "Thok der Blutdürstige",           id = 105609 },
        { slot = "Haupthand",   boss = "Garrosh Höllschrei",              id = 103649 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 103649 },
    },

    WARRIOR_PROTECTION = {
        { slot = "Kopf",        boss = "Garrosh Höllschrei",              id = 103840 },
        { slot = "Hals",        boss = "Belagerungsingenieur Rußschmied", id = 103884 },
        { slot = "Schultern",   boss = "Immerseus",                       id = 103747 },
        { slot = "Brust",       boss = "Eisener Koloss",                  id = 103914 },
        { slot = "Handgelenke", boss = "Malkorok",                        id = 103742 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99202 },
        { slot = "Taille",      boss = "Die Schätze Pandarias",           id = 103933 },
        { slot = "Beine",       boss = "Die gefallenen Beschützer",       id = 99195 },
        { slot = "Füße",        boss = "Immerseus",                       id = 103744 },
        { slot = "Finger",      boss = "Galakras",                        id = 103894 },
        { slot = "Finger",      boss = "Dunkelschamanen",                 id = 103895 },
        { slot = "Schmuck",     boss = "Die gefallenen Beschützer",       id = 105632 },
        { slot = "Schmuck",     boss = "Malkorok",                        id = 105568 },
        { slot = "Haupthand",   boss = "Dunkelschamanen",                 id = 103926 },
        { slot = "Nebenhand",   boss = "Sha des Stolzes",                 id = 103870 },
    },

    --------------------------------------------------
    -- PALADIN
    --------------------------------------------------

    PALADIN_HOLY = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99376 },
        { slot = "Hals",        boss = "Die Schätze Pandarias",           id = 105593 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99378 },
        { slot = "Brust",       boss = "Garrosh Höllschrei",              id = 105654 },
        { slot = "Handgelenke", boss = "Galakras",                        id = 105502 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99375 },
        { slot = "Taille",      boss = "Immerseus",                       id = 105427 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99377 },
        { slot = "Füße",        boss = "Die Schätze Pandarias",           id = 105600 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 105606 },
        { slot = "Finger",      boss = "Immerseus",                       id = 105423 },
        { slot = "Schmuck",     boss = "General Nazgrim",                 id = 105549 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 105474 },
        { slot = "Haupthand",   boss = "Dunkelschamanen",                 id = 105541 },
        { slot = "Nebenhand",   boss = "Norushen",                        id = 105466 },
    },

    PALADIN_PROTECTION = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99370 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99364 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99368 },
        { slot = "Handgelenke", boss = "Immerseus",                       id = 105411 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99127, note = "Quelle unsicher" },
        { slot = "Taille",      boss = "Die gefallenen Beschützer",       id = 105433 },
        { slot = "Beine",       boss = "Garrosh Höllschrei",              id = 104311 },
        { slot = "Finger",      boss = "Belagerungsingenieur Rußschmied", id = 104624 },
        { slot = "Schmuck",     boss = "Thok der Blutdürstige",           id = 105609 },
        { slot = "Schmuck",     boss = "Malkorok",                        id = 105568 },
        { slot = "Haupthand",   boss = "Malkorok",                        id = 105567, note = "Quelle unsicher" },
        { slot = "Nebenhand",   boss = "General Nazgrim",                 id = 105556 },
    },

    PALADIN_RETRIBUTION = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99379 },
        { slot = "Hals",        boss = "Malkorok",                        id = 105566 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99373 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99387 },
        { slot = "Handgelenke", boss = "Norushen",                        id = 105456 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99137, note = "Quelle unsicher" },
        { slot = "Taille",      boss = "Eisener Koloss",                  id = 105509 },
        { slot = "Beine",       boss = "Garrosh Höllschrei",              id = 104311 },
        { slot = "Füße",        boss = "Dunkelschamanen",                 id = 105282 },
        { slot = "Finger",      boss = "Dunkelschamanen",                 id = 105285 },
        { slot = "Finger",      boss = "Die Schätze Pandarias",           id = 103796 },
        { slot = "Schmuck",     boss = "Thok der Blutdürstige",           id = 105609 },
        { slot = "Haupthand",   boss = "Thok der Blutdürstige",           id = 105610, note = "Quelle unsicher" },
    },

    --------------------------------------------------
    -- JÄGER
    --------------------------------------------------

    HUNTER_BEASTMASTERY = {
        { slot = "Kopf",        boss = "Garrosh Höllschrei",              id = 99157 },
        { slot = "Hals",        boss = "Immerseus",                       id = 105158 },
        { slot = "Schultern",   boss = "Thok der Blutdürstige",           id = 99159 },
        { slot = "Brust",       boss = "Die Schätze Pandarias",           id = 104838 },
        { slot = "Handgelenke", boss = "Belagerungsingenieur Rußschmied", id = 105119 },
        { slot = "Hände",       boss = "Die Getreuen der Klaxxi",         id = 99168 },
        { slot = "Taille",      boss = "Die Schätze Pandarias",           id = 103888 },
        { slot = "Beine",       boss = "Die Schätze Pandarias",           id = 99158 },
        { slot = "Füße",        boss = "General Nazgrim",                 id = 105055 },
        { slot = "Finger",      boss = "Malkorok",                        id = 105558 },
        { slot = "Finger",      boss = "Die Getreuen der Klaxxi",         id = 103844, note = "Quelle unsicher" },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 102292 },
        { slot = "Schmuck",     boss = "Belagerungsingenieur Rußschmied", id = 102311 },
        { slot = "Haupthand",   boss = "Malkorok",                        id = 104563 },
    },

    HUNTER_MARKSMANSHIP = {
        { slot = "Kopf",        boss = "Garrosh Höllschrei",              id = 99157 },
        { slot = "Hals",        boss = "Thok der Blutdürstige",           id = 104606 },
        { slot = "Schultern",   boss = "Thok der Blutdürstige",           id = 99159 },
        { slot = "Brust",       boss = "Belagerungsingenieur Rußschmied", id = 99167 },
        { slot = "Handgelenke", boss = "Galakras",                        id = 104740 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99168 },
        { slot = "Taille",      boss = "Die Schätze Pandarias",           id = 103888 },
        { slot = "Beine",       boss = "Norushen",                        id = 104458 },
        { slot = "Füße",        boss = "General Nazgrim",                 id = 105055 },
        { slot = "Finger",      boss = "Galakras",                        id = 104985 },
        { slot = "Finger",      boss = "Norushen",                        id = 103841 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 102292 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102301 },
        { slot = "Haupthand",   boss = "Die Getreuen der Klaxxi",         id = 103886 },
    },

    HUNTER_SURVIVAL = {
        { slot = "Kopf",        boss = "Garrosh Höllschrei",              id = 99157 },
        { slot = "Hals",        boss = "Thok der Blutdürstige",           id = 104606 },
        { slot = "Schultern",   boss = "Thok der Blutdürstige",           id = 99159 },
        { slot = "Brust",       boss = "Die Schätze Pandarias",           id = 104838 },
        { slot = "Handgelenke", boss = "Malkorok",                        id = 103890 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99168 },
        { slot = "Taille",      boss = "Die Schätze Pandarias",           id = 103888 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99158 },
        { slot = "Füße",        boss = "General Nazgrim",                 id = 105055 },
        { slot = "Finger",      boss = "Die Getreuen der Klaxxi",         id = 103844, note = "Quelle unsicher" },
        { slot = "Finger",      boss = "Malkorok",                        id = 105558 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 102292 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102301 },
        { slot = "Haupthand",   boss = "Malkorok",                        id = 104563 },
    },

    --------------------------------------------------
    -- SCHURKE
    --------------------------------------------------

    ROGUE_ASSASSINATION = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99114 },
        { slot = "Hals",        boss = "Immerseus",                       id = 105158 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99116 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99112 },
        { slot = "Handgelenke", boss = "Belagerungsingenieur Rußschmied", id = 104620 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99113 },
        { slot = "Taille",      boss = "Dunkelschamanen",                 id = 103927 },
        { slot = "Beine",       boss = "Dunkelschamanen",                 id = 105031 },
        { slot = "Füße",        boss = "Galakras",                        id = 103778 },
        { slot = "Finger",      boss = "Die gefallenen Beschützer",       id = 103844 },
        { slot = "Finger",      boss = "Malkorok",                        id = 105558 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 105278 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 102292 },
        { slot = "Haupthand",   boss = "General Nazgrim",                 id = 105298 },
        { slot = "Nebenhand",   boss = "General Nazgrim",                 id = 105298 },
    },

    -- Vier Slots (Schultern/Brust/Hände/Beine) fehlen absichtlich: das
    -- Ausgangsmaterial listet dort für Kampf durchgängig Thron-des-
    -- Donners-Items (Vorpatch-Tier), keine SoO-Drops.
    ROGUE_COMBAT = {
        { slot = "Kopf",        boss = "Garrosh Höllschrei",              id = 104640 },
        { slot = "Hals",        boss = "Immerseus",                       id = 105158 },
        { slot = "Handgelenke", boss = "Belagerungsingenieur Rußschmied", id = 104620 },
        { slot = "Taille",      boss = "Dunkelschamanen",                 id = 103927 },
        { slot = "Füße",        boss = "Die Schätze Pandarias",           id = 105084 },
        { slot = "Finger",      boss = "Die gefallenen Beschützer",       id = 103844 },
        { slot = "Finger",      boss = "Galakras",                        id = 105483 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 102292 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 105278 },
        { slot = "Haupthand",   boss = "Die Schätze Pandarias",           id = 104585 },
        { slot = "Nebenhand",   boss = "Die Schätze Pandarias",           id = 104585 },
    },

    ROGUE_SUBTLETY = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99114 },
        { slot = "Hals",        boss = "Thok der Blutdürstige",           id = 104855 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99116 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99112 },
        { slot = "Handgelenke", boss = "Eisener Koloss",                  id = 103909 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99113 },
        { slot = "Taille",      boss = "Garrosh Höllschrei",              id = 103928 },
        { slot = "Beine",       boss = "Dunkelschamanen",                 id = 105031 },
        { slot = "Füße",        boss = "Die Schätze Pandarias",           id = 105084 },
        { slot = "Finger",      boss = "Norushen",                        id = 104953 },
        { slot = "Finger",      boss = "Die gefallenen Beschützer",       id = 103844 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 105278 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 102292 },
        { slot = "Haupthand",   boss = "Thok der Blutdürstige",           id = 103828 },
        { slot = "Nebenhand",   boss = "General Nazgrim",                 id = 105298 },
    },

    --------------------------------------------------
    -- PRIESTER
    --------------------------------------------------

    PRIEST_DISCIPLINE = {
        { slot = "Kopf",        boss = "Immerseus",                       id = 104424 },
        { slot = "Hals",        boss = "Die Schätze Pandarias",           id = 104597 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99358 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99357 },
        { slot = "Handgelenke", boss = "Die Getreuen der Klaxxi",         id = 104630 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99365 },
        { slot = "Taille",      boss = "Norushen",                        id = 104467 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99367 },
        { slot = "Füße",        boss = "Dunkelschamanen",                 id = 104541 },
        { slot = "Finger",      boss = "Malkorok",                        id = 104578 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 104610 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 104478 },
        { slot = "Schmuck",     boss = "General Nazgrim",                 id = 104553 },
        { slot = "Haupthand",   boss = "Die Schätze Pandarias",           id = 104598 },
        { slot = "Nebenhand",   boss = "Eisener Koloss",                  id = 104525 },
    },

    PRIEST_HOLY = {
        { slot = "Kopf",        boss = "Malkorok",                        id = 104574 },
        { slot = "Hals",        boss = "Sha des Stolzes",                 id = 104477 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99358 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99357 },
        { slot = "Handgelenke", boss = "Die gefallenen Beschützer",       id = 104446 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99365 },
        { slot = "Taille",      boss = "Norushen",                        id = 104467 },
        { slot = "Beine",       boss = "Die gefallenen Beschützer",       id = 99367 },
        { slot = "Füße",        boss = "Galakras",                        id = 103902 },
        { slot = "Finger",      boss = "Malkorok",                        id = 104578 },
        { slot = "Finger",      boss = "Immerseus",                       id = 104925 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 104478 },
        { slot = "Schmuck",     boss = "Belagerungsingenieur Rußschmied", id = 102309, note = "Quelle unsicher" },
        { slot = "Haupthand",   boss = "Galakras",                        id = 105001 },
    },

    PRIEST_SHADOW = {
        { slot = "Kopf",        boss = "Immerseus",                       id = 104424 },
        { slot = "Hals",        boss = "Sha des Stolzes",                 id = 104477 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99363 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99362 },
        { slot = "Handgelenke", boss = "Norushen",                        id = 103849 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99359 },
        { slot = "Taille",      boss = "Garrosh Höllschrei",              id = 103856 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99361 },
        { slot = "Füße",        boss = "Galakras",                        id = 104746, note = "Quelle unsicher" },
        { slot = "Finger",      boss = "Eisener Koloss",                  id = 104524 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 104610 },
        { slot = "Schmuck",     boss = "Immerseus",                       id = 102293, note = "Quelle unsicher" },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102300 },
        { slot = "Haupthand",   boss = "Garrosh Höllschrei",              id = 105400 },
        { slot = "Nebenhand",   boss = "Eisener Koloss",                  id = 104525 },
    },

    --------------------------------------------------
    -- TODESRITTER
    --------------------------------------------------

    DEATHKNIGHT_BLOOD = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99190 },
        { slot = "Hals",        boss = "Sha des Stolzes",                 id = 104733 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99179 },
        { slot = "Brust",       boss = "Eisener Koloss",                  id = 105263 },
        { slot = "Handgelenke", boss = "Malkorok",                        id = 104568 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99189 },
        { slot = "Taille",      boss = "Die Schätze Pandarias",           id = 103933 },
        { slot = "Beine",       boss = "Die gefallenen Beschützer",       id = 99191 },
        { slot = "Füße",        boss = "Immerseus",                       id = 104418 },
        { slot = "Finger",      boss = "Galakras",                        id = 104994 },
        { slot = "Finger",      boss = "Belagerungsingenieur Rußschmied", id = 104873 },
        { slot = "Schmuck",     boss = "Die gefallenen Beschützer",       id = 105383 },
        { slot = "Schmuck",     boss = "Malkorok",                        id = 104572 },
        { slot = "Haupthand",   boss = "Garrosh Höllschrei",              id = 105644 },
    },

    DEATHKNIGHT_FROST = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99194 },
        { slot = "Hals",        boss = "Malkorok",                        id = 105068 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99187 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99192 },
        { slot = "Handgelenke", boss = "Norushen",                        id = 103740, note = "Quelle unsicher" },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99193 },
        { slot = "Taille",      boss = "Eisener Koloss",                  id = 104513 },
        { slot = "Beine",       boss = "Malkorok",                        id = 103954 },
        { slot = "Füße",        boss = "Dunkelschamanen",                 id = 105282 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 105362 },
        { slot = "Finger",      boss = "Dunkelschamanen",                 id = 105534 },
        { slot = "Schmuck",     boss = "Thok der Blutdürstige",           id = 105360 },
        { slot = "Schmuck",     boss = "Die gefallenen Beschützer",       id = 105383 },
        { slot = "Haupthand",   boss = "Belagerungsingenieur Rußschmied", id = 105123 },
        { slot = "Nebenhand",   boss = "Belagerungsingenieur Rußschmied", id = 105123 },
    },

    DEATHKNIGHT_UNHOLY = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99194 },
        { slot = "Hals",        boss = "Malkorok",                        id = 105068 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99187 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99192 },
        { slot = "Handgelenke", boss = "Norushen",                        id = 103740, note = "Quelle unsicher" },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99193 },
        { slot = "Taille",      boss = "Eisener Koloss",                  id = 104513 },
        { slot = "Beine",       boss = "Malkorok",                        id = 103954 },
        { slot = "Füße",        boss = "Dunkelschamanen",                 id = 105282 },
        { slot = "Finger",      boss = "Die Schätze Pandarias",           id = 103796 },
        { slot = "Finger",      boss = "Belagerungsingenieur Rußschmied", id = 104873 },
        { slot = "Schmuck",     boss = "Thok der Blutdürstige",           id = 105360 },
        { slot = "Schmuck",     boss = "Galakras",                        id = 104993 },
        { slot = "Haupthand",   boss = "Garrosh Höllschrei",              id = 105644 },
    },

    --------------------------------------------------
    -- SCHAMANE
    --------------------------------------------------

    SHAMAN_ELEMENTAL = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99093 },
        { slot = "Hals",        boss = "Die Schätze Pandarias",           id = 105095 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99095 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99106 },
        { slot = "Handgelenke", boss = "Eisener Koloss",                  id = 104528 },
        { slot = "Hände",       boss = "Galakras",                        id = 103765 },
        { slot = "Taille",      boss = "Die Schätze Pandarias",           id = 105597 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99094 },
        { slot = "Füße",        boss = "Belagerungsingenieur Rußschmied", id = 103814 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 105357 },
        { slot = "Finger",      boss = "Eisener Koloss",                  id = 103773 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102300 },
        { slot = "Schmuck",     boss = "Immerseus",                       id = 105422 },
        { slot = "Haupthand",   boss = "Garrosh Höllschrei",              id = 103937 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 105152 },
    },

    SHAMAN_ENHANCEMENT = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99103 },
        { slot = "Hals",        boss = "Immerseus",                       id = 105158 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99105 },
        { slot = "Brust",       boss = "Die Schätze Pandarias",           id = 105585 },
        { slot = "Handgelenke", boss = "Belagerungsingenieur Rußschmied", id = 105617 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99102 },
        { slot = "Taille",      boss = "Die Schätze Pandarias",           id = 103888 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99104 },
        { slot = "Füße",        boss = "Eisener Koloss",                  id = 103731 },
        { slot = "Finger",      boss = "Die Getreuen der Klaxxi",         id = 103844 },
        { slot = "Finger",      boss = "Norushen",                        id = 104953 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 102292 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102301 },
        { slot = "Haupthand",   boss = "Die Getreuen der Klaxxi",         id = 104878 },
        { slot = "Nebenhand",   boss = "Die Getreuen der Klaxxi",         id = 104878 },
    },

    SHAMAN_RESTORATION = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99093 },
        { slot = "Hals",        boss = "Die Schätze Pandarias",           id = 105095 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99095 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99106 },
        { slot = "Handgelenke", boss = "Eisener Koloss",                  id = 104528 },
        { slot = "Hände",       boss = "Galakras",                        id = 103765 },
        { slot = "Taille",      boss = "Die Schätze Pandarias",           id = 105597 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99094 },
        { slot = "Füße",        boss = "Belagerungsingenieur Rußschmied", id = 103814 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 105357 },
        { slot = "Finger",      boss = "Eisener Koloss",                  id = 103773 },
        { slot = "Schmuck",     boss = "Thok der Blutdürstige",           id = 105109 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 105474 },
        { slot = "Haupthand",   boss = "Garrosh Höllschrei",              id = 103937 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 105152 },
    },

    --------------------------------------------------
    -- MAGIER
    --------------------------------------------------

    MAGE_ARCANE = {
        { slot = "Kopf",        boss = "Immerseus",                       id = 103751 },
        { slot = "Hals",        boss = "Norushen",                        id = 103867 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99153 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99152 },
        { slot = "Handgelenke", boss = "Die Schätze Pandarias",           id = 103851 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99160 },
        { slot = "Taille",      boss = "Eisener Koloss",                  id = 103898 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99162 },
        { slot = "Füße",        boss = "Galakras",                        id = 103805 },
        { slot = "Finger",      boss = "Die Getreuen der Klaxxi",         id = 103824 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 103774 },
        { slot = "Schmuck",     boss = "Immerseus",                       id = 102293 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102300 },
        { slot = "Haupthand",   boss = "Die Schätze Pandarias",           id = 103964 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 103920 },
    },

    MAGE_FIRE = {
        { slot = "Kopf",        boss = "Immerseus",                       id = 103751 },
        { slot = "Hals",        boss = "Norushen",                        id = 103867 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99153 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99152 },
        { slot = "Handgelenke", boss = "Die Getreuen der Klaxxi",         id = 103810 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99160 },
        { slot = "Taille",      boss = "Malkorok",                        id = 103899 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99162 },
        { slot = "Füße",        boss = "Dunkelschamanen",                 id = 103806 },
        { slot = "Finger",      boss = "Die gefallenen Beschützer",       id = 103822 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 103774 },
        { slot = "Schmuck",     boss = "Immerseus",                       id = 102293 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102300 },
        { slot = "Haupthand",   boss = "Die Schätze Pandarias",           id = 103964 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 103920 },
    },

    MAGE_FROST = {
        { slot = "Kopf",        boss = "Garrosh Höllschrei",              id = 103901 },
        { slot = "Hals",        boss = "Norushen",                        id = 103867 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99153 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99152 },
        { slot = "Handgelenke", boss = "Die Schätze Pandarias",           id = 103851 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99160 },
        { slot = "Taille",      boss = "Eisener Koloss",                  id = 103898 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99162 },
        { slot = "Füße",        boss = "Galakras",                        id = 103805 },
        { slot = "Finger",      boss = "Galakras",                        id = 103823 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 103774 },
        { slot = "Schmuck",     boss = "Immerseus",                       id = 102293 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102300 },
        { slot = "Haupthand",   boss = "Die Getreuen der Klaxxi",         id = 103973 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 103920 },
    },

    --------------------------------------------------
    -- HEXENMEISTER
    --------------------------------------------------

    WARLOCK_AFFLICTION = {
        { slot = "Kopf",        boss = "Garrosh Höllschrei",              id = 105647 },
        { slot = "Hals",        boss = "Norushen",                        id = 104967 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99205 },
        { slot = "Brust",       boss = "Die Schätze Pandarias",           id = 104845 },
        { slot = "Handgelenke", boss = "Die Schätze Pandarias",           id = 104595 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99096 },
        { slot = "Taille",      boss = "Eisener Koloss",                  id = 105017 },
        { slot = "Beine",       boss = "Eisener Koloss",                  id = 105267 },
        { slot = "Füße",        boss = "Galakras",                        id = 104995 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 105606 },
        { slot = "Finger",      boss = "Die Getreuen der Klaxxi",         id = 105628 },
        { slot = "Schmuck",     boss = "Immerseus",                       id = 102293 },
        { slot = "Schmuck",     boss = "Garrosh Höllschrei",              id = 102310 },
        { slot = "Haupthand",   boss = "Die Schätze Pandarias",           id = 103964 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 105152 },
    },

    WARLOCK_DEMONOLOGY = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99097 },
        { slot = "Hals",        boss = "Norushen",                        id = 104967 },
        { slot = "Schultern",   boss = "Thok der Blutdürstige",           id = 99205 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99204 },
        { slot = "Handgelenke", boss = "Die Schätze Pandarias",           id = 104595 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99096 },
        { slot = "Taille",      boss = "Eisener Koloss",                  id = 105017 },
        { slot = "Beine",       boss = "Eisener Koloss",                  id = 105267 },
        { slot = "Füße",        boss = "Galakras",                        id = 104995 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 105606 },
        { slot = "Finger",      boss = "Die Getreuen der Klaxxi",         id = 105628 },
        { slot = "Schmuck",     boss = "Immerseus",                       id = 102293 },
        { slot = "Haupthand",   boss = "General Nazgrim",                 id = 104554 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 105152 },
    },

    WARLOCK_DESTRUCTION = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99097 },
        { slot = "Hals",        boss = "Norushen",                        id = 104967 },
        { slot = "Schultern",   boss = "Thok der Blutdürstige",           id = 99205 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99204 },
        { slot = "Handgelenke", boss = "Die Schätze Pandarias",           id = 104595 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99096 },
        { slot = "Taille",      boss = "Eisener Koloss",                  id = 105017 },
        { slot = "Beine",       boss = "Eisener Koloss",                  id = 105267 },
        { slot = "Füße",        boss = "Galakras",                        id = 104995 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 105606 },
        { slot = "Finger",      boss = "Die Getreuen der Klaxxi",         id = 105628 },
        { slot = "Schmuck",     boss = "Immerseus",                       id = 102293 },
        { slot = "Schmuck",     boss = "Garrosh Höllschrei",              id = 102310 },
        { slot = "Haupthand",   boss = "General Nazgrim",                 id = 104554 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 105152 },
    },

    --------------------------------------------------
    -- MÖNCH
    --------------------------------------------------

    MONK_BREWMASTER = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99142 },
        { slot = "Hals",        boss = "Thok der Blutdürstige",           id = 104855, note = "Quelle unsicher" },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99144 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99140 },
        { slot = "Handgelenke", boss = "Eisener Koloss",                  id = 103909 },
        { slot = "Hände",       boss = "Norushen",                        id = 103830 },
        { slot = "Taille",      boss = "Garrosh Höllschrei",              id = 103928 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99143 },
        { slot = "Füße",        boss = "Galakras",                        id = 103778 },
        { slot = "Finger",      boss = "Norushen",                        id = 104953 },
        { slot = "Finger",      boss = "Malkorok",                        id = 103843 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102301 },
        { slot = "Schmuck",     boss = "Thok der Blutdürstige",           id = 102305 },
        { slot = "Haupthand",   boss = "Eisener Koloss",                  id = 104757, note = "Quelle unsicher" },
        { slot = "Nebenhand",   boss = "Die gefallenen Beschützer",       id = 104932 },
    },

    MONK_MISTWEAVER = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99148 },
        { slot = "Hals",        boss = "Sha des Stolzes",                 id = 104726 },
        { slot = "Schultern",   boss = "Die gefallenen Beschützer",       id = 103924 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99150 },
        { slot = "Handgelenke", boss = "Immerseus",                       id = 104927, note = "Quelle unsicher" },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99147 },
        { slot = "Taille",      boss = "Galakras",                        id = 105002, note = "Quelle unsicher" },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99149 },
        { slot = "Füße",        boss = "Immerseus",                       id = 105175 },
        { slot = "Finger",      boss = "Malkorok",                        id = 103772 },
        { slot = "Finger",      boss = "Eisener Koloss",                  id = 103773 },
        { slot = "Schmuck",     boss = "Immerseus",                       id = 102293 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 102299 },
        { slot = "Haupthand",   boss = "General Nazgrim",                 id = 105052, note = "Quelle unsicher" },
        { slot = "Nebenhand",   boss = "Eisener Koloss",                  id = 104525 },
    },

    MONK_WINDWALKER = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99156 },
        { slot = "Hals",        boss = "Immerseus",                       id = 105158 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99146 },
        { slot = "Brust",       boss = "Norushen",                        id = 105452 },
        { slot = "Handgelenke", boss = "Belagerungsingenieur Rußschmied", id = 104620 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99155 },
        { slot = "Taille",      boss = "Garrosh Höllschrei",              id = 103928 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99145 },
        { slot = "Füße",        boss = "Die Schätze Pandarias",           id = 105084 },
        { slot = "Finger",      boss = "Norushen",                        id = 104953 },
        { slot = "Finger",      boss = "Die Getreuen der Klaxxi",         id = 103844 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102301 },
        { slot = "Haupthand",   boss = "Die Getreuen der Klaxxi",         id = 104878 },
        { slot = "Nebenhand",   boss = "Die Getreuen der Klaxxi",         id = 104878 },
    },

    --------------------------------------------------
    -- DRUIDE
    --------------------------------------------------

    -- Absichtlich leer: im Ausgangsmaterial war für diese Spec bei
    -- praktisch jedem Slot nur "Schlacht um Orgrimmar" als Quelle
    -- angegeben, ohne konkreten Boss. Siehe Kommentar am Dateianfang.
    DRUID_BALANCE = {},

    DRUID_FERAL = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99182 },
        { slot = "Hals",        boss = "Immerseus",                       id = 104909 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99184 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99180 },
        { slot = "Handgelenke", boss = "Belagerungsingenieur Rußschmied", id = 104620 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99181 },
        { slot = "Taille",      boss = "Garrosh Höllschrei",              id = 103928 },
        { slot = "Beine",       boss = "Dunkelschamanen",                 id = 104533 },
        { slot = "Füße",        boss = "Die Schätze Pandarias",           id = 105084 },
        { slot = "Finger",      boss = "Die Getreuen der Klaxxi",         id = 105375 },
        { slot = "Finger",      boss = "Galakras",                        id = 104985 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102301 },
        { slot = "Haupthand",   boss = "Malkorok",                        id = 104564 },
    },

    DRUID_GUARDIAN = {
        { slot = "Kopf",        boss = "Thok der Blutdürstige",           id = 99164 },
        { slot = "Hals",        boss = "Thok der Blutdürstige",           id = 104855 },
        { slot = "Schultern",   boss = "Eisener Koloss",                  id = 104759 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99170 },
        { slot = "Handgelenke", boss = "Eisener Koloss",                  id = 103909 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99623 },
        { slot = "Taille",      boss = "Dunkelschamanen",                 id = 104532 },
        { slot = "Beine",       boss = "Die gefallenen Beschützer",       id = 98981 },
        { slot = "Füße",        boss = "Galakras",                        id = 103778 },
        { slot = "Finger",      boss = "Norushen",                        id = 104953 },
        { slot = "Finger",      boss = "Galakras",                        id = 104985 },
        { slot = "Schmuck",     boss = "Dunkelschamanen",                 id = 102301 },
        { slot = "Schmuck",     boss = "Malkorok",                        id = 105568 },
        { slot = "Haupthand",   boss = "Immerseus",                       id = 104910 },
    },

    DRUID_RESTORATION = {
        { slot = "Kopf",        boss = "Sha des Stolzes",                 id = 104978 },
        { slot = "Hals",        boss = "Die Schätze Pandarias",           id = 105095 },
        { slot = "Schultern",   boss = "Belagerungsingenieur Rußschmied", id = 99173 },
        { slot = "Brust",       boss = "Sha des Stolzes",                 id = 99172 },
        { slot = "Handgelenke", boss = "Malkorok",                        id = 103758 },
        { slot = "Hände",       boss = "General Nazgrim",                 id = 99185 },
        { slot = "Taille",      boss = "Garrosh Höllschrei",              id = 104655 },
        { slot = "Beine",       boss = "Die Getreuen der Klaxxi",         id = 99171 },
        { slot = "Füße",        boss = "Immerseus",                       id = 105175 },
        { slot = "Finger",      boss = "Immerseus",                       id = 104925 },
        { slot = "Finger",      boss = "Thok der Blutdürstige",           id = 104610 },
        { slot = "Schmuck",     boss = "Sha des Stolzes",                 id = 102299 },
        { slot = "Schmuck",     boss = "General Nazgrim",                 id = 102294 },
        { slot = "Haupthand",   boss = "Garrosh Höllschrei",              id = 105400 },
        { slot = "Nebenhand",   boss = "Garrosh Höllschrei",              id = 105401 },
    },
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
