--------------------------------------------------
-- WeintCodex :: Onboarding & Update-Changelog
-- Zeigt neuen Nutzern eine kurze Feature-Tour beim ersten Login und
-- informiert bestehende Nutzer nach einem Update per Popup ueber die
-- Aenderungen (data/changelog.lua). Beide Modi teilen sich dasselbe
-- Fenster - siehe EnsureFrame().
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Onboarding = {}

local C          = WeintCodex.C
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

--------------------------------------------------
-- Fenstermasse
--
-- WINDOW_H ist die Grundhoehe (sie traegt jede Tourseite), WINDOW_H_MAX
-- die Grenze, ab der stattdessen gescrollt wird. Die Grenze liegt unter
-- der kleinsten zulaessigen Hoehe des Hauptfensters (780, siehe
-- core/ui.lua), damit das Popup auch dort vollstaendig darin liegt.
--
-- Warum ueberhaupt beides: der Changelog eines Updates ist beliebig lang.
-- Bisher war der Text ein fester FontString auf dem Fenster - was nicht
-- hineinpasste, wurde nicht abgeschnitten, sondern lief unten heraus und
-- war unerreichbar. Sichtbar wurde das erst bei einem Sammelupdate ueber
-- mehrere Versionen, also genau dann, wenn es am meisten zu lesen gibt.
--------------------------------------------------

local WINDOW_W, WINDOW_H = 520, 380
local WINDOW_H_MAX = 620

-- Der Textbereich sitzt zwischen Trennlinie (BODY_TOP unter der
-- Fensterkante) und Knopfzeile (BODY_BOTTOM ueber der Unterkante).
local BODY_TOP, BODY_BOTTOM, BODY_X = 130, 64, 28

local overlay, window
local iconStr, titleStr, stepStr, bodyStr
local bodyScroll, bodyInner
local buttonRow = {}
local currentStep = 1

local TOUR_STEPS = {
    { icon = "Interface\\Icons\\INV_Misc_Book_09", title = "Willkommen bei WeintCodex",
      body = "WeintCodex ist euer Raid Guide & Intelligence System fuer die Gilde: Bossguides, Raidplanung, Charakterpflege, Materialtracking und WeakAuras - alles an einem Ort.\n\nEin kurzer Rundgang durch die wichtigsten Bereiche:" },
    { icon = "Interface\\Icons\\Achievement_Character_Human_Male", title = "Charakter",
      body = "Prueft eure Verzauberungen und Sockelsteine gegen das aktuelle Spec-Profil und verwaltet eure Twinks an einem Ort." },
    { icon = "Interface\\Icons\\INV_Misc_EngGizmos_37", title = "Ausruestungs-Alarm",
      body = "Legt ihr ein Teil an, das noch keine Verzauberung oder einen leeren Sockel hat, meldet sich das Addon gross in der Bildschirmmitte - und noch einmal, sobald ihr einen Ruhebereich betretet. Dort steht der Verzauberer, dort koennt ihr es erledigen.\n\nDie Meldung bleibt stehen, bis ihr sie wegklickt. Danach ist fuenf Minuten Ruhe, dann erinnert sie wieder - aber nur, wenn ihr gerade nichts anderes macht.\n\nGemeldet wird nur, was fehlt, nie was besser ginge. Habt ihr einen Beruf, zaehlt auch dessen Vorteil mit: der Guertel des Ingenieurs, die Zusatzsockel des Schmieds, die Schlangenaugen des Juweliers. Abschalten mit |cffD4A24A/wc alarm aus|r; |cffD4A24A/wc alarm|r zeigt alle Schalter." },
    { icon = "Interface\\Icons\\Achievement_Boss_LichKing", title = "Bossguides",
      body = "Rollen-Tipps fuer jeden Boss, inklusive Positionierungsbildern und der Best-in-Slot-Liste fuer euer Spec." },
    -- feature: Seite wird uebersprungen, wenn das Zugriffsprofil den Bereich
    -- nicht freigibt (siehe core/access.lua) - sonst bewirbt die Tour
    -- Bereiche, die der Spieler nicht oeffnen kann.
    { icon = "Interface\\Icons\\Ability_Warrior_BattleShout", title = "Raids",
      feature = "raids.view",
      body = "Meldet euch fuer den Mittwochs- oder Donnerstagsraid an und seht auf einen Blick, wer schon zugesagt hat." },
    { icon = "Interface\\Icons\\INV_Misc_GroupLooking", title = "Gruppencheck",
      body = "Verzauberungen und Sockel der ganzen Gruppe auf einen Blick - vor dem ersten Pull sofort sichtbar, wem noch etwas fehlt.\n\nGeprueft wird nur, ob etwas da ist. Ob es das Richtige ist, entscheidet die Charakterseite, und die gibt es nur fuer den eigenen Charakter." },
    { icon = "Interface\\Icons\\INV_Crate_01", title = "Materialien",
      feature = "materials.view",
      body = "Behaltet den Ueberblick ueber die Gildenbank-Materialien nach Kategorie - per Scan oder Import vom Discord-Bot." },
    { icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", title = "Kalender",
      feature = "calendar.view",
      body = "Alle Termine der Gilde auf einen Blick, inklusive Ingame-Einladungen." },
    { icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", title = "WeakAuras",
      body = "WeakAuras nach Kategorie sortiert per Klick importieren - keine Import-Strings mehr manuell suchen." },
    { icon = "Interface\\Icons\\INV_Misc_Spyglass_02", title = "WeintTV",
      body = "Die Tiefenanalyse eures letzten Pulls direkt im Spiel: vermeidbarer Schaden mit Gegenmassnahme, Wirkungsdauern, Aktivzeit, Laufwege, Cooldown-Nutzung und Mechanikfehler.\n\nDie Auswertung entsteht in WeintCompanion und wird ins Addon uebertragen - sie erscheint beim naechsten Login bzw. nach /reload. Das Lernzentrum dazu findet ihr unter Charakter." },
    { icon = "Interface\\Icons\\INV_Misc_Note_01", title = "Import",
      body = "Der Discord-Bot exportiert Bossnotizen, Raidlisten, Materialien und WeakAuras als Code - hier landen sie im Addon." },
    { icon = "Interface\\Icons\\Achievement_Quests_Completed_08", title = "Los geht's!",
      body = "Oeffnet das Addon jederzeit mit /wc oder /weintcodex. Bei kuenftigen Updates zeigt euch dieses Fenster kurz, was sich geaendert hat." },
}

