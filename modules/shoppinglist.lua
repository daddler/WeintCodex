--------------------------------------------------
-- WeintCodex :: Einkaufsliste am Auktionshaus (seit 2.7.2.0)
--------------------------------------------------
-- Das Addon weiss laengst, welcher Sockel leer ist und welche
-- Verzauberung fehlt. Nur steht diese Auskunft auf einer Seite, die man
-- vor dem Auktionshaus aufmacht, sich merkt und dann doch die Haelfte
-- vergisst. Der Ort, an dem sie gebraucht wird, ist das Auktionshaus —
-- also steht sie jetzt dort.
--
-- SIE RECHNET NICHTS.
--
-- Was fehlt und was stattdessen hingehoert, entscheidet
-- WeintCodex.Charakter.Scan() — dort stehen Spec-Profil, Grenzen,
-- Sockelboni und der Umschmiede-Ausblick. Diese Datei liest das Ergebnis
-- und zaehlt zusammen. Eine zweite Bewertung nebenher waere genau die
-- Doppelung, an der die Sockelbewertung ueber fuenf Releases gescheitert
-- ist (siehe PlanItem in modules/charakter.lua).
--
-- WAS AUF DIE LISTE KOMMT, IST EIN EINKAUF — KEIN BEFUND.
--
-- Ein leerer Sockel, ein Stein, der nachweislich falsch sitzt, eine
-- fehlende Verzauberung: dafuer geht man ins Auktionshaus. Ein Stein mit
-- dem Urteil "ok" dagegen ist eine Abwaegung, kein Mangel — er steht auf
-- der Sockelseite und nicht hier. Eine Einkaufsliste, auf der Dinge
-- stehen, die man nicht braucht, wird nicht benutzt.
--
-- UND SIE SUCHT SELBST.
--
-- Ein Klick auf eine Zeile traegt den Namen in die Suche des
-- Auktionshauses ein und stoesst sie an. Das ist der einzige Grund, warum
-- diese Liste hier besser aufgehoben ist als auf einem Zettel: sie nimmt
-- einem das Abtippen ab. Findet der Client die Suchfelder nicht, sagt die
-- Zeile das — statt stillschweigend nichts zu tun.
--
-- WELCHES AUKTIONSHAUS DAS IST, WEISS NUR DER CLIENT (seit 2.7.3.2).
--
-- Diese Datei ist mit 2.7.2.0 gekommen und hat bis 2.7.3.1 kein einziges
-- Mal funktioniert: sie hing an `AuctionFrame` und `BrowseName`, dem
-- Auktionshaus von 5.4.8. Mists Classic hat das ueberarbeitete
-- (`AuctionHouseFrame`, seit Phase 4 von Cataclysm Classic), und damit war
-- die Bedingung einfach nie erfuellt — lautlos. Beide Namen werden jetzt
-- gesucht, `/wc einkauf pruefen` sagt welcher gefunden wurde, und das
-- Ereignis allein reicht zum Aufgehen (siehe unten bei AuctionWindow).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.ShoppingList = {}

local SL = WeintCodex.ShoppingList
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts

local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

local DEFAULTS = { enabled = true }

local function Store()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local sd = WeintCodex.SavedData
    sd.shopping = sd.shopping or {}
    for key, value in pairs(DEFAULTS) do
        if sd.shopping[key] == nil then sd.shopping[key] = value end
    end
    return sd.shopping
end

function SL.GetOption(key)  return Store()[key] end
function SL.SetOption(key, value) Store()[key] = value and true or false end

local function Say(text)
    print(WeintCodex.ColorText("gold", "[WeintCodex]") .. " " .. text)
end

--------------------------------------------------
-- Die Liste
--------------------------------------------------
-- Rueckgabe: Liste von { kind, name, icon, count, note, itemId, search }
-- `search` ist der Text, mit dem gesucht wird — oder nil, wenn wir keinen
-- verlaesslichen Namen haben. Dann bleibt die Zeile stehen (der Befund
-- gilt trotzdem), nur klicken kann man sie nicht.
--------------------------------------------------

local function EnchantName(id)
    local db = WeintCodex_Enchants and WeintCodex_Enchants[id]
    return db and db.name
end

