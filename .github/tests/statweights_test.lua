-- Kopflose Pruefung des Sim-Gewichte-Imports (modules/statweights.lua).
--
-- Das Zerlegen einer fremden Zeichenkette ist genau die Sorte Rechnung, die
-- man ausserhalb des Spiels pruefen koennen muss: ein Muster, das ein Feld
-- verschluckt, faellt im Spiel erst auf, wenn jemand eine Gewichtung
-- benutzt, die zur Haelfte fehlt.
--
--   lua5.1 .github/tests/statweights_test.lua .

local ROOT = ...

WeintCodex = {}
UnitClass = function() return "Moench", "MONK", 10 end

dofile(ROOT .. "/modules/statweights.lua")
local SW = WeintCodex.StatWeights

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-46s %s", name, ok and "ok" or ("ABWEICHUNG  " .. (detail or ""))))
    if not ok then fails = fails + 1 end
end

local function Show(t)
    if not t then return "nil" end
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do out[#out + 1] = k .. "=" .. t[k] end
    return table.concat(out, " ")
end

--== Die vollstaendige Pawn-Zeichenkette ===================================
do
    local str = '( Pawn: v1: "WW Monk": Agility=1.00, HitRating=0.88,'
             .. ' ExpertiseRating=0.85, HasteRating=0.75, CritRating=0.68,'
             .. ' MasteryRating=0.66, Stamina=0.10 )'
    local raw, name, ignored = SW.Parse(str)
    Check("Pawn-Zeichenkette wird gelesen", raw ~= nil and name == "WW Monk", tostring(name))

    local w = SW.Normalize(raw)
    -- Der groesste Wert wird 100, die Verhaeltnisse bleiben.
    Check("Auf 100 skaliert, Verhaeltnisse bleiben",
        w and w.agility == 100 and w.hit == 88 and w.expertise == 85
          and w.haste == 75 and w.crit == 68 and w.mastery == 66 and w.stamina == 10,
        Show(w))
    Check("Nichts faelschlich verworfen", ignored and #ignored == 0,
        ignored and table.concat(ignored, ","))
end

--== Ganze Zahlen statt Bruchteilen ========================================
do
    -- Manche Sims geben schon grosse Zahlen heraus. Skaliert wird trotzdem
    -- auf 100, sonst stuenden die Felder auf 999.
    local raw = SW.Parse('( Pawn: v1: "X": Strength=3400, CritRating=1870, HasteRating=1700 )')
    local w = SW.Normalize(raw)
    Check("Grosse Zahlen kommen auch auf die Skala",
        w and w.strength == 100 and w.crit == 55 and w.haste == 50, Show(w))
end

--== Ohne Klammer-Rahmen ===================================================
do
    local raw = SW.Parse("Agility=1, CritRating=0.5, HasteRating=0.25")
    local w = SW.Normalize(raw)
    Check("Blosse Paarliste wird auch gelesen",
        w and w.agility == 100 and w.crit == 50 and w.haste == 25, Show(w))
end

--== Fremde Schluessel fallen NICHT unter den Tisch =========================
do
    -- Eine Pawn-Skala traegt Dinge wie Dps oder MetaSocketEffect. Sie
    -- duerfen die Skalierung nicht verzerren - und sie muessen gemeldet
    -- werden, sonst haelt man das Ergebnis fuer vollstaendig.
    local raw, _, ignored = SW.Parse(
        '( Pawn: v1: "X": Agility=1, CritRating=0.5, Dps=980, MetaSocketEffect=41 )')
    local w = SW.Normalize(raw)
    Check("Dps verzerrt die Skala nicht",
        w and w.agility == 100 and w.crit == 50 and w.dps == nil, Show(w))
    local named = ignored and table.concat(ignored, ",") or ""
    Check("Unbekannte Schluessel werden gemeldet",
        named:find("Dps", 1, true) ~= nil and named:find("MetaSocketEffect", 1, true) ~= nil,
        named)
end

--== Mehrere Schreibweisen desselben Werts =================================
do
    local raw = SW.Parse("Intellect=1, SpellHitRating=0.9, HitRating=0.6")
    local w = SW.Normalize(raw)
    -- Es ist EIN Wert, nicht zwei: addiert werden darf hier nichts.
    Check("Zwei Namen fuer Treffer werden nicht addiert",
        w and w.hit == 90, Show(w))
end

--== Negative Gewichte =====================================================
do
    local raw = SW.Parse("Agility=1, Strength=-1, CritRating=0.5")
    local w, negatives = SW.Normalize(raw)
    Check("Negatives wird 0 und gemeldet",
        w and w.strength == nil and w.agility == 100
          and negatives and #negatives == 1 and negatives[1] == "strength",
        Show(w))
end

--== Was nicht gelesen werden kann, sagt es ================================
do
    local a = SW.Parse("")
    local b = SW.Parse("völliger Unsinn ohne Gleichheitszeichen")
    local c = SW.Parse('( Pawn: v2: "X": Agility=1 )')
    Check("Leer, Unsinn und Fassung 2 werden abgelehnt",
        a == nil and b == nil and c == nil)

    -- Und eine Skala, in der alles 0 ist, ergibt keine Gewichtung -
    -- statt einer stillen leeren.
    local raw = SW.Parse("Agility=0, CritRating=0")
    Check("Alles 0 ergibt keine Gewichtung", SW.Normalize(raw) == nil)
end

--== Pawn-Skalen der eigenen Klasse ========================================
do
    PawnCommon = { Scales = {
        ["Mine"]   = { LocalizedName = "Mein Windläufer", ClassID = 10,
                       Values = { Agility = 1, CritRating = 0.5, Dps = 12 } },
        ["Fremd"]  = { LocalizedName = "Heilige Priesterin", ClassID = 5,
                       Values = { Intellect = 1 } },
        ["Frei"]   = { LocalizedName = "Ohne Klasse",
                       Values = { Agility = 1 } },
    } }
    local scales = SW.PawnScales()
    local names = {}
    for _, s in ipairs(scales) do names[#names + 1] = s.name end
    table.sort(names)
    Check("Nur Skalen der eigenen Klasse (plus klassenlose)",
        #scales == 2 and names[1] == "Mein Windläufer" and names[2] == "Ohne Klasse",
        table.concat(names, ", "))

    local raw = SW.FromValues(scales[1].values)
    local w = SW.Normalize(raw)
    Check("Pawn-Skala geht durch dieselbe Rechnung",
        w and w.agility == 100 and w.crit == 50 and w.dps == nil, Show(w))
end

print(fails == 0 and "\nAlles bestanden." or ("\n" .. fails .. " Abweichung(en)."))
os.exit(fails == 0 and 0 or 1)
