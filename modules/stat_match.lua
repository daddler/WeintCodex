--------------------------------------------------
-- WeintCodex :: StatMatch (Werteabgleich)
--
-- DER FALLBACK FÜR DEN FALLBACK.
--
-- Die Bewertungskette für eine angelegte Verzauberung hatte bisher zwei
-- Stufen: (1) die Verzauberungs-ID steht in der Empfehlungsliste, (2) der
-- Name aus dem Item-Tooltip ist derselbe wie der eines Empfehlungseintrags.
-- Beide Stufen hängen an data/enchants.lua — und genau dort steckt das
-- Problem: MoP-Verzauberungs-IDs sind am Client nicht ableitbar, die Tabelle
-- ist von Hand gepflegt, mehrere Einträge tragen bis heute verify = true.
-- Eine falsche ID oder ein abweichend übersetzter Name reichte deshalb aus,
-- damit eine völlig korrekt verzauberte Rüstung als "nicht ideal" in der
-- Liste stand. Das ist der Fehler, der nicht sein darf: das Addon behauptet
-- einen Mangel, den es nicht gibt.
--
-- Diese Datei beantwortet stattdessen die Frage, um die es eigentlich geht:
--
--     WELCHE WERTE bringt das, was da draufliegt —
--     und sind das dieselben Werte wie bei der Empfehlung?
--
-- Werte lügen nicht. Sie stehen im Item-Tooltip (bzw. bei Steinen sogar
-- lokalisierungsfrei in GetItemStats), sie hängen an keiner von uns
-- gepflegten ID und an keiner Übersetzung. Stimmen die Werte der angelegten
-- Verzauberung mit denen einer Empfehlung überein, IST es die Empfehlung —
-- unabhängig davon, was unsere Tabelle über die ID denkt.
--
-- Vier Urteile (SM.CompareStats):
--   equal     identische Statschlüssel, identische Werte  -> dieselbe VZ
--   better    identische Schlüssel, mindestens ein Wert höher, keiner
--             niedriger -> die stärkere Stufe (Berufs-Exklusivvariante,
--             z.B. die "Geheime Inschrift" der Inschriftler) -> gilt als gut
--   weaker    identische Schlüssel, mindestens ein Wert niedriger ->
--             dieselbe Verzauberung eine Stufe zu niedrig; ehrlich als
--             "nicht ideal" melden, aber MIT Begründung statt als Rätsel
--   partial   Schlüssel überlappen nur teilweise -> andere Verzauberung
--   different keine Schnittmenge -> andere Verzauberung
--
-- WICHTIG — was hier NICHT passiert: Es wird nie über Wertungen (statWeights)
-- entschieden, ob etwas "gleichwertig" ist. Zwei Verzauberungen mit gleicher
-- Gesamtwertung, aber verschiedenen Stats sind NICHT dasselbe (170 Tempo ist
-- nicht 170 Meisterschaft). Nur deckungsgleiche Statschlüssel zählen — sonst
-- würde der Abgleich Fehler erzeugen statt welche zu beheben.
--
-- Zweiter Zweck: Statquellen. SM.EnchantStats / SM.GemStats liefern die
-- Werte eines Eintrags, egal ob sie in unseren Datendateien stehen oder
-- nicht — fehlt der Eintrag, fragt die Datei den Client (GetItemStats bzw.
-- Tooltip-Scan). Damit ist eine Lücke in gem_stats.lua kein blinder Fleck
-- mehr, sondern nur noch eine fehlende Zeile Dokumentation.
--
-- Lädt VOR modules/charakter.lua (siehe .toc) — charakter.lua bindet die
-- Funktionen beim Laden in eigene locals.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.StatMatch = {}
local SM = WeintCodex.StatMatch

--------------------------------------------------
-- STAT-SCHLÜSSELWÖRTER (deutscher Client)
--
-- Wohnte bis 2.0.0.2 in modules/charakter.lua. Hier her gezogen, weil der
-- Werteabgleich dieselbe Tabelle braucht — zwei Kopien wären genau die Art
-- Doppelpflege, die den Abgleich irgendwann wieder auseinanderlaufen lässt.
--
-- Reihenfolge = Priorität: spezifischere Begriffe zuerst
-- ("kritische Trefferwertung" vor "Trefferwertung" vor "Trefferwert").
--------------------------------------------------