function SL.Build()
    local Ch = WeintCodex.Charakter
    if not (Ch and Ch.Scan) then return nil, "Charaktermodul nicht geladen." end

    local scan = Ch.Scan()
    if not scan then return nil, "Kein Ausrüstungs-Scan." end

    local items, byGem = {}, {}

    -- STEINE: leerer Sockel oder ein Stein, der nachweislich falsch sitzt.
    for _, row in ipairs((scan.gems and scan.gems.rows) or {}) do
        local wanted = row.recId
        local buy = (row.status == "missing")
                 or (row.status == "wrong")
                 or (row.status == "overcap")
        -- Ohne Basisdaten wird nichts behauptet (dieselbe Regel wie
        -- ueberall): eine Zeile, die der Client noch nicht lesen konnte,
        -- ist keine Einkaufsempfehlung.
        if buy and wanted and row.socketsKnown ~= false then
            local entry = byGem[wanted]
            if entry then
                entry.count = entry.count + 1
            else
                local name = WeintCodex_GetGemName and WeintCodex_GetGemName(wanted)
                local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(wanted)
                entry = {
                    kind   = "gem",
                    itemId = wanted,
                    name   = name or ("Stein " .. tostring(wanted)),
                    icon   = icon,
                    count  = 1,
                    search = name,
                    slots  = {},
                }
                byGem[wanted] = entry
                items[#items + 1] = entry
            end
            entry.slots[#entry.slots + 1] = row.slotName
        end
    end

    -- VERZAUBERUNGEN: nur die fehlenden. "Nicht ideal" ist eine Abwaegung
    -- und gehoert auf die Verzauberungsseite, nicht auf einen Einkaufszettel.
    for _, row in ipairs((scan.enchants and scan.enchants.rows) or {}) do
        if row.status == "missing" and row.recId then
            local name = EnchantName(row.recId)
            items[#items + 1] = {
                kind   = "enchant",
                name   = name or ("Verzauberung " .. tostring(row.recId)),
                note   = row.slotName,
                count  = 1,
                -- In MoP handeln Verzauberer ueber Pergamente, und die
                -- heissen im Auktionshaus wie die Verzauberung. Ohne Namen
                -- aus der Datenbank wird nicht geraten.
                search = name,
            }
        end
    end

    return items
end

--------------------------------------------------
-- Das Fenster des Auktionshauses
--------------------------------------------------
-- WELCHES FENSTER DAS IST, WIRD DEN CLIENT GEFRAGT.
--
-- Bis 2.7.3.1 stand hier fest `AuctionFrame` — das Auktionshaus, wie es
-- 5.4.8 hatte. Der Client von Mists Classic hat es nicht mehr: mit der
-- vierten Phase von Cataclysm Classic ist das ueberarbeitete Auktionshaus
-- dazugekommen (`AuctionHouseFrame`), und es ist mitgewandert. Damit war
-- `_G.AuctionFrame` schlicht `nil` — die Einkaufsliste ging am
-- Auktionshaus nie auf, und zwar lautlos: die Bedingung war einfach nie
-- erfuellt.
--
-- Genau die Sorte stiller Rueckfallweg, die es hier nicht geben darf
-- (dieselbe Lehre wie beim Signalton in modules/gearalert.lua und beim
-- Einladungslauf in modules/calendar.lua). Gesucht wird deshalb unter
-- mehreren Namen, und das Ergebnis steht in `/wc einkauf pruefen`.
--------------------------------------------------

local WINDOW_NAMES = { "AuctionHouseFrame", "AuctionFrame" }

local function AuctionWindow()
    for _, name in ipairs(WINDOW_NAMES) do
        local f = _G[name]
        if f and f.IsShown and f:IsShown() then return f, name end
    end
    return nil
end

--------------------------------------------------
-- Suche im Auktionshaus
--
-- Der Klick IST das Hardware-Ereignis, also darf von hier aus gesucht
-- werden. Gefragt wird trotzdem erst, ob es die Felder gibt: die
-- Oberflaeche des Auktionshauses wird nachgeladen, und ihre Innereien sind
-- nichts, worauf man sich blind verlaesst.
--
-- ANGESTOSSEN WIRD SIE UEBER DEN WEG, DEN DER SPIELER AUCH NIMMT.
-- Der Text kommt ins Suchfeld, dann laeuft dessen eigenes
-- "Eingabetaste"-Skript. Das ist der einzige Ausloeser, den es in jedem
-- Clientstand gibt — die Namen der Suchfunktionen dahinter haben sich
-- zwischen den Auktionshaeusern geaendert, das Feld und seine Taste nicht.
--------------------------------------------------

-- Rueckgabe: Suchfeld, Liste moeglicher Ausloeser (Name + Funktion).
local function SearchTargets()
    local ah = _G.AuctionHouseFrame
    local bar = ah and ah.SearchBar
    local box = bar and bar.SearchBox
    if box and box.SetText then
        local runs = {}
        local enter = box.GetScript and box:GetScript("OnEnterPressed")
        if enter then
            runs[#runs + 1] = { "SearchBox:OnEnterPressed", function() enter(box) end }
        end
        if bar.StartSearch then
            runs[#runs + 1] = { "SearchBar:StartSearch", function() bar:StartSearch() end }
        end
        local btn = bar.SearchButton
        if btn and btn.Click then
            runs[#runs + 1] = { "SearchBar.SearchButton:Click", function() btn:Click() end }
        end
        return box, runs, "AuctionHouseFrame.SearchBar.SearchBox"
    end

    -- Das Auktionshaus vor Cataclysm Phase 4. Bleibt stehen: ein Client,
    -- der es noch fuehrt, soll die Suche behalten.
    local old = _G.BrowseName
    local run = _G.AuctionFrameBrowse_Search
    if old and old.SetText and run then
        return old, { { "AuctionFrameBrowse_Search", run } }, "BrowseName"
    end

    return nil, {}, nil
end

function SL.Search(text)
    if not text or text == "" then return false end

    local box, runs = SearchTargets()
    if not box then return false end

    -- Auf den Reiter "Durchsuchen" wechseln, sonst sucht man in einem
    -- Fenster, das man nicht sieht. Nur das alte Auktionshaus hat ihn.
    local tab = _G.AuctionFrameTab1
    if tab and tab.Click and _G.AuctionFrameBrowse and not _G.AuctionFrameBrowse:IsShown() then
        pcall(tab.Click, tab)
    end

    if not pcall(box.SetText, box, text) then return false end

    for _, entry in ipairs(runs) do
        if pcall(entry[2]) then return true, entry[1] end
    end
    return false
end

--------------------------------------------------
-- Das Fenster
--------------------------------------------------
-- Eckig und ohne Eckmasken, aus demselben Grund wie der Ausruestungs-Alarm
-- und das Umschmieder-Fenster: die Masken aus core/ui.lua brauchen die
-- Farbe des Untergrunds, und dahinter liegt hier das Auktionshaus.
--------------------------------------------------

local frame, rows = nil, {}

local WIDTH  = 260
local HEAD_H = 40
local ROW_H  = 34

local function Build()
    if frame then return frame end

    frame = CreateFrame("Frame", "WeintCodexShoppingList", UIParent)
    frame:SetSize(WIDTH, 120)
    -- EIN FENSTER OHNE ANKERPUNKT ZEICHNET DER CLIENT NICHT. Die Stelle
    -- unten wird gleich ueberschrieben — von der gemerkten Position oder
    -- vom Auktionshaus. Aber wenn beides fehlt (`/wc einkauf` fernab vom
    -- Auktionshaus), stand das Fenster bis 2.7.3.1 ohne jeden Punkt da und
    -- war unsichtbar: `Show()` gelingt, zu sehen ist nichts, und
    -- verschieben kann man es auch nicht.
    frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        Store().pos = { point = point, x = x, y = y }
    end)

    SetSolidBg(frame, C.bgDark[1], C.bgDark[2], C.bgDark[3], 0.97)
    DrawBorder(frame, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)

    local header = CreateFrame("Frame", nil, frame)
    header:SetHeight(HEAD_H)
    header:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    SetSolidBg(header, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)

    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(F.serif, 13, "")
    title:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -7)
    title:SetTextColor(unpack(C.textBright))
    title:SetText("Einkaufsliste")

    frame.sub = header:CreateFontString(nil, "OVERLAY")
    frame.sub:SetFont(F.mono, 9, "")
    frame.sub:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -23)
    frame.sub:SetPoint("RIGHT",   header, "RIGHT", -28, 0)
    frame.sub:SetJustifyH("LEFT")
    frame.sub:SetTextColor(unpack(C.textFaint))

    local close = CreateFrame("Button", nil, header)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -8, -7)
    local lbl = close:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(F.mono, 11, "")
    lbl:SetAllPoints(close)
    lbl:SetJustifyH("CENTER")
    lbl:SetTextColor(unpack(C.textMuted))
    lbl:SetText("x")
    close:SetScript("OnClick", function() frame:Hide() end)

    frame.list = CreateFrame("Frame", nil, frame)
    frame.list:SetPoint("TOPLEFT",  frame, "TOPLEFT",  8, -(HEAD_H + 6))
    frame.list:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -(HEAD_H + 6))
    frame.list:SetHeight(10)

    frame.hint = frame:CreateFontString(nil, "OVERLAY")
    frame.hint:SetFont(F.sans, 9, "")
    frame.hint:SetJustifyH("LEFT")
    frame.hint:SetTextColor(unpack(C.textFaint))

    local pos = Store().pos
    if pos and pos.point then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end

    frame:Hide()
    return frame
