--------------------------------------------------
-- WeintCodex :: Rotationstrainer
--
-- Kleines, freiverschiebbares Fenster mit der Prioritätenliste der
-- aktuellen Spec (data/rotations.lua). Öffnet sich automatisch, wenn
-- das Ziel eine bekannte Trainingspuppe ist, oder manuell per
-- "/wc training". Zeigt live, welche Fähigkeit gerade priorisiert
-- fällig ist und ob der zuletzt gewirkte Zauber dazu passte.
--
-- Bewusst eine eigenständige Engine im Addon, nicht ueber die
-- Companion berechnet: die Companion hat (noch) keine Live-Combatlog-
-- Auswertung und die Inbox wird ohnehin nur bei Login/Reload gelesen
-- (siehe modules/companion.lua) - fuer Live-Haekchen waehrend des
-- Spielens gibt es also keinen anderen Weg. Die Auswertung ist
-- bewusst einfach (geordnete Liste + simple Bedingungen, kein
-- SimC/Hekili-APL) - siehe Kopfkommentar von data/rotations.lua.
--
-- Am Ende einer Sitzung wird das Ergebnis per
-- WeintCodex.Companion.SendDummyPracticeSession() an die Companion
-- gemeldet; die 3-Tage-Serie und das Abhaken im Trainingsplan
-- passieren dort (siehe core/academy_dummy_sync.py).
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.RotationTrainer = {}

local C          = WeintCodex.Colors
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

--------------------------------------------------
-- Konstanten
--------------------------------------------------

-- Best-Effort-Liste bekannter MoP-Trainingspuppen. Bewusst klein und
-- erweiterbar: "/wc training" auf einem unbekannten Ziel meldet dessen
-- NPC-ID im Chat, damit die Liste bei Bedarf ergänzt werden kann.
local DUMMY_NPC_IDS = {
    [2673] = true,  -- "Trainingspuppe" (Hauptstädte, seit Classic-Vanilla)
}

local MIN_SESSION_SECONDS = 30
local MIN_SESSION_HITS    = 5
local FLASH_SECONDS        = 1.2

local POWER_TYPE_GLOBAL = {
    RAGE        = "SPELL_POWER_RAGE",
    ENERGY      = "SPELL_POWER_ENERGY",
    FOCUS       = "SPELL_POWER_FOCUS",
    MANA        = "SPELL_POWER_MANA",
    RUNIC_POWER = "SPELL_POWER_RUNIC_POWER",
    CHI         = "SPELL_POWER_CHI",
    HOLY_POWER  = "SPELL_POWER_HOLY_POWER",
}

--------------------------------------------------
-- Spielzustand-Helfer
--
-- Aurenprüfung über den Namen statt über die Rückgabeposition von
-- spellId: UnitAura()s Tupel-Reihenfolge hat sich zwischen Client-
-- Versionen leicht verschoben, der Name ist stabil. Gleiche Doktrin
-- wie data/bis.lua/gems.lua: zur Laufzeit über die Spiel-API aufloesen.
--------------------------------------------------

local function HasAura(unit, filter, auraSpellId)
    local auraName = GetSpellInfo(auraSpellId)
    if not auraName then return false end
    for i = 1, 40 do
        local name = UnitAura(unit, i, filter)
        if not name then break end
        if name == auraName then return true end
    end
    return false
end

local function CurrentPower(powerType)
    local global = POWER_TYPE_GLOBAL[powerType]
    local index = global and _G[global]
    if index then
        return UnitPower("player", index)
    end
    return UnitPower("player")
end

local function TargetNpcId(unitToken)
    local guid = UnitGUID(unitToken)
    if not guid then return nil end
    local unitType, _, _, _, _, npcId = strsplit("-", guid)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    return tonumber(npcId)
end

local function TargetHealthPercent()
    if not UnitExists("target") then return nil end
    local max = UnitHealthMax("target")
    if not max or max <= 0 then return nil end
    return UnitHealth("target") / max * 100
end

