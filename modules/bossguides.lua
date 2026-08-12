--------------------------------------------------
-- WeintCodex :: Bossguides Module
-- Layout: Portrait | Name+Instanz | Zitat
--         Links:  Rollen-Tipps + Aufstellung (optional) + Fähigkeiten (scrollbar)
--         Inspector: Kurz & Knapp + Notizen + Ansage
--------------------------------------------------

WeintCodex.BossGuides = {}

local C            = WeintCodex.Colors
local selectedBoss  = nil
local selectedRole  = nil
local guideFrame    = nil

-- Schluessel fuer WeintCodex.SavedData.encounterProgress sowie Teilstring
-- zur Erkennung der passenden Blizzard-Lockout-Instanz (robuster als ein
-- exakter Namensvergleich gegen unsere eigene, ggf. leicht abweichende
-- Instanz-Bezeichnung in data/BossData.lua).
local INSTANCE_NAME  = "Schlacht um Orgrimmar"
local INSTANCE_MATCH = "Orgrimmar"

-- Instanz beim Tracking anmelden, damit der Lockout-Import auch ohne
-- geoeffnetes WeintCodex-Fenster laeuft (Login, Betreten der Instanz,
-- Bosskill). Ladereihenfolge laut .toc: encounter_tracking vor bossguides.
if WeintCodex.EncounterTracking and WeintCodex.EncounterTracking.RegisterInstance then
    WeintCodex.EncounterTracking.RegisterInstance(INSTANCE_NAME, INSTANCE_MATCH)
end

--------------------------------------------------
-- Boss-Reihenfolge SoO
--------------------------------------------------

local bossOrder = {
    { name = "Immerseus",                      color = {0.20, 0.45, 0.70} },
    { name = "Die gefallenen Beschützer",      color = {0.65, 0.30, 0.20} },
    { name = "Norushen",                       color = {0.80, 0.70, 0.30} },
    { name = "Sha des Stolzes",                color = {0.30, 0.20, 0.55} },
    { name = "Galakras",                       color = {0.70, 0.40, 0.10} },
    { name = "Eisener Koloss",                 color = {0.55, 0.55, 0.60} },
    { name = "Dunkelschamanen",                color = {0.20, 0.50, 0.60} },
    { name = "General Nazgrim",                color = {0.80, 0.60, 0.20} },
    { name = "Malkorok",                       color = {0.60, 0.20, 0.30} },
    { name = "Die Schätze Pandarias",          color = {0.80, 0.65, 0.20} },
    { name = "Thok der Blutdürstige",          color = {0.70, 0.25, 0.15} },
    { name = "Belagerungsingenieur Rußschmied",color = {0.50, 0.50, 0.40} },
    { name = "Die Getreuen der Klaxxi",        color = {0.60, 0.40, 0.20} },
    { name = "Garrosh Höllschrei",             color = {0.70, 0.20, 0.20} },
}

--------------------------------------------------
-- Rollen-Erkennung
--------------------------------------------------

local function GetPlayerRole()
    local role = UnitGroupRolesAssigned("player")
    if role == "TANK"    then return "tank"   end
    if role == "HEALER"  then return "healer" end
    if role == "DAMAGER" then return "dps"    end
    return nil
end

--------------------------------------------------
-- Guide Frame erstellen
--   Top (120px):    Portrait + Name/Instanz + Zitat
--   Rollen-Umschalter: Segmented Control im Content (Tank/Heiler/Schaden)
--   Body (scrollbar): GUIDE-Tipps + FÄHIGKEITEN-Liste
--   Inspector:       Kurz & Knapp + Notizen + "Im Raid ansagen"
--------------------------------------------------

