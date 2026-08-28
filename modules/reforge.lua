--------------------------------------------------
-- WeintCodex :: Umschmieden — Seite & Umschmieder-Fenster (BETA)
--------------------------------------------------
-- Zwei Oberflaechen ueber demselben Plan aus modules/reforge_engine.lua:
--
--   * die Unterseite "Umschmieden" unter Charakter — dort wird gelesen,
--     was warum umgeschmiedet werden soll;
--   * ein freistehendes Fenster beim Umschmieder, das genau das mit einem
--     Klick ausfuehrt.
--
-- BEIDE ZEIGEN DENSELBEN PLAN, UND ZWAR DENSELBEN AUFRUF.
-- Ein Fenster, das beim Umschmieder noch einmal selbst rechnet, koennte
-- etwas anderes anlegen, als auf der Seite stand — und das faellt erst auf,
-- wenn das Gold weg ist. `RE.GetPlan()` haelt sein Ergebnis, bis sich an
-- Ausruestung, Spec oder Zielen etwas aendert.
--
-- DAS WERKZEUG IST AUS, SOLANGE ES NIEMAND EINSCHALTET.
-- Es ist in Entwicklung, seine Vorschlaege sind noch nicht belastbar, und
-- es gibt Gold aus. Ein Beta-Werkzeug, das von selbst mitredet, ist der
-- Grund, warum man Addons abschaltet. Der Schalter steht unter
-- Einstellungen -> Umschmieden; der Hinweis auf den Entwicklungsstand steht
-- dort, auf der Seite und im Fenster, nicht nur an einer der drei Stellen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Reforge = {}

local RF = WeintCodex.Reforge
local RE = WeintCodex.ReforgeEngine
local R  = WeintCodex_Reforge
local C  = WeintCodex.Colors
local F  = WeintCodex.Fonts

local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

local BETA_TEXT = "Dieses Werkzeug ist noch in Entwicklung. Die Vorschläge"
    .. " sind noch nicht verlässlich — sieh sie dir an, bevor du Gold ausgibst."

local function Say(text)
    print(WeintCodex.ColorText("gold", "[WeintCodex]") .. " " .. text)
end

local function Coins(copper)
    if _G.GetCoinTextureString and copper and copper > 0 then
        return GetCoinTextureString(copper)
    end
    return "—"
end

local function Rating(value)
    return WeintCodex.FormatGrouped and WeintCodex.FormatGrouped(math.floor((value or 0) + 0.5))
        or tostring(math.floor((value or 0) + 0.5))
end

--------------------------------------------------
-- Ist die geplante Umschmiedung schon angelegt?
--
-- Gefragt wird am LINK des Slots, nicht am Plan: waehrend eines Laufs
-- aendert sich der Gegenstand unter der Hand, und ein Plan, der beim
-- Aufbau der Seite entstanden ist, weiss davon nichts. Ohne diese Frage
-- wuerde der Lauf jeden Slot noch einmal anfassen und noch einmal
-- bezahlen.
--------------------------------------------------

local function SlotMatches(slotId, target)
    local pair = RE.CurrentPair(slotId)
    if not target then return pair == nil end
    return pair ~= nil and pair.src == target.src and pair.dst == target.dst
end

--------------------------------------------------
-- SEITE: Charakter -> Umschmieden
--------------------------------------------------

local pageFrame = nil
local PAD_X  = 16
local HEAD_H = 78   -- dieselbe Kopfhoehe wie die uebrigen Charakter-Seiten

local function ClearContent()
    local cp = WeintCodex.ContentPanel
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
end

-- Steht unsere Seite gerade vorn? Gefragt wird am Rahmen und nicht an
-- einem eigenen Merker: wechselt der Nutzer auf eine andere
-- Charakter-Unterseite, versteckt jene alle Kinder des Inhaltsbereichs —
-- ein Merker wuesste davon nichts und liesse uns die fremde Seite
-- ueberzeichnen (dieselbe Kopplung, wegen der es Charakter.LeaveView gibt).
local function PageVisible()
    return pageFrame ~= nil and pageFrame:IsShown()
end

local function Text(parent, size, semi)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(semi and F.sansSemi or F.sans, size, "")
    fs:SetJustifyH("LEFT")
    return fs
end

local function Mono(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(F.monoMedium or F.mono, size, "")
    fs:SetJustifyH("RIGHT")
    return fs
end

--------------------------------------------------
-- Zielbalken: Istwert, Stand nach dem Plan, Ziel
--
-- Zwei Marken auf einer Bahn statt zweier Bahnen untereinander: gefragt
-- ist nicht "wo stehe ich" und "wo stuende ich", sondern der Weg zwischen
-- beiden. Die Zahl darueber bleibt die eigentliche Auskunft — ein Balken
-- ohne Zahl ist ein Gefuehl.
--------------------------------------------------

local BAR_H = 8

local function DrawTargetBar(parent, x, y, width, entry)
    local label = Text(parent, 11, true)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetTextColor(unpack(C.textNormal))
    label:SetText(entry.label)

    local reached = entry.after >= entry.target - 1
    local value = Mono(parent, 11)
    value:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -(x), y - 1)
    value:SetWidth(220)
    value:SetTextColor(unpack(reached and C.green or C.gold))
    if math.abs(entry.after - entry.before) < 1 then
        value:SetText(Rating(entry.after) .. " / " .. Rating(entry.target))
    else
        value:SetText(Rating(entry.before) .. "  →  " .. Rating(entry.after)
            .. "  / " .. Rating(entry.target))
    end

    y = y - 18

    local track = parent:CreateTexture(nil, "ARTWORK")
    track:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    track:SetSize(width, BAR_H)
    track:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)

    local scale = math.max(entry.target, entry.before, entry.after, 1)
    local function Fill(value, colour, alpha, height, offset)
        local w = math.max(1, math.min(width, width * (value / scale)))
        local tex = parent:CreateTexture(nil, "OVERLAY")
        tex:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - (offset or 0))
        tex:SetSize(w, height or BAR_H)
        tex:SetColorTexture(colour[1], colour[2], colour[3], alpha)
        return tex
    end

    Fill(entry.before, C.textFaint, 0.9)
    Fill(entry.after, reached and C.green or C.gold, 0.95, BAR_H - 3, 0)

    -- Zielmarke
    local markX = x + math.min(width, width * (entry.target / scale))
    local mark = parent:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("TOPLEFT", parent, "TOPLEFT", markX - 1, y - 2)
    mark:SetSize(2, BAR_H + 4)
    mark:SetColorTexture(C.textBright[1], C.textBright[2], C.textBright[3], 0.85)

    return 18 + BAR_H + 12
end

--------------------------------------------------
-- Eine Zeile der Planungsliste
--------------------------------------------------

local ROW_H = 42

