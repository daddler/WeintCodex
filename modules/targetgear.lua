--------------------------------------------------
-- WeintCodex :: ZIELAUSRUESTUNG AUS DEM SIM
--------------------------------------------------
-- WAS HIER ANDERS IST ALS ALLES DANEBEN.
--
-- Dieses Addon rechnet aus den Gewichten eines Spec-Profils aus, welcher
-- Stein in welchen Sockel gehoert und was wohin umgeschmiedet wird. Das
-- ist eine vollstaendige Optimierung - und damit die ZWEITE Antwort auf
-- eine Frage, die im Sim laengst beantwortet wurde. Fast alle gemeldeten
-- Fehlgriffe bei Steinen sind von dieser Sorte: nicht "die Rechnung ist
-- falsch", sondern "es wird ueberhaupt gerechnet, obwohl wowsims die
-- Entscheidung schon getroffen hat".
--
-- Diese Datei nimmt die Entscheidung entgegen. Sie rechnet NICHTS: sie
-- haelt fest, welche Steine und welche Umschmiedung der Sim fuer jeden
-- Ausruestungsplatz vorsieht, und beantwortet je Sockel und je Platz die
-- eine Frage "steht dazu etwas im Ziel?". Die Bewertung, die Anzeige und
-- der Spielraum bleiben, wo sie sind (modules/charakter.lua,
-- modules/reforge_engine.lua) - es wechselt nur die QUELLE der
-- Empfehlung, nicht die Stelle, an der sie entsteht.
--
-- DIE RANGFOLGE, UND SIE GILT IN GENAU DIESER RICHTUNG:
--
--   1. der Zielzustand aus dem Sim         (diese Datei)
--   2. eine Handauswahl des Spielers       (RE.GetManual, nur Umschmieden)
--   3. die eigene Rechnung als RUECKFALL   (PlanItem / der Suchlauf)
--
-- ...mit EINER Ausnahme, und die ist keine Inkonsequenz: beim Umschmieden
-- steht die Handauswahl VOR dem Sim-Ziel. Wer im Umschmiede-Fenster
-- "hier will ich Meisterschaft" gesagt hat, hat das nach dem Simmen
-- gesagt und weiss an dieser Stelle mehr - siehe modules/reforge_engine.lua.
-- Bei den Sockeln gibt es keine Handauswahl, dort ist die Frage nicht
-- gestellt.
--
-- WORAN DAS ZIEL SICH SELBST BEGRENZT.
--
-- Ein Zielzustand gilt fuer GENAU DIE AUSRUESTUNG, mit der gesimmt wurde.
-- Deshalb wird je Platz die Gegenstandsnummer verglichen: steckt dort
-- inzwischen ein anderes Teil, sagt das Ziel ueber diesen Platz nichts,
-- und die eigene Rechnung uebernimmt wieder. Das ist der Grund, aus dem
-- ein Ziel nicht wie eine Gewichtung erst bestaetigt werden muss: es kann
-- seinen Zusammenhang nicht ueberleben, sondern faellt von selbst weg,
-- sobald er nicht mehr gilt. Jede Zeile, die aus dem Ziel stammt, SAGT
-- das ausserdem (siehe ExplainGem drueben) - ohne diesen Satz waere eine
-- geaenderte Empfehlung von einem Fehler nicht zu unterscheiden.
--
-- ZUGEORDNET WIRD UEBER PLATZ UND POSITION, NIE UEBER EINEN NAMEN.
--
--   * Der PLATZ (`slot`) trennt Ring 1 von Ring 2, Schmuck 1 von
--     Schmuck 2 und Haupthand von Nebenhand. Zwei gleiche Ringe sind
--     zwei Ringe; welcher von beiden welche Steine bekommt, entscheidet
--     der Platz und nicht die Gegenstandsnummer.
--   * Die POSITION in `gems` ist der Sockel - dieselbe Zaehlung wie die
--     Steinfelder im Item-Link, also einschliesslich Zusatzsockel
--     (Guertelschnalle, Schmiedekunst). Eine 0 ist ein Sockel, der leer
--     bleiben soll, und sie muss stehen bleiben: ohne sie ruecken alle
--     Steine dahinter einen Sockel vor.
--
-- KEINE UNGEFRAGTE AUSGABE. Diagnose gibt es auf Zuruf (`/wc ziel`) -
-- dieselbe Linie wie `/wc sockel` und `/wc vz zeilen`. Diese Fehlerklasse
-- (falscher Platz, veraltetes Ziel, verschobene Sockelfolge) ist von
-- aussen sonst nicht zu unterscheiden von "der Sim hat es eben so
-- gewollt".
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.TargetGear = WeintCodex.TargetGear or {}

