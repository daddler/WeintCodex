--------------------------------------------------
-- WeintCodex :: Bossguides Module
-- Layout: Portrait | Name+Role-Tabs | Quote
--         Left: Guide-Tipps + Fähigkeiten
--         Right: Kurz & Knapp + Notizen
--------------------------------------------------

WeintCodex.BossGuides = {}

local C            = WeintCodex.Colors
local selectedBoss = nil
local selectedRole = nil
local guideFrame   = nil

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
-- Guide Frame erstellen
--   Content panel: ~888 x ~548 px
--   Layout:
--     Top fixed (130px): Portrait + Name/Instance + Role-Buttons
--     Quote strip (30px)
--     Divider
--     Body: left col (560px) | right col (290px)
--       Left:  GUIDE section + FÄHIGKEITEN section
--       Right: KURZ & KNAPP card + NOTIZEN card
--------------------------------------------------

local function CreateGuideFrame()
    if guideFrame then return guideFrame end

    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)

    -- ------------------------------------------------
    -- TOP HEADER (fixed, 118px)
    -- ------------------------------------------------

    local topBar = CreateFrame("Frame", nil, f)
    topBar:SetHeight(118)
    topBar:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    SetSolidBg(topBar, C.bgMid[1], C.bgMid[2], C.bgMid[3], 0.60)

    -- Boss portrait box
    local portraitBox = CreateFrame("Frame", nil, topBar)
    portraitBox:SetSize(86, 86)
    portraitBox:SetPoint("TOPLEFT", topBar, "TOPLEFT", 16, -16)
    SetSolidBg(portraitBox, 0.08, 0.05, 0.18, 1.0)
    DrawBorder(portraitBox, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80, 1)

    local portraitTexture = portraitBox:CreateTexture(nil, "ARTWORK")
    portraitTexture:SetAllPoints(portraitBox)
    portraitTexture:SetTexCoord(0, 1, 0, 1)

    f.PortraitTexture = portraitTexture

    -- Boss name
    local bossNameStr = topBar:CreateFontString(nil, "OVERLAY")
    bossNameStr:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    bossNameStr:SetPoint("TOPLEFT", portraitBox, "TOPRIGHT", 14, -6)
    bossNameStr:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    f.BossName = bossNameStr

    -- Instance badge
    local instanceStr = topBar:CreateFontString(nil, "OVERLAY")
    instanceStr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    instanceStr:SetPoint("TOPLEFT", bossNameStr, "BOTTOMLEFT", 0, -3)
    instanceStr:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    instanceStr:SetText("|cff4B4060—|r")
    f.InstanceStr = instanceStr

    -- Role Buttons (top right of header)
    local roleDefs = {
        { key = "tank",   label = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:0:19:22:41|t Tank",    cr = C.blue[1],  cg = C.blue[2],  cb = C.blue[3]  },
        { key = "healer", label = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:1:20|t Heiler",   cr = C.green[1], cg = C.green[2], cb = C.green[3] },
        { key = "dps",    label = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:16:16:0:0:64:64:20:39:22:41|t Schaden",  cr = C.red[1],   cg = C.red[2],   cb = C.red[3]   },
    }

    local roleBtns = {}
    local rX = -10
    for i = #roleDefs, 1, -1 do
        local rd = roleDefs[i]
        local rb = CreateFrame("Button", nil, topBar)
        rb:SetSize(118, 36)
        rb:SetPoint("TOPRIGHT", topBar, "TOPRIGHT", rX, -14)

        local rbg = rb:CreateTexture(nil, "BACKGROUND")
        rbg:SetAllPoints(rb)
        rbg:SetColorTexture(0.08, 0.05, 0.18, 0.90)
        rb._bg = rbg

        DrawBorder(rb, rd.cr, rd.cg, rd.cb, 0.50, 1)

        local rlbl = rb:CreateFontString(nil, "OVERLAY")
        rlbl:SetAllPoints(rb)
        rlbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        rlbl:SetText(rd.label)
        rlbl:SetTextColor(rd.cr * 0.65, rd.cg * 0.65, rd.cb * 0.65)
        rb._label = rlbl
        rb._rd    = rd

        rb:SetScript("OnEnter", function(self)
            if selectedRole ~= rd.key then
                self._bg:SetColorTexture(rd.cr * 0.25, rd.cg * 0.25, rd.cb * 0.25, 0.80)
            end
        end)
        rb:SetScript("OnLeave", function(self)
            if selectedRole ~= rd.key then
                self._bg:SetColorTexture(0.08, 0.05, 0.18, 0.90)
            end
        end)

        rb:SetScript("OnClick", function()
        ShowRoleTips(rd.key)
        end)

        table.insert(roleBtns, rb)
        rb._key = rd.key
        rX = rX - 124
    end

    f.RoleBtns = roleBtns

    -- Top bar bottom divider
    local topDiv = topBar:CreateTexture(nil, "OVERLAY")
    topDiv:SetSize(2000, 1)
    topDiv:SetPoint("BOTTOMLEFT", topBar, "BOTTOMLEFT", 0, 0)
    topDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50)

    -- ------------------------------------------------
    -- QUOTE STRIP (fixed, 34px)
    -- ------------------------------------------------

    local quoteBar = CreateFrame("Frame", nil, f)
    quoteBar:SetHeight(34)
    quoteBar:SetPoint("TOPLEFT",  topBar, "BOTTOMLEFT",  0, 0)
    quoteBar:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, 0)
    SetSolidBg(quoteBar, C.bgDark[1], C.bgDark[2], C.bgDark[3], 0.50)

    local quoteStr = quoteBar:CreateFontString(nil, "OVERLAY")
    quoteStr:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    quoteStr:SetPoint("LEFT", quoteBar, "LEFT", 16, 0)
    quoteStr:SetWidth(700)
    quoteStr:SetJustifyH("LEFT")
    quoteStr:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    quoteStr:SetText("")
    f.QuoteStr = quoteStr

    local quoteDiv = quoteBar:CreateTexture(nil, "OVERLAY")
    quoteDiv:SetSize(2000, 1)
    quoteDiv:SetPoint("BOTTOMLEFT", quoteBar, "BOTTOMLEFT", 0, 0)
    quoteDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.30)

    -- ------------------------------------------------
    -- BODY (two columns below quote)
    -- ------------------------------------------------

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT",     quoteBar,  "BOTTOMLEFT",  0,  0)
    body:SetPoint("BOTTOMRIGHT", f,         "BOTTOMRIGHT", 0,  0)

    -- LEFT COLUMN (scrollable content)
    local LEFT_W = 570

    local leftCol = CreateFrame("ScrollFrame", nil, body, "UIPanelScrollFrameTemplate")
    leftCol:SetPoint("TOPLEFT",    body, "TOPLEFT",    0, -6)
    leftCol:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 0,  0)
    leftCol:SetWidth(LEFT_W - 14)

    local leftChild = CreateFrame("Frame", nil, leftCol)
    leftChild:SetWidth(LEFT_W - 30)
    leftChild:SetHeight(1)
    leftCol:SetScrollChild(leftChild)
    f.LeftChild = leftChild

    -- RIGHT COLUMN (fixed)
    local rightCol = CreateFrame("Frame", nil, body)
    rightCol:SetPoint("TOPLEFT",     body, "TOPLEFT",     LEFT_W + 4,  -6)
    rightCol:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -6,           0)

    -- ------------------------------------------------
    -- LEFT: Guide section header
    -- ------------------------------------------------

    local guideHeader = leftChild:CreateFontString(nil, "OVERLAY")
    guideHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    guideHeader:SetPoint("TOPLEFT", leftChild, "TOPLEFT", 10, -8)
    guideHeader:SetText("|cff4B8FC4TANK GUIDE|r")
    f.GuideHeader = guideHeader

    local guideLine = leftChild:CreateTexture(nil, "OVERLAY")
    guideLine:SetHeight(1)
    guideLine:SetPoint("TOPLEFT",  leftChild, "TOPLEFT",  10, -22)
    guideLine:SetPoint("TOPRIGHT", leftChild, "TOPRIGHT", -10, -22)
    guideLine:SetColorTexture(C.blue[1], C.blue[2], C.blue[3], 0.40)
    f.GuideLine = guideLine

    -- Tip text
    local tipText = leftChild:CreateFontString(nil, "OVERLAY")
    tipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    tipText:SetPoint("TOPLEFT", leftChild, "TOPLEFT", 10, -30)
    tipText:SetWidth(LEFT_W - 46)
    tipText:SetJustifyH("LEFT")
    tipText:SetSpacing(5)
    tipText:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    tipText:SetText("")
    f.TipText = tipText

    -- ABILITIES section header
    local abilHeader = leftChild:CreateFontString(nil, "OVERLAY")
    abilHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    abilHeader:SetPoint("TOPLEFT", leftChild, "TOPLEFT", 10, -180)
    abilHeader:SetText("|cff9B6BFFWICHTIGE FÄHIGKEITEN|r")
    f.AbilHeader = abilHeader

    local abilLine = leftChild:CreateTexture(nil, "OVERLAY")
    abilLine:SetHeight(1)
    abilLine:SetPoint("TOPLEFT",  leftChild, "TOPLEFT",  10, -194)
    abilLine:SetPoint("TOPRIGHT", leftChild, "TOPRIGHT", -10, -194)
    abilLine:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.40)
    f.AbilLine = abilLine

    -- Ability rows container (dynamic)
    f.AbilContainer = leftChild
    f.AbilStartY    = -200

    -- ------------------------------------------------
    -- RIGHT: Kurz & Knapp card
    -- ------------------------------------------------

    local kurzCard = CreateFrame("Frame", nil, rightCol)
    kurzCard:SetPoint("TOPLEFT",  rightCol, "TOPLEFT",  0,    0)
    kurzCard:SetPoint("TOPRIGHT", rightCol, "TOPRIGHT", -2,   0)
    kurzCard:SetHeight(220)
    SetSolidBg(kurzCard, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
    DrawBorder(kurzCard, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40, 1)

    local kurzTitle = kurzCard:CreateFontString(nil, "OVERLAY")
    kurzTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    kurzTitle:SetPoint("TOPLEFT", kurzCard, "TOPLEFT", 10, -10)
    kurzTitle:SetText("|cffA0A0C0KURZ & KNAPP|r")

    local kurzDiv = kurzCard:CreateTexture(nil, "OVERLAY")
    kurzDiv:SetHeight(1)
    kurzDiv:SetPoint("TOPLEFT",  kurzCard, "TOPLEFT",  6,  -24)
    kurzDiv:SetPoint("TOPRIGHT", kurzCard, "TOPRIGHT", -6, -24)
    kurzDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40)

    -- Kurz items (dynamic)
    f.KurzCard  = kurzCard
    f.KurzItems = {}

    for i = 1, 6 do
        local row = CreateFrame("Frame", nil, kurzCard)
        row:SetHeight(26)
        row:SetPoint("TOPLEFT",  kurzCard, "TOPLEFT",  6, -24 - (i - 1) * 28)
        row:SetPoint("TOPRIGHT", kurzCard, "TOPRIGHT", -6, -24 - (i - 1) * 28)

        local roleIcon = row:CreateTexture(nil, "OVERLAY")
        roleIcon:SetSize(16, 16)
        roleIcon:SetPoint("LEFT", row, "LEFT", 2, 0)
        roleIcon:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.60)
        row._icon = roleIcon

        local rowLbl = row:CreateFontString(nil, "OVERLAY")
        rowLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        rowLbl:SetPoint("LEFT", row, "LEFT", 24, 0)
        rowLbl:SetWidth(200)
        rowLbl:SetJustifyH("LEFT")
        rowLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        rowLbl:SetText("")
        row._lbl = rowLbl

        row:Hide()
        f.KurzItems[i] = row
    end

    -- ------------------------------------------------
    -- RIGHT: Notizen card
    -- ------------------------------------------------

    local notizCard = CreateFrame("Frame", nil, rightCol)
    notizCard:SetPoint("TOPLEFT",    kurzCard, "BOTTOMLEFT",  0, -8)
    notizCard:SetPoint("TOPRIGHT",   kurzCard, "BOTTOMRIGHT", 0, -8)
    notizCard:SetPoint("BOTTOMRIGHT", rightCol, "BOTTOMRIGHT", -2, -6)
    SetSolidBg(notizCard, C.bgCard[1], C.bgCard[2], C.bgCard[3], 1.0)
    DrawBorder(notizCard, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40, 1)

    local notizTitle = notizCard:CreateFontString(nil, "OVERLAY")
    notizTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    notizTitle:SetPoint("TOPLEFT", notizCard, "TOPLEFT", 10, -10)
    notizTitle:SetText("|cffA0A0C0NOTIZEN|r")

    local notizDiv = notizCard:CreateTexture(nil, "OVERLAY")
    notizDiv:SetHeight(1)
    notizDiv:SetPoint("TOPLEFT",  notizCard, "TOPLEFT",  6,  -24)
    notizDiv:SetPoint("TOPRIGHT", notizCard, "TOPRIGHT", -6, -24)
    notizDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40)

    local notizBg = CreateFrame("Frame", nil, notizCard)
    notizBg:SetPoint("TOPLEFT",     notizCard, "TOPLEFT",     6,  -28)
    notizBg:SetPoint("BOTTOMRIGHT", notizCard, "BOTTOMRIGHT", -6, -6)
    SetSolidBg(notizBg, 0.04, 0.02, 0.10, 0.80)
    DrawBorder(notizBg, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40, 1)

    local notizBox = CreateFrame("EditBox", nil, notizBg)
    notizBox:SetPoint("TOPLEFT",     notizBg, "TOPLEFT",     4,  -4)
    notizBox:SetPoint("BOTTOMRIGHT", notizBg, "BOTTOMRIGHT", -4,  4)
    notizBox:SetMultiLine(true)
    notizBox:SetMaxLetters(0)
    notizBox:SetAutoFocus(false)
    notizBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    notizBox:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    notizBox:SetTextInsets(4, 4, 4, 4)

    local placeholder = notizBg:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    placeholder:SetPoint("TOPLEFT", notizBg, "TOPLEFT", 6, -6)
    placeholder:SetText("|cff3B2D60Eigene Notizen zu diesem Boss...|r")
    placeholder:SetWidth(220)
    placeholder:SetJustifyH("LEFT")

    notizBox:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= "" then
            placeholder:Hide()
        else
            placeholder:Show()
        end
        -- Persist
        if selectedBoss then
            if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
            if not WeintCodex.SavedData.bossNotes then WeintCodex.SavedData.bossNotes = {} end
            WeintCodex.SavedData.bossNotes[selectedBoss] = self:GetText()
        end
    end)
    notizBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    f.NotizBox   = notizBox
    f.NotizPlaceholder = placeholder

    guideFrame = f
    return f
