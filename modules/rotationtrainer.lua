--------------------------------------------------
-- WeintCodex :: Rotationshelfer
--
-- Freistehendes Fenster, das die Prioritätenliste der aktuellen Spec
-- live sortiert: oben, was jetzt fällig ist, darunter, was worauf
-- wartet. Wer eine Fähigkeit drückt, sieht sie im selben Moment nach
-- unten wandern und die nächste aufsteigen - die Liste ist damit keine
-- Tafel zum Ablesen, sondern folgt dem, was man tut.
--
-- Öffnet sich automatisch an einer bekannten Trainingspuppe oder
-- manuell per "/wc training".
--
-- Die gesamte Auswertung steckt in modules/rotation_engine.lua; hier
-- wird ausschließlich gezeichnet und auf Ereignisse reagiert. Die
-- Daten kommen aus data/rotations.lua.
--
-- Am Ende einer Sitzung geht das Ergebnis per
-- WeintCodex.Companion.SendDummyPracticeSession() an die Companion;
-- die Tage-Serie und das Abhaken im Trainingsplan passieren dort
-- (siehe core/academy_dummy_sync.py). Gemeldet wird erst ab drei
-- Minuten Kampfzeit (MIN_SESSION_SECONDS) - alles darunter ist kein
-- Training. Kurze Kampfpausen beenden die Sitzung dabei nicht, sonst
-- käme man an der Puppe kaum je auf drei Minuten am Stück
-- (RESUME_WINDOW).
--
-- Der Modulname bleibt WeintCodex.RotationTrainer, obwohl das Fenster
-- "Rotationshelfer" heißt: core/main.lua, modules/companion.lua und
-- die Companion-Seite hängen an diesem Namen.
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.RotationTrainer = {}

local C          = WeintCodex.Colors
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder
local RE         = WeintCodex.RotationEngine

--------------------------------------------------
-- Konstanten
--------------------------------------------------

-- Best-Effort-Liste bekannter MoP-Trainingspuppen. Bewusst klein und
-- erweiterbar: "/wc training" auf einem unbekannten Ziel meldet dessen
-- NPC-ID im Chat, damit die Liste bei Bedarf ergänzt werden kann.
local DUMMY_NPC_IDS = {
    [2673]  = true, -- "Trainingspuppe" (Hauptstädte, seit Classic-Vanilla)
    [67127] = true, -- "Trainingspuppe" (Schrein der Zwei Monde / Sieben Sterne, MoP)
    [31146] = true, -- "Trainingspuppe" (große Übungsziel-Variante, MoP)
}

-- Was als Training zählt. Drei Minuten am Stück ist die Untergrenze,
-- unterhalb derer nichts an die Companion geht: eine halbe Minute an
-- der Puppe sagt nichts über eine Rotation aus und würde die Tage-Serie
-- drüben (core/academy_dummy_sync.py) mit Rauschen füllen. Die
-- Trefferzahl bleibt als reine Plausibilitätsschwelle daneben stehen.
local MIN_SESSION_SECONDS = 180
local MIN_SESSION_HITS    = 5

-- Eine Kampfpause beendet die Sitzung nicht sofort. An der Puppe fällt
-- man schon durch einen Zielwechsel oder eine Ressourcenpause für ein
-- paar Sekunden aus dem Kampf; würde jedes Mal abgerechnet, wären drei
-- Minuten am Stück praktisch nie zu erreichen. Erst wenn nach dieser
-- Zeit kein Kampf zurückkommt, wird die Sitzung geschlossen - die Pause
-- selbst zählt nicht mit, gemessen wird weiterhin nur Kampfzeit.
local RESUME_WINDOW = 20

local FRAME_W    = 300
local HEADER_H   = 44
local TAB_H      = 22
local HERO_H     = 54
local ROW_H      = 30
local ROW_STEP   = 33
local EXTRA_H    = 36
local FOOTER_H   = 26
local PAD        = 8

-- Oberkante des wechselnden Inhalts: unter Kopfzeile und Reiterleiste.
local CONTENT_TOP = HEADER_H + TAB_H + 6

local TICK_COMBAT = 0.1
local TICK_IDLE   = 0.25
local FLASH_TIME  = 0.7
local CAST_DEDUPE = 0.4

-- Wie schnell eine Zeile an ihre neue Position gleitet. Der Wert ist
-- ein Anteil pro Sekunde, keine feste Geschwindigkeit - kurze Wege
-- laufen dadurch schnell, weite bleiben trotzdem lesbar.
local SLIDE_SPEED = 14

local KIND_COLOR = {
    cooldown = "gold",
    dot      = "violet",
    proc     = "blue",
    spender  = "red",
    builder  = "purple",
    execute  = "red",
    filler   = "textFaint",
    dump     = "goldDim",
    buff     = "green",
}

local STATE_COLOR = {
    ready    = "green",
    resource = "gold",
    waiting  = "textDim",
    blocked  = "textFaint",
    unknown  = "textGhost",
}

--------------------------------------------------
-- Einstellungen
--------------------------------------------------

local DEFAULT_SETTINGS = {
    auto       = true,   -- an der Puppe von selbst öffnen
    compact    = false,  -- nur die nächsten fünf Zeilen
    showExtras = true,   -- Cooldown-Leiste
    showKeys   = true,   -- Tastenkürzel
    locked     = false,  -- Fenster festsetzen
}

local function Store()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.rotationTrainer = WeintCodex.SavedData.rotationTrainer or {}
    return WeintCodex.SavedData.rotationTrainer
end

local function Settings()
    local store = Store()
    store.settings = store.settings or {}
    for key, value in pairs(DEFAULT_SETTINGS) do
        if store.settings[key] == nil then store.settings[key] = value end
    end
    return store.settings
end

-- Stummgeschaltete Regeln je Spec. Gedacht für Fähigkeiten, die dem
-- eigenen Talentaufbau fehlen: die Zeile bleibt sichtbar, zählt aber
-- weder für die Empfehlung noch für die Bewertung.
local function MutedFor(specKey)
    if not specKey then return nil end
    local store = Store()
    store.muted = store.muted or {}
    store.muted[specKey] = store.muted[specKey] or {}
    return store.muted[specKey]
end

--------------------------------------------------
-- Zustand
--------------------------------------------------

local frame, header, tabBar, hero, queue, extrasBar, footer, statsPanel, optionsPanel
local titleText, subtitleText, scoreBar, scoreFill, scoreText, metaText
local rows = {}
local extraIcons = {}

local currentSpecKey, currentSpecName
local dummyDetected, manualActive = false, false
local activePanel = "queue"

local plan
local ranksNow, ranksPrev = {}, {}
local lastCast = {}
local sessionActive = false
local inCombat = false
-- Zeitpunkt, an dem eine laufende Sitzung geschlossen wird, wenn bis
-- dahin kein Kampf zurückgekommen ist (siehe RESUME_WINDOW).
local resumeDeadline
local lastResult
-- Ob die zuletzt beendete Sitzung lang genug war, um gemeldet zu
-- werden. Nur so kann die Oberfläche den Unterschied zwischen "kurz
-- geübt" und "gewertet" überhaupt zeigen.
local lastReported = false

--------------------------------------------------
-- Kleine Zeichenhelfer
--------------------------------------------------

local function Col(name)
    return C[name] or C.textNormal
end

local function SetText(fontString, text, colorName)
    fontString:SetText(text or "")
    local col = Col(colorName or "textNormal")
    fontString:SetTextColor(col[1], col[2], col[3])
end

local function Clock(seconds)
    if WeintCodex.FormatClock then return WeintCodex.FormatClock(seconds or 0) end
    return string.format("%.0fs", seconds or 0)
end

