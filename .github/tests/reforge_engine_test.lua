-- Kopflose Pruefung des Umschmiede-Planers gegen rohe Gewalt.
-- Laeuft ausserhalb des Spiels; alles, was der Client sonst beantwortet,
-- steht hier als Attrappe.

local ROOT = ...
package.path = ROOT .. "/?.lua;" .. package.path

--== WoW-Attrappen ==========================================================
_G = _G or getfenv(0)

local function stubFrame()
    local f = {}
    local mt = { __index = function() return function() end end }
    setmetatable(f, mt)
    f.NumLines = function() return 0 end
    f.SetOwner = function() end
    f.ClearLines = function() end
    f.SetHyperlink = function() end
    return f
end
CreateFrame = function() return stubFrame() end
UIParent = stubFrame()
REFORGED = "Umgeschmiedet"

local EQUIP = {}
local ITEMS = {}          -- [slotId] = { id=, stats={}, reforge=nil }

GetInventoryItemLink = function(_, slot)
    local it = ITEMS[slot]
    if not it then return nil end
    return string.format("|cffa335ee|Hitem:%d:0:0:0:0:0:0:0:90:%d:0:0|h[Item%d]|h|r",
        it.id, it.reforge or 0, it.id)
end
GetItemInfo = function() return "Item", nil, 4, 0,0,0,0,0,0, "tex", 1000 end
C_Item = { GetDetailedItemLevelInfo = function() return 496 end }
GetItemStats = function(link)
    local id = tonumber(tostring(link):match("item:(%d+)")) or tonumber(tostring(link):match("^item:(%d+)"))
    for _, it in pairs(ITEMS) do if it.id == id then return it.raw end end
    return nil
end
UnitClass = function() return "Krieger", "WARRIOR" end
UnitRace  = function() return "Ork", "Orc" end
UnitStat  = function() return 0, 0 end
GetSpecialization = function() return 1 end
local RATINGS = {}
GetCombatRating = function(i) return RATINGS[i] or 0 end
InCombatLockdown = function() return false end
C_Timer = nil
debugprofilestop = nil

--== Addon-Umfeld ===========================================================
WeintCodex = { SavedData = {} }
WeintCodex.FormatGrouped = function(v) return tostring(v) end
WeintCodex.ColorText = function(_, t) return t end

dofile(ROOT .. "/data/reforge.lua")
local R = WeintCodex_Reforge

-- StatMatch: nur ItemStats wird gebraucht.
WeintCodex.StatMatch = {
    ItemStats = function(link)
        local raw = GetItemStats(link)
        if not raw then return nil end
        local out = {}
        for k, v in pairs(raw) do out[k] = v end
        return out
    end,
}

local CAPCTX = nil
WeintCodex.Charakter = {
    EquipSlots = EQUIP,
    CapContext = function() return CAPCTX end,
    GetProfileKey = function() return "TEST" end,
}

dofile(ROOT .. "/modules/reforge_engine.lua")
local RE = WeintCodex.ReforgeEngine
RE.SetOption("enabled", true)

--== Aufbau eines Testfalls =================================================
local function setup(items, weights, caps, ratings)
    for k in pairs(EQUIP) do EQUIP[k] = nil end
    for k in pairs(ITEMS) do ITEMS[k] = nil end
    for k in pairs(RATINGS) do RATINGS[k] = nil end

    for i, spec in ipairs(items) do
        EQUIP[i] = { id = i, name = "Slot" .. i }
        ITEMS[i] = { id = 1000 + i, raw = spec }
    end
    for k, v in pairs(ratings) do RATINGS[k] = v end

    CAPCTX = {
        profile = { role = "MELEE", statWeights = weights },
        profileKey = "TEST", specDisplay = "Test",
        caps = caps or {}, breakpoints = {},
    }
    RE.Invalidate()
    RE.ForgetLinks()
end

--== Rohe Gewalt ============================================================
local function brute(ctx, items)
    local best, bestScore, bestMiss
    local choice = {}
    local n = #items
    local function rec(i)
        if i > n then
            local total = {}
            for k, v in pairs(ctx.baseline) do total[k] = v end
            for j, item in ipairs(items) do
                for k, v in pairs(item.options[choice[j]].delta) do
                    total[k] = (total[k] or 0) + v
                end
            end
            local score = RE.Score(ctx, total)
            local miss = 0
            for key, goal in pairs(ctx.target) do
                if goal.require and (total[key] or 0) < goal.rating - 1 then miss = miss + 1 end
            end
            if best == nil or miss < bestMiss or (miss == bestMiss and score > bestScore + 1e-9) then
                best, bestScore, bestMiss = { unpack(choice) }, score, miss
            end
            return
        end
        for j = 1, #items[i].options do
            choice[i] = j
            rec(i + 1)
        end
    end
    rec(1)
    return best, bestScore, bestMiss
