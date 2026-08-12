--------------------------------------------------
-- WeintCodex :: WeintAcademy (Lernzentrum)
--
-- Abgespeckte Ingame-Fassung der Academy aus WeintCompanion. Haengt
-- als Unterseiten unter "Charakter" (siehe WeintCodex.Charakter.Show).
--
-- Wie modules/weinttv.lua rechnet dieses Modul NICHTS: Sternebewertung,
-- Trainingsplan-Reihenfolge und Check-Ergebnisse kommen fertig aus der
-- Companion (Nachrichtentypen "academy_catalog"/"academy_state", Schema
-- im Kopfkommentar von modules/companion.lua). Damit koennen Desktop
-- und Addon nicht unterschiedlich bewerten.
--
-- Zwei Konventionen aus der Companion gelten hier unveraendert:
--   * stars == 0 heisst "keine Daten", NICHT "schlecht". Nullwertungen
--     fliessen nicht in den Durchschnitt ein und gelten nicht als
--     Schwachstelle.
--   * Das Log-Ergebnis (results) und das eigene Haekchen (completed)
--     werden nie ineinander geschrieben. Angezeigt wird "erledigt",
--     wenn eines von beidem zutrifft.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Academy = {}

local C          = WeintCodex.Colors
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

local MAX_STARS = 5

-- Reihenfolge und Beschriftung wie CATEGORY_ORDER/CATEGORY_LABELS der
-- Companion. Liefert der Sync eigene Kategorien mit, gewinnen deren
-- Beschriftungen (siehe CategoryLabel).
local CATEGORY_ORDER = {
    "rotation", "movement", "cooldowns", "mechanics", "survival", "output",
}

local CATEGORY_LABELS = {
    rotation  = "Rotation",
    movement  = "Movement",
    cooldowns = "Cooldowns",
    mechanics = "Mechaniken",
    survival  = "Überleben",
    output    = "Leistung",
}

local CATEGORY_HINTS = {
    rotation  = "Aktivzeit und Wirkungsdauern",
    movement  = "Vermeidbare Treffer und Laufwege",
    cooldowns = "Genutzte Einsätze und ihr Zeitpunkt",
    mechanics = "Unterbrechungen und Bossmechaniken",
    survival  = "Erhaltener Schaden und Tode",
    output    = "Platz im Ranking der eigenen Rolle",
}

local STATUS_LABEL = {
    passed  = "erfüllt",
    failed  = "nicht erfüllt",
    unknown = "keine Daten",
}

local STATUS_COLOR = {
    passed  = "success",
    failed  = "danger",
    unknown = "textDim",
}

local academyFrame = nil

--------------------------------------------------
-- Datenzugriff
--------------------------------------------------

local function Store()
    if WeintCodex.Companion and WeintCodex.Companion.AcademyStore then
        return WeintCodex.Companion.AcademyStore()
    end
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    local store = WeintCodex.SavedData.academy or {}
    store.completed = store.completed or {}
    store.excluded  = store.excluded  or {}
    WeintCodex.SavedData.academy = store
    return store
end

--------------------------------------------------
-- Wer ist "ich"?
--------------------------------------------------
-- Der EINGELOGGTE Charakter, und sonst niemand. Bis 1.3.2.3 stand
-- hier state.character - also der Name aus der zuletzt gelieferten
-- Nutzlast, mit UnitName nur als Rueckfall. Weil es kontoweit nur
-- einen Platz fuer diese Nutzlast gab, sah jeder Twink die Bewertung
-- des Mains, unter dessen Namen, mit dessen Klasse und dessen
-- Trainingsplan - und keine Stelle im Code konnte das bemerken, weil
-- Anzeige und Identitaet aus derselben Tabelle kamen.
--------------------------------------------------
local function CharacterName()
    local me = WeintCodex.Names.Me()
    if me ~= "" then return me end
    return UnitName("player") or "?"
end

