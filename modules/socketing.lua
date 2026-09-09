--------------------------------------------------
-- WeintCodex :: Am Sockelfenster (seit 3.1.0.0)
--------------------------------------------------
-- Das Addon weiss, welcher Stein in welchen Sockel gehoert. Bis hierher
-- stand diese Auskunft auf *Charakter -> Sockel* — also an einer Stelle,
-- die man aufmacht, sich merkt und dann vor dem offenen Sockelfenster
-- doch nicht mehr weiss. Bei drei Sockeln in einem Teil, deren Steine
-- sich nur im zweiten Wert unterscheiden ("Kunstvoller" gegen
-- "Schneidender" Aragonit), ist das keine Nachlaessigkeit, sondern
-- normal.
--
-- Dieselbe Ueberlegung wie bei der Einkaufsliste am Auktionshaus
-- (modules/shoppinglist.lua): die Auskunft gehoert an den Ort, an dem
-- gehandelt wird.
--
-- SIE RECHNET NICHTS.
--
-- Was in welchen Sockel gehoert, entscheidet WeintCodex.Charakter.Scan()
-- — dort stehen Spec-Profil, Sim-Ziel, Sockelboni und Grenzen. Diese
-- Datei liest die fertigen Zeilen und stellt die dar, die zu dem gerade
-- geoeffneten Gegenstand gehoeren. Eine zweite Bewertung nebenher waere
-- genau die Doppelung, an der die Sockelbewertung ueber fuenf Releases
-- gescheitert ist.
--
-- WELCHES TEIL DAS IST, WEISS NUR DER CLIENT — UND ER SAGT ES NICHT.
--
-- `GetSocketItemInfo()` gibt Name, Symbol und Qualitaet heraus, aber
-- nicht den Ausruestungsplatz. Ueber den Namen zu suchen ginge schief,
-- wo es schiefgehen muss: Ring 1 und Ring 2 koennen dasselbe Teil sein,
-- und beide haben eigene Sockel.
--
-- Deshalb wird die Frage dort beantwortet, wo sie entsteht: das Spiel
-- oeffnet das Fenster ueber `SocketInventoryItem(slot)` (angelegtes
-- Teil) oder `SocketContainerItem(bag, slot)` (aus der Tasche). Beide
-- werden mitgehoert; die erste merkt sich den Platz, die zweite loescht
-- ihn. Ein Teil aus der Tasche ist nicht angelegt — ueber das sagt der
-- Scan nichts, und dann sagt auch diese Datei nichts.
--
-- GEGENPROBE STATT VERTRAUEN. Der gemerkte Platz koennte von einem
-- frueheren Fenster stammen. Vor jeder Anzeige wird deshalb der Name aus
-- `GetSocketItemInfo()` gegen den Namen des Teils in genau diesem Platz
-- gehalten. Stimmen sie nicht ueberein, gilt er nicht - eine Empfehlung
-- fuer das falsche Teil waere schlimmer als keine.
--
-- DER HAKEN FAENGT NICHT ALLE WEGE (behoben in 3.1.1.0).
--
-- Er faengt genau die zwei, die durch Lua fuehren: Umschalt-Klick auf ein
-- angelegtes Teil im Charakterfenster und derselbe Klick in der Tasche.
-- Der Weg, den fast jeder geht, fuehrt nicht durch Lua: Stein
-- rechtsklicken, dann auf das Teil klicken. Dabei oeffnet der Client das
-- Fenster selbst, `SocketInventoryItem` wird nie gerufen, `currentSlot`
-- bleibt leer - und 3.1.0.0 hat daraufhin gar nichts angezeigt. Gemeldet
-- wurde es als "es kommt kein Fenster", und das ist von "die Anzeige ist
-- kaputt" nicht zu unterscheiden.
--
-- RUECKFALL: DAS TEIL SELBST. `GetSocketItemInfo()` gibt den Namen
-- heraus; gesucht wird der angelegte Platz, der ihn traegt. Der
-- urspruengliche Einwand bleibt gueltig - Ring 1 und Ring 2 koennen
-- dasselbe Teil sein - deshalb wird nicht geraten, sondern gezaehlt:
--
--   genau ein Platz    der ist es
--   mehrere Plaetze    ueber die Steine unterscheiden, die JETZT im
--                      Fenster stecken (`GetExistingSocketLink`); bleibt
--                      genau einer uebrig, ist er es
--   immer noch mehrere nichts behaupten - aber es SAGEN
--   kein Platz         das Teil ist nicht angelegt - auch das wird gesagt
--
-- DASS ES GESAGT WIRD, GEHOERT ZUR SACHE. Eine Anzeige, die im Zweifel
-- gar nicht erscheint, ist von einer kaputten nicht zu unterscheiden -
-- genau der Weg, auf dem 3.1.0.0 als "geht nicht" ankam. Ein Satz, warum
-- hier nichts steht, ist deshalb keine Ausrede, sondern die Auskunft.
--
-- WOHER DAS FENSTER KAM, BLEIBT ENTSCHEIDEND. Ein Teil aus der Tasche
-- kann denselben Namen tragen wie ein angelegtes (zwei gleiche Ringe,
-- einer im Beutel). Der Rueckfall duerfte dann die Empfehlung des
-- angelegten Teils fuer das in der Tasche zeigen. Deshalb merkt sich der
-- Haken nicht nur den Platz, sondern auch die HERKUNFT: meldet er
-- "Tasche", wird gar nicht erst gesucht.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Socketing = {}