local function IsSpellReady(spellId)
    local name = GetSpellInfo(spellId)
    if not name then return false end
    if IsSpellKnown and not IsSpellKnown(spellId) then return false end
    local start, duration = GetSpellCooldown(spellId)
    if not start or duration == 0 then return true end
    return (start + duration - GetTime()) <= 0.1
end

-- Prüft die Zusatzbedingung einer Regel (ohne always/Cooldown - das
-- übernimmt IsSpellReady). Gibt true, wenn die Regel gerade zutrifft.
local function RuleConditionMet(rule)
    if rule.always then return true end

    if rule.execute then
        local pct = TargetHealthPercent()
        return pct ~= nil and pct <= rule.execute
    end

    if rule.buffPresent then
        return HasAura("player", "HELPFUL", rule.buffPresent)
    end

    if rule.buffMissing then
        return not HasAura("player", "HELPFUL", rule.buffMissing)
    end

    if rule.debuffPresent then
        return UnitExists("target") and HasAura("target", "HARMFUL|PLAYER", rule.debuffPresent)
    end

    if rule.debuffMissing then
        return not (UnitExists("target") and HasAura("target", "HARMFUL|PLAYER", rule.debuffMissing))
    end

    if rule.power then
        return CurrentPower(rule.power.type) >= rule.power.atLeast
    end

    return false
end

--------------------------------------------------
-- Zustand
--------------------------------------------------

local frame, titleText, hintText, statusText, rowsContainer
local rows = {}
local currentSpecKey = nil
local dummyDetected  = false
local manualActive   = false

local sessionActive  = false
local sessionStart   = 0
local hits           = 0
local compliantHits  = 0
local expectedIndex  = nil

--------------------------------------------------
-- Companion-Meldung / Verlauf
--------------------------------------------------

local function CharacterName()
    return UnitName("player") or "?"
end

local function RecordSession(durationSec, totalHits, correctHits, compliancePercent)
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.rotationTrainer = WeintCodex.SavedData.rotationTrainer or { sessions = {} }
    local store = WeintCodex.SavedData.rotationTrainer
    store.sessions = store.sessions or {}

    local name = CharacterName()
    store.sessions[name] = store.sessions[name] or {}
    local list = store.sessions[name]

    local session = {
        specKey     = currentSpecKey,
        date        = date("%Y%m%d"),
        duration    = math.floor(durationSec),
        hits        = totalHits,
        compliant   = correctHits,
        compliance  = compliancePercent,
    }
    list[#list + 1] = session

    -- Auf die letzten 30 Tage begrenzen, damit die SavedVariables nicht
    -- unbegrenzt wachsen.
    while #list > 0 and #list > 90 do
        table.remove(list, 1)
    end

    if WeintCodex.Companion and WeintCodex.Companion.SendDummyPracticeSession then
        WeintCodex.Companion.SendDummyPracticeSession(session)
    end
end

--------------------------------------------------
-- UI-Aufbau
--------------------------------------------------

local function CreateCloseButton(parent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(20, 20)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetAllPoints(btn)
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    label:SetText("x")
    label:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])

    btn:SetScript("OnEnter", function() label:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3]) end)
    btn:SetScript("OnLeave", function() label:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3]) end)
    btn:SetScript("OnClick", function() WeintCodex.RotationTrainer.Hide() end)

    return btn
end

