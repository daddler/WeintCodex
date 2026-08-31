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
-- KEIN FREMDES ADDON UND KEIN FREMDES FORMAT.
--
-- Diese Datei liest weder die gespeicherten Daten eines anderen Addons noch
-- verlangt sie eine bestimmte Zeichenkette. Sie liest WERTEPAARE: einen
-- Wertnamen, dann eine Zahl. Alles andere im Text wird uebergangen.
--
-- Das ist ausdruecklich der robustere Weg und nicht der bequemere. Ein
-- Muster, das auf EIN Ausgabeformat passt, geht kaputt, sobald jene Seite
-- ihre Ausgabe umstellt — und das merkt hier niemand ausser dem, der sich
-- wundert, warum seine Gewichtung zur Haelfte fehlt. Wertepaare dagegen
-- sind das, was jede Quelle gemeinsam hat:
--
--   * die Ausgabezeichenkette von wowsims.com/mop,
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

function SW.Parse(text)
    if type(text) ~= "string" or text:match("^%s*$") then
        return nil, "Da steht nichts."
    end

    local weights, ignored = ParsePairs(text)
    if not weights then
        return nil, "Darin steht kein einziges Wertepaar. Erwartet wird ein"
            .. " Wertname und eine Zahl — |cffD4A24ABeweglichkeit 100|r,"
            .. " |cffD4A24ACritRating=0.55|r, eine kopierte Werte-Tabelle"
            .. " oder das, was dir dein Sim ausgibt."
    end

    return weights, nil, ignored
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