end

--== Faelle =================================================================
local fails = 0
local function check(name, items, weights, caps, ratings)
    setup(items, weights, caps, ratings)
    local plan = RE.GetPlan(true)
    if not plan.ok then
        print("FEHLER  " .. name .. ": " .. tostring(plan.problem))
        fails = fails + 1
        return
    end

    local ctx = plan.ctx
    local scanned = RE.ScanItems()
    for _, item in ipairs(scanned) do
        item.options = RE.ItemOptions(item, ctx.mult, ctx.conv)
    end
    local _, bruteScore, bruteMiss = brute(ctx, scanned)

    local planMiss = plan.capMisses or 0
    local ok = (planMiss <= bruteMiss) and (plan.scoreAfter >= bruteScore - 1e-6)
    print(string.format("%-34s Planer %10.1f (%d verfehlt)   roh %10.1f (%d)   %s",
        name, plan.scoreAfter, planMiss, bruteScore, bruteMiss, ok and "ok" or "ABWEICHUNG"))
    if not ok then fails = fails + 1 end
end

local W = { hit = 100, crit = 60, haste = 55, mastery = 50, expertise = 90,
            spirit = 0, dodge = 0, parry = 0 }

-- 6 (Kopf) ist CR_HIT_MELEE, 24 Waffenkunde, 9 Krit, 18 Tempo, 26 Meisterschaft
local function caps(hitPct, hitUnder)
    return { { stat = "hit", typ = "melee", capPct = hitPct, current = hitPct - 1,
               overPct = -1, overRating = 0, underRating = hitUnder,
               perPct = 340, label = "Trefferwertung" } }
end

check("5 Teile, kein Kap",
    { { crit = 400, haste = 300 }, { crit = 350, mastery = 250 },
      { haste = 500, mastery = 200 }, { hit = 300, crit = 200 },
      { mastery = 450, expertise = 150 } },
    W, {}, { [6] = 300, [9] = 950, [18] = 800, [26] = 900, [24] = 150 })

check("5 Teile, Trefferkap fehlt 400",
    { { crit = 400, haste = 300 }, { crit = 350, mastery = 250 },
      { haste = 500, mastery = 200 }, { hit = 300, crit = 200 },
      { mastery = 450, expertise = 150 } },
    W, caps(7.5, 400), { [6] = 300, [9] = 950, [18] = 800, [26] = 900, [24] = 150 })

check("5 Teile, Trefferkap fehlt 1200",
    { { crit = 400, haste = 300 }, { crit = 350, mastery = 250 },
      { haste = 500, mastery = 200 }, { hit = 300, crit = 200 },
      { mastery = 450, expertise = 150 } },
    W, caps(7.5, 1200), { [6] = 300, [9] = 950, [18] = 800, [26] = 900, [24] = 150 })

check("6 Teile, Kap knapp (zweiter Zug noetig)",
    { { crit = 500, haste = 200 }, { crit = 480, mastery = 210 },
      { haste = 520, mastery = 190 }, { crit = 300, haste = 300 },
      { mastery = 470, crit = 150 }, { haste = 260, mastery = 260 } },
    W, caps(7.5, 260), { [6] = 2200, [9] = 1000, [18] = 900, [26] = 950, [24] = 200 })

check("6 Teile, Kap unerreichbar",
    { { crit = 500, haste = 200 }, { crit = 480, mastery = 210 },
      { haste = 520, mastery = 190 }, { crit = 300, haste = 300 },
      { mastery = 470, crit = 150 }, { haste = 260, mastery = 260 } },
    W, caps(7.5, 9000), { [6] = 100, [9] = 1000, [18] = 900, [26] = 950, [24] = 200 })

--== Zauberer: Waffenkunde zaehlt als Zaubertreffer ========================
-- Die Umwandlung muss auf BEIDEN Seiten der Rechnung stehen: im Istwert
-- und in den Aenderungen. Stimmt nur eine, wird Waffenkunde entweder
-- weggeschmiedet (obwohl sie ins Kap laeuft) oder doppelt gezaehlt.
UnitClass = function() return "Magier", "MAGE" end