--------------------------------------------------
-- Buttons
--------------------------------------------------

-- Nutzt die gemeinsame Schaltflaeche der neuen Sprache. Das Popup ist das
-- Erste, was nach einem Update zu sehen ist - es waere die falsche Stelle,
-- eine eigene Knopfform zu pflegen.
local function CreateButton(parent, text, width, onClick)
    return WeintCodex.CreateButton(parent, {
        text = text, width = width, kind = "primary",
        height = 32, backdrop = "surface2", onClick = onClick,
    })
end

local function ClearButtons()
    for _, b in ipairs(buttonRow) do
        b:Hide()
        b:SetParent(nil)
    end
    wipe(buttonRow)
end

local function AddButton(text, width, onClick)
    local btn = CreateButton(window, text, width, onClick)
    table.insert(buttonRow, btn)
    return btn
end

--------------------------------------------------
-- Schliessen: merkt sich die aktuelle Version, damit das Popup
-- nicht bei jedem Login erneut erscheint.
--------------------------------------------------

local function Dismiss()
    if overlay then overlay:Hide() end

    local sd = WeintCodex.SavedData
    if sd then
        sd.onboarding = sd.onboarding or {}
        sd.onboarding.lastSeenVersion = WeintCodex.Version
    end
end

--------------------------------------------------
-- Gemeinsames Fenster fuer Tour und Changelog-Popup
--------------------------------------------------

