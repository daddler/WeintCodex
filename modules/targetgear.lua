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
-- und die eigene Rechnung uebernimmt wieder. Es kann seinen Zusammenhang
-- also nicht ueberleben, sondern faellt von selbst weg, sobald er nicht
-- mehr gilt. Jede Zeile, die aus dem Ziel stammt, SAGT das ausserdem
-- (siehe ExplainGem drueben) - ohne diesen Satz waere eine geaenderte
-- Empfehlung von einem Fehler nicht zu unterscheiden.
--
-- SEIT 3.0.3.0 WIRD DER EINGEFUEGTE STRING TROTZDEM ERST GEZEIGT.
-- Nicht, weil zu klaeren waere, ob der Spieler das WILL - das hat er auf
-- dem Desktop entschieden -, sondern weil er sonst nicht sieht, WAS
-- eintrifft: welche Plaetze wegen eines getauschten Teils gar nicht
-- gelten, und dass Steine von Hand eingesetzt werden muessen. Siehe
-- TG.ShowConfirm ganz unten. Die Zustellung ueber die Addon-Bruecke
-- (Login/`/reload`) fragt weiterhin nicht.
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

        -- AUS WELCHEM SIM-LAUF (seit 3.2.0.0). Ein leeres Feld ist
        -- gueltig: jeder Zielzustand von einer Companion vor 3.3.0 hat
        -- keins. Zugeordnet wird weiterhin ueber Spec und
        -- Gegenstandsnummer - die Kennung beantwortet nur, ob dieser
        -- Zielzustand und die Gewichtung daneben aus EINEM Lauf
        -- stammen. Siehe modules/simexport.lua.
        run       = tostring(entry.run or ""),

        -- Der Zeitstempel der Ausruestung, MIT der gesimmt wurde, in
        -- der Uhr dieses Spiels (geschrieben vom WowSimsExporter).
        -- 0 heisst "nicht feststellbar", nicht "Sekunde 0".
        startedAt = tonumber(entry.startedAt) or 0,

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
--       :<Sim-Lauf>:<Startzeit>
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

        -- ABSCHNITT 7 UND 8, ANGEHAENGT (Companion ab 3.3.0). Die
        -- Felder 1 bis 6 stehen unveraendert an ihrem Platz; ein
        -- aelterer String liefert hier "" und 0. Der Bindestrich in
        -- der Kennung stoert nicht: er trennt nur INNERHALB eines
        -- Datensatzes die Steine, und der steht in Feld 6.
        run       = fields[7] or "",
        startedAt = tonumber(fields[8]) or 0,

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

local function PairText(pair)
    local R = WeintCodex_Reforge
    if not (R and R.SHORT and R.STATS) then return "?" end
    if not pair then return "keine" end
    return (R.SHORT[R.STATS[pair.src]] or "?") .. " -> "
        .. (R.SHORT[R.STATS[pair.dst]] or "?")
end

local function ReforgeText(reforgeId)
    local R = WeintCodex_Reforge
    if not (R and R.BY_ID) then return "?" end
    if not reforgeId or reforgeId == 0 then return "keine" end
    local pair = R.PAIRS[R.BY_ID[reforgeId] or -1]
    if not pair then return "unbekannt (" .. reforgeId .. ")" end
    return PairText(pair)
end

TG.ReforgeText = ReforgeText

--------------------------------------------------
-- ANGELEGT GEGEN ZIEL - EINMAL GERECHNET
--------------------------------------------------
-- Diese Frage stellen ZWEI Stellen: `/wc ziel` als Textausgabe und das
-- Bestaetigungsfenster vor dem Uebernehmen. Zwei Fassungen davon waeren
-- zwei Gelegenheiten auseinanderzulaufen - und ausgerechnet hier faellt
-- das niemandem auf, weil beide plausibel aussehen. Also: eine
-- Rechnung, zwei Darstellungen.
--
-- Rein lesend. Der Eintrag muss NICHT abgelegt sein - das
-- Bestaetigungsfenster vergleicht ihn, bevor er gilt.
--
-- ERWARTET DEN BEREINIGTEN EINTRAG (aus TG.CleanEntry oder TG.SetFor),
-- dessen `items` nach SLOTNUMMER indiziert sind. Das rohe Ergebnis von
-- TG.ParseTransfer ist eine fortlaufende Liste und passt hier nicht.
--
-- Je Platz einer von drei Zustaenden:
--   "ok"    das Ziel gilt hier
--   "stale" ein anderer Gegenstand steckt im Platz (Ziel greift nicht)
--   "none"  das Ziel sagt zu diesem Platz nichts
--------------------------------------------------