local TG = WeintCodex.TargetGear

--------------------------------------------------
-- ABLAGE
--------------------------------------------------
-- Ein Zielzustand JE SPEZIALISIERUNG, so wie die Companion sie ablegt
-- (`core/target_gear_store.py` drueben). Ein zweiter fuer dieselbe Spec
-- waere eine zweite Antwort auf eine Frage, die nur eine hat.
--
-- Geschrieben wird in WeintCodex.SavedData und NICHT in eine frisch
-- angelegte Ersatztabelle: WoW sichert nur, was in der .toc steht.

local DEFAULTS = {
    enabled = true,
}

local function Store()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local sd = WeintCodex.SavedData
    sd.targetGear = sd.targetGear or {}
    sd.targetGear.sets    = sd.targetGear.sets    or {}
    sd.targetGear.options = sd.targetGear.options or {}
    for key, value in pairs(DEFAULTS) do
        if sd.targetGear.options[key] == nil then
            sd.targetGear.options[key] = value
        end
    end
    return sd.targetGear
end

TG.Store = Store

-- Der Schalter ist bewusst da, und zwar fuer die Diagnose: "liegt es am
-- Sim-Ziel?" ist die erste Frage bei jeder Rueckmeldung zu einer
-- Steinempfehlung, und ohne ihn liesse sie sich nur durch Loeschen des
-- Ziels beantworten.
function TG.Enabled()
    return Store().options.enabled and true or false
end

function TG.SetEnabled(on)
    Store().options.enabled = on and true or false
end

--------------------------------------------------
-- EINEN EINTRAG PRUEFEN
--------------------------------------------------
-- Streng vorn, nachsichtig hinten - dieselbe Regel wie bei den
-- Sim-Gewichten. Ohne Spezialisierung liesse sich ein Ziel keinem Profil
-- zuordnen, ohne einen einzigen Platz haette es nichts zu sagen. Ein
-- unbekanntes Feld dagegen faellt weg und reisst nichts mit.
--
-- Rueckgabe: der bereinigte Eintrag, oder nil samt Grund.

local function CleanGems(list)
    local gems, seen = {}, 0
    if type(list) ~= "table" then return gems, 0 end
    -- ipairs, nicht pairs: die REIHENFOLGE ist die Aussage. Eine Luecke
    -- beendet die Liste, und das ist richtig - eine Position, die die
    -- Nachricht nicht nennt, gibt es nicht.
    for i, value in ipairs(list) do
        local number = tonumber(value) or 0
        gems[i] = (number > 0) and math.floor(number) or 0
        if gems[i] > 0 then seen = seen + 1 end
    end
    return gems, seen
end

