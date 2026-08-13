--------------------------------------------------
-- WeintCodex :: Kalender Module
--
-- Zeigt importierte Raidanmeldungen und erstellt
-- mit einem Klick einen In-Game Kalender-Eintrag
-- inkl. automatischer Einladung aller Angemeldeten.
--
-- WoW API:
--   Retail (C_Calendar):   C_Calendar.CreateEvent() etc.
--   MoP Classic (5.x):     Ältere globale Funktionen
--   Addon prüft automatisch welche API verfügbar ist.
--------------------------------------------------

WeintCodex.Calendar = {}

local C         = WeintCodex.Colors
local calFrame  = nil
local activeDay = "wednesday"
local RefreshPlayerPreview, AutoFillFromData

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function SetSolidBg(f, r, g, b, a)
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(f)
    t:SetColorTexture(r, g, b, a or 1)
    return t
end

local function DrawBorder(f, r, g, b, a, thick)
    thick = thick or 1
    local W, H = f:GetWidth(), f:GetHeight()
    local function T(pt, rpt, w, h)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(pt, f, rpt, 0, 0)
        t:SetSize(w, h)
    end
    T("TOPLEFT",    "TOPLEFT",    W,     thick)
    T("BOTTOMLEFT", "BOTTOMLEFT", W,     thick)
    T("TOPLEFT",    "TOPLEFT",    thick, H)
    T("TOPRIGHT",   "TOPRIGHT",   thick, H)
end

--------------------------------------------------
-- In-Game Kalender API Wrapper (C_Calendar)
-- Gilt fuer Retail und MoP Classic gleichermassen - die alten
-- Legacy-Globals (CalendarEventCreate, CalendarEventInvite, ...) aus
-- Vanilla/BC/WotLK existieren in diesem Client nicht mehr und wurden
-- hier bewusst entfernt (sie liefen zuvor als stille No-Ops, ohne
-- jemals tatsaechlich einen Eintrag zu erzeugen).
--------------------------------------------------

local function HasCalendarAPI()
    return C_Calendar ~= nil and C_Calendar.CreatePlayerEvent ~= nil
end

-- Datum-String "YYYY-MM-DD" in Teile zerlegen
local function ParseDate(dateStr)
    if not dateStr or dateStr == "" then
        return nil
    end
    local y, m, d = dateStr:match("(%d%d%d%d)-(%d%d)-(%d%d)")
    if y then
        return tonumber(m), tonumber(d), tonumber(y)
    end
    -- Fallback: Versuche deutsches Format "DD.MM.YYYY"
    d, m, y = dateStr:match("(%d%d?)%.(%d%d?)%.(%d%d%d%d)")
    if d then
        return tonumber(m), tonumber(d), tonumber(y)
    end
    return nil
end

-- Einladungsname fuer einen Spieler bestimmen. Crossrealm (z. B.
-- Everlook/Ook Ook): braucht "Name-Realm", sonst reicht der reine
-- Charaktername (Realm des einladenden Spielers wird angenommen).
local function InviteNameFor(p, myRealm)
    if p.name:find("%-") then
        -- Manuelle Korrektur wurde bereits als "Name-Realm" eingegeben
        return p.name
    end
    if p.realm and p.realm ~= "" and p.realm:lower() ~= (myRealm or ""):lower() then
        return p.name .. "-" .. p.realm
    end
    return p.name
end

-- Kalender-Eintrag erstellen
--
-- WICHTIG: CreatePlayerEvent/EventInvite/AddEvent sind vom Client
-- geschuetzte Funktionen ("protected"). Sie duerfen NUR synchron
-- innerhalb desselben Aufruf-Stapels laufen, der durch den Klick des
-- Spielers ausgeloest wurde - jeder Umweg ueber C_Timer.After (auch
-- nur fuer eine der Aktionen) reisst diese Kette ab und der Client
-- blockt den Aufruf mit ADDON_ACTION_BLOCKED. Deshalb laeuft hier
-- alles - Event anlegen, Felder setzen, ALLE Einladungen, Speichern -
-- in einem einzigen, ungestoerten Durchlauf.
local function CreateIngameCalendarEvent(title, desc, dateStr, hour, minute, players, statusCallback)
    if not HasCalendarAPI() then
        statusCallback(false,
            "Kalender-API nicht verfügbar.\n" ..
            "Öffne den Ingame-Kalender manuell (Minimap-Uhr) " ..
            "und erstelle den Eintrag dort.")
        return
    end

    local month, day, year = ParseDate(dateStr)

    if not month then
        -- Aktuelles Datum als Fallback
        local lt = date("*t")
        month, day, year = lt.month, lt.day, lt.year
    end

    title = (title and title ~= "") and title or "Raid"

    players = players or {}
    local total    = #players
    local invited  = 0
    local failed   = {}
    local myRealm  = GetRealmName() or ""

    local ok, err = pcall(function()
        C_Calendar.CreatePlayerEvent()
        C_Calendar.EventSetTitle(title)
        if C_Calendar.EventSetDescription then
            C_Calendar.EventSetDescription(desc or "")
        end
        C_Calendar.EventSetDate(month, day, year)
        C_Calendar.EventSetTime(hour or 20, minute or 0)
        if C_Calendar.EventSetType then
            C_Calendar.EventSetType(CALENDAR_EVENTTYPE_RAID or 1)
        end

        for _, p in ipairs(players) do
            local inviteName = InviteNameFor(p, myRealm)
            local invOk = pcall(C_Calendar.EventInvite, inviteName)
            if invOk then
                invited = invited + 1
            else
                table.insert(failed, inviteName)
            end
        end

        C_Calendar.AddEvent()
    end)

    if not ok then
        statusCallback(false,
            "Fehler beim Erstellen des Kalender-Eintrags:\n" .. tostring(err))
        return
    end

    local msg = WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-Ready", 14) .. " Kalender-Eintrag erstellt.\n" ..
        "Titel: " .. title .. "\n" ..
        "Datum: " .. (dateStr or "heute") ..
        "   Uhrzeit: " .. string.format("%02d:%02d", hour or 20, minute or 0) .. "\n" ..
        "Eingeladen: " .. invited .. "/" .. total

    if #failed > 0 then
        msg = msg .. "\n|cffE56B6BFehlgeschlagen:|r " .. table.concat(failed, ", ")
    end

    statusCallback(true, msg)
