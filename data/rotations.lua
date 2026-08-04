--------------------------------------------------
-- WeintCodex :: Rotationshelfer-Prioritätenlisten
-- Mists of Pandaria Classic (5.4)
--
-- Datengrundlage: etablierte MoP-Classic-Single-Target-Prioritäten
-- (Community-Standard, wie auch data/spec_profiles.lua mit
-- "Quelle: wowhead.com/mop-classic" zitiert). Bewusst vereinfacht:
--   * nur Single-Target, keine AoE-/Cleave-Sonderregeln
--   * kein volles SimC/Hekili-APL (kein Ressourcen-Pooling, keine
--     Cooldown-Ausrichtung) - siehe modules/rotation_engine.lua
--   * Aura-/Prozentwerte sind Best-Effort. "/wc training check" gibt
--     für die aktuelle Spec jede Regel mit Spell-ID, Client-Namen und
--     Gelernt-Status aus - damit lässt sich eine falsche ID zeilengenau
--     melden, ohne den Rest der Liste anzufassen.
--
--------------------------------------------------
-- AUFBAU EINER SPEC
--------------------------------------------------
--
--   SPEC_KEY = {                      -- Schlüssel wie WeintCodex_SpecProfiles
--       resource = "RAGE",            -- Hauptressource (Standard für power-Bedingungen)
--       note     = "...",             -- eine Zeile Kontext für den Kopf des Fensters
--       rules    = { ... },           -- die bewertete GCD-Prioritätenliste
--       extras   = { ... },           -- Cooldowns / Fähigkeiten ohne GCD (nie bewertet)
--   }
--
-- rules wird von oben nach unten geprüft. Eine Regel ist "bereit", wenn
-- ihre Bedingung erfüllt ist UND der Zauber gelernt und verfügbar ist.
-- Die oberste bereite Regel ist die empfohlene Aktion; alles darunter
-- rutscht in der Anzeige nach unten und steigt wieder auf, sobald es
-- an der Reihe ist (siehe modules/rotationtrainer.lua).
--
-- Es gibt bewusst KEINE always-Filler-Pflicht mehr: "gerade ist nichts
-- fällig" ist ein ehrlicher Zustand (Ressourcen sammeln, Cooldowns
-- abwarten) und wird in der Bewertung neutral behandelt, statt einen
-- Zauber zu empfehlen, den man gar nicht wirken kann. Jede Spec hat
-- aber genau eine Regel mit kind = "filler" - das ist die Fähigkeit,
-- die man drückt, wenn sonst nichts ansteht.
--
-- extras erscheinen als eigene Leiste unter der Liste. Sie werden nie
-- in die Bewertung eingerechnet: an der Puppe ist es keine Fehlleistung,
-- einen Zweiminuten-Cooldown liegen zu lassen, und eine Fähigkeit ohne
-- GCD (Heroischer Stoß, Blutmal) verdrängt keine andere Aktion.
--
--------------------------------------------------
-- REGELFELDER
--------------------------------------------------
--
--   spell   = SpellID                 -- Pflicht
--   alt     = { SpellID, ... }        -- Ausweich-IDs, siehe unten
--   kind    = "dot" | "cooldown" | "proc" | "spender" | "builder"
--             | "execute" | "filler" | "dump" | "buff"
--             (nur Einfärbung/Einordnung, keine Logik)
--   when    = { ... }                 -- Bedingung, siehe unten (fehlt = immer erfüllt)
--   why     = "Kurztext"              -- statischer Hinweis für den Tooltip
--   offGcd  = true                    -- nur in extras: löst keinen GCD aus
--   track   = true                    -- Aura dieser Regel in die Uptime-Wertung nehmen
--
-- alt ist für Fähigkeiten gedacht, die je nach Spezialisierung eine
-- andere Spell-ID tragen (Seelenschnitter, Verstümmeln): genommen wird
-- die erste ID, die der Charakter tatsächlich kennt. Ohne das wäre die
-- Zeile für einen Teil der Spieler dauerhaft tot.
--
--------------------------------------------------
-- BEDINGUNGEN (alle Felder eines when-Blocks müssen zutreffen)
--------------------------------------------------
--
--   hpBelow  = 20                     -- Ziel-Lebenspunkte <= 20 %
--   hpAbove  = 35                     -- Ziel-Lebenspunkte >  35 %
--   buff     = ID | { id = ID, stacks = n, remainingBelow = s, remainingAbove = s }
--   noBuff   = ID | { id = ID, remainingBelow = s }   -- fehlt ODER läuft in < s aus
--   debuff   = ID | { ... }           -- eigener Debuff am Ziel (wie buff)
--   noDebuff = ID | { id = ID, remainingBelow = s }   -- fehlt ODER läuft in < s aus
--   power    = { type = "RAGE"|..., atLeast = n, atMost = n }   -- type optional
--   combo    = { atLeast = n, atMost = n }            -- Kombopunkte am Ziel
--   runes    = { blood = n, frost = n, unholy = n }   -- bereite Runen (Todesrunen zählen als Joker)
--   spellReady      = ID              -- anderer Zauber ist verfügbar
--   spellOnCooldown = ID              -- anderer Zauber ist NICHT verfügbar
--   anyOf    = { { ... }, { ... } }   -- mindestens einer der Blöcke trifft zu
--
-- noBuff/noDebuff mit remainingBelow ist bewusst ein Feld und nicht
-- zwei: "fehlt oder läuft gleich aus" ist derselbe Gedanke und liest
-- sich in der Regel als ein Satz.
--
-- Namen und Symbole werden zur Laufzeit über GetSpellInfo aufgelöst,
-- nicht gespeichert - dieselbe Doktrin wie WeintCodex_GetGemName
-- (gems.lua) und data/bis.lua, damit die Anzeige immer der Sprache des
-- Clients folgt.
--------------------------------------------------