end

--------------------------------------------------
-- Rebuild the ability rows in leftChild
--------------------------------------------------

local activeAbilRows = {}

local function BuildAbilityRows(f, abilities)
    for _, row in ipairs(activeAbilRows) do
        row:Hide()
    end
    wipe(activeAbilRows)

    if not abilities or #abilities == 0 then
        f.AbilHeader:SetPoint("TOPLEFT", f.TipText, "BOTTOMLEFT", 0, -14)
        f.AbilLine:SetPoint("TOPLEFT",  f.TipText, "BOTTOMLEFT",  0, -28)
        f.AbilLine:SetPoint("TOPRIGHT", f.LeftChild, "TOPRIGHT", -10, -28)
        f.LeftChild:SetHeight(f.TipText:GetStringHeight() + 80)
        return
    end

    local lc       = f.LeftChild
    local tipH     = math.max(f.TipText:GetStringHeight(), 30)

    -- Reposition ability header below tips
    local abilOffY = -(tipH + 14 + 30)
    f.AbilHeader:SetPoint("TOPLEFT", lc, "TOPLEFT", 10, abilOffY)
    f.AbilLine:SetPoint("TOPLEFT",  lc, "TOPLEFT",  10, abilOffY - 14)
    f.AbilLine:SetPoint("TOPRIGHT", lc, "TOPRIGHT", -10, abilOffY - 14)

    local rowY = abilOffY - 22
    for _, ab in ipairs(abilities) do
        local row = CreateFrame("Frame", nil, lc)
        row:SetHeight(46)
        row:SetPoint("TOPLEFT",  lc, "TOPLEFT",  10, rowY)
        row:SetPoint("TOPRIGHT", lc, "TOPRIGHT", -10, rowY)
        SetSolidBg(row, C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.60)

        local iconBox = row:CreateTexture(nil, "ARTWORK")
        iconBox:SetSize(36, 36)
        iconBox:SetPoint("LEFT", row, "LEFT", 4, 0)

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
                            else
                                local ic = ab.color or {0.40, 0.40, 0.60}
                                iconBox:SetColorTexture(ic[1], ic[2], ic[3], 0.85)
                                end
                                if ab.spellID then
                                    row:SetScript("OnEnter", function(self)
                                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                    GameTooltip:SetSpellByID(ab.spellID)
                                    GameTooltip:Show()
                                    end)

                                    row:SetScript("OnLeave", function()
                                    GameTooltip:Hide()
                                    end)
                                    end

        local abName = row:CreateFontString(nil, "OVERLAY")
        abName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        abName:SetPoint("TOPLEFT", row, "TOPLEFT", 48, -6)
        abName:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        abName:SetText(ab.name or "")

        local abDesc = row:CreateFontString(nil, "OVERLAY")
        abDesc:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        abDesc:SetPoint("TOPLEFT", abName, "BOTTOMLEFT", 0, -2)
        abDesc:SetWidth(490)
        abDesc:SetJustifyH("LEFT")
        abDesc:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        abDesc:SetText(ab.desc or "")

        table.insert(activeAbilRows, row)
        rowY = rowY - 52
    end

    local totalH = math.abs(rowY) + 20
    lc:SetHeight(math.max(totalH, 400))