local SO = WeintCodex.Socketing

local DEFAULTS = { enabled = true }

local function Store()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local sd = WeintCodex.SavedData
    sd.socketing = sd.socketing or {}
    for key, value in pairs(DEFAULTS) do
        if sd.socketing[key] == nil then sd.socketing[key] = value end
    end
    return sd.socketing
end

function SO.GetOption(key) return Store()[key] end
function SO.SetOption(key, value) Store()[key] = value and true or false end

--------------------------------------------------
-- WAS ZU DIESEM PLATZ GEHOERT
--------------------------------------------------
-- Rein lesend, ohne Oberflaeche - damit der Testlauf ohne Spiel pruefen
-- kann, dass die Zeilen des richtigen Platzes in der richtigen
-- Sockelreihenfolge herauskommen. Die Reihenfolge ist die ganze Aussage:
-- ein verschobener Stein sieht aus wie eine Empfehlung und ist keine.

function SO.RowsForSlot(scan, slotId)
    local out = {}
    if not (scan and scan.gems and scan.gems.rows and slotId) then return out end

    for _, row in ipairs(scan.gems.rows) do
        if row.slotId == slotId then out[#out + 1] = row end
    end

    -- Nach der Sockelposition, nicht nach der Fundreihenfolge: der Scan
    -- laeuft zwar der Reihe nach, aber verlassen wird sich darauf nicht.
    table.sort(out, function(a, b)
        return (a.socket and a.socket.index or 0) < (b.socket and b.socket.index or 0)
    end)

    return out
end

--------------------------------------------------
-- EINE ZEILE, WIE SIE AM SOCKELFENSTER STEHT
--------------------------------------------------
-- Drei Faelle, drei Aussagen - und einer davon ist ausdruecklich KEINE
-- Aussage:
--
--   "done"    der Zielstein steckt schon drin (gleiche ID oder ein
--             wertgleicher Schliff davon)
--   "swap"    hier gehoert ein anderer Stein hinein
--   "none"    dazu ist nichts bekannt (Daten noch nicht geladen, oder
--             fuer diesen Sockel gibt es keine Empfehlung)
--
-- Rueckgabe: { kind, itemId, name, note }

function SO.LineFor(row)
    if not row then return nil end

    if row.socketsKnown == false or row.status == "neutral" then
        return { kind = "none",
                 note = "Gegenstandsdaten noch nicht geladen" }
    end

    local wanted = row.recId
    if not wanted then
        return { kind = "none", note = "keine Empfehlung fuer diesen Sockel" }
    end

    local name = (WeintCodex_GetGemName and WeintCodex_GetGemName(wanted))
        or ("Stein " .. tostring(wanted))

    -- "optimal" heisst: der empfohlene Stein steckt bereits drin -
    -- entweder mit derselben Nummer oder als wertgleicher Schliff
    -- (siehe EvaluateGem). Beides ist erledigt, nicht offen.
    if row.status == "optimal" then
        return { kind = "done", itemId = wanted, name = name,
                 note = row.fromSim and "wie im Sim-Ergebnis" or "steckt schon drin" }
    end

    return { kind = "swap", itemId = wanted, name = name,
             note = row.fromSim and "aus deinem Sim-Ergebnis" or "aus dem Spec-Profil" }
end

--------------------------------------------------
-- DER PLATZ, DER GERADE OFFEN IST
--------------------------------------------------

local currentSlot   = nil
local currentSource = nil   -- "angelegt" | "tasche" | nil (Client selbst)

-- Beide Einstiege des Spiels mithoeren. `hooksecurefunc` laeuft NACH der
-- Blizzard-Fassung und aendert an ihr nichts.
--
-- Gemerkt wird ZWEIERLEI: der Platz und die Herkunft. Die Herkunft ist
-- kein Beiwerk - sie ist das, was den Rueckfall weiter unten davon
-- abhaelt, einem Teil aus der Tasche die Empfehlung eines gleichnamigen
-- angelegten Teils unterzuschieben.
if type(hooksecurefunc) == "function" then
    if type(_G.SocketInventoryItem) == "function" then
        hooksecurefunc("SocketInventoryItem", function(slot)
            currentSlot, currentSource = tonumber(slot), "angelegt"
        end)
    end
    if type(_G.SocketContainerItem) == "function" then
        -- Aus der Tasche: kein angelegter Platz, also keine Auskunft.
        -- Ohne dieses Loeschen bliebe der Platz von vorhin stehen und die
        -- Anzeige gehoerte zum falschen Teil.
        hooksecurefunc("SocketContainerItem", function()
            currentSlot, currentSource = nil, "tasche"
        end)
    end
end

-- Der Name aus einem Item-Link. Als benannte Konstante, weil dasselbe
-- Muster an zwei Stellen gebraucht wird und ein Tippfehler darin still
-- bliebe: er faende einfach nie etwas.
local NAME_PATTERN = "|h%[(.-)%]|h"

local FIRST_SLOT, LAST_SLOT = 1, 18

local function NameOfSlot(slot)
    local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
    if not link then return nil end
    return (link:match(NAME_PATTERN)), link
end

-- Die Steine, die JETZT im offenen Fenster stecken - in der Reihenfolge
-- der Sockel. Nur zum Unterscheiden zweier gleicher angelegter Teile
-- gedacht, nie als Grundlage einer Empfehlung: waehrend man die Maske
-- fuellt, aendert sich diese Liste, das angelegte Teil aber erst beim
-- Klick auf "Sockeln".
local function OpenSocketGems()
    if type(GetNumSockets) ~= "function" then return nil end

    local count = GetNumSockets()
    if not count or count < 1 then return nil end

    local out = {}
    for i = 1, count do
        local link = GetExistingSocketLink and GetExistingSocketLink(i)
        out[i] = link and tonumber(link:match("item:(%d+)")) or 0
    end
    return out
end

local function SlotGems(link)
    local CH = WeintCodex.Charakter
    if not (CH and CH.ParseItemLinkForDiagnostics and link) then return nil end

    local ok, _, gems = pcall(CH.ParseItemLinkForDiagnostics, link)
    if not ok then return nil end
    return gems
end

local function GemsMatch(open, gems)
    if not (open and gems) then return false end

    for i = 1, #open do
        if (tonumber(gems[i]) or 0) ~= open[i] then return false end
    end
    return true
end

-- Welcher angelegte Platz liegt im Fenster?
--
--   slot, nil          so heisst der Platz
--   nil,  "zu"         kein Sockelfenster offen
--   nil,  "tasche"     das Teil ist nicht angelegt
--   nil,  "mehrdeutig" zwei gleiche angelegte Teile, keins davon sicher
local function ResolveSlot()
    if type(GetSocketItemInfo) ~= "function" then return nil, "zu" end

    local socketName = GetSocketItemInfo()
    if not socketName then return nil, "zu" end

    -- 1) Was der Haken gemerkt hat - aber nur, wenn dort auch dieses
    --    Teil steckt. Ein Platz von vorhin ist schlimmer als keiner.
    if currentSlot and NameOfSlot(currentSlot) == socketName then
        return currentSlot, nil
    end

    -- 2) Der Haken hat "Tasche" gemeldet: dann wird nicht gesucht. Der
    --    Name allein wuerde sonst auf ein gleichnamiges angelegtes Teil
    --    zeigen, und dessen Empfehlung gilt fuer das im Beutel nicht.
    if currentSource == "tasche" then return nil, "tasche" end

    -- 3) Rueckfall ueber das Teil selbst - der Weg, den der Haken nicht
    --    faengt (Stein aufnehmen, auf das angelegte Teil klicken).
    local hits = {}
    for slot = FIRST_SLOT, LAST_SLOT do
        local name, link = NameOfSlot(slot)
        if name and name == socketName then
            hits[#hits + 1] = { slot = slot, link = link }
        end
    end

    if #hits == 0 then return nil, "tasche" end
    if #hits == 1 then return hits[1].slot, nil end

    -- 4) Zwei gleiche angelegte Teile (Ring 1/Ring 2, zwei gleiche
    --    Schmuckstuecke). Ueber die Steine unterscheiden, die jetzt im
    --    Fenster liegen - aber nur, wenn genau EINER dazu passt.
    local open, only = OpenSocketGems(), nil
    for _, hit in ipairs(hits) do
        if GemsMatch(open, SlotGems(hit.link)) then
            if only then return nil, "mehrdeutig" end
            only = hit.slot
        end
    end

    if only then return only, nil end

    return nil, "mehrdeutig"
