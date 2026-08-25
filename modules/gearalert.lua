--------------------------------------------------
-- WeintCodex :: Ausrüstungs-Alarm
--
-- Grosse Einblendung in Bildschirmmitte, wenn ein frisch angelegtes
-- Teil weder verzaubert noch versockelt ist - und dieselbe Meldung als
-- Erinnerung, sobald man einen Ruhebereich betritt. Der Ruhebereich ist
-- dabei kein beliebiger Auslöser: dort steht der Verzauberer, dort ist
-- die Bank, dort kann man das auch tatsächlich erledigen. Im Raid davor
-- zu stehen bringt niemandem etwas.
--
-- SIE BLEIBT STEHEN, BIS MAN SIE WEGKLICKT - UND ERINNERT DANACH WIEDER
--
-- Das Wegklicken heisst "gesehen" und verschafft fünf Minuten Ruhe
-- (`ACK_LIFETIME`, `acked` in den SavedData). Danach erinnert der Alarm
-- erneut, solange die Lücke offen ist: sonst vergisst man sie schlicht
-- wieder, und genau dafür gibt es ihn. Dauerhaft still wird er, wenn
-- die Lücke behoben ist - oder über "/wc alarm aus".
--
-- Vier Anlässe bringen die Erinnerung zurück, alle durch dieselbe
-- Schleuse (`AmbientCheck`): ein Zonenwechsel, der Ruhebereich, der
-- Instanzeingang und ein Zeitgeber, damit es auch den erwischt, der
-- beim Taschensortieren an der Bank stehen bleibt.
--
-- **Aber nur, wenn man gerade nichts anderes macht** (`PlayerIsBusy`).
-- Kampf, Bosskampf, tot, Flugroute, Fahrzeug, Zaubern, Haustierkampf -
-- und Bewegung. Wer läuft, reitet oder fliegt, ist unterwegs und nicht
-- bei der Ausrüstung; dadurch landet die Erinnerung von selbst in dem
-- Moment, in dem man irgendwo stehen bleibt, und das ist genau der, in
-- dem man etwas tun kann.
--
-- Der Instanzeingang ist der einzige Anlass, der die Quittung übergeht
-- (`force`): er ist der letzte Moment, in dem sich die Lücke noch
-- schliessen lässt, und danach zählt sie eine Stunde lang bei jedem
-- Pull mit. `MIN_REPEAT` bleibt auch dort als Boden stehen, damit ein
-- zweiter Ladebildschirm die Meldung nicht Sekunden nach dem
-- Wegklicken zurückbringt.
--
-- Der Schlüssel trägt Art *und* Anzahl (`10|E|2|-`): wer die
-- Handschuhe verzaubert und dabei einen Sockel leer lässt, hat einen
-- anderen Befund als vorher und soll ihn auch sehen. Behobene
-- Schlüssel werden bei jedem Lauf verworfen (`PruneAcks`) - sonst
-- läge die Quittung noch da, wenn derselbe Slot Wochen später wieder
-- offen ist. `/wc alarm erneut` wirft alle Quittungen weg.
--
-- DREI SORTEN VON BEFUND, DIE NIE ZUSAMMENGEZÄHLT WERDEN
--
-- Fehlende Verzauberung, leerer Sockel, fehlender Sockelplatz
-- (Gürtelschnalle, Schmiede-Zusatzsockel) und ungenutzte
-- Berufsvergünstigung stehen nebeneinander. Zusammengezählt
-- verschwand die Gürtelschnalle in einem "3 Sockel leer", und wer das
-- las, wusste nicht, dass er dafür erst eine Schnalle kaufen muss -
-- ein leerer Sockel und ein fehlender Sockelplatz sind zwei
-- verschiedene Besorgungen.
--
-- Was ein Beruf zusätzlich hergibt, steht in data/professions.lua.
-- Entschieden wird dort ausschliesslich über Zählbares; kein Name und
-- keine Verzauberungs-ID aus jener Datei wird je verglichen. Die
-- Begründung steht in ihrem Kopf und ist die Lehre aus
-- data/enchants.lua.
--
-- ZWEI DINGE, DIE DIESE DATEI BEWUSST NICHT TUT
--
-- 1. Sie bewertet nicht. Gemeldet wird ausschliesslich "Verzauberung
--    fehlt" und "Sockel leer" - dieselbe Zurückhaltung wie im
--    Gruppencheck (modules/groupcheck.lua) und aus demselben Grund:
--    beides ist unstrittig, "nicht ideal" wäre eine Meinung. Eine
--    bildschirmfüllende Meldung über eine Meinung schaltet man nach
--    dem dritten Mal ab, und danach sieht man auch die echten
--    Mängel nicht mehr. Ob eine Verzauberung zur Spec passt, sagt
--    weiterhin nur die Charakterseite, wo man sie in Ruhe liest.
--
-- 2. Sie führt keine eigene Prüfung. Was offen ist, beantwortet
--    WeintCodex.Charakter.Scan() - dieselbe Liste der Slots, dieselbe
--    Auflösung des Verzauberungs-Topfes (inklusive "Ringe nur mit
--    Verzauberkunst") und dieselbe Sockelerkennung wie die
--    Charakterseite. Gelesen wird daraus aber nur `enchId == nil`
--    bzw. `socket.gemId == nil`, nicht der bewertete `status`: der
--    ist "neutral", wenn für den Slot keine Empfehlung existiert, und
--    ein fehlender Stein bleibt ein fehlender Stein, auch wenn das
--    Spec-Profil zu diesem Sockel nichts zu sagen hat.
--
-- WANN NICHTS KOMMT (jeder Punkt ist ein vermiedener Fehlalarm)
--
--  * Vor dem Login-Fenster. Weder Spec noch Item-Cache sind bei
--    PLAYER_LOGIN verlässlich; ein Scan zu diesem Zeitpunkt meldet
--    halb geladene Ausrüstung als Befund. Gewartet wird wie in
--    modules/companion.lua auf PLAYER_ENTERING_WORLD plus Vorlauf.
--  * Solange der Client die Basisdaten des Gegenstands nicht hat.
--    Dann steht die Prüfung an, statt zu raten - GET_ITEM_INFO_RECEIVED
--    gibt es hier nicht, also wird schlicht ein paar Sekunden später
--    noch einmal nachgesehen (RETRY_DELAY, RETRY_MAX).
--  * Unterhalb von Selten (blau). Wer ein Twinkset zusammensucht,
--    wechselt im Zehnminutentakt Gegenstände, die niemand verzaubert.
--    Ein grünes Teil zu melden wäre formal richtig und praktisch nur
--    Lärm - siehe MIN_QUALITY.
--  * Im Kampf. Die Meldung wartet auf PLAYER_REGEN_ENABLED, statt
--    sich über die Bossleiste zu legen; eine schon stehende weicht
--    dem Pull und kommt danach zurück, falls der Befund noch steht.
--
-- Abschalten: /wc alarm aus. Der Hinweis steht in der Meldung selbst;
-- eine Einblendung, die man nicht loswird, ohne die Dokumentation zu
-- lesen, ist eine Zumutung.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.GearAlert = {}

local GA = WeintCodex.GearAlert

local C          = WeintCodex.Colors
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder
local F          = WeintCodex.Fonts
local Upper      = WeintCodex.Upper
local Truncate   = WeintCodex.Truncate

--------------------------------------------------
-- Konstanten
--------------------------------------------------

-- Ab welcher Gegenstandsqualität überhaupt gemeldet wird. 3 = Selten
-- (blau). Alles darunter ist in MoP Übergangsware: der Weg von 85 auf
-- 90 besteht aus Grün, und wer dabei verzaubert, wirft das Material
-- weg. Blau ist die erste Stufe, bei der sich die Frage stellt.
local MIN_QUALITY = 3

-- Ein vollständiger Scan liest je Gegenstand den Tooltip, und beim
-- Umsockeln feuert PLAYER_EQUIPMENT_CHANGED mehrfach hintereinander -
-- dieselbe Überlegung wie beim Ausrüstungsbericht der Companion.
local EQUIP_DEBOUNCE = 2.5

-- Vorlauf nach dem Betreten der Welt, bis der Item-Cache warm ist.
local ENTER_WORLD_DELAY = 10

-- Noch nicht gecachte Gegenstände: kurz warten, ein paar Mal.
local RETRY_DELAY = 3
local RETRY_MAX   = 3

-- Wie lange eine Quittung hält. Danach erinnert der Alarm erneut -
-- ohne das vergisst man die Lücke schlicht wieder, und genau dafür
-- gibt es ihn. Wer sie dauerhaft loswerden will, behebt sie oder
-- schaltet über "/wc alarm aus" ab.
local ACK_LIFETIME = 300

-- Untergrenze zwischen zwei Meldungen desselben Befunds. Sie greift
-- auch dort, wo die Quittung übergangen wird (Instanzeingang): ohne
-- diesen Boden könnte ein zweiter Ladebildschirm die Meldung Sekunden
-- nach dem Wegklicken zurückbringen.
local MIN_REPEAT = 60

-- Frühestens so oft läuft eine Prüfung, die niemand ausgelöst hat
-- (Zeitgeber, Zonenwechsel, Ruhebereich). Kostenbremse: jede Prüfung
-- liest je Gegenstand den Tooltip.
local AMBIENT_THROTTLE = 300

-- Takt des Zeitgebers und Wartezeit, wenn der Spieler gerade etwas
-- anderes tut. Der Takt ist deutlich kürzer als AMBIENT_THROTTLE,
-- damit die Erinnerung im ERSTEN ruhigen Moment nach den fünf Minuten
-- kommt und nicht erst beim nächsten vollen Takt danach.
local TICK       = 60
local BUSY_RETRY = 30

local WIDTH   = 470
local PAD     = 16
local ICON_SZ = 44
local ROW_H   = 17
local MAX_ROWS = 6

-- Einblenden, halten, ausblenden.
local FADE_IN  = 0.22
local SLIDE    = 14

--------------------------------------------------
-- Einstellungen
--------------------------------------------------

local DEFAULTS = {
    enabled      = true,
    sound        = true,
    restReminder = true,
}

-- SavedData steht erst ab ADDON_LOADED bereit; deshalb bei jedem
-- Zugriff neu nachsehen, statt die Tabelle in einer Dateilokalen
-- festzuhalten (siehe core/access.lua für dieselbe Regel).
local function Store()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local s = WeintCodex.SavedData.gearAlert
    if not s then
        s = {}
        WeintCodex.SavedData.gearAlert = s
    end
    for key, value in pairs(DEFAULTS) do
        if s[key] == nil then s[key] = value end
    end
    return s
end

--------------------------------------------------
-- Was ist offen?
--------------------------------------------------

-- Ergebnis je Slot: nehmen, überspringen oder warten. "Warten" ist der
-- Grund, warum diese Funktion drei Werte kennt und nicht zwei: ein
-- Gegenstand, dessen Basisdaten noch nicht da sind, hat keine
-- Qualität - ihn deshalb zu überspringen hiesse, eine Aussage über
-- unseren Cache als Aussage über die Rüstung auszugeben.
local TAKE, SKIP, WAIT = 1, 2, 3

local function SlotVerdict(link)
    if not link then return SKIP end
    local name, _, quality = GetItemInfo(link)
    if not name or quality == nil then return WAIT end
    if quality < MIN_QUALITY then return SKIP end
    return TAKE
end

--------------------------------------------------
-- Berufsvergünstigungen: eine Entscheidung, zwei Leser
--------------------------------------------------
-- Diese Funktion ist die einzige Stelle, an der beantwortet wird, ob
-- eine Vergünstigung genutzt ist. Collect() baut daraus Befunde,
-- "/wc alarm berufe" druckt sie samt Begründung aus - eine zweite
-- Fassung wäre genau die Doppelpflege, an der die
-- Verzauberungserkennung in diesem Addon schon einmal gescheitert ist.
--
-- Rückgabe: used (true / false / nil = nicht feststellbar), detail
-- (was gelesen wurde, im Klartext).

local function PerkMinSkill(perk)
    return perk.minSkill or WeintCodex_ProfessionMinSkill or 500
end

--------------------------------------------------
-- Liegt an diesem Gegenstand eine Bastelei?
--------------------------------------------------
-- Der Ingenieurs-Gürtel hat gezeigt, dass die naheliegende Antwort
-- falsch ist: der Nitrobooster steht NICHT im Verzauberungsfeld des
-- Item-Links. Ein Gürtel, auf dem er nachweislich liegt (Tooltip:
-- "Benutzen: Erhöht 5 Sek. lang Euer Lauftempo enorm"), meldete
-- "keine Verzauberung im Item-Link" - nachgewiesen mit
-- "/wc alarm berufe" am gemeldeten Charakter.
--
-- Gefragt wird deshalb zusätzlich am Tooltip, und zwar über die
-- Differenz: trägt der ANGELEGTE Gegenstand eine "Benutzen:"-Zeile,
-- die sein GRUNDgegenstand nicht hat, wurde etwas angebracht. Das ist
-- die einzige Frage, die ohne Namen und ohne IDs auskommt - und die
-- Beschriftung kommt aus der Konstanten des Clients, nicht von uns.
--
-- Steine und Aufwertungsgrade stören dabei nicht: die fügen keine
-- "Benutzen:"-Zeile hinzu.

local alertTip
local function AlertTip()
    if alertTip then return alertTip end
    alertTip = CreateFrame("GameTooltip", "WeintCodexAlertTip", nil, "GameTooltipTemplate")
    alertTip:SetOwner(UIParent, "ANCHOR_NONE")
    return alertTip
end

-- Beschriftung des Clients ("Benutzen: %s"), nicht unsere.
local USE_PREFIX = (_G.ITEM_SPELL_TRIGGER_ONUSE or "Benutzen")
    :gsub("%%s.*$", ""):gsub("%s*$", "")

-- true / false / nil (Tooltip nicht lesbar)
local function TipHasUseLine(apply)
    local tip = AlertTip()
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()

    local ok = pcall(apply, tip)
    if not ok then return nil end

    local n = tip:NumLines() or 0
    if n == 0 then return nil end

    for i = 2, n do
        local line = _G["WeintCodexAlertTipTextLeft" .. i]
        local txt = line and line:GetText()
        if txt and USE_PREFIX ~= "" and txt:find(USE_PREFIX, 1, true) then
            return true
        end
    end
    return false
end

-- true  = am angelegten Gegenstand wurde etwas angebracht
-- false = nichts angebracht
-- nil   = nicht feststellbar (Tooltip noch nicht lesbar)
local function HasAppliedUseEffect(slotId, link)
    local equipped = TipHasUseLine(function(tip)
        tip:SetInventoryItem("player", slotId)
    end)
    if equipped ~= true then return equipped end

    -- Der Grundgegenstand ohne alles. Hat der dieselbe Zeile, gehört
    -- sie zum Gegenstand und nicht zu einem Beruf.
    local itemId = link and link:match("item:(%d+)")
    if not itemId then return nil end

    local base = TipHasUseLine(function(tip)
        tip:SetHyperlink("item:" .. itemId)
    end)
    if base == nil then return nil end

    return not base
end

local function CountJewelcrafterGems()
    local CH = WeintCodex.Charakter
    local n = 0
    for _, slotDef in ipairs(CH.EquipSlots or {}) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link then
            local _, gems = CH.ParseItemLink(link)
            for _, gemId in pairs(gems) do
                local db = WeintCodex_Gems and WeintCodex_Gems[gemId]
                if db and db.jcOnly then n = n + 1 end
            end
        end
    end
    return n
end

local function PerkState(perk, link, jcCount)
    local CH = WeintCodex.Charakter

    if perk.kind == "gems" then
        local need = perk.count or 0
        local have = jcCount or 0
        return have >= need, have .. " von " .. need .. " eingesetzt"
    end

    if not link then return nil, "kein Gegenstand angelegt" end

    if perk.kind == "exclusive" then
        -- Zwei Wege, in dieser Reihenfolge. Der erste ist der billige:
        -- steht im Verzauberungsfeld des Item-Links etwas, ist auf einem
        -- Gürtel nur die Bastelei des Ingenieurs möglich.
        local enchId = CH.ParseItemLink(link)
        if enchId then
            return true, "Verzauberung im Item-Link: " .. enchId
        end

        -- Der zweite ist der tragende: der Nitrobooster landet NICHT im
        -- Verzauberungsfeld (siehe HasAppliedUseEffect). Ohne diesen Weg
        -- meldete der Alarm ihn dauerhaft als fehlend.
        local applied = HasAppliedUseEffect(perk.slotId, link)
        if applied == true then
            return true, "keine Verzauberung im Item-Link, aber eine"
                .. " Benutzen-Zeile, die der Grundgegenstand nicht hat"
        end
        if applied == nil then
            return nil, "keine Verzauberung im Item-Link, Tooltip noch"
                .. " nicht lesbar"
        end
        return false, "keine Verzauberung im Item-Link und keine"
            .. " zusätzliche Benutzen-Zeile im Tooltip"
    end

    if perk.kind == "socket" then
        local sockets, known = CH.ScanItemSockets(link, perk.slotId)
        if not known then return nil, "Item-Basisdaten noch nicht geladen" end
        local base = 0
        for _, sock in ipairs(sockets) do
            if not sock.extra then base = base + 1 end
        end
        local _, gems = CH.ParseItemLink(link)
        local extra = gems[base + 1]
        return extra ~= nil,
            base .. " eingebaute Sockel, Zusatzsockel "
            .. (extra and ("belegt (Stein " .. extra .. ")") or "leer oder nicht angebracht")
    end

    return nil, nil
end

-- Die Sammelstelle der Juwelierssteine hat keinen Slot; sie steht ans
-- Ende der Liste.
local JC_PSEUDO_SLOT = 100

-- Rückgabe: entries (nach Slot sortiert), pending (mindestens ein
-- Gegenstand war noch nicht im Cache), hints (Berufsmöglichkeiten zu
-- ohnehin fehlenden Verzauberungen).
local function Collect()
    if not (WeintCodex.Charakter and WeintCodex.Charakter.Scan) then
        return nil, false
    end

    -- Der Scan liest gecachte Tooltip-Ergebnisse; nach einem
    -- Ausrüstungswechsel wären das die von vorhin.
    if WeintCodex.Charakter.ClearCache then
        WeintCodex.Charakter.ClearCache()
    end

    local ok, scan = pcall(WeintCodex.Charakter.Scan)
    if not ok or type(scan) ~= "table" then return nil, false end

    local bySlot, entries, pending = {}, {}, false
    local verdicts, links = {}, {}
    local hints = {}

    local function Verdict(slotId)
        local v = verdicts[slotId]
        if v then return v end
        links[slotId] = GetInventoryItemLink("player", slotId)
        v = SlotVerdict(links[slotId])
        verdicts[slotId] = v
        return v
    end

    local function Entry(slotId, slotName)
        local e = bySlot[slotId]
        if e then return e end
        e = {
            slotId   = slotId,
            slotName = slotName,
            link     = links[slotId],
            enchant  = false,
            sockets  = 0,
            buckle   = false,
            perks    = {},
        }
        bySlot[slotId] = e
        entries[#entries + 1] = e
        return e
    end

    for _, row in ipairs(scan.enchants and scan.enchants.rows or {}) do
        if not row.enchId then
            local v = Verdict(row.slotId)
            if v == WAIT then
                pending = true
            elseif v == TAKE then
                Entry(row.slotId, row.slotName).enchant = true
            end
        end
    end

    for _, row in ipairs(scan.gems and scan.gems.rows or {}) do
        local socket = row.socket
        -- socketsKnown == false heisst: der Client kannte die Basisdaten
        -- des Gegenstands nicht, die eingebauten Sockel sind damit
        -- unbekannt. Übrig bliebe nur die geratene Gürtelschnalle.
        if socket and not socket.gemId and row.socketsKnown ~= false then
            local v = Verdict(row.slotId)
            if v == WAIT then
                pending = true
            elseif v == TAKE then
                local e = Entry(row.slotId, row.slotName)
                -- Die Schnalle wird getrennt geführt und NICHT in die
                -- Sockelzahl eingerechnet. Zusammengezählt verschwand
                -- sie in einem "3 Sockel leer", und wer das las, wusste
                -- nicht, dass er dafür eine Gürtelschnalle kaufen muss -
                -- ein leerer Sockel und ein fehlender Sockelplatz sind
                -- zwei verschiedene Besorgungen.
                if socket.buckle then
                    e.buckle = true
                else
                    e.sockets = e.sockets + 1
                end
            end
        end
    end

    --------------------------------------------------
    -- Berufsvergünstigungen (data/professions.lua)
    --------------------------------------------------
    -- Was der Charakter dürfte und nicht hat. Entschieden wird
    -- ausschliesslich über Zählbares - siehe den Kopf jener Datei.
    -- Die Entscheidung je Vergünstigung liegt in PerkState (oben),
    -- damit "/wc alarm berufe" genau das ausgibt, was hier gilt, statt
    -- eine zweite Lesart derselben Frage zu führen.

    local CH = WeintCodex.Charakter

    if WeintCodex_ProfessionPerks and WeintCodex_GetProfessionSkills
       and CH.ParseItemLink and CH.ScanItemSockets then

        local skills  = WeintCodex_GetProfessionSkills()
        local jcCount = nil

        for skillLine, prof in pairs(WeintCodex_ProfessionPerks) do
            local level = skills[skillLine]
            for _, perk in ipairs(prof.perks or {}) do
                if level and level >= PerkMinSkill(perk) then

                    if perk.kind == "hint" then
                        -- Nur, wenn die Verzauberung ohnehin fehlt: ob
                        -- dort schon die stärkere Berufsvariante liegt,
                        -- ist ohne verlässliche IDs nicht zu sagen, und
                        -- "du könntest was Besseres tragen" wäre das
                        -- Urteil, das dieses Modul nicht fällt.
                        local e = bySlot[perk.slotId]
                        if e and e.enchant then
                            hints[#hints + 1] = prof.name .. ": "
                                .. perk.label .. " (" .. perk.slotName .. ")"
                        end

                    elseif perk.kind == "gems" then
                        jcCount = jcCount or CountJewelcrafterGems()
                        local used, detail = PerkState(perk, nil, jcCount)
                        if used == false then
                            local e = Entry(JC_PSEUDO_SLOT, prof.name)
                            e.perks[#e.perks + 1] = {
                                label = perk.label,
                                text  = perk.label .. ": " .. detail,
                            }
                        end

                    else
                        local v = Verdict(perk.slotId)
                        if v == WAIT then
                            pending = true
                        elseif v == TAKE then
                            local used = PerkState(perk, links[perk.slotId])
                            if used == nil then
                                pending = true
                            elseif used == false then
                                local e = Entry(perk.slotId, perk.slotName)
                                e.perks[#e.perks + 1] = {
                                    label = perk.label,
                                    text  = (perk.kind == "socket")
                                        and (perk.label .. " fehlt oder ist leer")
                                        or  (perk.label .. " fehlt"),
                                }
                            end
                        end
                    end

                end
            end
        end
    end

    -- EQUIP_SLOTS läuft nach Slot-ID aufsteigend; danach sortiert steht
    -- die Liste in derselben Reihenfolge wie auf der Charakterseite.
    table.sort(entries, function(a, b) return a.slotId < b.slotId end)

    return entries, pending, hints
end

GA.Collect = Collect

--------------------------------------------------
-- Quittungen ("gesehen")
--------------------------------------------------

-- Art UND Anzahl gehören in den Schlüssel: aus "Verzauberung fehlt und
-- zwei Sockel leer" wird nach dem Verzaubern "zwei Sockel leer", und das
-- ist ein anderer Befund, der wieder gemeldet werden soll. Schnalle und
-- Berufsvergünstigungen zählen mit, aus demselben Grund.
--
-- Die Berufs-HINWEISE stehen bewusst nicht drin: sie sind kein eigener
-- Befund, sondern ein Zusatz an einem, den es ohnehin gibt.
local function FindingKey(e)
    local parts = {
        e.slotId,
        e.enchant and "E" or "-",
        e.sockets,
        e.buckle and "B" or "-",
    }
    for _, perk in ipairs(e.perks or {}) do
        parts[#parts + 1] = "P:" .. tostring(perk.label)
    end
    return table.concat(parts, "|")
end

local function AckStore()
    local s = Store()
    s.acked = s.acked or {}
    return s.acked
end

-- Gespeichert wird der Zeitpunkt, nicht ein "ja". Eine Quittung ohne
-- Zeitpunkt (so schrieb 2.4.0.2) gilt als abgelaufen - das ist die
-- richtige Richtung: nach dem Update erinnert der Alarm einmal, statt
-- eine alte Zustimmung für immer weiterzutragen.
local function Acknowledge(entries)
    local acked = AckStore()
    local now = time()
    for _, e in ipairs(entries or {}) do
        acked[FindingKey(e)] = now
    end
end

-- Behobene Befunde vergessen. Ohne das läge die Quittung noch da, wenn
-- derselbe Slot Wochen später wieder offen ist - und die Tabelle wüchse
-- über jeden Ausrüstungswechsel hinweg weiter.
--
-- Läuft immer gegen das VOLLSTÄNDIGE Ergebnis von Collect(), nie gegen
-- die auf einzelne Slots gefilterte Liste: sonst würde eine Prüfung nach
-- dem Anlegen eines Rings die Quittungen aller anderen Slots wegwerfen.
--
-- Und nur, wenn der Client zu JEDEM Gegenstand Basisdaten hatte (siehe
-- den Aufruf). Ein ungecachter Gegenstand fehlt in `all`, sein Befund
-- sähe damit behoben aus, und die Quittung wäre weg - kurz darauf käme
-- dieselbe Meldung wieder, die man gestern weggeklickt hat. Dieselbe
-- Regel wie überall sonst in dieser Datei: aus unserem Ladezustand
-- folgt keine Aussage über die Rüstung.
local function PruneAcks(all)
    local acked = AckStore()
    local live = {}
    for _, e in ipairs(all) do live[FindingKey(e)] = true end
    for key in pairs(acked) do
        if not live[key] then acked[key] = nil end
    end
end

-- force = true: der Anlass wiegt schwerer als die Quittung (der
-- Instanzeingang ist der letzte Moment, in dem die Lücke noch zu
-- schliessen ist). Der Boden MIN_REPEAT gilt trotzdem.
local function IsAcked(e, force)
    local at = AckStore()[FindingKey(e)]
    if type(at) ~= "number" then return false end
    local age = time() - at
    if age < 0 then return true end          -- Uhr verstellt: nicht nerven
    return age < (force and MIN_REPEAT or ACK_LIFETIME)
end

--------------------------------------------------
-- Texte
--------------------------------------------------

-- Die drei Sorten stehen nebeneinander und werden nie zusammengezählt:
-- ein leerer Sockel, ein fehlender Sockelplatz und eine ungenutzte
-- Berufsvergünstigung sind drei verschiedene Besorgungen.
local function EntryFinding(e)
    local parts = {}
    if e.enchant then parts[#parts + 1] = "Verzauberung fehlt" end
    if e.buckle  then parts[#parts + 1] = "Gürtelschnalle fehlt" end
    if e.sockets == 1 then
        parts[#parts + 1] = "1 Sockel leer"
    elseif e.sockets > 1 then
        parts[#parts + 1] = e.sockets .. " Sockel leer"
    end
    for _, perk in ipairs(e.perks or {}) do
        parts[#parts + 1] = perk.text
    end
    return table.concat(parts, " · ")
end

local function ItemNameOf(e)
    return e.link and e.link:match("|h%[(.-)%]|h") or nil
end

-- Überschrift und Unterzeile der Einblendung. Ein einzelnes Teil nennt
-- den Befund gross und den Gegenstand darunter; mehrere nennen die Zahl,
-- weil "VERZAUBERUNG FEHLT" über einer Liste aus fünf Zeilen die falsche
-- Aussage wäre.
local function Headline(entries, reason)
    if #entries == 1 then
        local e = entries[1]
        local kinds = 0
        if e.enchant     then kinds = kinds + 1 end
        if e.buckle      then kinds = kinds + 1 end
        if e.sockets > 0 then kinds = kinds + 1 end
        if #e.perks > 0  then kinds = kinds + 1 end

        local title
        if kinds > 1 then
            title = "Am Ausrüstungsteil fehlt noch etwas"
        elseif e.enchant then
            title = "Verzauberung fehlt"
        elseif e.buckle then
            title = "Gürtelschnalle fehlt"
        elseif e.sockets > 0 then
            title = "Sockel noch leer"
        else
            title = "Berufsvorteil ungenutzt"
        end

        -- Bei mehr als einer Sorte sagt die Überschrift nur, DASS etwas
        -- offen ist; was genau, steht dann in der Unterzeile.
        local item = ItemNameOf(e)
        local where = item
            and (Truncate(item, 38) .. "  ·  " .. e.slotName)
            or  e.slotName
        local sub = (kinds > 1 or #e.perks > 0)
            and (where .. "  ·  " .. EntryFinding(e))
            or  where
        return title, sub
    end

    local title = (reason == "equip")
        and (#entries .. " angelegte Teile sind offen")
        or  (#entries .. " Teile brauchen noch etwas")

    local ench, sock, buckle, perks = 0, 0, 0, 0
    for _, e in ipairs(entries) do
        if e.enchant then ench   = ench + 1 end
        if e.buckle  then buckle = buckle + 1 end
        sock  = sock + e.sockets
        perks = perks + #(e.perks or {})
    end

    local bits = {}
    if ench > 0 then
        bits[#bits + 1] = (ench == 1) and "1 Verzauberung fehlt"
                                      or  (ench .. " Verzauberungen fehlen")
    end
    if buckle > 0 then
        bits[#bits + 1] = "Gürtelschnalle fehlt"
    end
    if sock > 0 then
        bits[#bits + 1] = (sock == 1) and "1 Sockel ist leer"
                                      or  (sock .. " Sockel sind leer")
    end
    if perks > 0 then
        bits[#bits + 1] = (perks == 1) and "1 Berufsvorteil ungenutzt"
                                       or  (perks .. " Berufsvorteile ungenutzt")
    end

    return title, table.concat(bits, "  ·  ")
end

--------------------------------------------------
-- Ton
--------------------------------------------------
-- Der Alarm hatte von Anfang an einen Ton, und er hat nie geklungen. Beide
-- Aufrufformen, die hier standen, sind auf dem Client, auf dem Mists Classic
-- laeuft, tot:
--
--   * PlaySoundFile("Sound\\Interface\\RaidWarning.wav") - Pfade IN die
--     Spieldaten loest der Client seit der Umstellung auf CASC nicht mehr
--     auf. PlaySoundFile kennt nur noch Dateien aus einem Addon-Ordner oder
--     eine FileDataID; der Aufruf gibt still `false` zurueck.
--   * PlaySound("RaidWarning") - PlaySound will eine NUMERISCHE SoundKit-ID.
--     Der Kit-Name als Zeichenkette war die Form des alten 5.x-Clients.
--
-- Und weil beides in pcall stand und niemand den Rueckgabewert ansah, war
-- das Ergebnis genau ein stiller Alarm: in den Einstellungen stand "Ton: an",
-- der Code lief sauber durch, und es passierte nichts. **Ein Rueckfallweg,
-- dessen Zweige alle schweigend scheitern koennen, ist kein Rueckfallweg** -
-- dieselbe Lehre wie beim Nitrobooster in 2.4.1.2.
--
-- Deshalb drei Aenderungen, und keine davon ist Geschmack:
--   * Die ID kommt aus der Tabelle des CLIENTS (SOUNDKIT) und nie aus einem
--     Namen von uns. Die Zahl daneben ist nur der Rueckfall, falls der
--     Client die Tabelle nicht fuehrt - sie steht NEBEN dem Namen, nicht
--     statt seiner, damit der Client entscheidet, solange er kann.
--   * Der Rueckgabewert wird ausgewertet. `willPlay == false` heisst, dass
--     nichts geklungen hat, und dann wird der naechste Klang probiert.
--   * Was tatsaechlich gespielt wurde, ist ablesbar (`/wc alarm` und die
--     Schaltflaeche "Ton testen" auf der Einstellungsseite). Genau diese
--     Fehlerklasse - "der Code laeuft, nur hoert man nichts" - ist von
--     aussen sonst nicht von "Lautstaerke auf 0" zu unterscheiden.
--------------------------------------------------

-- Reihenfolge: der Warnton des Raids, sonst der Bereitschaftscheck, sonst
-- der Hinweiston der Benutzeroberflaeche. Alle drei fuehrt der Client
-- selbst; die Zahlen sind seine, nicht unsere.
local SOUND_KITS = {
    { name = "RAID_WARNING",  id = 8959 },
    { name = "READY_CHECK",   id = 8960 },
    { name = "IG_MAINMENU_OPEN", id = 850 },
}

-- Was der letzte Versuch ergeben hat. Reine Diagnose - siehe PrintStatus.
local soundNote = "noch nicht gespielt"

-- Spielt den Alarmton, unabhaengig von der Einstellung. Gibt zurueck, ob
-- etwas geklungen hat, und eine Zeile, die sagt was.
function GA.PlaySignal()
    if type(PlaySound) ~= "function" then
        soundNote = "PlaySound gibt es auf diesem Client nicht"
        return false, soundNote
    end

    local kit = _G.SOUNDKIT
    for _, entry in ipairs(SOUND_KITS) do
        local id = (type(kit) == "table" and tonumber(kit[entry.name])) or entry.id
        local source = (type(kit) == "table" and tonumber(kit[entry.name]))
            and "SOUNDKIT" or "Rueckfallzahl"

        -- PlaySound(id, channel) liefert willPlay, soundHandle. "Master"
        -- ist Absicht: der Alarm soll auch zu hoeren sein, wenn jemand die
        -- Effektlautstaerke heruntergezogen hat - er meldet eine Luecke,
        -- die einen ganzen Raidabend kostet.
        local ok, willPlay = pcall(PlaySound, id, "Master")
        if ok and willPlay ~= false then
            soundNote = entry.name .. " (" .. id .. ", " .. source .. ")"
            return true, soundNote
        end
    end

    soundNote = "kein Klang des Clients liess sich abspielen"
    return false, soundNote
end

function GA.SoundNote()
    return soundNote
end

local function PlayAlertSound()
    if not Store().sound then
        soundNote = "abgeschaltet"
        return false
    end
    return (GA.PlaySignal())
end

--------------------------------------------------
-- Einblendung
--------------------------------------------------

local frame, icon, eyebrow, headline, subline, hintLine, hint
local rowLabels = {}
local anim = { state = nil, elapsed = 0, hold = 0 }
local moveMode = false

local function SavePosition()
    if not frame then return end
    local point, _, _, x, y = frame:GetPoint()
    if not point then return end
    Store().pos = { point = point, x = x, y = y }
end

local function RestorePosition()
    local pos = Store().pos
    frame:ClearAllPoints()
    if pos and pos.point then
        frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -170)
    end
end

local function NewText(font, size, color, justify)
    local fs = frame:CreateFontString(nil, "OVERLAY")
    fs:SetFont(font, size, "")
    fs:SetTextColor(C[color][1], C[color][2], C[color][3])
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

local function OpenCharakterPage(entries)
    local nav = WeintCodex.Navigation
    if not (WeintCodex.MainFrame and nav) then return end
    WeintCodex.MainFrame:Show()

    -- Erst den Bereich betreten, dann die Unterseite - dieselbe
    -- Reihenfolge wie in core/search.lua. Ueber GoToTab statt SwitchTo,
    -- damit die Navigationsspalte den Eintrag auch markiert (siehe die
    -- Begruendung an GoToTab in core/navigation.lua).
    if nav.GoToTab then
        nav.GoToTab("charakter")
    elseif nav.SwitchTo then
        nav.SwitchTo("charakter")
    end

    -- Auf die Seite, die zum Befund gehört: wer nur leere Sockel hat,
    -- will nicht auf der Verzauberungsseite landen.
    local anyEnchant = false
    for _, e in ipairs(entries or {}) do
        if e.enchant then anyEnchant = true; break end
    end

    local CH = WeintCodex.Charakter
    if not CH then return end
    if not anyEnchant and CH.ShowGems then
        CH.ShowGems()
    elseif CH.ShowEnchants then
        CH.ShowEnchants()
    end
end

local function Build()
    if frame then return end

    frame = CreateFrame("Button", "WeintCodexGearAlert", UIParent)
    frame:SetSize(WIDTH, 120)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:RegisterForDrag("LeftButton")
    frame:Hide()

    -- Bewusst ohne CutCorners: hinter dieser Fläche liegt die Spielwelt,
    -- und die Eckmasken brauchen die Farbe des Untergrunds. Aus demselben
    -- Grund bleibt auch das Hauptfenster eckig (siehe core/ui.lua).
    SetSolidBg(frame, C.bgDark[1], C.bgDark[2], C.bgDark[3], 0.95)
    DrawBorder(frame, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)

    -- Bernsteinfarbene Oberkante: die Hausform der Karte, hier zwei
    -- Pixel stark, weil das hier ein Befund ist und keine Seite.
    local accent = frame:CreateTexture(nil, "OVERLAY")
    accent:SetHeight(2)
    accent:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    accent:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1.0)

    -- Weicher Schimmer darunter, damit die Fläche über hellem Gelände
    -- nicht als grauer Kasten liest.
    local glow = frame:CreateTexture(nil, "ARTWORK")
    glow:SetHeight(46)
    glow:SetPoint("TOPLEFT",  frame, "TOPLEFT",  1, -2)
    glow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -2)
    WeintCodex.ApplyVerticalGradient(glow,
        { C.accent[1], C.accent[2], C.accent[3], 0.14 },
        { C.accent[1], C.accent[2], C.accent[3], 0.00 })

    icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SZ, ICON_SZ)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD - 4)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    eyebrow  = NewText(F.mono,     10, "textDim")
    headline = NewText(F.sansBold, 20, "accentBright")
    subline  = NewText(F.sans,     12, "textMuted")
    hintLine = NewText(F.sans,     10, "textMuted")
    hint     = NewText(F.sans,      9, "textFaint")

    frame:SetScript("OnDragStart", function(self)
        if not moveMode then return end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    frame:SetScript("OnClick", function(self, button)
        -- Der Ziehmodus quittiert nichts: dort geht es um die Position,
        -- nicht um den Befund (die Beispielmeldung kann sogar erfunden
        -- sein, siehe ShowMover).
        if moveMode then
            moveMode = false
            GA.Hide()
            print(WeintCodex.ColorText("gold", "[WeintCodex]")
                .. " Position des Ausrüstungs-Alarms gespeichert.")
            return
        end

        -- Beide Klicks heissen "gesehen". Der Linksklick führt zusätzlich
        -- dorthin, wo sich das beheben lässt; wer den Weg kennt, nimmt
        -- den Rechtsklick.
        local entries = self._entries
        GA.Dismiss()
        if button ~= "RightButton" then
            OpenCharakterPage(entries)
        end
    end)

    frame:SetScript("OnUpdate", function(self, elapsed)
        if not anim.state then return end
        anim.elapsed = anim.elapsed + elapsed

        if anim.state == "in" then
            local t = math.min(1, anim.elapsed / FADE_IN)
            self:SetAlpha(t)
            -- ClearAllPoints ist Pflicht: SetPoint ergaenzt, es ersetzt
            -- nicht, und ein Frame mit 20 Ankern pro Sekunde steht am
            -- Ende irgendwo.
            self:ClearAllPoints()
            self:SetPoint(anim.point, UIParent, anim.point,
                anim.x, anim.y - SLIDE * (1 - t))
            if t >= 1 then
                anim.state, anim.elapsed = "hold", 0
            end

        elseif anim.state == "hold" then
            -- Und hier bleibt sie. Weggeräumt wird sie nur durch einen
            -- Klick (siehe Dismiss), durch den Kampfbeginn oder durch
            -- "/wc alarm aus" - nie durch Zeitablauf.
            anim.state = nil
        end
    end)

    RestorePosition()
end

-- Gemessene Zeilenhoehe statt geschaetzter. Die Textfelder sind links
-- UND rechts verankert, brechen also um, sobald eine Ueberschrift breiter
-- ist als die Flaeche - mit festen Abstaenden laege der Rest darunter
-- ineinander. Dieselbe Reihenfolge wie in core/onboarding.lua: erst den
-- Text setzen, dann messen, dann die Hoehe stellen.
local function TextHeight(fs, minimum)
    local ok, h = pcall(fs.GetStringHeight, fs)
    if not ok or type(h) ~= "number" or h <= 0 then return minimum end
    return math.max(minimum, math.ceil(h))
end

-- Woher die Meldung kommt. "Ausrüstung" (also kein Eintrag hier) heisst:
-- du hast gerade etwas angelegt.
local EYEBROW = {
    rest     = "Erinnerung · Ruhebereich",
    zone     = "Erinnerung · Neue Zone",
    instance = "Erinnerung · Instanz",
    remind   = "Erinnerung",
}

local function RowLabel(index)
    local fs = rowLabels[index]
    if fs then return fs end
    fs = NewText(F.sans, 11, "textNormal")
    rowLabels[index] = fs
    return fs
end

-- Zeichnet Inhalt und stellt die Höhe darauf ein. Reihenfolge trägt:
-- erst die Texte setzen, dann die Fensterhöhe - dieselbe Abfolge wie in
-- core/onboarding.lua, aus demselben Grund.
local function Layout(entries, reason, hints)
    local single = (#entries == 1)
    local left   = PAD

    if single and entries[1].link then
        local tex = GetItemIcon and GetItemIcon(entries[1].link)
        if tex then
            icon:SetTexture(tex)
            icon:Show()
            left = PAD + ICON_SZ + 12
        else
            icon:Hide()
        end
    else
        icon:Hide()
    end

    local function Place(fs, y)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT",  frame, "TOPLEFT",  left, -y)
        fs:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
    end

    local y = PAD

    eyebrow:SetText(WeintCodex.Spaced(Upper(EYEBROW[reason] or "Ausrüstung")))
    Place(eyebrow, y)
    y = y + 15

    local title, sub = Headline(entries, reason)
    headline:SetText(Upper(title))
    Place(headline, y)
    y = y + TextHeight(headline, 24) + 2

    if sub and sub ~= "" then
        subline:SetText(sub)
        subline:Show()
        Place(subline, y)
        y = y + TextHeight(subline, 15) + 3
    else
        subline:Hide()
    end

    -- Die Einzelmeldung sagt den Befund schon in der Überschrift; die
    -- Liste darunter gibt es nur, wenn mehrere Teile offen sind.
    local shown = 0
    if not single then
        y = y + 4
        local limit = math.min(#entries, MAX_ROWS)
        for i = 1, limit do
            local e = entries[i]
            local fs = RowLabel(i)
            fs:SetText(WeintCodex.ColorText("textBright", e.slotName)
                .. "   " .. WeintCodex.ColorText("textMuted", EntryFinding(e)))
            fs:Show()
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT",  frame, "TOPLEFT",  left, -y)
            fs:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
            y = y + TextHeight(fs, ROW_H)
            shown = i
        end

        if #entries > limit then
            local fs = RowLabel(limit + 1)
            fs:SetText(WeintCodex.ColorText("textDim",
                "… und " .. (#entries - limit) .. " weitere"))
            fs:Show()
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT",  frame, "TOPLEFT",  left, -y)
            fs:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
            y = y + TextHeight(fs, ROW_H)
            shown = limit + 1
        end
    end

    for i = shown + 1, #rowLabels do rowLabels[i]:Hide() end

    -- Berufsmöglichkeiten zu ohnehin fehlenden Verzauberungen. Eine
    -- eigene Zeile, kein Anhängsel an den Befundzeilen: es ist keine
    -- Beanstandung, sondern die Auskunft, welche Wahl dieser Charakter
    -- zusätzlich hat.
    if hints and #hints > 0 then
        y = y + 6
        hintLine:SetText("Dein Beruf bietet hier zusätzlich — "
            .. table.concat(hints, "  ·  "))
        hintLine:Show()
        hintLine:ClearAllPoints()
        hintLine:SetPoint("TOPLEFT",  frame, "TOPLEFT",  left, -y)
        hintLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
        y = y + TextHeight(hintLine, 13)
    else
        hintLine:Hide()
    end

    -- Das Symbol darf die Fläche nicht überragen, auch nicht bei einer
    -- Einzelmeldung ohne Unterzeile.
    if icon:IsShown() then
        y = math.max(y, PAD + 4 + ICON_SZ)
    end

    y = y + 8
    hint:SetText(moveMode
        and "Ziehen zum Verschieben · Klick speichert die Position"
        or  "Bleibt stehen, bis du sie wegklickst — danach ist fünf Minuten Ruhe,"
            .. " dann erinnert sie wieder, solange die Lücke offen ist."
            .. "  Linksklick öffnet die Charakterseite, Rechtsklick schliesst nur."
            .. "  |cffD4A24A/wc alarm aus|r")
    hint:ClearAllPoints()
    hint:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD, -y)
    hint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
    y = y + TextHeight(hint, 12) + PAD

    frame:SetHeight(y)
end

--------------------------------------------------
-- Anzeigen / Verstecken
--------------------------------------------------

function GA.Hide()
    if not frame then return end
    anim.state = nil
    frame:Hide()
    frame:SetAlpha(1)
    RestorePosition()
end

-- Diese Funktion zeichnet nur. Ob ueberhaupt eingeblendet werden darf
-- (Kampf, abgeschaltet, nichts offen, schon quittiert), entscheidet
-- RunCheck weiter unten - sonst laege dieselbe Frage an zwei Stellen.
function GA.Show(entries, reason, hints)
    if not entries or #entries == 0 then return end

    Build()
    frame._entries = entries

    Layout(entries, reason, hints)
    RestorePosition()

    local point, _, _, x, y = frame:GetPoint()
    anim.point, anim.x, anim.y = point, x, y
    anim.state, anim.elapsed = "in", 0

    frame:SetAlpha(0)
    frame:Show()

    PlayAlertSound()
end

-- Wegklicken. Das Quittieren gehört hierher und nicht in GA.Hide: der
-- Kampfbeginn und "/wc alarm aus" blenden ebenfalls aus, und beides ist
-- keine Aussage darüber, ob jemand den Befund gesehen hat.
function GA.Dismiss()
    if frame then Acknowledge(frame._entries) end
    GA.Hide()
end

--------------------------------------------------
-- Prüflauf
--------------------------------------------------

local pendingSlots = {}   -- Slots, die seit dem letzten Lauf gewechselt haben
local scanScheduled = false
local retries = 0

-- Erst nach dem Vorlauf wird überhaupt zugehört. Beim Anmelden und nach
-- jedem Ladebildschirm feuert PLAYER_EQUIPMENT_CHANGED für angelegte
-- Gegenstände, ohne dass jemand etwas angelegt hätte - ohne diese
-- Sperre begrüsste das Addon einen mit einer Liste aller offenen Slots,
-- und zwar bei jedem Zonenwechsel.
local ready = false

local function After(delay, fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

-- Was im Kampf angefallen ist, wird nicht gezeigt, sondern vorgemerkt -
-- und nach dem Kampf neu geprueft statt aus dem Gedaechtnis gezeichnet.
-- Zwischen Pull und Ende kann sich die Ausruestung geaendert haben, und
-- eine Meldung ueber einen Zustand von vor vier Minuten ist keine.
local queued = nil

-- Der Anlass der gerade stehenden Meldung. Gebraucht wird er nur an einer
-- Stelle: weicht sie dem Kampf, muss danach dieselbe Frage noch einmal
-- gestellt werden koennen ("nur dieser Slot" bzw. "alles Offene").
local shownContext = nil

-- reason:  "equip" (nur die gewechselten Slots) | "rest" | "zone"
--          | "instance" | "remind" | "manual"
-- force:   die Quittung übergehen (nur der Instanzeingang tut das)
local function RunCheck(reason, slotFilter, force)
    if not Store().enabled and reason ~= "manual" then return end

    if reason ~= "manual" and UnitAffectingCombat("player") then
        queued = { reason = reason, filter = slotFilter, force = force }
        return
    end

    -- Ein echter Befund verschiebt nichts; der Ziehmodus gehoert allein
    -- zu "/wc alarm bewegen".
    moveMode = false

    local entries, pending, hints = Collect()
    if not entries then return end

    -- Gegen das vollständige Ergebnis, vor jeder Filterung: was behoben
    -- ist, verliert seine Quittung. Aber nur bei warmem Cache - siehe
    -- die Begründung an PruneAcks.
    if not pending then PruneAcks(entries) end

    if slotFilter then
        local filtered = {}
        for _, e in ipairs(entries) do
            if slotFilter[e.slotId] then filtered[#filtered + 1] = e end
        end
        entries = filtered
    end

    -- Schon weggeklickt? Dann war das die Antwort. "/wc alarm jetzt"
    -- fragt ausdrücklich und bekommt deshalb alles zu sehen.
    if reason ~= "manual" then
        local unseen = {}
        for _, e in ipairs(entries) do
            if not IsAcked(e, force) then unseen[#unseen + 1] = e end
        end
        entries = unseen
    end

    -- Noch nicht gecachte Gegenstände: später noch einmal nachsehen,
    -- statt jetzt eine Aussage über den eigenen Cache zu treffen.
    -- Nachgefasst wird nur, solange NICHTS gefunden wurde - sonst käme
    -- die Meldung ein zweites Mal, sobald der Rest nachgeladen ist.
    if #entries == 0 and pending and retries < RETRY_MAX then
        retries = retries + 1
        After(RETRY_DELAY, function() RunCheck(reason, slotFilter, force) end)
        return
    end

    if #entries == 0 then
        if reason == "manual" then
            print(WeintCodex.ColorText("gold", "[WeintCodex]")
                .. " Ausrüstungs-Alarm: nichts offen"
                .. (pending and " (einige Gegenstände sind noch nicht geladen)." or "."))
        end
        return
    end

    shownContext = { reason = reason, filter = slotFilter, force = force }
    GA.Show(entries, reason, hints)
end

GA.RunCheck = RunCheck

--------------------------------------------------
-- Auslöser
--------------------------------------------------

local watcher = CreateFrame("Frame")

local function ScheduleEquipCheck()
    if scanScheduled then return end
    scanScheduled = true
    After(EQUIP_DEBOUNCE, function()
        scanScheduled = false
        local slots = pendingSlots
        pendingSlots = {}
        retries = 0
        if not next(slots) then return end
        RunCheck("equip", slots)
    end)
end

--------------------------------------------------
-- "Nur, wenn man gerade nichts anderes macht"
--------------------------------------------------
-- Eine Erinnerung, die niemand angefordert hat, darf nicht mitten in
-- etwas hineinplatzen. Was als "etwas anderes" zählt, steht hier
-- vollständig - jede Zeile ist ein Moment, in dem eine Fläche mitten
-- im Bild schlicht im Weg ist.
--
-- Die Bewegung gehört ausdrücklich dazu: wer läuft, reitet oder fliegt,
-- ist unterwegs und nicht bei der Ausrüstung. Dadurch landet die
-- Erinnerung von selbst in dem Moment, in dem man irgendwo stehen
-- bleibt - und das ist genau der, in dem man etwas tun kann.
local function PlayerIsBusy()
    if UnitAffectingCombat("player")  then return true end
    if UnitIsDeadOrGhost("player")    then return true end

    if type(IsEncounterInProgress) == "function" and IsEncounterInProgress() then
        return true
    end
    if type(UnitOnTaxi) == "function" and UnitOnTaxi("player") then return true end
    if type(UnitInVehicle) == "function" and UnitInVehicle("player") then return true end
    if type(UnitCastingInfo) == "function" and UnitCastingInfo("player") then return true end
    if type(UnitChannelInfo) == "function" and UnitChannelInfo("player") then return true end
    if C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() then
        return true
    end
    if type(GetUnitSpeed) == "function" and (GetUnitSpeed("player") or 0) > 0 then
        return true
    end
    return false
end

GA.PlayerIsBusy = PlayerIsBusy

--------------------------------------------------
-- Erinnerungen, die niemand ausgelöst hat
--------------------------------------------------
-- Zeitgeber, Zonenwechsel, Ruhebereich, Instanzeingang. Alle vier
-- laufen durch dieselbe Schleuse, damit "nur wenn man nichts anderes
-- macht" und die Kostenbremse an EINER Stelle stehen.
--
-- lastAmbient ist bewusst eine Laufzeitvariable und beginnt bei 0: nach
-- einem /reload darf sofort nachgesehen werden. Gegen zu häufiges
-- Melden schützt dort die Quittung, und die liegt in den SavedData.
local lastAmbient  = 0
local busyPending  = false

local function AmbientCheck(reason, force)
    local s = Store()
    if not s.enabled then return end
    if not ready then return end
    -- Ein Schalter für alle vier Anlässe. Vier einzelne wären vier
    -- Fragen an den Nutzer, wo er nur eine hat: erinnern oder nicht.
    if not s.restReminder then return end

    if PlayerIsBusy() then
        -- Später noch einmal - aber nur ein Zeitgeber gleichzeitig,
        -- sonst stapeln sich bei jedem Zonenwechsel neue.
        if not busyPending then
            busyPending = true
            After(BUSY_RETRY, function()
                busyPending = false
                AmbientCheck(reason, force)
            end)
        end
        return
    end

    local now = time()
    if not force and (now - lastAmbient) < AMBIENT_THROTTLE then return end
    lastAmbient = now

    retries = 0
    RunCheck(reason, nil, force)
end

GA.AmbientCheck = AmbientCheck

local wasResting = nil

watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
watcher:RegisterEvent("PLAYER_UPDATE_RESTING")
watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- Beruf gelernt oder verlernt: die Berufsvergünstigungen kommen damit
-- in die Wertung hinein oder fallen heraus (data/professions.lua).
watcher:RegisterEvent("SKILL_LINES_CHANGED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")

watcher:SetScript("OnEvent", function(_, event, arg1)

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        if not (ready and Store().enabled) then return end
        if arg1 then pendingSlots[arg1] = true end
        ScheduleEquipCheck()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        -- Erst wenn der Item-Cache warm ist. Bis dahin ist jede Aussage
        -- über fehlende Verzauberungen eine über unseren Ladezustand.
        ready = false
        pendingSlots = {}
        After(ENTER_WORLD_DELAY, function()
            ready = true
            pendingSlots = {}
            wasResting = IsResting() and true or false

            -- Der Instanzeingang ist der einzige Anlass, der die
            -- Quittung übergeht: er ist der letzte Moment, in dem sich
            -- die Lücke noch schliessen lässt, und danach zählt sie
            -- eine Stunde lang bei jedem Pull mit. Hier ist die
            -- Erinnerung kein Nörgeln, sondern der Zweck der Sache.
            local inInstance = IsInInstance and IsInInstance()
            if inInstance then
                AmbientCheck("instance", true)
            elseif wasResting then
                AmbientCheck("rest")
            else
                AmbientCheck("remind")
            end
        end)
        return
    end

    if event == "PLAYER_UPDATE_RESTING" then
        local resting = IsResting() and true or false
        -- Nur beim Betreten. Das Ereignis feuert in beide Richtungen,
        -- und beim Verlassen ist die Erinnerung sinnlos - dort gibt es
        -- weder Bank noch Verzauberer.
        if resting and wasResting == false then
            After(2, function() AmbientCheck("rest") end)
        end
        wasResting = resting
        return
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        After(2, function() AmbientCheck("zone") end)
        return
    end

    if event == "SKILL_LINES_CHANGED" then
        After(3, function() AmbientCheck("remind") end)
        return
    end

    -- Beim Pull weicht eine stehende Meldung - eine Fläche mitten im
    -- Bild waehrend eines Bosskampfes ist genau das, was einen dazu
    -- bringt, das Ganze abzuschalten. Quittiert wird dabei NICHT: sie
    -- kommt nach dem Kampf zurück, sofern der Befund dann noch steht.
    if event == "PLAYER_REGEN_DISABLED" then
        if frame and frame:IsShown() and not moveMode then
            queued = queued or shownContext
            GA.Hide()
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" and queued then
        local q = queued
        queued = nil
        After(1, function()
            retries = 0
            RunCheck(q.reason, q.filter, q.force)
        end)
        return
    end
end)

--------------------------------------------------
-- Zeitgeber
--------------------------------------------------
-- Der Takt allein erinnert an nichts - AmbientCheck entscheidet, ob
-- die fünf Minuten um sind und ob der Moment passt. Ohne ihn käme die
-- Erinnerung nur bei Zonenwechsel oder Ruhebereich, und wer beim
-- Sortieren der Taschen in der Bank stehen bleibt, bekäme sie nie.
if C_Timer and C_Timer.After then
    local function Tick()
        C_Timer.After(TICK, function()
            pcall(AmbientCheck, "remind")
            Tick()
        end)
    end
    Tick()
end

--------------------------------------------------
-- Befehle (/wc alarm ...)
--------------------------------------------------

local function Say(text)
    print(WeintCodex.ColorText("gold", "[WeintCodex]") .. " " .. text)
end

function GA.PrintStatus()
    local s = Store()

    local acked = 0
    for _ in pairs(s.acked or {}) do acked = acked + 1 end

    -- Welche Berufsvergünstigungen für diesen Charakter überhaupt
    -- gelten. Ohne diese Zeile ist von aussen nicht zu sehen, ob der
    -- Beruf erkannt wurde oder ob nur gerade nichts offen ist.
    if WeintCodex_GetProfessionSkills and WeintCodex_ProfessionPerks then
        local named = {}
        for line, level in pairs(WeintCodex_GetProfessionSkills()) do
            local prof = WeintCodex_ProfessionPerks[line]
            if prof and level >= (WeintCodex_ProfessionMinSkill or 500) then
                named[#named + 1] = prof.name .. " (" .. level .. ")"
            end
        end
        Say("Berufsvergünstigungen: "
            .. (#named > 0 and table.concat(named, ", ")
                           or WeintCodex.ColorText("textDim", "keine")))
    end

    Say("Ausrüstungs-Alarm: "
        .. (s.enabled and WeintCodex.ColorText("green", "an")
                       or WeintCodex.ColorText("textDim", "aus"))
        .. "  ·  Ton: " .. (s.sound and "an" or "aus")
        .. "  ·  Erinnerungen: " .. (s.restReminder and "an" or "aus")
        .. "  ·  weggeklickt: " .. acked .. " Befund(e)")

    -- Was der letzte Tonversuch ergeben hat. Ohne diese Zeile ist "ich höre
    -- nichts" von aussen nicht von "Lautstärke steht auf 0" zu unterscheiden -
    -- und genau daran lag es, dass der stumme Alarm so lange unbemerkt blieb.
    Say("Zuletzt gespielt: " .. WeintCodex.ColorText("textDim", GA.SoundNote()))
    Say("|cffaaaaaaWeggeklickt heisst " .. math.floor(ACK_LIFETIME / 60)
        .. " Minuten Ruhe. Danach erinnert der Alarm erneut - beim"
        .. " Zonenwechsel, im Ruhebereich, am Instanzeingang oder von"
        .. " selbst, sobald du gerade nichts anderes machst.|r")
    Say("|cffaaaaaa/wc alarm an|aus · ton · tontest · erinnern · erneut · jetzt · berufe · test · bewegen|r")
end

--------------------------------------------------
-- /wc alarm berufe
--------------------------------------------------
-- Druckt je Vergünstigung aus, WAS gelesen wurde - den Gegenstand, den
-- Verzauberungswert seines Item-Links, die Sockelzahlen. Genau das
-- fehlte, als der Alarm einem Ingenieur "Nitrobooster fehlt" an einen
-- Gürtel schrieb, auf dem der Tinker lag: von aussen war nicht zu
-- unterscheiden, ob die Erkennung danebengreift oder ob schlicht ein
-- zweiter, unverzauberter Gürtel angelegt war. Dieselbe Überlegung wie
-- bei "/wc vz zeilen" in modules/charakter.lua - diese Fehlerklasse ist
-- ohne Ausgabe der Rohdaten nicht diagnostizierbar.
function GA.PrintProfessions()
    if not (WeintCodex_ProfessionPerks and WeintCodex_GetProfessionSkills) then
        Say("Berufsdaten nicht geladen (data/professions.lua).")
        return
    end

    local CH = WeintCodex.Charakter
    if not (CH and CH.ParseItemLink and CH.ScanItemSockets) then
        Say("Charaktermodul nicht bereit.")
        return
    end

    local skills = WeintCodex_GetProfessionSkills()
    if not next(skills) then
        Say("Kein Beruf erkannt. (GetProfessions liefert nichts - beim"
            .. " Anmelden kann das ein paar Sekunden dauern.)")
        return
    end

    local jcCount = CountJewelcrafterGems()

    for skillLine, level in pairs(skills) do
        local prof = WeintCodex_ProfessionPerks[skillLine]
        if not prof then
            Say(WeintCodex.ColorText("textDim",
                "Skill-Line " .. skillLine .. " (" .. level
                .. ") - keine Vergünstigung an der Ausrüstung hinterlegt."))
        else
            Say(WeintCodex.ColorText("gold", prof.name)
                .. " - Fertigkeit " .. level)

            for _, perk in ipairs(prof.perks or {}) do
                local need = PerkMinSkill(perk)

                if level < need then
                    Say("   " .. perk.label .. ": "
                        .. WeintCodex.ColorText("textDim",
                            "braucht Fertigkeit " .. need))
                elseif perk.kind == "hint" then
                    local link = GetInventoryItemLink("player", perk.slotId)
                    local enchId = link and CH.ParseItemLink(link)
                    Say("   " .. perk.label .. " (" .. perk.slotName .. ", Hinweis): "
                        .. (link or "kein Gegenstand angelegt")
                        .. " - Verzauberung im Item-Link: "
                        .. (enchId and tostring(enchId) or "keine"))
                else
                    local link = (perk.kind ~= "gems")
                        and GetInventoryItemLink("player", perk.slotId) or nil
                    local used, detail = PerkState(perk, link, jcCount)

                    local verdict
                    if used == true then
                        verdict = WeintCodex.ColorText("green", "genutzt")
                    elseif used == false then
                        verdict = WeintCodex.ColorText("warning", "offen")
                    else
                        verdict = WeintCodex.ColorText("textDim", "nicht feststellbar")
                    end

                    Say("   " .. perk.label
                        .. (perk.slotName and (" (" .. perk.slotName .. ")") or "")
                        .. ": " .. verdict)
                    Say("      " .. (link and (link .. " - ") or "")
                        .. tostring(detail))
                end
            end
        end
    end
end

-- Erfundener Befund fuer Testmeldung und Ziehmodus. Die Form muss exakt
-- der von Collect() entsprechen - Headline() liest `#e.perks`, und ein
-- Eintrag ohne dieses Feld liess "/wc alarm test" auf einem Charakter ohne
-- echten Befund mit einem Lua-Fehler auflaufen (genau dann also, wenn man
-- die Testmeldung ueberhaupt braucht).
local function SampleEntry(slotId, slotName, enchant, sockets)
    return {
        slotId  = slotId, slotName = slotName, link = nil,
        enchant = enchant and true or false,
        sockets = sockets or 0,
        buckle  = false,
        perks   = {},
    }
end

-- Beispielmeldung mit den eigenen Daten, sonst mit erfundenen. Sie
-- laesst sich im Ziehmodus verschieben und quittiert beim Klick
-- nichts - der Befund darin kann erfunden sein.
function GA.ShowMover()
    local entries = Collect()
    if not entries or #entries == 0 then
        entries = {
            SampleEntry(9,  "Handgelenke", true,  0),
            SampleEntry(10, "Hände",       false, 1),
        }
    end
    moveMode = true
    GA.Show(entries, "manual")
end

--------------------------------------------------
-- Einstellungen und Aktionen als API
--------------------------------------------------
-- Dieselben Handgriffe, die "/wc alarm ..." ausloest - nur ohne den Umweg
-- ueber eine Befehlszeichenkette. Die Einstellungsseite (modules/settings.lua)
-- liest und schreibt darueber; GA.Command ruft ab 2.6.0.0 ebenfalls nur noch
-- diese Funktionen auf, damit Schalter und Befehl nicht zwei Wege durch
-- denselben Zustand nehmen.
--------------------------------------------------

-- Erlaubte Schluessel: enabled, sound, restReminder. Bewusst kein freier
-- Durchgriff auf den ganzen Speicher - `acked` und `pos` sind kein Schalter.
local OPTION_KEYS = { enabled = true, sound = true, restReminder = true }

function GA.GetOption(key)
    if not OPTION_KEYS[key] then return nil end
    return Store()[key] and true or false
end

function GA.SetOption(key, value)
    if not OPTION_KEYS[key] then return end
    local s = Store()
    s[key] = value and true or false
    -- Ausschalten heisst auch: eine stehende Meldung geht weg. Sonst bliebe
    -- genau die Flaeche stehen, die man gerade abgeschaltet hat.
    if key == "enabled" and not s.enabled then GA.Hide() end
end

-- Zahl der weggeklickten Befunde - die Einstellungsseite beschriftet damit
-- ihre Schaltflaeche, statt eine Zahl zu behaupten, die niemand nachsieht.
function GA.AckCount()
    local n = 0
    for _ in pairs(Store().acked or {}) do n = n + 1 end
    return n
end

function GA.CheckNow()
    retries = 0
    RunCheck("manual", nil)
end

-- Der Rueckweg fuer alles Weggeklickte. Ohne ihn waere eine einmal
-- quittierte Luecke fuer immer stumm, und die einzige Abhilfe stuende in
-- den SavedData.
function GA.ForgetAcks()
    local s = Store()
    local n = GA.AckCount()
    s.acked = {}
    -- Die Kostenbremse gleich mit, sonst bliebe es bis zu fuenf Minuten
    -- still, obwohl man gerade um die Meldung gebeten hat.
    lastAmbient = 0
    retries = 0
    RunCheck("manual", nil)
    return n
end

function GA.ResetPosition()
    Store().pos = nil
    if frame then RestorePosition() end
end

-- Beispielmeldung mit den eigenen Daten, sonst mit einer erfundenen Zeile.
function GA.ShowTest()
    local entries = Collect()
    if not entries or #entries == 0 then
        entries = { SampleEntry(9, "Handgelenke", true, 0) }
    end
    moveMode = false
    GA.Show(entries, "manual")
end

function GA.Command(rest)
    local s = Store()

    if rest == "an" or rest == "ein" or rest == "on" then
        GA.SetOption("enabled", true)
        GA.PrintStatus()

    elseif rest == "aus" or rest == "off" then
        GA.SetOption("enabled", false)
        GA.PrintStatus()

    elseif rest == "ton" or rest == "sound" then
        GA.SetOption("sound", not s.sound)
        -- Beim Einschalten gleich einmal klingen lassen: eine Einstellung
        -- fuer einen Ton, die man erst beim naechsten Befund hoert, ist
        -- nicht pruefbar - und genau das war das Problem.
        if Store().sound then GA.PlaySignal() end
        GA.PrintStatus()

    elseif rest == "tontest" or rest == "tonprobe" or rest == "soundtest" then
        local played, note = GA.PlaySignal()
        Say(played and ("Ton gespielt: " .. note)
                    or WeintCodex.ColorText("warning", "Kein Ton: " .. note))

    elseif rest == "ruhe" or rest == "ruhebereich"
           or rest == "erinnern" or rest == "erinnerung" then
        GA.SetOption("restReminder", not s.restReminder)
        GA.PrintStatus()

    elseif rest == "test" then
        GA.ShowTest()

    elseif rest == "berufe" or rest == "beruf" then
        GA.PrintProfessions()

    elseif rest == "bewegen" or rest == "position" then
        GA.ShowMover()

    elseif rest == "zuruecksetzen" or rest == "zurücksetzen" then
        GA.ResetPosition()
        Say("Position des Ausrüstungs-Alarms zurückgesetzt.")

    elseif rest == "erneut" or rest == "wieder" or rest == "reset" then
        local n = GA.ForgetAcks()
        Say(n .. " weggeklickte Befund(e) vergessen - sie melden sich wieder.")

    elseif rest == "jetzt" or rest == "pruefen" or rest == "prüfen" then
        GA.CheckNow()

    else
        GA.PrintStatus()
    end

    -- Steht die Einstellungsseite gerade offen, zeigen ihre Schalter sonst
    -- den Stand von vor dem Befehl. Dieselbe Ueberlegung wie beim
    -- Schalterabgleich in modules/rotationtrainer.lua.
    if WeintCodex.Settings and WeintCodex.Settings.Refresh then
        WeintCodex.Settings.Refresh()
    end
end