WeintCodex_Rotations = {

    --------------------------------------------------
    -- KRIEGER
    --------------------------------------------------

    WARRIOR_ARMS = {
        resource = "RAGE",
        note     = "Koloss-Verwüstung ausnutzen, Wut über Heroischen Stoß abtragen.",
        rules = {
            { spell = 772,    kind = "dot",      track = true,
              when = { noDebuff = { id = 772, remainingBelow = 3 } },
              why  = "Verwunden läuft die ganze Zeit mit" },
            { spell = 86346,  kind = "cooldown",
              why  = "Rüstung brechen, dann alles hineinlegen" },
            { spell = 12294,  kind = "builder",
              why  = "Auf Cooldown halten" },
            { spell = 5308,   kind = "execute",
              when = { hpBelow = 20 },
              why  = "Ab 20 % ersetzt Vernichtungsstoß den Filler" },
            { spell = 7384,   kind = "proc",
              when = { buff = 60503 },
              why  = "Nur mit Blutgeschmack, sonst Wutverschwendung" },
            { spell = 1464,   kind = "filler",
              when = { power = { atLeast = 20 } } },
        },
        extras = {
            { spell = 78,     kind = "dump",     offGcd = true,
              when = { power = { atLeast = 60 } },
              why  = "Wutabbau ohne GCD" },
            { spell = 1719,   kind = "cooldown" },
            { spell = 114207, kind = "cooldown" },
            { spell = 12292,  kind = "cooldown" },
            { spell = 107574, kind = "cooldown" },
        },
    },

    WARRIOR_FURY = {
        resource = "RAGE",
        note     = "Blutdurst erzürnt, Wutender Schlag verwertet das Erzürnen.",
        rules = {
            { spell = 86346,  kind = "cooldown",
              why  = "Fenster für alles andere" },
            { spell = 23881,  kind = "builder",
              why  = "Erzeugt Erzürnen und Wut" },
            { spell = 5308,   kind = "execute",
              when = { hpBelow = 20 } },
            { spell = 85288,  kind = "proc",
              when = { buff = 12880 },
              why  = "Braucht Erzürnen" },
            { spell = 100130, kind = "proc",
              when = { buff = 46916 },
              why  = "Mit Blutrausch kostenlos und sofort" },
            { spell = 100130, kind = "filler",
              when = { power = { atLeast = 30 } } },
        },
        extras = {
            { spell = 78,     kind = "dump",     offGcd = true,
              when = { power = { atLeast = 60 } },
              why  = "Wutabbau ohne GCD" },
            { spell = 1719,   kind = "cooldown" },
            { spell = 114207, kind = "cooldown" },
            { spell = 12292,  kind = "cooldown" },
        },
    },

    --------------------------------------------------
    -- PALADIN
    --------------------------------------------------

    PALADIN_RETRIBUTION = {
        resource = "HOLY_POWER",
        note     = "Inquisition darf nie fallen, sonst fehlen 30 % Schaden.",
        rules = {
            { spell = 84963,  kind = "buff",     track = true,
              when = { noBuff = { id = 84963, remainingBelow = 4 },
                       power  = { atLeast = 3 } },
              why  = "Vor jedem Templerurteil: Inquisition steht" },
            { spell = 24275,  kind = "execute",
              when = { hpBelow = 20 },
              why  = "Kostet keine Heilige Kraft" },
            { spell = 85256,  kind = "spender",
              when = { anyOf = { { buff = 90174 },
                                 { power = { atLeast = 5 } } } },
              why  = "Bei 5 Kraft oder mit Göttlicher Führung gratis" },
            { spell = 35395,  kind = "builder" },
            { spell = 20271,  kind = "builder" },
            { spell = 879,    kind = "builder" },
            { spell = 85256,  kind = "filler",
              when = { power = { atLeast = 3 } },
              why  = "Notfalls schon bei 3 Kraft, wenn nichts nachkommt" },
        },
        extras = {
            { spell = 31884,  kind = "cooldown" },
            { spell = 105809, kind = "cooldown" },
            { spell = 114157, kind = "cooldown" },
            { spell = 86698,  kind = "cooldown" },
        },
    },

    --------------------------------------------------
    -- JÄGER
    --------------------------------------------------

    HUNTER_BEASTMASTERY = {
        resource = "FOCUS",
        note     = "Kommando ist der Hauptschaden, Kobraschuss füllt Fokus nach.",
        rules = {
            { spell = 1978,   kind = "dot",      track = true,
              when = { noDebuff = { id = 1978, remainingBelow = 3 } } },
            { spell = 34026,  kind = "cooldown",
              why  = "Immer sofort, nie liegen lassen" },
            { spell = 53351,  kind = "execute",
              when = { hpBelow = 20 } },
            { spell = 3044,   kind = "spender",
              when = { power = { atLeast = 60 } },
              why  = "Fokus abtragen, aber nie unter 30 für Kommando" },
            { spell = 77767,  kind = "filler",
              why  = "Baut Fokus auf und verlängert Gift des Vipers" },
        },
        extras = {
            { spell = 19574,  kind = "cooldown" },
            { spell = 3045,   kind = "cooldown" },
            { spell = 121818, kind = "cooldown" },
            { spell = 120679, kind = "cooldown" },
        },
    },

    HUNTER_MARKSMANSHIP = {
        resource = "FOCUS",
        note     = "Chimärenschuss erneuert das Gift, Zielsicherer Schuss füllt auf.",
        rules = {
            { spell = 1978,   kind = "dot",      track = true,
              when = { noDebuff = { id = 1978, remainingBelow = 3 } } },
            { spell = 53209,  kind = "cooldown",
              why  = "Erneuert Gift des Vipers und heilt" },
            { spell = 53351,  kind = "execute",
              when = { hpBelow = 20 } },
            { spell = 19434,  kind = "proc",
              when = { buff = 82925 },
              why  = "Mit Meisterschütze sofort und kostenlos" },
            { spell = 3044,   kind = "spender",
              when = { power = { atLeast = 60 } } },
            { spell = 56641,  kind = "filler" },
        },
        extras = {
            { spell = 3045,   kind = "cooldown" },
            { spell = 23989,  kind = "cooldown" },
            { spell = 121818, kind = "cooldown" },
            { spell = 117050, kind = "cooldown" },
        },
    },

    HUNTER_SURVIVAL = {
        resource = "FOCUS",
        note     = "Explosivschuss hat Vorrang vor allem außer den Giften.",
        rules = {
            { spell = 1978,   kind = "dot",      track = true,
              when = { noDebuff = { id = 1978, remainingBelow = 3 } } },
            { spell = 53301,  kind = "cooldown",
              why  = "Direkt beim Verfügbarwerden" },
            { spell = 3674,   kind = "dot",      track = true,
              when = { noDebuff = { id = 3674, remainingBelow = 1 } } },
            { spell = 53351,  kind = "execute",
              when = { hpBelow = 20 } },
            { spell = 3044,   kind = "spender",
              when = { power = { atLeast = 67 } },
              why  = "Genug Fokus für den nächsten Explosivschuss lassen" },
            { spell = 77767,  kind = "filler" },
        },
        extras = {
            { spell = 3045,   kind = "cooldown" },
            { spell = 121818, kind = "cooldown" },
            { spell = 131894, kind = "cooldown" },
            { spell = 120679, kind = "cooldown" },
        },
    },

    --------------------------------------------------
    -- SCHURKE
    --------------------------------------------------

    ROGUE_ASSASSINATION = {
        resource = "ENERGY",
        note     = "Säbelhieb und Blutung halten, dann alles in Auswinden.",
        rules = {
            { spell = 5171,   kind = "buff",     track = true,
              when = { noBuff = { id = 5171, remainingBelow = 6 },
                       combo  = { atLeast = 1 } },
              why  = "Säbelhieb darf nie auslaufen" },
            { spell = 1943,   kind = "dot",      track = true,
              when = { noDebuff = { id = 1943, remainingBelow = 4 },
                       combo    = { atLeast = 4 } } },
            { spell = 32645,  kind = "spender",
              when = { combo = { atLeast = 5 } },
              why  = "Auf 5 Kombopunkten, hält den Auswinden-Buff" },
            { spell = 111240, kind = "builder",
              when = { anyOf = { { buff = 121153 }, { hpBelow = 35 } } },
              why  = "Mit Blende oder unter 35 % statt Verstümmeln" },
            { spell = 1329,   alt = { 5374 }, kind = "filler",
              when = { power = { atLeast = 55 } } },
        },
        extras = {
            { spell = 79140,  kind = "cooldown" },
            { spell = 121471, kind = "cooldown" },
            { spell = 137619, kind = "cooldown" },
        },
    },

    ROGUE_COMBAT = {
        resource = "ENERGY",
        note     = "Aufschlussreicher Hieb vor jedem Ausweiden.",
        rules = {
            { spell = 5171,   kind = "buff",     track = true,
              when = { noBuff = { id = 5171, remainingBelow = 6 },
                       combo  = { atLeast = 1 } } },
            { spell = 84617,  kind = "dot",      track = true,
              when = { noDebuff = { id = 84617, remainingBelow = 4 },
                       combo    = { atMost  = 4 } },
              why  = "Verstärkt die Finisher, aber nicht auf 5 Punkten" },
            { spell = 2098,   kind = "spender",
              when = { combo = { atLeast = 5 }, debuff = 84617 } },
            { spell = 1752,   kind = "filler",
              when = { power = { atLeast = 40 } } },
        },
        extras = {
            { spell = 13750,  kind = "cooldown" },
            { spell = 51690,  kind = "cooldown" },
            { spell = 121471, kind = "cooldown" },
        },
    },

    ROGUE_SUBTLETY = {
        resource = "ENERGY",
        note     = "Hämorrhagie als Blutung halten, Meucheln nur von hinten.",
        rules = {
            { spell = 5171,   kind = "buff",     track = true,
              when = { noBuff = { id = 5171, remainingBelow = 6 },
                       combo  = { atLeast = 1 } } },
            { spell = 1943,   kind = "dot",      track = true,
              when = { noDebuff = { id = 1943, remainingBelow = 4 },
                       combo    = { atLeast = 5 } } },
            { spell = 16511,  kind = "dot",      track = true,
              when = { noDebuff = { id = 16511, remainingBelow = 4 } },
              why  = "Hält die Blutung, ersetzt Meucheln von vorne" },
            { spell = 2098,   kind = "spender",
              when = { combo = { atLeast = 5 } } },
            { spell = 53,     kind = "filler",
              when = { power = { atLeast = 35 } } },
        },
        extras = {
            { spell = 51713,  kind = "cooldown" },
            { spell = 121471, kind = "cooldown" },
            { spell = 137619, kind = "cooldown" },
        },
    },

    --------------------------------------------------
    -- PRIESTER
    --------------------------------------------------

    PRIEST_SHADOW = {
        resource = "SHADOW_ORBS",
        note     = "Drei Schattenkugeln gehören sofort in die Verschlingende Seuche.",
        rules = {
            { spell = 2944,   kind = "spender",
              when = { power = { atLeast = 3 } },
              why  = "Kugeln nie liegen lassen" },
            { spell = 589,    kind = "dot",      track = true,
              when = { noDebuff = { id = 589, remainingBelow = 4 } } },
            { spell = 34914,  kind = "dot",      track = true,
              when = { noDebuff = { id = 34914, remainingBelow = 6 } } },
            { spell = 8092,   kind = "cooldown",
              why  = "Erzeugt die Schattenkugeln" },
            { spell = 32379,  kind = "execute",
              when = { hpBelow = 20 } },
            { spell = 15407,  kind = "filler",
              why  = "Kanalisieren, bricht bei jedem anderen Punkt ab" },
        },
        extras = {
            { spell = 34433,  kind = "cooldown" },
            { spell = 123040, kind = "cooldown" },
            { spell = 10060,  kind = "cooldown" },
        },
    },

    --------------------------------------------------
    -- TODESRITTER
    --------------------------------------------------

    DEATHKNIGHT_FROST = {
        resource = "RUNIC_POWER",
        note     = "Tötungsmaschine sofort in Vernichten, Runenmacht nicht kappen.",
        rules = {
            { spell = 130735, alt = { 130736, 130737 }, kind = "execute",
              when = { hpBelow = 35 },
              why  = "Ab 35 % auf Cooldown" },
            { spell = 49184,  kind = "proc",
              when = { anyOf = { { buff = 59052 },
                                 { noDebuff = { id = 55095, remainingBelow = 3 } } } },
              track = true,
              why  = "Mit Raureif gratis, sonst zum Setzen des Frostfiebers" },
            { spell = 45462,  kind = "dot",      track = true,
              when = { noDebuff = { id = 55078, remainingBelow = 3 },
                       runes    = { unholy = 1 } } },
            { spell = 49020,  kind = "proc",
              when = { buff = 51124, runes = { frost = 1, unholy = 1 } },
              why  = "Tötungsmaschine macht Vernichten kritisch" },
            { spell = 49143,  kind = "dump",
              when = { power = { atLeast = 76 } },
              why  = "Runenmacht abtragen, bevor sie überläuft" },
            { spell = 49020,  kind = "filler",
              when = { runes = { frost = 1, unholy = 1 } } },
        },
        extras = {
            { spell = 51271,  kind = "cooldown" },
            { spell = 47568,  kind = "cooldown" },
            { spell = 77575,  kind = "cooldown" },
            { spell = 45529,  kind = "dump",     offGcd = true },
        },
    },

    DEATHKNIGHT_UNHOLY = {
        resource = "RUNIC_POWER",
        note     = "Seuchen stehen lassen, Geißelstoß frisst die Unheiligen Runen.",
        rules = {
            { spell = 130736, alt = { 130735, 130737 }, kind = "execute",
              when = { hpBelow = 35, runes = { frost = 1, unholy = 1 } } },
            { spell = 45462,  kind = "dot",      track = true,
              when = { noDebuff = { id = 55078, remainingBelow = 3 },
                       runes    = { unholy = 1 } } },
            { spell = 45477,  kind = "dot",      track = true,
              when = { noDebuff = { id = 55095, remainingBelow = 3 },
                       runes    = { frost = 1 } } },
            { spell = 63560,  kind = "cooldown",
              when = { buff = { id = 91342, stacks = 5 } },
              why  = "Erst mit 5 Schatteninfusionen" },
            { spell = 47541,  kind = "proc",
              when = { anyOf = { { buff = 81340 },
                                 { power = { atLeast = 80 } } } },
              why  = "Mit Jähem Verhängnis gratis, sonst gegen den Überlauf" },
            { spell = 55090,  kind = "builder",
              when = { runes = { unholy = 1 } } },
            { spell = 85948,  kind = "filler",
              when = { runes = { blood = 1, frost = 1 } },
              why  = "Verlängert beide Seuchen" },
        },
        extras = {
            { spell = 49206,  kind = "cooldown" },
            { spell = 49016,  kind = "cooldown" },
            { spell = 47568,  kind = "cooldown" },
            { spell = 45529,  kind = "dump",     offGcd = true },
        },
    },

    --------------------------------------------------
    -- SCHAMANE
    --------------------------------------------------

    SHAMAN_ELEMENTAL = {
        resource = "MANA",
        note     = "Lavastoß nur mit Flammenschock, Erdschock bei 7 Ladungen.",
        rules = {
            { spell = 8050,   kind = "dot",      track = true,
              when = { noDebuff = { id = 8050, remainingBelow = 5 } },
              why  = "Voraussetzung für den kritischen Lavastoß" },
            { spell = 51505,  kind = "cooldown",
              when = { debuff = 8050 },
              why  = "Trifft mit Flammenschock immer kritisch" },
            { spell = 8042,   kind = "spender",
              when = { buff = { id = 324, stacks = 7 } },
              why  = "Bei 7 Ladungen Blitzschlagschild" },
            { spell = 117014, kind = "cooldown" },
            { spell = 403,    kind = "filler" },
        },
        extras = {
            { spell = 114050, kind = "cooldown" },
            { spell = 2894,   kind = "cooldown" },
            { spell = 16166,  kind = "cooldown" },
            { spell = 3599,   kind = "cooldown" },
        },
    },

    SHAMAN_ENHANCEMENT = {
        resource = "MANA",
        note     = "Fünf Mahlstrom-Ladungen sofort in den Blitzschlag.",
        rules = {
            { spell = 403,    kind = "proc",
              when = { buff = { id = 53817, stacks = 5 } },
              why  = "Bei 5 Mahlstrom sofort, sonst verfällt der Stapel" },
            { spell = 17364,  kind = "cooldown",
              why  = "Der Taktgeber der Rotation" },
            { spell = 8050,   kind = "dot",      track = true,
              when = { noDebuff = { id = 8050, remainingBelow = 5 } } },
            { spell = 60103,  kind = "cooldown" },
            { spell = 73680,  kind = "cooldown" },
            { spell = 8042,   kind = "filler",
              when = { buff = { id = 324, stacks = 5 } },
              why  = "Ladungen abtragen, wenn nichts anderes ansteht" },
        },
        extras = {
            { spell = 51533,  kind = "cooldown" },
            { spell = 114051, kind = "cooldown" },
            { spell = 2894,   kind = "cooldown" },
            { spell = 3599,   kind = "cooldown" },
        },
    },

    --------------------------------------------------
    -- MAGIER
    --------------------------------------------------

    MAGE_ARCANE = {
        resource = "MANA",
        note     = "Arkaner Schlag stapeln, Geschosse nur mit Prozz.",
        rules = {
            { spell = 5143,   kind = "proc",
              when = { buff = { id = 79683, stacks = 2 } },
              why  = "Zwei Ladungen abarbeiten, bevor die dritte verfällt" },
            { spell = 44425,  kind = "spender",
              when = { buff = { id = 36032, stacks = 4 } },
              why  = "Baut die Ladungen ab, wenn das Mana knapp wird" },
            { spell = 30451,  kind = "filler",
              why  = "Der eigentliche Schaden - stapelt die Ladungen" },
        },
        extras = {
            { spell = 12042,  kind = "cooldown" },
            { spell = 12051,  kind = "cooldown" },
            { spell = 55342,  kind = "cooldown" },
            { spell = 12043,  kind = "cooldown" },
        },
    },

    MAGE_FIRE = {
        resource = "MANA",
        note     = "Erhitzen mit Inferno-Explosion in einen freien Pyroschlag drehen.",
        rules = {
            { spell = 11366,  kind = "proc",
              when = { buff = 48108 },
              why  = "Pyroschlag! nie verfallen lassen" },
            { spell = 44457,  kind = "dot",      track = true,
              when = { noDebuff = { id = 44457, remainingBelow = 3 } } },
            { spell = 108853, kind = "proc",
              when = { buff = 48107 },
              why  = "Erhitzen wird zum garantierten Pyroschlag!" },
            { spell = 133,    kind = "filler" },
        },
        extras = {
            { spell = 11129,  kind = "cooldown" },
            { spell = 55342,  kind = "cooldown" },
            { spell = 108978, kind = "cooldown" },
        },
    },

    MAGE_FROST = {
        resource = "MANA",
        note     = "Prozzs abarbeiten, Frostblitz füllt die Lücken.",
        rules = {
            { spell = 44614,  kind = "proc",
              when = { buff = 57761 },
              why  = "Gehirnfrost: sofort und kostenlos" },
            { spell = 30455,  kind = "proc",
              when = { buff = 44544 },
              why  = "Frostfinger, sonst trifft Eislanze für ein Drittel" },
            { spell = 116,    kind = "filler" },
        },
        extras = {
            { spell = 84714,  kind = "cooldown" },
            { spell = 12472,  kind = "cooldown" },
            { spell = 55342,  kind = "cooldown" },
        },
    },

    --------------------------------------------------
    -- HEXENMEISTER
    --------------------------------------------------

    WARLOCK_AFFLICTION = {
        resource = "SOUL_SHARDS",
        note     = "Drei Dots stehen lassen, Bösartiger Griff tickt sie schneller.",
        rules = {
            { spell = 980,    kind = "dot",      track = true,
              when = { noDebuff = { id = 980, remainingBelow = 5 } },
              why  = "Stapelt sich hoch - niemals auslaufen lassen" },
            { spell = 172,    kind = "dot",      track = true,
              when = { noDebuff = { id = 172, remainingBelow = 5 } } },
            { spell = 30108,  kind = "dot",      track = true,
              when = { noDebuff = { id = 30108, remainingBelow = 5 } } },
            { spell = 48181,  kind = "spender",
              when = { power = { atLeast = 1 } },
              why  = "Verstärkt alle laufenden Dots" },
            { spell = 1120,   kind = "execute",
              when = { hpBelow = 20 },
              why  = "Unter 20 % der stärkere Kanal" },
            { spell = 103103, kind = "filler",
              why  = "Beschleunigt alle Dots während des Kanalisierens" },
        },
        extras = {
            { spell = 113860, kind = "cooldown" },
            { spell = 18540,  kind = "cooldown" },
        },
    },

    WARLOCK_DEMONOLOGY = {
        resource = "DEMONIC_FURY",
        note     = "Dämonische Wut sammeln und in der Metamorphose ausgeben.",
        rules = {
            { spell = 172,    kind = "dot",      track = true,
              when = { noDebuff = { id = 172, remainingBelow = 5 } } },
            { spell = 105174, kind = "dot",      track = true,
              when = { noDebuff = { id = 47960, remainingBelow = 2 } },
              why  = "Schattenflamme am Ziel halten" },
            { spell = 6353,   kind = "proc",
              when = { buff = 122351 },
              why  = "Geschmolzener Kern: sofort und ohne Zauberzeit" },
            { spell = 686,    kind = "filler",
              why  = "Erzeugt Dämonische Wut" },
        },
        extras = {
            { spell = 103958, kind = "cooldown",
              when = { power = { type = "DEMONIC_FURY", atLeast = 800 } },
              why  = "Ab etwa 800 Wut wechseln" },
            { spell = 113861, kind = "cooldown" },
            { spell = 18540,  kind = "cooldown" },
        },
    },

    WARLOCK_DESTRUCTION = {
        resource = "BURNING_EMBERS",
        note     = "Glut sammeln, Chaosblitz ist der einzige echte Ausgabeposten.",
        rules = {
            { spell = 348,    kind = "dot",      track = true,
              when = { noDebuff = { id = 348, remainingBelow = 5 } },
              why  = "Speist die Glut über die Ticks" },
            { spell = 17962,  kind = "builder",
              why  = "Zwei Ladungen - erzeugt Glut" },
            { spell = 17877,  kind = "execute",
              when = { hpBelow = 20, power = { atLeast = 1 } },
              why  = "Unter 20 % vor dem Chaosblitz" },
            { spell = 116858, kind = "spender",
              when = { power = { atLeast = 1 } } },
            { spell = 29722,  kind = "filler" },
        },
        extras = {
            { spell = 113858, kind = "cooldown" },
            { spell = 18540,  kind = "cooldown" },
            { spell = 80240,  kind = "cooldown" },
        },
    },

    --------------------------------------------------
    -- MÖNCH
    --------------------------------------------------

    MONK_WINDWALKER = {
        resource = "CHI",
        note     = "Tigerkraft und Sterbliche Wunden stehen lassen, dann Chi ausgeben.",
        rules = {
            { spell = 107428, kind = "cooldown",
              why  = "Setzt Sterbliche Wunden und trifft am härtesten" },
            { spell = 100787, kind = "buff",     track = true,
              when = { noBuff = { id = 125359, remainingBelow = 4 },
                       power  = { atLeast = 1 } },
              why  = "Tigerkraft: 10 % mehr Schaden, darf nicht fallen" },
            { spell = 113656, kind = "spender",
              when = { power = { atLeast = 3 } },
              why  = "Kanalisieren - dabei stehen bleiben" },
            { spell = 100784, kind = "proc",
              when = { buff = 116768 },
              why  = "Kombomeister macht ihn kostenlos" },
            { spell = 100784, kind = "spender",
              when = { power = { atLeast = 3 } },
              why  = "Chi nicht über die Grenze laufen lassen" },
            { spell = 100780, kind = "filler",
              why  = "Erzeugt Chi" },
        },
        extras = {
            { spell = 116740, kind = "cooldown" },
            { spell = 115288, kind = "cooldown" },
            { spell = 115080, kind = "cooldown" },
            { spell = 123904, kind = "cooldown" },
        },
    },

    --------------------------------------------------
    -- DRUIDE
    --------------------------------------------------

    DRUID_BALANCE = {
        resource = "MANA",
        note     = "Der Eklipsenzeiger bestimmt, welcher Zauber gerade zählt.",
        rules = {
            { spell = 8921,   kind = "dot",      track = true,
              when = { noDebuff = { id = 8921, remainingBelow = 4 } } },
            { spell = 93402,  kind = "dot",      track = true,
              when = { noDebuff = { id = 93402, remainingBelow = 4 } } },
            { spell = 78674,  kind = "cooldown",
              why  = "Zwei Ladungen - nie beide verfallen lassen" },
            { spell = 2912,   kind = "builder",
              when = { buff = 48518 },
              why  = "In der Mondphase" },
            { spell = 5176,   kind = "builder",
              when = { buff = 48517 },
              why  = "In der Sonnenphase" },
            { spell = 5176,   kind = "filler",
              why  = "Treibt den Zeiger Richtung Sonnenphase" },
        },
        extras = {
            { spell = 112071, kind = "cooldown" },
            { spell = 102560, kind = "cooldown" },
            { spell = 106737, kind = "cooldown" },
        },
    },

    DRUID_FERAL = {
        resource = "ENERGY",
        note     = "Wildes Brüllen und Zerfleischen laufen durch, alles andere füllt.",
        rules = {
            { spell = 52610,  kind = "buff",     track = true,
              when = { noBuff = { id = 52610, remainingBelow = 4 },
                       combo  = { atLeast = 1 } },
              why  = "40 % mehr Autoangriffsschaden" },
            { spell = 1079,   kind = "dot",      track = true,
              when = { noDebuff = { id = 1079, remainingBelow = 3 },
                       combo    = { atLeast = 5 } },
              why  = "Nur mit 5 Kombopunkten setzen" },
            { spell = 1822,   kind = "dot",      track = true,
              when = { noDebuff = { id = 1822, remainingBelow = 3 } } },
            { spell = 22568,  kind = "execute",
              when = { combo = { atLeast = 5 }, hpBelow = 25, debuff = 1079 },
              why  = "Verlängert unter 25 % das laufende Zerfleischen" },
            { spell = 5221,   kind = "filler",
              when = { power = { atLeast = 40 } },
              why  = "Nur von hinten - sonst Verstümmeln" },
            { spell = 33876,  kind = "builder",
              when = { power = { atLeast = 35 } },
              why  = "Ersatz für Zerfetzen, wenn du vor dem Ziel stehst" },
        },
        extras = {
            { spell = 5217,   kind = "cooldown" },
            { spell = 106951, kind = "cooldown" },
            { spell = 102543, kind = "cooldown" },
            { spell = 106737, kind = "cooldown" },
        },
    },

}

