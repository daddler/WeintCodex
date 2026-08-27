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
-- DER MASSSTAB IST REFORGELITE.
--
-- Das ist die ausdrueckliche Vorgabe fuer diese Datei: ReforgeLite liefert
-- seit Cataclysm verlaessliche Ergebnisse, und ein zweites Werkzeug, das
-- "ungefaehr auch" umschmiedet, ist kein Fortschritt, sondern ein zweiter
-- Ratgeber, dem man nicht trauen kann. Drei Dinge folgen daraus, und keines
-- davon ist Geschmack:
--
--   * Der SUCHLAUF ist derselbe. Eine gierige Naeherung findet an einem Kap
--     nicht das Optimum: dort lohnt sich haeufig erst die zweite Aenderung,
--     und wer Slot fuer Slot das jeweils Beste nimmt, bleibt davor stehen.
--     Gerechnet wird deshalb wie dort eine vollstaendige dynamische
--     Programmierung ueber die beiden Grenzwerte (siehe unten).
--   * Die ITEMWERTE sind exakt, nicht geschaetzt. Ein Teil auf 4/4 traegt
--     gut 16 % mehr Wertung; wer das ueberschlaegt, liegt bei jedem Betrag
--     um denselben Prozentsatz daneben. data/reforge_scaling.lua traegt
--     dieselben Spieldaten, aus denen ReforgeLite rechnet.
--   * Die UMWANDLUNGEN sind vollstaendig. Willenskraft als Zaubertreffer,
--     Waffenkunde als Zaubertreffer, die Sonderfaelle des Nebelwirkers und
--     der Menschen-Willenskraft: das sind Spielregeln, keine Feinheiten.
--     Wer sie weglaesst, empfiehlt Casterspecs verlaesslich das Falsche.
--
--
-- ES GIBT TROTZDEM NUR EINE RECHNUNG FUER "WIEVIEL BRINGT DIESER WERT NOCH".
--
-- Caps (Treffer, Waffenkunde) und die Tempo-Treppe stehen bereits in
-- modules/charakter.lua, sie speisen dort den Spielraum der Sockelplanung,
-- und `/wc tempo` druckt ihre Herleitung aus. Diese Datei rechnet sie
-- deshalb NICHT nach, sondern ruft `WeintCodex.Charakter.Scan()` und liest
-- `scan.caps`, `scan.breakpoints` und `scan.profile.statWeights`. Genau
-- hier weicht der Planer von ReforgeLite ab, und zwar mit Absicht: dort
-- traegt der Nutzer Gewichte und Kapgrenzen von Hand ein, hier stehen sie
-- schon im Spec-Profil und werden bereits von zwei anderen Seiten benutzt.
-- Zwei Rechnungen nebeneinander waeren genau die Doppelung, an der die
-- Sockelbewertung ueber fuenf Releases gescheitert ist (siehe PlanItem
-- dort).
--
--
-- DIE SUMMEN KOMMEN VOM CHARAKTERBOGEN, DIE EINZELBETRAEGE VOM GEGENSTAND.
--
-- Was ein Spieler an Trefferwertung HAT, weiss der Client (GetCombatRating);
-- was ein einzelner Gegenstand dazu beitraegt, steht in seinen Itemdaten.
-- Der Ausgangspunkt ist deshalb die Kampfwertung des Clients, aus der die
-- aktuell angelegten Umschmiedungen herausgerechnet werden; bewegt wird
-- darauf mit den Betraegen aus den Itemdaten. Damit stimmt die Summe immer,
-- und "unveraendert lassen" ergibt exakt wieder den Istwert.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.ReforgeEngine = {}

local RE = WeintCodex.ReforgeEngine
local R  = WeintCodex_Reforge
local S  = WeintCodex_ReforgeScaling
local SM = WeintCodex.StatMatch

local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min

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
    return floor((v or 0) + 0.5)
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

local function LinkParts(link)
    local data = link and link:match("|Hitem:([^|]+)")
    if not data then return nil end
    local parts, i = {}, 0
    for piece in (data .. ":"):gmatch("([^:]*):") do
        i = i + 1
        parts[i] = tonumber(piece)
    end
    return parts
end

local function ReforgeFromLink(link)
    local parts = LinkParts(link)
    if not parts then return nil, nil end
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
-- ITEMWERTE JE AUFWERTUNGSSTUFE
--
-- Gelesen wird der Item-Link, so wie es ReforgeLite tut: GetItemStats
-- meldet daraus die Werte des Gegenstands SELBST, ohne Stein, ohne
-- Verzauberung und ohne die angelegte Umschmiedung — aber auch ohne die
-- Aufwertungsstufe, denn die steckt nicht in der Vorlage.
--
-- Hochgerechnet wird deshalb aus den Spieldaten in
-- data/reforge_scaling.lua: Budget der Gegenstandsstufe mal Anteil der
-- Vorlage. Nur wenn der Gegenstand dort fehlt (etwas Neues, etwas
-- Ungewoehnliches), bleibt die Budgetkurve 1,15 je 15 Stufen als
-- Naeherung — und die Zeile sagt in der Diagnose, welcher der beiden Wege
-- benutzt wurde. Eine Naeherung, die sich nicht von einer Messung
-- unterscheiden laesst, ist das Problem, nicht die Naeherung selbst.
--------------------------------------------------

local UPGRADE_MIN_ILVL = 458    -- darunter gab es in MoP keine Aufwertung

local function DetailedIlvl(what)
    local fn = (C_Item and C_Item.GetDetailedItemLevelInfo)
               or _G.GetDetailedItemLevelInfo
    return SafeNum(fn, what)
end