-- Beide duerfen nil sein: "fuer diesen Charakter liegt nichts vor"
-- ist ein gueltiger Zustand und wird als solcher benannt.
local function Catalog()
    if WeintCodex.Companion and WeintCodex.Companion.AcademyCatalogFor then
        return WeintCodex.Companion.AcademyCatalogFor(CharacterName())
    end
    return nil
end

local function State()
    if WeintCodex.Companion and WeintCodex.Companion.AcademyStateFor then
        return WeintCodex.Companion.AcademyStateFor(CharacterName())
    end
    return nil
end

-- Fuer wen hat die Companion zuletzt ausgewertet? Nur fuer den
-- Hinweistext gedacht, nie als Identitaet.
local function DeliveredCharacter()
    if WeintCodex.Companion and WeintCodex.Companion.AcademyDeliveredCharacter then
        return WeintCodex.Companion.AcademyDeliveredCharacter()
    end
    return nil
end

local function Progress()
    if WeintCodex.Companion and WeintCodex.Companion.AcademyProgress then
        return WeintCodex.Companion.AcademyProgress(CharacterName())
    end
    local store = Store()
    local name  = CharacterName()
    store.completed[name] = store.completed[name] or {}
    store.excluded[name]  = store.excluded[name]  or {}
    return store.completed[name], store.excluded[name]
end

local function CategoryLabel(id)
    local catalog = Catalog()
    for _, cat in ipairs(catalog and catalog.categories or {}) do
        if cat.id == id then return cat.label or id end
    end
    return CATEGORY_LABELS[id] or id
end

local function CategoryHint(id)
    local catalog = Catalog()
    for _, cat in ipairs(catalog and catalog.categories or {}) do
        if cat.id == id and cat.hint then return cat.hint end
    end
    return CATEGORY_HINTS[id] or ""
end