--------------------------------------------------
-- ZUGRIFF
--------------------------------------------------

-- Liefert die Rotationsdefinition zu einem Profilschlüssel.
-- Tank-Profile im Offensiv-Stil (*_OFFENSIVE, siehe spec_profiles.lua)
-- haben bewusst KEINE eigene Liste und fallen auch nicht auf die
-- Basis-Spec zurück: anders als bei der Ausrüstung (modules/bis.lua)
-- ist die Rotation eines Tanks eine völlig andere, und eine falsche
-- Liste wäre schlechter als gar keine.
function WeintCodex_GetRotation(specKey)
    if not specKey then return nil end
    if type(WeintCodex_Rotations) ~= "table" then return nil end
    return WeintCodex_Rotations[specKey]
end

--------------------------------------------------
-- DRIFT-SCHUTZ
--
-- Analog WeintCodex_ValidateSpecData/WeintCodex_ValidateBiSData. Prüft
-- den Aufbau aller Specs, löst Spell-IDs aber nur für die übergebene
-- (also die eigene) Spec auf - sonst stünden bei jedem Login Warnungen
-- zu 22 Specs im Chat, die den Spieler nichts angehen.
--------------------------------------------------

local VALID_KINDS = {
    dot = true, cooldown = true, proc = true, spender = true,
    builder = true, execute = true, filler = true, dump = true, buff = true,
}