-- DIE KURZFORMEN SIND PFLICHT, KEINE ZUGABE. Der MoP-Classic-Client
-- schreibt in den Wertzeilen die KURZE Form — und zwar in denen des
-- Gegenstands wie in denen der Verzauberung gleichermassen:
--
--     +1.201 Meisterschaft          (Gegenstand)
--     +170 Tempo                    (Verzauberung "Großes Tempo")
--     +991 Parieren                 (Gegenstand)
--     +180 kritischer Trefferwert   (Verzauberung "Überragende …")
--
-- Bis 2.0.0.3 kannte diese Tabelle nur die Langformen ("Tempowertung",
-- "Meisterschaftswertung"). Die Annahme dahinter war, dass die Kurzformen
-- allein am Gegenstand vorkommen und deshalb von selbst aus dem Parser
-- fallen — ein bequemer Filter, der aber die falsche Haelfte erwischt: mit
-- ihr war auch die ECHTE Verzauberungszeile unlesbar. Fuer den
-- Ausruestungs-Check hiess das, dass keine einzige Sekundaerwert-
-- Verzauberung Werte lieferte; der ganze Werteabgleich lief fuer sie leer,
-- und die Auswahl der richtigen Tooltip-Zeile fiel auf einen Gleichstand
-- zurueck, den die oberste Zeile gewann — die des Gegenstands. Genau das
-- meldete der Nutzer: "+1.201 Meisterschaft" als Verzauberung der
-- Handschuhe, waehrend exakt die empfohlene "+170 Tempo" darauflag.
--
-- Getrennt werden Gegenstands- und Verzauberungszeile jetzt dort, wo der
-- Unterschied wirklich liegt: an der Groessenordnung und am Treffer in
-- data/enchants.lua (siehe RankEnchantCandidate in modules/charakter.lua).
SM.STAT_KEYWORDS = {
    { "kritische trefferwertung", "crit" },
    { "kritischer trefferwert",   "crit" },
    { "krit. trefferwert",        "crit" },
    { "tempowertung",             "haste" },
    { "meisterschaftswertung",    "mastery" },
    { "meisterschaft",            "mastery" },
    { "ausweichwertung",          "dodge" },
    { "ausweichen",               "dodge" },
    { "parierwertung",            "parry" },
    { "parieren",                 "parry" },
    { "trefferwertung",           "hit" },
    { "trefferwert",              "hit" },
    { "waffenkunde",              "expertise" },
    { "beweglichkeit",            "agility" },
    { "intelligenz",              "intellect" },
    { "ausdauer",                 "stamina" },
    { "willenskraft",             "spirit" },
    { "stärke",                   "strength" },
    -- "tempo" steht bewusst ganz unten: es ist der kuerzeste Begriff der
    -- Tabelle und steckt als Teilwort in anderen ("Zaubertempo"). Weiter
    -- oben wuerde er spezifischere Treffer verdraengen.
    { "tempo",                    "haste" },
}

function SM.MatchStatKeyword(text)
    if not text then return nil end
    local lower = text:lower()
    for _, entry in ipairs(SM.STAT_KEYWORDS) do
        if lower:find(entry[1], 1, true) then
            return entry[2]
        end
    end
    return nil
end

--------------------------------------------------
-- ZAHLEN AUS TOOLTIP-TEXT
--
-- Der deutsche Client gruppiert Tausender mit einem PUNKT: die Handschuhe
-- aus dem Fehlerbericht zeigen "+1.201 Meisterschaft". Beide naheliegenden
-- Lesarten sind falsch — "(%d+)" liest davon die 1, tonumber("1.201")
-- ergibt 1,201. In beiden Faellen wird aus einem vierstelligen
-- Gegenstandswert eine Zahl in Verzauberungsgroesse, und damit laeuft jede
-- Plausibilitaetsgrenze ins Leere, die genau diesen Unterschied pruefen
-- soll (MAX_ENCHANT_VALUE in modules/charakter.lua).
--
-- Als Gruppierung gilt nur ein Trennzeichen, auf das GENAU drei Ziffern
-- folgen. Alles andere ist keine Gruppierung und wird abgeschnitten — ein
-- Dezimalanteil hat in einer Wertungszahl nichts zu suchen.
--------------------------------------------------