-- Reihenfolge der Bewertungen: die bekannten Kategorien zuerst in der
-- Companion-Reihenfolge, alles Unbekannte hinten dran (statt es zu
-- verschlucken - eine neue Kategorie soll sichtbar sein, auch wenn das
-- Addon sie noch nicht kennt).
local function OrderedCategories()
    local catalog = Catalog()
    local order, seen = {}, {}

    local source = (catalog and catalog.categories and #catalog.categories > 0)
        and catalog.categories or nil

    if source then
        for _, cat in ipairs(source) do
            if cat.id and not seen[cat.id] then
                seen[cat.id] = true
                order[#order + 1] = cat.id
            end
        end
        return order
    end

    for _, id in ipairs(CATEGORY_ORDER) do
        seen[id] = true
        order[#order + 1] = id
    end

    local state = State()
    for _, rating in ipairs(state and state.ratings or {}) do
        if rating.category and not seen[rating.category] then
            seen[rating.category] = true
            order[#order + 1] = rating.category
        end
    end

    return order
end

local function RatingFor(category)
    local state = State()
    for _, rating in ipairs(state and state.ratings or {}) do
        if rating.category == category then return rating end
    end
    return nil
end

local function LessonById(id)
    local catalog = Catalog()
    for _, lesson in ipairs(catalog and catalog.lessons or {}) do
        if lesson.id == id then return lesson end
    end
    return nil
end

-- Gilt die Lektion fuer den aktuellen Charakter? Bildet die Auswahl aus
-- registry.py nach (Encounter -> Spec -> Klasse -> Rolle -> generisch):
-- ein leeres Feld heisst "gilt fuer alle".
local function AppliesToMe(lesson)
    local state = State()
    local actor = (state and state.actor) or {}

    if lesson.class and lesson.class ~= "" then
        if (actor.class or "") ~= lesson.class then return false end
    end
    if lesson.spec and lesson.spec ~= "" then
        if (actor.spec or "") ~= lesson.spec then return false end
    end
    if lesson.encounter and lesson.encounter ~= "" then
        if (state and state.encounter or "") ~= lesson.encounter then return false end
    end
    if type(lesson.roles) == "table" and #lesson.roles > 0 then
        local match = false
        for _, role in ipairs(lesson.roles) do
            if role == (actor.role or "") then match = true break end
        end
        if not match then return false end
    end
    return true
end

local function ApplicableLessons()
    local catalog = Catalog()
    local result  = {}
    for _, lesson in ipairs(catalog and catalog.lessons or {}) do
        if lesson.id and AppliesToMe(lesson) then result[#result + 1] = lesson end
    end
    return result
end

local function ResultFor(lessonId)
    local state = State()
    local results = state and state.results
    return results and results[lessonId] or nil
end

-- "erledigt" = eigenes Haekchen ODER im Log nachgewiesen.
local function IsDone(lessonId, completed)
    if completed[lessonId] then return true end
    local res = ResultFor(lessonId)
    return res ~= nil and res.status == "passed"
end

--------------------------------------------------
-- Bausteine
--------------------------------------------------

local function ClearContent()
    local cp = WeintCodex.ContentPanel
    if not cp then return end
    for _, child in pairs({ cp:GetChildren() }) do child:Hide() end
end

local function Text(parent, size, point, rel, relPoint, x, y, width, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    -- Groesse kommt vom Aufrufer; ab 14 die halbfette Schnitt-Variante,
    -- wie im Entwurf (Kartentitel halbfett, Fliesstext normal).
    fs:SetFont(size >= 14 and WeintCodex.Fonts.sansSemi or WeintCodex.Fonts.sans, size, "")
    fs:SetPoint(point, rel, relPoint, x, y)
    if width then fs:SetWidth(width) end
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

-- Bewertungsbalken aus fuenf Segmenten. Bewusst gezeichnet statt ueber
-- eine Sterntextur: ein falscher Texturpfad faellt im Spiel nicht auf,
-- er bleibt einfach leer. Die Zahl daneben macht den Wert eindeutig.
local SEGMENT_W, SEGMENT_H, SEGMENT_GAP = 16, 10, 3

local function DrawRatingBar(parent, x, y, stars)
    for i = 1, MAX_STARS do
        local seg = parent:CreateTexture(nil, "OVERLAY")
        seg:SetSize(SEGMENT_W, SEGMENT_H)
        seg:SetPoint("TOPLEFT", parent, "TOPLEFT",
            x + (i - 1) * (SEGMENT_W + SEGMENT_GAP), y)
        if stars > 0 and i <= stars then
            seg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.95)
        else
            seg:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 0.85)
        end
    end
    return MAX_STARS * (SEGMENT_W + SEGMENT_GAP)
end

local function DrawPageHeader(frame, titleText)
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(WeintCodex.Fonts.serif, 19, "")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    title:SetText("|cffD4A24A" .. titleText .. "|r")

    WeintCodex.SetBreadcrumb("Charakter", "Academy", titleText)

    local state = State()
    local sub = Text(frame, 10, "TOPLEFT", frame, "TOPLEFT", 16, -40)
    if state then
        local parts = {}
        if state.encounter then parts[#parts + 1] = state.encounter end
        if state.pull      then parts[#parts + 1] = "Pull " .. tostring(state.pull) end
        if state.capturedAt then
            parts[#parts + 1] = "Stand: " .. date("%d.%m.%Y %H:%M", state.capturedAt)
        end
        sub:SetText(WeintCodex.ColorText("textFaint", table.concat(parts, "  ·  ")))
    else
        sub:SetText(WeintCodex.ColorText("textDim",
            "Noch keine Auswertung von WeintCompanion erhalten"))
    end

    return -62
end

local function DrawNotice(frame, y, message, height)
    height = height or 74
    local card = WeintCodex.CreateCard(frame, {
        width = frame:GetWidth() - 32, height = height, surface = "surface1",
        style = "border", borderColor = "hairline",
    })
    card:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, y)

    local fs = card:CreateFontString(nil, "OVERLAY")
    fs:SetFont(WeintCodex.Fonts.sans, 11, "")
    fs:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -14)
    fs:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 12)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetText(WeintCodex.ColorText("textMuted", message))

    return y - (height + 12)
end

local NO_DATA_TEXT =
    "WeintCompanion hat noch keine Academy-Daten geliefert. Sobald die "
    .. "Desktop-App einen Raid ausgewertet hat, erscheinen Bewertung und "
    .. "Trainingsplan hier — beim naechsten Login oder nach /reload."

-- Es gibt Daten, nur nicht fuer diesen Charakter. Das ist etwas ganz
-- anderes als "noch nichts geliefert" und fuehrt zu einer anderen
-- Handlung, deshalb ein eigener Text: der Nutzer muss wissen, dass
-- die Verbindung steht und nur die Auswahl auf dem Desktop auf
-- jemand anderem steht.
local function NoDataText()

    local delivered = DeliveredCharacter()

    if not delivered or delivered == "" then
        return NO_DATA_TEXT
    end

    if WeintCodex.Names.Equal(delivered, CharacterName()) then
        return NO_DATA_TEXT
    end

    return "Fuer " .. CharacterName() .. " liegt noch keine Auswertung vor. "
        .. "Zuletzt hat WeintCompanion " .. tostring(delivered)
        .. " ausgewertet. Waehle dort diesen Charakter aus — die Auswertung "
        .. "erscheint nach dem naechsten Login oder /reload."

end

local function Page(titleText, build)
    ClearContent()
    if academyFrame then academyFrame:Hide() end

    -- Wir haengen in der Charakter-Sidebar, sind aber ein eigenes Modul:
    -- dem Charakter-Modul sagen, dass gerade keine seiner Seiten sichtbar
    -- ist, sonst zeichnet es bei jedem Ausruestungswechsel darueber.
    if WeintCodex.Charakter and WeintCodex.Charakter.LeaveView then
        WeintCodex.Charakter.LeaveView()
    end

    local cp = WeintCodex.ContentPanel
    if not cp then return end

    academyFrame = CreateFrame("Frame", nil, cp)
    academyFrame:SetAllPoints(cp)
    academyFrame:Show()

    local y = DrawPageHeader(academyFrame, titleText)

    if not Catalog() and not State() then
        DrawNotice(academyFrame, y, NoDataText(), 104)
        WeintCodex.Navigation.SetInspector({
            { type = "header", text = "Academy" },
            { type = "card", lines = {
                "Bewertung und Lektionen entstehen in",
                "WeintCompanion und werden von dort",
                "ins Addon uebertragen.",
            } },
        })
        return
    end

    build(academyFrame, y)
end

--------------------------------------------------
-- Seite: Lernzentrum
--------------------------------------------------

function WeintCodex.Academy.ShowOverview()
    Page("Lernzentrum", function(frame, y)
        local state = State()
        local actor = (state and state.actor) or {}
        local completed = Progress()

        -- Charakterkarte
        local card = WeintCodex.CreateCard(frame, {
            width = frame:GetWidth() - 32, height = 62,
            surface = "surface2", style = "border", borderColor = "hairline",
        })
        card:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, y)

        local nameLbl = Text(card, 14, "TOPLEFT", card, "TOPLEFT", 14, -12)
        -- "-" ist der Wert einer aelteren Companion fuer "Spieler im
        -- Pull nicht gefunden" - als Charaktername unbrauchbar.
        local shown = actor.name
        if not shown or shown == "" or shown == "-" then shown = CharacterName() end
        nameLbl:SetText(WeintCodex.ColorText("textBright", shown))

        local specParts = {}
        if actor.spec  then specParts[#specParts + 1] = actor.spec end
        if actor.class then specParts[#specParts + 1] = actor.class end
        if actor.role  then specParts[#specParts + 1] = actor.role end
        local specLbl = Text(card, 10, "TOPLEFT", card, "TOPLEFT", 14, -34)
        specLbl:SetText(WeintCodex.ColorText("textMuted",
            #specParts > 0 and table.concat(specParts, " · ") or "Spec unbekannt"))

        -- Durchschnitt: Nullwertungen zaehlen NICHT mit (0 = keine Daten).
        local sum, rated = 0, 0
        for _, id in ipairs(OrderedCategories()) do
            local r = RatingFor(id)
            if r and (r.stars or 0) > 0 then
                sum = sum + r.stars
                rated = rated + 1
            end
        end
        local avgLbl = Text(card, 12, "TOPRIGHT", card, "TOPRIGHT", -14, -20, 160, "RIGHT")
        if rated > 0 then
            avgLbl:SetText(WeintCodex.ColorText("purple",
                (string.format("%.1f", sum / rated):gsub("%.", ",")) .. " / 5"))
        else
            avgLbl:SetText(WeintCodex.ColorText("textDim", "noch keine Bewertung"))
        end

        y = y - 74

        -- Bewertungsblock
        local head = Text(frame, 9, "TOPLEFT", frame, "TOPLEFT", 20, y)
        head:SetText(WeintCodex.ColorText("textFaint", "BEWERTUNG"))
        y = y - 20

        for _, id in ipairs(OrderedCategories()) do
            local rating = RatingFor(id)
            local stars  = rating and rating.stars or 0

            local lbl = Text(frame, 11, "TOPLEFT", frame, "TOPLEFT", 24, y, 110)
            lbl:SetText(WeintCodex.ColorText(
                stars > 0 and "textNormal" or "textDim", CategoryLabel(id)))

            DrawRatingBar(frame, 140, y + 1, stars)

            local valLbl = Text(frame, 10, "TOPLEFT", frame, "TOPLEFT", 244, y, 44, "RIGHT")
            valLbl:SetText(WeintCodex.ColorText(
                stars > 0 and "textMuted" or "textGhost",
                stars > 0 and (stars .. "/5") or "—"))

            local detail = Text(frame, 10, "TOPLEFT", frame, "TOPLEFT", 300, y,
                math.max(frame:GetWidth() - 340, 160))
            detail:SetWordWrap(false)
            if stars > 0 then
                detail:SetText(WeintCodex.ColorText("textMuted",
                    rating.detail or CategoryHint(id)))
            else
                detail:SetText(WeintCodex.ColorText("textGhost",
                    CategoryHint(id) .. " — noch keine Daten."))
            end

            y = y - 24
        end

        y = y - 12

        -- Naechste offene Lektion aus der vom Sync gelieferten Reihenfolge
        local nextLesson = nil
        for _, id in ipairs(state and state.plan or {}) do
            if not IsDone(id, completed) then
                nextLesson = LessonById(id)
                if nextLesson then break end
            end
        end

        if nextLesson then
            local nl = WeintCodex.CreateCard(frame, {
                width = frame:GetWidth() - 32, height = 66,
                surface = "surface2", tone = "plain", radius = 14, backdrop = "bgDark",
            })
            nl:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, y)

            local eyebrow = Text(nl, 9, "TOPLEFT", nl, "TOPLEFT", 14, -10)
            eyebrow:SetText(WeintCodex.ColorText("purple",
                "NÄCHSTE LEKTION · " .. string.upper(CategoryLabel(nextLesson.category))))

            local t = Text(nl, 12, "TOPLEFT", nl, "TOPLEFT", 14, -26, nl:GetWidth() - 28)
            t:SetWordWrap(false)
            t:SetText(WeintCodex.ColorText("textBright", nextLesson.title or "—"))

            local s = Text(nl, 10, "TOPLEFT", nl, "TOPLEFT", 14, -44, nl:GetWidth() - 28)
            s:SetWordWrap(false)
            s:SetText(WeintCodex.ColorText("textMuted", nextLesson.summary or ""))

            y = y - 78
        end

        -- Fortschritt gegen den vollen anwendbaren Katalog, nicht gegen den
        -- Plan: ein planbezogener Balken saehe nach Rueckschritt aus,
        -- sobald neue Schwachstellen dazukommen.
        local lessons = ApplicableLessons()
        local _, excluded = Progress()
        local total, done = 0, 0
        for _, lesson in ipairs(lessons) do
            if not excluded[lesson.id] then
                total = total + 1
                if IsDone(lesson.id, completed) then done = done + 1 end
            end
        end

        local prog = Text(frame, 10, "TOPLEFT", frame, "TOPLEFT", 20, y)
        prog:SetText(WeintCodex.ColorText("textMuted",
            string.format("%d von %d Lektionen erledigt", done, total)))

        WeintCodex.Navigation.SetInspector({
            { type = "header", text = "Bewertung" },
            { type = "rows", rows = {
                { label = "Bewertete Bereiche", value = rated .. " / " .. #OrderedCategories() },
                { label = "Lektionen erledigt", value = done .. " / " .. total },
            } },
            { type = "divider" },
            { type = "header", text = "Lesehilfe" },
            { type = "card", lines = {
                "Ein leerer Balken heisst 'keine Daten',",
                "nicht 'schlecht'. Bereiche ohne Daten",
                "zaehlen weder im Durchschnitt noch im",
                "Trainingsplan mit.",
            } },
        })
    end)
end

--------------------------------------------------
-- Seite: Trainingsplan
--------------------------------------------------

function WeintCodex.Academy.ShowPlan()
    Page("Trainingsplan", function(frame, y)
        local state = State()
        local completed, excluded = Progress()

        -- Plan aus dem Sync; ohne Plan die anwendbaren Lektionen zeigen,
        -- damit die Seite auch vor der ersten Auswertung nicht leer ist.
        local ids = {}
        for _, id in ipairs(state and state.plan or {}) do ids[#ids + 1] = id end
        if #ids == 0 then
            for _, lesson in ipairs(ApplicableLessons()) do ids[#ids + 1] = lesson.id end
        end

        local shown = {}
        for _, id in ipairs(ids) do
            if not excluded[id] and LessonById(id) then shown[#shown + 1] = id end
        end

        if #shown == 0 then
            DrawNotice(frame, y,
                "Kein Trainingsplan vorhanden. Sobald WeintCompanion einen "
                .. "Pull ausgewertet hat, stehen hier die passenden Lektionen.")
            WeintCodex.Navigation.SetInspector({
                { type = "header", text = "Trainingsplan" },
                { type = "card", lines = { "Noch keine Lektionen." } },
            })
            return
        end

        local sf, inner = WeintCodex.CreateScrollArea(frame, 14, y, 20, 400)
        sf:ClearAllPoints()
        sf:SetPoint("TOPLEFT",     frame, "TOPLEFT",     14, y)
        sf:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 24)
        inner:SetWidth(sf:GetWidth() - 22)

        local yOff  = 0
        local first = true

        for _, id in ipairs(shown) do
            local lesson = LessonById(id)
            local res    = ResultFor(id)
            local steps  = type(lesson.steps) == "table" and lesson.steps or {}

            -- Kartenhoehe aus dem Inhalt: Kopf + Zusammenfassung + Schritte
            -- + optional die Check-Zeile.
            local cardH = 62 + (#steps * 16) + (res and 18 or 0)

            local card = CreateFrame("Frame", nil, inner)
            card:SetSize(inner:GetWidth() - 4, cardH)
            card:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
            SetSolidBg(card, C.surface2[1], C.surface2[2], C.surface2[3], 0.68)

            local isDone = IsDone(id, completed)
            local stripe = card:CreateTexture(nil, "BORDER")
            stripe:SetSize(3, cardH)
            stripe:SetPoint("LEFT", card, "LEFT", 0, 0)
            local sc = isDone and C.successBright or (res and res.status == "failed" and C.dangerBright or C.textFaint)
            stripe:SetColorTexture(sc[1], sc[2], sc[3], 0.80)

            local eyebrow = Text(card, 9, "TOPLEFT", card, "TOPLEFT", 14, -8)
            local prefix  = (first and not isDone) and "NÄCHSTE LEKTION · " or ""
            eyebrow:SetText(WeintCodex.ColorText("purple",
                prefix .. string.upper(CategoryLabel(lesson.category))))
            if not isDone then first = false end

            local title = Text(card, 12, "TOPLEFT", card, "TOPLEFT", 14, -22,
                card:GetWidth() - 150)
            title:SetWordWrap(false)
            title:SetText(WeintCodex.ColorText("textBright", lesson.title or "—"))

            local summary = Text(card, 10, "TOPLEFT", card, "TOPLEFT", 14, -40,
                card:GetWidth() - 150)
            summary:SetWordWrap(false)
            summary:SetText(WeintCodex.ColorText("textMuted", lesson.summary or ""))

            local rowY = -58
            if res then
                local details = {}
                for _, chk in ipairs(res.checks or {}) do
                    if chk.detail then details[#details + 1] = chk.detail end
                end
                local line = Text(card, 10, "TOPLEFT", card, "TOPLEFT", 14, rowY,
                    card:GetWidth() - 150)
                line:SetWordWrap(false)
                line:SetText(WeintCodex.ColorText(
                        STATUS_COLOR[res.status] or "textDim",
                        string.upper(STATUS_LABEL[res.status] or "?"))
                    .. (details[1] and ("  " .. WeintCodex.ColorText("textMuted",
                        table.concat(details, " · "))) or ""))
                rowY = rowY - 18
            end

            for i, step in ipairs(steps) do
                local st = Text(card, 10, "TOPLEFT", card, "TOPLEFT", 24, rowY,
                    card:GetWidth() - 160)
                st:SetWordWrap(false)
                st:SetText(WeintCodex.ColorText("textDim", i .. ". ") ..
                    WeintCodex.ColorText("textMuted", step))
                rowY = rowY - 16
            end

            -- Erledigt-Haken. Schreibt NUR completed; das Log-Ergebnis
            -- bleibt unangetastet.
            local check = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
            check:SetSize(22, 22)
            check:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -12)
            check:SetChecked(completed[id] and true or false)
            check:SetScript("OnClick", function(self)
                local done = Progress()
                done[id] = self:GetChecked() and true or nil
                if WeintCodex.Companion and WeintCodex.Companion.SendAcademyProgress then
                    WeintCodex.Companion.SendAcademyProgress()
                end
                WeintCodex.Academy.ShowPlan()
            end)

            local checkLbl = Text(card, 9, "TOPRIGHT", check, "BOTTOMRIGHT", 4, -2, 80, "RIGHT")
            checkLbl:SetText(WeintCodex.ColorText(
                isDone and "success" or "textFaint", "erledigt"))

            yOff = yOff - (cardH + 8)
        end

        inner:SetHeight(math.abs(yOff) + 10)

        local open = 0
        for _, id in ipairs(shown) do
            if not IsDone(id, completed) then open = open + 1 end
        end

        WeintCodex.Navigation.SetInspector({
            { type = "header", text = "Trainingsplan" },
            { type = "rows", rows = {
                { label = "Lektionen", value = tostring(#shown) },
                { label = "Offen",     value = tostring(open),
                  valueColor = open > 0 and "warning" or "success" },
            } },
            { type = "divider" },
            { type = "card", lines = {
                "Der Haken ist deine eigene Notiz und",
                "wird an WeintCompanion zurueckgemeldet.",
                "Das Ergebnis aus dem Log bleibt davon",
                "unberuehrt.",
            } },
        })
    end)
end

--------------------------------------------------
-- Seite: Katalog
--------------------------------------------------

function WeintCodex.Academy.ShowCatalog()
    Page("Katalog", function(frame, y)
        local _, excluded = Progress()
        local lessons = ApplicableLessons()

        if #lessons == 0 then
            DrawNotice(frame, y,
                "Es wurde noch kein Lektionskatalog uebertragen.")
            WeintCodex.Navigation.SetInspector({
                { type = "header", text = "Katalog" },
                { type = "card", lines = { "Keine Lektionen vorhanden." } },
            })
            return
        end

        -- Nach Kategorie gruppieren, Reihenfolge wie in der Bewertung.
        local byCategory = {}
        for _, lesson in ipairs(lessons) do
            local key = lesson.category or "other"
            byCategory[key] = byCategory[key] or {}
            table.insert(byCategory[key], lesson)
        end

        local sf, inner = WeintCodex.CreateScrollArea(frame, 14, y, 20, 400)
        sf:ClearAllPoints()
        sf:SetPoint("TOPLEFT",     frame, "TOPLEFT",     14, y)
        sf:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 24)
        inner:SetWidth(sf:GetWidth() - 22)

        local yOff = 0
        local order = OrderedCategories()

        -- Kategorien ohne Bewertung, die trotzdem Lektionen haben, hinten
        -- anhaengen statt sie zu verschlucken.
        local seen = {}
        for _, id in ipairs(order) do seen[id] = true end
        for key in pairs(byCategory) do
            if not seen[key] then order[#order + 1] = key end
        end

        local activeTotal = 0

        for _, category in ipairs(order) do
            local group = byCategory[category]
            if group then
                table.sort(group, function(a, b)
                    return (a.title or "") < (b.title or "")
                end)

                local active = 0
                for _, lesson in ipairs(group) do
                    if not excluded[lesson.id] then active = active + 1 end
                end
                activeTotal = activeTotal + active

                local head = Text(inner, 10, "TOPLEFT", inner, "TOPLEFT", 6, yOff)
                head:SetText(WeintCodex.ColorText("purple",
                        string.upper(CategoryLabel(category)))
                    .. "   " .. WeintCodex.ColorText("textFaint",
                        active .. " von " .. #group .. " aktiv"))
                yOff = yOff - 20

                for _, lesson in ipairs(group) do
                    local row = CreateFrame("Frame", nil, inner)
                    row:SetSize(inner:GetWidth() - 4, 26)
                    row:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)

                    local box = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    box:SetSize(20, 20)
                    box:SetPoint("LEFT", row, "LEFT", 6, 0)
                    box:SetChecked(not excluded[lesson.id])
                    box:SetScript("OnClick", function(self)
                        local _, excl = Progress()
                        -- Gespeichert werden AUSSCHLUESSE (wie in der
                        -- Companion): neue Lektionen sind damit automatisch
                        -- aktiv, ohne Migration.
                        excl[lesson.id] = (not self:GetChecked()) and true or nil
                        if WeintCodex.Companion
                           and WeintCodex.Companion.SendAcademyProgress then
                            WeintCodex.Companion.SendAcademyProgress()
                        end
                        WeintCodex.Academy.ShowCatalog()
                    end)

                    local lbl = Text(row, 11, "LEFT", row, "LEFT", 32, 0,
                        row:GetWidth() - 44)
                    lbl:SetWordWrap(false)
                    lbl:SetText(WeintCodex.ColorText(
                        excluded[lesson.id] and "textGhost" or "textNormal",
                        lesson.title or lesson.id))

                    yOff = yOff - 28
                end

                yOff = yOff - 10
            end
        end

        inner:SetHeight(math.abs(yOff) + 10)

        WeintCodex.Navigation.SetInspector({
            { type = "header", text = "Katalog" },
            { type = "rows", rows = {
                { label = "Lektionen", value = tostring(#lessons) },
                { label = "Aktiv",     value = tostring(activeTotal) },
            } },
            { type = "divider" },
            { type = "button", label = "Alle wieder aufnehmen", style = "primary",
              onClick = function()
                  local _, excl = Progress()
                  for id in pairs(excl) do excl[id] = nil end
                  if WeintCodex.Companion
                     and WeintCodex.Companion.SendAcademyProgress then
                      WeintCodex.Companion.SendAcademyProgress()
                  end
                  WeintCodex.Academy.ShowCatalog()
              end },
        })
    end)
end
