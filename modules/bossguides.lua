--------------------------------------------------
-- WeintCodex :: Bossguides Module
-- Layout: Portrait | Name+Instanz | Zitat
--         Links:  Rollen-Tipps + Fähigkeiten (scrollbar)
--         Inspector: Kurz & Knapp + Notizen + Ansage
--------------------------------------------------

WeintCodex.BossGuides = {}

local C            = WeintCodex.Colors
local selectedBoss  = nil
local selectedRole  = nil
local guideFrame    = nil

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
--   Rollen-Umschalter: Titelleiste (Tank/Heiler/Schaden)
--   Body (scrollbar): GUIDE-Tipps + FÄHIGKEITEN-Liste
--   Inspector:       Kurz & Knapp + Notizen + "Im Raid ansagen"
--------------------------------------------------

local BODY_W = 560

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
    WeintCodex.SetSolidBg(portraitBox, C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
    WeintCodex.DrawSlimBorder(portraitBox, "hairline")

    local portraitTexture = portraitBox:CreateTexture(nil, "ARTWORK")
    portraitTexture:SetAllPoints(portraitBox)
    portraitTexture:SetTexCoord(0, 1, 0, 1)
    f.PortraitTexture = portraitTexture

    -- Encounter-Eyebrow + Boss-Name + Zitat
    local instanceStr = topBar:CreateFontString(nil, "OVERLAY")
    instanceStr:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    instanceStr:SetPoint("TOPLEFT", portraitBox, "TOPRIGHT", 16, -4)
    f.InstanceStr = instanceStr

    local bossNameStr = topBar:CreateFontString(nil, "OVERLAY")
    bossNameStr:SetFont("Fonts\\MORPHEUS.TTF", 23, "")
    bossNameStr:SetPoint("TOPLEFT", instanceStr, "BOTTOMLEFT", 0, -6)
    bossNameStr:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    f.BossName = bossNameStr

    local quoteStr = topBar:CreateFontString(nil, "OVERLAY")
    quoteStr:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    quoteStr:SetPoint("TOPLEFT", bossNameStr, "BOTTOMLEFT", 0, -8)
    quoteStr:SetPoint("RIGHT", topBar, "RIGHT", -20, 0)
    quoteStr:SetJustifyH("LEFT")
    quoteStr:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    f.QuoteStr = quoteStr

    -- ------------------------------------------------
    -- Rollen-Umschalter (Titelleiste, Segmented Control)
    -- ------------------------------------------------

    local roleDefs = {
        { key = "tank",   label = "Tank",    colorName = "blue"  },
        { key = "healer", label = "Heiler",  colorName = "green" },
        { key = "dps",    label = "Schaden", colorName = "red"   },
    }

    local roleBtns = {}
    local rX = 0
    for _, rd in ipairs(roleDefs) do
        local rb = CreateFrame("Button", nil, WeintCodex.TitleBarActions)
        rb:SetSize(74, 30)
        rb:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", rX, -11)

        local rbg = rb:CreateTexture(nil, "BACKGROUND")
        rbg:SetAllPoints(rb)
        rbg:SetColorTexture(C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
        rb._bg = rbg

        local rlbl = rb:CreateFontString(nil, "OVERLAY")
        rlbl:SetAllPoints(rb)
        rlbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
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
        rX = rX - 78
    end
    f.RoleBtns = roleBtns

    -- ------------------------------------------------
    -- BODY (scrollbar, einspaltig)
    -- ------------------------------------------------

    local body = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    body:SetPoint("TOPLEFT",     topBar, "BOTTOMLEFT",  0, -8)
    body:SetPoint("BOTTOMRIGHT", f,      "BOTTOMRIGHT", -26, 4)

    local bodyChild = CreateFrame("Frame", nil, body)
    bodyChild:SetWidth(BODY_W)
    bodyChild:SetHeight(1)
    body:SetScrollChild(bodyChild)
    f.LeftChild = bodyChild

    -- GUIDE section header
    local guideHeader = bodyChild:CreateFontString(nil, "OVERLAY")
    guideHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    guideHeader:SetPoint("TOPLEFT", bodyChild, "TOPLEFT", 20, -14)
    f.GuideHeader = guideHeader

    local guideLine = bodyChild:CreateTexture(nil, "OVERLAY")
    guideLine:SetHeight(1)
    guideLine:SetPoint("TOPLEFT",  bodyChild, "TOPLEFT",  20, -30)
    guideLine:SetPoint("TOPRIGHT", bodyChild, "TOPRIGHT", -20, -30)
    f.GuideLine = guideLine

    -- Tip text
    local tipText = bodyChild:CreateFontString(nil, "OVERLAY")
    tipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    tipText:SetPoint("TOPLEFT", bodyChild, "TOPLEFT", 20, -40)
    tipText:SetWidth(BODY_W - 40)
    tipText:SetJustifyH("LEFT")
    tipText:SetSpacing(6)
    tipText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3])
    f.TipText = tipText

    -- FÄHIGKEITEN section header
    local abilHeader = bodyChild:CreateFontString(nil, "OVERLAY")
    abilHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
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
-- Rebuild the ability rows in bodyChild
--------------------------------------------------