-- Wie viel Kampfzeit einer Sitzung noch bis zur Wertung fehlt, oder
-- nil, wenn die Mindestdauer erreicht ist. Einzige Stelle, an der die
-- Oberfläche diese Frage stellt.
local function SessionRemaining(score)
    if not score then return nil end
    local missing = MIN_SESSION_SECONDS - (score.duration or 0)
    if missing <= 0 then return nil end
    return missing
end

local function NewFont(parent, font, size, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(font, size, flags or "")
    return fs
end

local function Seconds(value)
    if value >= 10 then return string.format("%.0fs", value) end
    return string.format("%.1fs", value)
end

local function AttachCooldown(parent, icon)
    local cd = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate")
    cd:SetAllPoints(icon)
    if cd.SetHideCountdownNumbers then
        pcall(cd.SetHideCountdownNumbers, cd, true)
    end
    return cd
end

-- Der GCD wird bewusst nicht als Wischer gezeichnet: sonst drehen sich
-- nach jedem Tastendruck alle Symbole gleichzeitig, und die eine
-- Fähigkeit, die wirklich auf Abklingzeit ist, geht darin unter.
local function ApplyCooldownSwipe(cd, spellId)
    local start, duration = GetSpellCooldown(spellId)
    if start and duration and duration > 1.5 then
        cd:SetCooldown(start, duration)
    else
        cd:SetCooldown(0, 0)
    end
end

local function ShowSpellTooltip(owner, spellId, rule, reason)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if GetSpellInfo(spellId) then
        GameTooltip:SetSpellByID(spellId)
    else
        GameTooltip:SetText("Zauber " .. tostring(spellId))
    end
    if rule and rule.why then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(rule.why, 0.78, 0.46, 0.23, true)
    end
    if reason then
        GameTooltip:AddLine(reason, 0.54, 0.51, 0.47, true)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Rechtsklick: Zeile stummschalten", 0.42, 0.38, 0.35, true)
    GameTooltip:Show()
end

--------------------------------------------------
-- Position merken
--------------------------------------------------

local function SavePosition()
    if not frame then return end
    local point, _, _, x, y = frame:GetPoint()
    local store = Store()
    store.pos = { point = point, x = x, y = y }
end

local function MakeDraggable(region)
    region:EnableMouse(true)
    region:RegisterForDrag("LeftButton")
    region:SetScript("OnDragStart", function()
        if Settings().locked then return end
        frame:StartMoving()
    end)
    region:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SavePosition()
    end)
end

--------------------------------------------------
-- Kopfzeile
--------------------------------------------------

local function CreateHeaderButton(parent, label, tooltip, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)

    local text = NewFont(btn, WeintCodex.Fonts.mono, 11, "")
    text:SetAllPoints(btn)
    text:SetJustifyH("CENTER")
    SetText(text, label, "textMuted")

    btn:SetScript("OnEnter", function(self)
        SetText(text, label, "textBright")
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(tooltip, 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        SetText(text, label, "textMuted")
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", onClick)

    return btn
end

local SwitchPanel

local function BuildHeader()
    header = CreateFrame("Frame", nil, frame)
    header:SetHeight(HEADER_H)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    SetSolidBg(header, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)
    MakeDraggable(header)

    titleText = NewFont(header, WeintCodex.Fonts.serif, 13, "")
    titleText:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -7)
    SetText(titleText, "Rotationshelfer", "textBright")

    subtitleText = NewFont(header, WeintCodex.Fonts.mono, 9, "")
    subtitleText:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -25)
    subtitleText:SetPoint("RIGHT", header, "RIGHT", -28, 0)
    subtitleText:SetJustifyH("LEFT")
    SetText(subtitleText, "", "textFaint")

    local close = CreateHeaderButton(header, "x", "Schließen", function()
        WeintCodex.RotationTrainer.Hide()
    end)
    close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -6, -6)
end

--------------------------------------------------
-- Reiterleiste
--
-- Bewertung und Einstellungen hingen bisher als zwei einzelne Zeichen
-- ("%" und "=") in der Kopfzeile und gingen dort neben Titel, Spec und
-- Schließen-Kreuz unter: beschriftet waren sie nur im Tooltip, und
-- welche Seite gerade offen ist, stand nirgends. Sie sind jetzt ein
-- Segmented Control unter der Kopfzeile - dasselbe Muster wie der
-- Rollen-Umschalter in modules/bossguides.lua, nur auf die Fensterbreite
-- heruntergerechnet: beschriftet, immer sichtbar, mit erkennbarem
-- Aktiv-Zustand (heller Text plus Akzentlinie).
--------------------------------------------------

local TAB_DEFS = {
    { key = "queue",   label = "LISTE",         tooltip = "Prioritätenliste" },
    { key = "stats",   label = "BEWERTUNG",     tooltip = "Note der laufenden oder letzten Sitzung" },
    { key = "options", label = "EINSTELLUNGEN", tooltip = "Fenster und Anzeige einstellen" },
}

local TAB_GAP = 2

local function CreateTab(def, index, count)
    local btn = CreateFrame("Button", nil, tabBar)
    btn:SetHeight(TAB_H)

    local width = math.floor((FRAME_W - PAD * 2 - TAB_GAP * (count - 1)) / count)
    btn:SetWidth(width)
    btn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", (index - 1) * (width + TAB_GAP), 0)
    if index == count then
        -- Der letzte Reiter schließt bündig mit der rechten Kante ab,
        -- damit die Rundung der Segmentbreite keine Lücke hinterlässt.
        btn:SetPoint("TOPRIGHT", tabBar, "TOPRIGHT", 0, 0)
    end

    btn.bg = SetSolidBg(btn, C.surface1[1], C.surface1[2], C.surface1[3], 1.0)

    btn.accent = btn:CreateTexture(nil, "OVERLAY")
    btn.accent:SetHeight(2)
    btn.accent:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    btn.accent:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    btn.accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1)
    btn.accent:Hide()

    btn.label = NewFont(btn, WeintCodex.Fonts.mono, 9, "")
    btn.label:SetAllPoints(btn)
    btn.label:SetJustifyH("CENTER")

    btn.active = false

    btn.SetActive = function(_, active)
        btn.active = active and true or false
        if btn.active then
            btn.bg:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1)
            btn.accent:Show()
            SetText(btn.label, def.label, "textBright")
        else
            btn.bg:SetColorTexture(C.surface1[1], C.surface1[2], C.surface1[3], 1)
            btn.accent:Hide()
            SetText(btn.label, def.label, "textDim")
        end
    end

    btn:SetScript("OnEnter", function(self)
        if not btn.active then
            btn.bg:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1)
            SetText(btn.label, def.label, "textMuted")
        end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(def.tooltip, 1, 1, 1)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        if not btn.active then
            btn.bg:SetColorTexture(C.surface1[1], C.surface1[2], C.surface1[3], 1)
            SetText(btn.label, def.label, "textDim")
        end
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function()
        SwitchPanel(def.key)
    end)

    btn:SetActive(false)
    return btn
end