function TG.CleanEntry(entry)
    if type(entry) ~= "table" then return nil, "keine Angaben" end

    local spec = tostring(entry.spec or ""):upper()
    if spec == "" then
        return nil, "ohne Spezialisierung — ein Zielzustand liesse sich"
            .. " keinem Profil zuordnen"
    end

    local items, count, gemCount, reforgeCount = {}, 0, 0, 0

    for _, row in ipairs(entry.items or {}) do
        if type(row) == "table" then
            local slot   = tonumber(row.slot)
            local itemId = tonumber(row.itemId or row.item_id)
            if slot and itemId and slot > 0 and itemId > 0 then
                local gems, filled = CleanGems(row.gems)
                local reforge = tonumber(row.reforge or row.reforging) or 0
                -- Ausserhalb der 56 Paare ist es keine Umschmiedung.
                -- Weitergereicht wuerde daraus drueben eine laufende
                -- Nummer im Umschmieder, die es nicht gibt - und die
                -- schmiedet etwas anderes, als auf der Seite steht.
                local R = WeintCodex_Reforge
                if R and R.BY_ID and not R.BY_ID[reforge] then reforge = 0 end
                items[slot] = {
                    slot    = slot,
                    itemId  = math.floor(itemId),
                    gems    = gems,
                    reforge = reforge,
                    enchant = tonumber(row.enchant) or 0,
                }
                count        = count + 1
                gemCount     = gemCount + filled
                reforgeCount = reforgeCount + ((reforge > 0) and 1 or 0)
            end
        end
    end

    if count == 0 then
        return nil, "ohne einen einzigen Ausruestungsplatz"
    end

    -- EIN ZIEL OHNE STEIN UND OHNE UMSCHMIEDUNG IST KEINE AUSKUNFT.
    -- Es saehe im Spiel aus wie "alles ist schon richtig" und wuerde
    -- jede Empfehlung zum Schweigen bringen - genau die Sorte
    -- Fehlmeldung, die man nicht als solche erkennt.
    if gemCount == 0 and reforgeCount == 0 then
        return nil, "ohne einen einzigen Stein und ohne Umschmiedung"
    end

    return {
        id        = tostring(entry.id or ""),
        spec      = spec,
        character = tostring(entry.character or ""),
        realm     = tostring(entry.realm or ""),
        source    = tostring(entry.source or "wowsims"),
        created   = tonumber(entry.created) or 0,
        items     = items,
        count     = count,
        gemCount  = gemCount,
        reforgeCount = reforgeCount,
    }
end

--------------------------------------------------
-- ABLEGEN
--------------------------------------------------
-- Ein Ziel wird HINGELEGT UND GILT - anders als eine Gewichtung, die
-- erst auf Klick wirksam wird. Der Unterschied steht oben im Kopf: eine
-- Gewichtung gilt fuer jede Ausruestung und ueberlebt damit ihren
-- Zusammenhang, ein Ziel nicht. Es wirkt nur dort, wo noch derselbe
-- Gegenstand steckt, es sagt an jeder Zeile, dass es aus dem Sim kommt,
-- und `/wc ziel` zeigt es vollstaendig.

function TG.Accept(entry)
    local clean, problem = TG.CleanEntry(entry)
    if not clean then return false, problem end

    Store().sets[clean.spec] = clean
    return true, nil, clean
end

-- Die Companion schickt IMMER die ganze Liste (siehe
-- core/target_gear_sync.py). Was nicht mehr geliefert wird, gibt es
-- nicht mehr - eine Einzelnachricht koennte "mich gibt es nicht mehr"
-- gar nicht ausdruecken, weil das Addon seine Inbox bei jedem Login
-- leert.
function TG.ReplaceAll(list)
    local store = Store()
    local kept, fresh = {}, 0

    for _, entry in ipairs(list or {}) do
        local ok, _, clean = TG.Accept(entry)
        if clean then
            kept[clean.spec] = true
            if ok then fresh = fresh + 1 end
        end
    end

    for spec in pairs(store.sets) do
        if not kept[spec] then store.sets[spec] = nil end
    end

    return fresh
end

function TG.Forget(specKey)
    local store = Store()
    if specKey then
        store.sets[tostring(specKey):upper()] = nil
    else
        store.sets = {}
    end
end

function TG.Count()
    local n = 0
    for _ in pairs(Store().sets) do n = n + 1 end
    return n
end

--------------------------------------------------
-- LESEN
--------------------------------------------------

-- DER CHARAKTER MUSS STIMMEN, WENN DAS ZIEL EINEN NENNT.
--
-- WeintCodex_SavedData ist kontoweit. Ohne diese Pruefung truege der
-- Zweitcharakter derselben Klasse und Spec das Ziel des Mains - und weil
-- die Gegenstandsnummern dort andere sind, faende er ueberall "kein
-- Ziel" statt "das Ziel gehoert nicht mir". Das sind zwei verschiedene
-- Auskuenfte, und nur die zweite fuehrt zu einem naechsten Schritt.
--
-- Nennt das Ziel keinen Charakter (die wowsims-ADRESSE tut das nicht),
-- gilt es fuer den, der es angenommen hat. Ein leeres Feld ist keine
-- Aussage ueber jemand anderen.
local function BelongsToMe(entry)
    local name = entry and entry.character or ""
    if name == "" then return true end
    if not (WeintCodex.Names and WeintCodex.Names.Equal) then return true end
    local me = WeintCodex.Names.Me and WeintCodex.Names.Me() or nil
    if not me then return true end
    return WeintCodex.Names.Equal(name, me)
       or WeintCodex.Names.Equal(name, (tostring(me):match("^([^%-]+)")))
