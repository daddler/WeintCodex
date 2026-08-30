--------------------------------------------------
-- WeintCodex :: Sim-Gewichte uebernehmen (seit 2.7.3.0)
--------------------------------------------------
-- Ein Sim im Spiel waere Monate Arbeit und eine eigene Spielsimulation —
-- und einer, der nur so aussieht, waere schlimmer als keiner: seine Zahlen
-- saehen aus wie echte. Was ein Sim aber liefert und was hier fehlte, sind
-- die WERTEGEWICHTE. Genau die sind die Schnittstelle: WeintCodex rechnet
-- ohnehin mit Gewichten, an drei Stellen (Sockel, Verzauberungen,
-- Umschmieden). Wer simuliert hat, soll sein Ergebnis hier einsetzen
-- koennen, statt es abzutippen.
--
-- DAS FORMAT IST PAWN, UND ZWAR AUS EINEM GRUND.
--
-- WoWSims, Raidbots, AskMrRobot und Pawn selbst geben Wertegewichte
-- allesamt als Pawn-Zeichenkette heraus. Sie ist einzeilig, sie ist Text,
-- und sie ist seit Jahren stabil. Ein eigenes Format zu erfinden hiesse,
-- die eine Sache nachzubauen, die es schon gibt — und ReforgeLite liest
-- dieselbe.
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
-- Die Namen, die Sims benutzen
--
-- Pawn kennt fuer denselben Wert mehrere Schreibweisen, und die Exporte
-- der Sims sind sich darin nicht einig: WoWSims schreibt `CritRating`,
-- aeltere Pawn-Skalen `SpellCritRating`, manche Zettel schlicht `Crit`.
-- Aufgeschrieben wird deshalb jede, die vorkommt — dieselbe Lehre wie bei
-- den ITEM_MOD-Schluesseln in modules/stat_match.lua: die Schreibweise ist
-- nicht unsere Entscheidung.
--------------------------------------------------

local NAMES = {
    strength  = { "Strength", "Str" },
    agility   = { "Agility", "Agi" },
    intellect = { "Intellect", "Int" },
    stamina   = { "Stamina", "Sta" },
    spirit    = { "Spirit", "Spi", "Mp5" },
    hit       = { "HitRating", "Hit", "SpellHitRating", "MeleeHitRating",
                  "RangedHitRating" },
    crit      = { "CritRating", "Crit", "SpellCritRating", "MeleeCritRating",
                  "RangedCritRating" },
    haste     = { "HasteRating", "Haste", "SpellHasteRating",
                  "MeleeHasteRating", "RangedHasteRating" },
    expertise = { "ExpertiseRating", "Expertise", "Exp" },
    mastery   = { "MasteryRating", "Mastery" },
    dodge     = { "DodgeRating", "Dodge" },
    parry     = { "ParryRating", "Parry" },
}

local LOOKUP = {}
for key, names in pairs(NAMES) do
    for _, name in ipairs(names) do LOOKUP[name:lower()] = key end
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
-- Rueckgabe: weights (rohe Zahlen, unskaliert), name, ignored
--            oder nil, Fehlertext
--
-- `ignored` sammelt jeden Schluessel, den wir nicht kennen. Er wird nicht
-- verschwiegen: eine Pawn-Skala traegt Dinge wie `Dps` oder
-- `MetaSocketEffect`, und wer nicht sieht, dass sie unter den Tisch
-- fallen, haelt das Ergebnis fuer vollstaendig.
--------------------------------------------------

local function ParsePairs(text)
    local weights, ignored, found = {}, {}, 0
    -- Ein abschliessendes Komma anhaengen, damit auch das letzte Paar auf
    -- dasselbe Muster passt (derselbe Kniff wie in ReforgeLite).
    for pair in (text .. ","):gmatch("[^,]*,") do
        local stat, value = pair:match("^%s*([%a%d_]+)%s*=%s*(%-?[%d%.]+)%s*,$")
        value = tonumber(value)
        if stat and value then
            local key = LOOKUP[stat:lower()]
            if key then
                -- Mehrere Schreibweisen desselben Werts (SpellHitRating
                -- neben HitRating): die groessere gewinnt, statt sie zu
                -- addieren — es ist derselbe Wert, nicht zwei.
                if not weights[key] or value > weights[key] then
                    weights[key] = value
                end
                found = found + 1
            else
                ignored[#ignored + 1] = stat
            end
        end
    end
    if found == 0 then return nil end
    return weights, ignored
end

function SW.Parse(text)
    if type(text) ~= "string" or text:match("^%s*$") then
        return nil, "Da steht nichts."
    end

    -- Die vollstaendige Pawn-Zeichenkette: ( Pawn: v1: "Name": Stat=Wert, … )
    local version, name, values =
        text:match('^%s*%(%s*[Pp]awn%s*:%s*v(%d+)%s*:%s*"([^"]*)"%s*:%s*(.-)%s*%)%s*$')

    if version and tonumber(version) and tonumber(version) > 1 then
        return nil, "Das ist eine Pawn-Zeichenkette der Fassung "
            .. version .. " — gelesen wird Fassung 1."
    end

    -- Ohne Klammer-Rahmen wird der ganze Text als Paarliste gelesen. Manche
    -- Sims geben nur "Agility=1, CritRating=0.55, …" heraus, und daran soll
    -- der Import nicht scheitern.
    local weights, ignored = ParsePairs(values or text)
    if not weights then
        return nil, "Darin steht kein einziges Wertepaar der Form"
            .. " |cffD4A24AName=Zahl|r. Erwartet wird eine"
            .. " Pawn-Zeichenkette, wie WoWSims, Raidbots und AMR sie"
            .. " ausgeben."
    end

    return weights, (name ~= "" and name or nil), ignored
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

--------------------------------------------------
-- Skalen aus Pawn, falls Pawn installiert ist
--
-- Wer schon eine Skala gepflegt hat, soll sie nicht erst exportieren
-- muessen. Gelesen wird nur, was Pawn selbst gespeichert hat; geschrieben
-- wird dort nie.
--------------------------------------------------

function SW.PawnScales()
    local out = {}
    local common = _G.PawnCommon
    if not (common and common.Scales) then return out end

    local _, _, classId = UnitClass("player")
    for key, scale in pairs(common.Scales) do
        if type(scale) == "table" and type(scale.Values) == "table" then
            -- Nur die Skalen der eigenen Klasse: eine Heilerskala auf einem
            -- Schurken ist keine Auswahl, sondern eine Falle. Skalen ohne
            -- Klassenangabe bleiben drin — sie koennen selbst gebaut sein.
            if scale.ClassID == nil or classId == nil or scale.ClassID == classId then
                out[#out + 1] = {
                    name   = scale.LocalizedName or tostring(key),
                    values = scale.Values,
                }
            end
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- Eine Pawn-Skala hat ihre Werte schon als Tabelle; sie muss nur durch
-- dieselbe Namenszuordnung und dieselbe Skalierung wie eine eingefuegte
-- Zeichenkette. Zwei Wege mit zwei Rechnungen waeren zwei Gelegenheiten
-- auseinanderzulaufen.
function SW.FromValues(values)
    if type(values) ~= "table" then return nil end
    local raw, ignored, found = {}, {}, 0
    for stat, value in pairs(values) do
        if type(value) == "number" then
            local key = LOOKUP[tostring(stat):lower()]
            if key then
                if not raw[key] or value > raw[key] then raw[key] = value end
                found = found + 1
            else
                ignored[#ignored + 1] = tostring(stat)
            end
        end
    end
    if found == 0 then return nil end
    return raw, nil, ignored
end