local function BuildTabBar()
    tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetHeight(TAB_H)
    tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -HEADER_H)
    tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -HEADER_H)

    tabBar.buttons = {}
    for index, def in ipairs(TAB_DEFS) do
        tabBar.buttons[def.key] = CreateTab(def, index, #TAB_DEFS)
    end
end

--------------------------------------------------
-- Jetzt-Karte
--
-- Die oberste Zeile noch einmal groß: beim Üben schaut man auf ein
-- Symbol, nicht auf eine Tabelle. Rechts stehen die nächsten drei als
-- Vorschau, damit man weiß, worauf man zusteuert.
--------------------------------------------------

local function BuildHero()
    hero = CreateFrame("Frame", nil, frame)
    hero:SetHeight(HERO_H)
    hero:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -CONTENT_TOP)
    hero:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -CONTENT_TOP)
    SetSolidBg(hero, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)

    hero.accent = hero:CreateTexture(nil, "ARTWORK")
    hero.accent:SetPoint("TOPLEFT", hero, "TOPLEFT", 0, 0)
    hero.accent:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 0, 0)
    hero.accent:SetWidth(3)
    hero.accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1)

    hero.icon = hero:CreateTexture(nil, "ARTWORK")
    hero.icon:SetSize(38, 38)
    hero.icon:SetPoint("LEFT", hero, "LEFT", 10, 0)
    hero.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    hero.cd = AttachCooldown(hero, hero.icon)

    hero.name = NewFont(hero, WeintCodex.Fonts.serif, 14, "")
    hero.name:SetPoint("TOPLEFT", hero.icon, "TOPRIGHT", 9, -2)
    hero.name:SetPoint("RIGHT", hero, "RIGHT", -78, 0)
    hero.name:SetJustifyH("LEFT")

    hero.reason = NewFont(hero, WeintCodex.Fonts.mono, 9, "")
    hero.reason:SetPoint("TOPLEFT", hero.icon, "TOPRIGHT", 9, -22)
    hero.reason:SetPoint("RIGHT", hero, "RIGHT", -78, 0)
    hero.reason:SetJustifyH("LEFT")

    hero.key = NewFont(hero, WeintCodex.Fonts.monoMedium, 10, "")
    hero.key:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -8, -8)
    hero.key:SetJustifyH("RIGHT")

    hero.preview = {}
    for i = 1, 3 do
        local tex = hero:CreateTexture(nil, "ARTWORK")
        tex:SetSize(17, 17)
        tex:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", -8 - (3 - i) * 20, 7)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tex:SetAlpha(0.55)
        hero.preview[i] = tex
    end
end

--------------------------------------------------
-- Zeilen der Prioritätenliste
--
-- Es gibt genau eine Zeile pro Regel, und die behält ihre Identität.
-- Umsortiert wird nur die Position - deshalb kann die Zeile dorthin
-- gleiten, statt an anderer Stelle neu aufzutauchen.
--------------------------------------------------

local function ToggleMute(spellId)
    local muted = MutedFor(currentSpecKey)
    if not muted then return end
    muted[spellId] = (not muted[spellId]) or nil
end

-- Verankert die Zeile an ihrer aktuellen Höhe. Wird beim Anlegen, beim
-- Einblenden und in jedem Bild des Gleitens gerufen - ohne den ersten
-- Aufruf hätte eine Zeile, die von Anfang an ganz oben steht, nie einen
-- Ankerpunkt bekommen.
local function PlaceRow(row)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", queue, "TOPLEFT", 0, row.y)
    row:SetPoint("TOPRIGHT", queue, "TOPRIGHT", 0, row.y)
end

local function CreateRow(ruleIndex)
    local row = CreateFrame("Button", nil, queue)
    row:SetHeight(ROW_H)
    row:RegisterForClicks("AnyUp")

    row.bg = SetSolidBg(row, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)

    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.accent:SetWidth(2)

    row.rank = NewFont(row, WeintCodex.Fonts.monoMedium, 10, "")
    row.rank:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.rank:SetWidth(10)
    row.rank:SetJustifyH("CENTER")

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", row, "LEFT", 20, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.cd = AttachCooldown(row, row.icon)

    row.name = NewFont(row, WeintCodex.Fonts.sans, 11, "")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 7, -1)
    row.name:SetPoint("RIGHT", row, "RIGHT", -52, 0)
    row.name:SetJustifyH("LEFT")

    row.reason = NewFont(row, WeintCodex.Fonts.mono, 8, "")
    row.reason:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 7, -15)
    row.reason:SetPoint("RIGHT", row, "RIGHT", -52, 0)
    row.reason:SetJustifyH("LEFT")

    row.status = NewFont(row, WeintCodex.Fonts.mono, 9, "")
    row.status:SetPoint("RIGHT", row, "RIGHT", -6, 6)
    row.status:SetJustifyH("RIGHT")

    row.key = NewFont(row, WeintCodex.Fonts.mono, 8, "")
    row.key:SetPoint("RIGHT", row, "RIGHT", -6, -7)
    row.key:SetJustifyH("RIGHT")

    row.ruleIndex = ruleIndex
    row.y, row.targetY = 0, 0
    row.flashUntil = 0
    PlaceRow(row)

    row:SetScript("OnEnter", function(self)
        if self.spell then ShowSpellTooltip(self, self.spell, self.rule, self.reasonText) end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" and self.spell then
            ToggleMute(self.spell)
            WeintCodex.RotationTrainer.Refresh()
        end
    end)

    return row
end

local function EnsureRows(count)
    for i = #rows + 1, count do
        rows[i] = CreateRow(i)
    end
    for i = count + 1, #rows do
        rows[i]:Hide()
    end
end

--------------------------------------------------
-- Cooldown-Leiste
--
-- Extras werden nie bewertet (siehe Kopf von data/rotations.lua): an
-- der Puppe einen Zweiminuten-Cooldown liegen zu lassen ist keine
-- Fehlleistung. Sie stehen hier, weil man sie trotzdem sehen will.
--------------------------------------------------

local function BuildExtrasBar()
    extrasBar = CreateFrame("Frame", nil, frame)
    extrasBar:SetHeight(EXTRA_H)

    extrasBar.label = NewFont(extrasBar, WeintCodex.Fonts.mono, 8, "")
    extrasBar.label:SetPoint("TOPLEFT", extrasBar, "TOPLEFT", 2, 0)
    SetText(extrasBar.label, "COOLDOWNS", "textGhost")
end

local function CreateExtraIcon(index)
    local button = CreateFrame("Button", nil, extrasBar)
    button:SetSize(24, 24)
    button:SetPoint("TOPLEFT", extrasBar, "TOPLEFT", (index - 1) * 28, -11)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.cd = AttachCooldown(button, button.icon)

    button.glow = button:CreateTexture(nil, "OVERLAY")
    button.glow:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    button.glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    button.glow:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.0)

    button:SetScript("OnEnter", function(self)
        if self.spell then ShowSpellTooltip(self, self.spell, self.rule, self.reasonText) end
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return button
end

--------------------------------------------------
-- Fußzeile mit dem laufenden Wert
--------------------------------------------------

local function BuildFooter()
    footer = CreateFrame("Frame", nil, frame)
    footer:SetHeight(FOOTER_H)

    scoreBar = CreateFrame("Frame", nil, footer)
    scoreBar:SetHeight(4)
    scoreBar:SetPoint("TOPLEFT", footer, "TOPLEFT", 2, -4)
    scoreBar:SetPoint("TOPRIGHT", footer, "TOPRIGHT", -2, -4)
    SetSolidBg(scoreBar, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)

    scoreFill = scoreBar:CreateTexture(nil, "ARTWORK")
    scoreFill:SetPoint("TOPLEFT", scoreBar, "TOPLEFT", 0, 0)
    scoreFill:SetPoint("BOTTOMLEFT", scoreBar, "BOTTOMLEFT", 0, 0)
    scoreFill:SetWidth(1)
    scoreFill:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1)

    scoreText = NewFont(footer, WeintCodex.Fonts.monoMedium, 10, "")
    scoreText:SetPoint("TOPLEFT", footer, "TOPLEFT", 2, -10)
    SetText(scoreText, "Kein Kampf", "textFaint")

    metaText = NewFont(footer, WeintCodex.Fonts.mono, 9, "")
    metaText:SetPoint("TOPRIGHT", footer, "TOPRIGHT", -2, -10)
    metaText:SetJustifyH("RIGHT")
    SetText(metaText, "", "textFaint")
end

--------------------------------------------------
-- Bewertungsseite
--------------------------------------------------

