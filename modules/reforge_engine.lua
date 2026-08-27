--------------------------------------------------
-- WeintCodex :: Umschmieden — Planer (BETA)
--------------------------------------------------
-- Beantwortet zwei Fragen und sonst keine:
--   1. Was traegt jedes angelegte Teil an umschmiedbarer Wertung, und was
--      ist daran gerade umgeschmiedet?
--   2. Welche Verteilung waere nach den Gewichten und Grenzen der eigenen
--      Spec die beste?
--
-- Diese Datei zeichnet nichts und kennt keine Farben (dieselbe Trennung wie
-- modules/rotation_engine.lua gegenueber modules/rotationtrainer.lua). Sie
-- laedt nach modules/charakter.lua, weil sie deren Slotliste, Item-Zerlegung
-- und vor allem deren Cap- und Schwellenrechnung liest.
--
--
-- ES GIBT NUR EINE RECHNUNG FUER "WIEVIEL BRINGT DIESER WERT NOCH".
--
-- Caps (Treffer, Waffenkunde) und die Tempo-Treppe stehen bereits in
-- modules/charakter.lua, sie speisen dort den Spielraum der Sockelplanung,
-- und `/wc tempo` druckt ihre Herleitung aus. Diese Datei rechnet sie
-- deshalb NICHT nach, sondern ruft `WeintCodex.Charakter.Scan()` und liest
-- `scan.caps`, `scan.breakpoints` und `scan.profile.statWeights`. Zwei
-- Rechnungen nebeneinander waeren genau die Doppelung, an der die
-- Sockelbewertung ueber fuenf Releases gescheitert ist (siehe PlanItem
-- dort): die Umschmiedeseite behauptete sonst ein anderes Trefferkap als
-- die Seite daneben, und niemand koennte sagen, welche recht hat.
--
--
-- DIE SUMMEN KOMMEN VOM CHARAKTERBOGEN, DIE EINZELBETRAEGE VOM GEGENSTAND.
--
-- Was ein Spieler an Trefferwertung HAT, weiss der Client (GetCombatRating);
-- was ein einzelner Gegenstand dazu beitraegt, steht in seinen Itemdaten.
-- Der Planer haengt deshalb an beidem: der Ausgangspunkt ist die
-- Kampfwertung des Clients, aus der die aktuell angelegten Umschmiedungen
-- herausgerechnet werden, und bewegt wird darauf mit den Betraegen aus den
-- Itemdaten. Damit stimmt die Summe immer, auch wenn ein Einzelbetrag um
-- ein paar Punkte danebenliegt — und "unveraendert lassen" ergibt exakt
-- wieder den Istwert.
--
--
-- ITEMWERTE KOMMEN VOM GRUNDGEGENSTAND, NICHT VOM ANGELEGTEN LINK.
--
-- Umgeschmiedet wird der Wert, den der Gegenstand SELBST traegt — nicht
-- der Stein darin und nicht die Verzauberung darauf. Gefragt wird deshalb
-- `GetItemStats("item:<id>")`: das ist der blanke Grundgegenstand, ohne
-- Steine, ohne Verzauberung, ohne bereits angelegte Umschmiedung. Der Link
-- des angelegten Teils koennte all das enthalten, und ob er es tut, ist von
-- hier aus nicht zu belegen — dieselbe Vorsicht wie bei der Sockelfolge in
-- modules/charakter.lua. `/wc umschmieden` druckt beide Fassungen
-- nebeneinander aus, damit ein Unterschied sichtbar wird statt sich in die
-- Empfehlung zu schleichen.
--
-- Was der Grundgegenstand nicht kennt, ist die AUFWERTUNGSSTUFE. Ein
-- Gegenstand auf 4/4 traegt gut 16 % mehr Wertung als sein Grundwert, und
-- das ist zuviel, um es zu uebergehen. Hochgerechnet wird mit der
-- Budgetkurve von MoP (1,15 je 15 Gegenstandsstufen) und mit dem Abstand,
-- den der CLIENT zwischen Link und blankem Gegenstand meldet — nicht mit
-- einer Aufwertungstabelle, die wir pflegen muessten. Das ist eine
-- Naeherung, sie steht als solche in `/wc umschmieden`, und sie wirkt nur
-- auf die Einzelbetraege, nie auf die Summen (siehe oben).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.ReforgeEngine = {}

local RE = WeintCodex.ReforgeEngine
local R  = WeintCodex_Reforge
local SM = WeintCodex.StatMatch