end

TG.BelongsToMe = BelongsToMe

-- Der Zielzustand fuer eine Spezialisierung, oder nil samt Grund.
--
-- `specKey` gibt der Aufrufer mit; diese Datei ermittelt die
-- Spezialisierung NICHT selbst. modules/charakter.lua kennt sie bereits
-- (GetCurrentSpecProfile), und eine zweite Ermittlung daneben waere
-- genau die Doppelung, an der die Sockelbewertung schon einmal
-- auseinandergelaufen ist - abgesehen davon laedt diese Datei vor jener.
function TG.SetFor(specKey)
    if not TG.Enabled() then return nil, "abgeschaltet" end

    local key = tostring(specKey or ""):upper()
    if key == "" then return nil, "keine Spezialisierung" end

    -- Die Tank-Haltung hat ein eigenes Profil (`*_OFFENSIVE`), der Sim
    -- kennt sie nicht: er fuehrt je Spec eine Seite. Ein Ziel fuer die
    -- Basis-Spec gilt deshalb fuer beide Haltungen - es beschreibt
    -- Steine und Umschmiedungen, nicht eine Spielweise.
    key = key:gsub("_OFFENSIVE$", "")

    local entry = Store().sets[key]
    if not entry then return nil, "kein Ziel fuer " .. key end

    if not BelongsToMe(entry) then
        return nil, "das Ziel gehoert " .. entry.character
    end

    return entry
end

-- Der Zieleintrag EINES Platzes - und zwar nur, wenn dort noch derselbe
-- Gegenstand steckt.
--
-- Rueckgabe: item, entry  bzw.  nil, nil, grund
function TG.ItemFor(specKey, slotId, equippedItemId)
    local entry, why = TG.SetFor(specKey)
    if not entry then return nil, nil, why end

    local item = entry.items[slotId]
    if not item then
        return nil, entry, "das Ziel nennt diesen Platz nicht"
    end

    if equippedItemId and item.itemId ~= equippedItemId then
        -- VERALTET IST NICHT DASSELBE WIE NICHT VORHANDEN. Wer seit dem
        -- Simmen ein neues Teil angelegt hat, soll das lesen koennen -
        -- sonst sucht er den Fehler in der Steinliste.
        return nil, entry, string.format(
            "das Ziel meint Gegenstand %d, angelegt ist %d",
            item.itemId, equippedItemId)
    end

    return item, entry
end