local WC = { hit = 100, crit = 60, haste = 55, mastery = 50, expertise = 0,
             spirit = 0, dodge = 0, parry = 0 }

check("Magier, Waffenkunde -> Zaubertreffer",
    { { crit = 400, haste = 300 }, { expertise = 350, mastery = 250 },
      { haste = 500, mastery = 200 }, { hit = 300, crit = 200 },
      { mastery = 450, expertise = 150 } },
    WC, { { stat = "hit", typ = "spell", capPct = 15, current = 13,
            overPct = -2, overRating = 0, underRating = 700,
            perPct = 340, label = "Zaubertreffer" } },
    { [8] = 2000, [11] = 900, [20] = 800, [26] = 900, [24] = 400 })

-- Und die Gegenprobe: die Waffenkunde, die schon dasteht, muss im Istwert
-- stehen. Ohne sie waere das Kap hier scheinbar nicht erreichbar.
do
    setup({ { expertise = 800, crit = 200 } }, WC,
        { { stat = "hit", typ = "spell", capPct = 15, current = 14,
            overPct = -1, overRating = 0, underRating = 340,
            perPct = 340, label = "Zaubertreffer" } },
        { [8] = 1000, [11] = 900, [20] = 800, [26] = 900, [24] = 800 })
    local plan = RE.GetPlan(true)
    local live = plan.ok and plan.ctx.live.hit
    print(string.format("%-34s Istwert Zaubertreffer %s (1000 + 800 Waffenkunde erwartet)",
        "Istwert mit Umwandlung", tostring(live)))
    if live ~= 1800 then fails = fails + 1 end
end

UnitClass = function() return "Krieger", "WARRIOR" end

--== Gesperrte Slots bleiben, wie sie sind =================================
do
    setup({ { crit = 400, haste = 300 }, { crit = 350, mastery = 250 },
            { haste = 500, mastery = 200 } }, W, {},
        { [6] = 300, [9] = 950, [18] = 800, [26] = 900, [24] = 150 })
    RE.SetLocked(2, true)
    local plan = RE.GetPlan(true)
    local row = plan.ok and plan.rows[2]
    local ok = row and row.locked and not row.changed
    print(string.format("%-34s %s", "Gesperrter Slot bleibt unangetastet",
        ok and "ok" or "ABWEICHUNG"))
    if not ok then fails = fails + 1 end
    RE.SetLocked(2, false)
end