function TG.Compare(entry)
    local rows, ok, stale, none = {}, 0, 0, 0
    if type(entry) ~= "table" or type(entry.items) ~= "table" then
        return { rows = rows, ok = 0, stale = 0, none = 0 }
    end

    local CH = WeintCodex.Charakter
    local RE = WeintCodex.ReforgeEngine

    for slot = 1, 18 do
        local name = SLOT_NAMES[slot]
        local link = name and GetInventoryItemLink
            and GetInventoryItemLink("player", slot)
        local item = entry.items[slot]

        if name and (link or item) then
            local equippedId, equippedGems
            if link and CH and CH.ParseItemLinkForDiagnostics then
                equippedId, equippedGems = CH.ParseItemLinkForDiagnostics(link)
            end

            local row = {
                slot = slot, name = name,
                targetItemId = item and item.itemId or nil,
                equippedItemId = equippedId,
            }

            if not item then
                row.state = "none"
                none = none + 1
            elseif equippedId and equippedId ~= item.itemId then
                row.state = "stale"
                stale = stale + 1
            else
                row.state = "ok"
                ok = ok + 1

                -- Bis 4, nicht bis `#gems`: ParseItemLink liefert eine
                -- LUECKENHAFTE Tabelle (leere Sockel fehlen darin), und
                -- `#` ist auf so einer nicht verlaesslich. Vier ist die
                -- Zahl der Steinfelder im Item-Link.
                local istIds, sollIds = {}, {}
                local n = math.max(#(item.gems or {}), 4)
                for i = 1, n do
                    istIds[i]  = (equippedGems or {})[i] or 0
                    sollIds[i] = (item.gems or {})[i] or 0
                end
                -- Hinten abschneiden, solange BEIDE Seiten leer sind: ein
                -- Ring ohne Sockel soll nicht viermal "leer" sagen.
                while #istIds > 0
                      and istIds[#istIds] == 0 and sollIds[#sollIds] == 0 do
                    table.remove(istIds)
                    table.remove(sollIds)
                end

                local istText, sollText, changed = {}, {}, false
                for i = 1, #istIds do
                    istText[i]  = GemName(istIds[i])
                    sollText[i] = GemName(sollIds[i])
                    -- EINE 0 IM ZIEL IST KEINE AENDERUNG. Sie heisst
                    -- "der Sim sagt zu diesem Sockel nichts" und nicht
                    -- "nimm den Stein heraus" - dieselbe Linie wie in
                    -- ParseTransfer und in PlanItem.
                    if sollIds[i] ~= 0 and sollIds[i] ~= istIds[i] then
                        changed = true
                    end
                end

                row.gemIdsIst  = istIds
                row.gemIdsSoll = sollIds
                row.gemsIst    = istText
                row.gemsSoll   = sollText
                row.gemsChanged = changed

                row.reforgeSoll     = item.reforge or 0
                row.reforgeSollText = ReforgeText(item.reforge)

                local current = RE and RE.CurrentPair and RE.CurrentPair(slot) or nil
                row.reforgeIstText = PairText(current)

                local R = WeintCodex_Reforge
                local wanted = (item.reforge or 0) ~= 0 and R and R.BY_ID
                    and R.PAIRS[R.BY_ID[item.reforge] or -1] or nil
                row.reforgeChanged =
                    (wanted and wanted.src or 0) ~= (current and current.src or 0)
                    or (wanted and wanted.dst or 0) ~= (current and current.dst or 0)
            end

            rows[#rows + 1] = row
        end
    end

    return { rows = rows, ok = ok, stale = stale, none = none }
end

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

        -- AUS WELCHEM LAUF, UND PASST DIE GEWICHTUNG DAZU?
        --
        -- Das ist die erste Frage jeder Rueckmeldung zu einer
        -- Steinempfehlung - und die eine, die von aussen gar nicht zu
        -- beantworten war. Eine Gewichtung aus dem Lauf von gestern
        -- neben einem Zielzustand von heute sieht im Spiel aus wie ein
        -- stimmiges Ergebnis und ist eine Aussage ueber zwei
        -- verschiedene Ausruestungen.
        if (entry.run or "") ~= "" then
            Say("    Sim-Lauf " .. entry.run
                .. ((entry.startedAt or 0) > 0 and date
                    and (" · Ausruestung vom "
                         .. date("%d.%m.%Y %H:%M", entry.startedAt)) or ""))

            local SW = WeintCodex.StatWeights
            local weights = SW and SW.Pending and SW.Pending(spec)
            if weights and (weights.run or "") ~= ""
               and weights.run ~= entry.run then
                Say("    |cffEF4444Die bereitliegende Gewichtung stammt aus"
                    .. " einem anderen Lauf (" .. weights.run .. ").|r"
                    .. " |cff9A9AA5Beide Ausgaben desselben Laufs einfuegen,"
                    .. " dann passt es zusammen.|r")
            end
        else
            Say("    |cff9A9AA5ohne Sim-Lauf-Kennung (aeltere Companion oder"
                .. " von Hand eingefuegt)|r")
        end
    end

    local SE = WeintCodex.SimExport
    local last = SE and SE.LastRun and SE.LastRun()
    if last then
        Say(string.format(
            "  Zuletzt angekommen: %s (%s%s)", last.id or "?",
            last.weights and "Gewichtung" or "keine Gewichtung",
            last.target and " + Zielausruestung" or ""))
    end

    if not specKey then return end

    local entry, why = TG.SetFor(specKey)
    if not entry then
        Say("  |cffEF4444Kein wirksames Ziel:|r " .. tostring(why))
        return
    end

    Say("  Platz fuer Platz (angelegt gegen Ziel):")

    for _, row in ipairs(TG.Compare(entry).rows) do
        if row.state == "none" then
            Say(string.format("    %-12s |cff9A9AA5kein Ziel|r", row.name))
        elseif row.state == "stale" then
            Say(string.format(
                "    %-12s |cffEF4444veraltet|r — Ziel %d, angelegt %d",
                row.name, row.targetItemId or 0, row.equippedItemId or 0))
        else
            Say(string.format("    %-12s Sockel: %s |cffD4A24A->|r %s",
                row.name,
                (#row.gemsIst > 0 and table.concat(row.gemsIst, ", ") or "-"),
                (#row.gemsSoll > 0 and table.concat(row.gemsSoll, ", ") or "-")))
            Say(string.format("                 Umschmieden: %s |cffD4A24A->|r %s",
                row.reforgeIstText, row.reforgeSollText))
        end
    end
end

--------------------------------------------------
-- DAS BESTAETIGUNGSFENSTER
--------------------------------------------------
-- Ein Zielzustand aendert Sockel- UND Umschmiede-Empfehlung fuer die
-- halbe Ausruestung auf einen Schlag. Bis 3.0.2.3 geschah das
-- stillschweigend beim Einfuegen des Strings - mit der Begruendung, dass
-- der Spieler die Entscheidung ja schon auf dem Desktop getroffen hat.
--
-- DIESE BEGRUENDUNG WAR NUR HALB RICHTIG. Sie erklaert, warum nicht
-- nachgefragt werden muss, ob er das WILL - nicht aber, woher er wissen
-- soll, WAS eintrifft. Genau daran ist es aufgefallen: was der Sim
-- vorsieht, welche Plaetze wegen eines getauschten Teils gar nicht
-- gelten, und dass Steine von Hand eingesetzt werden muessen, stand
-- nirgends. Ein Import, der "15 Plaetze" meldet und danach an sechs
-- davon nichts tut, ist von einem kaputten Import nicht zu
-- unterscheiden.
--
-- Das Fenster zeigt deshalb Platz fuer Platz, was gilt und was nicht -
-- aus DERSELBEN Rechnung wie `/wc ziel` (TG.Compare) - und uebernimmt
-- erst auf Klick. Abbrechen legt nichts ab.
--
-- Es entscheidet NICHT selbst: `onConfirm` gehoert dem Aufrufer
-- (modules/sync.lua), damit es genau einen Weg gibt, auf dem ein Ziel
-- abgelegt wird.
--------------------------------------------------

local confirmFrame = nil

local function SpecLabel(spec)
    local profiles = WeintCodex_SpecProfiles
    if profiles and profiles[spec] and profiles[spec].name then
        return profiles[spec].name
    end
    return spec or "?"
end

local function BuildConfirmFrame()
    local C = WeintCodex.Colors
    local F = WeintCodex.Fonts
    local parent = WeintCodex.MainFrame

    local f = WeintCodex.CreateSurface(parent, {
        width = 900, height = 600, tone = "plain", radius = 14,
        backdrop = "bgDark",
    })
    f:SetPoint("CENTER", parent, "CENTER", 0, 0)
    f:SetFrameStrata("TOOLTIP")
    f:EnableMouse(true)
    f:Hide()

    local eyebrow = WeintCodex.Eyebrow(f, "Zielausruestung aus dem Sim")
    eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -20)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(F.sansBold, 20, "")
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)
    title:SetTextColor(unpack(C.textBright))
    title:SetText("Das steht in deinem Sim-Ergebnis")
    f._title = title

    local herkunft = WeintCodex.Label(f, "", { color = "textMuted", size = 13 })
    herkunft:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    herkunft:SetWidth(840)
    herkunft:SetJustifyH("LEFT")
    f._herkunft = herkunft

    local summe = WeintCodex.Label(f, "", { color = "textNormal", size = 13 })
    summe:SetPoint("TOPLEFT", herkunft, "BOTTOMLEFT", 0, -6)
    summe:SetWidth(840)
    summe:SetJustifyH("LEFT")
    f._summe = summe

    -- Die Warnzeile steht NICHT immer da: eine dauerhafte Warnung, die
    -- meistens "0" sagt, liest nach zwei Malen niemand mehr.
    local warnung = WeintCodex.Label(f, "", { color = "danger", size = 13 })
    warnung:SetPoint("TOPLEFT", summe, "BOTTOMLEFT", 0, -4)
    warnung:SetWidth(840)
    warnung:SetJustifyH("LEFT")
    f._warnung = warnung

    local listBg = WeintCodex.CreateSurface(f, {
        width = 852, height = 350, tone = "flat", surface = "surface1",
        radius = 10, backdrop = "cardTop",
    })
    listBg:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -152)
    f._listBg = listBg

    local scroll, inner = WeintCodex.CreateScrollArea(listBg, 4, -6, 844, 338, true)
    f._inner = inner
    f._scroll = scroll
    f._rows = {}

    local fuss = WeintCodex.Label(f,
        "Sockelsteine setzt du selbst ein - WeintCodex zeigt nur, welche."
        .. " Umschmieden geht ueber |cffD4A24AAlles umschmieden|r beim Umschmieder.",
        { color = "textDim", size = 12 })
    fuss:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 24, 26)
    fuss:SetWidth(430)
    fuss:SetJustifyH("LEFT")
    f._fuss = fuss

    local ok = WeintCodex.CreateButton(f, {
        text = "Uebernehmen", kind = "primary", width = 160,
        backdrop = "cardBottom",
        onClick = function()
            local fn = f._onConfirm
            f._onConfirm = nil
            f:Hide()
            if fn then fn() end
        end,
    })
    ok:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 20)
    f._ok = ok

    local abbruch = WeintCodex.CreateButton(f, {
        text = "Abbrechen", kind = "secondary", width = 130,
        backdrop = "cardBottom",
        onClick = function()
            f._onConfirm = nil
            f:Hide()
        end,
    })
    abbruch:SetPoint("BOTTOMRIGHT", ok, "BOTTOMLEFT", -10, 3)

    return f
end

-- Eine Zeile des Bildlauffelds. Wiederverwendet statt neu erzeugt: das
-- Fenster geht bei jedem Import erneut auf, und Frames lassen sich in
-- WoW nicht wieder freigeben.
local function ConfirmRow(f, index)
    local C = WeintCodex.Colors
    local F = WeintCodex.Fonts

    if f._rows[index] then return f._rows[index] end

    local prev = f._rows[index - 1]
    local row = CreateFrame("Frame", nil, f._inner)
    row:SetSize(830, 34)
    if prev then
        row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2)
    else
        row:SetPoint("TOPLEFT", f._inner, "TOPLEFT", 6, -4)
    end

    row.name = row:CreateFontString(nil, "OVERLAY")
    row.name:SetFont(F.sansMedium, 12, "")
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
    row.name:SetWidth(92)
    row.name:SetJustifyH("LEFT")

    row.oben = row:CreateFontString(nil, "OVERLAY")
    row.oben:SetFont(F.sans, 12, "")
    row.oben:SetPoint("TOPLEFT", row, "TOPLEFT", 96, -1)
    row.oben:SetWidth(724)
    row.oben:SetJustifyH("LEFT")

    row.unten = row:CreateFontString(nil, "OVERLAY")
    row.unten:SetFont(F.sans, 11, "")
    row.unten:SetPoint("TOPLEFT", row.oben, "BOTTOMLEFT", 0, -2)
    row.unten:SetWidth(724)
    row.unten:SetJustifyH("LEFT")
    row.unten:SetTextColor(unpack(C.textDim))

    f._rows[index] = row
    return row
end

-- Zeigt den Eintrag zur Bestaetigung. `onConfirm` laeuft NUR, wenn der
-- Spieler "Uebernehmen" klickt.
-- Fuellt Zusammenfassung, Warnung und die Platz-fuer-Platz-Liste EINES
-- Zielzustands in EIN beliebiges Fenster - geteilt zwischen dem
-- Bestaetigungsfenster (TG.ShowConfirm, vor dem Uebernehmen) und der
-- Ankunfts-Zusammenfassung (TG.ShowArrival, danach, informativ). Beide
-- zeigen dieselbe Rechnung (TG.Compare); zwei Fassungen dieser
-- Fuellschleife liefen sonst irgendwann auseinander - genau die Sorte
-- Doppelung, die diese Datei an anderer Stelle vermeidet.
--
-- Erwartet ein Fenster mit `_summe`, `_warnung`, `_listBg`, `_inner`,
-- `_scroll`, `_rows` - beide Frame-Bauer unten legen das identisch an.
local function FillCompareArea(f, entry)
    local C = WeintCodex.Colors

    local vergleich = TG.Compare(entry)

    f._summe:SetText(string.format(
        "|cffD4A24A%d|r Plaetze · |cffD4A24A%d|r Sockelsteine · |cffD4A24A%d|r Umschmiedungen",
        entry.count or 0, entry.gemCount or 0, entry.reforgeCount or 0))
    f._summe:Show()

    if vergleich.stale > 0 then
        f._warnung:SetText(string.format(
            "%d Platz/Plaetze gelten NICHT: dort steckt ein anderes Teil"
            .. " als beim Simmen. Diese rechnet WeintCodex weiter selbst.",
            vergleich.stale))
        f._warnung:Show()
    else
        f._warnung:SetText("")
        f._warnung:Hide()
    end

    -- Zeilen fuellen. Alte werden versteckt, nicht geloescht.
    local used = 0
    for _, r in ipairs(vergleich.rows) do
        used = used + 1
        local row = ConfirmRow(f, used)
        row.name:SetText(r.name)

        if r.state == "stale" then
            row.name:SetTextColor(unpack(C.danger))
            row.oben:SetText(string.format(
                "|cffE56B6Bgilt nicht|r - Ziel %d, angelegt %d",
                r.targetItemId or 0, r.equippedItemId or 0))
            row.oben:SetTextColor(unpack(C.textMuted))
            row.unten:SetText("dieser Platz rechnet weiter selbst")
        elseif r.state == "none" then
            row.name:SetTextColor(unpack(C.textDim))
            row.oben:SetText("|cff6B6B74kein Ziel - rechnet weiter selbst|r")
            row.oben:SetTextColor(unpack(C.textDim))
            row.unten:SetText("")
        else
            row.name:SetTextColor(unpack(C.textNormal))
            row.oben:SetText("Sockel: "
                .. (#r.gemsIst > 0 and table.concat(r.gemsIst, ", ") or "-")
                .. "  |cffD4A24A->|r  "
                .. (r.gemsChanged and "|cffE8C96D" or "|cff6B6B74")
                .. (#r.gemsSoll > 0 and table.concat(r.gemsSoll, ", ") or "-")
                .. "|r")
            row.oben:SetTextColor(unpack(C.textMuted))
            row.unten:SetText("Umschmieden: " .. r.reforgeIstText
                .. "  |cffD4A24A->|r  "
                .. (r.reforgeChanged and "|cffE8C96D" or "|cff6B6B74")
                .. r.reforgeSollText .. "|r")
        end
        -- DIE HOEHE STEHT ERST FEST, WENN DER TEXT DRIN IST. Drei
        -- Steinnamen wie "Finsterer Bergkristall, Kunstvoller Aragonit"
        -- brechen um; mit fester Zeilenhoehe schiebt sich die naechste
        -- Zeile darueber - genau so gemeldet und im Bild zu sehen.
        local hoch = (row.oben:GetStringHeight() or 12)
        if row.unten:GetText() ~= "" then
            hoch = hoch + (row.unten:GetStringHeight() or 11) + 2
        end
        row:SetHeight(math.max(hoch + 8, 30))
        row:Show()
    end

    for i = used + 1, #f._rows do f._rows[i]:Hide() end

    -- Die Zeilen haengen aneinander, also ergibt sich die Gesamthoehe
    -- erst aus ihnen. Zu klein gesetzt, schneidet das Bildlauffeld die
    -- letzten Plaetze ab, ohne dass es jemand merkt.
    local gesamt = 10
    for i = 1, used do gesamt = gesamt + f._rows[i]:GetHeight() + 2 end
    f._inner:SetHeight(math.max(338, gesamt))
    f._scroll:SetVerticalScroll(0)

    f._listBg:Show()
    if f._fuss then f._fuss:Show() end
end

-- Blendet Zusammenfassung, Warnung und Liste aus - der Gegenpart zu
-- FillCompareArea, fuer den Fall, dass es keinen Zielzustand zu zeigen
-- gibt (TG.ShowArrival mit nur einer Gewichtung).
local function HideCompareArea(f)
    f._summe:SetText("")
    f._summe:Hide()
    f._warnung:SetText("")
    f._warnung:Hide()
    f._listBg:Hide()
    if f._fuss then f._fuss:Hide() end
    for _, row in ipairs(f._rows) do row:Hide() end
end

function TG.ShowConfirm(entry, onConfirm)
    if type(entry) ~= "table" then return false end
    if not (WeintCodex.MainFrame and WeintCodex.CreateSurface) then
        -- Ohne Oberflaeche keine Rueckfrage: dann gilt der Eintrag wie
        -- vor 3.0.3.0 sofort. Lieber uebernehmen als verlieren.
        if onConfirm then onConfirm() end
        return true
    end

    confirmFrame = confirmFrame or BuildConfirmFrame()
    local f = confirmFrame

    f._onConfirm = onConfirm

    local wann = ""
    if (tonumber(entry.created) or 0) > 0 and date then
        wann = " · " .. date("%d.%m.%Y", entry.created)
    end
    f._herkunft:SetText(SpecLabel(entry.spec)
        .. (entry.character ~= "" and (" · " .. entry.character) or "")
        .. " · " .. (entry.source or "wowsims") .. wann
        -- Die Kennung des Laufs steht dabei, damit eine Rueckfrage sie
        -- nennen kann. Sie muss niemandem auffallen; sie muss dastehen.
        .. (((entry.run or "") ~= "")
            and (" · " .. WeintCodex.ColorText("textDim", entry.run)) or ""))

    FillCompareArea(f, entry)

    f:Show()
    return true
end

--------------------------------------------------
-- DIE ANKUNFTS-ZUSAMMENFASSUNG (seit 3.2.0.1)
--------------------------------------------------
-- Ein zweites Fenster, INFORMATIV statt FRAGEND - siehe der lange
-- Kommentar bei SE.BeginArrival in modules/simexport.lua fuer den
-- Anlass. Es teilt sich die Platz-fuer-Platz-Liste mit dem
-- Bestaetigungsfenster oben (FillCompareArea), aber nicht den Frame:
-- dort steht "Uebernehmen/Abbrechen" vor einer Entscheidung, hier
-- "Verstanden" nach einer bereits getroffenen. Ein gemeinsamer,
-- wiederverwendeter Frame muesste diese beiden Zustaende bei jedem
-- Aufruf sauber auseinanderhalten - zwei kleine, gleich aufgebaute
-- Fenster sind hier das robustere Mittel als ein grosses mit Modus-
-- Schalter.
--------------------------------------------------

local arrivalFrame = nil

local function BuildArrivalFrame()
    local F = WeintCodex.Fonts
    local parent = WeintCodex.MainFrame

    local f = WeintCodex.CreateSurface(parent, {
        width = 900, height = 600, tone = "plain", radius = 14,
        backdrop = "bgDark",
    })
    f:SetPoint("CENTER", parent, "CENTER", 0, 0)
    f:SetFrameStrata("TOOLTIP")
    f:EnableMouse(true)
    f:Hide()

    local eyebrow = WeintCodex.Eyebrow(f, "Sim-Ergebnis")
    eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -20)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(F.sansBold, 20, "")
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)
    title:SetTextColor(unpack(WeintCodex.Colors.textBright))
    title:SetText("Das ist bei dir angekommen")
    f._title = title

    local herkunft = WeintCodex.Label(f, "", { color = "textMuted", size = 13 })
    herkunft:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    herkunft:SetWidth(840)
    herkunft:SetJustifyH("LEFT")
    f._herkunft = herkunft

    -- Die Gewichtung steht ALS EIGENE ZEILE ueber der Zusammenfassung
    -- des Zielzustands: beides kann unabhaengig voneinander da sein
    -- oder fehlen (ein Heiler-Lauf ueber QE Live kennt nur die erste),
    -- und keine der beiden darf die andere verdecken.
    local gewichtung = WeintCodex.Label(f, "", { color = "textNormal", size = 13 })
    gewichtung:SetPoint("TOPLEFT", herkunft, "BOTTOMLEFT", 0, -6)
    gewichtung:SetWidth(840)
    gewichtung:SetJustifyH("LEFT")
    f._gewichtung = gewichtung

    local summe = WeintCodex.Label(f, "", { color = "textNormal", size = 13 })
    summe:SetPoint("TOPLEFT", gewichtung, "BOTTOMLEFT", 0, -6)
    summe:SetWidth(840)
    summe:SetJustifyH("LEFT")
    f._summe = summe

    local warnung = WeintCodex.Label(f, "", { color = "danger", size = 13 })
    warnung:SetPoint("TOPLEFT", summe, "BOTTOMLEFT", 0, -4)
    warnung:SetWidth(840)
    warnung:SetJustifyH("LEFT")
    f._warnung = warnung

    -- Fester Abstand vom Fensteranfang, nicht von der Gewichtungszeile
    -- abhaengig - dieselbe Toleranz wie im Bestaetigungsfenster: eine
    -- leere Zeile darueber laesst etwas Luft, statt die Liste zu
    -- verschieben. 34 px tiefer als dort, fuer die zusaetzliche Zeile.
    local listBg = WeintCodex.CreateSurface(f, {
        width = 852, height = 350, tone = "flat", surface = "surface1",
        radius = 10, backdrop = "cardTop",
    })
    listBg:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -186)
    f._listBg = listBg

    local scroll, inner = WeintCodex.CreateScrollArea(listBg, 4, -6, 844, 338, true)
    f._inner = inner
    f._scroll = scroll
    f._rows = {}

    local fuss = WeintCodex.Label(f,
        "Sockelsteine setzt du selbst ein - WeintCodex zeigt nur, welche."
        .. " Umschmieden geht ueber |cffD4A24AAlles umschmieden|r beim Umschmieder.",
        { color = "textDim", size = 12 })
    fuss:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 24, 26)
    fuss:SetWidth(430)
    fuss:SetJustifyH("LEFT")
    f._fuss = fuss

    -- EIN KNOPF, KEIN "ABBRECHEN". Es gibt nichts abzubrechen - das
    -- hier ist eine Auskunft ueber etwas, das laengst uebernommen ist.
    local ok = WeintCodex.CreateButton(f, {
        text = "Verstanden", kind = "primary", width = 160,
        backdrop = "cardBottom",
        onClick = function() f:Hide() end,
    })
    ok:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 20)
    f._ok = ok

    return f