--------------------------------------------------
-- Einstellungen
--------------------------------------------------
-- `enabled` ist mit Absicht AUS. Das Werkzeug ist in Entwicklung, seine
-- Vorschlaege sind noch nicht belastbar, und es gibt Gold aus — es darf
-- niemandem passieren, sondern muss eingeschaltet werden.
--------------------------------------------------

local DEFAULTS = {
    enabled  = false,
    autoOpen = true,    -- Fenster beim Umschmieder von selbst oeffnen
}

local function Store()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local store = WeintCodex.SavedData.reforge
    if not store then
        store = {}
        WeintCodex.SavedData.reforge = store
    end
    store.options = store.options or {}
    for key, value in pairs(DEFAULTS) do
        if store.options[key] == nil then store.options[key] = value end
    end
    store.locked = store.locked or {}
    return store
end

function RE.GetOption(key)
    return Store().options[key]
end

-- Bewusst OHNE Settings.Refresh(): aus einem Schalter jener Seite heraus
-- waere das ein Neuaufbau mitten im Klick, und das Widget, das man gerade
-- umgelegt hat, gaebe es danach nicht mehr (siehe modules/settings.lua).
-- Der Slash-Befehl zieht die offene Seite selbst nach, so wie GA.Command.
function RE.SetOption(key, value)
    Store().options[key] = value and true or false
end

function RE.Enabled()
    return Store().options.enabled and true or false
end

function RE.IsLocked(slotId)
    return Store().locked[slotId] and true or false
end

function RE.SetLocked(slotId, on)
    Store().locked[slotId] = on and true or nil
    RE.Invalidate()
end

--------------------------------------------------
-- Hilfsfunktionen
--------------------------------------------------