--== Der Umschmiedewert im Item-Link ======================================
-- Die eine Frage, an der ein Lauf scheitern kann, ohne dass es sonst
-- irgendwo auffaellt. Geprueft werden beide Wege: die Zerlegung des
-- Clients und der Rueckfall ueber die Feldposition.
do
    local pairIdx = R.PAIR_INDEX[R.INDEX.crit][R.INDEX.hit]
    setup({ { crit = 400, haste = 300 } }, W, {},
        { [6] = 300, [9] = 950, [18] = 800, [26] = 900, [24] = 150 })
    ITEMS[1].reforge = R.TABLE_BASE + pairIdx

    -- Weg 3: Feldsuche (der Client kennt die Zerlegung nicht)
    RE.ForgetLinks()
    local cur = RE.CurrentPair(1)
    local okScan = cur and cur.src == R.INDEX.crit and cur.dst == R.INDEX.hit
    print(string.format("%-34s %s", "Link ohne Client-Zerlegung", okScan and "ok" or "ABWEICHUNG"))
    if not okScan then fails = fails + 1 end

    -- Weg 1: die Zerlegung des Clients
    GetItemInfoFromHyperlink = function(link)
        local data = link:match("|Hitem:([^|]+)")
        return tonumber(data:match("^(%d+)")), data
    end
    LinkUtil = { SplitLinkOptions = function(opts)
        local out = {}
        for piece in (opts .. ":"):gmatch("([^:]*):") do out[#out + 1] = piece end
        return unpack(out)
    end }
    RE.ForgetLinks()
    cur = RE.CurrentPair(1)
    local okClient = cur and cur.src == R.INDEX.crit and cur.dst == R.INDEX.hit
    print(string.format("%-34s %s", "Link ueber die Client-Zerlegung", okClient and "ok" or "ABWEICHUNG"))
    if not okClient then fails = fails + 1 end

    -- Und ohne Umschmiedung kommt nichts zurueck.
    ITEMS[1].reforge = 0
    RE.ForgetLinks()
    local none = RE.CurrentPair(1)
    print(string.format("%-34s %s", "Unumgeschmiedet bleibt leer", none == nil and "ok" or "ABWEICHUNG"))
    if none ~= nil then fails = fails + 1 end
end

--== Die laufende Nummer fuer den Umschmieder ==============================
-- Sie entsteht, indem die Paartabelle von oben durchgegangen und jedes
-- fuer den Gegenstand zulaessige Paar mitgezaehlt wird. Nachgerechnet wird
-- das hier von Hand, genau so, wie ReforgeLite es tut.
do
    local item = { stats = { crit = 400, haste = 300 } }
    local wrong = 0
    for _, pair in ipairs(R.PAIRS) do
        local src, dst = R.STATS[pair.src], R.STATS[pair.dst]
        local allowed = (item.stats[src] or 0) ~= 0 and (item.stats[dst] or 0) == 0
        local got = RE.ForgeIndex(item, pair.src, pair.dst)
        if allowed then
            local expect = -1
            for _, p2 in ipairs(R.PAIRS) do
                local s2, d2 = R.STATS[p2.src], R.STATS[p2.dst]
                if (item.stats[s2] or 0) ~= 0 and (item.stats[d2] or 0) == 0 then
                    expect = expect + 1
                end
                if p2 == pair then break end
            end
            if got ~= expect then wrong = wrong + 1 end
        elseif got ~= nil then
            wrong = wrong + 1
        end
    end
    print(string.format("%-34s %s", "Laufende Nummer je Paar",
        wrong == 0 and "ok (56 Paare)" or (wrong .. " falsch")))
    if wrong > 0 then fails = fails + 1 end
end

--== Die Schreibweisen des Clients =========================================
-- DIE STELLE, AN DER 2.7.1.0 GESCHEITERT IST.
--
-- GetItemStats liefert seine Schluessel als Namen der ITEM_MOD_*-Konstanten.
-- Kennt das Addon eine Schreibweise nicht, faellt der Wert lautlos heraus —
-- und dann zaehlt ForgeIndex eine andere Zahl zulaessiger Umschmiedungen als
-- der Client. Der Umschmieder legt daraufhin verlaesslich etwas anderes an,
-- als auf der Seite steht.
--
-- Geprueft wird gegen die Liste aus ReforgeLite, weil sie am laufenden
-- Client belegt ist: Willenskraft und Meisterschaft mit `_SHORT`, die
-- uebrigen sechs ohne.
do
    -- stat_match.lua braucht nur diese beiden Attrappen zusaetzlich.
    strlenutf8 = function(t) return #t end
    dofile(ROOT .. "/modules/stat_match.lua")
    local SM = WeintCodex.StatMatch

    local CLIENT_KEYS = {
        ITEM_MOD_SPIRIT_SHORT          = "spirit",
        ITEM_MOD_DODGE_RATING          = "dodge",
        ITEM_MOD_PARRY_RATING          = "parry",
        ITEM_MOD_HIT_RATING            = "hit",
        ITEM_MOD_CRIT_RATING           = "crit",
        ITEM_MOD_HASTE_RATING          = "haste",
        ITEM_MOD_EXPERTISE_RATING      = "expertise",
        ITEM_MOD_MASTERY_RATING_SHORT  = "mastery",
    }

    local raw, want = {}, {}
    for key, stat in pairs(CLIENT_KEYS) do
        raw[key]  = 100
        want[stat] = 100
    end
    local got = SM.NormalizeItemStats(raw) or {}

    local bad = {}
    for stat, value in pairs(want) do
        if got[stat] ~= value then bad[#bad + 1] = stat end
    end
    print(string.format("%-34s %s", "Statnamen des Clients (ReforgeLite)",
        #bad == 0 and "ok (alle acht)" or ("FEHLT: " .. table.concat(bad, ", "))))
    if #bad > 0 then fails = fails + 1 end

    -- Und die Selbstpruefung meldet, wenn eine Schreibweise fehlt. Hier
    -- traegt die Attrappe alle acht, sie muss also durchgehen.
    for key in pairs(CLIENT_KEYS) do _G[key] = key end
    local ok = SM.ValidateStatKeys()
    print(string.format("%-34s %s", "Selbstpruefung der Schreibweisen",
        ok and "ok" or "ABWEICHUNG"))
    if not ok then fails = fails + 1 end
end

print(fails == 0 and "\nAlles bestanden." or ("\n" .. fails .. " Abweichung(en)."))
os.exit(fails == 0 and 0 or 1)