end

--------------------------------------------------
-- Kleines Input-Feld Helper
--------------------------------------------------

local function MakeInputField(parent, label, x, y, w, defaultText)
    local labelStr = parent:CreateFontString(nil, "OVERLAY")
    labelStr:SetFont(WeintCodex.Fonts.sans, 10, "")
    labelStr:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    labelStr:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    labelStr:SetText(label)

    local bg = CreateFrame("Frame", nil, parent)
    bg:SetSize(w, 26)
    bg:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 16)
    SetSolidBg(bg, C.headerBg[1], C.headerBg[2], C.headerBg[3], 0.90)
    DrawBorder(bg, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)

    local eb = CreateFrame("EditBox", nil, bg)
    eb:SetSize(w - 8, 20)
    eb:SetPoint("LEFT", bg, "LEFT", 4, 0)
    eb:SetAutoFocus(false)
    eb:SetFont(WeintCodex.Fonts.sans, 11, "")
    eb:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    eb:SetTextInsets(2, 2, 2, 2)
    eb:SetText(defaultText or "")
    eb:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    eb:SetScript("OnTabPressed",    function(s) s:ClearFocus() end)

    return eb
end

--------------------------------------------------
-- Kalender Frame erstellen
--------------------------------------------------

local function CreateCalendarFrame()
    if calFrame then return calFrame end

    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)

    -- Header
    -- Kopf ohne gefuelltes Band: die neue Sprache trennt mit Weissraum und
    -- einer Haarlinie, nicht mit einer abgesetzten Flaeche.
    --
    -- Der Entwurf zeigt an dieser Stelle ein Monatsraster. Diese Seite ist
    -- aber keine Monatsansicht, sondern das Formular, mit dem aus einer
    -- Raidanmeldung ein Ingame-Kalendereintrag wird - ein Raster zu bauen
    -- waere neue Funktion, nicht neue Gestalt. Es bleibt beim Formular.
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(72)
    header:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

    WeintCodex.PageHead(header, {
        eyebrow = "Gildentermine",
        title = "Kalender",
        sub = "Kalender-Eintrag aus Raidanmeldungen erstellen",
        subSize = 13, subInline = true,
        x = 20, y = 16, height = 56,
    })

    local headerDiv = header:CreateTexture(nil, "OVERLAY")
    headerDiv:SetHeight(1)
    headerDiv:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  0, 0)
    headerDiv:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerDiv:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

    -- Body: links Event-Einstellungen, rechts Spielervorschau
    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT",     header, "BOTTOMLEFT",  0,   0)
    body:SetPoint("BOTTOMRIGHT", f,      "BOTTOMRIGHT", 0,   0)

    -- ============================
    -- LINKE SEITE: Event-Setup
    -- ============================
    local LEFT_W = 430

    local leftPanel = CreateFrame("Frame", nil, body)
    leftPanel:SetWidth(LEFT_W)
    leftPanel:SetPoint("TOPLEFT",    body, "TOPLEFT",    0,   0)
    leftPanel:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 0,   0)

    -- Section: Event-Details
    local detailsSect = WeintCodex.Eyebrow(leftPanel, "Event-Details", { color = "textFaint" })
    detailsSect:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -16)

    local detailsLine = leftPanel:CreateTexture(nil, "OVERLAY")
    detailsLine:SetHeight(1)
    detailsLine:SetPoint("TOPLEFT",  leftPanel, "TOPLEFT",  16, -30)
    detailsLine:SetSize(LEFT_W - 32, 1)
    detailsLine:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

    -- Titel
    local titleInput = MakeInputField(leftPanel, "Titel", 16, -38, LEFT_W - 32, "Raid – WeintCodex")
    f.TitleInput = titleInput

    -- Datum
    local dateInput  = MakeInputField(leftPanel, "Datum (YYYY-MM-DD)", 16, -84, 180, "")
    f.DateInput = dateInput

    -- Uhrzeit
    local hourInput   = MakeInputField(leftPanel, "Stunde", 210, -84, 60,  "20")
    local minuteInput = MakeInputField(leftPanel, "Minute", 284, -84, 60,  "00")
    f.HourInput   = hourInput
    f.MinuteInput = minuteInput

    local timeSep = leftPanel:CreateFontString(nil, "OVERLAY")
    timeSep:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    timeSep:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 276, -100)
    timeSep:SetText("|cff4A4A52:|r")

    -- Beschreibung
    local descLabel = leftPanel:CreateFontString(nil, "OVERLAY")
    descLabel:SetFont(WeintCodex.Fonts.sans, 10, "")
    descLabel:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -130)
    descLabel:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    descLabel:SetText("Beschreibung")

    local descBg = CreateFrame("Frame", nil, leftPanel)
    descBg:SetSize(LEFT_W - 32, 60)
    descBg:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -144)
    SetSolidBg(descBg, C.headerBg[1], C.headerBg[2], C.headerBg[3], 0.90)
    DrawBorder(descBg, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)

    local descBox = CreateFrame("EditBox", nil, descBg)
    descBox:SetSize(LEFT_W - 44, 54)
    descBox:SetPoint("TOPLEFT", descBg, "TOPLEFT", 4, -4)
    descBox:SetMultiLine(true)
    descBox:SetMaxLetters(0)
    descBox:SetAutoFocus(false)
    descBox:SetFont(WeintCodex.Fonts.sans, 11, "")
    descBox:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    descBox:SetTextInsets(4, 4, 4, 4)
    descBox:SetText("Raidabend mit WeintCodex.\nAnmeldung via Discord-Bot.")
    descBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)

    local descScroll = CreateFrame("ScrollFrame", nil, descBg, "UIPanelScrollFrameTemplate")
    descScroll:SetSize(LEFT_W - 44, 54)
    descScroll:SetPoint("TOPLEFT", descBg, "TOPLEFT", 0, 0)
    descScroll:SetScrollChild(descBox)
    f.DescBox = descBox

    -- Auto-Fill Button (füllt Felder aus Raiddata)
    local autoFillBtn = CreateFrame("Button", nil, leftPanel)
    autoFillBtn:SetSize(LEFT_W - 32, 30)
    autoFillBtn:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -216)
    SetSolidBg(autoFillBtn, C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.80)
    DrawBorder(autoFillBtn, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)

    local autoFillLbl = autoFillBtn:CreateFontString(nil, "OVERLAY")
    autoFillLbl:SetAllPoints(autoFillBtn)
    autoFillLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
    autoFillLbl:SetText("|cff6B6B74" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 14) .. "  Felder aus Raidanmeldung befüllen|r")

    autoFillBtn:SetScript("OnEnter", function(self)
        SetSolidBg(self, C.purple[1] * 0.15, C.purple[2] * 0.15, C.purple[3] * 0.15, 0.90)
    end)
    autoFillBtn:SetScript("OnLeave", function(self)
        SetSolidBg(self, C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.80)
    end)
    autoFillBtn:SetScript("OnClick", function()
        local sd  = WeintCodex.SavedData
        local key = (activeDay == "thursday") and "raidThursday" or "raidWednesday"
        local data = sd and sd[key]
        if data and data.date and data.date ~= "" then
            AutoFillFromData(f, data)
        else
            f.StatusText:SetText("|cffE56B6B" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_QuestionMark", 14) .. " Keine Raidanmeldung für " ..
                ((activeDay == "thursday") and "Donnerstag" or "Mittwoch") ..
                " vorhanden. Bitte zuerst importieren.|r")
        end
    end)
    f.AutoFillBtn = autoFillBtn

    -- Section: Einladungsoptionen
    local invSect = WeintCodex.Eyebrow(leftPanel, "Einladungen", { color = "textFaint" })
    invSect:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -262)

    local invLine = leftPanel:CreateTexture(nil, "OVERLAY")
    invLine:SetHeight(1)
    invLine:SetSize(LEFT_W - 32, 1)
    invLine:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -276)
    invLine:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

    -- Checkboxes für Rollen-Filter
    local function MakeCheckbox(parent, label, x, y, default)
        local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        cb:SetChecked(default ~= false)

        local lbl = parent:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(WeintCodex.Fonts.sans, 11, "")
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetText(label)
        lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        return cb
    end

    local cbTank   = MakeCheckbox(leftPanel, "|cff8B95F5" .. WeintCodex.Icon("Interface\\Icons\\Ability_Warrior_DefensiveStance", 14) .. "  Tanks einladen|r",   16, -284, true)
    local cbHealer = MakeCheckbox(leftPanel, "|cff7CC06E" .. WeintCodex.Icon("Interface\\Icons\\Spell_Holy_Renew", 14) .. "  Heiler einladen|r",  16, -308, true)
    local cbDps    = MakeCheckbox(leftPanel, "|cffE56B6B" .. WeintCodex.Icon("Interface\\Icons\\Ability_DualWield", 14) .. "  DPS einladen|r",     16, -332, true)
    local cbMerge  = MakeCheckbox(leftPanel, WeintCodex.ColorText("textNormal", WeintCodex.Icon("Interface\\Icons\\Achievement_Character_Human_Male", 14) .. "  Raidtage zusammenführen"), 16, -356, false)
    f.CbMerge  = cbMerge
    f.CbTank   = cbTank
    f.CbHealer = cbHealer
    f.CbDps    = cbDps

    -- Checkbox script wiring for interactive updates
    local function CheckboxOnClick()
        RefreshPlayerPreview(f)
        AutoFillFromData(f)
    end
    cbTank:SetScript("OnClick", CheckboxOnClick)
    cbHealer:SetScript("OnClick", CheckboxOnClick)
    cbDps:SetScript("OnClick", CheckboxOnClick)
    cbMerge:SetScript("OnClick", CheckboxOnClick)

    -- CREATE BUTTON (groß, prominent)
    local createBtn = CreateFrame("Button", nil, leftPanel)
    createBtn:SetSize(LEFT_W - 32, 44)
    createBtn:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -392)
    SetSolidBg(createBtn, C.purple[1], C.purple[2], C.purple[3], 0.85)
    DrawBorder(createBtn, C.purple[1], C.purple[2], C.purple[3], 1.0, 1)

    -- Glow line on top
    local btnGlow = createBtn:CreateTexture(nil, "OVERLAY")
    btnGlow:SetHeight(2)
    btnGlow:SetPoint("TOPLEFT",  createBtn, "TOPLEFT",  0, 0)
    btnGlow:SetPoint("TOPRIGHT", createBtn, "TOPRIGHT", 0, 0)
    btnGlow:SetColorTexture(1, 1, 1, 0.15)

    local createBtnLbl = createBtn:CreateFontString(nil, "OVERLAY")
    createBtnLbl:SetAllPoints(createBtn)
    createBtnLbl:SetFont(WeintCodex.Fonts.sansSemi, 14, "")
    createBtnLbl:SetText("|cffffffff" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 16) .. "  Kalender-Eintrag erstellen|r")

    createBtn:SetScript("OnEnter", function(self)
        SetSolidBg(self, math.min(1, C.purple[1] * 1.25), math.min(1, C.purple[2] * 1.25), math.min(1, C.purple[3] * 1.15), 0.95)
    end)
    createBtn:SetScript("OnLeave", function(self)
        SetSolidBg(self, C.purple[1], C.purple[2], C.purple[3], 0.85)
    end)

    f.CreateBtnLbl = createBtnLbl

    -- Status text
    local statusText = leftPanel:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(WeintCodex.Fonts.sans, 11, "")
    statusText:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -448)
    statusText:SetWidth(LEFT_W - 32)
    statusText:SetJustifyH("LEFT")
    statusText:SetSpacing(3)
    statusText:SetText("")
    f.StatusText = statusText

    -- API info text
    local apiInfo = leftPanel:CreateFontString(nil, "OVERLAY")
    apiInfo:SetFont(WeintCodex.Fonts.sans, 10, "")
    apiInfo:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMLEFT", 16, 10)
    apiInfo:SetWidth(LEFT_W - 32)
    apiInfo:SetJustifyH("LEFT")
    apiInfo:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

    -- API-Verfügbarkeit prüfen
    C_Timer.After(0.2, function()
        local ok = HasCalendarAPI()
        if ok then
            apiInfo:SetText("|cff33D65E" .. WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-Ready", 14) .. " Kalender-API (C_Calendar) verfügbar|r")
        else
            apiInfo:SetText("|cffE56B6B" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_QuestionMark", 14) .. " Kalender-API nicht erkannt – manuelles Erstellen nötig|r")
        end
        f.ApiAvailable = ok
        WeintCodex.Navigation.SetInspector({
            { type = "header", text = "Kalender-Status" },
            { type = "rows", rows = {
                { label = "C_Calendar API", value = ok and "verfügbar" or "nicht erkannt",
                  valueColor = ok and "success" or "danger" },
            }},
            { type = "divider" },
            { type = "card", lines = {
                "Der Eintrag wird beim Klick auf 'Kalender-Eintrag erstellen'",
                "sofort angelegt und alle gefilterten Spieler eingeladen.",
            }},
        })
    end)

    -- Divider zwischen links und rechts
    local bodyDiv = body:CreateTexture(nil, "OVERLAY")
    bodyDiv:SetWidth(1)
    bodyDiv:SetPoint("TOPLEFT",    body, "TOPLEFT",    LEFT_W + 1, -6)
    bodyDiv:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", LEFT_W + 1,  6)
    bodyDiv:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

    -- ============================
    -- RECHTE SEITE: Spielervorschau
    -- ============================

    local rightPanel = CreateFrame("Frame", nil, body)
    rightPanel:SetPoint("TOPLEFT",     body, "TOPLEFT",     LEFT_W + 6,  0)
    rightPanel:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0,           0)

    local previewSect = WeintCodex.Eyebrow(rightPanel, "Einzuladende Spieler", { color = "textFaint" })
    previewSect:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -16)
    f.PreviewSect = previewSect

    local previewLine = rightPanel:CreateTexture(nil, "OVERLAY")
    previewLine:SetHeight(1)
    previewLine:SetPoint("TOPLEFT",  rightPanel, "TOPLEFT",  10, -30)
    previewLine:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -10, -30)
    previewLine:SetColorTexture(C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0)

    -- Spieler-Zähler
    local previewCount = rightPanel:CreateFontString(nil, "OVERLAY")
    previewCount:SetFont(WeintCodex.Fonts.sans, 11, "")
    previewCount:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -10, -16)
    previewCount:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    previewCount:SetText("")
    f.PreviewCount = previewCount

    -- Scroll: Spielerliste
    local previewScroll = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate")
    previewScroll:SetPoint("TOPLEFT",     rightPanel, "TOPLEFT",     10,  -36)
    previewScroll:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -4,   4)

    local previewChild = CreateFrame("Frame", nil, previewScroll)
    previewChild:SetWidth(400)
    previewChild:SetHeight(1)
    previewScroll:SetScrollChild(previewChild)
    f.PreviewChild = previewChild

    -- Create button logic (needs access to rightPanel data)
    createBtn:SetScript("OnClick", function()
        -- Einladungen an den ganzen Raid verschickt die Raidleitung (siehe
        -- core/access.lua). Die Pruefung steht bewusst hier, im selben
        -- synchronen Durchlauf wie CreatePlayerEvent - siehe die Warnung
        -- zu ADDON_ACTION_BLOCKED weiter oben in dieser Datei.
        if WeintCodex.Access and not WeintCodex.Access.Can("calendar.invite") then
            f.StatusText:SetText("|cffff6666"
                .. WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-NotReady", 14) .. " "
                .. WeintCodex.Access.Reason("calendar.invite") .. "|r")
            return
        end

        local sd  = WeintCodex.SavedData
        local key = (activeDay == "thursday") and "raidThursday" or "raidWednesday"
        local data = sd and sd[key]

        local title    = f.TitleInput:GetText()
        local dateStr  = f.DateInput:GetText()
        local hour     = tonumber(f.HourInput:GetText())   or 20
        local minute   = tonumber(f.MinuteInput:GetText()) or 0
        local descText = f.DescBox:GetText()

        if title == "" then
            f.StatusText:SetText("|cffff6666" .. WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-NotReady", 14) .. " Bitte einen Titel eingeben.|r")
            return
        end

        -- Spielerliste filtern (mit Merge-Option)
        local invitePlayers = {}
        local seen = {}

        local function AddInvitees(dayData)
            if dayData and dayData.players then
                for _, p in ipairs(dayData.players) do
                    local nameKey = p.name:lower()
                    if not seen[nameKey] then
                        local include = false
                        if p.role == "TANK" and f.CbTank:GetChecked() then include = true
                        elseif p.role == "HEALER" and f.CbHealer:GetChecked() then include = true
                        elseif (p.role ~= "TANK" and p.role ~= "HEALER") and f.CbDps:GetChecked() then include = true
                        end
                        if include then
                            table.insert(invitePlayers, p)
                            seen[nameKey] = true
                        end
                    end
                end
            end
        end

        if f.CbMerge:GetChecked() then
            AddInvitees(sd and sd.raidWednesday)
            AddInvitees(sd and sd.raidThursday)
        else
            AddInvitees(data)
        end

        f.StatusText:SetText("|cffD4A24A" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 14) .. " Kalender wird vorbereitet...|r")

        CreateIngameCalendarEvent(
            title, descText, dateStr, hour, minute, invitePlayers,
            function(success, msg)
                if success then
                    f.StatusText:SetText("|cff33D65E" .. msg .. "|r")
                    print("|cffD4A24A[WeintCodex Kalender]|r |cff33D65E" ..
                        "Eintrag '" .. title .. "' vorbereitet (" ..
                        #invitePlayers .. " Spieler).|r")
                else
                    f.StatusText:SetText("|cffE56B6B" .. msg .. "|r")
                end
            end
        )
    end)

    --------------------------------------------------
    -- Monatsansicht (Entwurf 2d)
    --------------------------------------------------
    -- Zweite Ansicht derselben Seite, NEBEN dem Einladungsformular - nicht
    -- an dessen Stelle. Die Reiterleiste schaltet um; "Mittwoch"/"Donnerstag"
    -- zeigen unveraendert das Formular.
    --
    -- Woher die Termine kommen:
    --   1. Die beiden Raidtermine aus den SavedData (raidWednesday/-Thursday).
    --      Die kennt das Addon immer, ohne jede Spiel-API.
    --   2. Zusaetzlich, wenn der Client sie hergibt, die echten
    --      Kalendereintraege ueber C_Calendar. Das ist bewusst nur eine
    --      Anreicherung: das Lesen der Blizzard-Kalenderdaten ist an den
    --      Ladezustand des Kalenders gebunden und in MoP Classic nicht
    --      zugesichert. Alles laeuft in pcall - faellt es aus, steht das
    --      Raster trotzdem, nur eben mit den Raidterminen allein.
    --
    -- Kein SetAbsMonth: das wuerde den Monat der Blizzard-Kalenderoberflaeche
    -- global umstellen. Gelesen wird ueber den relativen Monatsversatz, den
    -- die Ansicht ohnehin fuehrt.
    --------------------------------------------------

    local monthView = CreateFrame("Frame", nil, f)
    monthView:SetPoint("TOPLEFT",     header, "BOTTOMLEFT",  0, 0)
    monthView:SetPoint("BOTTOMRIGHT", f,      "BOTTOMRIGHT", 0, 0)
    monthView:Hide()
    f.MonthView = monthView
    f.Body = body

    local MONTH_NAMES = { "Januar", "Februar", "März", "April", "Mai", "Juni",
        "Juli", "August", "September", "Oktober", "November", "Dezember" }
    local WEEKDAYS = { "Mo", "Di", "Mi", "Do", "Fr", "Sa", "So" }

    local monthOffset = 0   -- 0 = laufender Monat

    local function DaysInMonth(m, y)
        local d = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
        if m == 2 and ((y % 4 == 0 and y % 100 ~= 0) or y % 400 == 0) then
            return 29
        end
        return d[m]
    end

    -- Verschobener Monat als (Monat, Jahr)
    local function ShiftedMonth(offset)
        local now = date("*t")
        local m = now.month + offset
        local y = now.year
        while m > 12 do m = m - 12; y = y + 1 end
        while m < 1  do m = m + 12; y = y - 1 end
        return m, y
    end

    -- Termine des angezeigten Monats einsammeln -> { [tag] = { {text=, tone=}, ... } }
    local function CollectEvents(m, y)
        local byDay = {}
        local function Add(day, text, tone)
            byDay[day] = byDay[day] or {}
            table.insert(byDay[day], { text = text, tone = tone })
        end

        -- 1) Eigene Raidtermine
        local sd = WeintCodex.SavedData
        local function AddRaid(data, label)
            if not (data and data.date) then return end
            local dm, dd, dy = ParseDate(data.date)
            if dm == m and dy == y then
                local n = data.players and #data.players or 0
                Add(dd, label .. (n > 0 and (" · " .. n) or ""), "accent")
            end
        end
        AddRaid(sd and sd.raidWednesday, "Raid Mi")
        AddRaid(sd and sd.raidThursday,  "Raid Do")

        -- 2) Blizzard-Kalender, falls lesbar
        if C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent then
            pcall(function()
                if C_Calendar.OpenCalendar then C_Calendar.OpenCalendar() end
                local days = DaysInMonth(m, y)
                for day = 1, days do
                    local n = C_Calendar.GetNumDayEvents(monthOffset, day) or 0
                    for i = 1, n do
                        local ev = C_Calendar.GetDayEvent(monthOffset, day, i)
                        if ev and ev.title then
                            local t = ev.title
                            if ev.startTime and ev.startTime.hour then
                                t = string.format("%s %d:%02d", t,
                                    ev.startTime.hour, ev.startTime.minute or 0)
                            end
                            Add(day, t, "info")
                        end
                    end
                end
            end)
        end
        return byDay
    end

    --------------------------------------------------
    -- Kopfzeile der Monatsansicht
    --------------------------------------------------

    local mEyebrow = WeintCodex.Eyebrow(monthView, "Gildentermine", { size = 10 })
    mEyebrow:SetPoint("TOPLEFT", monthView, "TOPLEFT", 20, -16)

    local mTitle = WeintCodex.PageTitle(monthView, "", { size = 26 })
    mTitle:SetPoint("TOPLEFT", mEyebrow, "BOTTOMLEFT", 0, -6)

    local RenderMonth   -- vorwaerts, die Knoepfe rufen sie auf

    local nextBtn = WeintCodex.CreateButton(monthView, {
        text = "\226\128\186", width = 34, height = 34, kind = "secondary",
        backdrop = "bgDark", tooltip = "Nächster Monat",
        onClick = function() monthOffset = monthOffset + 1; RenderMonth() end,
    })
    nextBtn:SetPoint("TOPRIGHT", monthView, "TOPRIGHT", -20, -22)

    local todayBtn = WeintCodex.CreateButton(monthView, {
        text = "Heute", height = 34, kind = "secondary", backdrop = "bgDark",
        onClick = function() monthOffset = 0; RenderMonth() end,
    })
    todayBtn:SetPoint("RIGHT", nextBtn, "LEFT", -8, 0)

    local prevBtn = WeintCodex.CreateButton(monthView, {
        text = "\226\128\185", width = 34, height = 34, kind = "secondary",
        backdrop = "bgDark", tooltip = "Voriger Monat",
        onClick = function() monthOffset = monthOffset - 1; RenderMonth() end,
    })
    prevBtn:SetPoint("RIGHT", todayBtn, "LEFT", -8, 0)

    --------------------------------------------------
    -- Wochentagszeile und Raster
    --------------------------------------------------

    local GRID_TOP  = -92
    local HEAD_H    = 22

    local weekRow = CreateFrame("Frame", nil, monthView)
    weekRow:SetHeight(HEAD_H)
    weekRow:SetPoint("TOPLEFT",  monthView, "TOPLEFT",  20, GRID_TOP)
    weekRow:SetPoint("TOPRIGHT", monthView, "TOPRIGHT", -20, GRID_TOP)

    local weekLabels = {}
    for i = 1, 7 do
        weekLabels[i] = WeintCodex.Eyebrow(weekRow, WEEKDAYS[i], { size = 9 })
    end

    local gridHost = CreateFrame("Frame", nil, monthView)
    gridHost:SetPoint("TOPLEFT",     weekRow,   "BOTTOMLEFT",  0, -6)
    gridHost:SetPoint("BOTTOMRIGHT", monthView, "BOTTOMRIGHT", -20, 20)

    -- 7 x 6 Zellen einmal bauen und danach nur noch befuellen. Ein Neuaufbau
    -- bei jedem Monatswechsel wuerde bei jedem Klick Frames erzeugen, die WoW
    -- nie wieder freigibt.
    local cells = {}
    for i = 1, 42 do
        local cell = WeintCodex.CreateSurface(gridHost, {
            tone = "flat", surface = "surface1", radius = 10,
            backdrop = "bgDark", button = true,
        })

        local dayLbl = cell:CreateFontString(nil, "OVERLAY")
        dayLbl:SetFont(WeintCodex.Fonts.monoBold, 12, "")
        dayLbl:SetPoint("TOPLEFT", cell, "TOPLEFT", 8, -6)
        cell._day = dayLbl

        -- Zwei Terminzeilen je Zelle plus Ueberlaufmarke; mehr passt in eine
        -- Tageszelle nicht lesbar hinein. Der Rest steht im Detailbereich.
        cell._chips = {}
        for c = 1, 2 do
            local chip = cell:CreateFontString(nil, "OVERLAY")
            chip:SetFont(WeintCodex.Fonts.sans, 11, "")
            chip:SetPoint("TOPLEFT",  cell, "TOPLEFT",  8, -22 - (c - 1) * 15)
            chip:SetPoint("RIGHT",    cell, "RIGHT",   -6, 0)
            chip:SetJustifyH("LEFT")
            chip:SetWordWrap(false)
            chip:Hide()
            cell._chips[c] = chip
        end

        local more = cell:CreateFontString(nil, "OVERLAY")
        more:SetFont(WeintCodex.Fonts.mono, 9, "")
        more:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -6, 5)
        more:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
        more:Hide()
        cell._more = more

        -- Markierung fuer "heute": Bernsteinlinie an der Oberkante, dasselbe
        -- Mittel, mit dem jede Akzentkarte sich auszeichnet.
        local mark = cell:CreateTexture(nil, "OVERLAY")
        mark:SetHeight(1)
        mark:SetPoint("TOPLEFT",  cell, "TOPLEFT",   8, 0)
        mark:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -8, 0)
        mark:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1.0)
        mark:Hide()
        cell._mark = mark

        cells[i] = cell
    end

    -- Zellen relativ zur Rasterbreite platzieren; das Fenster ist in der
    -- Groesse veraenderbar, feste Breiten waeren nach dem ersten Ziehen falsch.
    local function LayoutGrid()
        local w = gridHost:GetWidth() or 0
        local h = gridHost:GetHeight() or 0
        if w <= 0 or h <= 0 then return end
        local gap  = 6
        local cw   = (w - gap * 6) / 7
        local ch   = (h - gap * 5) / 6
        for i = 1, 42 do
            local col = (i - 1) % 7
            local rowI = math.floor((i - 1) / 7)
            cells[i]:ClearAllPoints()
            cells[i]:SetPoint("TOPLEFT", gridHost, "TOPLEFT",
                col * (cw + gap), -rowI * (ch + gap))
            cells[i]:SetSize(cw, ch)
        end
        for i = 1, 7 do
            weekLabels[i]:ClearAllPoints()
            weekLabels[i]:SetPoint("LEFT", weekRow, "LEFT", (i - 1) * (cw + gap) + 8, 0)
        end
    end
    gridHost:HookScript("OnSizeChanged", LayoutGrid)
    -- Beim ersten Aufbau steht die Breite des Rasters noch nicht fest;
    -- LayoutGrid steigt dann aus. Der Anker beim Einblenden holt das nach,
    -- sonst blieben die Zellen ohne Groesse und damit unsichtbar.
    monthView:HookScript("OnShow", LayoutGrid)

    --------------------------------------------------
    -- Tagesdetails im Detailbereich
    --------------------------------------------------

    local function ShowDayDetail(day, m, y, events)
        local blocks = {
            { type = "header", text = string.format("%d. %s %d", day, MONTH_NAMES[m], y) },
        }
        if not events or #events == 0 then
            blocks[#blocks + 1] = { type = "rows",
                rows = { { label = "Termine", value = "keine" } } }
        else
            local rows = {}
            for _, ev in ipairs(events) do
                rows[#rows + 1] = { label = ev.text, value = "" }
            end
            blocks[#blocks + 1] = { type = "rows", rows = rows }
        end
        WeintCodex.Navigation.SetInspector(blocks)
    end

    --------------------------------------------------
    -- Zeichnen
    --------------------------------------------------

    RenderMonth = function()
        local m, y = ShiftedMonth(monthOffset)
        local events = CollectEvents(m, y)

        local total = 0
        for _, list in pairs(events) do total = total + #list end
        mEyebrow:SetText(WeintCodex.Spaced(string.upper(
            "Gildentermine · " .. total .. (total == 1 and " Termin" or " Termine"))))
        mTitle:SetText(MONTH_NAMES[m] .. " " .. y)

        -- Wochentag des Ersten, montagsbasiert (date() liefert 1 = Sonntag)
        local firstW = date("*t", time({ year = y, month = m, day = 1, hour = 12 })).wday
        local startCol = (firstW + 5) % 7          -- 0 = Montag
        local days = DaysInMonth(m, y)

        local today = date("*t")
        local isThisMonth = (today.month == m and today.year == y)

        LayoutGrid()

        for i = 1, 42 do
            local cell = cells[i]
            local dayNum = i - startCol
            local inMonth = (dayNum >= 1 and dayNum <= days)

            cell._mark:Hide()
            for _, chip in ipairs(cell._chips) do chip:Hide() end
            cell._more:Hide()

            if not inMonth then
                -- Tage der Nachbarmonate bleiben sichtbar, aber stumm: das
                -- Raster soll seine Form behalten, ohne etwas zu behaupten.
                cell._day:SetText("")
                cell:SetAlpha(0.35)
                cell:SetScript("OnClick", nil)
                cell:SetScript("OnEnter", nil)
                cell:SetScript("OnLeave", nil)
            else
                cell:SetAlpha(1)
                cell._day:SetText(tostring(dayNum))

                local dayEvents = events[dayNum]
                local isToday = isThisMonth and today.day == dayNum

                if isToday then
                    cell._mark:Show()
                    cell._day:SetTextColor(C.accentBright[1], C.accentBright[2], C.accentBright[3])
                elseif dayEvents then
                    cell._day:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
                else
                    cell._day:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
                end

                if dayEvents then
                    for c = 1, math.min(2, #dayEvents) do
                        local ev = dayEvents[c]
                        local col = C[(ev.tone == "accent") and "accentBright" or "infoBright"]
                        cell._chips[c]:SetTextColor(col[1], col[2], col[3])
                        cell._chips[c]:SetText(ev.text)
                        cell._chips[c]:Show()
                    end
                    if #dayEvents > 2 then
                        cell._more:SetText("+" .. (#dayEvents - 2))
                        cell._more:Show()
                    end
                end

                cell:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
                cell:SetScript("OnLeave", function(self)
                    self:SetSurface("surface1")
                end)
                cell:SetScript("OnClick", function()
                    ShowDayDetail(dayNum, m, y, dayEvents)
                end)
            end
        end
    end

    f.RenderMonth = RenderMonth

    calFrame = f
    return f
end

--------------------------------------------------
-- Spielervorschau aktualisieren
--------------------------------------------------

local activePreviewRows = {}

RefreshPlayerPreview = function(f, raidData)
    local pc = f.PreviewChild

    for _, row in ipairs(activePreviewRows) do row:Hide() end
    for _, child in pairs({pc:GetChildren()}) do child:Hide() end
    for _, child in pairs({pc:GetRegions()}) do child:Hide() end
    wipe(activePreviewRows)

    local sd = WeintCodex.SavedData
    local players = {}
    local seen = {}

    local function AddPlayers(dayData)
        if dayData and dayData.players then
            for _, p in ipairs(dayData.players) do
                local nameKey = p.name:lower()
                if not seen[nameKey] then
                    local include = false
                    if p.role == "TANK" and f.CbTank:GetChecked() then include = true
                    elseif p.role == "HEALER" and f.CbHealer:GetChecked() then include = true
                    elseif (p.role ~= "TANK" and p.role ~= "HEALER") and f.CbDps:GetChecked() then include = true
                    end
                    if include then
                        table.insert(players, p)
                        seen[nameKey] = true
                    end
                end
            end
        end
    end

    if f.CbMerge:GetChecked() then
        AddPlayers(sd and sd.raidWednesday)
        AddPlayers(sd and sd.raidThursday)
    else
        if raidData then
            AddPlayers(raidData)
        else
            local key = (activeDay == "thursday") and "raidThursday" or "raidWednesday"
            AddPlayers(sd and sd[key])
        end
    end

    if #players == 0 then
        local noData = pc:CreateFontString(nil, "OVERLAY")
        noData:SetFont(WeintCodex.Fonts.sans, 12, "")
        noData:SetPoint("TOPLEFT", pc, "TOPLEFT", 0, -10)
        noData:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        noData:SetText(
            "Keine Spieler zum Einladen.\n\n" ..
            "Überprüfe Filter-Häkchen oder importiere\nRaidanmeldungen im Import-Tab."
        )
        noData:SetSpacing(3)
        pc:SetHeight(80)
        table.insert(activePreviewRows, noData)
        f.PreviewCount:SetText("")
        return
    end

    local total    = #players
    local tanks    = 0
    local healers  = 0
    local dps      = 0

    local offsetY  = -4
    local altRow   = false

    local roleColors = {
        TANK   = C.blue,
        HEALER = C.green,
        DPS    = C.red,
    }
    local classColors = {
        WARRIOR="|cffc79c6e",PALADIN="|cfff58cba",HUNTER="|cffabd473",
        ROGUE="|cfffff569",PRIEST="|cffffffff",DEATHKNIGHT="|cffc41f3b",
        SHAMAN="|cff0070de",MAGE="|cff69ccf0",WARLOCK="|cff9482c9",
        MONK="|cff00ff96",DRUID="|cffff7d0a",
    }

    for _, p in ipairs(players) do
        if p.role == "TANK"   then tanks   = tanks   + 1 end
        if p.role == "HEALER" then healers = healers + 1 end
        if p.role ~= "TANK" and p.role ~= "HEALER" then dps = dps + 1 end

        local row = CreateFrame("Frame", nil, pc)
        row:SetHeight(24)
        row:SetPoint("TOPLEFT",  pc, "TOPLEFT",  0, offsetY)
        row:SetPoint("TOPRIGHT", pc, "TOPRIGHT", -6, offsetY)

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints(row)
        if altRow then
            rowBg:SetColorTexture(C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.45)
        else
            rowBg:SetColorTexture(0, 0, 0, 0)
        end
        altRow = not altRow

        -- Role dot
        local rc = roleColors[p.role] or roleColors.DPS
        local dot = row:CreateTexture(nil, "OVERLAY")
        dot:SetSize(8, 8)
        dot:SetPoint("LEFT", row, "LEFT", 4, 0)
        dot:SetColorTexture(rc[1], rc[2], rc[3], 0.90)

        -- Name
        local ccol = classColors[p.class] or "|cffdddddd"
        local nameLbl = row:CreateFontString(nil, "OVERLAY")
        nameLbl:SetFont(WeintCodex.Fonts.sans, 11, "")
        nameLbl:SetPoint("LEFT", row, "LEFT", 18, 0)
        nameLbl:SetText(ccol .. (p.name or "?") .. "|r")
        nameLbl:SetWidth(160)

        -- Class
        local classLbl = row:CreateFontString(nil, "OVERLAY")
        classLbl:SetFont(WeintCodex.Fonts.sans, 10, "")
        classLbl:SetPoint("LEFT", row, "LEFT", 190, 0)
        classLbl:SetText("|cff4A4A52" .. (p.class or "") .. "|r")
        classLbl:SetWidth(120)

        table.insert(activePreviewRows, row)
        offsetY = offsetY - 26
    end

    pc:SetHeight(math.abs(offsetY) + 10)

    f.PreviewCount:SetText(
        "|cff8B95F5" .. tanks .. "T|r  " ..
        "|cff7CC06E" .. healers .. "H|r  " ..
        "|cffE56B6B" .. dps .. "D|r  " ..
        "|cff888888" .. total .. " gesamt|r"
    )
end

--------------------------------------------------
-- Datum-Feld aus Raiddata befüllen
--------------------------------------------------

AutoFillFromData = function(f, raidData)
    local sd  = WeintCodex.SavedData
    local dayName = (activeDay == "thursday") and "Donnerstag" or "Mittwoch"

    if f.CbMerge:GetChecked() then
        local wData = sd and sd.raidWednesday
        local tData = sd and sd.raidThursday
        local wDate = wData and wData.date or ""
        local tDate = tData and tData.date or ""

        f.DateInput:SetText(wDate ~= "" and wDate or tDate)
        f.TitleInput:SetText(
            (wData and wData.title) or (tData and tData.title) or
            ("Raid Mi & Do – " .. (wDate ~= "" and wDate or tDate))
        )
        f.HourInput:SetText(string.format("%02d", (wData and wData.hour) or (tData and tData.hour) or 20))
        f.MinuteInput:SetText(string.format("%02d", (wData and wData.minute) or (tData and tData.minute) or 0))

        local cntW = wData and wData.players and #wData.players or 0
        local cntT = tData and tData.players and #tData.players or 0
        f.DescBox:SetText(
            "Raidabend – Mittwoch & Donnerstag\n" ..
            "Mittwoch: " .. cntW .. " Spieler, Donnerstag: " .. cntT .. " Spieler\n" ..
            "Zusammengeführt und erstellt von WeintCodex."
        )
    else
        raidData = raidData or (sd and ((activeDay == "thursday") and sd.raidThursday or sd.raidWednesday))
        if raidData and raidData.date and raidData.date ~= "" then
            f.DateInput:SetText(raidData.date)
            f.TitleInput:SetText(raidData.title or ("Raid " .. dayName .. " – " .. raidData.date))
            f.HourInput:SetText(string.format("%02d", raidData.hour or 20))
            f.MinuteInput:SetText(string.format("%02d", raidData.minute or 0))
            local cnt = raidData.players and #raidData.players or 0
            f.DescBox:SetText(
                "Raidabend – " .. dayName .. "\n" ..
                "Angemeldet: " .. cnt .. " Spieler\n" ..
                "Erstellt von WeintCodex."
            )
        end
    end
end

--------------------------------------------------
-- Modul anzeigen
--------------------------------------------------

function WeintCodex.Calendar.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    local f = CreateCalendarFrame()
    f:Show()
    f.StatusText:SetText("")

    -- Der Knopf bleibt sichtbar, aber sichtbar unzustaendig: so ist erkennbar,
    -- dass es die Funktion gibt, und der Klick nennt den Grund.
    local mayInvite = not WeintCodex.Access or WeintCodex.Access.Can("calendar.invite")
    f.CreateBtnLbl:SetText(
        (mayInvite and "|cffffffff" or "|cff8A8178")
        .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 16)
        .. "  Kalender-Eintrag erstellen|r"
    )

    -- Umschalten zwischen Monatsraster und Einladungsformular. Das Formular
    -- ist unveraendert - die Monatsansicht kommt daneben, nicht an seine Stelle.
    local function ShowForm()
        f.MonthView:Hide()
        f.Body:Show()
        WeintCodex.Navigation.ClearInspector()
    end

    local sidebarItems = {
        {
            label   = "Monat",
            onClick = function()
                f.Body:Hide()
                f.MonthView:Show()
                WeintCodex.SetBreadcrumb("Kalender", "Monat")
                f.StatusText:SetText("")
                f.RenderMonth()
            end,
        },
        {
            label   = "Mittwoch",
            onClick = function()
                ShowForm()
                activeDay = "wednesday"
                local data = WeintCodex.SavedData and WeintCodex.SavedData.raidWednesday
                f.PreviewSect:SetText(WeintCodex.ColorText("textFaint",
                    WeintCodex.Spaced("EINZULADENDE SPIELER"))
                    .. "  " .. WeintCodex.ColorText("textGhost", WeintCodex.Spaced("MITTWOCH")))
                WeintCodex.SetBreadcrumb("Kalender", "Mittwoch")
                AutoFillFromData(f, data)
                RefreshPlayerPreview(f, data)
                f.StatusText:SetText("")
            end,
        },
        {
            label   = "Donnerstag",
            onClick = function()
                ShowForm()
                activeDay = "thursday"
                local data = WeintCodex.SavedData and WeintCodex.SavedData.raidThursday
                f.PreviewSect:SetText(WeintCodex.ColorText("textFaint",
                    WeintCodex.Spaced("EINZULADENDE SPIELER"))
                    .. "  " .. WeintCodex.ColorText("textGhost", WeintCodex.Spaced("DONNERSTAG")))
                WeintCodex.SetBreadcrumb("Kalender", "Donnerstag")
                AutoFillFromData(f, data)
                RefreshPlayerPreview(f, data)
                f.StatusText:SetText("")
            end,
        },
    }

    WeintCodex.Navigation.BuildSidebar("Kalender", sidebarItems)

    -- Das Formular schon befuellen, damit der Wechsel auf "Mittwoch" nicht
    -- erst beim Klick Daten nachzieht (Verhalten wie bisher).
    local initData = WeintCodex.SavedData and WeintCodex.SavedData.raidWednesday
    AutoFillFromData(f, initData)
    RefreshPlayerPreview(f, initData)

    -- Startansicht ist das Monatsraster (Entwurf 2d).
    WeintCodex.Navigation.ActivateFirst()
end