end

SO.ResolveSlot = ResolveSlot

-- Der alte Name, unveraendert in seiner Bedeutung: der Platz, oder nichts.
local function VerifiedSlot()
    return (ResolveSlot())
end

SO.VerifiedSlot = VerifiedSlot

--------------------------------------------------
-- Die Zeilen holen - hoechstens einmal je geoeffnetem Teil
--------------------------------------------------
-- `SOCKET_INFO_UPDATE` feuert bei jedem Stein, den man in die Maske legt.
-- Ein voller Ausruestungsscan je Ereignis waere an der teuersten Stelle
-- die haeufigste Rechnung.

local cachedSlot, cachedRows = nil, nil

local function Invalidate()
    cachedSlot, cachedRows = nil, nil
end

SO.Invalidate = Invalidate

local function RowsNow(slot)
    if cachedSlot == slot and cachedRows then return cachedRows end

    local Ch = WeintCodex.Charakter
    if not (Ch and Ch.Scan) then return nil end

    local ok, scan = pcall(Ch.Scan)
    if not ok or not scan then return nil end

    cachedSlot = slot
    cachedRows = SO.RowsForSlot(scan, slot)
    return cachedRows
end

--------------------------------------------------
-- Das Panel neben dem Sockelfenster
--------------------------------------------------
-- Gebaut wird es erst beim ersten Ereignis: `ItemSocketingFrame` gehoert
-- zu Blizzard_ItemSocketingUI und wird nachgeladen. Vorher gibt es nichts
-- zum Anhaengen.