local function ValidateRuleList(problems, specKey, section, list, requireFiller)
    if type(list) ~= "table" or #list == 0 then
        if requireFiller then
            problems[#problems + 1] = string.format(
                "%s: keine gültige Regelliste (%s)", specKey, section)
        end
        return
    end

    local hasFiller = false

    for index, rule in ipairs(list) do
        if type(rule) ~= "table" or type(rule.spell) ~= "number" then
            problems[#problems + 1] = string.format(
                "%s %s #%d: keine gültige Spell-ID", specKey, section, index)
        end
        if rule.kind and not VALID_KINDS[rule.kind] then
            problems[#problems + 1] = string.format(
                "%s %s #%d: unbekannte Art '%s'", specKey, section, index, tostring(rule.kind))
        end
        if rule.kind == "filler" then hasFiller = true end
        if rule.when ~= nil and type(rule.when) ~= "table" then
            problems[#problems + 1] = string.format(
                "%s %s #%d: 'when' ist keine Tabelle", specKey, section, index)
        end
    end

    if requireFiller and not hasFiller then
        problems[#problems + 1] = string.format(
            "%s: keine Regel mit kind = \"filler\"", specKey)
    end
end

function WeintCodex_ValidateRotationData(currentSpecKey)
    if type(WeintCodex_Rotations) ~= "table" then return end

    local problems = {}

    for specKey, spec in pairs(WeintCodex_Rotations) do

        if WeintCodex_SpecProfiles and not WeintCodex_SpecProfiles[specKey] then
            problems[#problems + 1] = string.format(
                "%s: Spec-Schlüssel existiert nicht in spec_profiles.lua", specKey)
        end

        if type(spec) ~= "table" or type(spec.rules) ~= "table" then
            problems[#problems + 1] = string.format(
                "%s: kein rules-Block", specKey)
        else
            ValidateRuleList(problems, specKey, "Regel", spec.rules, true)
            if spec.extras then
                ValidateRuleList(problems, specKey, "Extra", spec.extras, false)
            end
        end

    end

    -- Spell-IDs nur für die eigene Spec auflösen: GetSpellInfo liefert
    -- für eine Tippfehler-ID nichts zurück, und genau das ist der Fehler,
    -- den man sonst erst im Spiel als leere Zeile bemerkt.
    local spec = currentSpecKey and WeintCodex_Rotations[currentSpecKey]
    if spec and GetSpellInfo then
        local sections = { { "Regel", spec.rules }, { "Extra", spec.extras } }
        for _, section in ipairs(sections) do
            for index, rule in ipairs(section[2] or {}) do
                if type(rule.spell) == "number" and not GetSpellInfo(rule.spell) then
                    problems[#problems + 1] = string.format(
                        "%s %s #%d: Spell-ID %d ist dem Client unbekannt",
                        currentSpecKey, section[1], index, rule.spell)
                end
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
