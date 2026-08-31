--------------------------------------------------
-- WeintCodex :: Sim-Gewichte uebernehmen (seit 2.7.3.0)
--------------------------------------------------
-- Ein Sim im Spiel waere eine eigene Spielsimulation; einer, der nur so
-- aussieht, waere schlimmer als keiner, weil seine Zahlen aussehen wie
-- echte. Was ein Sim aber liefert und was hier fehlte, sind die
-- WERTEGEWICHTE — und genau die sind die Schnittstelle: WeintCodex rechnet
-- ohnehin mit Gewichten, an drei Stellen (Sockel, Verzauberungen,
-- Umschmieden). Wer simuliert hat, setzt sein Ergebnis hier ein, statt es
-- abzutippen.
--
-- ZWEI LESEWEGE, UND WELCHER GILT, ENTSCHEIDET DER TEXT.
--
--   1. WERTEPAARE — ein Wertname, dann eine Zahl. Das ist der Normalfall
--      und der Weg fuer alles, was Namen im Text stehen hat.
--   2. DIE AUSGABE VON wowsims.com/mop — eine lange Zeichenkette, in der
--      die Gewichte als blosse Zahlenreihe stehen und die POSITION sagt,
--      welcher Wert gemeint ist. Sie ist dieselbe, die man in ReforgeLite
--      einfuegt; die Begruendung und die Waechter dafuer stehen weiter
--      unten bei SW.ParseSim.
--
-- KEIN FREMDES ADDON.
--
-- Diese Datei liest die gespeicherten Daten keines anderen Addons — was
-- gelesen wird, fuegt der Nutzer selbst ein.
--
-- Weg 1 verlangt dabei keine bestimmte Zeichenkette: einen Wertnamen, dann
-- eine Zahl, alles andere im Text wird uebergangen.
--
-- Das ist ausdruecklich der robustere Weg und nicht der bequemere. Ein
-- Muster, das auf EIN Ausgabeformat passt, geht kaputt, sobald jene Seite
-- ihre Ausgabe umstellt — und das merkt hier niemand ausser dem, der sich
-- wundert, warum seine Gewichtung zur Haelfte fehlt. Wertepaare dagegen
-- sind das, was jede Quelle gemeinsam hat:
--
--   * die abgeschriebene Werte-Tabelle (Name, Tabulator, Zahl),
--   * eine JSON-Zeile { "Agility": 1, "CritRating": 0.55 },
--   * oder eine von Hand getippte Liste.
--
-- Getrennt werden darf mit Gleichheitszeichen, Doppelpunkt, Komma,
-- Semikolon, Tabulator, Zeilenumbruch oder schlicht einem Leerzeichen.
-- Klammern und Anfuehrungszeichen fallen weg. Was uebrig bleibt und keinen
-- bekannten Wertnamen trifft, wird NICHT stillschweigend verworfen,
-- sondern gemeldet (siehe unten).
--
-- DIESE DATEI ZERLEGT UND RECHNET, SIE ZEICHNET NICHT.
--
-- Dieselbe Trennung wie zwischen modules/rotation_engine.lua und
-- modules/rotationtrainer.lua, und aus demselben Grund: das Zerlegen einer
-- fremden Zeichenkette ist genau die Sorte Rechnung, die man ausserhalb
-- des Spiels pruefen koennen muss. Der Testlauf unter .github/tests/ tut
-- das.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.StatWeights = {}

local SW = WeintCodex.StatWeights

--------------------------------------------------
-- Die Namen, unter denen ein Wert auftauchen kann
--
-- Aufgeschrieben wird jede Schreibweise, die vorkommt — dieselbe Lehre wie
-- bei den ITEM_MOD-Schluesseln in modules/stat_match.lua: wie eine Quelle
-- ihre Werte nennt, ist nicht unsere Entscheidung. Leerzeichen sind dabei
-- egal ("Crit Rating" und "CritRating" sind derselbe Name), Gross- und
-- Kleinschreibung auch.
--------------------------------------------------