end

local function Row(index)
    local row = rows[index]
    if row then return row end

    row = CreateFrame("Button", nil, frame.list)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT",  frame.list, "TOPLEFT",  0, -((index - 1) * ROW_H))
    row:SetPoint("TOPRIGHT", frame.list, "TOPRIGHT", 0, -((index - 1) * ROW_H))

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.name = row:CreateFontString(nil, "OVERLAY")
    row.name:SetFont(F.sans, 11, "")
    row.name:SetPoint("TOPLEFT",  row, "TOPLEFT",  32, -4)
    row.name:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -4)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row.note = row:CreateFontString(nil, "OVERLAY")
    row.note:SetFont(F.mono, 9, "")
    row.note:SetPoint("TOPLEFT",  row, "TOPLEFT",  32, -18)
    row.note:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -18)
    row.note:SetJustifyH("LEFT")
    row.note:SetWordWrap(false)
    row.note:SetTextColor(unpack(C.textFaint))

    -- Einmal angelegt und danach nur noch ein- und ausgeblendet: WoW gibt
    -- Texturen nie wieder frei, und eine je Ueberfahren waere eine
    -- Sammlung, die nur waechst (dieselbe Regel wie beim Seitengeruest der
    -- Einstellungen).
    row.hl = SetSolidBg(row, C.surface2[1], C.surface2[2], C.surface2[3], 0.7)
    row.hl:Hide()

    row:SetScript("OnEnter", function(self)
        self.hl:Show()
        if self._entry and self._entry.itemId then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetItemByID(self._entry.itemId)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        self.hl:Hide()
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self)
        local entry = self._entry
        if not (entry and entry.search) then
            Say("Für diese Zeile kenne ich keinen Namen zum Suchen.")
            return
        end
        if not SL.Search(entry.search) then
            Say("Die Suche des Auktionshauses ist von hier aus nicht erreichbar —"
                .. " Name: |cffD4A24A" .. entry.search .. "|r")
        end
    end)

    rows[index] = row
    return row