local function CreateGuideFrame()
    if guideFrame then return guideFrame end

    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)

    -- ------------------------------------------------
    -- TOP HEADER (fixed, 120px)
    -- ------------------------------------------------

    local topBar = CreateFrame("Frame", nil, f)
    topBar:SetHeight(120)
    topBar:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

    local topDiv = topBar:CreateTexture(nil, "OVERLAY")
    topDiv:SetHeight(1)
    topDiv:SetPoint("BOTTOMLEFT",  topBar, "BOTTOMLEFT",  0, 0)
    topDiv:SetPoint("BOTTOMRIGHT", topBar, "BOTTOMRIGHT", 0, 0)
    topDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

    -- Boss portrait box
    local portraitBox = CreateFrame("Frame", nil, topBar)
    portraitBox:SetSize(86, 86)
    portraitBox:SetPoint("TOPLEFT", topBar, "TOPLEFT", 20, -18)
    WeintCodex.SetSolidBg(portraitBox, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)
    WeintCodex.DrawSlimBorder(portraitBox, "borderStrong")
    WeintCodex.CutCorners(portraitBox, 10, "bgDark")

    local portraitTexture = portraitBox:CreateTexture(nil, "ARTWORK")
    portraitTexture:SetAllPoints(portraitBox)
    portraitTexture:SetTexCoord(0, 1, 0, 1)
    f.PortraitTexture = portraitTexture

    -- Encounter-Eyebrow + Boss-Name + Zitat
    local instanceStr = topBar:CreateFontString(nil, "OVERLAY")
    instanceStr:SetFont(WeintCodex.Fonts.mono, 10, "")
    instanceStr:SetPoint("TOPLEFT", portraitBox, "TOPRIGHT", 16, -4)
    f.InstanceStr = instanceStr

    local bossNameStr = topBar:CreateFontString(nil, "OVERLAY")
    bossNameStr:SetFont(WeintCodex.Fonts.sansBold, 24, "")
    bossNameStr:SetPoint("TOPLEFT", instanceStr, "BOTTOMLEFT", 0, -6)
    bossNameStr:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    f.BossName = bossNameStr

    -- ------------------------------------------------
    -- Fortschritts-Block (rechts, Encounter-Tracking - siehe
    -- modules/encounter_tracking.lua). Zitat weicht dem Block aus.
    -- ------------------------------------------------

    local progressBox = CreateFrame("Frame", nil, topBar)
    progressBox:SetSize(120, 60)
    progressBox:SetPoint("TOPRIGHT", topBar, "TOPRIGHT", -20, -20)

    local progressEyebrow = progressBox:CreateFontString(nil, "OVERLAY")
    progressEyebrow:SetFont(WeintCodex.Fonts.sans, 9, "")
    progressEyebrow:SetPoint("TOPRIGHT", progressBox, "TOPRIGHT", 0, 0)
    progressEyebrow:SetJustifyH("RIGHT")
    progressEyebrow:SetText(WeintCodex.ColorText("textFaint", "FORTSCHRITT"))

    local progressPct = progressBox:CreateFontString(nil, "OVERLAY")
    progressPct:SetFont(WeintCodex.Fonts.serifBold, 28, "")
    progressPct:SetPoint("TOPRIGHT", progressEyebrow, "BOTTOMRIGHT", 0, -4)
    progressPct:SetJustifyH("RIGHT")
    f.ProgressPct = progressPct

    local progressTrack = progressBox:CreateTexture(nil, "OVERLAY")
    progressTrack:SetHeight(3)
    progressTrack:SetPoint("BOTTOMRIGHT", progressBox, "BOTTOMRIGHT", 0, 0)
    progressTrack:SetSize(120, 3)
    progressTrack:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)

    local progressFill = progressBox:CreateTexture(nil, "OVERLAY")
    progressFill:SetHeight(3)
    progressFill:SetPoint("BOTTOMRIGHT", progressBox, "BOTTOMRIGHT", 0, 0)
    f.ProgressFill = progressFill
    f.ProgressTrackW = 120

    local quoteStr = topBar:CreateFontString(nil, "OVERLAY")
    quoteStr:SetFont(WeintCodex.Fonts.sans, 11, "")
    quoteStr:SetPoint("TOPLEFT", bossNameStr, "BOTTOMLEFT", 0, -8)
    quoteStr:SetPoint("RIGHT", progressBox, "LEFT", -20, 0)
    quoteStr:SetJustifyH("LEFT")
    quoteStr:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    f.QuoteStr = quoteStr

    -- ------------------------------------------------
    -- Rollen-Umschalter (Segmented Control, im Content statt Titelleiste)
    -- ------------------------------------------------

    local roleDefs = {
        { key = "tank",   label = "Tank",    colorName = "blue"  },
        { key = "healer", label = "Heiler",  colorName = "green" },
        { key = "dps",    label = "Schaden", colorName = "red"   },
    }

    local roleBar = CreateFrame("Frame", nil, f)
    roleBar:SetHeight(34)
    roleBar:SetPoint("TOPLEFT",  topBar, "BOTTOMLEFT",  0, -8)
    roleBar:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, -8)
    f.RoleBar = roleBar

    local roleBtns = {}
    for _, rd in ipairs(roleDefs) do
        local rb = CreateFrame("Button", nil, roleBar)
        rb:SetHeight(34)

        local rbg = rb:CreateTexture(nil, "BACKGROUND")
        rbg:SetAllPoints(rb)
        rbg:SetColorTexture(C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
        rb._bg = rbg

        local rlbl = rb:CreateFontString(nil, "OVERLAY")
        rlbl:SetAllPoints(rb)
        rlbl:SetFont(WeintCodex.Fonts.sans, 11, "")
        rlbl:SetJustifyH("CENTER")
        rlbl:SetText(rd.label)
        rb._label = rlbl
        rb._rd    = rd
        rb._key   = rd.key

        rb:SetScript("OnEnter", function(self)
            if selectedRole ~= rd.key then
                self._bg:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
            end
        end)
        rb:SetScript("OnLeave", function(self)
            if selectedRole ~= rd.key then
                self._bg:SetColorTexture(C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
            end
        end)
        rb:SetScript("OnClick", function() ShowRoleTips(rd.key) end)

        table.insert(roleBtns, rb)
    end
    f.RoleBtns = roleBtns

    -- ------------------------------------------------
    -- BODY (scrollbar, einspaltig)
    -- ------------------------------------------------

    local body = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    body:SetPoint("TOPLEFT",     roleBar, "BOTTOMLEFT", 0, -8)
    body:SetPoint("BOTTOMRIGHT", f,       "BOTTOMRIGHT", -26, 4)

    local bodyChild = CreateFrame("Frame", nil, body)
    bodyChild:SetWidth(560)
    bodyChild:SetHeight(1)
    body:SetScrollChild(bodyChild)
    f.LeftChild = bodyChild

    -- GUIDE section header
    local guideHeader = bodyChild:CreateFontString(nil, "OVERLAY")
    guideHeader:SetFont(WeintCodex.Fonts.sans, 10, "")
    guideHeader:SetPoint("TOPLEFT", bodyChild, "TOPLEFT", 20, -14)
    f.GuideHeader = guideHeader

    local guideLine = bodyChild:CreateTexture(nil, "OVERLAY")
    guideLine:SetHeight(1)
    guideLine:SetPoint("TOPLEFT",  bodyChild, "TOPLEFT",  20, -30)
    guideLine:SetPoint("TOPRIGHT", bodyChild, "TOPRIGHT", -20, -30)
    f.GuideLine = guideLine

    -- Tip text
    local tipText = bodyChild:CreateFontString(nil, "OVERLAY")
    tipText:SetFont(WeintCodex.Fonts.sans, 12, "")
    tipText:SetPoint("TOPLEFT", bodyChild, "TOPLEFT", 20, -40)
    tipText:SetWidth(520)
    tipText:SetJustifyH("LEFT")
    tipText:SetSpacing(6)
    tipText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    f.TipText = tipText

    -- AUFSTELLUNG section header (Positionierungsbild, optional - nur
    -- sichtbar wenn der Boss ein "positioning"-Feld in BossData.lua hat)
    local posHeader = bodyChild:CreateFontString(nil, "OVERLAY")
    posHeader:SetFont(WeintCodex.Fonts.sans, 10, "")
    posHeader:SetText(WeintCodex.ColorText("textFaint", "AUFSTELLUNG"))
    f.PosHeader = posHeader

    local posLine = bodyChild:CreateTexture(nil, "OVERLAY")
    posLine:SetHeight(1)
    posLine:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])
    f.PosLine = posLine

    -- Erklaerungstext zur Aufstellung (positioning.text in BossData.lua),
    -- steht zwischen PosLine und den Vorschaubildern.
    local posText = bodyChild:CreateFontString(nil, "OVERLAY")
    posText:SetFont(WeintCodex.Fonts.sans, 11, "")
    posText:SetJustifyH("LEFT")
    posText:SetSpacing(4)
    posText:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    f.PosText = posText

    -- Die Vorschaubilder selbst (f.PosImageBoxes) werden dynamisch in
    -- BuildPositioningSection() erzeugt, da ein Boss ein oder mehrere
    -- Bilder haben kann (z.B. Galakras: zwei Phasen).

    -- FÄHIGKEITEN section header
    local abilHeader = bodyChild:CreateFontString(nil, "OVERLAY")
    abilHeader:SetFont(WeintCodex.Fonts.sans, 10, "")
    abilHeader:SetText(WeintCodex.ColorText("textFaint", "WICHTIGE FÄHIGKEITEN"))
    f.AbilHeader = abilHeader

    local abilLine = bodyChild:CreateTexture(nil, "OVERLAY")
    abilLine:SetHeight(1)
    abilLine:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])
    f.AbilLine = abilLine

    guideFrame = f
    return f