local panel = nil
local MAX_ROWS = 4
local retryPending = false

-- Warum hier nichts steht. Ohne diese Saetze bliebe das Fenster in
-- genau den Faellen aus, in denen der Spieler eine Auskunft erwartet -
-- und ein ausbleibendes Fenster ist von einem kaputten nicht zu
-- unterscheiden.
local REASON_TEXT = {
    tasche =
        "Dieses Teil ist nicht angelegt. WeintCodex bewertet nur, was du"
        .. " traegst - leg es an und oeffne die Sockel erneut.",
    mehrdeutig =
        "Du traegst dieses Teil zweimal (zwei gleiche Ringe oder"
        .. " Schmuckstuecke). Welches davon offen ist, sagt das Spiel"
        .. " nicht. Oeffne die Sockel aus dem Charakterfenster heraus,"
        .. " dann ist es eindeutig.",
}

local function BuildPanel()
    local host = _G.ItemSocketingFrame
    if not host then return nil end

    local C = WeintCodex.Colors
    local F = WeintCodex.Fonts

    local f = WeintCodex.CreateSurface(UIParent, {
        width = 260, height = 190, tone = "plain", radius = 12,
        backdrop = "bgDark",
    })
    f:SetPoint("TOPLEFT", host, "TOPRIGHT", 6, -12)
    f:SetFrameStrata(host:GetFrameStrata() or "HIGH")
    f:SetToplevel(false)
    f:Hide()

    local eyebrow = WeintCodex.Eyebrow(f, "WeintCodex")
    eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(F.sansBold, 14, "")
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -4)
    title:SetTextColor(unpack(C.textBright))
    title:SetText("Das gehoert hier hinein")
    f._title = title

    local sub = WeintCodex.Label(f, "", { color = "textMuted", size = 11 })
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetWidth(232)
    sub:SetJustifyH("LEFT")
    f._sub = sub

    f._rows = {}
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(232, 30)
        if i == 1 then
            row:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -8)
        else
            row:SetPoint("TOPLEFT", f._rows[i - 1], "BOTTOMLEFT", 0, -4)
        end

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)

        row.name = row:CreateFontString(nil, "OVERLAY")
        row.name:SetFont(F.sans, 12, "")
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 24, 0)
        row.name:SetWidth(208)
        row.name:SetJustifyH("LEFT")

        row.note = row:CreateFontString(nil, "OVERLAY")
        row.note:SetFont(F.sans, 10, "")
        row.note:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -1)
        row.note:SetWidth(208)
        row.note:SetJustifyH("LEFT")
        row.note:SetTextColor(unpack(C.textDim))

        -- Der Tooltip ist der einzige Weg, die Werte des Zielsteins zu
        -- sehen, ohne das Fenster zu verlassen. Einsetzen kann das Addon
        -- ihn nicht: das ist eine geschuetzte Handlung des Spielers.
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if not self._itemId then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self._itemId)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        f._rows[i] = row
    end

    local hint = WeintCodex.Label(f,
        "Ziehe den Stein selbst in die Maske — Einsetzen kann dir kein Addon abnehmen.",
        { color = "textFaint", size = 10 })
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 12)
    hint:SetWidth(232)
    hint:SetJustifyH("LEFT")
    f._hint = hint

    return f