local function EnsureFrame()
    if overlay then return end

    local parent = WeintCodex.MainFrame
    if not parent then return end

    overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints(parent)
    overlay:SetFrameLevel(parent:GetFrameLevel() + 100)
    overlay:EnableMouse(true)
    SetSolidBg(overlay, 0, 0, 0, 0.75)
    overlay:Hide()

    window = CreateFrame("Frame", nil, overlay)
    window:SetSize(WINDOW_W, WINDOW_H)
    window:SetPoint("CENTER")
    SetSolidBg(window, C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
    DrawBorder(window, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
    -- Bernstein nur als Oberkante, wie an jeder Karte der neuen Sprache -
    -- ein umlaufender Akzentrahmen ist die alte Ornamentik.
    local topEdge = window:CreateTexture(nil, "ARTWORK")
    topEdge:SetHeight(1)
    topEdge:SetPoint("TOPLEFT",  window, "TOPLEFT",   8, 0)
    topEdge:SetPoint("TOPRIGHT", window, "TOPRIGHT", -8, 0)
    topEdge:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)
    WeintCodex.CutCorners(window, 14, "bgDark")

    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -10)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetAllPoints(closeBtn)
    closeX:SetFont(WeintCodex.Fonts.sansSemi, 15, "")
    closeX:SetText(WeintCodex.ColorText("textMuted", "\195\151"))
    closeBtn:SetScript("OnClick", Dismiss)

    iconStr = window:CreateFontString(nil, "OVERLAY")
    iconStr:SetPoint("TOP", window, "TOP", 0, -22)
    iconStr:SetFont(WeintCodex.Fonts.sansSemi, 30, "")

    titleStr = window:CreateFontString(nil, "OVERLAY")
    titleStr:SetPoint("TOP", iconStr, "BOTTOM", 0, -10)
    titleStr:SetFont(WeintCodex.Fonts.sansBold, 20, "")
    titleStr:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    stepStr = window:CreateFontString(nil, "OVERLAY")
    stepStr:SetPoint("TOP", titleStr, "BOTTOM", 0, -6)
    stepStr:SetFont(WeintCodex.Fonts.mono, 10, "")

    local divider = window:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)
    divider:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -112)
    divider:SetPoint("TOPRIGHT", window, "TOPRIGHT", -24, -112)
    divider:SetHeight(1)

    -- Der Text liegt in einem Bildlauffeld, nicht direkt auf dem Fenster.
    -- Die schlanke Leiste ist die Hausform (siehe CLAUDE.md), das Mausrad
    -- bringt WeintCodex.CreateScrollArea mit.
    bodyScroll, bodyInner = WeintCodex.CreateScrollArea(
        window, BODY_X, -BODY_TOP,
        WINDOW_W - 2 * BODY_X, WINDOW_H - BODY_TOP - BODY_BOTTOM, true)
    -- Zweiter Ankerpunkt: damit folgt die Hoehe des Feldes der des
    -- Fensters, das SetBody() an den Text anpasst.
    bodyScroll:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", BODY_X, BODY_BOTTOM)
    -- Ohne dieses Flag blendet ScrollFrame_OnScrollRangeChanged die Leiste
    -- bei Bildlaufweite 0 wieder ein (nur ohne Griff) und wuerde damit das
    -- Ausblenden in SetBody() rueckgaengig machen.
    bodyScroll.scrollBarHideable = true

    bodyStr = bodyInner:CreateFontString(nil, "OVERLAY")
    bodyStr:SetPoint("TOPLEFT", bodyInner, "TOPLEFT", 0, 0)
    bodyStr:SetWidth(bodyInner:GetWidth())
    bodyStr:SetJustifyH("LEFT")
    bodyStr:SetJustifyV("TOP")
    bodyStr:SetFont(WeintCodex.Fonts.sans, 13, "")
    bodyStr:SetSpacing(4)
    bodyStr:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
end

--------------------------------------------------
-- Text setzen und das Fenster darauf einstellen.
--
-- Reihenfolge ist hier tragend: erst der Text, dann seine gemessene Hoehe,
-- daraus die Fensterhoehe, und erst danach die Hoehe des Bildlaufinhalts -
-- die Sichtbarkeit der Leiste haengt von der Differenz beider ab.
--------------------------------------------------

local function SetBody(text)
    bodyStr:SetText(text or "")

    local needed  = math.ceil(bodyStr:GetStringHeight() or 0) + 8
    local height  = BODY_TOP + BODY_BOTTOM + needed
    if height < WINDOW_H     then height = WINDOW_H     end
    if height > WINDOW_H_MAX then height = WINDOW_H_MAX end
    window:SetHeight(height)

    local visible = height - BODY_TOP - BODY_BOTTOM
    bodyInner:SetHeight(needed > visible and needed or visible)

    bodyScroll:SetVerticalScroll(0)
    if bodyScroll.UpdateScrollChildRect then
        bodyScroll:UpdateScrollChildRect()
    end

    -- Eine Leiste ohne Bildlauf ist ein Bedienelement, das nichts tut.
    local bar = bodyScroll.WCScrollBar
    if bar then
        if needed > visible then bar:Show() else bar:Hide() end
    end
end

local function ShowFrame()
    local main = WeintCodex.MainFrame
    if main and not main:IsShown() then
        if WeintCodex.ResetToHome then WeintCodex.ResetToHome() end
        main:Show()
    end
    overlay:Show()
end

--------------------------------------------------
-- Tour (Erststart)
--------------------------------------------------

-- Tatsaechlich gezeigte Seiten. Die Konstante TOUR_STEPS bleibt unangetastet,
-- damit ein spaeter eintreffendes Zugriffsprofil die uebersprungenen Seiten
-- beim naechsten Aufruf wieder einblenden kann.
local visibleSteps = {}