end

function SL.Refresh()
    if not frame then return end

    local items, problem = SL.Build()
    local shown = 0

    for _, entry in ipairs(items or {}) do
        shown = shown + 1
        local row = Row(shown)
        row._entry = entry

        if entry.icon then
            row.icon:SetTexture(entry.icon)
            row.icon:Show()
        else
            row.icon:Hide()
        end

        row.name:SetText((entry.count > 1 and (entry.count .. "× ") or "") .. entry.name)
        row.name:SetTextColor(unpack(entry.kind == "gem" and C.textNormal or C.textDim))
        row.note:SetText(entry.kind == "gem"
            and table.concat(entry.slots, ", ")
            or ("Verzauberung · " .. (entry.note or "")))
        row:Show()
    end

    for i = shown + 1, #rows do rows[i]:Hide() end

    frame.list:SetHeight(math.max(1, shown * ROW_H))

    if problem then
        frame.sub:SetText(problem)
    elseif shown == 0 then
        frame.sub:SetText(WeintCodex.ColorText("green", "Nichts zu besorgen."))
    else
        frame.sub:SetText(shown .. " Posten · Klick sucht danach")
    end

    frame.hint:ClearAllPoints()
    frame.hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 10,
        -(HEAD_H + 6 + shown * ROW_H + 6))
    frame.hint:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    frame.hint:SetText(shown > 0
        and "Fehlende Verzauberungen und Steine für leere oder falsch besetzte Sockel."
        or "")

    frame:SetHeight(HEAD_H + 6 + shown * ROW_H + (shown > 0 and 34 or 14))