local function CreateFrameOnce()
    if frame then return end

    frame = CreateFrame("Frame", "WeintCodexRotationTrainer", UIParent)
    frame:SetSize(230, 300)
    frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        WeintCodex.SavedData = WeintCodex.SavedData or {}
        WeintCodex.SavedData.rotationTrainer = WeintCodex.SavedData.rotationTrainer or {}
        WeintCodex.SavedData.rotationTrainer.pos = { point = point, x = x, y = y }
    end)

    SetSolidBg(frame, C.bgDark[1], C.bgDark[2], C.bgDark[3], 0.96)
    DrawBorder(frame, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.6, 1)

    local header = CreateFrame("Frame", nil, frame)
    header:SetHeight(46)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint()
        WeintCodex.SavedData.rotationTrainer.pos = { point = point, x = x, y = y }
    end)
    SetSolidBg(header, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)

    titleText = header:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(WeintCodex.Fonts.serif, 13, "")
    titleText:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -8)
    titleText:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    titleText:SetText("Rotationstrainer")

    statusText = header:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(WeintCodex.Fonts.mono, 10, "")
    statusText:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -26)
    statusText:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
    statusText:SetText("Kein Kampf")

    CreateCloseButton(header)

    hintText = frame:CreateFontString(nil, "OVERLAY")
    hintText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    hintText:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
    hintText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -60)
    hintText:SetJustifyH("LEFT")
    hintText:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    hintText:Hide()

    rowsContainer = CreateFrame("Frame", nil, frame)
    rowsContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -52)
    rowsContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)

    local savedPos = WeintCodex.SavedData and WeintCodex.SavedData.rotationTrainer and WeintCodex.SavedData.rotationTrainer.pos
    if savedPos and savedPos.point then
        frame:ClearAllPoints()
        frame:SetPoint(savedPos.point, UIParent, savedPos.point, savedPos.x, savedPos.y)
    end

    frame:Hide()
end

local function CreateRow(index)
    local row = CreateFrame("Frame", nil, rowsContainer)
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", rowsContainer, "TOPLEFT", 0, -(index - 1) * 34)
    row:SetPoint("TOPRIGHT", rowsContainer, "TOPRIGHT", 0, -(index - 1) * 34)

    local bg = SetSolidBg(row, C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.9)
    row.bg = bg

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon = icon

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -26, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    row.label = label

    local status = row:CreateFontString(nil, "OVERLAY")
    status:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    status:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.status = status

    return row
end

local function EnsureRows(count)
    for i = #rows + 1, count do
        rows[i] = CreateRow(i)
    end
    for i = count + 1, #rows do
        rows[i]:Hide()
    end
    for i = 1, count do
        rows[i]:Show()
    end
end

--------------------------------------------------
-- Anzeige aktualisieren
--------------------------------------------------

local function ResetRowVisuals()
    for _, row in ipairs(rows) do
        row.bg:SetColorTexture(C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.9)
        row.status:SetText("")
    end
end