local NBSP = "\194\160"

-- Ziffernfolge samt moeglicher Gruppierungszeichen. Bewusst ohne %s: ein
-- gieriges Leerzeichen wuerde ueber das Stat-Wort hinweg in die naechste
-- Zahl derselben Zeile laufen.
local NUM_TOKEN = "(%d[%d%.,]*)"

function SM.ParseNumber(token)
    if not token then return nil end
    local cleaned = tostring(token)
    -- Zwei Durchgaenge decken bis zu neunstellige Zahlen ab; gsub arbeitet
    -- ueberlappungsfrei und verbraucht die fuehrende Ziffer der Gruppe.
    cleaned = cleaned:gsub("(%d)[%.,](%d%d%d)", "%1%2")
    cleaned = cleaned:gsub("(%d)[%.,](%d%d%d)", "%1%2")
    return tonumber(cleaned:match("^(%d+)"))
end

function SM.ParseStatText(text)
    if not text then return nil end
    local normalized = text:gsub(NBSP, " ")
    local value = SM.ParseNumber(normalized:match(NUM_TOKEN))
    if not value then return nil end
    local stat = SM.MatchStatKeyword(normalized)
    if not stat then return nil end
    return stat, value
end

-- Alle "+<Wert> <Stat>"-Paare einer Zeile einsammeln. Verzauberungen mit
-- zwei Stats ("+285 Beweglichkeit und +165 kritische Trefferwertung",
-- Beinrüstungen) würden mit ParseStatText sonst falsch zusammengesetzt
-- (erster Wert + zuletzt gefundenes Schlüsselwort).
function SM.ParseAllStats(text)
    if not text then return nil end
    local normalized = text:gsub(NBSP, " ")
    local stats, count = {}, 0
    for token, label in normalized:gmatch("%+%s*" .. NUM_TOKEN .. "%s*([^%+]+)") do
        local key = SM.MatchStatKeyword(label)
        local num = SM.ParseNumber(token)
        if key and num then
            stats[key] = (stats[key] or 0) + num
            count = count + 1
        end
    end
    if count == 0 then return nil end
    return stats
end

--------------------------------------------------
-- STATS VOM CLIENT (lokalisierungsfrei)
--
-- GetItemStats liefert eine Tabelle, deren SCHLÜSSEL die Namen der
-- ITEM_MOD_*-Konstanten sind ("ITEM_MOD_CRIT_RATING_SHORT"), nicht deren
-- übersetzte Werte. Das ist die einzige Statquelle im ganzen Addon, die
-- weder von unserer Datenpflege noch von der Übersetzung abhängt — für
-- Sockelsteine (eigenständige Items) also die erste Wahl.
--
-- Die Spell-Varianten (…_SPELL_RATING_SHORT) stammen aus der Zeit getrennter
-- Zauber-/Nahkampfwertungen; MoP führt sie zusammen, ältere Steine tragen
-- sie aber noch, deshalb landen sie auf denselben Schlüsseln.
--------------------------------------------------

local ITEM_MOD_MAP = {
    ITEM_MOD_STRENGTH_SHORT            = "strength",
    ITEM_MOD_AGILITY_SHORT             = "agility",
    ITEM_MOD_INTELLECT_SHORT           = "intellect",
    ITEM_MOD_STAMINA_SHORT             = "stamina",
    ITEM_MOD_SPIRIT_SHORT              = "spirit",
    ITEM_MOD_CRIT_RATING_SHORT         = "crit",
    ITEM_MOD_CRIT_SPELL_RATING_SHORT   = "crit",
    ITEM_MOD_CRIT_MELEE_RATING_SHORT   = "crit",
    ITEM_MOD_CRIT_RANGED_RATING_SHORT  = "crit",
    ITEM_MOD_HASTE_RATING_SHORT        = "haste",
    ITEM_MOD_HASTE_SPELL_RATING_SHORT  = "haste",
    ITEM_MOD_MASTERY_RATING_SHORT      = "mastery",
    ITEM_MOD_HIT_RATING_SHORT          = "hit",
    ITEM_MOD_HIT_SPELL_RATING_SHORT    = "hit",
    ITEM_MOD_HIT_MELEE_RATING_SHORT    = "hit",
    ITEM_MOD_HIT_RANGED_RATING_SHORT   = "hit",
    ITEM_MOD_EXPERTISE_RATING_SHORT    = "expertise",
    ITEM_MOD_DODGE_RATING_SHORT        = "dodge",
    ITEM_MOD_PARRY_RATING_SHORT        = "parry",
}