local function UpgradeLevel(link, itemId, quality)
    local cur  = DetailedIlvl(link)
    local base = DetailedIlvl(itemId)
    if not (cur and base) then return 0, cur, base end
    if quality and quality < 3 then return 0, cur, base end
    if cur < UPGRADE_MIN_ILVL then return 0, cur, base end
    if cur <= base then return 0, cur, base end
    return (cur - base) / 4, cur, base
end

-- Rueckgabe: Werte, Herkunft ("tabelle" | "kurve" | "grund")
local function ScaleToUpgrade(stats, itemId, upgrade, baseIlvl)
    if not (upgrade and upgrade > 0 and baseIlvl) then return stats, "grund" end

    local iLvl = baseIlvl + upgrade * 4
    local budget, ref
    local entry = S and S.ItemUpgradeStats and S.ItemUpgradeStats[itemId]
    if entry and S.RandPropPoints[iLvl] then
        budget = S.RandPropPoints[iLvl][entry[1]]
        ref    = S.StatsRef[entry[2] + 1]
    end

    local source = (budget and ref) and "tabelle" or "kurve"
    local curve  = math.pow(1.15, (iLvl - baseIlvl) / 15)

    for sid, key in ipairs(R.STATS) do
        if stats[key] then
            if budget and ref and ref[sid] then
                stats[key] = floor(ref[sid][1] * budget * 0.0001 - ref[sid][2] * 160 + 0.5)
            else
                stats[key] = floor(stats[key] * curve)
            end
        end
    end
    return stats, source
end

local function ReforgeStatsOf(link)
    if not (SM and SM.ItemStats and link) then return nil end
    local raw = SM.ItemStats(link)
    if not raw then return nil end
    local out = {}
    for _, key in ipairs(R.STATS) do
        local value = raw[key]
        if value and value > 0 then out[key] = value end
    end
    return out
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
        locked   = RE.IsLocked(slotDef.id),
    }

    local fromLink = itemId and ReforgeStatsOf(link)
    if not (name and fromLink) then
        -- Ohne Grunddaten wird nichts behauptet. Der Client liefert sie
        -- nach; die Seite fasst dann von selbst nach.
        entry.problem = "Gegenstandsdaten noch nicht geladen"
        return entry
    end

    -- Gegenprobe: der blanke Grundgegenstand kann weder Stein noch
    -- Verzauberung tragen. Weichen die beiden Statmengen voneinander ab,
    -- liefert GetItemStats am Link mehr als die Vorlage — und dann waere
    -- die Frage, welche Umschmiedung ueberhaupt zulaessig ist, falsch
    -- beantwortet. Gerechnet wird trotzdem weiter (mit dem Link, wie
    -- ReforgeLite), aber die Diagnose weist es aus.
    local fromBare = ReforgeStatsOf("item:" .. itemId)
    entry.bare = fromBare
    if fromBare then
        for _, key in ipairs(R.STATS) do
            if (fromLink[key] ~= nil) ~= (fromBare[key] ~= nil) then
                entry.statSetMismatch = true
            end
        end
    end

    local upgrade, curIlvl, baseIlvl = UpgradeLevel(link, itemId, quality)
    entry.upgrade  = upgrade
    entry.ilvl     = curIlvl
    entry.baseIlvl = baseIlvl
    entry.stats, entry.statSource = ScaleToUpgrade(fromLink, itemId, upgrade, baseIlvl)

    local any = false
    for _, key in ipairs(R.STATS) do
        if entry.stats[key] and entry.stats[key] > 0 then any = true end
    end
    -- Kein umschmiedbarer Wert (reine Ausdauer-/Primaerteile, viele
    -- Schmuckstuecke). Keine Meldung: das ist kein Mangel, sondern der
    -- Gegenstand.
    entry.noSecondary = not any

    local pair, field = ReforgeFromLink(link)
    local says = TooltipSaysReforged(link)
    entry.linkField       = field
    entry.tooltipReforged = says

    if says ~= nil and (says ~= (pair ~= nil)) then
        entry.warning = says
            and "Der Client meldet eine Umschmiedung, im Item-Link steht keine"
            or  "Im Item-Link steht eine Umschmiedung, der Client zeigt keine"
    end

    if pair then
        entry.current = {
            src = pair.src,
            dst = pair.dst,
            id  = pair.id,
            raw = floor((entry.stats[R.STATS[pair.src]] or 0) * R.COEFF),
        }
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
            if entry.problem then pending = true end
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
-- UMWANDLUNGEN: WELCHER WERT SPEIST WELCHEN ANDEREN?
--
-- Spielregeln von MoP, keine Feinheiten. Willenskraft zaehlt bei drei
-- Specs als Zaubertreffer; bei Zauberklassen zaehlt Waffenkunde ebenfalls
-- als Zaubertreffer; der Nebelwirker bekommt aus Willenskraft je zur
-- Haelfte Treffer und Waffenkunde und aus Tempo die Haelfte obendrauf; und
-- Menschen tragen 3 % mehr Willenskraft.
--
-- Wer sie weglaesst, empfiehlt jedem Zauberer verlaesslich das Falsche:
-- ohne die Waffenkunde-Umwandlung waere Waffenkunde fuer einen Magier ein
-- toter Wert, den der Planer wegschmiedet — obwohl er direkt in sein
-- Trefferkap laeuft.
--
-- Die Tabelle ist die aus ReforgeLite, weil sie dort gegen den laufenden
-- Client gestellt ist. Uebersetzt sind nur die Statnamen; die Spec-Nummern
-- kommen wie dort aus dem Client (GetSpecialization), nicht aus unseren
-- Profilschluesseln — die Umwandlung ist eine Eigenschaft der Spec im
-- Spiel und nicht unserer Datenpflege.
--------------------------------------------------

local CASTER_CONV = { expertise = { hit = 1 } }
local HYBRID_CONV = { spirit = { hit = 1 }, expertise = { hit = 1 } }