end

--------------------------------------------------
-- Content nutzt die tatsaechliche Panelbreite statt einer festen Spalte
-- (analog Charakter-Uebersicht). Wird bei jedem ShowRoleTips() neu
-- ausgerechnet, damit ein zwischenzeitlicher Fensterresize beim naechsten
-- Rollen-/Bosswechsel korrekt uebernommen wird.
--
-- Zwei getrennte Breiten noetig: "roleBar" haengt direkt an f (kein
-- ScrollFrame-Kind) und darf die volle Panelbreite nutzen. "LeftChild"/
-- "TipText" stecken dagegen im ScrollFrame "body", das -26px fuer die
-- Scrollleiste reserviert (siehe body:SetPoint BOTTOMRIGHT) - ohne den
-- Abzug waere der Scroll-Child breiter als sein sichtbarer Viewport und
-- der rechte Rand der Faehigkeiten-Zeilen wuerde abgeschnitten.
--------------------------------------------------

local function UpdateBodyWidth(f)
    local fullW = math.max(560, WeintCodex.ContentPanel:GetWidth())
    local bodyW = math.max(560, WeintCodex.ContentPanel:GetWidth() - 26)

    f.LeftChild:SetWidth(bodyW)
    f.TipText:SetWidth(bodyW - 40)

    local segW = fullW / #f.RoleBtns
    f.RoleDividers = f.RoleDividers or {}
    for i, rb in ipairs(f.RoleBtns) do
        rb:SetWidth(segW)
        rb:ClearAllPoints()
        rb:SetPoint("TOPLEFT", f.RoleBar, "TOPLEFT", (i - 1) * segW, 0)

        if i > 1 then
            local div = f.RoleDividers[i]
            if not div then
                div = f.RoleBar:CreateTexture(nil, "OVERLAY")
                div:SetWidth(1)
                div:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])
                f.RoleDividers[i] = div
            end
            div:ClearAllPoints()
            div:SetPoint("TOP",    f.RoleBar, "TOPLEFT", (i - 1) * segW, 0)
            div:SetPoint("BOTTOM", f.RoleBar, "BOTTOMLEFT", (i - 1) * segW, 0)
        end
    end

    return bodyW
end

--------------------------------------------------
-- Aufstellungsbild gross anzeigen (Lightbox)
--
-- Abgedunkelter Overlay ueber dem ContentPanel, analog zum Sync-Reload-
-- Overlay in modules/dialog.lua (Create()/Show()) - hier mit Bild statt
-- Text/Buttons. An ContentPanel statt MainFrame geparkt, damit der
-- bestehende Tab-Wechsel-Cleanup (ClearContentPanel() in
-- core/navigation.lua) ihn automatisch mit ausblendet, ohne dass
-- navigation.lua etwas von dieser Lightbox wissen muss. Wird einmalig
-- gebaut und danach nur noch mit neuer Textur/Groesse wiederverwendet.
--------------------------------------------------

local DEFAULT_POS_ASPECT = 9 / 16

local positioningOverlay, positioningImageBox, positioningImageTexture