local function SafeNum(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and type(value) == "number" then return value end
    return nil
end

local function Round(v)
    return math.floor((v or 0) + 0.5)
end

--------------------------------------------------
-- Der Umschmiedewert im Item-Link
--
-- Der Client legt ihn in ein Feld des Links, dessen Position sich zwischen
-- Erweiterungen und Clientstaenden verschoben hat. Statt eine davon zu
-- glauben, wird der Bereich abgesucht, in dem sie ueberhaupt liegen kann,
-- und dort das eine Feld genommen, dessen Wert ein gueltiger
-- Umschmiedewert IST (113..168). Kein anderes Feld dieses Bereichs kann in
-- diesem Zahlenraum liegen: die Aufwertungsnummern beginnen bei 373, die
-- Spezialisierungsnummern von MoP liegen darunter oder darueber, und die
-- Stufe steht davor.
--
-- Die Felder 8 (uniqueID) und 9 (Stufe) bleiben ausdruecklich aussen vor:
-- uniqueID ist eine grosse Zufallszahl und koennte zufaellig treffen.
--------------------------------------------------

local LINK_REFORGE_FIELDS = { 10, 11, 12, 13 }

local function ReforgeFromLink(link)
    local data = link and link:match("|Hitem:([^|]+)")
    if not data then return nil, nil end

    local parts, i = {}, 0
    for piece in (data .. ":"):gmatch("([^:]*):") do
        i = i + 1
        parts[i] = tonumber(piece)
    end

    for _, pos in ipairs(LINK_REFORGE_FIELDS) do
        local value = parts[pos]
        if value and R.BY_ID[value] then
            return R.PAIRS[R.BY_ID[value]], pos
        end
    end
    return nil, nil
end

--------------------------------------------------
-- Gegenprobe am Tooltip
--
-- Der Link sagt WELCHE Umschmiedung angelegt ist; der Tooltip sagt nur, OB
-- eine angelegt ist — ueber die eigene Zeichenkette des Clients (REFORGED).
-- Diese Ja/Nein-Auskunft ist die Gegenprobe auf die Feldposition im Link.
--
-- SIE WIDERSPRICHT, SIE VERBIETET NICHT.
-- Ein Widerspruch steht an der Zeile und in /wc umschmieden, die Zeile
-- bleibt aber planbar. Der Grund ist die Richtung des Irrtums: was der
-- Umschmieder tatsaechlich anlegt, haengt an der laufenden Nummer, und die
-- haengt allein an den Werten des GRUNDgegenstands — nicht daran, was
-- gerade umgeschmiedet ist. Eine falsch gelesene angelegte Umschmiedung
-- macht die Betraege ungenau; die Zeile deswegen ganz zu sperren, machte
-- aus einer ungenauen Zahl gar keine. Und stimmte unsere Lesart der
-- Zeichenkette REFORGED einmal nicht, waere das Werkzeug damit auf einen
-- Schlag fuer jeden umgeschmiedeten Gegenstand tot — eine Pruefung, die im
-- Zweifel alles abschaltet, ist keine.
--------------------------------------------------

local scanTip = CreateFrame("GameTooltip", "WeintCodexReforgeTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

local function TooltipSaysReforged(link)
    local marker = _G.REFORGED
    if not (marker and link) then return nil end

    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    if not pcall(scanTip.SetHyperlink, scanTip, link) then return nil end

    local lines = scanTip:NumLines() or 0
    if lines == 0 then return nil end   -- Tooltip noch nicht lesbar

    for index = 1, lines do
        local fs = _G["WeintCodexReforgeTipTextLeft" .. index]
        local text = fs and fs:GetText()
        if text and text:find(marker, 1, true) then return true end
    end
    return false
end

--------------------------------------------------
-- Werte des Grundgegenstands, hochgerechnet auf die Aufwertungsstufe
--------------------------------------------------

local function ItemFactor(link, itemId)
    local detailed = C_Item and C_Item.GetDetailedItemLevelInfo
                     or _G.GetDetailedItemLevelInfo
    if type(detailed) ~= "function" then return 1, nil, nil end

    local cur  = SafeNum(detailed, link)
    local base = SafeNum(detailed, itemId)
    if not (cur and base) or base <= 0 or cur <= base then
        return 1, cur, base
    end
    -- Budgetkurve von MoP: 1,15 je 15 Gegenstandsstufen.
    return math.pow(1.15, (cur - base) / 15), cur, base
end

local function BaseItemStats(itemId)
    if not (SM and SM.ItemStats and itemId) then return nil end
    return SM.ItemStats("item:" .. itemId)
end

--------------------------------------------------
-- Ein Durchgang ueber die angelegte Ausruestung
--------------------------------------------------

local function ScanSlot(slotDef)
    local link = GetInventoryItemLink("player", slotDef.id)
    if not link then return nil end

    local itemId = tonumber(link:match("|Hitem:(%d+)"))
    local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(link)
    local entry = {
        slot     = slotDef.id,
        slotName = slotDef.name,
        link     = link,
        itemId   = itemId,
        name     = name or link:match("|h%[(.-)%]|h") or "?",
        quality  = quality,
        icon     = texture,
        stats    = {},
        raw      = nil,
        locked   = RE.IsLocked(slotDef.id),
    }

    local base = itemId and BaseItemStats(itemId)
    if not (name and base) then
        -- Ohne Grunddaten wird nichts behauptet. Der Client liefert
        -- sie nach; die Seite fasst dann von selbst nach.
        entry.problem = "Gegenstandsdaten noch nicht geladen"
    else
        local factor, curIlvl, baseIlvl = ItemFactor(link, itemId)
        entry.raw      = base
        entry.factor   = factor
        entry.ilvl     = curIlvl
        entry.baseIlvl = baseIlvl

        local any = false
        for _, key in ipairs(R.STATS) do
            local value = base[key]
            if value and value > 0 then
                entry.stats[key] = math.floor(value * factor + 0.5)
                any = true
            end
        end
        if not any then
            -- Kein umschmiedbarer Wert (reine Ausdauer/Primaerteile,
            -- viele Schmuckstuecke). Keine Meldung: das ist kein
            -- Mangel, sondern der Gegenstand.
            entry.noSecondary = true
        end

        local pair, field = ReforgeFromLink(link)
        local says = TooltipSaysReforged(link)
        entry.linkField = field
        entry.tooltipReforged = says

        if says ~= nil and (says ~= (pair ~= nil)) then
            entry.warning = says
                and "Der Client meldet eine Umschmiedung, im Item-Link steht keine"
                or  "Im Item-Link steht eine Umschmiedung, der Client zeigt keine"
        end

        if pair then
            local srcKey = R.STATS[pair.src]
            entry.current = {
                src    = pair.src,
                dst    = pair.dst,
                id     = pair.id,
                amount = math.floor((entry.stats[srcKey] or 0) * R.COEFF),
            }
        end
    end

    return entry
end

local function ScanItems()
    local slots = WeintCodex.Charakter and WeintCodex.Charakter.EquipSlots
    if not slots then return {}, "Charaktermodul nicht geladen." end

    local items, pending = {}, false
    for _, slotDef in ipairs(slots) do
        local entry = ScanSlot(slotDef)
        if entry then
            if entry.problem == "Gegenstandsdaten noch nicht geladen" then
                pending = true
            end
            items[#items + 1] = entry
        end
    end
    return items, nil, pending
end

RE.ScanItems = ScanItems

--------------------------------------------------
-- Die billige Auskunft: was ist an DIESEM Slot gerade umgeschmiedet?
--
-- Liest nur den Item-Link, keinen Tooltip und keine Itemdaten. Waehrend
-- eines Umschmiede-Laufs wird sie nach jedem Gegenstand gebraucht, und ein
-- vollstaendiger Durchgang ueber alle sechzehn Slots je Antwort waere
-- sechzehnmal derselbe Tooltip-Scan fuer eine Ja/Nein-Frage.
--------------------------------------------------

function RE.CurrentPair(slotId)
    local link = GetInventoryItemLink("player", slotId)
    if not link then return nil end
    return (ReforgeFromLink(link))
end

--------------------------------------------------
-- Zulaessige Umschmiedungen eines Gegenstands
--
-- Quelle: ein Wert, den der GRUNDgegenstand traegt. Ziel: einer, den er
-- NICHT traegt. Das ist die Regel des Spiels, und sie kennt weder Steine
-- noch die bereits angelegte Umschmiedung — deshalb steht sie hier auf den
-- Werten des Grundgegenstands und nicht auf denen des angelegten Teils.
--------------------------------------------------

local function ItemOptions(item)
    local options = { { src = nil, dst = nil, amount = 0 } }
    if item.problem or item.noSecondary then return options end

    for src = 1, #R.STATS do
        local srcValue = item.stats[R.STATS[src]] or 0
        if srcValue > 0 then
            local amount = math.floor(srcValue * R.COEFF)
            if amount > 0 then
                for dst = 1, #R.STATS do
                    if dst ~= src and (item.stats[R.STATS[dst]] or 0) == 0 then
                        options[#options + 1] = { src = src, dst = dst, amount = amount }
                    end
                end
            end
        end
    end
    return options
end

RE.ItemOptions = ItemOptions

--------------------------------------------------
-- Laufende Nummer der Umschmiedung fuer C_Reforge.ReforgeItem
--
-- Der Umschmieder kennt keine Statnamen. Er nimmt die Position in SEINER
-- Liste der fuer diesen Gegenstand zulaessigen Umschmiedungen — und die
-- entsteht, indem die Paartabelle von oben nach unten durchgegangen und
-- jedes zulaessige Paar mitgezaehlt wird. Die erste zulaessige Umschmiedung
-- hat die Nummer 0, "nicht umgeschmiedet" die Nummer -1.
--
-- Ist das gewuenschte Paar fuer diesen Gegenstand gar nicht zulaessig, kommt
-- NICHTS zurueck. Die Zahl an dieser Stelle trotzdem herauszugeben, waere
-- die Nummer einer anderen Umschmiedung — der eine Fehler dieser Datei, der
-- Gold kostet und erst am Ergebnis auffaellt.
--------------------------------------------------

local UNFORGE_INDEX = -1
RE.UNFORGE_INDEX = UNFORGE_INDEX

function RE.ForgeIndex(item, srcIdx, dstIdx)
    if not (item and srcIdx and dstIdx) then return nil end
    if (item.stats[R.STATS[srcIdx]] or 0) == 0 then return nil end
    if (item.stats[R.STATS[dstIdx]] or 0) ~= 0 then return nil end

    local index = UNFORGE_INDEX
    for _, pair in ipairs(R.PAIRS) do
        if (item.stats[R.STATS[pair.src]] or 0) ~= 0
           and (item.stats[R.STATS[pair.dst]] or 0) == 0 then
            index = index + 1
        end
        if pair.src == srcIdx and pair.dst == dstIdx then
            return index
        end
    end
    return nil
end

--------------------------------------------------
-- Istwerte und Ziele
--------------------------------------------------

local ROLE_TYP = {
    MELEE  = "melee",
    TANK   = "melee",
    RANGED = "ranged",
    CASTER = "spell",
    HEALER = "spell",
}

local function LiveRating(statKey, typ)
    if statKey == "spirit" then
        local ok, _, value = pcall(UnitStat, "player", 5)
        return (ok and value) or 0
    end
    local idx = R.CR[statKey]
    if type(idx) == "table" then idx = idx[typ] or idx.melee end
    if not idx then return 0 end
    return SafeNum(_G.GetCombatRating, idx) or 0
end

--------------------------------------------------
-- Der Ausgangspunkt: Kampfwertung OHNE die angelegten Umschmiedungen
--------------------------------------------------

local function BuildContext(scan, items)
    local profile = scan and scan.profile
    local role    = profile and profile.role
    local defTyp  = ROLE_TYP[role or ""] or "melee"

    local typ = {}
    for _, key in ipairs(R.STATS) do typ[key] = defTyp end
    for _, cap in ipairs((scan and scan.caps) or {}) do
        if cap.typ then typ[cap.stat] = cap.typ end
    end
    for _, bp in ipairs((scan and scan.breakpoints) or {}) do
        if bp.typ then typ[bp.stat] = bp.typ end
    end

    local live = {}
    for _, key in ipairs(R.STATS) do
        live[key] = LiveRating(key, typ[key])
    end

    -- Angelegte Umschmiedungen herausrechnen: das ist der Stand, auf dem
    -- der Planer arbeitet, und "alles so lassen" ergibt daraus wieder
    -- genau den Istwert.
    local baseline = {}
    for key, value in pairs(live) do baseline[key] = value end
    for _, item in ipairs(items) do
        local cur = item.current
        if cur then
            local srcKey, dstKey = R.STATS[cur.src], R.STATS[cur.dst]
            baseline[srcKey] = (baseline[srcKey] or 0) + cur.amount
            baseline[dstKey] = (baseline[dstKey] or 0) - cur.amount
        end
    end

    --------------------------------------------------
    -- Ziele
    --
    -- `underRating` / `overRating` stehen bereits fertig an den Cap- und
    -- Schwellenzustaenden aus modules/charakter.lua und tragen dort alles,
    -- was der Client sonst noch beisteuert (Rassenbonus, Talente, die
    -- Willenskraft-Umwandlung, den Buff-Faktor der Tempo-Treppe). Das Ziel
    -- ist deshalb schlicht der Istwert plus der Abstand, den jene Rechnung
    -- ohnehin schon kennt — hier wird nichts davon nachgerechnet.
    --
    -- Kein Eintrag heisst "keine Grenze": der Wert zaehlt unbegrenzt. Das
    -- ist dieselbe Bedeutung wie beim Spielraum der Sockelplanung
    -- (`headroom == nil` heisst "keine Aussage").
    --------------------------------------------------
    local target = {}

    for _, cap in ipairs((scan and scan.caps) or {}) do
        if R.INDEX[cap.stat] then
            target[cap.stat] = {
                rating = math.max(0, (live[cap.stat] or 0)
                         + (cap.underRating or 0) - (cap.overRating or 0)),
                label  = cap.label or R.LABEL[cap.stat],
                kind   = "cap",
            }
        end
    end

    for _, bp in ipairs((scan and scan.breakpoints) or {}) do
        -- capPct == nil heisst ausdruecklich "kein Ziel" (kein Rang
        -- erreicht und keiner in Reichweite, oder der Spieler hat die
        -- Schwellen abgeschaltet). Dann bleibt der Wert ungedeckelt.
        if R.INDEX[bp.stat] and bp.capPct ~= nil then
            target[bp.stat] = {
                rating = math.max(0, (live[bp.stat] or 0)
                         + (bp.underRating or 0) - (bp.overRating or 0)),
                label  = (bp.target and bp.target.label) or bp.label or R.LABEL[bp.stat],
                kind   = "stufe",
            }
        end
    end

    -- Willenskraft zaehlt bei drei Casterspecs als Zaubertreffer. Das
    -- Trefferziel oben steht in reiner Trefferwertung und rechnet mit der
    -- Willenskraft, die GERADE angelegt ist. Verschiebt der Plan sie, muss
    -- das Trefferziel mitwandern — sonst verlangt die Seite Treffer, den
    -- die Willenskraft schon abdeckt. Doppelt gezaehlt wird dabei nichts:
    -- Willenskraft behaelt ihr eigenes Gewicht, sie senkt nur den Bedarf.
    local spiritFillsHit = false
    for _, cap in ipairs((scan and scan.caps) or {}) do
        if cap.spiritZaehlt then spiritFillsHit = true end
    end

    return {
        weights        = (profile and profile.statWeights) or {},
        target         = target,
        live           = live,
        baseline       = baseline,
        typ            = typ,
        spiritFillsHit = spiritFillsHit,
        profile        = profile,
        profileKey     = scan and scan.profileKey,
    }
end

RE.BuildContext = BuildContext

--------------------------------------------------
-- Bewertung einer Verteilung
--
-- Je Wert: Gewicht mal Wertung, aber nur bis zum Ziel. Was darueber liegt,
-- zaehlt nicht — dieselbe Regel wie GemValue in modules/charakter.lua, und
-- aus demselben Grund: ueber dem Trefferkap ist ein Punkt Treffer
-- nachweislich wertlos, hinter der letzten erreichbaren Tempo-Stufe bringt
-- er keinen Tick mehr.
--
-- Genau daraus faellt das gewuenschte Verhalten von selbst heraus, ohne
-- eine erfundene Cap-Praemie: unter dem Kap ist Treffer der
-- hoechstgewichtete Sekundaerwert und wird gefuellt, ueber dem Kap ist er
-- null wert und wird weggeschmiedet. Eine Praemie waere eine Zahl, die in
-- keinem Spec-Profil steht.
--------------------------------------------------

local function Score(ctx, total)
    local sum = 0
    local spiritShift = 0
    if ctx.spiritFillsHit then
        spiritShift = (total.spirit or 0) - (ctx.baseline.spirit or 0)
    end

    for _, key in ipairs(R.STATS) do
        local weight = ctx.weights[key] or 0
        if weight > 0 then
            local value = total[key] or 0
            local goal  = ctx.target[key]
            if goal then
                local limit = goal.rating
                if key == "hit" then limit = limit - spiritShift end
                if limit < 0 then limit = 0 end
                if value > limit then value = limit end
            end
            sum = sum + weight * value
        end
    end
    return sum
end

RE.Score = Score

--------------------------------------------------
-- Der Suchlauf
--
-- Eine vollstaendige Suche ueber 16 Slots mit je rund einem Dutzend
-- Moeglichkeiten waere ein Vielfaches dessen, was ein Frame hergibt. Der
-- Planer arbeitet stattdessen in zwei Runden, die zusammen genau die
-- Faelle abdecken, in denen sich eine einzelne Aenderung nicht lohnt:
--
--   * Einzeln: fuer jeden Slot die beste Wahl bei allen anderen fest.
--     Wiederholt, bis sich nichts mehr bewegt.
--   * Paarweise: fuer je zwei Slots alle Kombinationen. Das faengt den
--     Fall "erst beide zusammen bringen etwas" — der bei einem Kap der
--     Normalfall ist, weil ein einzelner Schritt darueber hinausschiesst.
--
-- Zwei Startaufstellungen, weil beide Runden nur bergauf gehen und damit
-- am naechsten Gipfel stehenbleiben: einmal von "gar nichts umgeschmiedet"
-- und einmal vom aktuellen Stand. Genommen wird die bessere.
--------------------------------------------------

local MAX_PASSES = 6

local function ApplyChoice(total, item, option, sign)
    if not (option and option.src) then return end
    local srcKey, dstKey = R.STATS[option.src], R.STATS[option.dst]
    total[srcKey] = (total[srcKey] or 0) - sign * option.amount
    total[dstKey] = (total[dstKey] or 0) + sign * option.amount
end

local function TotalsFor(ctx, items, choice)
    local total = {}
    for key, value in pairs(ctx.baseline) do total[key] = value end
    for i, item in ipairs(items) do
        ApplyChoice(total, item, item.options[choice[i]], 1)
    end
    return total
end

local function Search(ctx, items, choice)
    local total = TotalsFor(ctx, items, choice)
    local best  = Score(ctx, total)

    for round = 1, 3 do
        local moved = false

        -- Einzeln
        for pass = 1, MAX_PASSES do
            local changedThisPass = false
            for i, item in ipairs(items) do
                if not item.locked and #item.options > 1 then
                    ApplyChoice(total, item, item.options[choice[i]], -1)
                    local bestJ, bestScore = choice[i], nil
                    for j, option in ipairs(item.options) do
                        ApplyChoice(total, item, option, 1)
                        local score = Score(ctx, total)
                        if (not bestScore) or score > bestScore + 0.0001 then
                            bestScore, bestJ = score, j
                        end
                        ApplyChoice(total, item, option, -1)
                    end
                    ApplyChoice(total, item, item.options[bestJ], 1)
                    if bestJ ~= choice[i] then
                        choice[i] = bestJ
                        changedThisPass = true
                        moved = true
                    end
                    best = bestScore or best
                end
            end
            if not changedThisPass then break end
        end

        -- Paarweise
        local pairMoved = false
        for a = 1, #items - 1 do
            local itemA = items[a]
            if not itemA.locked and #itemA.options > 1 then
                for b = a + 1, #items do
                    local itemB = items[b]
                    if not itemB.locked and #itemB.options > 1 then
                        ApplyChoice(total, itemA, itemA.options[choice[a]], -1)
                        ApplyChoice(total, itemB, itemB.options[choice[b]], -1)
                        local bestA, bestB, bestScore = choice[a], choice[b], nil
                        for ja, optA in ipairs(itemA.options) do
                            ApplyChoice(total, itemA, optA, 1)
                            for jb, optB in ipairs(itemB.options) do
                                ApplyChoice(total, itemB, optB, 1)
                                local score = Score(ctx, total)
                                if (not bestScore) or score > bestScore + 0.0001 then
                                    bestScore, bestA, bestB = score, ja, jb
                                end
                                ApplyChoice(total, itemB, optB, -1)
                            end
                            ApplyChoice(total, itemA, optA, -1)
                        end
                        ApplyChoice(total, itemA, itemA.options[bestA], 1)
                        ApplyChoice(total, itemB, itemB.options[bestB], 1)
                        if bestA ~= choice[a] or bestB ~= choice[b] then
                            choice[a], choice[b] = bestA, bestB
                            pairMoved, moved = true, true
                        end
                        best = bestScore or best
                    end
                end
            end
        end

        -- Hat die paarweise Runde nichts mehr bewegt, findet die
        -- einzelne auch nichts mehr: beide stehen dann am selben Gipfel.
        if not (pairMoved and moved) then break end
    end

    return choice, best, total
end

--------------------------------------------------
-- Warum diese Umschmiedung?
--
-- Die Begruendung wird nicht dazuerfunden, sie wird an der Entscheidung
-- abgelesen, die eben gefallen ist: laeuft der Wert in ein Ziel, das noch
-- nicht erreicht ist? Kommt er aus einem, das ueberschritten war? Sonst
-- bleibt die Gewichtung, und dann stehen beide Gewichte in der Zeile —
-- ohne sie waere "hoeher gewichtet" eine Behauptung ohne Beleg.
--------------------------------------------------

local function ReasonFor(ctx, option, before, after)
    if not (option and option.src) then return "unverändert", "textDim" end

    local srcKey, dstKey = R.STATS[option.src], R.STATS[option.dst]
    local goalDst = ctx.target[dstKey]
    local goalSrc = ctx.target[srcKey]

    if goalDst and (before[dstKey] or 0) < goalDst.rating - 1 then
        return (goalDst.kind == "cap" and "füllt " or "erreicht ")
               .. (goalDst.label or R.LABEL[dstKey]), "green"
    end
    if goalSrc and (before[srcKey] or 0) > goalSrc.rating + 1 then
        return "über " .. (goalSrc.label or R.LABEL[srcKey]), "gold"
    end

    local ws = ctx.weights[srcKey] or 0
    local wd = ctx.weights[dstKey] or 0
    return string.format("%s (%d) ist höher gewichtet als %s (%d)",
        R.SHORT[dstKey], wd, R.SHORT[srcKey], ws), "textMuted"
end

--------------------------------------------------
-- Planen
--------------------------------------------------

local cache = nil

function RE.Invalidate()
    cache = nil
end

--------------------------------------------------
-- Wann muss neu gerechnet werden?
--
-- Die Kennung wird BILLIG gebildet — nur aus Item-Links, Sperren, Spec und
-- den acht Kampfwertungen. Kein Tooltip, kein Itemdaten-Abruf, kein
-- Ausruestungs-Scan. Das ist tragend, nicht sparsam: waehrend eines
-- Umschmiede-Laufs fragt das Fenster nach jedem Gegenstand nach, und ein
-- vollstaendiger Scan je Antwort waere sechzehn davon mitten im Klicken.
--
-- Der Item-Link traegt den Umschmiedewert selbst, also aendert sich die
-- Kennung nach jedem umgeschmiedeten Teil von allein.
--------------------------------------------------

local function Signature()
    local slots = WeintCodex.Charakter and WeintCodex.Charakter.EquipSlots
    if not slots then return nil end

    local profileKey = WeintCodex.Charakter.GetProfileKey
                       and WeintCodex.Charakter.GetProfileKey() or "?"
    local parts = { tostring(profileKey) }
    for _, slotDef in ipairs(slots) do
        parts[#parts + 1] = (GetInventoryItemLink("player", slotDef.id) or "-")
                            .. (RE.IsLocked(slotDef.id) and "!" or "")
    end
    for _, key in ipairs(R.STATS) do
        parts[#parts + 1] = math.floor(LiveRating(key, "melee"))
    end
    return table.concat(parts, "|")
end

function RE.GetPlan(force)
    if not RE.Enabled() then
        return { ok = false, problem = "Der Umschmiede-Planer ist ausgeschaltet." }
    end
    if not (WeintCodex.Charakter and WeintCodex.Charakter.Scan) then
        return { ok = false, problem = "Charaktermodul nicht geladen." }
    end

    local signature = Signature()
    if cache and signature and cache.signature == signature and not force then
        return cache.plan
    end

    local scan = WeintCodex.Charakter.Scan()
    local items, problem, pending = ScanItems()
    if problem then return { ok = false, problem = problem } end

    local ctx = BuildContext(scan, items)

    if not ctx.profile then
        local plan = { ok = false, pending = pending,
            problem = "Für diese Spezialisierung ist kein Profil hinterlegt —"
                .. " ohne Gewichte lässt sich nichts abwägen." }
        cache = { signature = signature, plan = plan }
        return plan
    end

    for _, item in ipairs(items) do
        item.options = ItemOptions(item)
    end

    -- Start 1: gar nichts umgeschmiedet.
    local blank = {}
    for i = 1, #items do blank[i] = 1 end
    -- Ein gesperrter Slot bleibt in JEDEM Startpunkt auf seinem Iststand,
    -- sonst hiesse "nicht anfassen" in Wahrheit "zuruecksetzen".
    for i, item in ipairs(items) do
        if item.locked and item.current then
            for j, option in ipairs(item.options) do
                if option.src == item.current.src and option.dst == item.current.dst then
                    blank[i] = j
                    break
                end
            end
        end
    end

    -- Start 2: der aktuelle Stand.
    local asIs = {}
    for i, item in ipairs(items) do
        asIs[i] = 1
        if item.current then
            for j, option in ipairs(item.options) do
                if option.src == item.current.src and option.dst == item.current.dst then
                    asIs[i] = j
                    break
                end
            end
        end
    end

    local beforeTotals = TotalsFor(ctx, items, asIs)
    local scoreBefore  = Score(ctx, beforeTotals)

    local choiceA, scoreA = Search(ctx, items, blank)
    local choiceB, scoreB = Search(ctx, items, asIs)

    local choice, scoreAfter = choiceA, scoreA
    if scoreB > scoreA then choice, scoreAfter = choiceB, scoreB end

    local afterTotals = TotalsFor(ctx, items, choice)

    local rows, changes, cost = {}, 0, 0
    for i, item in ipairs(items) do
        local option = item.options[choice[i]]
        local row = {
            slot        = item.slot,
            slotName    = item.slotName,
            name        = item.name,
            link        = item.link,
            icon        = item.icon,
            quality     = item.quality,
            stats       = item.stats,
            ilvl        = item.ilvl,
            baseIlvl    = item.baseIlvl,
            factor      = item.factor,
            locked      = item.locked,
            problem     = item.problem,
            warning     = item.warning,
            noSecondary = item.noSecondary,
            current     = item.current,
            options     = item.options,
        }

        if option and option.src then
            row.target = { src = option.src, dst = option.dst, amount = option.amount }
            row.reason, row.reasonTone = ReasonFor(ctx, option, beforeTotals, afterTotals)
        else
            row.target = nil
            row.reason, row.reasonTone = "keine Umschmiedung", "textDim"
        end

        local cur = item.current
        row.changed = not (
            (cur == nil and row.target == nil)
            or (cur and row.target and cur.src == row.target.src and cur.dst == row.target.dst)
        )

        if row.changed then
            changes = changes + 1
            -- Der Umschmieder verlangt den Verkaufspreis des Gegenstands.
            -- Meldet der Client keinen, wird nicht geraten: die Zeile
            -- traegt dann keinen Preis und die Summe sagt "mindestens".
            local price = item.link and select(11, GetItemInfo(item.link))
            if price and price > 0 then
                row.cost = price
                cost = cost + price
            else
                row.costUnknown = true
            end
        end

        rows[#rows + 1] = row
    end

    local plan = {
        ok          = true,
        pending     = pending,
        rows        = rows,
        ctx         = ctx,
        before      = beforeTotals,
        after       = afterTotals,
        scoreBefore = scoreBefore,
        scoreAfter  = scoreAfter,
        changes     = changes,
        cost        = cost,
        profileKey  = scan.profileKey,
        specDisplay = scan.specDisplay,
    }

    cache = { signature = signature, plan = plan }
    return plan
end

--------------------------------------------------
-- Was aendert der Plan an den Grenzen?
--
-- Fuer die Kopfzeile und den Inspektor: je Ziel der Istwert, der Zielwert
-- und der Stand danach. Eine Umschmiedeseite, die nicht sagt, ob das
-- Trefferkap danach steht, beantwortet die eine Frage nicht, wegen der man
-- sie aufmacht.
--------------------------------------------------

function RE.TargetSummary(plan)
    local out = {}
    if not (plan and plan.ok) then return out end
    for _, key in ipairs(R.STATS) do
        local goal = plan.ctx.target[key]
        if goal then
            out[#out + 1] = {
                stat   = key,
                label  = goal.label or R.LABEL[key],
                kind   = goal.kind,
                target = goal.rating,
                before = plan.before[key] or 0,
                after  = plan.after[key] or 0,
            }
        end
    end
    return out
end