local function CreateBar(parent, offsetY, label)
    local bar = {}

    bar.label = NewFont(parent, WeintCodex.Fonts.mono, 9, "")
    bar.label:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, offsetY)
    SetText(bar.label, label, "textDim")

    bar.value = NewFont(parent, WeintCodex.Fonts.monoMedium, 9, "")
    bar.value:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, offsetY)
    bar.value:SetJustifyH("RIGHT")

    local track = CreateFrame("Frame", nil, parent)
    track:SetHeight(3)
    track:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, offsetY - 13)
    track:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, offsetY - 13)
    SetSolidBg(track, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)

    bar.fill = track:CreateTexture(nil, "ARTWORK")
    bar.fill:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
    bar.fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 0, 0)
    bar.fill:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1)
    bar.track = track

    bar.Set = function(_, percent, colorName)
        percent = percent or 0
        local width = math.max(1, (track:GetWidth() or 1) * math.min(1, percent / 100))
        bar.fill:SetWidth(width)
        local col = Col(colorName or "purple")
        bar.fill:SetColorTexture(col[1], col[2], col[3], 1)
        SetText(bar.value, string.format("%.0f %%", percent), colorName or "textNormal")
    end

    return bar
end

local function BuildStatsPanel()
    statsPanel = CreateFrame("Frame", nil, frame)
    statsPanel:Hide()

    statsPanel.grade = NewFont(statsPanel, WeintCodex.Fonts.serif, 30, "")
    statsPanel.grade:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 4, -2)

    statsPanel.gradeLabel = NewFont(statsPanel, WeintCodex.Fonts.serif, 12, "")
    statsPanel.gradeLabel:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 42, -6)

    statsPanel.gradeHint = NewFont(statsPanel, WeintCodex.Fonts.mono, 8, "")
    statsPanel.gradeHint:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 42, -24)
    statsPanel.gradeHint:SetPoint("RIGHT", statsPanel, "RIGHT", -2, 0)
    statsPanel.gradeHint:SetJustifyH("LEFT")

    statsPanel.priority = CreateBar(statsPanel, -48, "Priorität (60 %)")
    statsPanel.busy     = CreateBar(statsPanel, -72, "Auslastung (20 %)")
    statsPanel.uptime   = CreateBar(statsPanel, -96, "Laufzeit (20 %)")

    statsPanel.listTitle = NewFont(statsPanel, WeintCodex.Fonts.mono, 8, "")
    statsPanel.listTitle:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 2, -118)
    SetText(statsPanel.listTitle, "HÄUFIGSTE FEHLGRIFFE", "textGhost")

    statsPanel.lines = {}
    for i = 1, 6 do
        local line = NewFont(statsPanel, WeintCodex.Fonts.sans, 10, "")
        line:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 2, -132 - (i - 1) * 15)
        line:SetPoint("RIGHT", statsPanel, "RIGHT", -2, 0)
        line:SetJustifyH("LEFT")
        statsPanel.lines[i] = line
    end
end

local function FillStatsPanel()
    local score = RE.Session.Score() or lastResult
    local live = RE.Session.IsActive()

    if not score or (score.casts or 0) == 0 then
        SetText(statsPanel.grade, "–", "textGhost")
        SetText(statsPanel.gradeLabel, "Noch keine Sitzung", "textDim")
        SetText(statsPanel.gradeHint,
            "Greife eine Trainingspuppe an - die Wertung läuft mit.\n"
            .. "Ab 3 Minuten am Stück geht die Sitzung an die Companion.",
            "textFaint")
        statsPanel.priority:Set(0, "textFaint")
        statsPanel.busy:Set(0, "textFaint")
        statsPanel.uptime:Set(0, "textFaint")
        for _, line in ipairs(statsPanel.lines) do SetText(line, "") end
        return
    end

    local grade, label = RE.GradeFor(score.total or 0)
    if score.grade then grade, label = score.grade, score.gradeLabel end

    local gradeColor = "green"
    if (score.total or 0) < 62 then gradeColor = "red"
    elseif (score.total or 0) < 84 then gradeColor = "gold" end

    SetText(statsPanel.grade, grade, gradeColor)
    SetText(statsPanel.gradeLabel, string.format("%s · %.0f %%", label, score.total or 0), "textBright")

    -- Der Hinweis unter der Note trägt den Stand zur Mindestdauer: was
    -- noch fehlt, solange sie läuft, und hinterher, ob die Sitzung
    -- gemeldet wurde. Ohne das wäre "gewertet oder nicht" nirgends
    -- ablesbar (siehe MIN_SESSION_SECONDS).
    local remaining = SessionRemaining(score)
    local hint, hintColor

    if live and resumeDeadline then
        hint = string.format("Kampfpause · Sitzung läuft weiter (noch %ds)",
            math.max(0, math.ceil(resumeDeadline - GetTime())))
        hintColor = "gold"
    elseif live and remaining then
        hint = string.format("Läuft: %d Aktionen · noch %s bis zur Wertung",
            score.casts, Clock(remaining))
        hintColor = "textFaint"
    elseif live then
        hint = string.format("Läuft: %d Aktionen, %d auf Rang 1 · wird gemeldet",
            score.casts, score.perfect)
        hintColor = "green"
    elseif lastReported then
        hint = string.format("Letzte Sitzung: %d Aktionen, %s · gemeldet",
            score.casts, Clock(score.duration))
        hintColor = "textFaint"
    elseif (score.duration or 0) < MIN_SESSION_SECONDS then
        hint = string.format("Letzte Sitzung: %s · unter 3 Minuten, nicht gewertet",
            Clock(score.duration))
        hintColor = "gold"
    else
        -- Lang genug, aber zu wenig gedrückt: der andere Grund, aus dem
        -- eine Sitzung nicht gemeldet wird (MIN_SESSION_HITS).
        hint = string.format("Letzte Sitzung: %d Aktionen · zu wenig, nicht gewertet",
            score.casts)
        hintColor = "gold"
    end

    SetText(statsPanel.gradeHint, hint, hintColor)

    statsPanel.priority:Set(score.priority or 0, "purple")
    statsPanel.busy:Set(score.busy or 0, "blue")
    statsPanel.uptime:Set(score.uptime or 0, score.uptime and "violet" or "textFaint")

    local index = 0
    local function AddLine(text, colorName)
        index = index + 1
        if statsPanel.lines[index] then SetText(statsPanel.lines[index], text, colorName) end
    end

    local mistakes = score.mistakes
    if not mistakes and lastResult and not live then mistakes = lastResult.mistakes end

    if mistakes and #mistakes > 0 then
        for i = 1, math.min(3, #mistakes) do
            local entry = mistakes[i]
            AddLine(string.format("%d×  %s  statt  %s", entry.count,
                RE.SpellName(entry.cast) or "?", RE.SpellName(entry.expected) or "?"), "textMuted")
        end
    elseif not live then
        AddLine("Keine Fehlgriffe - saubere Reihenfolge.", "green")
    else
        AddLine("Bewertung läuft …", "textFaint")
    end

    local tracked = score.tracked or (lastResult and not live and lastResult.tracked)
    if tracked and #tracked > 0 then
        AddLine("")
        AddLine("SCHWÄCHSTE LAUFZEIT", "textGhost")
        for i = 1, math.min(2, #tracked) do
            local entry = tracked[i]
            AddLine(string.format("%s  %.0f %%", entry.name, entry.uptime),
                entry.uptime >= 90 and "green" or (entry.uptime >= 70 and "gold" or "red"))
        end
    end
end

--------------------------------------------------
-- Einstellungsseite
--------------------------------------------------

local function CreateToggle(parent, offsetY, key, label, description)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, offsetY)
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, offsetY)

    local box = button:CreateTexture(nil, "ARTWORK")
    box:SetSize(10, 10)
    box:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -2)

    local mark = button:CreateTexture(nil, "OVERLAY")
    mark:SetSize(6, 6)
    mark:SetPoint("CENTER", box, "CENTER", 0, 0)

    local title = NewFont(button, WeintCodex.Fonts.sans, 11, "")
    title:SetPoint("TOPLEFT", button, "TOPLEFT", 17, 0)
    title:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    title:SetJustifyH("LEFT")

    local hint = NewFont(button, WeintCodex.Fonts.mono, 8, "")
    hint:SetPoint("TOPLEFT", button, "TOPLEFT", 17, -13)
    hint:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    hint:SetJustifyH("LEFT")
    SetText(hint, description, "textFaint")

    button.Sync = function()
        local on = Settings()[key] and true or false
        box:SetColorTexture(C.bgCard[1], C.bgCard[2], C.bgCard[3], 1)
        if on then
            mark:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1)
        else
            mark:SetColorTexture(C.bgMid[1], C.bgMid[2], C.bgMid[3], 1)
        end
        SetText(title, label, on and "textBright" or "textDim")
    end

    button:SetScript("OnClick", function()
        Settings()[key] = not Settings()[key]
        button.Sync()
        WeintCodex.RotationTrainer.Refresh()
    end)

    button.Sync()
    return button