local GetItemStatsCompat = GetItemStats or (C_Item and C_Item.GetItemStats)

-- Eigener Scan-Tooltip. Bewusst NICHT der aus charakter.lua: der wird dort
-- für Item-Slots benutzt und beide Dateien setzen ihn mitten im jeweils
-- anderen Durchlauf neu — ein gemeinsamer Tooltip liefert dann die Zeilen
-- des zuletzt gesetzten Gegenstands.
local tip = CreateFrame("GameTooltip", "WeintCodexStatMatchTip", nil, "GameTooltipTemplate")
tip:SetOwner(UIParent, "ANCHOR_NONE")

local gemStatCache    = {}
local enchantStatCache = {}

-- Items, deren Basisdaten beim Abfragen noch nicht im Client-Cache lagen.
-- charakter.lua holt sie sich über SM.TakePendingItems() ab und meldet sie
-- an seinen GET_ITEM_INFO_RECEIVED-Watcher, der die Seite dann neu zeichnet.
local pendingItems = {}

function SM.ClearCache()
    gemStatCache    = {}
    enchantStatCache = {}
    pendingItems    = {}
end

-- Liefert die gesammelten Item-IDs und leert die Liste.
function SM.TakePendingItems()
    local out = pendingItems
    pendingItems = {}
    return out
end

local function CopyStats(src)
    if not src then return nil end
    local out, n = {}, 0
    for k, v in pairs(src) do
        if type(v) == "number" and v ~= 0 then
            out[k] = v
            n = n + 1
        end
    end
    if n == 0 then return nil end
    return out
end

-- Stats eines Gegenstands (Stein, Verzauberungsrolle) vom Client.
-- Rückgabe: stats | nil
local function StatsFromItemAPI(itemId)
    if not (GetItemStatsCompat and itemId) then return nil end
    local ok, raw = pcall(GetItemStatsCompat, "item:" .. itemId)
    if not ok or type(raw) ~= "table" then return nil end
    local out, n = {}, 0
    for key, value in pairs(raw) do
        local mapped = ITEM_MOD_MAP[key]
        if mapped and type(value) == "number" and value ~= 0 then
            out[mapped] = (out[mapped] or 0) + value
            n = n + 1
        end
    end
    if n == 0 then return nil end
    return out
end

-- Zweiter Weg: den Tooltip des Gegenstands/der Verzauberung lesen und die
-- "+<Wert> <Stat>"-Zeilen parsen. Nötig, wenn GetItemStats nichts liefert
-- (Verzauberungs-Hyperlinks haben keine Item-Stats) oder wenn der Stein
-- keine klassischen Item-Mods trägt.
local function StatsFromTooltip(hyperlink)
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    local ok = pcall(tip.SetHyperlink, tip, hyperlink)
    if not ok then return nil end
    local n = tip:NumLines() or 0
    local acc, found = {}, false
    for i = 1, n do
        local line = _G["WeintCodexStatMatchTipTextLeft" .. i]
        local txt  = line and line:GetText()
        if txt and txt ~= "" then
            local stats = SM.ParseAllStats(txt)
            if stats then
                for k, v in pairs(stats) do
                    acc[k] = (acc[k] or 0) + v
                end
                found = true
            end
        end
    end
    if not found then return nil end
    return acc
end

