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
        msg = msg .. "\n|cffC85A3AFehlgeschlagen:|r " .. table.concat(failed, ", ")
    end

    statusCallback(true, msg)
end

--------------------------------------------------
-- Kleines Input-Feld Helper
--------------------------------------------------

local function MakeInputField(parent, label, x, y, w, defaultText)
    local labelStr = parent:CreateFontString(nil, "OVERLAY")
    labelStr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    labelStr:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    labelStr:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    labelStr:SetText(label)

    local bg = CreateFrame("Frame", nil, parent)
    bg:SetSize(w, 26)
    bg:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 16)
    SetSolidBg(bg, C.headerBg[1], C.headerBg[2], C.headerBg[3], 0.90)
    DrawBorder(bg, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50, 1)

    local eb = CreateFrame("EditBox", nil, bg)
    eb:SetSize(w - 8, 20)
    eb:SetPoint("LEFT", bg, "LEFT", 4, 0)
    eb:SetAutoFocus(false)
    eb:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
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
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(54)
    header:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    SetSolidBg(header, C.bgMid[1], C.bgMid[2], C.bgMid[3], 0.50)

    local titleStr = header:CreateFontString(nil, "OVERLAY")
    titleStr:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    titleStr:SetPoint("TOPLEFT", header, "TOPLEFT", 20, -14)
    titleStr:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    titleStr:SetText("Kalender")

    local subStr = header:CreateFontString(nil, "OVERLAY")
    subStr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    subStr:SetPoint("BOTTOMLEFT", titleStr, "BOTTOMRIGHT", 10, 2)
    subStr:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    subStr:SetText(WeintCodex.ColorText("textFaint", "Kalender-Eintrag aus Raidanmeldungen erstellen"))

    local headerDiv = header:CreateTexture(nil, "OVERLAY")
    headerDiv:SetHeight(1)
    headerDiv:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  0, 0)
    headerDiv:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50)

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
    local detailsSect = leftPanel:CreateFontString(nil, "OVERLAY")
    detailsSect:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    detailsSect:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -16)
    detailsSect:SetText("|cffC8763AEVENT-DETAILS|r")

    local detailsLine = leftPanel:CreateTexture(nil, "OVERLAY")
    detailsLine:SetHeight(1)
    detailsLine:SetPoint("TOPLEFT",  leftPanel, "TOPLEFT",  16, -30)
    detailsLine:SetSize(LEFT_W - 32, 1)
    detailsLine:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50)

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
    timeSep:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    timeSep:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 276, -100)
    timeSep:SetText("|cff6B6259:|r")

    -- Beschreibung
    local descLabel = leftPanel:CreateFontString(nil, "OVERLAY")
    descLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    descLabel:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -130)
    descLabel:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    descLabel:SetText("Beschreibung")

    local descBg = CreateFrame("Frame", nil, leftPanel)
    descBg:SetSize(LEFT_W - 32, 60)
    descBg:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -144)
    SetSolidBg(descBg, C.headerBg[1], C.headerBg[2], C.headerBg[3], 0.90)
    DrawBorder(descBg, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50, 1)

    local descBox = CreateFrame("EditBox", nil, descBg)
    descBox:SetSize(LEFT_W - 44, 54)
    descBox:SetPoint("TOPLEFT", descBg, "TOPLEFT", 4, -4)
    descBox:SetMultiLine(true)
    descBox:SetMaxLetters(0)
    descBox:SetAutoFocus(false)
    descBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
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
    DrawBorder(autoFillBtn, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50, 1)

    local autoFillLbl = autoFillBtn:CreateFontString(nil, "OVERLAY")
    autoFillLbl:SetAllPoints(autoFillBtn)
    autoFillLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    autoFillLbl:SetText("|cff8A8177" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 14) .. "  Felder aus Raidanmeldung befüllen|r")

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
            f.StatusText:SetText("|cffC85A3A" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_QuestionMark", 14) .. " Keine Raidanmeldung für " ..
                ((activeDay == "thursday") and "Donnerstag" or "Mittwoch") ..
                " vorhanden. Bitte zuerst importieren.|r")
        end
    end)
    f.AutoFillBtn = autoFillBtn

    -- Section: Einladungsoptionen
    local invSect = leftPanel:CreateFontString(nil, "OVERLAY")
    invSect:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    invSect:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -262)
    invSect:SetText("|cffC8763AEINLADUNGEN|r")

    local invLine = leftPanel:CreateTexture(nil, "OVERLAY")
    invLine:SetHeight(1)
    invLine:SetSize(LEFT_W - 32, 1)
    invLine:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -276)
    invLine:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50)

    -- Checkboxes für Rollen-Filter
    local function MakeCheckbox(parent, label, x, y, default)
        local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        cb:SetChecked(default ~= false)

        local lbl = parent:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetText(label)
        lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

        return cb
    end

    local cbTank   = MakeCheckbox(leftPanel, "|cff6BA0D9" .. WeintCodex.Icon("Interface\\Icons\\Ability_Warrior_DefensiveStance", 14) .. "  Tanks einladen|r",   16, -284, true)
    local cbHealer = MakeCheckbox(leftPanel, "|cff4A7C59" .. WeintCodex.Icon("Interface\\Icons\\Spell_Holy_Renew", 14) .. "  Heiler einladen|r",  16, -308, true)
    local cbDps    = MakeCheckbox(leftPanel, "|cffC85A3A" .. WeintCodex.Icon("Interface\\Icons\\Ability_DualWield", 14) .. "  DPS einladen|r",     16, -332, true)
    local cbMerge  = MakeCheckbox(leftPanel, "|cffC8763A" .. WeintCodex.Icon("Interface\\Icons\\Achievement_Character_Human_Male", 14) .. "  Raidtage zusammenführen|r", 16, -356, false)
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
    createBtnLbl:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    createBtnLbl:SetText("|cffffffff" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 16) .. "  Kalender-Eintrag erstellen|r")

    createBtn:SetScript("OnEnter", function(self)
        SetSolidBg(self, math.min(1, C.purple[1] * 1.25), math.min(1, C.purple[2] * 1.25), math.min(1, C.purple[3] * 1.15), 0.95)
    end)
    createBtn:SetScript("OnLeave", function(self)
        SetSolidBg(self, C.purple[1], C.purple[2], C.purple[3], 0.85)
    end)

    -- Status text
    local statusText = leftPanel:CreateFontString(nil, "OVERLAY")
    statusText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    statusText:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 16, -448)
    statusText:SetWidth(LEFT_W - 32)
    statusText:SetJustifyH("LEFT")
    statusText:SetSpacing(3)
    statusText:SetText("")
    f.StatusText = statusText

    -- API info text
    local apiInfo = leftPanel:CreateFontString(nil, "OVERLAY")
    apiInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
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
            apiInfo:SetText("|cffC85A3A" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_QuestionMark", 14) .. " Kalender-API nicht erkannt – manuelles Erstellen nötig|r")
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
    bodyDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40)

    -- ============================
    -- RECHTE SEITE: Spielervorschau
    -- ============================

    local rightPanel = CreateFrame("Frame", nil, body)
    rightPanel:SetPoint("TOPLEFT",     body, "TOPLEFT",     LEFT_W + 6,  0)
    rightPanel:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0,           0)

    local previewSect = rightPanel:CreateFontString(nil, "OVERLAY")
    previewSect:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    previewSect:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -16)
    previewSect:SetText("|cffC8763AEINZULADENDE SPIELER|r")
    f.PreviewSect = previewSect

    local previewLine = rightPanel:CreateTexture(nil, "OVERLAY")
    previewLine:SetHeight(1)
    previewLine:SetPoint("TOPLEFT",  rightPanel, "TOPLEFT",  10, -30)
    previewLine:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -10, -30)
    previewLine:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50)

    -- Spieler-Zähler
    local previewCount = rightPanel:CreateFontString(nil, "OVERLAY")
    previewCount:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
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

        f.StatusText:SetText("|cffC8763A" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 14) .. " Kalender wird vorbereitet...|r")

        CreateIngameCalendarEvent(
            title, descText, dateStr, hour, minute, invitePlayers,
            function(success, msg)
                if success then
                    f.StatusText:SetText("|cff33D65E" .. msg .. "|r")
                    print("|cffC8763A[WeintCodex Kalender]|r |cff33D65E" ..
                        "Eintrag '" .. title .. "' vorbereitet (" ..
                        #invitePlayers .. " Spieler).|r")
                else
                    f.StatusText:SetText("|cffC85A3A" .. msg .. "|r")
                end
            end
        )
    end)

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
        noData:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
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
        nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        nameLbl:SetPoint("LEFT", row, "LEFT", 18, 0)
        nameLbl:SetText(ccol .. (p.name or "?") .. "|r")
        nameLbl:SetWidth(160)

        -- Class
        local classLbl = row:CreateFontString(nil, "OVERLAY")
        classLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        classLbl:SetPoint("LEFT", row, "LEFT", 190, 0)
        classLbl:SetText("|cff6B6259" .. (p.class or "") .. "|r")
        classLbl:SetWidth(120)

        table.insert(activePreviewRows, row)
        offsetY = offsetY - 26
    end

    pc:SetHeight(math.abs(offsetY) + 10)

    f.PreviewCount:SetText(
        "|cff6BA0D9" .. tanks .. "T|r  " ..
        "|cff4A7C59" .. healers .. "H|r  " ..
        "|cffC85A3A" .. dps .. "D|r  " ..
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

    local sidebarItems = {
        {
            label   = "Mittwoch",
            onClick = function()
                activeDay = "wednesday"
                local data = WeintCodex.SavedData and WeintCodex.SavedData.raidWednesday
                f.PreviewSect:SetText("|cffC8763AEINZULADENDE SPIELER|r  |cff6B6259Mittwoch|r")
                WeintCodex.SetBreadcrumb("Kalender", "Mittwoch")
                AutoFillFromData(f, data)
                RefreshPlayerPreview(f, data)
                f.StatusText:SetText("")
            end,
        },
        {
            label   = "Donnerstag",
            onClick = function()
                activeDay = "thursday"
                local data = WeintCodex.SavedData and WeintCodex.SavedData.raidThursday
                f.PreviewSect:SetText("|cffC8763AEINZULADENDE SPIELER|r  |cff6B6259Donnerstag|r")
                WeintCodex.SetBreadcrumb("Kalender", "Donnerstag")
                AutoFillFromData(f, data)
                RefreshPlayerPreview(f, data)
                f.StatusText:SetText("")
            end,
        },
    }

    WeintCodex.Navigation.BuildSidebar("Kalender", sidebarItems)
    WeintCodex.SetBreadcrumb("Kalender", "Mittwoch")

    -- Default: Mittwoch
    local initData = WeintCodex.SavedData and WeintCodex.SavedData.raidWednesday
    AutoFillFromData(f, initData)
    RefreshPlayerPreview(f, initData)
end