end

local function BuildOptionsPanel()
    optionsPanel = CreateFrame("Frame", nil, frame)
    optionsPanel:Hide()
    optionsPanel.toggles = {}

    local definitions = {
        { "auto",       "An der Trainingspuppe öffnen",
                        "Fenster erscheint von selbst, sobald du eine Puppe anvisierst" },
        { "compact",    "Nur die nächsten fünf Zeilen",
                        "Kürzere Liste für kleine Bildschirme" },
        { "showExtras", "Cooldown-Leiste anzeigen",
                        "Große Cooldowns unter der Liste (nie bewertet)" },
        { "showKeys",   "Tastenkürzel anzeigen",
                        "Belegung aus deinen Aktionsleisten" },
        { "locked",     "Fenster festsetzen",
                        "Verhindert versehentliches Verschieben" },
    }

    for i, def in ipairs(definitions) do
        optionsPanel.toggles[i] = CreateToggle(optionsPanel, -(i - 1) * 30, def[1], def[2], def[3])
    end

    local reset = CreateFrame("Button", nil, optionsPanel)
    reset:SetHeight(20)
    reset:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 2, -158)
    reset:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -2, -158)
    SetSolidBg(reset, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)

    local resetLabel = NewFont(reset, WeintCodex.Fonts.mono, 9, "")
    resetLabel:SetAllPoints(reset)
    resetLabel:SetJustifyH("CENTER")
    SetText(resetLabel, "Stummschaltungen aufheben", "textMuted")

    reset:SetScript("OnEnter", function() SetText(resetLabel, "Stummschaltungen aufheben", "textBright") end)
    reset:SetScript("OnLeave", function() SetText(resetLabel, "Stummschaltungen aufheben", "textMuted") end)
    reset:SetScript("OnClick", function()
        local muted = MutedFor(currentSpecKey)
        if muted then for key in pairs(muted) do muted[key] = nil end end
        WeintCodex.RotationTrainer.Refresh()
    end)

    local hint = NewFont(optionsPanel, WeintCodex.Fonts.mono, 8, "")
    hint:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 2, -184)
    hint:SetPoint("RIGHT", optionsPanel, "RIGHT", -2, 0)
    hint:SetJustifyH("LEFT")
    SetText(hint, "Rechtsklick auf eine Zeile schaltet sie stumm.\n"
        .. "/wc training check meldet falsche Zauber-IDs.", "textFaint")
end

--------------------------------------------------
-- Aufbau
--------------------------------------------------

local function CreateFrameOnce()
    if frame then return end

    frame = CreateFrame("Frame", "WeintCodexRotationTrainer", UIParent)
    frame:SetSize(FRAME_W, 400)
    frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    MakeDraggable(frame)

    SetSolidBg(frame, C.bgDark[1], C.bgDark[2], C.bgDark[3], 0.96)
    DrawBorder(frame, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)

    BuildHeader()
    BuildTabBar()
    BuildHero()

    queue = CreateFrame("Frame", nil, frame)
    queue:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(CONTENT_TOP + HERO_H + 6))
    queue:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -(CONTENT_TOP + HERO_H + 6))
    queue:SetHeight(10)

    BuildExtrasBar()
    BuildFooter()
    BuildStatsPanel()
    BuildOptionsPanel()

    local savedPos = Store().pos
    if savedPos and savedPos.point then
        frame:ClearAllPoints()
        frame:SetPoint(savedPos.point, UIParent, savedPos.point, savedPos.x, savedPos.y)
    end

    frame:Hide()
end

--------------------------------------------------
-- Umschalten zwischen Liste, Bewertung und Einstellungen
--------------------------------------------------

SwitchPanel = function(target)
    activePanel = target
    if not frame then return end

    queue:SetShown(target == "queue")
    hero:SetShown(target == "queue")
    extrasBar:SetShown(target == "queue" and Settings().showExtras)
    statsPanel:SetShown(target == "stats")
    optionsPanel:SetShown(target == "options")

    for key, button in pairs(tabBar.buttons) do
        button:SetActive(key == target)
    end

    if target == "options" then
        for _, toggle in ipairs(optionsPanel.toggles) do toggle.Sync() end
    end

    WeintCodex.RotationTrainer.Refresh()
end

--------------------------------------------------
-- Zeichnen
--------------------------------------------------

local function LayoutFrame(visibleRows)
    local y = CONTENT_TOP

    if activePanel == "queue" then
        y = y + HERO_H + 6
        queue:ClearAllPoints()
        queue:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -y)
        queue:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
        queue:SetHeight(math.max(1, visibleRows * ROW_STEP))
        y = y + visibleRows * ROW_STEP + 2

        if extrasBar:IsShown() then
            extrasBar:ClearAllPoints()
            extrasBar:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -y)
            extrasBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)
            y = y + EXTRA_H
        end
    else
        local panel = (activePanel == "stats") and statsPanel or optionsPanel
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 2, -y)
        panel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD - 2, -y)
        local height = (activePanel == "stats") and 230 or 215
        panel:SetHeight(height)
        y = y + height + 4
    end

    footer:ClearAllPoints()
    footer:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -y)
    footer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -y)

    frame:SetHeight(y + FOOTER_H + PAD)
end

local function UpdateHero()
    local top = plan and plan.ranked[1]

    if not top then
        hero.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        hero.cd:SetCooldown(0, 0)
        hero.accent:SetColorTexture(C.textGhost[1], C.textGhost[2], C.textGhost[3], 1)

        local waitingReason
        for _, entry in ipairs(plan and plan.entries or {}) do
            if entry.state ~= "unknown" then waitingReason = entry.reason; break end
        end

        SetText(hero.name, "Warten", "textDim")
        SetText(hero.reason, waitingReason or "Nichts ist gerade wirkbar", "textFaint")
        SetText(hero.key, "")
        for _, tex in ipairs(hero.preview) do tex:SetTexture(nil) end
        return
    end

    local _, _, icon = GetSpellInfo(top.spell)
    hero.icon:SetTexture(icon)
    ApplyCooldownSwipe(hero.cd, top.spell)

    local accent = Col(KIND_COLOR[top.rule.kind] or "purple")
    hero.accent:SetColorTexture(accent[1], accent[2], accent[3], 1)

    SetText(hero.name, RE.SpellName(top.spell) or ("Zauber " .. top.spell), "textBright")
    SetText(hero.reason, top.reason or (top.rule.why or "jetzt"), "textMuted")

    local key = Settings().showKeys and RE.Keybind(top.spell)
    SetText(hero.key, key and ("[" .. key .. "]") or "", "purple")

    for i, tex in ipairs(hero.preview) do
        local following = plan.ranked[i + 1]
        if following then
            local _, _, nextIcon = GetSpellInfo(following.spell)
            tex:SetTexture(nextIcon)
        else
            tex:SetTexture(nil)
        end
    end
end