local STAT_CONVERSIONS = {
    DRUID = {
        specs = {
            [1] = HYBRID_CONV,      -- Gleichgewicht
            [4] = CASTER_CONV,      -- Wiederherstellung
        },
    },
    MAGE    = { base = CASTER_CONV },
    MONK    = {
        specs = {
            [2] = {                 -- Nebelwirker
                spirit = { hit = 0.5, expertise = 0.5 },
                haste  = { haste = 0.5 },
            },
        },
    },
    PALADIN = { specs = { [1] = CASTER_CONV } },      -- Heilig
    PRIEST  = {
        base  = CASTER_CONV,
        specs = { [3] = HYBRID_CONV },                -- Schatten
    },
    SHAMAN  = {
        specs = {
            [1] = HYBRID_CONV,                        -- Elementar
            [3] = CASTER_CONV,                        -- Wiederherstellung
        },
    },
    WARLOCK = { base = CASTER_CONV },
}

local function CopyConv(into, from)
    for src, map in pairs(from) do
        into[src] = into[src] or {}
        for dst, factor in pairs(map) do into[src][dst] = factor end
    end
end

local function BuildConversions()
    local conv = {}
    local class = select(2, UnitClass("player"))
    local info  = STAT_CONVERSIONS[class or ""]
    if info then
        if info.base then CopyConv(conv, info.base) end
        local spec = SafeNum(_G.GetSpecialization)
                     or (C_SpecializationInfo and SafeNum(C_SpecializationInfo.GetSpecialization))
        if spec and info.specs and info.specs[spec] then
            CopyConv(conv, info.specs[spec])
        end
    end
    if select(2, UnitRace("player")) == "Human" then
        -- Menschlicher Geist: 3 % mehr Willenskraft. Additiv auf den
        -- bewegten Betrag, deshalb ein eigener Eintrag neben einer
        -- moeglicherweise schon vorhandenen Willenskraft-Umwandlung.
        conv.spirit = conv.spirit or {}
        conv.spirit.spirit = (conv.spirit.spirit or 0) + 0.03
    end
    return conv
end

--------------------------------------------------
-- Verstaerkungs-Schmuck (Siegfrieds Donner): erhoeht Tempo, Meisterschaft
-- und Willenskraft prozentual. Der Charakterbogen zeigt den erhoehten
-- Wert; ein umgeschmiedeter Punkt in diese Werte ist deshalb mehr wert als
-- einer.
--------------------------------------------------

local function StatMultipliers(items)
    local mult = {}
    if not (S and S.Amplification) then return mult end
    for _, item in ipairs(items) do
        if item.itemId and S.Amplification[item.itemId] and item.ilvl then
            local points = S.RandPropPoints[item.ilvl] and S.RandPropPoints[item.ilvl][2]
            if points then
                local factor = 1 + 0.01 * Round(points / 420)
                for _, key in ipairs({ "haste", "mastery", "spirit" }) do
                    mult[key] = (mult[key] or 1) * factor
                end
            end
        end
    end
    return mult
end

--------------------------------------------------
-- Zulaessige Umschmiedungen eines Gegenstands
--
-- Quelle: ein Wert, den der Gegenstand traegt. Ziel: einer, den er NICHT
-- traegt. Das ist die Regel des Spiels, und sie kennt weder Steine noch
-- die bereits angelegte Umschmiedung.
--
-- Jede Moeglichkeit traegt gleich ihren vollstaendigen Vektor mit: was
-- sich an allen acht Werten aendert, Verstaerkung und Umwandlungen
-- eingerechnet. Der Suchlauf rechnet damit nur noch Summen.
--------------------------------------------------

local function DeltaOf(item, src, dst, mult, conv)
    local delta = {}
    if not src then return delta end

    local srcKey, dstKey = R.STATS[src], R.STATS[dst]
    local raw = floor((item.stats[srcKey] or 0) * R.COEFF)

    delta[srcKey] = -Round(raw * (mult[srcKey] or 1))
    delta[dstKey] =  Round(raw * (mult[dstKey] or 1))

    -- Umwandlungen auf die bewegten Betraege. Auf einer Kopie, damit eine
    -- Umwandlung nicht die naechste speist (Willenskraft -> Treffer darf
    -- nicht ueber Treffer -> irgendwas weiterlaufen).
    local moved = { [srcKey] = delta[srcKey], [dstKey] = delta[dstKey] }
    for from, map in pairs(conv) do
        local amount = moved[from]
        if amount and amount ~= 0 then
            for to, factor in pairs(map) do
                delta[to] = (delta[to] or 0) + Round(amount * factor)
            end
        end
    end
    return delta
end

local function ItemOptions(item, mult, conv)
    local options = { { src = nil, dst = nil, raw = 0, delta = {} } }
    if item.problem or item.noSecondary or item.locked then
        -- Ein gesperrter Slot behaelt in JEDEM Startpunkt seinen Iststand,
        -- sonst hiesse "nicht anfassen" in Wahrheit "zuruecksetzen".
        if item.locked and item.current and not item.problem then
            local cur = item.current
            options[1] = {
                src = cur.src, dst = cur.dst,
                raw = cur.raw,
                delta = DeltaOf(item, cur.src, cur.dst, mult, conv),
            }
        end
        return options
    end

    for src = 1, #R.STATS do
        if (item.stats[R.STATS[src]] or 0) > 0 then
            local raw = floor((item.stats[R.STATS[src]] or 0) * R.COEFF)
            if raw > 0 then
                for dst = 1, #R.STATS do
                    if dst ~= src and (item.stats[R.STATS[dst]] or 0) == 0 then
                        options[#options + 1] = {
                            src = src, dst = dst, raw = raw,
                            delta = DeltaOf(item, src, dst, mult, conv),
                        }
                    end
                end
            end
        end
    end
    return options
end