local NAMES = {
    strength  = { "Strength", "Str", "Stärke", "Staerke" },
    agility   = { "Agility", "Agi", "Beweglichkeit" },
    intellect = { "Intellect", "Int", "Intelligenz" },
    stamina   = { "Stamina", "Sta", "Ausdauer" },
    spirit    = { "Spirit", "Spi", "Willenskraft" },

    hit       = { "HitRating", "Hit", "SpellHitRating", "SpellHit",
                  "MeleeHitRating", "RangedHitRating", "PhysicalHitRating",
                  "Trefferwertung", "Treffer" },
    crit      = { "CritRating", "Crit", "CriticalStrike", "CritChance",
                  "SpellCritRating", "SpellCrit", "MeleeCritRating",
                  "RangedCritRating", "PhysicalCritRating",
                  "KritischeTrefferwertung", "Krit" },
    haste     = { "HasteRating", "Haste", "SpellHasteRating", "SpellHaste",
                  "MeleeHasteRating", "RangedHasteRating",
                  "Tempowertung", "Tempo" },
    expertise = { "ExpertiseRating", "Expertise", "Exp",
                  "Waffenkundewertung", "Waffenkunde" },
    mastery   = { "MasteryRating", "Mastery", "Meisterschaftswertung",
                  "Meisterschaft" },
    dodge     = { "DodgeRating", "Dodge", "Ausweichwertung", "Ausweichen" },
    parry     = { "ParryRating", "Parry", "Parierwertung", "Parieren",
                  "Parierchance" },
}

local LOOKUP = {}
do
    -- Verglichen wird ohne Leerzeichen und in Kleinschreibung. `lower()`
    -- laesst alles oberhalb von ASCII in Ruhe, deshalb stehen die deutschen
    -- Namen oben schon klein genug beieinander — und zusaetzlich in einer
    -- Umlaut-freien Schreibweise, damit "Staerke" ebenso trifft.
    for key, names in pairs(NAMES) do
        for _, name in ipairs(names) do
            LOOKUP[name:gsub("%s+", ""):lower()] = key
        end
    end
end

-- Die Reihenfolge, in der die Seite sie anzeigt. Muss zu WEIGHT_STATS in
-- modules/charakter.lua passen; steht hier, damit die Meldung nach einem
-- Import dieselbe Reihenfolge hat wie die Felder darunter.
SW.ORDER = { "strength", "agility", "intellect", "stamina", "spirit",
             "hit", "expertise", "crit", "haste", "mastery",
             "dodge", "parry" }

--------------------------------------------------
-- Zerlegen
--
-- Rueckgabe: weights (rohe Zahlen, unskaliert), quelle, ignored
--            oder nil, Fehlertext
--
-- `ignored` sammelt jeden Namen, der vor einer Zahl stand und den wir nicht
-- kennen. Er wird nicht verschwiegen: eine Sim-Ausgabe traegt Dinge wie
-- `Dps` oder `MetaSocketEffect`, und wer nicht sieht, dass sie unter den
-- Tisch fallen, haelt das Ergebnis fuer vollstaendig.
--------------------------------------------------

local function IsNumber(token)
    return token:match("^%-?%d+%.?%d*$") ~= nil
        or token:match("^%-?%.%d+$") ~= nil
end

