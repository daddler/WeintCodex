--------------------------------------------------
-- WeintCodex :: Umschmieden — Grunddaten (BETA)
--------------------------------------------------
-- Alles, was am Umschmieden feststeht und sich nicht aus dem Client lesen
-- laesst. Drei Zahlen, eine Reihenfolge, ein paar Beschriftungen — mehr ist
-- es nicht, und mehr darf es auch nicht werden.
--
-- DIE REIHENFOLGE IST DER GANZE PUNKT DIESER DATEI.
--
-- Der Umschmieder kennt keine Statnamen. `C_Reforge.ReforgeItem(index)`
-- bekommt eine LAUFENDE NUMMER in der Liste der Umschmiedungen, die fuer
-- genau diesen Gegenstand zulaessig sind — und diese Liste entsteht,
-- indem der Client seine eigene Paartabelle von oben nach unten durchgeht
-- und jedes Paar mitzaehlt, dessen Quelle der Gegenstand traegt und dessen
-- Ziel er nicht traegt. Steht unsere Paartabelle auch nur an einer Stelle
-- anders herum als seine, schmiedet der Knopf "Alles umschmieden" etwas
-- anderes, als auf der Seite steht — und das faellt erst am Ergebnis auf,
-- nachdem Gold ausgegeben wurde.
--
-- Deshalb wird sie hier ERZEUGT und nicht abgetippt: die Regel ist "fuer
-- jede Quelle in Statreihenfolge jedes Ziel in Statreihenfolge, ausser sich
-- selbst", das sind 8 x 7 = 56 Paare, und der Umschmiedewert eines Paares
-- ist TABLE_BASE + seine Nummer. Eine abgetippte Tabelle koennte einen
-- Zahlendreher enthalten, den niemand ansieht; eine erzeugte kann das
-- nicht. WeintCodex_ValidateReforgeData() prueft trotzdem nach, denn die
-- REIHENFOLGE DER STATS ist die eine Annahme, die hier drinsteckt.
--
-- Die Statreihenfolge stammt nicht von uns: es ist die des Clients
-- (Willenskraft, Ausweichen, Parieren, Treffer, Krit, Tempo, Waffenkunde,
-- Meisterschaft). Sie steht in keiner API, sie ist an den Umschmiedewerten
-- 113..168 abzulesen, und ReforgeLite benutzt seit Cataclysm dieselbe.
--------------------------------------------------

WeintCodex_Reforge = {}

local R = WeintCodex_Reforge

-- Umgeschmiedet werden 40 % EINES Sekundaerwerts. Die Zahl steht seit
-- Cataclysm fest; sie steht ausserdem schon einmal in modules/charakter.lua
-- (REFORGE_SHARE) — dort fuer die Frage "wieviel Wertung waere ueberhaupt
-- noch zu bewegen". Zwei Konstanten fuer dieselbe Zahl waeren die Sorte
-- Doppelung, die auseinanderlaeuft, also liest jene Datei ab 2.7.0.0 diese
-- hier, falls sie geladen ist.
R.COEFF = 0.4

-- Umschmiedewert 113 ist das erste Paar. Der Wert im Item-Link ist
-- TABLE_BASE + laufende Nummer.
R.TABLE_BASE = 112

-- Die acht umschmiedbaren Werte, in der Reihenfolge des Clients.
R.STATS = { "spirit", "dodge", "parry", "hit", "crit", "haste", "expertise", "mastery" }

R.INDEX = {}
for i, key in ipairs(R.STATS) do R.INDEX[key] = i end

R.LABEL = {
    spirit    = "Willenskraft",
    dodge     = "Ausweichen",
    parry     = "Parieren",
    hit       = "Trefferwertung",
    crit      = "Kritische Trefferwertung",
    haste     = "Tempo",
    expertise = "Waffenkunde",
    mastery   = "Meisterschaft",
}

-- Kurzform fuer die Zeilen der Planungsliste. "Kritische Trefferwertung"
-- neben einem Pfeil und einer Zahl macht die Zeile unlesbar.
R.SHORT = {
    spirit    = "Willenskraft",
    dodge     = "Ausweichen",
    parry     = "Parieren",
    hit       = "Treffer",
    crit      = "Krit",
    haste     = "Tempo",
    expertise = "Waffenkunde",
    mastery   = "Meisterschaft",
}