local function DrawPlanRow(parent, x, y, width, row, index)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, ROW_H)
    SetSolidBg(frame, C.surface2[1], C.surface2[2], C.surface2[3],
        index % 2 == 0 and 0.45 or 0.28)

    if row.icon then
        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(26, 26)
        icon:SetPoint("LEFT", frame, "LEFT", 6, 0)
        icon:SetTexture(row.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    local name = Text(frame, 12, true)
    name:SetPoint("TOPLEFT", frame, "TOPLEFT", 38, -5)
    name:SetWidth(width - 300)
    name:SetTextColor(unpack(C.textNormal))
    name:SetText(row.name)

    local slot = Text(frame, 9)
    slot:SetPoint("TOPLEFT", frame, "TOPLEFT", 38, -21)
    slot:SetWidth(width - 300)
    slot:SetTextColor(unpack(C.textFaint))
    slot:SetText(row.slotName .. (row.locked and "  ·  gesperrt" or ""))

    -- Die Umschmiedung selbst. Der Pfeil traegt die ganze Auskunft: was
    -- geht weg, was kommt dazu, wieviel.
    local move = Mono(frame, 12)
    move:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -6)
    move:SetWidth(250)

    local reason = Text(frame, 9)
    reason:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -22)
    reason:SetWidth(250)
    reason:SetJustifyH("RIGHT")
    reason:SetTextColor(unpack(C[row.reasonTone or "textDim"] or C.textDim))
    reason:SetText(row.reason or "")

    if row.problem then
        move:SetTextColor(unpack(C.red))
        move:SetText("nicht planbar")
        reason:SetTextColor(unpack(C.textDim))
        reason:SetText(row.problem)
    elseif row.warning then
        -- Der Widerspruch verbietet nichts (siehe modules/reforge_engine.lua),
        -- aber er steht an der Zeile: die Betraege daran sind unsicher.
        slot:SetTextColor(unpack(C.gold))
        slot:SetText(row.slotName .. "  ·  " .. row.warning)
    end

    if not row.problem then
        if row.target then
            move:SetTextColor(unpack(C.textBright))
            move:SetText(string.format("%s  →  %s   |cff7CC06E+%d|r",
                R.SHORT[R.STATS[row.target.src]],
                R.SHORT[R.STATS[row.target.dst]],
                row.target.amount))
        else
            move:SetTextColor(unpack(C.textDim))
            move:SetText("—")
        end
    end

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if row.link then GameTooltip:SetHyperlink(row.link) else GameTooltip:SetText(row.name) end
        GameTooltip:AddLine(" ")
        if row.current then
            GameTooltip:AddLine(string.format("Jetzt: %s → %s (+%d)",
                R.LABEL[R.STATS[row.current.src]],
                R.LABEL[R.STATS[row.current.dst]], row.current.amount), 0.66, 0.66, 0.69)
        else
            GameTooltip:AddLine("Jetzt: nicht umgeschmiedet", 0.66, 0.66, 0.69)
        end
        if row.cost then
            GameTooltip:AddLine("Kosten: " .. Coins(row.cost), 0.83, 0.64, 0.29)
        end
        GameTooltip:AddLine(row.locked and "Linksklick: Sperre aufheben"
                                       or "Linksklick: dieses Teil in Ruhe lassen",
            0.42, 0.38, 0.35)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:SetScript("OnClick", function()
        RE.SetLocked(row.slot, not row.locked)
        RF.ShowPage()
    end)

    return ROW_H + 4
end

--------------------------------------------------
-- Der Inspektor rechts
--------------------------------------------------