local function ParsePairs(text)
    --------------------------------------------------
    -- ZUERST DAS KOMMA ZWISCHEN ZIFFERN, DANN ERST TRENNEN.
    --
    -- Ein Komma trennt hier Wertepaare — aber es steht im Deutschen auch
    -- zwischen Vor- und Nachkommastelle und im Englischen vor den Tausendern.
    -- Wer "Krit 0,68" einfuegt, bekaeme sonst den Wert 0 zugeschrieben und
    -- die 68 als unbekannten Rest: der Wert faellt still auf null, und
    -- genau das faellt niemandem auf.
    --
    -- ENTSCHIEDEN WIRD AM GANZEN TEXT, NICHT AN DER EINZELNEN STELLE.
    -- Steht irgendwo ein Punkt zwischen Ziffern, schreibt diese Quelle
    -- Nachkommastellen mit Punkt — dann ist ein Komma ein
    -- Tausendertrennzeichen und wird herausgenommen. Steht nirgends einer,
    -- ist das Komma die Nachkommastelle.
    --
    -- Und das genuegt hier, weil weiter unten auf "groesstes Gewicht = 100"
    -- skaliert wird: was zaehlt, ist das VERHAELTNIS der Zahlen
    -- zueinander. Solange eine Lesart innerhalb eines Textes einheitlich
    -- ist, kommt dasselbe heraus — "3,400 / 1,870" ergibt als 3.4 / 1.87
    -- dieselbe Gewichtung wie als 3400 / 1870.
    --------------------------------------------------
    if text:match("%d%.%d") then
        -- Punktschreibweise: Komma trennt Tausender. Wiederholt, weil
        -- "1,234,567" mehrere Stellen hat.
        for _ = 1, 4 do
            local next_ = text:gsub("(%d),(%d%d%d)", "%1%2")
            if next_ == text then break end
            text = next_
        end
    else
        text = text:gsub("(%d),(%d+)", "%1.%2")
    end

    -- Alles, was trennen kann, wird zu einem Leerzeichen; Klammern und
    -- Anfuehrungszeichen fallen weg. Danach steht in jedem Token entweder
    -- ein Wortbestandteil oder eine Zahl.
    local flat = text:gsub("[%(%)%[%]{}\"']", " ")
                     :gsub("[=:,;\t\r\n]", " ")

    local tokens = {}
    for token in flat:gmatch("%S+") do tokens[#tokens + 1] = token end

    local weights, ignored, found = {}, {}, 0
    local seenIgnored = {}

    local i = 1
    while i <= #tokens do
        if IsNumber(tokens[i]) then
            -- Eine Zahl allein sagt nichts. Der Name steht davor, und er
            -- kann aus zwei Woertern bestehen ("Crit Rating"). Der
            -- laengere Name gewinnt, sonst traefe "Rating" nie zu.
            local value = tonumber(tokens[i])
            local one   = tokens[i - 1]
            local two   = (i >= 3) and (tokens[i - 2] .. tokens[i - 1]) or nil

            local key = (two and LOOKUP[two:gsub("%s+", ""):lower()])
                     or (one and LOOKUP[one:gsub("%s+", ""):lower()])

            if key and value then
                -- Mehrere Schreibweisen desselben Werts (SpellHitRating
                -- neben HitRating): die groessere gewinnt, statt sie zu
                -- addieren — es ist derselbe Wert, nicht zwei.
                if not weights[key] or value > weights[key] then
                    weights[key] = value
                end
                found = found + 1
            elseif one and one:match("^[%a]") and not seenIgnored[one] then
                seenIgnored[one] = true
                ignored[#ignored + 1] = one
            end
        end
        i = i + 1
    end

    if found == 0 then return nil end
    return weights, ignored
end

SW.ParsePairs = ParsePairs

--------------------------------------------------
-- ZWEITER LESEWEG: die Ausgabe von wowsims.com/mop
--
-- Wer dort simmt und auf "Suggest Reforges" drueckt, bekommt EINE lange
-- Zeichenkette heraus. Sie traegt alles, was ein Umschmiede-Werkzeug
-- braucht — die Wertegewichte und die Grenzen —, und genau deshalb reicht
-- sie in ReforgeLite als einziger Handgriff.
--
-- WARUM DER PAARLESER SIE NICHT LESEN KANN.
--
-- Er liest "ein Name, dann eine Zahl", und das ist das, was alle
-- Textquellen gemeinsam haben. Hier stehen die Namen aber NICHT im Text:
-- die Gewichte liegen als blosse Zahlenreihe da, und welcher Wert gemeint
-- ist, sagt allein die POSITION in dieser Reihe.
--
--     "epWeightsStats":{"stats":[1,0,1.02,0,0,1.77, … ]}
--                                ^  ^  ^
--                          Staerke  |  Ausdauer
--                            Beweglichkeit
--
-- Diesem Text ist also nur beizukommen, indem man die Reihenfolge des Sims
-- kennt — und damit ist dieser Leseweg als einziger im Addon an EIN
-- fremdes Format gebunden. Das ist keine Kehrtwende gegenueber dem
-- Paarleser oben, sondern die Ausnahme, die seine Regel bestaetigt: eine
-- Positionsliste hat keine Namen, an denen man sich festhalten koennte.
--
-- WAS FOLGT: ER MUSS LAUT SCHEITERN.
--
-- Verschiebt der Sim seine Reihenfolge, bekaeme jeder Wert lautlos das
-- Gewicht eines anderen — eine Gewichtung, die vollstaendig aussieht und
-- falsch ist. Genau dieselbe Fehlerklasse wie die laufende Nummer des
-- Umschmieders (siehe CLAUDE.md). Deshalb wird die LAENGE der Reihe
-- geprueft, bevor auch nur ein Wert uebernommen wird: 22 Werte und 16
-- abgeleitete Werte, so wie wir sie kennen. Zaehlt der Sim anders, wird
-- nichts geraten und nichts gelesen, sondern gesagt, dass sich das Format
-- geaendert hat.
--
-- Und traegt der Text ueberhaupt eine Sim-Ausgabe, wird NICHT hilfsweise
-- der Paarleser probiert. Der faende darin Schluesselnamen und Zahlen und
-- machte daraus etwas — die stille Falschauskunft, die es hier nicht geben
-- darf.
--------------------------------------------------

-- Die Reihenfolge der Werte, wie der Sim sie fuehrt. Belegt an einer
-- echten Ausgabe (Blut-Todesritter): Staerke 1 / Beweglichkeit 0 /
-- Intelligenz 0 passt zur Klasse, und die Grenze auf Platz 8 lautet 5100
-- Wertung — 15 % Waffenkunde bei 340 Wertung je Prozent, also genau der
-- Wert, den auch unser Spec-Profil fuehrt. Die Plaetze 3 und 4
-- (Intelligenz, Willenskraft) waren in jener Ausgabe beide 0 und sind
-- damit nicht einzeln belegt; sie stehen an der einzigen Stelle, die
-- ueberhaupt noch frei ist.
local SIM_STAT_KEY = {
    [0] = "strength", [1] = "agility",  [2] = "stamina",
    [3] = "intellect", [4] = "spirit",
    [5] = "hit",      [6] = "crit",     [7] = "haste",
    [8] = "expertise", [9] = "dodge",   [10] = "parry", [11] = "mastery",
}

-- Nur fuer die Meldung "nicht uebernommen". Ein Name mehr oder weniger
-- kostet hier nichts; entschieden wird nach der Tabelle darueber.
local SIM_STAT_NAME = {
    [12] = "Angriffskraft",   [13] = "Distanzangriffskraft",
    [14] = "Zaubermacht",     [15] = "PvP-Abhärtung", [16] = "PvP-Macht",
    [17] = "Rüstung",         [18] = "Zusatzrüstung",
    [19] = "Gesundheit",      [20] = "Mana",          [21] = "Mana alle 5 Sek.",
}

local SIM_STAT_COUNT = 22

-- Die abgeleiteten Werte (Prozentangaben und Waffenschaden). Gebraucht
-- werden davon genau zwei — die Trefferchance-Grenzen —, und die sind an
-- derselben Ausgabe belegt (Platz 12 = 7,5 %). Der Rest steht hier nur, um
-- eine nicht uebernommene Grenze beim Namen nennen zu koennen.
local SIM_PSEUDO_NAME = {
    [0]  = "Waffenschaden (Haupthand)", [1] = "Waffenschaden (Nebenhand)",
    [2]  = "Waffenschaden (Distanz)",
    [3]  = "Blockchance",  [4] = "Ausweichchance", [5] = "Parierchance",
    [6]  = "Angriffstempo", [7] = "Distanzangriffstempo", [8] = "Zauberzeit",
    [9]  = "Nahkampftempo", [10] = "Distanztempo", [11] = "Zaubertempo",
    [12] = "Trefferchance (physisch)", [13] = "Trefferchance (Zauber)",
    [14] = "Kritische Chance (physisch)", [15] = "Kritische Chance (Zauber)",
}

-- Aus einer Prozentgrenze des Sims wird eine Grenze, die WeintCodex kennt.
-- Mehr als diese beiden gibt es hier nicht: Ausweichen und Parieren haben
-- in keinem Spec-Profil eine Decke, und eine erfundene waere schlimmer als
-- keine.
local SIM_PSEUDO_CAP = {
    [12] = { stat = "hit", typ = "melee" },
    [13] = { stat = "hit", typ = "spell" },
}

local SIM_PSEUDO_COUNT = 16

-- Waffenkunde und Treffer rechnen auf Stufe 90 mit derselben Zahl; sie
-- steht so auch in modules/charakter.lua (RATING_PER_PCT_FALLBACK). Sie
-- ist hier nur der Rueckfall: wo der Client seine eigene Umrechnung
-- meldet, gewinnt die (siehe SW.CapPercent).
local RATING_PER_PCT = 340

function SW.LooksLikeSim(text)
    if type(text) ~= "string" then return false end
    return text:find('"epWeightsStats"', 1, true) ~= nil
        or (text:find('"reforgeSettings"', 1, true) ~= nil
            and text:find('"player"', 1, true) ~= nil)
end

-- Die Zahlenreihe `field` innerhalb des Abschnitts `section`. Gesucht wird
-- ab dem Abschnitt, damit "stats" nicht das erstbeste Vorkommen im ganzen
-- Text trifft; das fuehrende Anfuehrungszeichen im Muster trennt dabei
-- "stats" von "pseudoStats".
--
-- Ein Feld, das keine reine Zahl ist, macht die ganze Reihe ungueltig
-- statt eine 0 zu erfinden: eine 0 an falscher Stelle ist genau die
-- stille Falschauskunft, gegen die die Laengenpruefung steht.
local function SimArray(text, section, field)
    local from = text:find('"' .. section .. '"', 1, true)
    if not from then return nil end
    local _, e = text:find('"' .. field .. '"%s*:%s*%[', from)
    if not e then return nil end
    local close = text:find("]", e, true)
    if not close then return nil end

    local out = {}
    for token in text:sub(e + 1, close - 1):gmatch("[^,]+") do
        local n = tonumber((token:gsub("%s+", "")))
        if not n then return nil end
        out[#out + 1] = n
    end
    return out
end

-- Der Klassenname des Sims ("ClassDeathKnight") als das Kuerzel, das der
-- Client benutzt ("DEATHKNIGHT"). `upper` ist hier unbedenklich: das ist
-- kein Anzeigetext, sondern ein reines ASCII-Kuerzel aus der Ausgabe.
local function SimClass(text)
    local name = text:match('"class"%s*:%s*"Class(%a+)"')
    if not name then return nil end
    return name:upper()
end

--------------------------------------------------
-- Rueckgabe: weights (roh, unskaliert), ignored, info
--            oder nil, Fehlertext
--
-- `info` traegt, was der Text ausser den Gewichten noch weiss: die Grenzen
-- und die Klasse. BEIDES WIRD GEMELDET, NICHT ANGEWENDET — eine Grenze ist
-- eine Aussage ueber das Spiel und steht im Spec-Profil, und eine
-- Gewichtung, die zu einer anderen Klasse gehoert, ist eine Frage an den
-- Spieler und keine an den Code.
--------------------------------------------------

function SW.ParseSim(text)
    local stats = SimArray(text, "epWeightsStats", "stats")
    if not stats then
        return nil, "Das sieht nach einer Sim-Ausgabe aus, trägt aber keine"
            .. " Wertegewichte. Im Sim erst rechnen lassen"
            .. " (|cffD4A24ASuggest Reforges|r bzw. die Werteberechnung),"
            .. " dann exportieren."
    end

    -- DIE LAENGE ENTSCHEIDET, OB WIR DIESE AUSGABE UEBERHAUPT VERSTEHEN.
    if #stats ~= SIM_STAT_COUNT then
        return nil, "Diese Sim-Ausgabe zählt " .. #stats .. " Werte,"
            .. " WeintCodex kennt die Reihenfolge von " .. SIM_STAT_COUNT
            .. ". Damit ist nicht mehr sicher, welche Zahl zu welchem Wert"
            .. " gehört — und eine falsch zugeordnete Gewichtung sieht"
            .. " vollständig aus. Bitte melden."
    end

    local weights, ignored, found = {}, {}, 0
    for i = 1, #stats do
        local idx   = i - 1
        local value = stats[i]
        local key   = SIM_STAT_KEY[idx]
        if key then
            if value ~= 0 then
                weights[key] = value
                found = found + 1
            end
        elseif value ~= 0 then
            ignored[#ignored + 1] = SIM_STAT_NAME[idx] or ("Feld " .. idx)
        end
    end

    local pseudo = SimArray(text, "epWeightsStats", "pseudoStats")
    if pseudo and #pseudo == SIM_PSEUDO_COUNT then
        for i = 1, #pseudo do
            if pseudo[i] ~= 0 then
                local name = SIM_PSEUDO_NAME[i - 1] or ("Feld " .. (i - 1))
                ignored[#ignored + 1] = name
            end
        end
    end

    if found == 0 then
        return nil, "In dieser Sim-Ausgabe steht kein einziges Gewicht über"
            .. " null. Im Sim erst die Wertegewichte ausrechnen lassen."
    end

    --------------------------------------------------
    -- Die Grenzen, die der Sim mitgibt
    --
    -- Waffenkunde steht dort als WERTUNG (5100), die Trefferchance als
    -- PROZENT (7,5). Beides bleibt so, wie es dasteht; umgerechnet wird
    -- erst beim Vergleich, weil die Umrechnung am Client haengt und nicht
    -- an dieser Datei (siehe SW.CapPercent).
    --------------------------------------------------
    local caps, capsIgnored = {}, {}

    local capStats = SimArray(text, "statCaps", "stats")
    if capStats and #capStats == SIM_STAT_COUNT then
        for i = 1, #capStats do
            local idx = i - 1
            if capStats[i] > 0 then
                local key = SIM_STAT_KEY[idx]
                if key then
                    caps[#caps + 1] = { stat = key, rating = capStats[i] }
                else
                    capsIgnored[#capsIgnored + 1] =
                        SIM_STAT_NAME[idx] or ("Feld " .. idx)
                end
            end
        end
    end

    local capPseudo = SimArray(text, "statCaps", "pseudoStats")
    if capPseudo and #capPseudo ~= SIM_PSEUDO_COUNT then
        -- Dieselbe Ueberlegung wie bei der Laenge oben, nur mit milderer
        -- Folge: eine Grenze wird hier nur GEMELDET, nie angewendet. Sie
        -- stillschweigend wegzulassen waere trotzdem falsch — dann fehlte
        -- sie im Vergleich, und niemand wuesste warum.
        capsIgnored[#capsIgnored + 1] = "abgeleitete Werte (Reihenfolge passt nicht)"
    elseif capPseudo then
        for i = 1, #capPseudo do
            local idx = i - 1
            if capPseudo[i] > 0 then
                local map = SIM_PSEUDO_CAP[idx]
                if map then
                    caps[#caps + 1] =
                        { stat = map.stat, typ = map.typ, pct = capPseudo[i] }
                else
                    capsIgnored[#capsIgnored + 1] =
                        SIM_PSEUDO_NAME[idx] or ("Feld " .. idx)
                end
            end
        end
    end

    return weights, ignored, {
        source      = "sim",
        caps        = caps,
        capsIgnored = capsIgnored,
        class       = SimClass(text),
    }
end

-- Eine Sim-Grenze als Prozentwert. `perPct` ist die Umrechnung, die der
-- CLIENT meldet (Wertung je Prozent); ohne sie bleibt die Zahl fuer
-- Stufe 90. Steht die Grenze schon in Prozent, wird nichts gerechnet.
function SW.CapPercent(cap, perPct)
    if not cap then return nil end
    if cap.pct then return cap.pct end
    if not cap.rating then return nil end
    local per = perPct
    if not per or per <= 0 then per = RATING_PER_PCT end
    return cap.rating / per
end

--------------------------------------------------
-- Der Einstieg: welcher der beiden Wege gilt
--------------------------------------------------

function SW.Parse(text)
    if type(text) ~= "string" or text:match("^%s*$") then
        return nil, "Da steht nichts."
    end

    -- Eine Sim-Ausgabe wird als Sim-Ausgabe gelesen oder gar nicht. Auf
    -- den Paarleser auszuweichen hiesse, aus Schluesselnamen und Zahlen
    -- eine Gewichtung zu bauen, die niemand so gemeint hat.
    if SW.LooksLikeSim(text) then
        -- SW.ParseSim meldet Misserfolg als `nil, Fehlertext` und Erfolg
        -- als `weights, ignored, info` — der zweite Rueckgabewert traegt
        -- also je nach Ausgang Verschiedenes.
        local weights, ignoredOrProblem, info = SW.ParseSim(text)
        if not weights then return nil, ignoredOrProblem end
        return weights, nil, ignoredOrProblem, info
    end

    local weights, ignored = ParsePairs(text)
    if not weights then
        return nil, "Darin steht kein einziges Wertepaar. Erwartet wird ein"
            .. " Wertname und eine Zahl — |cffD4A24ABeweglichkeit 100|r,"
            .. " |cffD4A24ACritRating=0.55|r, eine kopierte Werte-Tabelle"
            .. " oder das, was dir dein Sim ausgibt."
    end

    return weights, nil, ignored, { source = "pairs" }
end

--------------------------------------------------
-- Auf unsere Skala bringen
--
-- Sims geben Gewichte relativ heraus: der Primaerwert steht auf 1.0, alles
-- andere darunter (0.55 Krit, 0.48 Tempo). Unsere Profile fuehren denselben
-- Gedanken mit 100 fuer den Primaerwert, und die Eingabefelder nehmen ganze
-- Zahlen von 0 bis 999.
--
-- Umgerechnet wird deshalb auf "groesstes Gewicht = 100". Das ist
-- ausdruecklich KEINE Wertung, sondern nur ein Maszstabswechsel: welche
-- Werte wie zueinander stehen, aendert sich dabei nicht — und genau darauf
-- kommt es an, denn alle drei Seiten vergleichen Gewichte nur untereinander.
--
-- NEGATIVE GEWICHTE WERDEN 0, NICHT VERSCHWIEGEN. Manche Skalen setzen
-- einen Wert auf -1, um ihn zu meiden. Unsere Skala kennt kein "meiden",
-- nur "egal" — der Aufrufer bekommt die Liste und sagt es dazu.
--------------------------------------------------

local TOP = 100

function SW.Normalize(raw)
    if not raw then return nil end

    local top, negatives = 0, {}
    for key, value in pairs(raw) do
        if value < 0 then negatives[#negatives + 1] = key end
        if value > top then top = value end
    end

    -- Alles 0 oder negativ: dann gibt es nichts zu skalieren, und eine
    -- Division waere hier der Fehler, der stumm eine leere Gewichtung
    -- erzeugt.
    if top <= 0 then return nil, negatives end

    local out = {}
    for key, value in pairs(raw) do
        local scaled = math.floor((value / top) * TOP + 0.5)
        if scaled < 0   then scaled = 0   end
        if scaled > 999 then scaled = 999 end
        if scaled > 0   then out[key] = scaled end
    end
    return out, negatives
end