end

function SL.Show(manual)
    if not (WeintCodex.Charakter and WeintCodex.Charakter.Scan) then
        if manual then Say("Charaktermodul nicht geladen.") end
        return
    end
    Build()
    SL.Refresh()

    -- Neben das Auktionshaus, solange es offen ist. Sonst bleibt die
    -- zuletzt gezogene Stelle — und wenn es die auch nicht gibt, der
    -- Ankerpunkt aus Build().
    local ah = AuctionWindow()
    if ah and not Store().pos then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", ah, "TOPRIGHT", 4, 0)
    end

    frame:Show()
end

function SL.Hide()
    if frame then frame:Hide() end
end

function SL.Toggle()
    if frame and frame:IsShown() then SL.Hide() else SL.Show(true) end
end

--------------------------------------------------
-- Diagnose
--------------------------------------------------
-- Aus demselben Grund wie /wc sockel, /wc tempo und /wc vz zeilen: von
-- aussen sieht "es kommt kein Fenster" bei einem abgewaehlten Charakter,
-- einem ausgeschalteten Schalter, einem leeren Befund und einem Namen, den
-- dieser Client gar nicht fuehrt, voellig gleich aus. Genau daran hat die
-- Einkaufsliste eine ganze Fassung lang stumm danebengelegen.
--------------------------------------------------

function SL.Dump()
    Say("Einkaufsliste — was der Client hergibt:")

    print("  Schalter: " .. (Store().enabled and "an" or "aus")
        .. " · Mitreden: " .. ((not WeintCodex.OptIn or WeintCodex.OptIn.Active())
            and "ja" or "nein (/wc hier)"))

    for _, name in ipairs(WINDOW_NAMES) do
        local f = _G[name]
        print("  " .. name .. ": " .. (f
            and ("vorhanden, " .. ((f.IsShown and f:IsShown()) and "offen" or "zu"))
            or "kennt der Client nicht"))
    end

    local box, runs, where = SearchTargets()
    print("  Suchfeld: " .. (where or "nicht gefunden"))
    if box then
        local names = {}
        for _, entry in ipairs(runs) do names[#names + 1] = entry[1] end
        print("  Ausloeser: " .. (#names > 0 and table.concat(names, ", ")
            or "keiner — der Text landet im Feld, gesucht wird von Hand"))
    end

    local items, problem = SL.Build()
    if problem then
        print("  Liste: " .. problem)
    else
        print("  Liste: " .. #(items or {}) .. " Posten")
        for _, entry in ipairs(items or {}) do
            print("    " .. entry.count .. "x " .. entry.name
                .. " · " .. (entry.search and "suchbar" or "kein Name zum Suchen"))
        end
    end
end

function SL.Command(rest)
    if rest == "pruefen" or rest == "prüfen" or rest == "check" then
        SL.Dump()
        return
    end
    SL.Toggle()
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local watcher = CreateFrame("Frame")
for _, event in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED" }) do
    pcall(watcher.RegisterEvent, watcher, event)
end

watcher:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_SHOW" then
        if not Store().enabled then return end
        -- "Hier nicht mitreden" (core/optin.lua): ein Fenster, das von
        -- selbst aufgeht, ist genau das, was dort abgewaehlt wurde.
        if WeintCodex.OptIn and not WeintCodex.OptIn.Active() then return end
        -- Der Ausruestungs-Scan liest je Gegenstand den Tooltip; beim
        -- Oeffnen des Auktionshauses ist der Client ohnehin beschaeftigt.
        -- DAS EREIGNIS IST DIE AUSKUNFT, NICHT DAS FENSTER. Bis 2.7.3.1
        -- hing der Aufruf daran, dass `AuctionFrame` da und sichtbar ist;
        -- kennt der Client diesen Namen nicht, passierte nichts — und
        -- nichts sagte, warum. Der Client hat gerade gemeldet, dass das
        -- Auktionshaus offen ist; das genuegt. Wo das Fenster steht, ist
        -- eine Frage der Position und keine Bedingung mehr.
        --
        -- Der Ausruestungs-Scan liest je Gegenstand den Tooltip; beim
        -- Oeffnen des Auktionshauses ist der Client ohnehin beschaeftigt.
        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, function() SL.Show(false) end)
        else
            SL.Show(false)
        end
    else
        SL.Hide()
    end
end)