RE.ItemOptions = ItemOptions

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

RE.LiveRating = LiveRating

local function BuildContext(scan, items)
    local profile = scan and scan.profile
    local defTyp  = ROLE_TYP[(profile and profile.role) or ""] or "melee"

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

    local mult = StatMultipliers(items)
    local conv = BuildConversions()

    -- Angelegte Umschmiedungen herausrechnen: das ist der Stand, auf dem
    -- der Planer arbeitet, und "alles so lassen" ergibt daraus wieder
    -- genau den Istwert.
    local baseline = {}
    for key, value in pairs(live) do baseline[key] = value end
    for _, item in ipairs(items) do
        if item.current then
            local delta = DeltaOf(item, item.current.src, item.current.dst, mult, conv)
            item.current.delta  = delta
            item.current.amount = math.abs(delta[R.STATS[item.current.src]] or 0)
            for key, value in pairs(delta) do
                baseline[key] = (baseline[key] or 0) - value
            end
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
    --
    -- `require` trennt die beiden Sorten Ziel: ein Kap MUSS erreicht
    -- werden, wenn es irgend geht (unter dem Trefferkap gehen Schlaege
    -- daneben, das ist keine Abwaegung). Eine Tempo-Stufe ist dagegen ein
    -- Angebot: sie lohnt sich, aber nicht um jeden Preis.
    --------------------------------------------------
    local target, order = {}, {}

    for _, cap in ipairs((scan and scan.caps) or {}) do
        if R.INDEX[cap.stat] and not target[cap.stat] then
            target[cap.stat] = {
                rating  = max(0, (live[cap.stat] or 0)
                          + (cap.underRating or 0) - (cap.overRating or 0)),
                label   = cap.label or R.LABEL[cap.stat],
                kind    = "cap",
                require = true,
            }
            order[#order + 1] = cap.stat
        end
    end

    for _, bp in ipairs((scan and scan.breakpoints) or {}) do
        if R.INDEX[bp.stat] and bp.capPct ~= nil and not target[bp.stat] then
            target[bp.stat] = {
                rating  = max(0, (live[bp.stat] or 0)
                          + (bp.underRating or 0) - (bp.overRating or 0)),
                label   = (bp.target and bp.target.label) or bp.label or R.LABEL[bp.stat],
                kind    = "stufe",
                require = false,
            }
            order[#order + 1] = bp.stat
        end
    end

    return {
        weights     = (profile and profile.statWeights) or {},
        target      = target,
        targetOrder = order,
        live        = live,
        baseline    = baseline,
        typ         = typ,
        mult        = mult,
        conv        = conv,
        profile     = profile,
        profileKey  = scan and scan.profileKey,
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
-- null wert und wird weggeschmiedet.
--
-- Der winzige Abzug fuer Wertung ueber einem Ziel ist kein zweites
-- Gewicht, sondern ein Gleichstandsbrecher: zwei Loesungen mit demselben
-- Nutzen sind nicht gleich gut, wenn eine davon 400 Punkte ins Leere legt.
--------------------------------------------------

local OVERSHOOT_PENALTY = 0.001

local function Score(ctx, total)
    local sum = 0
    for _, key in ipairs(R.STATS) do
        local value  = total[key] or 0
        local weight = ctx.weights[key] or 0
        local goal   = ctx.target[key]
        if goal then
            local limit = goal.rating
            if value > limit then
                sum = sum + weight * limit - OVERSHOOT_PENALTY * (value - limit)
            else
                sum = sum + weight * value
            end
        elseif weight > 0 then
            sum = sum + weight * value
        end
    end
    return sum
end

RE.Score = Score

-- Erfuellt eine Verteilung die Pflicht-Kaps? Rueckgabe: Zahl der
-- verfehlten Kaps (0 = alles erreicht). Kleiner ist besser, und das
-- schlaegt jede Punktzahl — unter dem Trefferkap gehen Schlaege daneben.
local function CapMisses(ctx, total)
    local misses = 0
    for key, goal in pairs(ctx.target) do
        if goal.require and (total[key] or 0) < goal.rating - 1 then
            misses = misses + 1
        end
    end
    return misses
end

local function Better(ctx, totalA, scoreA, totalB, scoreB)
    local missA, missB = CapMisses(ctx, totalA), CapMisses(ctx, totalB)
    if missA ~= missB then return missA < missB end
    return scoreA > scoreB
end

--------------------------------------------------
-- DER SUCHLAUF
--
-- Zwei Stufen, und die erste ist der Grund, warum dieser Planer sich an
-- ReforgeLite messen lassen kann:
--
--   1. VOLLSTAENDIGE DYNAMISCHE PROGRAMMIERUNG ueber die beiden Werte, an
--      denen eine Grenze haengt. Alles andere ist an jedem Gegenstand
--      linear und faellt deshalb in eine einzige Punktzahl zusammen; nur
--      die beiden Grenzwerte sind es nicht, weil dort Wertung ueber dem
--      Ziel nichts mehr bringt. Genau diese zwei Achsen bilden den
--      Zustandsraum. Eine gierige Suche findet hier nachweislich nicht das
--      Optimum: am Kap lohnt sich haeufig erst die zweite Aenderung, und
--      wer Slot fuer Slot das jeweils Beste nimmt, bleibt davor stehen.
--
--      Zwei Achsen reichen: in data/spec_profiles.lua hat keine Spec mehr
--      als zwei Grenzen, und keine der sieben Specs mit Tempo-Treppe hat
--      mehr als ein Kap daneben. Kaeme je eine dritte dazu, bekaeme sie
--      ein lineares Gewicht und die Diagnose sagt es.
--
--   2. NACHPOLIEREN. Der Zustandsraum ist gerastert (sonst waere er zu
--      gross), das Ergebnis also auf ein paar Punkte genau. Die zweite
--      Stufe rechnet mit den EXAKTEN Summen weiter: erst jeder Slot
--      einzeln, dann je zwei zusammen, bis sich nichts mehr bewegt. Sie
--      kann das Ergebnis nur verbessern, und sie raeumt die Rasterreste
--      weg.
--
-- Gerechnet wird in einer Koroutine, die regelmaessig anhaelt. Ein
-- vollstaendiger Durchlauf ueber sechzehn Slots ist mehr, als ein
-- einzelnes Bild hergibt, und ein Addon, das den Client fuer eine Sekunde
-- stehenlaesst, ist genau das, was man abschaltet.
--------------------------------------------------

-- Angehalten wird nach ZEIT, nicht nach Schritten. Eine feste Schrittzahl
-- ist auf einem schnellen Rechner Verschwendung und auf einem langsamen ein
-- Ruckler — und sie wuerde bei jeder Aenderung an der Rechnung wieder
-- danebenliegen. Acht Millisekunden sind gut die Haelfte eines Bildes bei
-- 60 Hz; darunter faellt der Lauf nicht auf, darueber schon.
local BUDGET_MS   = 8
local CHECK_EVERY = 512   -- die Uhr nicht bei jedem einzelnen Schritt lesen
local FALLBACK_STEPS = 4000

local steps, budgetStart = 0, 0

local function Now()
    if _G.debugprofilestop then
        local ok, value = pcall(_G.debugprofilestop)
        if ok and type(value) == "number" then return value end
    end
    return nil
end

local function Breathe()
    steps = steps + 1
    if steps < CHECK_EVERY then return end
    steps = 0
    local now = Now()
    if now then
        if now - budgetStart >= BUDGET_MS then
            coroutine.yield()
            budgetStart = Now() or 0
        end
    else
        -- Kein Zeitgeber: dann eben nach Schritten, damit ueberhaupt
        -- angehalten wird.
        FALLBACK_STEPS = FALLBACK_STEPS - CHECK_EVERY
        if FALLBACK_STEPS <= 0 then
            FALLBACK_STEPS = 4000
            coroutine.yield()
        end
    end
end

local function TotalsFor(ctx, items, choice)
    local total = {}
    for key, value in pairs(ctx.baseline) do total[key] = value end
    for i, item in ipairs(items) do
        local option = item.options[choice[i]]
        if option then
            for key, value in pairs(option.delta) do
                total[key] = (total[key] or 0) + value
            end
        end
    end
    return total
end

--------------------------------------------------
-- Stufe 1: die dynamische Programmierung
--------------------------------------------------

local function RunDP(ctx, items)
    local dims = {}
    for _, key in ipairs(ctx.targetOrder) do
        if #dims < 2 then dims[#dims + 1] = key end
    end
    if #dims == 0 then return nil, dims end

    -- Rasterweite. Wie in ReforgeLite an der Gesamtmenge bewegbarer
    -- Wertung ausgerichtet, damit der Zustandsraum unabhaengig von der
    -- Ausruestungsstufe etwa gleich gross bleibt.
    local statsSum = 0
    for _, item in ipairs(items) do
        for _, key in ipairs(R.STATS) do
            statsSum = statsSum + (item.stats[key] or 0)
        end
    end
    local cheat = max(1, ceil(statsSum / 1000))

    -- Obergrenze je Achse: ueber dem Ziel ist jeder weitere Punkt gleich
    -- viel wert (naemlich nichts), also fallen alle diese Zustaende in
    -- einen zusammen. Ohne diese Klammer waere der Zustandsraum um ein
    -- Vielfaches groesser, ohne eine einzige zusaetzliche Entscheidung zu
    -- ermoeglichen.
    local capQ = {}
    for d = 1, #dims do
        capQ[d] = floor((ctx.target[dims[d]].rating / cheat) + 0.5) + 1
    end

    -- Gibt es nur eine Achse, ist die zweite dauerhaft 0 — dann kostet der
    -- Zustandsraum auch nur eine Dimension.
    local function Quant(d, value)
        if not capQ[d] then return 0 end
        local q = floor(value / cheat + 0.5)
        if q < 0 then q = 0 end
        if q > capQ[d] then q = capQ[d] end
        return q
    end

    local STRIDE = capQ[1] + 1

    -- Moeglichkeiten je Gegenstand auf die Achsen eindampfen: zwei
    -- Umschmiedungen, die an beiden Grenzwerten dasselbe bewirken,
    -- unterscheiden sich nur noch in der Punktzahl — davon ueberlebt die
    -- bessere. Aus einem Dutzend werden so meist eine Handvoll.
    local perItem = {}
    for i, item in ipairs(items) do
        local best = {}
        for j, option in ipairs(item.options) do
            local d1 = option.delta[dims[1]] or 0
            local d2 = dims[2] and (option.delta[dims[2]] or 0) or 0
            local score = 0
            for _, key in ipairs(R.STATS) do
                if key ~= dims[1] and key ~= dims[2] then
                    score = score + (ctx.weights[key] or 0) * (option.delta[key] or 0)
                end
            end
            local key = d1 .. "/" .. d2
            local prev = best[key]
            if not prev or score > prev.score then
                best[key] = { index = j, d1 = d1, d2 = d2, score = score }
            end
            Breathe()
        end
        local list = {}
        for _, entry in pairs(best) do list[#list + 1] = entry end
        perItem[i] = list
    end

    -- Startzustand: alles unumgeschmiedet.
    local init1 = ctx.baseline[dims[1]] or 0
    local init2 = dims[2] and (ctx.baseline[dims[2]] or 0) or 0

    local layers = {}
    local scores = { [Quant(1, init1) + Quant(2, init2) * STRIDE] = 0 }
    local ex1    = { [Quant(1, init1) + Quant(2, init2) * STRIDE] = init1 }
    local ex2    = { [Quant(1, init1) + Quant(2, init2) * STRIDE] = init2 }

    for i = 1, #items do
        local nextScores, nextEx1, nextEx2 = {}, {}, {}
        local from, took = {}, {}
        local list = perItem[i]

        for key, score in pairs(scores) do
            local e1, e2 = ex1[key], ex2[key]
            for _, option in ipairs(list) do
                local n1 = e1 + option.d1
                local n2 = e2 + option.d2
                local nk = Quant(1, n1) + Quant(2, n2) * STRIDE
                local ns = score + option.score
                local old = nextScores[nk]
                -- Gleichstand: die Loesung mit weniger Ueberschuss gewinnt.
                if old == nil or ns > old
                   or (ns == old and (n1 + n2) < (nextEx1[nk] + nextEx2[nk])) then
                    nextScores[nk] = ns
                    nextEx1[nk]    = n1
                    nextEx2[nk]    = n2
                    from[nk]       = key
                    took[nk]       = option.index
                end
                Breathe()
            end
        end

        layers[i] = { from = from, took = took }
        scores, ex1, ex2 = nextScores, nextEx1, nextEx2
    end

    -- Bestes Endergebnis: erst die Pflicht-Kaps, dann die Punktzahl.
    local bestKey, bestScore, bestMiss
    local req1 = ctx.target[dims[1]].require and ctx.target[dims[1]].rating or nil
    local req2 = dims[2] and ctx.target[dims[2]].require and ctx.target[dims[2]].rating or nil

    for key, score in pairs(scores) do
        local miss = 0
        if req1 and ex1[key] < req1 - 1 then miss = miss + 1 end
        if req2 and ex2[key] < req2 - 1 then miss = miss + 1 end

        -- Der Wert an einer Achse zaehlt nur bis zum Ziel; das steckt im
        -- Zustand, nicht in der laufenden Punktzahl, und kommt deshalb
        -- hier dazu.
        local full = score
        full = full + (ctx.weights[dims[1]] or 0) * min(ex1[key], ctx.target[dims[1]].rating)
        if dims[2] then
            full = full + (ctx.weights[dims[2]] or 0) * min(ex2[key], ctx.target[dims[2]].rating)
        end

        if bestKey == nil or miss < bestMiss or (miss == bestMiss and full > bestScore) then
            bestKey, bestScore, bestMiss = key, full, miss
        end
        Breathe()
    end

    if not bestKey then return nil, dims end

    local choice = {}
    local key = bestKey
    for i = #items, 1, -1 do
        choice[i] = layers[i].took[key] or 1
        key = layers[i].from[key]
    end
    return choice, dims
end

--------------------------------------------------
-- Stufe 2: nachpolieren mit den exakten Summen
--------------------------------------------------

local MAX_PASSES = 6

local function ApplyDelta(total, delta, sign)
    for key, value in pairs(delta) do
        total[key] = (total[key] or 0) + sign * value
    end
end

local function Polish(ctx, items, choice)
    local total = TotalsFor(ctx, items, choice)

    for round = 1, 3 do
        local pairMoved = false

        for _ = 1, MAX_PASSES do
            local moved = false
            for i, item in ipairs(items) do
                if #item.options > 1 then
                    ApplyDelta(total, item.options[choice[i]].delta, -1)
                    local bestJ, bestScore, bestMiss = nil, nil, nil
                    for j, option in ipairs(item.options) do
                        ApplyDelta(total, option.delta, 1)
                        local score = Score(ctx, total)
                        local miss  = CapMisses(ctx, total)
                        if bestJ == nil or miss < bestMiss
                           or (miss == bestMiss and score > bestScore + 1e-9) then
                            bestJ, bestScore, bestMiss = j, score, miss
                        end
                        ApplyDelta(total, option.delta, -1)
                        Breathe()
                    end
                    ApplyDelta(total, item.options[bestJ].delta, 1)
                    if bestJ ~= choice[i] then
                        choice[i] = bestJ
                        moved = true
                    end
                end
            end
            if not moved then break end
        end

        -- Paarweise: faengt den Fall, in dem sich erst zwei Aenderungen
        -- zusammen lohnen. An einem Kap ist das der Normalfall, weil ein
        -- einzelner Schritt darueber hinausschiesst.
        for a = 1, #items - 1 do
            local itemA = items[a]
            if #itemA.options > 1 then
                for b = a + 1, #items do
                    local itemB = items[b]
                    if #itemB.options > 1 then
                        ApplyDelta(total, itemA.options[choice[a]].delta, -1)
                        ApplyDelta(total, itemB.options[choice[b]].delta, -1)
                        local bestA, bestB, bestScore, bestMiss
                        for ja, optA in ipairs(itemA.options) do
                            ApplyDelta(total, optA.delta, 1)
                            for jb, optB in ipairs(itemB.options) do
                                ApplyDelta(total, optB.delta, 1)
                                local score = Score(ctx, total)
                                local miss  = CapMisses(ctx, total)
                                if bestA == nil or miss < bestMiss
                                   or (miss == bestMiss and score > bestScore + 1e-9) then
                                    bestA, bestB, bestScore, bestMiss = ja, jb, score, miss
                                end
                                ApplyDelta(total, optB.delta, -1)
                                Breathe()
                            end
                            ApplyDelta(total, optA.delta, -1)
                        end
                        ApplyDelta(total, itemA.options[bestA].delta, 1)
                        ApplyDelta(total, itemB.options[bestB].delta, 1)
                        if bestA ~= choice[a] or bestB ~= choice[b] then
                            choice[a], choice[b] = bestA, bestB
                            pairMoved = true
                        end
                    end
                end
            end
        end

        -- Hat die paarweise Runde nichts mehr bewegt, findet die einzelne
        -- auch nichts mehr: beide stehen dann am selben Gipfel.
        if not pairMoved then break end
    end

    return choice, total
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

local function ReasonFor(ctx, option, before)
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

    -- Umgewandelte Werte: Waffenkunde, die als Zaubertreffer zaehlt, wird
    -- nicht nach ihrem eigenen Gewicht empfohlen, sondern weil sie in ein
    -- Ziel laeuft. Das gehoert in die Zeile, sonst steht dort "Waffenkunde
    -- (0) ist hoeher gewichtet als Krit (58)".
    local map = ctx.conv[dstKey]
    if map then
        for to in pairs(map) do
            local goal = ctx.target[to]
            if goal and to ~= dstKey and (before[to] or 0) < goal.rating - 1 then
                return string.format("%s zählt als %s", R.SHORT[dstKey],
                    goal.label or R.LABEL[to]), "green"
            end
        end
    end

    local ws = ctx.weights[srcKey] or 0
    local wd = ctx.weights[dstKey] or 0
    return string.format("%s (%d) ist höher gewichtet als %s (%d)",
        R.SHORT[dstKey], wd, R.SHORT[srcKey], ws), "textMuted"
end

--------------------------------------------------
-- Planen
--------------------------------------------------

local cache      = nil
local worker     = nil
local workerSig  = nil
local listeners  = {}

function RE.OnPlanReady(fn)
    listeners[#listeners + 1] = fn
end

local function Notify()
    for _, fn in ipairs(listeners) do pcall(fn) end
end

function RE.Invalidate()
    cache  = nil
    worker = nil
    workerSig = nil
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
    -- Die Kampfwertungen gerundet, und zwar grob: sie schwanken mit jedem
    -- Schmuckproc und jedem Raidbuff, und eine Kennung, die daran haengt,
    -- wuerde den Plan mitten im Kampf immer wieder verwerfen — samt der
    -- Auskunft, mit der die Sockelseite rechnet. Eine echte Umschmiedung
    -- bewegt mehrere hundert Punkte und faellt trotzdem auf; ausserdem
    -- traegt der Item-Link sie ohnehin.
    for _, key in ipairs(R.STATS) do
        parts[#parts + 1] = floor(LiveRating(key, "melee") / 100)
    end
    return table.concat(parts, "|")
end

local function BuildPlan(signature)
    -- NUR die Grenzen, nicht der volle Ausruestungs-Scan. Zwei Gruende, und
    -- der zweite ist der wichtigere: es spart sechzehn Tooltips je Lauf,
    -- UND es loest den Kreis auf. Die Sockelplanung in
    -- modules/charakter.lua liest das Ergebnis dieses Planers (RE.CapOutlook)
    -- — riefe der Planer hier den vollen Scan, riefe der Scan wieder ihn.
    local scan = WeintCodex.Charakter.CapContext()
    local items, problem, pending = ScanItems()
    if problem then
        cache = { signature = signature, plan = { ok = false, problem = problem } }
        return
    end

    local ctx = BuildContext(scan, items)

    if not ctx.profile then
        cache = { signature = signature, plan = { ok = false, pending = pending,
            problem = "Für diese Spezialisierung ist kein Profil hinterlegt —"
                .. " ohne Gewichte lässt sich nichts abwägen." } }
        return
    end

    for _, item in ipairs(items) do
        item.options = ItemOptions(item, ctx.mult, ctx.conv)
    end

    -- Der Iststand als Vergleichsmassstab.
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

    -- Stufe 1 und 2.
    local dpChoice, dims = RunDP(ctx, items)
    local choice, afterTotals
    if dpChoice then
        choice, afterTotals = Polish(ctx, items, dpChoice)
    else
        local blank = {}
        for i = 1, #items do blank[i] = 1 end
        choice, afterTotals = Polish(ctx, items, blank)
    end
    local scoreAfter = Score(ctx, afterTotals)

    -- Und der Iststand als zweiter Startpunkt: der Suchlauf geht immer nur
    -- bergauf, und "so lassen" muss eine erreichbare Antwort bleiben.
    local altChoice = {}
    for i, v in ipairs(asIs) do altChoice[i] = v end
    local altPolished, altTotals = Polish(ctx, items, altChoice)
    local altScore = Score(ctx, altTotals)
    if Better(ctx, altTotals, altScore, afterTotals, scoreAfter) then
        choice, afterTotals, scoreAfter = altPolished, altTotals, altScore
    end

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
            bare        = item.bare,
            ilvl        = item.ilvl,
            baseIlvl    = item.baseIlvl,
            upgrade     = item.upgrade,
            statSource  = item.statSource,
            statSetMismatch = item.statSetMismatch,
            locked      = item.locked,
            problem     = item.problem,
            warning     = item.warning,
            noSecondary = item.noSecondary,
            current     = item.current,
            options     = item.options,
        }

        if option and option.src then
            row.target = {
                src    = option.src,
                dst    = option.dst,
                amount = math.abs(option.delta[R.STATS[option.src]] or option.raw),
                raw    = option.raw,
            }
            row.reason, row.reasonTone = ReasonFor(ctx, option, beforeTotals)
        else
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
            -- traegt dann keinen Preis.
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

    cache = { signature = signature, plan = {
        ok          = true,
        pending     = pending,
        rows        = rows,
        ctx         = ctx,
        dims        = dims,
        before      = beforeTotals,
        after       = afterTotals,
        scoreBefore = scoreBefore,
        scoreAfter  = scoreAfter,
        capMisses   = CapMisses(ctx, afterTotals),
        changes     = changes,
        cost        = cost,
        profileKey  = scan.profileKey,
        specDisplay = scan.specDisplay,
    } }
end

--------------------------------------------------
-- Der Rechenlauf haelt regelmaessig an
--
-- Sechzehn Slots, zwei Achsen und ein Zustandsraum, der in die Tausende
-- geht: das ist mehr, als ein einzelnes Bild hergibt. Ein Addon, das den
-- Client dafuer stehenlaesst, ist genau das, was man abschaltet — also
-- wird in Haeppchen gerechnet und die Seite sagt so lange, dass sie
-- rechnet. Faellt der Lauf auf einen Fehler, wird er gemeldet und nicht
-- verschluckt: eine Seite, die ewig "rechnet", ist die schlechtere
-- Auskunft.
--------------------------------------------------

local function Pump()
    if not worker then return end
    local ok, err = coroutine.resume(worker)
    if not ok then
        worker = nil
        cache = { signature = workerSig, plan = { ok = false,
            problem = "Beim Rechnen ist etwas schiefgegangen: " .. tostring(err) } }
        Notify()
        return
    end
    if coroutine.status(worker) == "dead" then
        worker = nil
        Notify()
        return
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, Pump)
    else
        while worker and coroutine.status(worker) == "suspended" do
            coroutine.resume(worker)
        end
        worker = nil
        Notify()
    end
end

function RE.GetPlan(force)
    if not RE.Enabled() then
        return { ok = false, problem = "Der Umschmiede-Planer ist ausgeschaltet." }
    end
    if not (WeintCodex.Charakter and WeintCodex.Charakter.CapContext) then
        return { ok = false, problem = "Charaktermodul nicht geladen." }
    end

    local signature = Signature()

    if force then
        worker, workerSig, cache = nil, nil, nil
    elseif cache and signature and cache.signature == signature then
        return cache.plan
    end

    if worker and workerSig == signature then
        return { ok = false, computing = true }
    end

    steps       = 0
    budgetStart = Now() or 0
    workerSig   = signature
    worker    = coroutine.create(function() BuildPlan(signature) end)

    -- Ohne Zeitgeber (Testlauf ausserhalb des Spiels) wird sofort
    -- durchgerechnet, sonst kaeme nie ein Ergebnis.
    if not (C_Timer and C_Timer.After) or force then
        while worker and coroutine.status(worker) == "suspended" do
            local ok, err = coroutine.resume(worker)
            if not ok then
                worker = nil
                return { ok = false, problem = "Beim Rechnen ist etwas schiefgegangen: "
                    .. tostring(err) }
            end
        end
        worker = nil
        return (cache and cache.plan) or { ok = false, problem = "Kein Plan." }
    end

    Pump()
    if cache and cache.signature == signature then return cache.plan end
    return { ok = false, computing = true }
end

--------------------------------------------------
-- WAS DER PLAN AN DEN GRENZEN SCHON ERLEDIGT
--
-- Die eine Auskunft, die die Sockelplanung braucht — und der Grund, warum
-- Umschmieden und Sockel ueberhaupt zusammengehoeren:
--
--   UMSCHMIEDEN KOSTET GOLD, EIN SOCKEL IST EINMALIG.
--
-- Ein Sockel laesst sich einmal vergeben; Umschmieden bewegt 40 % eines
-- Sekundaerwerts je Gegenstand und laesst sich jederzeit zuruecknehmen. Wer
-- einen Sockel benutzt, um ein Kap zu fuellen, das das Umschmieden ohnehin
-- fuellt, verschenkt den Sockel. Genau das hat die Sockelseite bis 2.7.0.0
-- getan: sie rechnete mit dem Abstand zum Kap, den sie GERADE sah, und
-- empfahl Treffersteine fuer eine Luecke, die das Umschmieden umsonst
-- schliesst.
--
-- DREI ZURUECKHALTUNGEN, und jede ist eine Aussage ueber unser Wissen:
--   * Nur ein FERTIGER Plan zaehlt. Waehrend gerechnet wird, gibt es keine
--     Auskunft — und dann bleibt die Sockelseite bei ihrer bisherigen
--     Rechnung, statt mit halben Zahlen zu arbeiten.
--   * Nur ein Plan zur AKTUELLEN Ausruestung zaehlt (Kennungsvergleich).
--     Ein Plan von vor drei Gegenstaenden ist eine Aussage ueber eine
--     Ausruestung, die es nicht mehr gibt.
--   * Es wird NIE gerechnet. Diese Funktion laeuft mitten im Scan; wuerde
--     sie einen Lauf anstossen, riefe der Lauf wieder den Scan.
--
-- Ist der Planer aus, kommt nil — und alles bleibt, wie es vor 2.7.0.0 war.
--------------------------------------------------

function RE.CapOutlook()
    if not RE.Enabled() then return nil end
    if worker then return nil end
    if not (cache and cache.plan and cache.plan.ok and cache.plan.ctx) then return nil end
    if cache.signature ~= Signature() then return nil end

    local out = {}
    for key, goal in pairs(cache.plan.ctx.target) do
        local after = cache.plan.after[key] or 0
        out[key] = {
            label   = goal.label or R.LABEL[key],
            kind    = goal.kind,
            require = goal.require,
            target  = goal.rating,
            before  = cache.plan.before[key] or 0,
            after   = after,
            -- Schliesst der Plan diese Grenze von selbst?
            closes  = after >= goal.rating - 1,
            -- Und raeumt er einen Ueberschuss weg, der jetzt noch dasteht?
            over    = max(0, after - goal.rating),
        }
    end
    return out, cache.plan.changes
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
    for _, key in ipairs(plan.ctx.targetOrder) do
        local goal = plan.ctx.target[key]
        if goal then
            out[#out + 1] = {
                stat    = key,
                label   = goal.label or R.LABEL[key],
                kind    = goal.kind,
                require = goal.require,
                target  = goal.rating,
                before  = plan.before[key] or 0,
                after   = plan.after[key] or 0,
            }
        end
    end
    return out
end