--------------------------------------------------
-- Kampfwertungsindizes des Clients
--
-- Dieselbe Numerierung wie CR_INDEX / CR_HASTE_INDEX / CR_CRIT_INDEX in
-- modules/charakter.lua; sie steht hier noch einmal, weil der Planer alle
-- acht Werte braucht und jene Datei nur die drei kennt, an denen eine
-- Grenze haengt. Treffer, Krit und Tempo sind in MoP je eine einzige
-- Wertung — welchen der drei Indizes man abfragt, aendert das Ergebnis
-- nicht. Abgefragt wird trotzdem der zur Spec passende, damit hier
-- dieselbe Zahl herauskommt wie in der Cap-Pruefung.
--
-- Willenskraft ist KEINE Kampfwertung, sondern ein Grundwert
-- (UnitStat 5). Der Eintrag fehlt deshalb absichtlich.
--------------------------------------------------
R.CR = {
    dodge     = 3,
    parry     = 4,
    hit       = { melee = 6,  ranged = 7,  spell = 8  },
    crit      = { melee = 9,  ranged = 10, spell = 11 },
    haste     = { melee = 18, ranged = 19, spell = 20 },
    expertise = 24,
    mastery   = 26,
}

--------------------------------------------------
-- Die Paartabelle
--------------------------------------------------

R.PAIRS      = {}   -- [n] = { src = <idx>, dst = <idx>, id = TABLE_BASE + n }
R.PAIR_INDEX = {}   -- [srcIdx][dstIdx] = n
R.BY_ID      = {}   -- [TABLE_BASE + n] = n

do
    local n = 0
    for src = 1, #R.STATS do
        R.PAIR_INDEX[src] = {}
        for dst = 1, #R.STATS do
            if src ~= dst then
                n = n + 1
                R.PAIRS[n] = { src = src, dst = dst, id = R.TABLE_BASE + n }
                R.PAIR_INDEX[src][dst] = n
                R.BY_ID[R.TABLE_BASE + n] = n
            end
        end
    end
end

-- Kleinster/groesster Umschmiedewert. Der Item-Link wird damit geprueft,
-- statt eine Feldposition zu glauben (siehe modules/reforge_engine.lua).
R.MIN_ID = R.TABLE_BASE + 1
R.MAX_ID = R.TABLE_BASE + #R.PAIRS

--------------------------------------------------
-- Selbstpruefung
--------------------------------------------------
-- Die Erzeugung oben kann keinen Zahlendreher enthalten; was sie nicht
-- absichern kann, ist die Statreihenfolge. Diese Pruefung meldet deshalb
-- nur, was ueberhaupt zu pruefen ist: dass 56 Paare herausgekommen sind,
-- dass keines doppelt ist und dass Nummer und Umschmiedewert
-- zusammenpassen. Ob "Willenskraft" wirklich der erste Wert ist, kann sie
-- nicht wissen — dafuer steht der Vergleich mit dem angelegten Gegenstand
-- in /wc umschmieden.
--------------------------------------------------

function WeintCodex_ValidateReforgeData()
    local expected = #R.STATS * (#R.STATS - 1)
    local problems = {}

    if #R.PAIRS ~= expected then
        problems[#problems + 1] = string.format(
            "%d Paare statt %d", #R.PAIRS, expected)
    end

    local seen = {}
    for n, pair in ipairs(R.PAIRS) do
        local key = pair.src .. ">" .. pair.dst
        if seen[key] then
            problems[#problems + 1] = "Paar doppelt: " .. key
        end
        seen[key] = true
        if pair.src == pair.dst then
            problems[#problems + 1] = "Paar auf sich selbst: " .. key
        end
        if pair.id ~= R.TABLE_BASE + n then
            problems[#problems + 1] = string.format(
                "Umschmiedewert %d an Position %d", pair.id, n)
        end
    end

    if #problems > 0 then
        print("|cffD4A24A[WeintCodex]|r |cffE56B6BUmschmiede-Grunddaten fehlerhaft:|r")
        for _, text in ipairs(problems) do
            print("  |cffE56B6B" .. text .. "|r")
        end
        return false
    end
    return true
end
