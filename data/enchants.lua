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
-- ID-ABGLEICH (08.09.2026): Jede ID, jeder Wert und jede Slot-Zuordnung
-- dieser Datei ist einmal gegen die MoP-Spieldaten gehalten worden
-- (Verzauberungstabelle der MoP-Simulation wowsims/mop,
-- assets/database/db.json: Verzauberungs-ID -> Formel-Gegenstand ->
-- Zauber -> Werte). Sieben Einträge waren falsch, darunter drei, die
-- Empfehlungen für 39 Profile verdreht haben - jeder davon steht unten
-- mit Begründung. Was seither hier steht, ist an zwei unabhängigen
-- Quellen belegt: der Spieldatenbank und (wo vorhanden) dem Live-Tooltip.
-- ES BLEIBT EINE UNGEPRÜFTE SPALTE: der DEUTSCHE NAME. Er steht in
-- keiner dieser Quellen, und genau darauf zeigt "verify = true" jetzt.
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

    -- ZWEI DAVON WAREN ERFUNDEN. "Lied des Windes" (4441) und "Lied des
    -- Flusses" (4446) waren aus dem Englischen uebersetzt statt aus dem
    -- Client abgeschrieben - der deutsche Client sagt "Windweise" und
    -- "Flussgesang". Das ist nicht nur ein falscher Empfehlungstext: die
    -- Waffenverzauberungen sind Proc-Verzauberungen, also NAMENSZEILEN
    -- ohne Werte, und eine Namenszeile wird nur ueber ihren Namen erkannt.
    -- Auf einer Waffe mit "Windweise" fiel die echte Zeile deshalb aus dem
    -- Scan, und uebrig blieb der Meisterschaftswert des Gegenstands - samt
    -- der Marke "(ID 4441 abweichend)" an einer korrekt verzauberten Waffe.
    -- Die Erkennung haengt seit 2.9.0.1 nicht mehr allein an diesen Namen
    -- (siehe LooksLikeEnchantText in modules/charakter.lua); richtig sein
    -- muessen sie trotzdem, denn sie stehen in den Empfehlungen.
    [4441] = { name = "Windweise",        slot = "Waffe" },   -- Windsong (Proc: 1500 Krit/Tempo/Meisterschaft)
    [4442] = { name = "Jadegeist",        slot = "Waffe" },   -- Jade Spirit (Proc: 1650 Intelligenz)
    [4443] = { name = "Elementarkraft",   slot = "Waffe" },   -- Elemental Force (Elementarschaden-Proc)
    [4444] = { name = "Tanzender Stahl",  slot = "Waffe" },   -- Dancing Steel (Proc: 1650 Stärke ODER Beweglichkeit)
    [4445] = { name = "Koloss",           slot = "Waffe" },   -- Colossus (Absorbschild-Proc, Tank)
    [4446] = { name = "Flussgesang",      slot = "Waffe" },   -- River's Song (Ausweich-Proc, Tank)

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
    -- 4099 ist laut Spieldaten die Cata-Waffenverzauberung "Bergsturz"
    -- (Landslide), kein Zielfernrohr. Sie steht weiter hier, damit eine
    -- alte Waffe nicht als "Unbekannt (ID 4099)" dasteht.
    [4099] = { name = "Bergsturz",                                       slot = "Waffe", verify = true },
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

    -- KORRIGIERT 08.09.2026 (Abgleich gegen die Spieldaten, siehe Kopf):
    -- 4422 stand hier ein zweites Mal als Krit-Verzauberung. Sie ist es
    -- nicht. 4422 ist der AUSDAUER-Umhang ("Großer Schutz",
    -- Formel-Gegenstand 74711, Zauber 104401) - also genau die
    -- Verzauberung, die bis dahin ein paar Zeilen tiefer unter ihrer
    -- Gegenstandsnummer stand. Krit hat genau eine ID: 4424.
    --
    -- Zu sehen war der Fehler nicht, weil beide Einträge denselben Namen
    -- trugen und der Namensabgleich sie deshalb gleichsetzte. In den
    -- Empfehlungslisten stand dadurch aber bei acht Specs die
    -- Ausdauer-ID an der Stelle, an der "Krit zuerst" gemeint war.
    --
    -- 4892 ist NICHT eine zweite Intelligenz-Verzauberung, sondern die
    -- Schneiderei-Stickerei "Lichtweberstickerei" (Rang 3, Zauber
    -- 125481). Sie gibt keine festen Werte, sondern procct Intelligenz -
    -- deshalb steht sie ohne stats hier, wie die Waffen-Procs oben, und
    -- wird über ihren Namen erkannt. Als feste "+180 Intelligenz"
    -- eingetragen war sie für jeden Nicht-Schneider die falsche
    -- Empfehlung; die Zauberer-Profile führen jetzt 4423 zuerst.
    [4421] = { name = "Präzision",                            slot = "Umhang", stats = { hit = 180 } },        -- Gegenstand 74710
    [4422] = { name = "Großer Schutz",                        slot = "Umhang", stats = { stamina = 200 } },    -- Gegenstand 74711 (Tank)
    [4423] = { name = "Überragende Intelligenz",              slot = "Umhang", stats = { intellect = 180 }, verify = true },  -- Gegenstand 74712
    [4424] = { name = "Überragende kritische Trefferwertung", slot = "Umhang", stats = { crit = 180 } },       -- Gegenstand 74713
    [4892] = { name = "Lichtweberstickerei",                  slot = "Umhang", verify = true },                -- Schneiderei-Proc (Zauber 125481)

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
    -- Wert korrigiert 2026-08-20 (Nutzerbericht, Live-Tooltip): +180
    -- Beweglichkeit, nicht 170 — dieselbe Altlast wie bei 4415 daneben.
    -- Die MoP-Handgelenke geben auf allen drei Primärwerten 180; nur die
    -- Sekundärwertung (4411) bleibt bei 170.
    [4416] = { name = "Große Beweglichkeit",     slot = "Handgelenke", stats = { agility = 180 } },

    --------------------------------------------------
    -- HÄNDE
    --------------------------------------------------

    -- KORRIGIERT 08.09.2026 (Abgleich gegen die Spieldaten, siehe Kopf).
    -- Die vier MoP-Handschuhverzauberungen liegen lückenlos auf
    -- 4430-4433, jede genau einmal:
    --   4430 Großes Tempo              (Gegenstand 74719, Zauber 104416)
    --   4431 Überragende Waffenkunde   (Gegenstand 74720, Zauber 104417)
    --   4432 Erstklassige Stärke       (Gegenstand 74721, Zauber 104419)
    --   4433 Überragende Meisterschaft (Gegenstand 74722, Zauber 104420)
    --
    -- Hier stand 4430 als Meisterschaft, abgeleitet aus einem alten
    -- Nutzerbericht; die Tempo-Handschuhe lagen deshalb ersatzweise unter
    -- ihrer Gegenstandsnummer 74719. Beides zusammen hiess: die
    -- Empfehlungslisten führten für 13 Tempo-Specs ZWEIMAL DIESELBE
    -- Verzauberung und für die Meisterschafts-Specs (Heilig-Paladin,
    -- Blut-Todesritter, Priester, Verstärker) gar keine Meisterschaft -
    -- was dort "Meisterschaft" hiess, war Tempo.
    --
    -- Der Bericht vom Heiligpriester (2.6.0.3), dessen Handschuhe die
    -- 4433 trugen und "+170 Meisterschaft" zeigten, war also richtig und
    -- vollständig; der ältere Bericht dagegen ist damit widerlegt. Zwei
    -- IDs für dieselbe Verzauberung gibt es an dieser Stelle nicht.
    --
    -- 4434 stand hier als zweite Stärke-ID. Auch das war falsch: 4434 ist
    -- die Nebenhand-Intelligenz und steht jetzt in ihrem eigenen Block.
    [4430] = { name = "Großes Tempo",              slot = "Hände", stats = { haste = 170 } },      -- Gegenstand 74719
    [4431] = { name = "Überragende Waffenkunde",   slot = "Hände", stats = { expertise = 170 } },  -- Gegenstand 74720
    [4432] = { name = "Erstklassige Stärke",       slot = "Hände", stats = { strength = 170 } },   -- Gegenstand 74721 (Live-Tooltip)
    [4433] = { name = "Überragende Meisterschaft", slot = "Hände", stats = { mastery = 170 } },    -- Gegenstand 74722 (Live-Tooltip)

    --------------------------------------------------
    -- BEINE (Lederverarbeitung / Schneiderei)
    --------------------------------------------------

    [4822] = { name = "Schattenlederbeinrüstung",            slot = "Beine", stats = { agility = 285, crit = 165 } },
    [4823] = { name = "Zornbalgbeinrüstung",                 slot = "Beine", stats = { strength = 285, crit = 165 } },
    [4824] = { name = "Eisenschuppenbeinrüstung",            slot = "Beine", stats = { stamina = 430, dodge = 165 } },
    -- Die beiden Zauberfäden standen bis 2.6.0.3 vertauscht. Gemeldet am
    -- Heiligpriester: seine Hose trägt im Item-Link die 4826 und im
    -- Tooltip "+285 Intelligenz und +165 Willenskraft" — also den
    -- perlmuttfarbenen. Die Namen selbst waren richtig (Pearlescent =
    -- perlmuttfarben = Intelligenz + Willenskraft, Cerulean =
    -- himmelblau = Intelligenz + kritische Trefferwertung); vertauscht
    -- war, welche ID welchen Faden meint. Bestätigt wurde damals nur die
    -- Schreibweise des Namens ("himmelblau" statt "zerulanblau"), nicht
    -- die Zuordnung — und der Heiler bekam deshalb für den richtigen
    -- Faden "(ID 4826 abweichend – /wc vz)" zu lesen.
    --
    -- 4825 ist die Gegenprobe dazu und nicht selbst belegt: bestätigt ist
    -- 4826 = Willenskraft, der andere Faden dieses Paares muss dann der
    -- himmelblaue sein. Deshalb steht dort weiterhin verify.
    [4825] = { name = "Großer himmelblauer Zauberfaden",     slot = "Beine", stats = { intellect = 285, crit = 165 }, verify = true },
    [4826] = { name = "Großer perlmuttfarbener Zauberfaden", slot = "Beine", stats = { intellect = 285, spirit = 165 } },  -- Live-Tooltip (Heiligpriester)

    --------------------------------------------------
    -- FÜSSE
    --------------------------------------------------

    -- KORRIGIERT 08.09.2026. Anlass war ein Nutzerbericht am
    -- Verstärker-Schamanen: richtig verzauberte Stiefel lasen
    -- "Verschwimmen (ID 4428 abweichend – /wc vz)". Der Abgleich gegen
    -- die Spieldaten (siehe Kopf) sagt, warum - MoP hat genau vier
    -- Stiefelverzauberungen, und sie liegen lückenlos auf 4426-4429:
    --   4426 Großes Tempo    (Gegenstand 74715, Zauber 104407)
    --   4427 Große Präzision (Gegenstand 74716, Zauber 104408)
    --   4428 Verschwimmen    (Gegenstand 74717, Zauber 104409)
    --   4429 Pandarenpfoten  (Gegenstand 74718, Zauber 104414)
    --
    -- Hier stand die Präzision auf der 4428 und Verschwimmen auf einer
    -- 4425, die es in MoP nicht gibt. Beide Fehler zusammen hiessen:
    -- jeder mit "Verschwimmen" verzauberte Stiefel trug die Marke
    -- "(ID abweichend)", und in den Empfehlungslisten stand für die
    -- Beweglichkeits-Specs die Präzision da, wo die Pandarenpfoten
    -- gemeint waren (die Kommentare dort rechneten seit jeher mit
    -- Meisterschaft).
    --
    -- Der Wert der Pandarenpfoten bleibt, wie er seit 2.3.0.2 ist: 140
    -- Meisterschaft, bestätigt am deutschen Gegenstand 74718 und jetzt
    -- ein zweites Mal an den Spieldaten. 175 wären ein Gleichstand mit
    -- dem Tempo-Enchant gewesen - und genau davon hängen die
    -- Stiefel-Empfehlungen in data/spec_profiles.lua ab.
    [4426] = { name = "Großes Tempo",    slot = "Füße", stats = { haste = 175 } },    -- Gegenstand 74715 (Live-Tooltip: Sporen des Wolfsreiters/105033)
    [4427] = { name = "Große Präzision", slot = "Füße", stats = { hit = 175 }, verify = true },  -- Gegenstand 74716
    [4428] = { name = "Verschwimmen",    slot = "Füße", stats = { agility = 140 } },  -- Gegenstand 74717 (Live-Tooltip: Nutzerbericht 08.09.2026)
    [4429] = { name = "Pandarenpfoten",  slot = "Füße", stats = { mastery = 140 } },  -- Gegenstand 74718

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
    -- SCHLÜSSEL: seit dem Abgleich vom 08.09.2026 stehen beide unter
    -- ihrer echten Verzauberungs-ID statt unter der Nummer der
    -- Verzauberungsrolle. 4434 stand bis dahin fälschlich als zweite
    -- Stärke-ID im HÄNDE-Block.
    --------------------------------------------------

    [4434] = { name = "Mächtige Intelligenz", slot = "Nebenhand", stats = { intellect = 165 }, verify = true },  -- Gegenstand 74729
    [4993] = { name = "Großes Parieren",      slot = "Nebenhand", stats = { parry = 170 },     verify = true, nurSchild = true },  -- Gegenstand 89737

    --------------------------------------------------
    -- RINGE (Verzauberkunst-exklusiv)
    --
    -- Nur Verzauberer können ihre eigenen Ringe verzaubern. Das
    -- Charakter-Modul blendet die Ring-Zeilen deshalb aus, wenn der
    -- Beruf nicht geskillt ist (siehe HasEnchanting in charakter.lua) -
    -- sonst hätten Nicht-Verzauberer dauerhaft zwei "fehlende"
    -- Verzauberungen im Check.
    --
    -- SCHLÜSSEL: seit dem Abgleich vom 08.09.2026 die echten
    -- Verzauberungs-IDs statt der Formel-Gegenstände 84575-84578.
    -- Die Stärke fällt dabei aus der Reihe: 4359/4360/4361 liegen
    -- beieinander, die Stärke sitzt auf 4807. Genau deshalb taugt
    -- Weiterzählen hier nicht.
    --------------------------------------------------

    [4359] = { name = "Große Beweglichkeit", slot = "Ring", stats = { agility   = 160 }, verify = true },  -- Gegenstand 84575, Zauber 103461
    [4360] = { name = "Große Intelligenz",   slot = "Ring", stats = { intellect = 160 }, verify = true },  -- Gegenstand 84576, Zauber 103462
    [4361] = { name = "Große Ausdauer",      slot = "Ring", stats = { stamina   = 240 }, verify = true },  -- Gegenstand 84577, Zauber 103463
    [4807] = { name = "Große Stärke",        slot = "Ring", stats = { strength  = 160 }, verify = true },  -- Gegenstand 84578, Zauber 103465

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