end

-- Vorwaerts angemeldet: `Refresh` ruft sich beim Nachladen der
-- Blizzard-Oberflaeche einmal selbst nach.
local Refresh

-- Alle Zeilen ausblenden und eine einzige Aussage hinschreiben. Genutzt
-- fuer die Faelle, in denen es KEINE Empfehlung gibt und das auch so
-- gemeint ist.
local function ShowMessage(text)
    for i = 1, MAX_ROWS do panel._rows[i]:Hide() end

    -- Ueberschrift und Fusszeile gehoeren zur Empfehlung, nicht zur
    -- Begruendung ihres Fehlens: "Das gehoert hier hinein" ueber einem
    -- Satz, der sagt, dass nichts hineingehoert, waere ein Widerspruch.
    panel._title:SetText("Dazu sagt WeintCodex nichts")
    panel._hint:Hide()

    panel._sub:SetText(text)

    -- Die Hoehe kommt vom umgebrochenen Text, nicht aus einer Zahl:
    -- die Saetze sind verschieden lang, und ein abgeschnittener
    -- Begruendungssatz ist schlimmer als gar keiner.
    local h = panel._sub.GetStringHeight and panel._sub:GetStringHeight() or 60
    panel:SetHeight(78 + math.max(h, 40))
    panel:Show()
end

