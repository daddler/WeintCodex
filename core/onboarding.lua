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

local WINDOW_W, WINDOW_H = 520, 380

local overlay, window
local iconStr, titleStr, stepStr, bodyStr
local buttonRow = {}
local currentStep = 1

local TOUR_STEPS = {
    { icon = "Interface\\Icons\\INV_Misc_Book_09", title = "Willkommen bei WeintCodex",
      body = "WeintCodex ist euer Raid Guide & Intelligence System fuer die Gilde: Bossguides, Raidplanung, Charakterpflege, Materialtracking und WeakAuras - alles an einem Ort.\n\nEin kurzer Rundgang durch die wichtigsten Bereiche:" },
    { icon = "Interface\\Icons\\Achievement_Character_Human_Male", title = "Charakter",
      body = "Prueft eure Verzauberungen und Sockelsteine gegen das aktuelle Spec-Profil und verwaltet eure Twinks an einem Ort." },
    { icon = "Interface\\Icons\\Achievement_Boss_LichKing", title = "Bossguides",
      body = "Rollen-Tipps fuer jeden Boss, inklusive Positionierungsbildern und der Best-in-Slot-Liste fuer euer Spec." },
    { icon = "Interface\\Icons\\Ability_Warrior_BattleShout", title = "Raids",
      body = "Meldet euch fuer den Mittwochs- oder Donnerstagsraid an und seht auf einen Blick, wer schon zugesagt hat." },
    { icon = "Interface\\Icons\\INV_Crate_01", title = "Materialien",
      body = "Behaltet den Ueberblick ueber die Gildenbank-Materialien nach Kategorie - per Scan oder Import vom Discord-Bot." },
    { icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", title = "Kalender",
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

local function CreateButton(parent, text, width, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 28)

    SetSolidBg(btn, C.purple[1], C.purple[2], C.purple[3], 0.85)
    DrawBorder(btn, C.purple[1], C.purple[2], C.purple[3], 1, 1)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetAllPoints(btn)
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    lbl:SetText(text)
    lbl:SetTextColor(1, 1, 1)

    btn:SetScript("OnEnter", function(self)
        SetSolidBg(self, C.purple[1]*1.15, C.purple[2]*1.15, C.purple[3]*1.15, 0.95)
    end)
    btn:SetScript("OnLeave", function(self)
        SetSolidBg(self, C.purple[1], C.purple[2], C.purple[3], 0.85)
    end)
    btn:SetScript("OnClick", onClick)

    return btn
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
    SetSolidBg(window, 0.10, 0.10, 0.13, 0.98)
    DrawBorder(window, C.purple[1], C.purple[2], C.purple[3], 1, 2)

    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -10)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetAllPoints(closeBtn)
    closeX:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    closeX:SetText("|cffff5555×|r")
    closeBtn:SetScript("OnClick", Dismiss)

    iconStr = window:CreateFontString(nil, "OVERLAY")
    iconStr:SetPoint("TOP", window, "TOP", 0, -22)
    iconStr:SetFont("Fonts\\FRIZQT__.TTF", 30, "")

    titleStr = window:CreateFontString(nil, "OVERLAY")
    titleStr:SetPoint("TOP", iconStr, "BOTTOM", 0, -10)
    titleStr:SetFont("Fonts\\FRIZQT__.TTF", 17, "OUTLINE")
    titleStr:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    stepStr = window:CreateFontString(nil, "OVERLAY")
    stepStr:SetPoint("TOP", titleStr, "BOTTOM", 0, -6)
    stepStr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    local divider = window:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.5)
    divider:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -112)
    divider:SetPoint("TOPRIGHT", window, "TOPRIGHT", -24, -112)
    divider:SetHeight(1)

    bodyStr = window:CreateFontString(nil, "OVERLAY")
    bodyStr:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 4, -18)
    bodyStr:SetPoint("TOPRIGHT", divider, "BOTTOMRIGHT", -4, -18)
    bodyStr:SetJustifyH("LEFT")
    bodyStr:SetJustifyV("TOP")
    bodyStr:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    bodyStr:SetSpacing(4)
    bodyStr:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
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

local function RenderTourStep()
    local step = TOUR_STEPS[currentStep]

    iconStr:SetText(WeintCodex.Icon(step.icon, 30))
    titleStr:SetText(step.title)
    stepStr:SetText(WeintCodex.ColorText("textDim", "Schritt " .. currentStep .. " von " .. #TOUR_STEPS))
    bodyStr:SetText(step.body)

    ClearButtons()

    local isLast  = currentStep == #TOUR_STEPS
    local nextBtn = AddButton(isLast and "Los geht's!" or "Weiter", 140, function()
        if currentStep < #TOUR_STEPS then
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
    bodyStr:SetText(table.concat(lines, "\n"))

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