local function BuildVisibleSteps()
    wipe(visibleSteps)

    for _, step in ipairs(TOUR_STEPS) do
        local allowed = true
        if step.feature and WeintCodex.Access and WeintCodex.Access.Can then
            allowed = WeintCodex.Access.Can(step.feature)
        end
        if allowed then
            visibleSteps[#visibleSteps + 1] = step
        end
    end
end

local function RenderTourStep()
    local step = visibleSteps[currentStep]
    if not step then return end

    iconStr:SetText(WeintCodex.Icon(step.icon, 30))
    titleStr:SetText(step.title)
    stepStr:SetText(WeintCodex.ColorText("textDim", "Schritt " .. currentStep .. " von " .. #visibleSteps))
    SetBody(step.body)

    ClearButtons()

    local isLast  = currentStep == #visibleSteps
    local nextBtn = AddButton(isLast and "Los geht's!" or "Weiter", 140, function()
        if currentStep < #visibleSteps then
            currentStep = currentStep + 1
            RenderTourStep()
        else
            Dismiss()
        end
    end)
    nextBtn:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -20, 20)

    if currentStep > 1 then
        local backBtn = AddButton("Zurück", 100, function()
            currentStep = currentStep - 1
            RenderTourStep()
        end)
        backBtn:SetPoint("BOTTOMRIGHT", nextBtn, "BOTTOMLEFT", -10, 0)
    end
end

function WeintCodex.Onboarding.ShowTour()
    EnsureFrame()
    if not overlay then return end

    BuildVisibleSteps()
    if #visibleSteps == 0 then return end

    currentStep = 1
    RenderTourStep()
    ShowFrame()
end

--------------------------------------------------
-- Update-Changelog-Popup
--------------------------------------------------

function WeintCodex.Onboarding.ShowChangelog(entries)
    if not entries or #entries == 0 then return end
    EnsureFrame()
    if not overlay then return end

    iconStr:SetText(WeintCodex.Icon("Interface\\Icons\\INV_Misc_Note_02", 30))
    titleStr:SetText("Was gibt's Neues?")

    if #entries == 1 then
        stepStr:SetText(WeintCodex.ColorText("textDim", "Version " .. entries[1].version .. " · " .. (entries[1].date or "")))
    else
        stepStr:SetText(WeintCodex.ColorText("textDim", #entries .. " Updates seit eurem letzten Login"))
    end

    local lines = {}
    for _, entry in ipairs(entries) do
        if #entries > 1 then
            table.insert(lines, WeintCodex.ColorText("textBright",
                "Version " .. entry.version .. (entry.date and (" (" .. entry.date .. ")") or "")))
        end
        for _, note in ipairs(entry.notes) do
            table.insert(lines, "• " .. note)
        end
        table.insert(lines, "")
    end
    SetBody(table.concat(lines, "\n"))

    ClearButtons()
    local okBtn = AddButton("Verstanden", 160, Dismiss)
    okBtn:SetPoint("BOTTOM", window, "BOTTOM", 0, 20)

    ShowFrame()
end

--------------------------------------------------
-- Sammelt alle Changelog-Eintraege, die neuer sind als die zuletzt
-- gesehene Version (WeintCodex_ChangelogData ist neueste-zuerst
-- sortiert - siehe data/changelog.lua).
--------------------------------------------------

local function CollectChangelogSince(lastVersion)
    local data = WeintCodex_ChangelogData
    if not data or #data == 0 then return nil end

    local collected, found = {}, false
    for _, entry in ipairs(data) do
        if entry.version == lastVersion then
            found = true
            break
        end
        table.insert(collected, entry)
    end

    -- lastVersion nicht in der Liste (z.B. mehrere uebersprungene
    -- Releases oder gekuerzte Historie) - sicherheitshalber alles zeigen.
    if not found then
        collected = data
    end

    if #collected == 0 then return nil end
    return collected
end

--------------------------------------------------
-- Wird einmal pro Login aus core/main.lua (PLAYER_LOGIN) aufgerufen.
--------------------------------------------------

function WeintCodex.Onboarding.Check()
    local sd = WeintCodex.SavedData
    if not sd then return end

    sd.onboarding = sd.onboarding or {}
    local last = sd.onboarding.lastSeenVersion

    if not last then
        WeintCodex.Onboarding.ShowTour()
        return
    end

    if last == WeintCodex.Version then
        return
    end

    local entries = CollectChangelogSince(last)
    if entries then
        WeintCodex.Onboarding.ShowChangelog(entries)
    else
        -- Version hat sich geaendert, aber keine passenden Changelog-
        -- Eintraege vorhanden - trotzdem als gesehen markieren.
        sd.onboarding.lastSeenVersion = WeintCodex.Version
    end
end