local function BuildInspector(plan)
    local blocks = {}

    blocks[#blocks + 1] = { type = "header", text = "Umschmieden (Beta)" }

    if not plan.ok then
        blocks[#blocks + 1] = { type = "rows", rows = {
            { label = "Zustand",
              value = plan.computing and "wird gerechnet" or "kein Plan",
              valueColor = plan.computing and "gold" or "textFaint" },
        }}
        WeintCodex.Navigation.SetInspector(blocks)
        return
    end

    local gain = 0
    if plan.scoreBefore and plan.scoreBefore > 0 then
        gain = (plan.scoreAfter - plan.scoreBefore) / plan.scoreBefore * 100
    end

    blocks[#blocks + 1] = { type = "rows", rows = {
        { label = "Teile zu ändern", value = tostring(plan.changes),
          valueColor = plan.changes > 0 and "gold" or "green" },
        { label = "Kosten",          value = plan.cost > 0 and Coins(plan.cost) or "—" },
        { label = "Bewertung",       value = string.format("%+.1f %%", gain),
          valueColor = gain > 0.05 and "green" or "textFaint" },
    }}

    local targets = RE.TargetSummary(plan)
    if #targets > 0 then
        local rows = {}
        for _, entry in ipairs(targets) do
            local reached = entry.after >= entry.target - 1
            rows[#rows + 1] = {
                label = entry.label,
                value = reached and "erreicht"
                    or string.format("−%s", Rating(entry.target - entry.after)),
                valueColor = reached and "green" or "gold",
            }
        end
        blocks[#blocks + 1] = { type = "divider" }
        blocks[#blocks + 1] = { type = "header", text = "Nach dem Plan" }
        blocks[#blocks + 1] = { type = "rows", rows = rows }
    end

    blocks[#blocks + 1] = { type = "divider" }
    blocks[#blocks + 1] = { type = "button", style = "primary",
        label = "Fenster ansehen", onClick = function() RF.ShowForge(true) end }
    blocks[#blocks + 1] = { type = "button",
        label = "Alle Sperren lösen", onClick = function()
            local store = WeintCodex.SavedData and WeintCodex.SavedData.reforge
            if store then store.locked = {} end
            RE.Invalidate()
            RF.ShowPage()
        end }
    -- Der Weg zurueck zur anderen Haelfte derselben Frage: die
    -- Sockelempfehlungen rechnen mit genau diesem Plan (siehe
    -- ScanCharacter in modules/charakter.lua).
    blocks[#blocks + 1] = { type = "button",
        label = "Zu den Sockeln", onClick = function()
            if WeintCodex.Charakter and WeintCodex.Charakter.ShowGems then
                WeintCodex.Charakter.ShowGems()
            end
        end }
    blocks[#blocks + 1] = { type = "button",
        label = "Diagnose ausgeben", onClick = function() RF.Dump() end }

    WeintCodex.Navigation.SetInspector(blocks)
end

--------------------------------------------------
-- Die Seite
--------------------------------------------------

function RF.ShowPage()
    local cp = WeintCodex.ContentPanel
    if not cp then return end

    -- Diese Seite gehoert zu Charakter, wird aber nicht von
    -- modules/charakter.lua gezeichnet. Ohne diesen Aufruf legte dessen
    -- Ausruestungs-Watcher die zuletzt gezeigte Charakterseite darueber,
    -- sobald sich etwas an der Ausruestung aendert (dieselbe Kopplung wie
    -- bei modules/academy.lua).
    if WeintCodex.Charakter and WeintCodex.Charakter.LeaveView then
        WeintCodex.Charakter.LeaveView()
    end
    ClearContent()
    if pageFrame then pageFrame:Hide(); pageFrame = nil end

    WeintCodex.SetBreadcrumb("Charakter", "Umschmieden")

    local plan = RE.GetPlan()

    pageFrame = CreateFrame("Frame", nil, cp)
    pageFrame:SetAllPoints(cp)

    local head = WeintCodex.PageHead(pageFrame, {
        eyebrow = "Charakter",
        title   = "Umschmieden",
        sub     = "",
        titleSize = 20, subSize = 10,
        x = PAD_X, y = 14, height = HEAD_H - 14,
    })
    head.Sub:SetText(WeintCodex.ColorText("gold", "BETA") .. "  "
        .. WeintCodex.ColorText("textFaint",
            plan.specDisplay and ("Spec: " .. plan.specDisplay) or "Spec unbekannt"))

    local y = -HEAD_H

    -- Der Hinweis auf den Entwicklungsstand steht ueber allem anderen und
    -- nicht als Fussnote: wer die Zahlen zuerst liest, hat ihn nicht mehr
    -- gesehen, wenn er beim Umschmieder steht.
    local warn = CreateFrame("Frame", nil, pageFrame)
    warn:SetPoint("TOPLEFT",  pageFrame, "TOPLEFT",  PAD_X, y)
    warn:SetPoint("TOPRIGHT", pageFrame, "TOPRIGHT", -PAD_X, y)
    warn:SetHeight(34)
    SetSolidBg(warn, C.gold[1], C.gold[2], C.gold[3], 0.10)
    DrawBorder(warn, C.gold[1], C.gold[2], C.gold[3], 0.45, 1)

    local warnText = Text(warn, 11)
    warnText:SetPoint("LEFT",  warn, "LEFT",  10, 0)
    warnText:SetPoint("RIGHT", warn, "RIGHT", -10, 0)
    warnText:SetTextColor(unpack(C.goldBright))
    warnText:SetText(BETA_TEXT)

    y = y - 44

    if not plan.ok then
        local msg = Text(pageFrame, 12)
        msg:SetPoint("TOPLEFT",  pageFrame, "TOPLEFT",  PAD_X, y)
        msg:SetPoint("TOPRIGHT", pageFrame, "TOPRIGHT", -PAD_X, y)
        if plan.computing then
            -- Der Suchlauf geht ueber sechzehn Slots und rechnet in
            -- Haeppchen; er meldet sich von selbst, sobald er fertig ist
            -- (RE.OnPlanReady weiter unten). Ein Fortschrittsbalken waere
            -- hier eine Beschaeftigung fuer eine gute halbe Sekunde.
            msg:SetTextColor(unpack(C.gold))
            msg:SetText("Wird gerechnet …")
        else
            msg:SetTextColor(unpack(C.textDim))
            msg:SetText(plan.problem or "Kein Plan.")
        end
        BuildInspector(plan)
        pageFrame:Show()
        return
    end

    local sf, body = WeintCodex.CreateScrollArea(pageFrame, PAD_X, y, 100, 100, true)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     pageFrame, "TOPLEFT",  PAD_X, y)
    sf:SetPoint("BOTTOMRIGHT", pageFrame, "BOTTOMRIGHT", -PAD_X, 26)
    sf.scrollBarHideable = true

    -- Die Breite kommt aus dem Bildlauffeld, das seine Groesse schon aus
    -- den Ankern hat. CreateScrollArea verlangt Pixelmasse und wird
    -- deshalb erst danach umgehaengt (dieselbe Reihenfolge wie auf der
    -- Seite "Werteverteilung & Caps"); die 500 ist nur der Boden, falls
    -- der Rahmen noch keine Breite meldet.
    local BODY_W = math.max(500, (sf:GetWidth() or 0) - 14)
    body:SetWidth(BODY_W)

    local by = 0
    local function Section(title)
        local fs = Text(body, 10)
        fs:SetPoint("TOPLEFT", body, "TOPLEFT", 0, by)
        fs:SetTextColor(unpack(C.textFaint))
        fs:SetText("— " .. WeintCodex.Upper(title) .. " —")
        by = by - 20
    end

    -- ZIELE
    local targets = RE.TargetSummary(plan)
    if #targets > 0 then
        Section("Grenzen und Schwellen")
        for _, entry in ipairs(targets) do
            by = by - DrawTargetBar(body, 0, by, math.max(200, BODY_W - 250), entry)
        end
        by = by - 8
    end

    -- ÄNDERUNGEN
    local changed, unchanged, blocked = {}, {}, {}
    for _, row in ipairs(plan.rows) do
        if row.problem then
            blocked[#blocked + 1] = row
        elseif row.changed then
            changed[#changed + 1] = row
        else
            unchanged[#unchanged + 1] = row
        end
    end

    Section(#changed > 0
        and string.format("Umzuschmieden (%d) · %s", #changed, Coins(plan.cost))
        or  "Umzuschmieden")

    if #changed == 0 then
        local none = Text(body, 11)
        none:SetPoint("TOPLEFT", body, "TOPLEFT", 0, by)
        none:SetTextColor(unpack(C.green))
        none:SetText("Nach dieser Rechnung sitzt schon alles richtig.")
        by = by - 26
    else
        for index, row in ipairs(changed) do
            by = by - DrawPlanRow(body, 0, by, BODY_W, row, index)
        end
        by = by - 8
    end

    if #blocked > 0 then
        Section(string.format("Nicht planbar (%d)", #blocked))
        for index, row in ipairs(blocked) do
            by = by - DrawPlanRow(body, 0, by, BODY_W, row, index)
        end
        by = by - 8
    end

    if #unchanged > 0 then
        Section(string.format("Bleibt so (%d)", #unchanged))
        for index, row in ipairs(unchanged) do
            by = by - DrawPlanRow(body, 0, by, BODY_W, row, index)
        end
    end

    body:SetHeight(math.max(60, -by + 20))

    BuildInspector(plan)
    pageFrame:Show()
end

--------------------------------------------------
-- FENSTER BEIM UMSCHMIEDER
--------------------------------------------------
-- Freistehend wie der Rotationshelfer und aus demselben Grund: es gehoert
-- neben das Fenster des Umschmieders und nicht in die Navigation eines
-- zweiten Fensters, das man daneben auch noch offen halten muesste.
--------------------------------------------------

local forge          = nil
local forgeRows      = {}
local forgeCo        = nil
local forgeTicking   = false
local forgeWish      = nil    -- Klick, der auf den fertigen Plan wartet

local FORGE_W   = 340
local FORGE_HDR = 42
local FORGE_ROW = 30

-- Wie oft der Lauf von selbst nachsieht, und wie lange er auf EINEN
-- Gegenstand wartet, bevor er aufgibt.
local TICK          = 0.25
local ITEM_TIMEOUT  = 8      -- Sekunden
local WISH_TIMEOUT  = 15     -- so lange gilt ein Klick, der auf den Plan wartet

-- Vorwaertsdeklaration: der Lauf weiter unten baut das Fenster notfalls
-- selbst auf, definiert wird es aber erst danach.
local BuildForge

local function ReforgingFrameIsVisible()
    return _G.ReforgingFrame and _G.ReforgingFrame:IsShown()
end

local function Now()
    return (_G.GetTime and GetTime()) or 0
end

local function StopRun(message)
    forgeCo   = nil
    forgeWish = nil
    if forge then
        forge.action:SetText("Alles umschmieden")
    end
    if message then Say(message) end
    RE.Invalidate()
    if forge and forge:IsShown() then RF.RefreshForge() end
    if PageVisible() then RF.ShowPage() end
end

--------------------------------------------------
-- DER LAUF
--
-- Der Umschmieder beantwortet immer nur einen Gegenstand. Der Lauf ist
-- deshalb eine Koroutine, die nach jedem Auftrag anhaelt — dieselbe
-- Bauform wie in ReforgeLite, weil der Server hier den Takt vorgibt und
-- nicht wir.
--
-- GEWARTET WIRD AUF DIE BESTAETIGUNG, NICHT AUF DAS NAECHSTE EREIGNIS.
--
-- Bis 2.7.0.1 ging der Lauf nach JEDEM Aufwachen zum naechsten Gegenstand
-- weiter. Das setzt voraus, dass auf einen Auftrag genau ein Ereignis
-- kommt — und diese Annahme haelt nicht: das Einlegen in den Umschmieder
-- meldet sich ebenso wie das Umschmieden selbst, und je nach Verzoegerung
-- kommen beide in einem Rutsch. Dann schickt der Lauf den naechsten
-- Auftrag, bevor der vorige durch ist, laeuft dem Server davon, und
-- irgendwann kommt gar nichts mehr: die Koroutine steht still, der Knopf
-- heisst weiter "Abbrechen", und ein zweiter Klick bricht nur ab.
--
-- Jetzt wird nach dem Auftrag so lange gewartet, bis der ITEM-LINK des
-- Slots die neue Umschmiedung wirklich traegt. Ein Ereignis ist dabei nur
-- ein Anlass nachzusehen, kein Beweis; ein eigener Takt sieht ausserdem
-- viermal je Sekunde von sich aus nach, damit ein ausgebliebenes Ereignis
-- den Lauf nicht stehenlaesst. Das ist dieselbe Lehre wie beim
-- Kalender-Invite: gewartet wird auf Fortschritt, nicht auf eine Frist.
--
-- Und der Rueckgabewert von coroutine.resume wird gelesen. Ein Fehler
-- mitten im Lauf liess die Koroutine bis 2.7.0.1 tot zurueck, ohne dass
-- irgendetwas davon zu sehen war — genau der stille Rueckfallweg, den es
-- in diesem Addon nicht geben darf (siehe Signalton in gearalert.lua).
--------------------------------------------------

local PokeRun   -- weckt den Lauf; unten definiert

local function Tick()
    if not forgeCo then forgeTicking = false return end
    PokeRun()
    if forgeCo and C_Timer and C_Timer.After then
        C_Timer.After(TICK, Tick)
    else
        forgeTicking = false
    end
end

local function StartTicking()
    if forgeTicking or not (C_Timer and C_Timer.After) then return end
    forgeTicking = true
    C_Timer.After(TICK, Tick)
end

PokeRun = function()
    if not forgeCo then return end

    local status = coroutine.status(forgeCo)
    if status == "running" or status == "normal" then
        -- Wir stecken schon mittendrin (ein Ereignis waehrend eines
        -- Neuzeichnens). Nichts tun, aber auch nichts stillschweigend
        -- verwerfen: der Takt sieht gleich wieder nach.
        return
    end
    if status == "dead" then
        -- Zu Ende, ohne dass StopRun gelaufen waere. Dann bleibt der Knopf
        -- sonst bis zum naechsten /reload auf "Abbrechen" stehen.
        StopRun("Der Umschmiede-Lauf ist unerwartet zu Ende gegangen.")
        return
    end

    if forge and forge:IsShown() then RF.RefreshForge() end

    local ok, err = coroutine.resume(forgeCo)
    if not ok then
        forgeCo = nil
        StopRun(WeintCodex.ColorText("danger",
            "Fehler im Umschmiede-Lauf: " .. tostring(err))
            .. " Bitte mit |cffD4A24A/wc umschmieden pruefen|r melden.")
    end
end

local function RunReforge()
    for _, row in ipairs(RF.currentPlanRows or {}) do
        if not forgeCo then return end

        if row.changed and not row.locked and not row.problem
           and not SlotMatches(row.slot, row.target) then

            if not ReforgingFrameIsVisible() then
                StopRun("Das Fenster des Umschmieders ist zu.")
                return
            end

            -- Die laufende Nummer haengt an den Werten des
            -- GRUNDgegenstands, und die aendert das Umschmieden nicht.
            -- Sie stammt deshalb aus der Planzeile und nicht aus einem
            -- frischen Scan mitten im Lauf.
            local index
            if row.target then
                index = RE.ForgeIndex(row, row.target.src, row.target.dst)
            else
                index = RE.UNFORGE_INDEX
            end

            if not index then
                -- Kein gueltiger Auftrag fuer diesen Gegenstand: lieber
                -- ueberspringen als irgendeine Nummer schicken. Welche das
                -- waere, wuesste hinterher niemand.
                Say(WeintCodex.ColorText("warning",
                    row.slotName .. ": diese Umschmiedung ist für den Gegenstand"
                    .. " nicht zulässig — übersprungen."))
            else
                ClearCursor()
                PickupInventoryItem(row.slot)
                C_Reforge.SetReforgeFromCursorItem()
                C_Reforge.ReforgeItem(index)

                -- Warten, bis der Item-Link es wirklich zeigt.
                local deadline, ticks = Now() + ITEM_TIMEOUT, 0
                while not SlotMatches(row.slot, row.target) do
                    if not forgeCo then return end
                    if not ReforgingFrameIsVisible() then
                        StopRun("Das Fenster des Umschmieders ist zu.")
                        return
                    end

                    ticks = ticks + 1
                    -- Zeit zaehlt, nicht Aufwachen: Ereignisse koennen in
                    -- Schueben kommen und wuerden eine Schrittzahl in
                    -- Sekundenbruchteilen aufbrauchen. Der Zaehler ist nur
                    -- der Rueckfall, falls der Client keine Uhr hergibt.
                    if (Now() > deadline) or ticks > 200 then
                        StopRun(WeintCodex.ColorText("warning",
                            row.slotName .. ": der Umschmieder hat nicht geantwortet.")
                            .. " Lauf angehalten — genug Gold dabei? Ein erneuter Klick"
                            .. " macht dort weiter, wo er stehengeblieben ist.")
                        return
                    end

                    -- NICHTS NACHSCHICKEN. Ein zweiter Auftrag fuer
                    -- denselben Gegenstand koennte ein zweites Mal Gold
                    -- kosten, wenn der erste doch noch ankommt. Warten und
                    -- es sagen ist die ehrlichere Antwort.
                    coroutine.yield()
                end
            end
        end
    end

    ClearCursor()
    StopRun("Umschmieden abgeschlossen.")
end

function RF.StartRun()
    if not RE.Enabled() then return end
    if not (C_Reforge and C_Reforge.SetReforgeFromCursorItem and C_Reforge.ReforgeItem) then
        Say(WeintCodex.ColorText("warning",
            "Dieser Client kennt die Umschmiede-Schnittstelle nicht."))
        return
    end
    if InCombatLockdown() then
        Say("Im Kampf geht das nicht.")
        return
    end
    if not forge then
        BuildForge()
    end
    if forgeCo then
        StopRun("Abgebrochen.")
        return
    end
    if not ReforgingFrameIsVisible() then
        Say("Dafür muss das Fenster des Umschmieders offen sein.")
        return
    end

    local plan = RE.GetPlan()

    -- DER KLICK WARTET AUF DEN PLAN, DER NUTZER NICHT AUF EINEN ZWEITEN
    -- KLICK. Nach einem Abbruch ist der Plan verworfen und wird neu
    -- gerechnet (rund eine Sekunde); bis 2.7.0.1 hiess das "gleich
    -- nochmal", und genau so fuehlte es sich auch an: der erste Klick tat
    -- sichtbar nichts.
    if plan.computing then
        forgeWish = Now() + WISH_TIMEOUT
        Say("Der Plan wird noch gerechnet — der Lauf startet von selbst,"
            .. " sobald er fertig ist.")
        if forge and forge:IsShown() then RF.RefreshForge() end
        return
    end
    if not (plan.ok and plan.changes > 0) then
        Say("Es gibt nichts umzuschmieden.")
        return
    end

    RF.currentPlanRows = plan.rows
    forgeWish = nil

    ClearCursor()
    C_Reforge.SetReforgeFromCursorItem()
    ClearCursor()

    forge.action:SetText("Abbrechen")
    forgeCo = coroutine.create(RunReforge)
    StartTicking()

    local ok, err = coroutine.resume(forgeCo)
    if not ok then
        forgeCo = nil
        StopRun(WeintCodex.ColorText("danger",
            "Fehler im Umschmiede-Lauf: " .. tostring(err)))
    end
end

--------------------------------------------------
-- Aufbau des Fensters
--------------------------------------------------

function BuildForge()
    if forge then return end

    forge = CreateFrame("Frame", "WeintCodexReforgeWindow", UIParent)
    forge:SetSize(FORGE_W, 200)
    forge:SetPoint("CENTER", UIParent, "CENTER", 320, 0)
    forge:SetFrameStrata("HIGH")
    forge:SetClampedToScreen(true)
    forge:SetMovable(true)
    forge:EnableMouse(true)
    forge:RegisterForDrag("LeftButton")
    forge:SetScript("OnDragStart", function(self) self:StartMoving() end)
    forge:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        local store = WeintCodex.SavedData and WeintCodex.SavedData.reforge
        if store then store.pos = { point = point, x = x, y = y } end
    end)

    -- Eckig wie der Ausruestungs-Alarm und aus demselben Grund: die
    -- Eckmasken aus core/ui.lua brauchen die Farbe des Untergrunds, und
    -- dahinter liegt hier das Fenster des Umschmieders.
    SetSolidBg(forge, C.bgDark[1], C.bgDark[2], C.bgDark[3], 0.97)
    DrawBorder(forge, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)

    local header = CreateFrame("Frame", nil, forge)
    header:SetHeight(FORGE_HDR)
    header:SetPoint("TOPLEFT",  forge, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", forge, "TOPRIGHT", 0, 0)
    SetSolidBg(header, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)

    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(F.serif, 13, "")
    title:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -7)
    title:SetTextColor(unpack(C.textBright))
    title:SetText("Umschmieden " .. WeintCodex.ColorText("gold", "· Beta"))

    forge.sub = header:CreateFontString(nil, "OVERLAY")
    forge.sub:SetFont(F.mono, 9, "")
    forge.sub:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -24)
    forge.sub:SetPoint("RIGHT",   header, "RIGHT", -28, 0)
    forge.sub:SetJustifyH("LEFT")
    forge.sub:SetTextColor(unpack(C.textFaint))

    local close = CreateFrame("Button", nil, header)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -8, -7)
    local closeLbl = close:CreateFontString(nil, "OVERLAY")
    closeLbl:SetFont(F.mono, 11, "")
    closeLbl:SetAllPoints(close)
    closeLbl:SetJustifyH("CENTER")
    closeLbl:SetTextColor(unpack(C.textMuted))
    closeLbl:SetText("x")
    close:SetScript("OnClick", function() RF.HideForge() end)

    forge.list = CreateFrame("Frame", nil, forge)
    forge.list:SetPoint("TOPLEFT",  forge, "TOPLEFT",  10, -(FORGE_HDR + 6))
    forge.list:SetPoint("TOPRIGHT", forge, "TOPRIGHT", -10, -(FORGE_HDR + 6))
    forge.list:SetHeight(10)

    forge.action = WeintCodex.CreateButton(forge, {
        text = "Alles umschmieden", kind = "primary", height = 34,
        width = FORGE_W - 20, backdrop = "bgDark",
        tooltip = "Schmiedet alle Teile der Liste nacheinander um."
            .. " Ein Klick genügt — jeder Gegenstand wird einzeln beim"
            .. " Umschmieder abgegeben, sobald er den vorigen bestätigt hat.",
        onClick = function() RF.StartRun() end,
    })

    forge.hint = forge:CreateFontString(nil, "OVERLAY")
    forge.hint:SetFont(F.sans, 9, "")
    forge.hint:SetJustifyH("LEFT")
    forge.hint:SetTextColor(unpack(C.textFaint))

    local store = WeintCodex.SavedData and WeintCodex.SavedData.reforge
    if store and store.pos and store.pos.point then
        forge:ClearAllPoints()
        forge:SetPoint(store.pos.point, UIParent, store.pos.point, store.pos.x, store.pos.y)
    end

    forge:Hide()
end

local function ForgeRow(index)
    local row = forgeRows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, forge.list)
    row:SetHeight(FORGE_ROW)
    row:SetPoint("TOPLEFT",  forge.list, "TOPLEFT",  0, -((index - 1) * FORGE_ROW))
    row:SetPoint("TOPRIGHT", forge.list, "TOPRIGHT", 0, -((index - 1) * FORGE_ROW))

    row.mark = row:CreateFontString(nil, "OVERLAY")
    row.mark:SetFont(F.mono, 11, "")
    row.mark:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.mark:SetWidth(14)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", row, "LEFT", 18, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.name = row:CreateFontString(nil, "OVERLAY")
    row.name:SetFont(F.sans, 11, "")
    row.name:SetPoint("LEFT", row, "LEFT", 44, 6)
    row.name:SetPoint("RIGHT", row, "RIGHT", -4, 6)
    row.name:SetJustifyH("LEFT")

    row.move = row:CreateFontString(nil, "OVERLAY")
    row.move:SetFont(F.mono, 9, "")
    row.move:SetPoint("LEFT", row, "LEFT", 44, -7)
    row.move:SetPoint("RIGHT", row, "RIGHT", -4, -7)
    row.move:SetJustifyH("LEFT")

    forgeRows[index] = row
    return row
end

function RF.RefreshForge()
    if not forge then return end

    -- WAEHREND EINES LAUFS WIRD NICHT NEU GEPLANT.
    -- Nach jedem umgeschmiedeten Teil aendert sich der Item-Link, also
    -- auch die Ausgangslage — und ein Planer, der mitten im Lauf seine
    -- Meinung aendert, schmiedet das naechste Teil anders, als in der
    -- Liste steht, auf die geklickt wurde. Der Lauf arbeitet deshalb den
    -- Plan ab, mit dem er begonnen hat; die Haken daran kommen aus dem
    -- Item-Link und sind damit trotzdem der echte Stand.
    local plan
    if forgeCo and RF.currentPlanRows then
        plan = { ok = true, rows = RF.currentPlanRows }
    else
        plan = RE.GetPlan()
    end

    -- DIE ZAHLEN KOMMEN AUS DEM ISTSTAND, NICHT AUS DEM PLAN.
    --
    -- Bis 2.7.0.1 stand hier die Summe, mit der der Lauf begonnen hat — sie
    -- blieb waehrend des ganzen Laufs stehen, auch wenn schon die Haelfte
    -- erledigt war. Was hier interessiert, ist aber, was noch aussteht und
    -- was das noch kostet. Gefragt wird das je Zeile am Item-Link, so wie
    -- auch der Haken davor.
    local shown, offen, kosten = 0, 0, 0

    if plan.ok then
        for _, planRow in ipairs(plan.rows) do
            if planRow.changed and not planRow.locked and not planRow.problem then
                shown = shown + 1
                local row = ForgeRow(shown)
                row.icon:SetTexture(planRow.icon)
                row.name:SetText(planRow.name)
                row.name:SetTextColor(unpack(C.textNormal))

                if planRow.target then
                    row.move:SetText(string.format("%s → %s  +%d",
                        R.SHORT[R.STATS[planRow.target.src]],
                        R.SHORT[R.STATS[planRow.target.dst]],
                        planRow.target.amount))
                else
                    row.move:SetText("Umschmiedung entfernen")
                end
                row.move:SetTextColor(unpack(C.textDim))

                local done = SlotMatches(planRow.slot, planRow.target)
                if done then
                    row.name:SetTextColor(unpack(C.textFaint))
                else
                    offen  = offen + 1
                    kosten = kosten + (planRow.cost or 0)
                end
                row.mark:SetText(done and "|cff7CC06E+|r" or "|cff4A4A52·|r")
                row:Show()
            end
        end
    end

    for index = shown + 1, #forgeRows do forgeRows[index]:Hide() end

    forge.list:SetHeight(math.max(1, shown * FORGE_ROW))

    if plan.ok and shown > 0 then
        if offen == 0 then
            forge.sub:SetText(WeintCodex.ColorText("green", "Alle " .. shown .. " Teile erledigt."))
        elseif offen < shown then
            forge.sub:SetText(string.format("%d von %d offen · %s",
                offen, shown, Coins(kosten)))
        else
            forge.sub:SetText(string.format("%d Teile · %s", shown, Coins(kosten)))
        end
    elseif plan.ok then
        forge.sub:SetText("Nichts zu tun — es sitzt alles richtig.")
    elseif plan.computing then
        forge.sub:SetText(forgeWish and "Wird gerechnet — der Lauf startet gleich von selbst …"
                                    or "Wird gerechnet …")
    else
        forge.sub:SetText(plan.problem or "Kein Plan.")
    end

    forge.action:ClearAllPoints()
    forge.action:SetPoint("TOPLEFT", forge, "TOPLEFT", 10,
        -(FORGE_HDR + 6 + shown * FORGE_ROW + 8))
    forge.action:SetShown(shown > 0 and (offen > 0 or forgeCo ~= nil))

    forge.hint:ClearAllPoints()
    forge.hint:SetPoint("TOPLEFT",  forge, "TOPLEFT", 12,
        -(FORGE_HDR + 6 + shown * FORGE_ROW + (shown > 0 and 48 or 8)))
    forge.hint:SetPoint("RIGHT", forge, "RIGHT", -12, 0)
    forge.hint:SetText(shown > 0
        and "Beta — die Vorschläge sind noch nicht verlässlich."
        or  "")

    forge:SetHeight(FORGE_HDR + 6 + shown * FORGE_ROW
        + (shown > 0 and 48 or 10) + (shown > 0 and 22 or 8))
end

function RF.ShowForge(manual)
    if not RE.Enabled() then
        if manual then Say("Der Umschmiede-Planer ist ausgeschaltet"
            .. " (Einstellungen → Umschmieden).") end
        return
    end
    BuildForge()
    RF.RefreshForge()

    -- Neben das Fenster des Umschmieders, solange es offen ist. Sonst
    -- bleibt die zuletzt gezogene Stelle.
    if ReforgingFrameIsVisible() then
        forge:ClearAllPoints()
        forge:SetPoint("TOPLEFT", _G.ReforgingFrame, "TOPRIGHT", 4, 0)
    end

    forge:Show()
end

-- Laeuft gerade ein Umschmiede-Lauf? Fuer die Seite und fuer die Frage,
-- ob ein Klick abbricht oder startet.
function RF.RunActive()
    return forgeCo ~= nil
end

function RF.HideForge()
    forgeWish = nil
    if forgeCo then StopRun("Abgebrochen.") end
    if forge then forge:Hide() end
end

function RF.ToggleForge()
    if forge and forge:IsShown() then RF.HideForge() else RF.ShowForge(true) end
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local redrawPending = false

local function Redraw()
    if redrawPending then return end
    if not (PageVisible() or (forge and forge:IsShown())) then return end
    if not (C_Timer and C_Timer.After) then
        if PageVisible() then RF.ShowPage() end
        if forge and forge:IsShown() and not forgeCo then RF.RefreshForge() end
        return
    end
    redrawPending = true
    C_Timer.After(1.5, function()
        redrawPending = false
        if PageVisible() then RF.ShowPage() end
        if forge and forge:IsShown() and not forgeCo then RF.RefreshForge() end
    end)
end

-- Der Suchlauf rechnet in Haeppchen ueber mehrere Bilder (siehe
-- modules/reforge_engine.lua). Wer ihn angestossen hat, bekommt danach
-- kein Ergebnis zurueck, sondern ein "wird gerechnet" — deshalb meldet
-- der Motor sich hier, wenn er fertig ist, und die offene Seite bzw. das
-- Fenster zeichnen sich dann neu.
RE.OnPlanReady(function()
    if PageVisible() then RF.ShowPage() end
    if forge and forge:IsShown() then RF.RefreshForge() end

    -- Ein Klick, der auf den Plan gewartet hat, wird jetzt eingeloest —
    -- aber nur, solange er frisch ist und der Umschmieder noch offen
    -- steht. Alles andere waere eine Goldausgabe, die aus einem Klick von
    -- vor fuenf Minuten folgt.
    if forgeWish then
        local wish = forgeWish
        forgeWish = nil
        if Now() <= wish and ReforgingFrameIsVisible()
           and forge and forge:IsShown() and not forgeCo then
            RF.StartRun()
        end
    end
end)

local watcher = CreateFrame("Frame")

-- Ueber pcall angemeldet: RegisterEvent mit einem Namen, den der Client
-- nicht kennt, wirft einen Fehler — und der beendet das Laden DIESER
-- Datei, nicht nur die Zeile. Der Umschmieder ist eine Einrichtung von
-- Cataclysm/MoP; sollte ein Clientstand eines dieser Ereignisse einmal
-- nicht fuehren, faellt genau die Funktion aus und nicht die Seite.
for _, event in ipairs({
    "FORGE_MASTER_OPENED", "FORGE_MASTER_CLOSED", "FORGE_MASTER_ITEM_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED", "PLAYER_SPECIALIZATION_CHANGED",
    "GET_ITEM_INFO_RECEIVED",
}) do
    pcall(watcher.RegisterEvent, watcher, event)
end

-- Nachlieferung der Gegenstandsdaten. Ohne sie bliebe eine Zeile, die beim
-- Aufbau noch keine Itemdaten hatte, dauerhaft auf "nicht planbar" stehen —
-- dieselbe Nachfassung wie bei Verzauberungen und Steinen. Entprellt, weil
-- GET_ITEM_INFO_RECEIVED in Schueben kommt, und nur, solange ueberhaupt
-- etwas aussteht.
local refillPending = false
local function NoteRefill()
    if refillPending then return end
    -- Nur, wenn ueberhaupt etwas zu zeichnen ist: GET_ITEM_INFO_RECEIVED
    -- kommt beim Betreten der Welt in Schueben, und ein Plan je Schub
    -- waere ein Ausruestungs-Scan je Schub.
    if not (PageVisible() or (forge and forge:IsShown())) then return end
    local plan = RE.GetPlan()
    if not plan.pending then return end
    refillPending = true
    if not (C_Timer and C_Timer.After) then refillPending = false return end
    C_Timer.After(1.0, function()
        refillPending = false
        RE.Invalidate()
        if PageVisible() then RF.ShowPage() end
        if forge and forge:IsShown() and not forgeCo then RF.RefreshForge() end
    end)
end

watcher:SetScript("OnEvent", function(_, event)
    if event == "GET_ITEM_INFO_RECEIVED" then
        NoteRefill()
    elseif event == "FORGE_MASTER_OPENED" then
        RE.Invalidate()
        if RE.Enabled() and RE.GetOption("autoOpen") then
            RF.ShowForge(false)
        end
    elseif event == "FORGE_MASTER_CLOSED" then
        forgeWish = nil
        if forgeCo then StopRun("Das Fenster des Umschmieders ist zu.") end
        if forge then forge:Hide() end
    elseif event == "FORGE_MASTER_ITEM_CHANGED" then
        -- WAEHREND EINES LAUFS BLEIBT DER PLAN STEHEN. Er wird gerade
        -- abgearbeitet, und ihn nach jedem Gegenstand zu verwerfen hiess:
        -- nach dem Lauf steht erst einmal keiner mehr da, und der naechste
        -- Klick tut sichtbar nichts, weil er auf die Neuberechnung wartet.
        if forgeCo then PokeRun() else RE.Invalidate() end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" and forgeCo then
        -- Der umgeschmiedete Gegenstand kommt als Ausruestungsaenderung
        -- zurueck — haeufig frueher als das Umschmieder-Ereignis. Der Lauf
        -- wartet auf den Item-Link, also ist das genau sein Anlass
        -- nachzusehen.
        PokeRun()
    else
        RE.Invalidate()
        -- Entprellt, aus zwei Gruenden: PLAYER_EQUIPMENT_CHANGED feuert
        -- beim Umsockeln mehrfach hintereinander (dieselbe Beobachtung wie
        -- in modules/gearalert.lua), und jeder Aufbau der Seite legt neue
        -- Frames an, die WoW nie wieder freigibt. Nachgezogen wird
        -- ausserdem nur, was auch offen steht.
        Redraw()
    end
end)

--------------------------------------------------
-- /wc umschmieden pruefen — DIAGNOSE
--------------------------------------------------
-- Aus demselben Grund wie /wc sockel und /wc tempo: eine Empfehlung, die
-- daneben liegt, sieht von aussen bei einer falsch gelesenen Sockelfolge,
-- einem falsch geratenen Link-Feld, einer verpassten Aufwertungsstufe und
-- einem falschen Gewicht voellig gleich aus. Gedruckt wird deshalb jede
-- Zwischenzahl: woher die Itemwerte kommen, mit welchem Faktor
-- hochgerechnet wurde, aus welchem Feld des Links die angelegte
-- Umschmiedung stammt, was der Client selbst dazu sagt, welches Ziel
-- gerechnet wurde und welche laufende Nummer der Umschmieder bekaeme.
--------------------------------------------------

function RF.Dump()
    Say("Umschmieden — Diagnose (Beta):")

    if not RE.Enabled() then
        print("  " .. WeintCodex.ColorText("warning",
            "Der Planer ist ausgeschaltet (Einstellungen → Umschmieden)."))
        return
    end

    local plan = RE.GetPlan(true)
    if not plan.ok then
        print("  " .. WeintCodex.ColorText("warning", plan.problem or "Kein Plan."))
        return
    end

    print("  Spec: " .. (plan.specDisplay or plan.profileKey or "?")
        .. WeintCodex.ColorText("textFaint", "  ·  Anteil 40 % je Gegenstand"))

    local gewichte = {}
    for _, key in ipairs(R.STATS) do
        local w = plan.ctx.weights[key]
        if w and w > 0 then gewichte[#gewichte + 1] = R.SHORT[key] .. " " .. w end
    end
    print("  Gewichte: " .. (#gewichte > 0 and table.concat(gewichte, ", ")
        or WeintCodex.ColorText("warning", "keine")))

    -- Umwandlungen: der haeufigste Grund fuer eine Empfehlung, die von
    -- aussen unsinnig aussieht ("wieso Waffenkunde auf einem Magier?").
    local conv = {}
    for from, map in pairs(plan.ctx.conv or {}) do
        for to, factor in pairs(map) do
            conv[#conv + 1] = string.format("%s → %s ×%.2f",
                R.SHORT[from] or from, R.SHORT[to] or to, factor)
        end
    end
    print("  Umwandlungen: " .. (#conv > 0 and table.concat(conv, ", ")
        or WeintCodex.ColorText("textFaint", "keine")))

    local mult = {}
    for key, factor in pairs(plan.ctx.mult or {}) do
        mult[#mult + 1] = string.format("%s ×%.3f", R.SHORT[key] or key, factor)
    end
    if #mult > 0 then print("  Verstärkung: " .. table.concat(mult, ", ")) end

    if plan.dims and #plan.dims > 0 then
        local names = {}
        for _, key in ipairs(plan.dims) do names[#names + 1] = R.SHORT[key] end
        print("  Suchachsen: " .. table.concat(names, ", ")
            .. WeintCodex.ColorText("textFaint",
               "  (darüber hinaus gehende Ziele zählen nur linear)"))
    end

    for _, key in ipairs(R.STATS) do
        local goal = plan.ctx.target[key]
        local live = plan.ctx.live[key] or 0
        local base = plan.ctx.baseline[key] or 0
        print(string.format("  %-14s ist %s  ohne Umschmiedungen %s  %s",
            R.SHORT[key], Rating(live), Rating(base),
            goal and WeintCodex.ColorText(goal.require and "gold" or "textMuted",
                string.format("Ziel %s (%s%s)", Rating(goal.rating), goal.kind,
                    goal.require and ", Pflicht" or ""))
            or WeintCodex.ColorText("textFaint", "kein Ziel")))
    end

    print("  " .. WeintCodex.ColorText("textFaint", "— Gegenstände —"))
    for _, row in ipairs(plan.rows) do
        local head = string.format("  %s %s", row.slotName, row.name)
        if row.locked then head = head .. WeintCodex.ColorText("gold", "  [gesperrt]") end
        print(head)

        if row.warning then
            print("    " .. WeintCodex.ColorText("warning", row.warning))
        end
        if row.statSetMismatch then
            print("    " .. WeintCodex.ColorText("warning",
                "Item-Link und Grundgegenstand melden verschiedene Werte —"
                .. " gerechnet wird mit dem Link"))
        end

        if row.problem then
            print("    " .. WeintCodex.ColorText("danger", row.problem))
        else
            local parts = {}
            for _, key in ipairs(R.STATS) do
                if row.stats[key] then
                    parts[#parts + 1] = R.SHORT[key] .. " " .. row.stats[key]
                end
            end
            print("    Werte: " .. (#parts > 0 and table.concat(parts, ", ")
                or WeintCodex.ColorText("textFaint", "keine umschmiedbaren")))

            if row.bare then
                local bare = {}
                for _, key in ipairs(R.STATS) do
                    if row.bare[key] then bare[#bare + 1] = R.SHORT[key] .. " " .. row.bare[key] end
                end
                print("    " .. WeintCodex.ColorText("textFaint",
                    "Grundgegenstand: " .. (#bare > 0 and table.concat(bare, ", ") or "—")))
            end

            print(string.format("    Stufe %s (Grund %s), Aufwertung %s, Quelle: %s",
                tostring(row.ilvl or "?"), tostring(row.baseIlvl or "?"),
                tostring(row.upgrade or 0),
                row.statSource == "tabelle" and "Skalierungstabelle (exakt)"
                or row.statSource == "kurve" and WeintCodex.ColorText("warning",
                       "Budgetkurve (Näherung — Vorlage nicht in der Tabelle)")
                or "Grundwerte"))

            if row.current then
                print(string.format("    angelegt: %s → %s (+%d), Umschmiedewert %d",
                    R.SHORT[R.STATS[row.current.src]], R.SHORT[R.STATS[row.current.dst]],
                    row.current.amount or row.current.raw,
                    R.PAIRS[R.PAIR_INDEX[row.current.src][row.current.dst]].id))
            else
                print("    angelegt: " .. WeintCodex.ColorText("textFaint", "nichts"))
            end

            if row.target then
                local index = RE.ForgeIndex(row, row.target.src, row.target.dst)
                print(string.format("    geplant:  %s → %s (+%d)  ·  %s  ·  laufende Nummer %s",
                    R.SHORT[R.STATS[row.target.src]], R.SHORT[R.STATS[row.target.dst]],
                    row.target.amount, row.reason or "",
                    index and tostring(index) or WeintCodex.ColorText("danger", "keine!")))
            else
                print("    geplant:  " .. WeintCodex.ColorText("textFaint", "nichts")
                    .. "  ·  " .. (row.reason or ""))
            end
        end
    end

    print(string.format("  Ergebnis: %d Änderungen, %s, Bewertung %.0f → %.0f%s",
        plan.changes, Coins(plan.cost), plan.scoreBefore or 0, plan.scoreAfter or 0,
        (plan.capMisses or 0) > 0
            and WeintCodex.ColorText("warning",
                string.format("  ·  %d Pflicht-Kap nicht erreichbar", plan.capMisses))
            or ""))
    print("  " .. WeintCodex.ColorText("textFaint",
        "Suchlauf: vollständige Programmierung über die Suchachsen, danach"
        .. " nachpoliert mit den exakten Summen."))
end

--------------------------------------------------
-- Slash-Befehl
--------------------------------------------------

function RF.Command(rest)
    rest = rest or ""

    -- Die offene Einstellungsseite zieht nur der BEFEHL nach; ein Schalter
    -- dort setzt seinen Zustand selbst (siehe RE.SetOption).
    local function Sync()
        if WeintCodex.Settings and WeintCodex.Settings.Refresh then
            WeintCodex.Settings.Refresh()
        end
    end

    if rest == "an" or rest == "ein" then
        RE.SetOption("enabled", true)
        Sync()
        Say("Umschmiede-Planer " .. WeintCodex.ColorText("green", "an")
            .. " — " .. BETA_TEXT)
        return
    end
    if rest == "aus" then
        RE.SetOption("enabled", false)
        RF.HideForge()
        Sync()
        Say("Umschmiede-Planer " .. WeintCodex.ColorText("textDim", "aus") .. ".")
        return
    end
    if rest == "pruefen" or rest == "prüfen" or rest == "diagnose" then
        RF.Dump()
        return
    end
    if rest == "fenster" then
        RF.ToggleForge()
        return
    end

    if not RE.Enabled() then
        Say("Der Umschmiede-Planer ist ausgeschaltet. Einschalten mit"
            .. " |cffD4A24A/wc umschmieden an|r oder unter Einstellungen → Umschmieden.")
        return
    end

    if not (WeintCodex.MainFrame and WeintCodex.Navigation) then return end
    WeintCodex.MainFrame:Show()
    WeintCodex.Navigation.GoToTab("charakter")
    RF.ShowPage()
end