local activeAbilRows = {}

local function BuildAbilityRows(f, abilities)
    for _, row in ipairs(activeAbilRows) do
        row:Hide()
    end
    wipe(activeAbilRows)

    local lc   = f.LeftChild
    local tipH = math.max(f.TipText:GetStringHeight(), 24)

    local abilOffY = -(40 + tipH + 24)
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
        abName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        abName:SetPoint("TOPLEFT", row, "TOPLEFT", 52, -8)
        abName:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        abName:SetText(ab.name or "")

        local abDesc = row:CreateFontString(nil, "OVERLAY")
        abDesc:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        abDesc:SetPoint("TOPLEFT", abName, "BOTTOMLEFT", 0, -3)
        abDesc:SetPoint("RIGHT", row, "RIGHT", -10, 0)
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
-- Boss-Tipps im Raid-/Gruppenchat ansagen
--------------------------------------------------

local function AnnounceBossTips(bossName, roleKey)
    local data = WeintCodex_BossData and WeintCodex_BossData[bossName]
    local savedData = WeintCodex.SavedData and WeintCodex.SavedData.bossData
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

    local abilities = data and data.abilities
    BuildAbilityRows(f, abilities)

    -- ------------------------------------------------
    -- Inspector: Kurz & Knapp + Notizen + Ansage
    -- ------------------------------------------------

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

    local bossForNotes = selectedBoss

    WeintCodex.Navigation.SetInspector({
        { type = "header", text = "Kurz & Knapp" },
        { type = "list", items = kurzItems },
        { type = "divider" },
        { type = "header", text = "Notizen" },
        { type = "notes", height = 110,
            get = function()
                return WeintCodex.SavedData and WeintCodex.SavedData.bossNotes
                    and WeintCodex.SavedData.bossNotes[bossForNotes] or ""
            end,
            set = function(text)
                if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
                if not WeintCodex.SavedData.bossNotes then WeintCodex.SavedData.bossNotes = {} end
                WeintCodex.SavedData.bossNotes[bossForNotes] = text
            end,
        },
        { type = "button", style = "primary", label = "Im Raid ansagen", onClick = function()
            AnnounceBossTips(bossForNotes, roleKey)
        end },
    })
end

--------------------------------------------------
-- ShowBoss
--------------------------------------------------

local function ShowBoss(bossName)
    selectedBoss = bossName
    local f = CreateGuideFrame()

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
    for _, rb in ipairs(f.RoleBtns) do rb:Show() end

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

    WeintCodex.Navigation.BuildSidebar("Schlacht um Orgrimmar", sidebarItems)

    if selectedBoss then
        ShowBoss(selectedBoss)
    else
        ShowBoss(bossOrder[1].name)
    end
end