Refresh = function()
    if not SO.GetOption("enabled") then
        if panel then panel:Hide() end
        return
    end

    panel = panel or BuildPanel()
    if not panel then
        -- `Blizzard_ItemSocketingUI` wird nachgeladen: beim allerersten
        -- Sockeln kann das Ereignis vor dem Fenster da sein, an das wir
        -- uns haengen. Einmal kurz spaeter erneut versuchen - sonst
        -- bleibt ausgerechnet die erste Sockelung stumm, und die ist
        -- die, an der man sich ein Urteil bildet.
        if C_Timer and C_Timer.After and not retryPending then
            retryPending = true
            C_Timer.After(0.2, function()
                retryPending = false
                Refresh()
            end)
        end
        return
    end

    local slot, reason = ResolveSlot()

    if not slot then
        local text = reason and REASON_TEXT[reason]
        if text then
            ShowMessage(text)
        else
            panel:Hide()
        end
        return
    end

    local rows = RowsNow(slot)

    if not rows or #rows == 0 then
        -- Der Platz steht fest, der Scan hat aber keine Sockelzeile
        -- dazu: das Teil hat keine (oder die Gegenstandsdaten fehlen
        -- noch). Nichts behaupten.
        panel:Hide()
        return
    end

    local C  = WeintCodex.Colors
    local TG = WeintCodex.TargetGear
    local CH = WeintCodex.Charakter
    local SLOT_NAMES  = TG and TG.SLOT_NAMES or {}
    local COLOR_LABEL = (CH and CH.SocketColorLabel) or {}

    local ausSim = false
    for _, row in ipairs(rows) do
        if row.fromSim then ausSim = true end
    end

    panel._title:SetText("Das gehoert hier hinein")
    panel._hint:Show()

    panel._sub:SetText((SLOT_NAMES[slot] or "Dieser Platz")
        .. (ausSim and " · aus deinem Sim-Ergebnis" or " · aus dem Spec-Profil"))

    local used = 0
    for i = 1, MAX_ROWS do
        local row  = panel._rows[i]
        local line = rows[i] and SO.LineFor(rows[i]) or nil

        if not line then
            row:Hide()
        else
            used = used + 1
            row._itemId = line.itemId

            -- DIE SOCKELFARBE STEHT DABEI (seit 3.1.1.0). Im Fenster
            -- liegen die Sockel nebeneinander und unterscheiden sich
            -- nur an ihrer Farbe; "Sockel 2" allein zwingt zum
            -- Nachzaehlen, und genau dabei verzaehlt man sich.
            local socket = rows[i].socket
            local farbe  = socket and socket.color and COLOR_LABEL[socket.color]
            local label  = "Sockel " .. i .. (farbe and (" (" .. farbe .. ")") or "")

            if line.kind == "none" then
                row.icon:SetTexture("Interface\\Buttons\\UI-MinusButton-UP")
                row.name:SetText(label .. ": —")
                row.name:SetTextColor(unpack(C.textDim))
                row.note:SetText(line.note or "")
            else
                local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(line.itemId)
                row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Gem_Variety_01")
                row.name:SetText(label .. ": " .. line.name)
                if line.kind == "done" then
                    row.name:SetTextColor(unpack(C.green))
                else
                    row.name:SetTextColor(unpack(C.accent))
                end
                row.note:SetText(line.note or "")
            end
            row:Show()
        end
    end

    panel:SetHeight(96 + math.max(used, 1) * 34)
    panel:Show()
end

SO.Refresh = Refresh

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local watcher = CreateFrame("Frame")
for _, event in ipairs({
    "SOCKET_INFO_UPDATE", "SOCKET_INFO_CLOSE", "PLAYER_EQUIPMENT_CHANGED",
}) do
    pcall(watcher.RegisterEvent, watcher, event)
end

watcher:SetScript("OnEvent", function(_, event)
    if event == "SOCKET_INFO_CLOSE" then
        currentSlot, currentSource = nil, nil
        Invalidate()
        if panel then panel:Hide() end
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        -- Ein gesockelter Stein aendert das angelegte Teil: der naechste
        -- Blick muss neu rechnen, sonst steht die Empfehlung von vorhin da.
        Invalidate()
        if WeintCodex.Charakter and WeintCodex.Charakter.ClearCache then
            WeintCodex.Charakter.ClearCache()
        end
        if panel and panel:IsShown() then Refresh() end
        return
    end

    Refresh()
end)

--------------------------------------------------
-- `/wc sockelfenster`
--------------------------------------------------

local function Say(text)
    print("|cffD4A24A[WeintCodex]|r " .. text)
end

function SO.Command(rest)
    local arg = tostring(rest or ""):lower():match("^%s*(%S*)")

    if arg == "aus" or arg == "off" then
        SO.SetOption("enabled", false)
        if panel then panel:Hide() end
        Say("Die Anzeige am Sockelfenster ist |cffEF4444abgeschaltet|r.")
        return
    end

    if arg == "an" or arg == "on" then
        SO.SetOption("enabled", true)
        Say("Die Anzeige am Sockelfenster ist |cff22C55Ean|r.")
        return
    end

    Say("Anzeige am Sockelfenster: "
        .. (SO.GetOption("enabled") and "|cff22C55Ean|r" or "|cffEF4444aus|r")
        .. ". Umschalten mit |cffD4A24A/wc sockelfenster an|r bzw. |cffD4A24Aaus|r.")
    -- Die Diagnose nennt beide Wege getrennt. Wer meldet "es kommt kein
    -- Fenster", soll hier ablesen koennen, WORAN es liegt: hat der Haken
    -- nichts gemerkt (dann greift der Rueckfall), oder findet auch der
    -- Rueckfall den Platz nicht (dann steht der Grund daneben)?
    local slot, reason = ResolveSlot()

    Say("  Haken: Platz " .. tostring(currentSlot)
        .. ", Herkunft " .. tostring(currentSource))
    Say("  Ermittelt: Platz " .. tostring(slot)
        .. (reason and (" (" .. reason .. ")") or ""))
end