end

-- Die Gewichtung als eine Zeile - Spec und die Werte, wie sie im Spiel
-- unter Priorisierung liegen. `entry` ist ein SW.CleanEntry-Ergebnis
-- (id, spec, weights, character, source, created, run, startedAt).
local function WeightsLine(entry)
    if type(entry) ~= "table" or type(entry.weights) ~= "table" then
        return ""
    end

    local SW = WeintCodex.StatWeights
    local order  = (SW and SW.ORDER) or {}
    local labels = (SW and SW.LABELS) or {}

    local teile = {}
    for _, key in ipairs(order) do
        local value = tonumber(entry.weights[key])
        if value and value > 0 then
            teile[#teile + 1] = (labels[key] or key) .. " " .. value
        end
    end

    if #teile == 0 then return "" end

    return "|cffD4A24AGewichtung:|r " .. table.concat(teile, " · ")
end

-- Zeigt, was gerade angekommen ist - Gewichtung und/oder Zielzustand,
-- BEREITS UEBERNOMMEN. Anders als TG.ShowConfirm fragt dieses Fenster
-- nichts: entschieden hat der Spieler auf dem Desktop, hier geht es
-- nur um Sichtbarkeit - dieselbe Auskunft, die ein manueller Import
-- ueber TG.ShowConfirm sofort zeigt, hatte der Weg ueber die
-- Addon-Bruecke bisher nicht.
--
-- `arrival = { weights = <SW.CleanEntry-Ergebnis oder nil>,
--              target  = <TG.CleanEntry-Ergebnis oder nil> }`
-- Mindestens eins von beiden muss da sein.
function TG.ShowArrival(arrival)
    if type(arrival) ~= "table" then return false end

    local weights = arrival.weights
    local target  = arrival.target

    if not weights and not target then return false end

    if not (WeintCodex.MainFrame and WeintCodex.CreateSurface) then
        -- Ohne Oberflaeche keine Anzeige. Die Daten sind laengst
        -- uebernommen - hier entfaellt nur das Zeigen, nicht die
        -- Wirkung, dieselbe Zurueckhaltung wie in TG.ShowConfirm.
        return false
    end

    arrivalFrame = arrivalFrame or BuildArrivalFrame()
    local f = arrivalFrame

    -- HERKUNFT: aus dem Zielzustand, wenn er da ist - er nennt Spec,
    -- Charakter, Quelle und Datum genauer als die Gewichtung, die
    -- fuer jede Ausruestung gilt und deshalb weniger ueber EINEN Lauf
    -- aussagt. Ohne Zielzustand liefert die Gewichtung dieselben Felder.
    local quelle = target or weights

    local wann = ""
    if quelle and (tonumber(quelle.created) or 0) > 0 and date then
        wann = " · " .. date("%d.%m.%Y", quelle.created)
    end

    f._herkunft:SetText(SpecLabel(quelle and quelle.spec)
        .. (quelle and quelle.character ~= "" and (" · " .. quelle.character) or "")
        .. " · " .. (quelle and quelle.source or "wowsims") .. wann
        .. (quelle and ((quelle.run or "") ~= "")
            and (" · " .. WeintCodex.ColorText("textDim", quelle.run)) or ""))

    local gewichtungText = WeightsLine(weights)
    f._gewichtung:SetText(gewichtungText)
    if gewichtungText ~= "" then f._gewichtung:Show() else f._gewichtung:Hide() end

    if target then
        FillCompareArea(f, target)
    else
        -- Nur eine Gewichtung ist angekommen (z. B. ein Heiler-Lauf
        -- ueber QE Live, der keinen Zielzustand kennt) - keine
        -- Platz-fuer-Platz-Liste zu zeigen.
        HideCompareArea(f)
    end

    f:Show()
    return true
end
