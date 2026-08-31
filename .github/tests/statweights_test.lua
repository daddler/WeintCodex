-- Kopflose Pruefung des Sim-Gewichte-Imports (modules/statweights.lua).
--
-- Das Zerlegen einer fremden Zeichenkette ist genau die Sorte Rechnung, die
-- man ausserhalb des Spiels pruefen koennen muss: ein Muster, das ein Feld
-- verschluckt, faellt im Spiel erst auf, wenn jemand mit einer Gewichtung
-- rechnet, die zur Haelfte fehlt.
--
-- Geprueft wird ausdruecklich gegen MEHRERE Gestalten desselben Inhalts -
-- Ausgabezeichenkette, kopierte Tabelle, JSON-Zeile, getippte Liste. Ein
-- Import, der nur eine davon versteht, geht kaputt, sobald die Quelle ihre
-- Ausgabe umstellt.
--
--   lua5.1 .github/tests/statweights_test.lua .

local ROOT = ...

WeintCodex = {}
dofile(ROOT .. "/modules/statweights.lua")
local SW = WeintCodex.StatWeights

local fails = 0
local function Check(name, ok, detail)
    print(string.format("%-48s %s", name, ok and "ok" or ("ABWEICHUNG  " .. (detail or ""))))
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

local function Weights(text)
    local raw = SW.Parse(text)
    return (SW.Normalize(raw))
end

--== Dieselben Zahlen in vier Gestalten =====================================
-- Beweglichkeit 1.00, Treffer 0.88, Krit 0.68 - egal wie geschrieben.
do
    local want = "agility=100 crit=68 hit=88"

    local forms = {
        ["Ausgabezeichenkette"] =
            '( X: v1: "WW Monk": Agility=1.00, HitRating=0.88, CritRating=0.68 )',
        ["blosse Paarliste"] =
            "Agility=1.00, HitRating=0.88, CritRating=0.68",
        ["kopierte Tabelle"] =
            "Agility\t1.00\nHit Rating\t0.88\nCrit Rating\t0.68",
        ["JSON-Zeile"] =
            '{ "Agility": 1.00, "HitRating": 0.88, "CritRating": 0.68 }',
        ["deutsch getippt"] =
            "Beweglichkeit 1,0\nTrefferwertung 0.88\nKritische Trefferwertung 0.68",
    }

    for label, text in pairs(forms) do
        local w = Weights(text)
        Check("Gelesen: " .. label, Show(w) == want, Show(w))
    end
end

--== Das deutsche Dezimalkomma =============================================
do
    -- "Krit 0,68" darf nicht als "Krit 0" gelesen werden - der Wert fiele
    -- still auf null, und genau das faellt niemandem auf.
    local w = Weights("Beweglichkeit 1,00\nKrit 0,68\nTempo 0,75")
    Check("Komma als Nachkommastelle",
        w and w.agility == 100 and w.crit == 68 and w.haste == 75, Show(w))

    -- Dieselben Zahlen in Tausenderschreibweise. Weil nach dem Lesen auf
    -- "groesstes Gewicht = 100" skaliert wird, muss dabei DASSELBE
    -- herauskommen - egal, ob das Komma als Nachkommastelle oder als
    -- Tausendertrennzeichen gelesen wurde. Entscheidend ist nur, dass die
    -- Lesart innerhalb eines Textes einheitlich ist.
    local t = Weights("Strength 3,400\nCritRating 1,870")
    Check("Komma ohne Punkte im Text",
        t and t.strength == 100 and t.crit == 55, Show(t))

    -- Und mit Punktschreibweise daneben wird das Komma zum Tausender.
    local e = Weights("Strength 3,400\nCritRating 1,870\nHasteRating 1700.0")
    Check("Komma neben Punktschreibweise",
        e and e.strength == 100 and e.crit == 55 and e.haste == 50, Show(e))

    -- Und ein Komma zwischen zwei Paaren trennt weiterhin.
    local c = Weights("Agility=1,CritRating=0.5")
    Check("Komma trennt weiterhin zwei Paare",
        c and c.agility == 100 and c.crit == 50, Show(c))
end