--------------------------------------------------
-- Stats eines Sockelsteins.
--   1) data/gem_stats.lua (kuratiert, verlässlich)
--   2) GetItemStats (Client, lokalisierungsfrei)
--   3) Tooltip-Scan (Client, deutsche Langformen)
-- Rückgabe: stats | nil, quelle ("db" | "client" | "tooltip")
--------------------------------------------------
function SM.GemStats(gemId)
    if not gemId then return nil end
    local cached = gemStatCache[gemId]
    if cached ~= nil then
        if cached == false then return nil end
        return cached.stats, cached.source
    end

    local db = WeintCodex_GemStats and WeintCodex_GemStats[gemId]
    local stats, source = CopyStats(db), db and "db" or nil

    if not stats then
        stats = StatsFromItemAPI(gemId)
        if stats then source = "client" end
    end
    if not stats then
        stats  = StatsFromTooltip("item:" .. gemId)
        if stats then source = "tooltip" end
    end

    if not stats then
        -- Noch nicht im Client-Cache? Dann ist das kein unbekannter Stein,
        -- sondern nur ein zu früher Scan — Nachlieferung anmelden und NICHT
        -- dauerhaft als "nichts gefunden" cachen.
        if GetItemInfo and not GetItemInfo(gemId) then
            pendingItems[gemId] = true
            return nil
        end
        gemStatCache[gemId] = false
        return nil
    end

    gemStatCache[gemId] = { stats = stats, source = source }
    return stats, source
end

--------------------------------------------------
-- Stats einer Verzauberung.
--   1) data/enchants.lua
--   2) Tooltip des enchant:-Hyperlinks (viele IDs lösen darüber auf)
-- Rückgabe: stats | nil, quelle ("db" | "tooltip")
--
-- Für Proc-Verzauberungen (Lied des Windes, Jadegeist, DK-Runen) gibt es
-- bewusst KEINE Stats — die dürfen nie über Werte verglichen werden, ihr
-- Nutzen steckt im Proc. Für sie liefert diese Funktion nil, und der
-- Werteabgleich hält sich dann heraus.
--------------------------------------------------
function SM.EnchantStats(enchantId)
    if not enchantId then return nil end
    local cached = enchantStatCache[enchantId]
    if cached ~= nil then
        if cached == false then return nil end
        return cached.stats, cached.source
    end

    local db = WeintCodex_Enchants and WeintCodex_Enchants[enchantId]
    local stats, source = CopyStats(db and db.stats), (db and db.stats) and "db" or nil

    if not stats then
        stats = StatsFromTooltip("enchant:" .. enchantId)
        if stats then source = "tooltip" end
    end

    if not stats then
        enchantStatCache[enchantId] = false
        return nil
    end

    enchantStatCache[enchantId] = { stats = stats, source = source }
    return stats, source
end

--------------------------------------------------
-- VERGLEICH
--------------------------------------------------

-- Absolute Rundungstoleranz für "gleich". Der Client zeigt gelegentlich
-- ab-/aufgerundete Werte; 1 Wertung Unterschied ist keine andere
-- Verzauberung.
local EQUAL_EPS = 1

-- Relative Toleranz für "gehört zur selben Verzauberung" (SM.SameFamily).
-- Deutlich weiter gefasst als EQUAL_EPS, weil hier bewusst auch die
-- Stufenunterschiede innerhalb einer Verzauberungsfamilie mitgenommen
-- werden — genau dafür ist die Funktion da: eine ID identifizieren, deren
-- Wert in unserer Tabelle veraltet ist (170 statt 180 usw.).
local FAMILY_TOLERANCE = 0.25

function SM.IsEmpty(stats)
    if type(stats) ~= "table" then return true end
    return next(stats) == nil
end

function SM.Sum(stats)
    local total = 0
    if type(stats) == "table" then
        for _, v in pairs(stats) do
            if type(v) == "number" then total = total + v end
        end
    end
    return total
end