local function CreatePositioningLightbox()
    if positioningOverlay then return end

    local parent = WeintCodex.ContentPanel
    if not parent then return end

    positioningOverlay = CreateFrame("Frame", nil, parent)
    positioningOverlay:SetAllPoints(parent)
    positioningOverlay:SetFrameLevel(parent:GetFrameLevel() + 100)
    positioningOverlay:EnableMouse(true)
    WeintCodex.SetSolidBg(positioningOverlay, 0, 0, 0, 0.75)
    positioningOverlay:Hide()
    positioningOverlay:SetScript("OnMouseUp", function() positioningOverlay:Hide() end)

    positioningImageBox = CreateFrame("Frame", nil, positioningOverlay)
    positioningImageBox:SetPoint("CENTER")
    WeintCodex.SetSolidBg(positioningImageBox, C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
    WeintCodex.DrawSlimBorder(positioningImageBox, "hairline")
    positioningImageBox:EnableMouse(true)
    positioningImageBox:SetScript("OnMouseUp", function() end)

    positioningImageTexture = positioningImageBox:CreateTexture(nil, "ARTWORK")
    positioningImageTexture:SetAllPoints(positioningImageBox)
    positioningImageTexture:SetTexCoord(0, 1, 0, 1)
end

local function ShowPositioningLightbox(img)
    if not img or not img.image then return end

    CreatePositioningLightbox()
    if not positioningOverlay then return end

    local aspect = DEFAULT_POS_ASPECT
    if img.width and img.height and img.width > 0 then
        aspect = img.height / img.width
    end

    local maxW = WeintCodex.ContentPanel:GetWidth() * 0.8
    local maxH = WeintCodex.ContentPanel:GetHeight() * 0.8

    local imgW, imgH = maxW, maxW * aspect
    if imgH > maxH then
        imgH = maxH
        imgW = imgH / aspect
    end

    positioningImageBox:SetSize(math.floor(imgW), math.floor(imgH))
    positioningImageTexture:SetTexture("Interface\\AddOns\\WeintCodex\\" .. img.image)

    positioningOverlay:Show()
end

--------------------------------------------------
-- AUFSTELLUNG-Abschnitt (Positionierungsbilder) aufbauen
--
-- Optional - fehlt bei einem Boss "positioning.images" (bzw. ist leer),
-- wird der komplette Abschnitt versteckt und offY unveraendert
-- zurueckgegeben, damit die Faehigkeiten-Liste direkt danach nahtlos
-- anschliesst. Ein Boss kann mehrere Bilder haben (z.B. Galakras: zwei
-- Phasen) - die Vorschaubilder teilen sich dann eine Zeile mit fester
-- Gesamtbreite POS_ROW_W, jedes einzeln klickbar fuer die Grossansicht.
--------------------------------------------------

local POS_ROW_W = 280
local POS_GAP   = 8

local activePosImageBoxes = {}

local function BuildPositioningSection(f, positioning, offY)
    for _, box in ipairs(activePosImageBoxes) do
        box:Hide()
    end
    wipe(activePosImageBoxes)

    local images = positioning and positioning.images
    if not images or #images == 0 then
        f.PosHeader:Hide()
        f.PosLine:Hide()
        f.PosText:Hide()
        return offY
    end

    local lc = f.LeftChild

    f.PosHeader:Show()
    f.PosLine:Show()

    f.PosHeader:SetPoint("TOPLEFT", lc, "TOPLEFT", 20, offY)
    f.PosLine:SetPoint("TOPLEFT",  lc, "TOPLEFT",  20, offY - 16)
    f.PosLine:SetPoint("TOPRIGHT", lc, "TOPRIGHT", -20, offY - 16)

    local imagesOffY = offY - 24
    if positioning.text and positioning.text ~= "" then
        f.PosText:Show()
        f.PosText:ClearAllPoints()
        f.PosText:SetPoint("TOPLEFT", lc, "TOPLEFT", 20, imagesOffY)
        f.PosText:SetWidth(lc:GetWidth() - 40)
        f.PosText:SetText(positioning.text)
        imagesOffY = imagesOffY - f.PosText:GetStringHeight() - 12
    else
        f.PosText:Hide()
    end

    local n      = #images
    local thumbW = (POS_ROW_W - POS_GAP * (n - 1)) / n
    local thumbX = 20
    local rowH   = 0

    for _, img in ipairs(images) do
        local aspect = DEFAULT_POS_ASPECT
        if img.width and img.height and img.width > 0 then
            aspect = img.height / img.width
        end
        local thumbH = math.floor(thumbW * aspect)
        rowH = math.max(rowH, thumbH)

        local box = CreateFrame("Frame", nil, lc)
        WeintCodex.SetSolidBg(box, C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
        WeintCodex.DrawSlimBorder(box, "hairline")
        box:SetPoint("TOPLEFT", lc, "TOPLEFT", thumbX, imagesOffY)
        box:SetSize(thumbW, thumbH)

        local tex = box:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(box)
        tex:SetTexCoord(0, 1, 0, 1)
        tex:SetTexture("Interface\\AddOns\\WeintCodex\\" .. img.image)

        box:EnableMouse(true)
        box:SetScript("OnEnter", function(self)
            WeintCodex.DrawBorder(self, C.purple[1], C.purple[2], C.purple[3], 0.85, 1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Klicken zum Vergrößern")
            GameTooltip:Show()
        end)
        box:SetScript("OnLeave", function(self)
            WeintCodex.DrawSlimBorder(self, "hairline")
            GameTooltip:Hide()
        end)
        box:SetScript("OnMouseUp", function()
            ShowPositioningLightbox(img)
        end)

        table.insert(activePosImageBoxes, box)
        thumbX = thumbX + thumbW + POS_GAP
    end

    return imagesOffY - (rowH + 24)
end

--------------------------------------------------
-- Rebuild the ability rows in bodyChild
--------------------------------------------------

local activeAbilRows = {}

local function BuildAbilityRows(f, abilities, positioning)
    for _, row in ipairs(activeAbilRows) do
        row:Hide()
    end
    wipe(activeAbilRows)

    local lc   = f.LeftChild
    local tipH = math.max(f.TipText:GetStringHeight(), 24)

    local abilOffY = BuildPositioningSection(f, positioning, -(40 + tipH + 24))
    f.AbilHeader:SetPoint("TOPLEFT", lc, "TOPLEFT", 20, abilOffY)
    f.AbilLine:SetPoint("TOPLEFT",  lc, "TOPLEFT",  20, abilOffY - 16)
    f.AbilLine:SetPoint("TOPRIGHT", lc, "TOPRIGHT", -20, abilOffY - 16)

    if not abilities or #abilities == 0 then
        lc:SetHeight(math.abs(abilOffY) + 60)
        return
    end

    local rowY = abilOffY - 24
    for _, ab in ipairs(abilities) do
        local row = CreateFrame("Frame", nil, lc)
        row:SetHeight(50)
        row:SetPoint("TOPLEFT",  lc, "TOPLEFT",  20, rowY)
        row:SetPoint("TOPRIGHT", lc, "TOPRIGHT", -20, rowY)
        WeintCodex.SetSolidBg(row, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
        WeintCodex.DrawSlimBorder(row, "hairline")

        local iconBox = row:CreateTexture(nil, "ARTWORK")
        iconBox:SetSize(38, 38)
        iconBox:SetPoint("LEFT", row, "LEFT", 6, 0)

        if ab.spellID then
            local texture
            if C_Spell and C_Spell.GetSpellTexture then
                texture = C_Spell.GetSpellTexture(ab.spellID)
            else
                texture = select(3, GetSpellInfo(ab.spellID))
            end

            if texture then
                iconBox:SetTexture(texture)
            else
                iconBox:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end

            row:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(ab.spellID)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        else
            local ic = ab.color or {0.40, 0.40, 0.40}
            iconBox:SetColorTexture(ic[1], ic[2], ic[3], 0.85)
        end

        local abName = row:CreateFontString(nil, "OVERLAY")
        abName:SetFont(WeintCodex.Fonts.sans, 12, "")
        abName:SetPoint("TOPLEFT", row, "TOPLEFT", 52, -8)
        abName:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        abName:SetText(ab.name or "")

        local descRightPad = -10
        if ab.tag and ab.tag.label then
            local tagCol = C[ab.tag.color] or C.textDim
            local badge = CreateFrame("Frame", nil, row)
            badge:SetSize(52, 18)
            badge:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            WeintCodex.SetSolidBg(badge, tagCol[1], tagCol[2], tagCol[3], 0.15)
            WeintCodex.DrawBorder(badge, tagCol[1], tagCol[2], tagCol[3], 0.60, 1)

            local tagLbl = badge:CreateFontString(nil, "OVERLAY")
            tagLbl:SetAllPoints(badge)
            tagLbl:SetFont(WeintCodex.Fonts.sans, 8, "")
            tagLbl:SetJustifyH("CENTER")
            tagLbl:SetJustifyV("MIDDLE")
            tagLbl:SetTextColor(tagCol[1], tagCol[2], tagCol[3])
            tagLbl:SetText(string.upper(ab.tag.label))

            descRightPad = -68
        end

        local abDesc = row:CreateFontString(nil, "OVERLAY")
        abDesc:SetFont(WeintCodex.Fonts.sans, 11, "")
        abDesc:SetPoint("TOPLEFT", abName, "BOTTOMLEFT", 0, -3)
        abDesc:SetPoint("RIGHT", row, "RIGHT", descRightPad, 0)
        abDesc:SetJustifyH("LEFT")
        abDesc:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        abDesc:SetText(ab.desc or "")

        table.insert(activeAbilRows, row)
        rowY = rowY - 56
    end

    lc:SetHeight(math.abs(rowY) + 20)
end

--------------------------------------------------
-- Rollen-Farben & Labels
--------------------------------------------------

local ROLE_COLOR_NAME = { tank = "blue", healer = "green", dps = "red" }
local roleLabels = { tank = "Tank Guide", healer = "Heiler Guide", dps = "Schaden Guide" }

--------------------------------------------------
-- Encounter-Fortschritt (Sidebar-Status + Header-Balken)
--------------------------------------------------

local function FormatRelativeTime(timestamp)
    if type(timestamp) ~= "number" then return nil end
    local diff = time() - timestamp
    if diff < 0 then diff = 0 end
    if diff < 3600 then
        return "<1h"
    elseif diff < 86400 then
        return math.floor(diff / 3600) .. "h"
    else
        return math.floor(diff / 86400) .. "d"
    end
end

-- Prozent mit einer Nachkommastelle, deutsches Dezimalkomma (die
-- gesamte In-Game-Oberflaeche ist deutsch). Klammern noetig: gsub gibt
-- zwei Werte zurueck, die sonst in die Konkatenation laufen.
local function FormatPct1(value)
    return (string.format("%.1f", value):gsub("%.", ",")) .. "%"
end

local function BuildBossStatus(bossIndex)
    local et = WeintCodex.EncounterTracking
    local status = et and et.GetStatus(INSTANCE_NAME, bossIndex)

    if status and status.cleared then
        local rel = FormatRelativeTime(status.clearedAt)
        return { text = rel and ("Cleared · " .. rel) or "Cleared", color = "green" }
    end

    -- Offener Boss: Wipes und bester Versuch (niedrigste Boss-Rest-HP)
    -- als eine Zeile, jeder Teil nur wenn vorhanden - ein Platzhalter bei
    -- jedem unberuehrten Boss waere nur Rauschen.
    local parts = { "Offen" }

    if status and status.wipes and status.wipes > 0 then
        parts[#parts + 1] = status.wipes .. " Wipe" .. (status.wipes == 1 and "" or "s")
    end

    if status and type(status.bestTry) == "number" then
        parts[#parts + 1] = "Best " .. FormatPct1(status.bestTry)
    end

    return {
        text  = table.concat(parts, " · "),
        color = (#parts > 1) and "gold" or "textFaint",
    }
end

local function UpdateProgressHeader(f)
    if not (f and f.ProgressPct) then return end

    local et    = WeintCodex.EncounterTracking
    local total = #bossOrder
    local cleared = 0
    if et then
        for i = 1, total do
            local status = et.GetStatus(INSTANCE_NAME, i)
            if status and status.cleared then cleared = cleared + 1 end
        end
    end

    local pct = (total > 0) and (cleared / total) or 0
    local col = (total > 0 and cleared >= total) and C.green or C.purple

    f.ProgressPct:SetText(math.floor(pct * 100 + 0.5) .. "%")
    f.ProgressPct:SetTextColor(col[1], col[2], col[3])

    local trackW = f.ProgressTrackW or 120
    if pct > 0.005 then
        f.ProgressFill:SetWidth(math.max(1, trackW * pct))
        f.ProgressFill:SetColorTexture(col[1], col[2], col[3], 1.0)
        f.ProgressFill:Show()
    else
        f.ProgressFill:Hide()
    end
end

--------------------------------------------------
-- Boss-Tipps im Raid-/Gruppenchat ansagen
--------------------------------------------------

-- Vom Bot gelieferte Rollen-Tipps sind gildeninterne Taktiknotizen und
-- haengen an der eigenen Discord-Rolle (siehe core/access.lua). Die
-- statischen Guides aus data/BossData.lua bleiben immer offen.
local function BotTips()
    if WeintCodex.Access and not WeintCodex.Access.Can("bossguides.tips") then
        return nil
    end
    return WeintCodex.SavedData and WeintCodex.SavedData.bossData
end

local function AnnounceBossTips(bossName, roleKey)
    local data = WeintCodex_BossData and WeintCodex_BossData[bossName]
    local savedData = BotTips()
    if savedData and savedData[bossName] then data = savedData[bossName] end

    if not data then
        print(WeintCodex.ColorText("danger", "[WeintCodex]") .. " Keine Daten für " .. bossName .. ".")
        return
    end

    local lines = data.kurz and data.kurz[roleKey]
    if not lines or #lines == 0 then
        lines = data[roleKey]
    end
    if not lines or #lines == 0 then
        print(WeintCodex.ColorText("danger", "[WeintCodex]") .. " Keine Tipps zum Ansagen vorhanden.")
        return
    end

    local channel = "SAY"
    if IsInRaid() then
        channel = "RAID"
    elseif IsInGroup() then
        channel = "PARTY"
    end

    SendChatMessage(bossName .. " – " .. (roleLabels[roleKey] or "Guide"), channel)
    for _, line in ipairs(lines) do
        SendChatMessage(line, channel)
    end
end

--------------------------------------------------
-- Bossdaten auflösen
--
-- Ein per Bot importierter Guide ersetzt das komplette Boss-Objekt
-- (siehe sync.lua) - deshalb wird er nur bevorzugt, wenn er die
-- angefragte Rolle auch wirklich enthält.
--------------------------------------------------

local function ResolveBossData(bossName, roleKey)
    local data = WeintCodex_BossData and WeintCodex_BossData[bossName]

    local savedData = BotTips()
    if savedData and savedData[bossName] and savedData[bossName][roleKey] then
        data = savedData[bossName]
    end

    return data
end

--------------------------------------------------
-- BiS-Liste für den aktuellen Boss
--
-- Liefert die Blockdaten für den itemlist-Block des Inspectors:
-- Überschrift, Einträge und den passenden Leertext. Die eigentliche
-- Logik (Spec, Besitzprüfung) steckt in modules/bis.lua.
--------------------------------------------------

local function BuildBiSSection(bossName)
    local header = "BiS-Liste"
    local items  = {}
    local empty  = "BiS-Modul nicht geladen."

    if not WeintCodex.BiS then
        return header, items, empty
    end

    local specKey, specDisplay = WeintCodex.BiS.GetSpecKey()

    if not specKey then
        return header, items, "Spec nicht erkannt."
    end

    if specDisplay then
        header = "BiS · " .. specDisplay
    end

    local entries, hasSpecData = WeintCodex.BiS.GetForBoss(bossName, specKey)

    if #entries == 0 then
        if hasSpecData then
            empty = "Kein BiS-Item bei diesem Boss."
        else
            empty = "Keine BiS-Daten für diese Spec hinterlegt."
        end
        return header, items, empty
    end

    for _, entry in ipairs(entries) do
        local sub = entry.slot or ""

        if entry.note and entry.note ~= "" then
            sub = sub .. " · " .. entry.note
        end

        -- Andere Schwierigkeitsstufe angelegt: man hat das Item im
        -- Prinzip, das Upgrade lohnt sich aber noch.
        if entry.state == "variant" then
            sub = sub .. " · andere Stufe angelegt"
        end

        items[#items + 1] = {
            id       = entry.id,
            sublabel = sub,
            state    = entry.state,
        }
    end

    return header, items, empty
end

--------------------------------------------------
-- Notizen: zwei Spalten pro Boss
--
-- SavedData.bossNotes[boss] war bisher ein reiner String (eine Spalte).
-- Bestehende Notizen wandern beim ersten Schreiben nach dem Update in
-- Spalte 1, statt verloren zu gehen.
--------------------------------------------------

local function GetBossNoteColumn(bossName, col)
    local raw = WeintCodex.SavedData and WeintCodex.SavedData.bossNotes
        and WeintCodex.SavedData.bossNotes[bossName]
    if not raw then return "" end
    if type(raw) == "string" then
        return (col == 2) and "" or raw
    end
    return raw["col" .. col] or ""
end

local function SetBossNoteColumn(bossName, col, text)
    if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
    if not WeintCodex.SavedData.bossNotes then WeintCodex.SavedData.bossNotes = {} end

    local raw = WeintCodex.SavedData.bossNotes[bossName]
    local tbl = (type(raw) == "table") and raw or { col1 = raw or "" }
    tbl["col" .. col] = text
    WeintCodex.SavedData.bossNotes[bossName] = tbl
end

-- Ein- oder zweispaltig ist eine Vorliebe, kein Bossmerkmal: die
-- Einstellung gilt deshalb fuer alle Bosse gemeinsam.
local function GetNotesLayout()
    local mode = WeintCodex.SavedData and WeintCodex.SavedData.bossNotesLayout
    return (mode == "columns") and "columns" or "single"
end

local function SetNotesLayout(mode)
    if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
    WeintCodex.SavedData.bossNotesLayout = (mode == "columns") and "columns" or "single"
end

-- Beim Wechsel auf eine Spalte wandert Spalte 2 ans Ende von Spalte 1.
-- Sonst laege sie unerreichbar im SavedData und der Nutzer haette den
-- Eindruck, seine Notizen seien weg.
local function MergeBossNoteColumns(bossName)
    local second = GetBossNoteColumn(bossName, 2)
    if second == "" then return end

    local first = GetBossNoteColumn(bossName, 1)
    SetBossNoteColumn(bossName, 1, (first ~= "") and (first .. "\n\n" .. second) or second)
    SetBossNoteColumn(bossName, 2, "")
end

--------------------------------------------------
-- Inspector (rechte Spalte) aufbauen
--
-- Getrennt von ShowRoleTips, damit die Spalte auch allein neu gebaut
-- werden kann - z.B. wenn ein BiS-Item an- oder abgelegt wurde.
--------------------------------------------------

local function BuildInspector(data, roleKey)
    local kurzList  = data and data.kurz and data.kurz[roleKey]
    local kurzItems = {}
    if kurzList then
        for _, text in ipairs(kurzList) do
            kurzItems[#kurzItems + 1] = { label = text }
        end
    end
    if #kurzItems == 0 then
        kurzItems[1] = { label = "Keine Kurzfassung hinterlegt.", labelColor = "textFaint" }
    end

    -- Lokale Kopie: die Closures unten dürfen nicht auf einen späteren
    -- Bosswechsel zeigen.
    local bossForNotes = selectedBoss

    local bisHeader, bisItems, bisEmpty = BuildBiSSection(bossForNotes)

    WeintCodex.Navigation.SetInspector({
        { type = "header", text = "Kurz & Knapp" },
        { type = "checklist", items = kurzItems },
        { type = "divider" },
        { type = "notes", title = "Notizen", height = 210, columns = true,
            placeholder = { "Ablauf, Aufstellung, eigene Aufgaben …", "Cooldowns, Zuweisungen …" },
            get = function(col) return GetBossNoteColumn(bossForNotes, col) end,
            set = function(col, text) SetBossNoteColumn(bossForNotes, col, text) end,
            getLayout    = GetNotesLayout,
            setLayout    = SetNotesLayout,
            mergeColumns = function() MergeBossNoteColumns(bossForNotes) end,
            shouldAsk    = function()
                return not (WeintCodex.SavedData and WeintCodex.SavedData.bossNotesAsked)
            end,
            markAsked    = function()
                if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
                WeintCodex.SavedData.bossNotesAsked = true
            end,
        },
        { type = "divider" },
        { type = "header", text = bisHeader },
        -- "fill" nimmt den Restplatz; reserveBelow hält den Ansage-Button
        -- frei, der als letzter Block folgt.
        { type = "itemlist", height = "fill", reserveBelow = 48, minHeight = 90,
            items = bisItems, empty = bisEmpty },
        { type = "button", style = "primary", label = "Im Raid ansagen", onClick = function()
            AnnounceBossTips(bossForNotes, roleKey)
        end },
    })
end

--------------------------------------------------
-- ShowRoleTips
--------------------------------------------------

function ShowRoleTips(roleKey)
    selectedRole = roleKey
    local f = guideFrame
    if not f then return end

    UpdateBodyWidth(f)

    local data = ResolveBossData(selectedBoss, roleKey)

    -- Rollen-Button-Highlight
    for _, rb in ipairs(f.RoleBtns) do
        local rd  = rb._rd
        local col = C[rd.colorName]
        if rb._key == roleKey then
            rb._bg:SetColorTexture(col[1] * 0.30, col[2] * 0.30, col[3] * 0.30, 1.0)
            rb._label:SetTextColor(col[1], col[2], col[3])
        else
            rb._bg:SetColorTexture(C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
            rb._label:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        end
    end

    f.GuideHeader:SetText(WeintCodex.ColorText("textFaint", string.upper(roleLabels[roleKey] or "GUIDE")))

    local rc = C[ROLE_COLOR_NAME[roleKey] or "purple"]
    f.GuideLine:SetColorTexture(rc[1], rc[2], rc[3], 0.60)

    if not data then
        f.TipText:SetText(WeintCodex.ColorText("textFaint", "Keine Daten für diesen Boss.\nNutze den Import-Tab um Guides zu laden."))
    else
        local tips = data[roleKey]
        if not tips or #tips == 0 then
            f.TipText:SetText(WeintCodex.ColorText("textFaint", "Keine Tipps für diese Rolle eingetragen."))
        else
            local lines = {}
            for _, tip in ipairs(tips) do
                lines[#lines + 1] = WeintCodex.ColorText("purple", "• ") .. tip
            end
            f.TipText:SetText(table.concat(lines, "\n"))
        end
    end

    local abilities  = data and data.abilities
    local positioning = data and data.positioning
    BuildAbilityRows(f, abilities, positioning)

    -- Inspector: Kurz & Knapp + Notizen + BiS-Liste + Ansage
    BuildInspector(data, roleKey)
end

--------------------------------------------------
-- Nur die rechte Spalte neu aufbauen
--
-- Aufgerufen aus modules/bis.lua, wenn sich Ausrüstung oder Spec
-- ändert: die Haken in der BiS-Liste sollen sofort umspringen, ohne
-- Guide-Text und Fähigkeitenliste neu zu bauen.
--------------------------------------------------

function WeintCodex.BossGuides.RefreshInspector()
    if not guideFrame or not guideFrame:IsShown() then return end
    if not selectedBoss or not selectedRole then return end

    BuildInspector(ResolveBossData(selectedBoss, selectedRole), selectedRole)
end

--------------------------------------------------
-- ShowBoss
--------------------------------------------------

local function ShowBoss(bossName)
    selectedBoss = bossName
    local f = CreateGuideFrame()

    if positioningOverlay then positioningOverlay:Hide() end

    local data = WeintCodex_BossData and WeintCodex_BossData[bossName]

    f.BossName:SetText(bossName)
    f.InstanceStr:SetText(WeintCodex.ColorText("textFaint", string.upper(data and data.instance or "Belagerung von Orgrimmar")))

    if data and data.quote then
        f.QuoteStr:SetText(data.quote)
    else
        f.QuoteStr:SetText("")
    end

    if data and data.portrait then
        f.PortraitTexture:SetTexture("Interface\\AddOns\\WeintCodex\\" .. data.portrait)
    else
        f.PortraitTexture:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
    end

    WeintCodex.SetBreadcrumb("Bossguides", data and data.instance or "Schlacht um Orgrimmar", bossName)

    if WeintCodex.EncounterTracking then
        local bossIndex
        for i, bossInfo in ipairs(bossOrder) do
            if bossInfo.name == bossName then bossIndex = i break end
        end
        if bossIndex then
            WeintCodex.EncounterTracking.SetActiveContext(INSTANCE_NAME, INSTANCE_MATCH, bossIndex, bossName)
        end
    end

    selectedRole = nil
    local autoRole = GetPlayerRole()
    ShowRoleTips(autoRole or "tank")

    -- Header-Fortschritt mitziehen: Show() baut ihn nur einmal beim
    -- Betreten des Tabs, ein Bosswechsel/Kill danach sonst nicht.
    UpdateProgressHeader(f)
end

--------------------------------------------------
-- Fortschritt aktualisieren, ohne die Seite neu aufzubauen
-- (Hook aus modules/encounter_tracking.lua).
--------------------------------------------------

function WeintCodex.BossGuides.RefreshProgress()
    -- Nur wenn der Bossguide-Tab wirklich sichtbar ist - sonst wuerden
    -- wir in die Sidebar eines fremden Tabs schreiben.
    if not (guideFrame and guideFrame:IsVisible()) then return end

    if WeintCodex.Navigation and WeintCodex.Navigation.UpdateSidebarStatus then
        for i = 1, #bossOrder do
            WeintCodex.Navigation.UpdateSidebarStatus(i, BuildBossStatus(i))
        end
    end
    UpdateProgressHeader(guideFrame)
end

if WeintCodex.EncounterTracking then
    WeintCodex.EncounterTracking.onChanged = function()
        WeintCodex.BossGuides.RefreshProgress()
    end
end

--------------------------------------------------
-- Modul anzeigen
--------------------------------------------------

function WeintCodex.BossGuides.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    local f = CreateGuideFrame()
    f:Show()
    for _, rb in ipairs(f.RoleBtns) do rb:Show() end

    if WeintCodex.EncounterTracking then
        WeintCodex.EncounterTracking.RefreshFromLockout(INSTANCE_NAME, INSTANCE_MATCH)
    end

    local sidebarItems = {}
    for i, bossInfo in ipairs(bossOrder) do
        local bn = bossInfo.name
        local data = WeintCodex_BossData and WeintCodex_BossData[bn]

        sidebarItems[#sidebarItems + 1] = {
            label    = bn,
            portrait = data and data.portrait,
            status   = BuildBossStatus(i),
            onClick  = function() ShowBoss(bn) end,
        }
        end

    WeintCodex.Navigation.BuildSidebar("Schlacht um Orgrimmar", sidebarItems)
    UpdateProgressHeader(f)

    if selectedBoss then
        ShowBoss(selectedBoss)
    else
        ShowBoss(bossOrder[1].name)
    end
end

-- Direkteinstieg fuer die globale Suche (core/search.lua): merkt sich den
-- Zielboss, damit Show() ihn statt des ersten Bosses in der Liste anzeigt.
function WeintCodex.BossGuides.ShowBoss(bossName)
    selectedBoss = bossName
    WeintCodex.BossGuides.Show()
end