--== Der Maszstab ===========================================================
do
    -- Sims geben Bruchteile heraus, andere Quellen grosse Zahlen. Beides
    -- landet auf derselben Skala, und die Verhaeltnisse bleiben.
    local a = Weights("Strength=1, CritRating=0.55, HasteRating=0.5")
    local b = Weights("Strength=3400, CritRating=1870, HasteRating=1700")
    Check("Bruchteile und grosse Zahlen ergeben dasselbe",
        Show(a) == Show(b) and a and a.strength == 100 and a.crit == 55,
        Show(a) .. "  /  " .. Show(b))
end

--== Fremde Schluessel ======================================================
do
    -- Eine Sim-Ausgabe traegt Dinge wie Dps oder MetaSocketEffect. Sie
    -- duerfen die Skalierung nicht verzerren - und sie muessen gemeldet
    -- werden, sonst haelt man das Ergebnis fuer vollstaendig.
    local raw, _, ignored = SW.Parse(
        "Agility=1, CritRating=0.5, Dps=980, MetaSocketEffect=41")
    local w = SW.Normalize(raw)
    Check("Dps verzerrt die Skala nicht",
        w and w.agility == 100 and w.crit == 50 and w.dps == nil, Show(w))

    local named = table.concat(ignored or {}, ",")
    Check("Unbekannte Namen werden gemeldet",
        named:find("Dps", 1, true) and named:find("MetaSocketEffect", 1, true),
        named)
end

--== Ein Wert, zwei Namen ===================================================
do
    local w = Weights("Intellect=1, SpellHitRating=0.9, HitRating=0.6")
    -- Es ist EIN Wert, nicht zwei: addiert werden darf hier nichts.
    Check("Zwei Namen fuer Treffer werden nicht addiert", w and w.hit == 90, Show(w))
end

--== Zweiwortnamen ==========================================================
do
    -- "Crit Rating" muss als EIN Name gelesen werden. Wird nur das letzte
    -- Wort genommen, trifft "Rating" nie zu und der Wert faellt weg.
    local w = Weights("Agility 1  Crit Rating 0.5  Haste Rating 0.25")
    Check("Zweiwortnamen werden zusammengezogen",
        w and w.agility == 100 and w.crit == 50 and w.haste == 25, Show(w))
end

--== Negative Gewichte ======================================================
do
    local raw = SW.Parse("Agility=1, Strength=-1, CritRating=0.5")
    local w, negatives = SW.Normalize(raw)
    -- Unsere Skala kennt "egal", nicht "meiden" - das wird gesagt, nicht
    -- stillschweigend gemacht.
    Check("Negatives wird 0 und gemeldet",
        w and w.strength == nil and w.agility == 100
          and negatives and #negatives == 1 and negatives[1] == "strength",
        Show(w))
end

--== Was nicht gelesen werden kann, sagt es =================================
do
    local a = SW.Parse("")
    local b = SW.Parse("völliger Unsinn ohne eine einzige Zahl")
    Check("Leer und Unsinn werden abgelehnt", a == nil and b == nil)

    -- Eine Liste, in der alles 0 ist, ergibt keine Gewichtung - statt einer
    -- stillen leeren.
    Check("Alles 0 ergibt keine Gewichtung",
        SW.Normalize(SW.Parse("Agility=0, CritRating=0")) == nil)

    -- Und eine Zahl ohne Namen davor erfindet keinen Wert.
    Check("Blosse Zahlen erfinden nichts", SW.Parse("1 2 3 4") == nil)
end

--== Kein fremdes Addon =====================================================
do
    -- Diese Datei darf die gespeicherten Daten keines anderen Addons
    -- anfassen. Geprueft wird strukturell, nicht am Verhalten.
    local f = io.open(ROOT .. "/modules/statweights.lua", "r")
    local text = f:read("*a")
    f:close()
    local hits = {}
    for line in text:gmatch("[^\r\n]+") do
        if not line:match("^%s*%-%-") and line:match("Pawn") then
            hits[#hits + 1] = line
        end
    end
    Check("Kein Zugriff auf ein fremdes Addon", #hits == 0, hits[1])
end

print(fails == 0 and "\nAlles bestanden." or ("\n" .. fails .. " Abweichung(en)."))
os.exit(fails == 0 and 0 or 1)