local function UpdateRow(row, entry, position, now, showKeys)
    row.spell = entry.spell
    row.rule = entry.rule
    row.reasonText = entry.reason

    local _, _, icon = GetSpellInfo(entry.spell)
    row.icon:SetTexture(icon)
    ApplyCooldownSwipe(row.cd, entry.spell)

    local muted = entry.muted
    local name = RE.SpellName(entry.spell) or ("Zauber " .. entry.spell)

    if entry.state == "ready" then
        local rank = 0
        for i, ranked in ipairs(plan.ranked) do
            if ranked.spell == entry.spell then rank = i; break end
        end
        SetText(row.rank, tostring(rank > 0 and rank or "·"), rank == 1 and "gold" or "textDim")
    else
        SetText(row.rank, "·", "textGhost")
    end

    SetText(row.name, name, muted and "textGhost" or
        (entry.state == "ready" and "textBright" or "textDim"))

    local accent = Col(entry.state == "ready" and (KIND_COLOR[entry.rule.kind] or "purple") or "bgMid")
    row.accent:SetColorTexture(accent[1], accent[2], accent[3], entry.state == "ready" and 1 or 0.6)

    -- Hintergrund: die fällige Zeile hebt sich ab, alles andere bleibt
    -- ruhig. Nach einem Tastendruck blitzt die Zeile kurz auf.
    if now < row.flashUntil then
        local col = Col(row.flashColor or "green")
        row.bg:SetColorTexture(col[1], col[2], col[3], 0.35)
    elseif entry.state == "ready" and position == 1 then
        row.bg:SetColorTexture(C.purpleDeep[1], C.purpleDeep[2], C.purpleDeep[3], 0.75)
    else
        row.bg:SetColorTexture(C.bgCard[1], C.bgCard[2], C.bgCard[3], entry.state == "ready" and 1.0 or 0.7)
    end

    if entry.state == "waiting" and entry.remaining > 0 then
        SetText(row.status, Seconds(entry.remaining), "textDim")
        SetText(row.reason, entry.reason or "", "textGhost")
    elseif entry.state == "ready" then
        SetText(row.status, entry.charges and ("×" .. entry.charges) or "bereit", "green")
        SetText(row.reason, entry.reason or (entry.rule.why or ""), "textFaint")
    elseif entry.state == "unknown" then
        SetText(row.status, muted and "stumm" or "—", "textGhost")
        SetText(row.reason, entry.reason or "", "textGhost")
    else
        SetText(row.status, entry.state == "resource" and "Ressource" or "",
            entry.state == "resource" and "gold" or "textFaint")
        SetText(row.reason, entry.reason or "", "textFaint")
    end

    local key = showKeys and RE.Keybind(entry.spell)
    SetText(row.key, key or "", "textGhost")

    row:SetAlpha(muted and 0.45 or 1.0)
end