end

--------------------------------------------------
-- Update Kurz & Knapp panel
--------------------------------------------------

local function UpdateKurz(f, kurzList)
    for _, item in ipairs(f.KurzItems) do
        item:Hide()
    end
    if not kurzList then return end

    for i, text in ipairs(kurzList) do
        local item = f.KurzItems[i]
        if not item then break end
        item._lbl:SetText("|cff8B8BB0•|r " .. text)
        item:Show()
    end
    f.KurzCard:SetHeight(36 + #kurzList * 28)
end

--------------------------------------------------
-- Role color definitions
--------------------------------------------------

local roleColors = {
    tank   = { C.blue[1],  C.blue[2],  C.blue[3]  },
    healer = { C.green[1], C.green[2], C.green[3] },
    dps    = { C.red[1],   C.red[2],   C.red[3]   },
}

local roleLabels = {
    tank   = "TANK GUIDE",
    healer = "HEILER GUIDE",
    dps    = "DPS GUIDE",
}

local roleBullets = {
    tank   = "|cff66ccff•|r ",
    healer = "|cff66ff88•|r ",
    dps    = "|cffff6655•|r ",
}

--------------------------------------------------
-- ShowRoleTips
--------------------------------------------------

function ShowRoleTips(roleKey)
    selectedRole = roleKey
    local f = guideFrame
    if not f then return end

    local data = WeintCodex_BossData and WeintCodex_BossData[selectedBoss]
    local savedData = WeintCodex.SavedData and WeintCodex.SavedData.bossData
    if savedData and savedData[selectedBoss] and savedData[selectedBoss][roleKey] then
        data = savedData[selectedBoss]
    end

    -- Role button highlight
    local rc = roleColors[roleKey]
    for _, rb in ipairs(f.RoleBtns) do
        if rb._key == roleKey then
            rb._bg:SetColorTexture(rc[1] * 0.22, rc[2] * 0.22, rc[3] * 0.22, 0.95)
            rb._label:SetTextColor(rc[1], rc[2], rc[3])
        else
            rb._bg:SetColorTexture(0.08, 0.05, 0.18, 0.90)
            local rd = rb._rd
            rb._label:SetTextColor(rd.cr * 0.55, rd.cg * 0.55, rd.cb * 0.55)
        end
    end

    -- Guide section header color
    local label = roleLabels[roleKey] or "GUIDE"
    local hexMap = {
        tank   = "|cff5AB8F8",
        healer = "|cff44EE77",
        dps    = "|cffFF6655",
    }
    local hex = hexMap[roleKey] or "|cffaaaaaa"
    f.GuideHeader:SetText(hex .. label .. "|r")

    -- Guide line color
    if rc then
        f.GuideLine:SetColorTexture(rc[1], rc[2], rc[3], 0.45)
    end

    -- Tip text
    if not data then
        f.TipText:SetText("|cff6B7280Keine Daten für diesen Boss.\nNutze den Import-Tab um Guides zu laden.|r")
    else
        local tips = data[roleKey]
        if not tips or #tips == 0 then
            f.TipText:SetText("|cff6B7280Keine Tipps für diese Rolle eingetragen.|r")
        else
            local bullet = roleBullets[roleKey] or "• "
            local lines  = {}
            for _, tip in ipairs(tips) do
                lines[#lines + 1] = bullet .. tip
            end
            f.TipText:SetText(table.concat(lines, "\n"))
        end
    end

    -- Abilities
    local abilities = data and data.abilities
    BuildAbilityRows(f, abilities)

    -- Kurz & Knapp
    local kurzList = data and data.kurz and data.kurz[roleKey]
    UpdateKurz(f, kurzList)
end

--------------------------------------------------
-- ShowBoss
--------------------------------------------------

local function ShowBoss(bossName)
    selectedBoss = bossName
    local f = CreateGuideFrame()

    local data = WeintCodex_BossData and WeintCodex_BossData[bossName]

    f.BossName:SetText(bossName)
    f.InstanceStr:SetText("|cff6B5090" .. (data and data.instance or "Belagerung von Orgrimmar") .. "|r")

    -- Quote
    if data and data.quote then
        f.QuoteStr:SetText("|cff5B4878" .. data.quote .. "|r")
    else
        f.QuoteStr:SetText("")
    end

    -- Portrait
    if data and data.portrait then
        f.PortraitTexture:SetTexture(
            "Interface\\AddOns\\WeintCodex\\" .. data.portrait
        )
        else
            f.PortraitTexture:SetColorTexture(0.20, 0.20, 0.40, 1.0)
            end

    -- Notizen
    local note = WeintCodex.SavedData and WeintCodex.SavedData.bossNotes and WeintCodex.SavedData.bossNotes[bossName] or ""
    f.NotizBox:SetText(note)
    if note == "" then
        f.NotizPlaceholder:Show()
    else
        f.NotizPlaceholder:Hide()
    end

    selectedRole = nil
    local autoRole = GetPlayerRole()
    ShowRoleTips(autoRole or "tank")
end

--------------------------------------------------
-- Modul anzeigen
--------------------------------------------------

function WeintCodex.BossGuides.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    local f = CreateGuideFrame()
    f:Show()

    local sidebarItems = {}
    for _, bossInfo in ipairs(bossOrder) do
        local bn = bossInfo.name
        local data = WeintCodex_BossData and WeintCodex_BossData[bn]

        sidebarItems[#sidebarItems + 1] = {
            label    = bn,
            portrait = data and data.portrait,
            onClick  = function() ShowBoss(bn) end,
        }
        end

    WeintCodex.Navigation.BuildSidebar("— SCHLACHT UM ORGRIMMAR —", sidebarItems)

    if selectedBoss then
        ShowBoss(selectedBoss)
    else
        ShowBoss(bossOrder[1].name)
    end
end