-- WELCHER STEIN GEHOERT IN DIESEN SOCKEL - laut Sim.
--
-- `socketIndex` ist die Position im Item-Link (socket.index drueben),
-- also dieselbe Zaehlung, in der der Sim seine Steine fuehrt. Zusatz-
-- sockel eingeschlossen: sie stehen im Link an den Positionen hinter den
-- eingebauten, und der Sim haengt sie ebenso hinten an.
--
-- EINE 0 IST KEINE AUSSAGE, SONDERN EINE LUECKE.
--
-- Im Uebertragungsformat muss sie stehen bleiben, weil die Position den
-- Sockel benennt (ohne sie ruecken alle Steine dahinter vor). Gelesen
-- wird sie hier aber als "das Ziel nennt fuer diesen Sockel keinen
-- Stein" und ausdruecklich NICHT als "dieser Sockel soll leer bleiben":
-- eine 0 entsteht auch dann, wenn im Sim schlicht nichts eingestellt
-- war, und aus ihr eine Empfehlung "nimm deinen Stein wieder heraus" zu
-- machen waere der teure Irrtum in der falschen Richtung. Fuer diesen
-- Sockel rechnet dann die eigene Empfehlung weiter - dieselbe Linie wie
-- `headroom == nil` und `stars == 0`.
--
-- Rueckgabe:
--   gemId    ein Stein
--   nil      das Ziel sagt zu diesem Sockel nichts, samt Grund
function TG.GemFor(specKey, slotId, equippedItemId, socketIndex)
    local item, _, why = TG.ItemFor(specKey, slotId, equippedItemId)
    if not item then return nil, why end

    if not socketIndex or socketIndex < 1 then
        return nil, "kein Sockelplatz"
    end

    local gems = item.gems or {}

    if socketIndex > #gems then
        -- DAS ZIEL KENNT WENIGER SOCKEL ALS DAS TEIL. Kommt vor, wenn
        -- der Sim einen Zusatzsockel nicht mitfuehrt (Guertelschnalle,
        -- Schmiedekunst) oder der Spieler ihn nach dem Simmen erst
        -- angebracht hat. Fuer DIESEN Sockel gilt dann die eigene
        -- Rechnung - die uebrigen bleiben beim Ziel. Alles andere
        -- hiesse, einen Sockel zu raten oder das ganze Teil
        -- wegzuwerfen, und beides ist schlechter.
        return nil, string.format(
            "das Ziel nennt nur %d Sockel, gefragt ist der %d.",
            #gems, socketIndex)
    end

    local gem = gems[socketIndex] or 0

    if gem == 0 then
        return nil, "das Ziel nennt fuer diesen Sockel keinen Stein"
    end

    return gem
end

-- WAS SOLL AN DIESEM TEIL UMGESCHMIEDET WERDEN - laut Sim.
--
-- Rueckgabe:
--   src, dst   Statnummern nach WeintCodex_Reforge.STATS
--   false      hier soll GAR NICHT umgeschmiedet werden (eine Aussage)
--   nil        das Ziel sagt zu diesem Platz nichts, samt Grund
function TG.ReforgeFor(specKey, slotId, equippedItemId)
    local item, _, why = TG.ItemFor(specKey, slotId, equippedItemId)
    if not item then return nil, why end

    local R = WeintCodex_Reforge
    if not (R and R.BY_ID and R.PAIRS) then
        return nil, "Umschmiede-Grunddaten fehlen"
    end

    if (item.reforge or 0) == 0 then
        -- AUSDRUECKLICH KEINE. Der Sim hat diesen Platz angesehen und
        -- nichts umgeschmiedet; das ist etwas anderes als "kein Ziel".
        -- Ohne diese Unterscheidung wuerde der Planer den Platz wieder
        -- selbst belegen, und zwar genau dort, wo der Sim sich bewusst
        -- dagegen entschieden hat.
        return false
    end

    local n = R.BY_ID[item.reforge]
    local pair = n and R.PAIRS[n]
    if not pair then
        return nil, "unbekannter Umschmiedewert " .. tostring(item.reforge)
    end

    return pair.src, pair.dst
end

--------------------------------------------------
-- DER UEBERTRAGUNGSSTRING
--
--   WCIMPORT:TG:<Spec>:<Kennung>:<Zeit>:<Charakter>:<Quelle>:
--       <slot>|<itemId>|<gem1>-<gem2>-<gem3>|<reforge>|<enchant>,...
--
-- Dieselbe Form wie die uebrigen Importe (Abschnitte mit ":",
-- Datensaetze mit ",", Felder mit "|"), damit es keinen zweiten Parser
-- gibt. Die Steine eines Gegenstands haengen mit "-" aneinander, weil
-- die drei uebrigen Zeichen vergeben sind; sie sind Ziffern, ein
-- Bindestrich kann darin nicht vorkommen.
--
-- Erzeugt wird er drueben in `core/target_gear.build_transfer()`;
-- zerlegt wird er HIER und nicht in modules/sync.lua, weil das Zerlegen
-- einer fremden Zeichenkette die Sorte Rechnung ist, die der Testlauf
-- ohne Spiel pruefen koennen muss.
--------------------------------------------------

function TG.ParseTransfer(payload)
    if type(payload) ~= "string" then return nil, "Leerer Import-String." end

    local fields = {}
    for part in (payload .. ":"):gmatch("([^:]*):") do
        fields[#fields + 1] = part
    end

    local spec = tostring(fields[1] or ""):gsub("%s+", ""):upper()
    if spec == "" then
        return nil, "Dem String fehlt die Spezialisierung — ohne sie"
            .. " liesse sich der Zielzustand keinem Profil zuordnen."
    end

    local rows = fields[6] or ""
    local items = {}

    for row in (rows .. ","):gmatch("([^,]*),") do
        local trimmed = row:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            local parts = {}
            for part in (trimmed .. "|"):gmatch("([^|]*)|") do
                parts[#parts + 1] = part
            end
            local slot   = tonumber(parts[1])
            local itemId = tonumber(parts[2])
            if slot and itemId then
                -- DIE LEEREN FELDER MUESSEN MITZAEHLEN. "76895--76639"
                -- ist ein leerer MITTLERER Sockel; wuerde er
                -- uebersprungen, ruecken die Steine dahinter vor -
                -- derselbe Fehler, den ParseItemLink beim Item-Link
                -- ausdruecklich vermeidet.
                local gems = {}
                local raw = parts[3] or ""
                if raw ~= "" then
                    for value in (raw .. "-"):gmatch("([^-]*)-") do
                        gems[#gems + 1] = tonumber(value) or 0
                    end
                end
                items[#items + 1] = {
                    slot    = slot,
                    itemId  = itemId,
                    gems    = gems,
                    reforge = tonumber(parts[4]) or 0,
                    enchant = tonumber(parts[5]) or 0,
                }
            end
        end
    end

    if #items == 0 then
        return nil, "In dem String steht kein einziger Ausruestungsplatz."
    end

    return {
        id        = fields[2] or "",
        spec      = spec,
        created   = tonumber(fields[3]) or 0,
        character = fields[4] or "",
        source    = (fields[5] ~= "" and fields[5]) or "wowsims",
        items     = items,
    }
end

--------------------------------------------------
-- DIAGNOSE (`/wc ziel`)
--------------------------------------------------
-- Was wurde geliefert, was steht angelegt, und woraus folgt die
-- Empfehlung? Diese Fehlerklasse - ein veraltetes Ziel, ein verschobener
-- Sockel, ein Ziel fuer den falschen Charakter - sieht von aussen
-- identisch aus zu "der Sim wollte es eben so". Ohne diesen Befehl waere
-- sie nicht zu melden, dieselbe Ueberlegung wie bei `/wc sockel`.
--
-- KEINE AUSGABE OHNE FRAGE: gedruckt wird nur hier.

local function Say(text)
    print("|cffD4A24A[WeintCodex]|r " .. text)
end

local SLOT_NAMES = {
    [1] = "Kopf", [2] = "Hals", [3] = "Schultern", [5] = "Brust",
    [6] = "Taille", [7] = "Beine", [8] = "Fuesse", [9] = "Handgelenke",
    [10] = "Haende", [11] = "Finger 1", [12] = "Finger 2",
    [13] = "Schmuck 1", [14] = "Schmuck 2", [15] = "Umhang",
    [16] = "Haupthand", [17] = "Nebenhand", [18] = "Distanz",
}

TG.SLOT_NAMES = SLOT_NAMES

local function GemName(id)
    if not id or id == 0 then return "leer" end
    if WeintCodex_GetGemName then return WeintCodex_GetGemName(id) end
    return "ID " .. id
end

local function ReforgeText(reforgeId)
    local R = WeintCodex_Reforge
    if not (R and R.BY_ID) then return "?" end
    if not reforgeId or reforgeId == 0 then return "keine" end
    local pair = R.PAIRS[R.BY_ID[reforgeId] or -1]
    if not pair then return "unbekannt (" .. reforgeId .. ")" end
    return (R.SHORT[R.STATS[pair.src]] or "?") .. " -> "
        .. (R.SHORT[R.STATS[pair.dst]] or "?")
end

TG.ReforgeText = ReforgeText

function TG.Command(rest)
    local arg = tostring(rest or ""):lower():match("^%s*(%S*)")

    if arg == "aus" or arg == "off" then
        TG.SetEnabled(false)
        Say("Zielausruestung aus dem Sim ist |cffEF4444abgeschaltet|r —"
            .. " Sockel und Umschmieden rechnen wieder selbst.")
        return
    end

    if arg == "an" or arg == "on" then
        TG.SetEnabled(true)
        Say("Zielausruestung aus dem Sim ist |cff22C55Ean|r.")
        return
    end

    if arg == "weg" or arg == "loeschen" then
        TG.Forget()
        Say("Alle Zielausruestungen verworfen.")
        return
    end

    TG.Dump()
end

function TG.Dump()
    local store = Store()

    Say("ZIELAUSRUESTUNG — " .. (TG.Enabled() and "an" or "AUS")
        .. ", " .. TG.Count() .. " abgelegt.")

    if not TG.Enabled() then
        Say("  |cff9A9AA5/wc ziel an|r schaltet sie wieder ein.")
    end

    local CH = WeintCodex.Charakter
    local specKey = CH and CH.CurrentProfileKey and CH.CurrentProfileKey() or nil

    if not specKey then
        Say("  |cffEF4444Aktuelle Spezialisierung nicht ermittelbar.|r")
    end

    for spec, entry in pairs(store.sets) do
        Say(string.format(
            "  %s%s|r — %d Plaetze, %d Steine, %d Umschmiedungen, aus %s%s",
            (spec == (specKey or ""):gsub("_OFFENSIVE$", "")) and "|cff22C55E" or "|cff9A9AA5",
            spec, entry.count or 0, entry.gemCount or 0,
            entry.reforgeCount or 0, entry.source or "?",
            (entry.character ~= "" and (" fuer " .. entry.character) or "")))
        if not BelongsToMe(entry) then
            Say("    |cffEF4444gilt nicht fuer diesen Charakter|r")
        end
    end

    if not specKey then return end

    local entry, why = TG.SetFor(specKey)
    if not entry then
        Say("  |cffEF4444Kein wirksames Ziel:|r " .. tostring(why))
        return
    end

    Say("  Platz fuer Platz (angelegt gegen Ziel):")

    for slot = 1, 18 do
        local name = SLOT_NAMES[slot]
        local link = name and GetInventoryItemLink and GetInventoryItemLink("player", slot)
        local item = entry.items[slot]

        if name and (link or item) then
            local equippedId, equippedGems
            if link and CH and CH.ParseItemLinkForDiagnostics then
                equippedId, equippedGems = CH.ParseItemLinkForDiagnostics(link)
            end

            if not item then
                Say(string.format("    %-12s |cff9A9AA5kein Ziel|r", name))
            elseif equippedId and equippedId ~= item.itemId then
                Say(string.format(
                    "    %-12s |cffEF4444veraltet|r — Ziel %d, angelegt %d",
                    name, item.itemId, equippedId))
            else
                -- Bis 4, nicht bis `#gems`: ParseItemLink liefert eine
                -- LUECKENHAFTE Tabelle (leere Sockel fehlen darin), und
                -- `#` ist auf so einer nicht verlaesslich. Vier ist die
                -- Zahl der Steinfelder im Item-Link.
                local ist, soll = {}, {}
                local n = math.max(#(item.gems or {}), 4)
                for i = 1, n do
                    ist[#ist + 1]  = GemName((equippedGems or {})[i])
                    soll[#soll + 1] = GemName((item.gems or {})[i])
                end
                -- Hinten abschneiden, solange BEIDE Seiten leer sind:
                -- ein Ring ohne Sockel soll nicht viermal "leer" sagen.
                while #ist > 0 and ist[#ist] == "leer" and soll[#soll] == "leer" do
                    table.remove(ist)
                    table.remove(soll)
                end
                Say(string.format("    %-12s Sockel: %s |cffD4A24A->|r %s",
                    name,
                    (#ist > 0 and table.concat(ist, ", ") or "-"),
                    (#soll > 0 and table.concat(soll, ", ") or "-")))
                Say(string.format("                 Umschmieden Ziel: %s",
                    ReforgeText(item.reforge)))
            end
        end
    end
end