local function Redraw()
    if not plan or not plan.spec then return end

    local now = GetTime()
    local settings = Settings()
    local maxRows = settings.compact and 5 or #plan.entries
    local shown = 0

    EnsureRows(#plan.entries)

    for position, entry in ipairs(plan.entries) do
        local row = rows[entry.index]
        if position <= maxRows then
            shown = shown + 1
            row.targetY = -(position - 1) * ROW_STEP

            -- Eine Zeile, die gerade erst eingeblendet wird, springt an
            -- ihren Platz statt von ihrer alten Höhe herüberzugleiten -
            -- sonst wandert sie beim Öffnen des Fensters quer durch die
            -- Liste, obwohl sich nichts umsortiert hat.
            if not row:IsShown() then
                row.y = row.targetY
                PlaceRow(row)
                row:Show()
            end

            UpdateRow(row, entry, position, now, settings.showKeys)
        else
            row:Hide()
        end
    end

    -- Cooldown-Leiste
    for index, extra in ipairs(plan.extras) do
        local button = extraIcons[index]
        if not button then
            button = CreateExtraIcon(index)
            extraIcons[index] = button
        end
        button.spell = extra.spell
        button.rule = extra.rule
        button.reasonText = extra.reason

        local _, _, icon = GetSpellInfo(extra.spell)
        button.icon:SetTexture(icon)
        ApplyCooldownSwipe(button.cd, extra.spell)

        if extra.state == "unknown" then
            button:Hide()
        else
            button:Show()
            button.icon:SetDesaturated(not extra.ready)
            button.icon:SetAlpha(extra.ready and 1.0 or 0.45)
            button.glow:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], extra.ready and 0.55 or 0.0)
        end
    end
    for index = #plan.extras + 1, #extraIcons do
        extraIcons[index]:Hide()
    end

    extrasBar:SetShown(settings.showExtras and #plan.extras > 0)

    UpdateHero()
    LayoutFrame(shown)
end

-- Einziger Zeichenpfad. Wichtig ist, dass LayoutFrame in jedem Fall
-- läuft: die Bewertungs- und die Einstellungsseite bekommen ihre Anker
-- und ihre Höhe erst dort, und die Fußzeile rutscht mit.
local function DrawActivePanel()
    if activePanel == "queue" then
        Redraw()
        return
    end

    if activePanel == "stats" then FillStatsPanel() end
    LayoutFrame(0)
end

--------------------------------------------------
-- Fußzeile / Kopfzeile mit Text füllen
--------------------------------------------------

local function UpdateFooter()
    local score = RE.Session.Score()

    if not score then
        -- Zwischen zwei Sitzungen sagt die Fußzeile, ob die letzte lang
        -- genug war - sonst bliebe die Mindestdauer eine unsichtbare
        -- Regel, und ein "nichts kam an" wäre nicht erklärbar.
        SetText(scoreText, lastResult
            and (lastReported and "Letzte Sitzung" or "Letzte Sitzung · zu kurz")
            or "Kein Kampf", lastResult and not lastReported and "gold" or "textFaint")

        if lastResult then
            SetText(metaText, string.format("%s · %.0f %%",
                lastResult.grade or "?", lastResult.total or 0), "textDim")
            scoreFill:SetWidth(math.max(1, (scoreBar:GetWidth() or 1)
                * math.min(1, (lastResult.total or 0) / 100)))
        else
            SetText(metaText, "", "textFaint")
            scoreFill:SetWidth(1)
        end
        return
    end

    local total = score.total or 0
    local colorName = total >= 84 and "green" or (total >= 62 and "gold" or "red")

    SetText(scoreText, string.format("%.0f %%  %s", total, select(2, RE.GradeFor(total))), colorName)

    -- Rechts steht, woran die Sitzung gerade hängt: erst der Weg zur
    -- Mindestdauer, dann die reine Laufzeit. Wer nach der Sitzung
    -- fragt "warum kam nichts an", hat die Antwort vorher gesehen.
    local remaining = SessionRemaining(score)

    if resumeDeadline then
        SetText(metaText, string.format("Pause · noch %ds",
            math.max(0, math.ceil(resumeDeadline - GetTime()))), "gold")
    elseif remaining then
        SetText(metaText, string.format("%s / %s",
            Clock(score.duration), Clock(MIN_SESSION_SECONDS)), "textDim")
    else
        SetText(metaText, string.format("%d Aktionen · %s",
            score.casts, Clock(score.duration)), "textDim")
    end

    local col = Col(colorName)
    scoreFill:SetColorTexture(col[1], col[2], col[3], 1)
    scoreFill:SetWidth(math.max(1, (scoreBar:GetWidth() or 1) * math.min(1, total / 100)))
end

local function UpdateSubtitle()
    -- Die Unterzeile gehoert der Kopfleiste des Trainerfensters, und die
    -- entsteht erst in CreateFrameOnce(). Zwei Wege kommen aber hier an,
    -- ohne dass das Fenster je offen war: "/wc training check" und
    -- "Stummschaltungen aufheben" rufen RefreshSpec(), und das endet
    -- immer in dieser Funktion. Ohne diese Zeile lief der reine
    -- Diagnosebefehl auf einem `subtitleText == nil` auf - und zwar genau
    -- bei dem, der den Helfer noch nie geoeffnet hatte.
    --
    -- Bewusst hier und nicht in SetText: ein FontString, den es nicht gibt,
    -- ist sonst ueberall in dieser Datei ein Fehler und soll auch einer
    -- bleiben. Nur diese eine Anzeige darf fehlen.
    if not subtitleText then return end

    if not currentSpecKey then
        SetText(subtitleText, "Keine Spec erkannt", "red")
        return
    end

    local spec = WeintCodex_GetRotation and WeintCodex_GetRotation(currentSpecKey)
    if not spec then
        SetText(subtitleText, (currentSpecName or currentSpecKey) .. " · keine Liste", "gold")
        return
    end

    local where = dummyDetected and "Trainingspuppe" or (manualActive and "manuell" or "")
    SetText(subtitleText, (currentSpecName or currentSpecKey)
        .. (where ~= "" and (" · " .. where) or ""), "textFaint")
end

--------------------------------------------------
-- Spec wechseln
--------------------------------------------------

local function RefreshSpec()
    local key, display
    if WeintCodex.Charakter and WeintCodex.Charakter.GetProfileKey then
        key, display = WeintCodex.Charakter.GetProfileKey()
    end

    if key ~= currentSpecKey then
        for _, row in ipairs(rows) do row:Hide() end
        RE.ResetCastMemory()
    end

    currentSpecKey, currentSpecName = key, display
    UpdateSubtitle()
end

--------------------------------------------------
-- Sitzung
--------------------------------------------------

local function RecordSession(result)
    if not result then return end

    local store = Store()
    store.sessions = store.sessions or {}

    local name = UnitName("player") or "?"
    store.sessions[name] = store.sessions[name] or {}
    local list = store.sessions[name]

    local session = {
        specKey    = result.specKey,
        date       = date("%Y%m%d"),
        duration   = math.floor(result.duration or 0),
        hits       = result.casts or 0,
        compliant  = result.perfect or 0,
        -- compliance trägt jetzt die Gesamtnote statt der reinen
        -- Trefferquote. Das Feld bleibt eine Prozentzahl mit derselben
        -- Bedeutung ("wie gut war die Sitzung"), damit die Tage-Serie in
        -- der Companion (core/academy_dummy_sync.py) unverändert
        -- weiterrechnet - nur eben auf einer ehrlicheren Zahl.
        compliance = result.total or 0,
        grade      = result.grade,
        priority   = result.priority,
        busy       = result.busy,
        uptime     = result.uptime,
    }
    list[#list + 1] = session

    while #list > 90 do
        table.remove(list, 1)
    end

    store.best = store.best or {}
    local best = store.best[result.specKey or "?"]
    if not best or (result.total or 0) > best then
        store.best[result.specKey or "?"] = result.total or 0
    end

    if WeintCodex.Companion and WeintCodex.Companion.SendDummyPracticeSession then
        WeintCodex.Companion.SendDummyPracticeSession(session)
    end
end

-- Kampfbeginn: entweder eine neue Sitzung, oder die Fortsetzung der
-- laufenden, wenn die Pause kurz genug war (siehe RESUME_WINDOW).
local function StartSession()
    resumeDeadline = nil

    if sessionActive or not currentSpecKey then return end
    if not (WeintCodex_GetRotation and WeintCodex_GetRotation(currentSpecKey)) then return end

    sessionActive = true
    RE.Session.Start(currentSpecKey)
end

-- Kampfende: die Sitzung bleibt zunächst offen und wird erst nach
-- RESUME_WINDOW geschlossen. Wer nur kurz Ressourcen sammelt oder das
-- Ziel wechselt, übt danach an derselben Sitzung weiter.
local function PauseSession()
    if not sessionActive then return end
    resumeDeadline = GetTime() + RESUME_WINDOW
end

local function FinalizeSession()
    if not sessionActive then return end
    sessionActive = false
    resumeDeadline = nil

    local result = RE.Session.Finish()
    if not result then return end

    lastResult = result

    -- Erst ab drei Minuten Kampfzeit ist es eine Übungssitzung: alles
    -- darunter ist ein Scharmützel, sagt nichts über die Rotation aus
    -- und würde die Tage-Serie in der Companion mit Rauschen füllen.
    -- Die Zahl steht auch drüben in core/academy_dummy_sync.py, damit
    -- die Regel unabhängig von der Addon-Version desselben Spielers gilt.
    lastReported = (result.duration or 0) >= MIN_SESSION_SECONDS
        and (result.casts or 0) >= MIN_SESSION_HITS

    if lastReported then
        RecordSession(result)
    end

    if frame and frame:IsShown() then
        UpdateFooter()
        if activePanel == "stats" then FillStatsPanel() end
    end
end

--------------------------------------------------
-- Takt
--------------------------------------------------

local elapsedSinceTick = 0

local function OnUpdate(self, elapsed)
    -- Gleiten läuft in jedem Bild, nicht nur im Auswertungstakt -
    -- sonst würde die Zeile in Zehntelschritten springen.
    for _, row in ipairs(rows) do
        if row:IsShown() and row.y ~= row.targetY then
            if math.abs(row.targetY - row.y) < 0.5 then
                row.y = row.targetY
            else
                row.y = row.y + (row.targetY - row.y) * math.min(1, elapsed * SLIDE_SPEED)
            end
            PlaceRow(row)
        end
    end

    elapsedSinceTick = elapsedSinceTick + elapsed
    local interval = sessionActive and TICK_COMBAT or TICK_IDLE
    if elapsedSinceTick < interval then return end

    local step = elapsedSinceTick
    elapsedSinceTick = 0

    -- Ist die Kampfpause zu lang geworden, wird hier abgerechnet. Das
    -- muss vor dem Spec-Ausstieg stehen: eine offene Sitzung darf nicht
    -- daran hängenbleiben, dass die Spec gerade nicht auflösbar ist.
    if resumeDeadline and GetTime() >= resumeDeadline then
        FinalizeSession()
    end

    if not currentSpecKey then return end

    ranksNow, ranksPrev = ranksPrev, ranksNow
    plan = RE.Evaluate(currentSpecKey, MutedFor(currentSpecKey))
    RE.RankList(plan, ranksNow)

    -- Gemessen wird ausschließlich echte Kampfzeit: die Pause zwischen
    -- zwei Versuchen zählt weder für die Dauer noch für die Auslastung,
    -- obwohl die Sitzung sie überlebt.
    RE.Session.Sample(plan, step, sessionActive and inCombat)

    DrawActivePanel()
    UpdateFooter()
end

--------------------------------------------------
-- Öffentliche API
--------------------------------------------------

function WeintCodex.RotationTrainer.Refresh()
    if not frame or not frame:IsShown() then return end
    if not currentSpecKey then return end

    plan = RE.Evaluate(currentSpecKey, MutedFor(currentSpecKey))
    RE.RankList(plan, ranksNow)

    DrawActivePanel()
    UpdateFooter()
    UpdateSubtitle()
end

function WeintCodex.RotationTrainer.Show()
    CreateFrameOnce()
    RefreshSpec()
    RE.InvalidateKeybinds()

    local spec = currentSpecKey and WeintCodex_GetRotation and WeintCodex_GetRotation(currentSpecKey)
    if not spec then
        -- Ohne Liste bleibt das Fenster leer, aber es sagt warum: die
        -- Tank-Profile haben bewusst keine (siehe data/rotations.lua).
        SwitchPanel("queue")
        frame:Show()
        UpdateSubtitle()
        LayoutFrame(0)
        SetText(hero.name, "Keine Liste", "textDim")
        SetText(hero.reason, "Für diese Spec ist keine Rotation hinterlegt.", "textFaint")
        hero.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        return
    end

    SwitchPanel(activePanel == "queue" and "queue" or activePanel)
    frame:Show()

    inCombat = UnitAffectingCombat("player") and true or false
    if inCombat then StartSession() end
    WeintCodex.RotationTrainer.Refresh()
end

function WeintCodex.RotationTrainer.Hide()
    if frame then frame:Hide() end
    manualActive = false
    dummyDetected = false
    FinalizeSession()
end

function WeintCodex.RotationTrainer.Toggle()
    if frame and frame:IsShown() then
        WeintCodex.RotationTrainer.Hide()
    else
        manualActive = true
        WeintCodex.RotationTrainer.Show()
    end
end

function WeintCodex.RotationTrainer.StartManual()
    manualActive = true
    WeintCodex.RotationTrainer.Show()
end

function WeintCodex.RotationTrainer.StopManual()
    WeintCodex.RotationTrainer.Hide()
end

-- "/wc training check": listet die Regeln der eigenen Spec mit ID,
-- Client-Namen und Gelernt-Status auf.
function WeintCodex.RotationTrainer.PrintCheck()
    RefreshSpec()
    if not currentSpecKey then
        print("|cffD4A24A[WeintCodex]|r Keine Spec erkannt.")
        return
    end
    RE.PrintDiagnostics(currentSpecKey)
end

-- Die fuenf Schalter des Fensters auch von aussen: bis 2.5.0.0 waren sie
-- nur ueber die Einstellungsseite IM Trainerfenster erreichbar, das sich
-- wiederum nur an einer Trainingspuppe oder ueber "/wc training" oeffnet.
-- Wer den Helfer abschalten wollte, musste ihn dafuer erst aufmachen.
-- Gelesen und geschrieben wird derselbe Speicher wie dort - eine zweite
-- Wahrheit daneben gaebe es nicht zu gewinnen.
function WeintCodex.RotationTrainer.GetOption(key)
    if DEFAULT_SETTINGS[key] == nil then return nil end
    return Settings()[key] and true or false
end

function WeintCodex.RotationTrainer.SetOption(key, value)
    if DEFAULT_SETTINGS[key] == nil then return end
    Settings()[key] = value and true or false
    -- Die Schalter im Trainerfenster lesen ihren Zustand nur beim Aufbau der
    -- Seite. Steht das Fenster offen, waehrend jemand nebenan im Hauptfenster
    -- umschaltet, zeigte es sonst den alten Stand.
    if optionsPanel and optionsPanel.toggles then
        for _, toggle in ipairs(optionsPanel.toggles) do toggle.Sync() end
    end
    -- Und umgekehrt: die Einstellungsseite fuehrt dieselben fuenf Schalter.
    if WeintCodex.Settings and WeintCodex.Settings.Refresh then
        WeintCodex.Settings.Refresh()
    end
    WeintCodex.RotationTrainer.Refresh()
end

function WeintCodex.RotationTrainer.IsShown()
    return frame and frame:IsShown() and true or false
end

-- Stummgeschaltete Zeilen der aktuellen Spec wieder hoerbar machen.
-- Gibt zurueck, wie viele es waren, damit der Aufrufer das sagen kann,
-- statt eine Zahl zu behaupten.
function WeintCodex.RotationTrainer.ClearMuted()
    RefreshSpec()
    local muted = MutedFor(currentSpecKey)
    if not muted then return 0 end
    local n = 0
    for key in pairs(muted) do
        muted[key] = nil
        n = n + 1
    end
    WeintCodex.RotationTrainer.Refresh()
    return n
end

-- Für "/wc training" auf einem unbekannten Ziel: meldet die NPC-ID,
-- damit DUMMY_NPC_IDS ergänzt werden kann.
function WeintCodex.RotationTrainer.PrintTargetId()
    local guid = UnitGUID("target")
    if not guid then
        print("|cffD4A24A[WeintCodex]|r Kein Ziel ausgewählt.")
        return
    end
    local unitType, _, _, _, _, npcId = strsplit("-", guid)
    print(string.format("|cffD4A24A[WeintCodex]|r Ziel: %s (%s), NPC-ID %s",
        UnitName("target") or "?", unitType or "?", tostring(npcId)))
end

--------------------------------------------------
-- Ereignisse
--------------------------------------------------

local watcher = CreateFrame("Frame")

local function TryRegisterEvent(f, eventName)
    return pcall(f.RegisterEvent, f, eventName)
end

watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
watcher:RegisterEvent("UPDATE_BINDINGS")
watcher:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
TryRegisterEvent(watcher, "UNIT_SPELLCAST_CHANNEL_START")
TryRegisterEvent(watcher, "PLAYER_SPECIALIZATION_CHANGED")
TryRegisterEvent(watcher, "ACTIVE_TALENT_GROUP_CHANGED")

local function TargetNpcId(unitToken)
    local guid = UnitGUID(unitToken)
    if not guid then return nil end
    local unitType, _, _, _, _, npcId = strsplit("-", guid)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    return tonumber(npcId)
end

-- Die Argumente von UNIT_SPELLCAST_SUCCEEDED sind zwischen den
-- Client-Generationen verschoben worden (früher Name/Rang/LineID/ID,
-- heute GUID/ID). In beiden Fällen steht die Spell-ID hinten - deshalb
-- wird von hinten nach der ersten Zahl gesucht, die der Client als
-- Zauber kennt, statt eine feste Position zu raten.
local function ExtractSpellId(...)
    for i = select("#", ...), 1, -1 do
        local value = select(i, ...)
        if type(value) == "number" and GetSpellInfo(value) then return value end
    end
    return nil
end

local function HandleCast(spellId)
    if not spellId or not sessionActive or not currentSpecKey then return end

    -- Kanalisierte Zauber lösen je nach Client beide Ereignisse aus.
    local now = GetTime()
    if lastCast[spellId] and (now - lastCast[spellId]) < CAST_DEDUPE then return end
    lastCast[spellId] = now

    local credit, rank = RE.Session.NoteCast(spellId, ranksNow, ranksPrev)
    RE.NoteCast(spellId)

    if credit then
        for _, row in ipairs(rows) do
            if row.spell == spellId then
                row.flashUntil = now + FLASH_TIME
                row.flashColor = (rank == 1) and "green" or (credit > 0 and "gold" or "red")
            end
        end
    end

    -- Sofort neu bewerten: die eben gedrückte Fähigkeit soll im selben
    -- Moment nach unten wandern, nicht erst beim nächsten Takt.
    WeintCodex.RotationTrainer.Refresh()
end

watcher:SetScript("OnEvent", function(self, event, unit, ...)

    if event == "PLAYER_TARGET_CHANGED" then
        local npcId = TargetNpcId("target")
        dummyDetected = npcId ~= nil and DUMMY_NPC_IDS[npcId] == true

        if dummyDetected and Settings().auto then
            WeintCodex.RotationTrainer.Show()
        end

        if frame and frame:IsShown() then
            UpdateSubtitle()
            WeintCodex.RotationTrainer.Refresh()
        end
        return
    end

    if event == "UPDATE_BINDINGS" or event == "ACTIONBAR_SLOT_CHANGED" then
        RE.InvalidateKeybinds()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        if frame and frame:IsShown() then StartSession() end
        return
    end

    -- Kampfende schließt die Sitzung nicht: erst wenn nach
    -- RESUME_WINDOW kein Kampf zurückgekommen ist, wird abgerechnet
    -- (im Takt, siehe OnUpdate).
    if event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        PauseSession()
        return
    end

    if not frame or not frame:IsShown() then return end

    if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        if unit ~= "player" then return end
        HandleCast(ExtractSpellId(...))
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        RefreshSpec()
        WeintCodex.RotationTrainer.Refresh()
        return
    end
end)

-- Der Takt hängt am Fenster selbst: läuft nur, solange es sichtbar ist.
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(self, elapsed)
    if not frame or not frame:IsShown() then return end
    OnUpdate(self, elapsed)
end)