-- Rückgabe: verdict, ratio
--   verdict  "equal" | "better" | "weaker" | "partial" | "different"
--   ratio    Gesamtwert des Kandidaten / Gesamtwert der Referenz (gerundet
--            auf Prozent), nil wenn nicht sinnvoll bestimmbar
function SM.CompareStats(candidate, reference)
    if SM.IsEmpty(candidate) or SM.IsEmpty(reference) then
        return "different", nil
    end

    local shared, onlyCandidate, onlyReference = 0, 0, 0
    for key in pairs(candidate) do
        if reference[key] then shared = shared + 1 else onlyCandidate = onlyCandidate + 1 end
    end
    for key in pairs(reference) do
        if not candidate[key] then onlyReference = onlyReference + 1 end
    end

    local refSum = SM.Sum(reference)
    local ratio  = (refSum > 0)
        and math.floor((SM.Sum(candidate) / refSum) * 100 + 0.5) or nil

    if shared == 0 then return "different", ratio end
    if onlyCandidate > 0 or onlyReference > 0 then return "partial", ratio end

    local higher, lower = false, false
    for key, value in pairs(candidate) do
        local ref = reference[key]
        if value > ref + EQUAL_EPS then
            higher = true
        elseif value < ref - EQUAL_EPS then
            lower = true
        end
    end

    if lower  then return "weaker", ratio end
    if higher then return "better", ratio end
    return "equal", ratio or 100
end

-- "Ist das dieselbe Verzauberung, nur mit leicht anderem Zahlenwert?"
-- Deckungsgleiche Statschlüssel + jeder Wert innerhalb FAMILY_TOLERANCE.
-- Damit wird eine ID auch dann noch richtig zugeordnet, wenn der Wert in
-- data/enchants.lua veraltet ist.
function SM.SameFamily(a, b)
    local verdict = SM.CompareStats(a, b)
    if verdict ~= "equal" and verdict ~= "better" and verdict ~= "weaker" then
        return false
    end
    for key, value in pairs(a) do
        local ref  = b[key]
        local high = math.max(value, ref)
        if high > 0 and math.abs(value - ref) / high > FAMILY_TOLERANCE then
            return false
        end
    end
    return true
end

-- Rangfolge der Urteile: je kleiner, desto besser passend.
local VERDICT_RANK = {
    equal = 1, better = 2, weaker = 3, partial = 4, different = 5,
}

SM.VERDICT_RANK = VERDICT_RANK

-- Gilt das Urteil als "die Empfehlung liegt an"?
function SM.IsMatch(verdict)
    return verdict == "equal" or verdict == "better"
end

-- Stats gegen eine Liste von Empfehlungs-IDs abgleichen.
--   stats     Werte der angelegten Verzauberung / des Steins
--   list      Liste von IDs (bestEnchants / bestGems)
--   resolver  Funktion(id) -> stats  (SM.EnchantStats bzw. SM.GemStats)
-- Rückgabe: verdict, refId, ratio
function SM.MatchAgainstList(stats, list, resolver)
    if SM.IsEmpty(stats) or not list or not resolver then
        return "different", nil, nil
    end

    local bestVerdict, bestId, bestRatio = "different", nil, nil
    for _, id in ipairs(list) do
        local refStats = resolver(id)
        if refStats then
            local verdict, ratio = SM.CompareStats(stats, refStats)
            if (VERDICT_RANK[verdict] or 9) < (VERDICT_RANK[bestVerdict] or 9) then
                bestVerdict, bestId, bestRatio = verdict, id, ratio
                if verdict == "equal" then break end
            end
        end
    end

    return bestVerdict, bestId, bestRatio
end

--------------------------------------------------
-- ANZEIGE
--------------------------------------------------

-- Kurzer Zusatz für die Zeile im Charakter-Fenster. Bewusst knapp: die
-- Zeile hat schon Slot, Gegenstand, Verzauberung und Empfehlung.
local VERDICT_NOTE = {
    equal  = "werte-identisch",
    better = "stärkere Stufe",
    weaker = "schwächere Stufe",
}

function SM.VerdictNote(verdict)
    return VERDICT_NOTE[verdict]
end

-- "agility=285, crit=165" — für /wc vz und Fehlermeldungen.
function SM.FormatStats(stats)
    if SM.IsEmpty(stats) then return nil end
    local parts = {}
    for key, value in pairs(stats) do
        parts[#parts + 1] = key .. "=" .. value
    end
    table.sort(parts)
    return table.concat(parts, ", ")
end