local function RefreshSpecRows()
    currentSpecKey = WeintCodex.Charakter and WeintCodex.Charakter.GetProfileKey and WeintCodex.Charakter.GetProfileKey()
    local ruleList = currentSpecKey and WeintCodex_Rotations and WeintCodex_Rotations[currentSpecKey]

    if not ruleList then
        EnsureRows(0)
        hintText:SetText("Für deine Spec ist noch keine Prioritätenliste gepflegt.")
        hintText:Show()
        return
    end

    hintText:Hide()
    EnsureRows(#ruleList)

    for i, rule in ipairs(ruleList) do
        local row = rows[i]
        local name, _, icon = GetSpellInfo(rule.spell)
        row.icon:SetTexture(icon)
        row.label:SetText(name or ("Spell " .. rule.spell))
    end
end

-- Ermittelt die aktuell hoechstpriorisierte, gerade erfuellte UND
-- verfuegbare Regel. Wird bei jedem relevanten Event neu berechnet.
local function RecomputeExpected()
    local ruleList = currentSpecKey and WeintCodex_Rotations and WeintCodex_Rotations[currentSpecKey]
    if not ruleList then return end

    ResetRowVisuals()

    local newIndex = nil
    for i, rule in ipairs(ruleList) do
        if RuleConditionMet(rule) and IsSpellReady(rule.spell) then
            newIndex = i
            break
        end
    end

    expectedIndex = newIndex

    if expectedIndex and rows[expectedIndex] then
        rows[expectedIndex].bg:SetColorTexture(C.purpleDeep and C.purpleDeep[1] or C.purple[1],
            C.purpleDeep and C.purpleDeep[2] or C.purple[2],
            C.purpleDeep and C.purpleDeep[3] or C.purple[3], 0.9)
        rows[expectedIndex].status:SetText("▶")
        rows[expectedIndex].status:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    end
end

local function FlashRow(index, ok)
    local row = rows[index]
    if not row then return end

    local col = ok and C.success or C.warning
    row.bg:SetColorTexture(col[1], col[2], col[3], 0.55)
    row.status:SetText(ok and "✓" or "…")
    row.status:SetTextColor(col[1], col[2], col[3])

    if C_Timer and C_Timer.After then
        C_Timer.After(FLASH_SECONDS, function()
            RecomputeExpected()
        end)
    end
end

local function UpdateStatusText()
    if not sessionActive then
        statusText:SetText("Kein Kampf")
        return
    end
    local pct = hits > 0 and (compliantHits / hits * 100) or 0
    statusText:SetText(string.format("%d Aktionen | %d%% Priorität", hits, pct))
end

--------------------------------------------------
-- Sitzungssteuerung
--------------------------------------------------

local function StartSession()
    if sessionActive then return end
    sessionActive = true
    sessionStart = GetTime()
    hits, compliantHits = 0, 0
    UpdateStatusText()
end

local function FinalizeSession()
    if not sessionActive then return end
    sessionActive = false

    local duration = GetTime() - sessionStart
    if duration >= MIN_SESSION_SECONDS and hits >= MIN_SESSION_HITS then
        local compliance = hits > 0 and (compliantHits / hits * 100) or 0
        RecordSession(duration, hits, compliantHits, compliance)
    end

    hits, compliantHits = 0, 0
    UpdateStatusText()
end

--------------------------------------------------
-- Öffentliche API
--------------------------------------------------

function WeintCodex.RotationTrainer.Show()
    CreateFrameOnce()
    RefreshSpecRows()
    RecomputeExpected()
    UpdateStatusText()
    frame:Show()
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

--------------------------------------------------
-- Events
--------------------------------------------------

local watcher = CreateFrame("Frame")

local function TryRegisterEvent(f, eventName)
    return pcall(f.RegisterEvent, f, eventName)
end

watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
watcher:RegisterEvent("UNIT_AURA")
watcher:RegisterEvent("UNIT_POWER_UPDATE")
TryRegisterEvent(watcher, "PLAYER_SPECIALIZATION_CHANGED")
TryRegisterEvent(watcher, "ACTIVE_TALENT_GROUP_CHANGED")

watcher:SetScript("OnEvent", function(self, event, unit, ...)

    if event == "PLAYER_TARGET_CHANGED" then
        local npcId = TargetNpcId("target")
        dummyDetected = npcId ~= nil and DUMMY_NPC_IDS[npcId] == true

        if dummyDetected then
            WeintCodex.RotationTrainer.Show()
        end

        if frame and frame:IsShown() then
            RecomputeExpected()
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if frame and frame:IsShown() then
            StartSession()
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        FinalizeSession()
        return
    end

    if not frame or not frame:IsShown() then return end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit ~= "player" then return end
        local spellId = select(2, ...)

        if not sessionActive then return end
        if not currentSpecKey or not WeintCodex_Rotations or not WeintCodex_Rotations[currentSpecKey] then return end

        hits = hits + 1
        local ok = expectedIndex and rows[expectedIndex] and
            WeintCodex_Rotations[currentSpecKey][expectedIndex] and
            WeintCodex_Rotations[currentSpecKey][expectedIndex].spell == spellId

        if ok then compliantHits = compliantHits + 1 end

        if expectedIndex then
            FlashRow(expectedIndex, ok)
        end

        UpdateStatusText()
        return
    end

    if event == "UNIT_AURA" then
        if unit ~= "player" and unit ~= "target" then return end
        RecomputeExpected()
        return
    end

    if event == "UNIT_POWER_UPDATE" then
        if unit ~= "player" then return end
        RecomputeExpected()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        RefreshSpecRows()
        RecomputeExpected()
        return
    end
end)
