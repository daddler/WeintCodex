--------------------------------------------------
-- WeintCodex :: Charakter Module
-- Mists of Pandaria Classic
--
-- Rubriken:
--   Übersicht        – Portrait + Live Score-Ampel
--   Verzauberungen   – Alle enchantbaren Slots (primär: vorhanden? sekundär: optimal?)
--   Sockel           – Alle Slots mit Sockeln (primär: belegt? sekundär: optimal?)
--   Werteverteilung  – Stub
--   Twinkverwaltung  – Stub
--------------------------------------------------

WeintCodex.Charakter = {}

local C = WeintCodex.Colors

--------------------------------------------------
-- HILFSFUNKTIONEN
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

local function MakeBtn(parent, label, w, h, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)
    SetSolidBg(btn, 0.12, 0.08, 0.22, 0.92)
    DrawBorder(btn, 0.42, 0.25, 0.72, 0.70, 1)
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    lbl:SetAllPoints(btn)
    lbl:SetJustifyH("CENTER")
    lbl:SetJustifyV("MIDDLE")
    lbl:SetText(label)
    lbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    btn:SetScript("OnEnter", function(self)
        SetSolidBg(self, 0.20, 0.14, 0.35, 0.98)
    end)
    btn:SetScript("OnLeave", function(self)
        SetSolidBg(self, 0.12, 0.08, 0.22, 0.92)
    end)
    if onClick then btn:SetScript("OnClick", onClick) end
    return btn, lbl
end

--------------------------------------------------
-- BLIZZARD-STATUS-ICONS (statt Unicode-Zeichen)
--------------------------------------------------

local STATUS_TEX = {
    optimal    = { path = "Interface\\RaidFrame\\ReadyCheck-Ready",          w = 16, h = 16 },
    missing    = { path = "Interface\\RaidFrame\\ReadyCheck-NotReady",       w = 16, h = 16 },
    suboptimal = { path = "Interface\\DialogFrame\\UI-Dialog-Icon-Alert",    w = 20, h = 20 },
    neutral    = { path = "Interface\\Buttons\\UI-MinusButton-UP",           w = 14, h = 14 },
}

local function AttachStatusIcon(parent, status, xOff, yOff)
    local info = STATUS_TEX[status] or STATUS_TEX.neutral
    local tex  = parent:CreateTexture(nil, "OVERLAY")
    tex:SetSize(info.w, info.h)
    tex:SetPoint("LEFT", parent, "LEFT", xOff or 8, yOff or 0)
    tex:SetTexture(info.path)
    return tex
end

local function StatusLegendText(optimal, subopt, missing)
    return "Optimal: " .. optimal .. "   Akzeptabel: " .. subopt .. "   Fehlt: " .. missing
end

--------------------------------------------------
-- TOOLTIP-SCANNER (Verzauberungen & Sockel)
--------------------------------------------------

local scanTip = CreateFrame("GameTooltip", "WeintCodexScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

WeintCodex._enchantNameCache = WeintCodex._enchantNameCache or {}

local function GetEnchantDisplayName(enchantId)
    if not enchantId then return nil end
    if WeintCodex._enchantNameCache[enchantId] then
        return WeintCodex._enchantNameCache[enchantId]
    end
    local db = WeintCodex_Enchants and WeintCodex_Enchants[enchantId]
    if db and db.name then
        WeintCodex._enchantNameCache[enchantId] = db.name
        return db.name
    end
    scanTip:ClearLines()
    scanTip:SetHyperlink("enchant:" .. enchantId)
    if scanTip:NumLines() >= 1 then
        local line = _G["WeintCodexScanTipTextLeft1"]
        local name = line and line:GetText()
        if name and name ~= "" then
            WeintCodex._enchantNameCache[enchantId] = name
            return name
        end
    end
    return "Unbekannte Verzauberung (ID: " .. enchantId .. ")"
end

local SOCKET_PATTERNS = {
    { pattern = "Meta%-Sockel",           color = "meta" },
    { pattern = "Meta Socket",            color = "meta" },
    { pattern = "Meta%-Socket",           color = "meta" },
    { pattern = "Roter Sockel",           color = "rot" },
    { pattern = "Red Socket",             color = "rot" },
    { pattern = "Gelber Sockel",          color = "gelb" },
    { pattern = "Yellow Socket",          color = "gelb" },
    { pattern = "Blauer Sockel",          color = "blau" },
    { pattern = "Blue Socket",            color = "blau" },
    { pattern = "Prismatischer Sockel",   color = "prismatic" },
    { pattern = "Prismatic Socket",       color = "prismatic" },
}
local function GetGemDisplayName(gemId)
    if WeintCodex_GetGemName then
        return WeintCodex_GetGemName(gemId)
    end
    if not gemId then return nil end
    return "Unbekannter Stein (ID: " .. gemId .. ")"
end

local function ClearCharakterCache()
    WeintCodex._enchantNameCache = {}
end

local activeCharakterView = nil

local function MakeRefreshButton(parent, onRefresh)
    local btn, lbl = MakeBtn(parent, "Aktualisieren", 118, 24, function()
        ClearCharakterCache()
        if onRefresh then onRefresh() end
    end)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, -12)
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    return btn
end

--------------------------------------------------
-- AKTUELLE SEITE (für Equipment-Events)
--------------------------------------------------

local function RefreshActiveCharakterView()
    ClearCharakterCache()
    if activeCharakterView == "uebersicht" then
        ShowUebersicht()
    elseif activeCharakterView == "enchants" then
        ShowEnchants()
    elseif activeCharakterView == "gems" then
        ShowGems()
    elseif activeCharakterView == "werte" then
        ShowWerteverteilung()
    end
end

local equipWatcher = CreateFrame("Frame")
equipWatcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
equipWatcher:SetScript("OnEvent", function()
    if activeCharakterView then
        RefreshActiveCharakterView()
    end
end)

-- Slot 18 (Fernkampf) ist enchantierbar – wird
-- nur angezeigt wenn ein Item angelegt ist.
--------------------------------------------------

local EQUIP_SLOTS = {
    { id = 1,  name = "Kopf",          enchSlot = nil,            },
    { id = 2,  name = "Hals",          enchSlot = nil,            },
    { id = 3,  name = "Schultern",     enchSlot = "Schultern",    },
    { id = 5,  name = "Brust",         enchSlot = "Brust",        },
    { id = 6,  name = "Taille",        enchSlot = nil,            },
    { id = 7,  name = "Beine",         enchSlot = "Beine",        },
    { id = 8,  name = "Füße",          enchSlot = "Füße",         },
    { id = 9,  name = "Handgelenke",   enchSlot = "Handgelenke",  },
    { id = 10, name = "Hände",         enchSlot = "Hände",        },
    { id = 11, name = "Finger 1",      enchSlot = nil,            },
    { id = 12, name = "Finger 2",      enchSlot = nil,            },
    { id = 13, name = "Schmuck 1",     enchSlot = nil,            },
    { id = 14, name = "Schmuck 2",     enchSlot = nil,            },
    { id = 15, name = "Umhang",        enchSlot = "Umhang",       },
    { id = 16, name = "Haupthand",     enchSlot = "Waffe",        },
    { id = 17, name = "Nebenhand",     enchSlot = "Waffe",        },
    { id = 18, name = "Fernkampf",     enchSlot = "Fernkampf",    },
}

--------------------------------------------------
-- SPEC-MAP: Klasse + Index → Profil-Key
--------------------------------------------------

local SPEC_MAP = {
    WARRIOR     = { "ARMS",          "FURY",          "PROTECTION"  },
    PALADIN     = { "HOLY",          "PROTECTION",    "RETRIBUTION" },
    HUNTER      = { "BEASTMASTERY",  "MARKSMANSHIP",  "SURVIVAL"    },
    ROGUE       = { "ASSASSINATION", "COMBAT",        "SUBTLETY"    },
    PRIEST      = { "DISCIPLINE",    "HOLY",          "SHADOW"      },
    DEATHKNIGHT = { "BLOOD",         "FROST",         "UNHOLY"      },
    SHAMAN      = { "ELEMENTAL",     "ENHANCEMENT",   "RESTORATION" },
    MAGE        = { "ARCANE",        "FIRE",          "FROST"       },
    WARLOCK     = { "AFFLICTION",    "DEMONOLOGY",    "DESTRUCTION" },
    MONK        = { "BREWMASTER",    "MISTWEAVER",    "WINDWALKER"  },
    DRUID       = { "BALANCE",       "FERAL",         "GUARDIAN",   "RESTORATION" },
}

--------------------------------------------------
-- TANK-SPEC-ERKENNUNG & SPIELSTIL
--------------------------------------------------

local TANK_SPECS = {
    WARRIOR_PROTECTION   = true,
    PALADIN_PROTECTION   = true,
    DEATHKNIGHT_BLOOD    = true,
    MONK_BREWMASTER      = true,
    DRUID_GUARDIAN       = true,
}

-- Spielstil pro Spec: "DEF" = Defensiv, "OFF" = Offensiv
local WeintCodex_TankPlayStyle = {}

--------------------------------------------------
-- AKTIVES SPEC-PROFIL ERMITTELN
-- Gibt zurück: profile, profileKey, tankStyle
--------------------------------------------------

local function GetCurrentSpecProfile()

local _, className = UnitClass("player")

if not className then
    return nil, nil, nil
    end

    local specIndex

    if GetPrimaryTalentTree then
        local ok, tree = pcall(GetPrimaryTalentTree)

        if ok and tree then
            specIndex = tree
            end
            end

            if not specIndex then
                return nil, nil, nil
                end

                local specs = SPEC_MAP[className]

                if not specs then
                    return nil, nil, nil
                    end

                    local specName = specs[specIndex]

                    if not specName then
                        return nil, nil, nil
                        end

                        local profileKey = className .. "_" .. specName

                        --------------------------------------------------
                        -- Tank-Spezialisierungen
                        --------------------------------------------------

                        if TANK_SPECS[profileKey] then

                            local style =
                            WeintCodex_TankPlayStyle[profileKey] or "DEF"

                            if style == "OFF" then

                                local offKey = profileKey .. "_OFFENSIVE"

                                local offProfile =
                                WeintCodex_SpecProfiles and
                                WeintCodex_SpecProfiles[offKey]

                                if offProfile then
                                    return offProfile, profileKey, "OFF"
                                    end
                                    end

                                    local defProfile =
                                    WeintCodex_SpecProfiles and
                                    WeintCodex_SpecProfiles[profileKey]

                                    return defProfile, profileKey, "DEF"
                                    end

                                    local profile =
                                    WeintCodex_SpecProfiles and
                                    WeintCodex_SpecProfiles[profileKey]

                                    return profile, profileKey, nil
                                    end
--------------------------------------------------
-- ITEM-LINK PARSEN: Verzauberung & Edelsteine
-- Format: |Hitem:itemId:enchId:g1:g2:g3:g4:...|h[Name]|h
--------------------------------------------------

local function ParseItemLink(link)
    if not link then return nil, {} end

    local linkData = link:match("|Hitem:([^|]+)|h")
    if not linkData then return nil, {} end

    local parts = {}
    for p in linkData:gmatch("[^:]+") do
        table.insert(parts, tonumber(p) or 0)
    end

    local enchantId = (parts[2] and parts[2] > 0) and parts[2] or nil

    local gems = {}
    for i = 3, 6 do
        if parts[i] and parts[i] > 0 then
            table.insert(gems, parts[i])
        else
            table.insert(gems, nil)
        end
    end

    return enchantId, gems
end

--------------------------------------------------
-- SOCKEL ÜBER ITEMSTATS ERMITTELN
--------------------------------------------------

local SOCKET_ORDER = {
    { stat = "EMPTY_SOCKET_META",      color = "meta" },
    { stat = "EMPTY_SOCKET_RED",       color = "rot" },
    { stat = "EMPTY_SOCKET_YELLOW",    color = "gelb" },
    { stat = "EMPTY_SOCKET_BLUE",      color = "blau" },
    { stat = "EMPTY_SOCKET_PRISMATIC", color = "prismatic" },
}

local function ScanItemSockets(link, slotId)

local sockets = {}

if not link then
    return sockets
    end

    local _, gems = ParseItemLink(link)

    local stats = GetItemStats(link)

    if not stats then
        return sockets
        end

        local gemIndex = 1

        for _, socketInfo in ipairs(SOCKET_ORDER) do

            local count = stats[socketInfo.stat]

            if count and count > 0 then

                for i = 1, count do

                    sockets[#sockets + 1] = {
                        color = socketInfo.color,
                        gemId = gems[gemIndex],
                    }

                    gemIndex = gemIndex + 1
                    end
                    end
                    end

                    --------------------------------------------------
                    -- Gürtelschnalle (zusätzlicher prismatischer Sockel)
                    --------------------------------------------------

                    if slotId == 6 then
                        sockets[#sockets + 1] = {
                            color = "prismatic",
                            gemId = gems[gemIndex],
                        }
                        end

                        return sockets
                        end

                        --------------------------------------------------
                        -- GEM SCORE BERECHNEN
                        --------------------------------------------------

                        local function GetGemScore(gemId, statWeights)

                        local gemStats =
                        WeintCodex_GemStats and WeintCodex_GemStats[gemId]

                        if not gemStats then
                            return 0
                            end

                            if not statWeights then
                                return 0
                                end

                                local score = 0

                                for stat, value in pairs(gemStats) do
                                    local weight = statWeights[stat] or 0
                                    score = score + (value * weight)
                                    end
                                    for stat, value in pairs(gemStats) do
                                        print(
                                            "STAT",
                                            stat,
                                            value,
                                            "WEIGHT",
                                            statWeights[stat]
                                        )
                                        end

                                    return score
                                    end

--------------------------------------------------
-- CONTENT-PANEL-ZUGRIFF
--------------------------------------------------

local contentPanel = nil
local function GetContentPanel()
    contentPanel = contentPanel or WeintCodex.ContentPanel
    return contentPanel
end

--------------------------------------------------
-- SCROLL-FRAME ERSTELLEN
--------------------------------------------------

local function CreateScrollArea(parent, x, y, w, h)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    sf:SetSize(w, h)
    sf:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local inner = CreateFrame("Frame", nil, sf)
    inner:SetSize(w - 20, h)
    sf:SetScrollChild(inner)

    return sf, inner
end

--------------------------------------------------
-- TANK-SPIELSTIL-TOGGLE ZEICHNEN
-- Gibt die genutzte Y-Höhe zurück (negativ)
--------------------------------------------------

local function DrawTankStyleToggle(parent, profileKey, currentStyle, onSwitch)
    if not TANK_SPECS[profileKey] then return 0 end

    local W = parent:GetWidth() - 32

    local bg = CreateFrame("Frame", nil, parent)
    bg:SetSize(W, 28)
    bg:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -44)
    SetSolidBg(bg, 0.05, 0.03, 0.12, 0.80)
    DrawBorder(bg, 0.42, 0.25, 0.72, 0.40, 1)

    local info = bg:CreateFontString(nil, "OVERLAY")
    info:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    info:SetPoint("LEFT", bg, "LEFT", 10, 0)
    info:SetText("|cff8B5CF6Tank-Spielstil:|r")

    local function StyleBtn(label, style, xOff)
        local isActive = (currentStyle == style)
        local btn = CreateFrame("Button", nil, bg)
        btn:SetSize(90, 20)
        btn:SetPoint("RIGHT", bg, "RIGHT", xOff, 0)

        local r, g, b = isActive and 0.25 or 0.08, isActive and 0.10 or 0.05, isActive and 0.50 or 0.18
        SetSolidBg(btn, r, g, b, 0.95)
        local br, bg2, bb = isActive and 0.60 or 0.28, isActive and 0.28 or 0.14, isActive and 1.00 or 0.45
        DrawBorder(btn, br, bg2, bb, 0.85, 1)

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        lbl:SetAllPoints(btn)
        lbl:SetJustifyH("CENTER")
        lbl:SetJustifyV("MIDDLE")
        lbl:SetText(isActive and ("|cffcc88ff" .. label .. "|r") or ("|cff664488" .. label .. "|r"))

        btn:SetScript("OnClick", function()
            WeintCodex_TankPlayStyle[profileKey] = style
            if onSwitch then onSwitch() end
        end)
        return btn
    end

    StyleBtn("⚔ Offensiv", "OFF", -4)
    StyleBtn("🛡 Defensiv", "DEF", -98)

    return -36
end

--------------------------------------------------
-- ENCHANT-ZEILE: 3-ZUSTANDS-SYSTEM
--
--   ✔ Optimal    (grün)  – Verzauberung vorhanden + korrekt
--   ~ Akzeptabel (gold)  – Verzauberung vorhanden, nicht empfohlen
--   ! Fehlt      (rot)   – KEINE Verzauberung (primäre Warnung)
--------------------------------------------------

local function CreateEnchantRow(parent, yOff, slotName, itemName, enchantId, profile)
    local BEST     = profile and profile.bestEnchants
    local bestList = BEST and BEST[slotName] or nil

    -- Enchant-Name aus Datenbank / Tooltip
    local enchName = GetEnchantDisplayName(enchantId)

    -- Beste Verzauberung
    local bestId   = bestList and bestList[1]
    local bestName = GetEnchantDisplayName(bestId) or (bestId and ("ID: " .. bestId) or "—")

    -- Status bestimmen
    local hasEnch  = enchantId ~= nil
    local isOptimal = false
    if hasEnch and bestList then
        for _, bid in ipairs(bestList) do
            if bid == enchantId then isOptimal = true; break end
        end
    end

    local status
    if isOptimal then
        status = "optimal"     -- ✔ grün
    elseif hasEnch then
        status = "suboptimal"  -- ~ gold
    else
        status = "missing"     -- ! rot
    end

    -- Keine bestList → Slot neutral (kein Spec-Tipp)
    local neutral = (not bestList)

    -- Farbe + Icon
    local statusCol   = (status == "optimal") and C.green
                     or (status == "missing")  and C.red
                     or C.gold

    if neutral then
        statusCol = C.textDim
        status   = "neutral"
    end

    -- Zeilenrahmen
    local rowH = 34
    local row  = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth() - 4, rowH)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, yOff)
    SetSolidBg(row, 0.07, 0.05, 0.14, 0.68)

    -- Farbstreifen links
    local stripe = row:CreateTexture(nil, "BACKGROUND")
    stripe:SetSize(3, rowH)
    stripe:SetPoint("LEFT", row, "LEFT", 0, 0)
    stripe:SetColorTexture(statusCol[1], statusCol[2], statusCol[3], 0.75)

    AttachStatusIcon(row, status, 10, 0)

    -- Slot-Name
    local slotLbl = row:CreateFontString(nil, "OVERLAY")
    slotLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    slotLbl:SetPoint("TOPLEFT", row, "TOPLEFT", 34, -6)
    slotLbl:SetWidth(118)
    slotLbl:SetText(slotName)
    slotLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

    -- Item-Name (klein, darunter)
    if itemName then
        local itemLbl = row:CreateFontString(nil, "OVERLAY")
        itemLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        itemLbl:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 34, 5)
        itemLbl:SetWidth(118)
        itemLbl:SetText("|cff3B2D60" .. itemName .. "|r")
    end

    -- Aktuelle Verzauberung
    local curLbl = row:CreateFontString(nil, "OVERLAY")
    curLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    curLbl:SetPoint("LEFT", row, "LEFT", 158, 0)
    curLbl:SetWidth(228)

    if status == "missing" then
        curLbl:SetText("|cffff5555— Keine Verzauberung! —|r")
    elseif status == "optimal" then
        curLbl:SetText(enchName or "—")
        curLbl:SetTextColor(C.green[1], C.green[2], C.green[3])
    else
        curLbl:SetText(enchName or "—")
        curLbl:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    end

    -- Empfehlung (bei suboptimal oder missing + bekannte Empfehlung)
    if bestList and (status == "suboptimal" or status == "missing") then
        local recLbl = row:CreateFontString(nil, "OVERLAY")
        recLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        recLbl:SetPoint("LEFT", row, "LEFT", 394, 0)
        recLbl:SetWidth(240)
        recLbl:SetText("|cff8B5CF6► " .. bestName .. "|r")
    end

    return -(rowH + 2)
end

--------------------------------------------------
-- ENCHANT-SEITE
--------------------------------------------------

local enchantFrame  = nil

local function ShowEnchants()
    activeCharakterView = "enchants"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    if enchantFrame then
        enchantFrame:Hide()
        enchantFrame = nil
    end
    enchantFrame = CreateFrame("Frame", nil, cp)
    enchantFrame:SetAllPoints(cp)
    enchantFrame:Show()

    -- Profil ermitteln
    local profile, profileKey, tankStyle = GetCurrentSpecProfile()

    -- Titel
    local title = enchantFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", enchantFrame, "TOPLEFT", 16, -14)
    title:SetText("|cff8B5CF6Verzauberungen|r")

    MakeRefreshButton(enchantFrame, ShowEnchants)

    local specInfo = enchantFrame:CreateFontString(nil, "OVERLAY")
    specInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    specInfo:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    if profileKey then
        local styleHint = tankStyle and (" |cff8B5CF6[" .. (tankStyle == "OFF" and "Offensiv" or "Defensiv") .. "]|r") or ""
        specInfo:SetText("|cff5B4880Spec: " .. profileKey .. styleHint .. "|r")
    else
        specInfo:SetText("|cffff9900Spec konnte nicht ermittelt werden. Einloggen!|r")
    end

    -- Tank-Spielstil-Toggle
    local toggleOffset = DrawTankStyleToggle(enchantFrame, profileKey, tankStyle, ShowEnchants)

    -- Spalten-Header
    local headerY = -52 + toggleOffset
    local function MakeHeader(text, x, w)
        local h = enchantFrame:CreateFontString(nil, "OVERLAY")
        h:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        h:SetPoint("TOPLEFT", enchantFrame, "TOPLEFT", x, headerY)
        h:SetWidth(w)
        h:SetText("|cff4B3880" .. text .. "|r")
    end
    MakeHeader("STATUS", 24, 28)
    MakeHeader("SLOT / ITEM", 54, 118)
    MakeHeader("AKTUELLE VERZAUBERUNG", 158, 228)
    MakeHeader("EMPFEHLUNG", 394, 240)

    local divider = enchantFrame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  enchantFrame, "TOPLEFT",  16, headerY - 14)
    divider:SetPoint("TOPRIGHT", enchantFrame, "TOPRIGHT", -16, headerY - 14)
    divider:SetHeight(1)
    divider:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40)

    -- Scroll-Bereich
    local sf, inner = CreateScrollArea(enchantFrame, 14, headerY - 18, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     enchantFrame, "TOPLEFT",     14, headerY - 18)
    sf:SetPoint("BOTTOMRIGHT", enchantFrame, "BOTTOMRIGHT", -14, 24)
    inner:SetWidth(sf:GetWidth() - 22)

    -- Zähler für Legende
    local cntMissing, cntSubopt, cntOptimal = 0, 0, 0

    local yOff = 0
    local anySlot = false

    for _, slotDef in ipairs(EQUIP_SLOTS) do
        if slotDef.enchSlot then
            local link = GetInventoryItemLink("player", slotDef.id)
            if link then
                -- Item-Name aus Link extrahieren
                local rawName = link:match("|h%[(.-)%]|h")

                local enchId = select(1, ParseItemLink(link))
                local rowH = CreateEnchantRow(inner, yOff, slotDef.enchSlot, rawName, enchId, profile)
                yOff = yOff + rowH
                anySlot = true

                -- Für Legende zählen
                local hasEnch = enchId ~= nil
                local isOpt   = false
                local bl      = profile and profile.bestEnchants and profile.bestEnchants[slotDef.enchSlot]
                if hasEnch and bl then
                    for _, bid in ipairs(bl) do
                        if bid == enchId then isOpt = true; break end
                    end
                end
                if not hasEnch then
                    cntMissing = cntMissing + 1
                elseif isOpt then
                    cntOptimal = cntOptimal + 1
                else
                    cntSubopt  = cntSubopt + 1
                end
            end
        end
    end

    if not anySlot then
        local noSlot = inner:CreateFontString(nil, "OVERLAY")
        noSlot:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        noSlot:SetPoint("TOPLEFT", inner, "TOPLEFT", 10, -10)
        noSlot:SetText("|cffaaaaaa Keine Items angelegt (Charakter einloggen!).|r")
    end

    inner:SetHeight(math.max(20, -yOff + 10))

    -- Legende + Zähler
    local legendText = "|cff22C55E" .. StatusLegendText(cntOptimal, cntSubopt, cntMissing) .. "|r"
    local legend = enchantFrame:CreateFontString(nil, "OVERLAY")
    legend:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    legend:SetPoint("BOTTOMLEFT", enchantFrame, "BOTTOMLEFT", 16, 6)
    legend:SetText(legendText)

    -- Hinweis rechts
    local total  = cntMissing + cntSubopt + cntOptimal
    if total > 0 then
        local vollPct = math.floor(((cntSubopt + cntOptimal) / total) * 100)
        local qualPct = math.floor((cntOptimal / total) * 100)
        local col     = vollPct < 100 and "|cffff5555" or "|cff22C55E"
        local scoreStr = col .. "Vollständig: " .. vollPct .. "%|r  |cff8B5CF6Qualität: " .. qualPct .. "%|r"
        local score = enchantFrame:CreateFontString(nil, "OVERLAY")
        score:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        score:SetPoint("BOTTOMRIGHT", enchantFrame, "BOTTOMRIGHT", -16, 6)
        score:SetText(scoreStr)
    end
end

--------------------------------------------------
-- GEM-ZEILE: 3-ZUSTANDS-SYSTEM
--
--   ✔ Optimal    (grün)  – Stein eingesetzt + korrekt
--   ~ Akzeptabel (gold)  – Stein eingesetzt, nicht empfohlen
--   ! Fehlt      (rot)   – LEERER Sockel (primäre Warnung)
--------------------------------------------------

local function CreateGemRow(parent, yOff, label, gemId, profile, socketColor)
    local gemData  = gemId and WeintCodex_Gems and WeintCodex_Gems[gemId]
    local gemName  = GetGemDisplayName(gemId)
    local colorKey = (gemData and gemData.color) or socketColor

    local bestList = nil
    if profile and profile.bestGems and colorKey then
        bestList = profile.bestGems[colorKey]
    end

    local bestId   = bestList and bestList[1]
    local bestName = GetGemDisplayName(bestId) or (bestId and ("ID: " .. bestId) or "—")

    --------------------------------------------------
    -- SCORE SYSTEM
    --------------------------------------------------

    local currentScore = 0
    local bestScore    = 0
    local qualityPct   = 0

    if profile and profile.statWeights then

        currentScore = GetGemScore(
            gemId,
            profile.statWeights
        )

        if bestList then
            for _, candidateId in ipairs(bestList) do

                local score =
                GetGemScore(
                    candidateId,
                    profile.statWeights
                )

                if score > bestScore then
                    bestScore = score
                    end
                    end
                    end

                    if bestScore > 0 then
                        qualityPct =
                        math.floor(
                            (currentScore / bestScore) * 100
                        )
                        end
                        end

    -- Status bestimmen
    local hasGem   = gemId ~= nil
    local isOptimal = false
    if hasGem and bestList then
        for _, bid in ipairs(bestList) do
            if bid == gemId then isOptimal = true; break end
        end
    end

    local status

    if not hasGem then

        status = "missing"

        elseif isOptimal then

            status = "optimal"

            elseif qualityPct >= 90 then

                status = "optimal"

                elseif qualityPct >= 70 then

                    status = "suboptimal"

                    else

                        status = "suboptimal"

                        end

    -- Farb-Dot für Sockelfarbe
    local dotColor = {
        rot      = {0.90, 0.20, 0.20},
        gelb     = {0.95, 0.85, 0.10},
        blau     = {0.20, 0.55, 0.95},
        orange   = {0.95, 0.55, 0.10},
        lila     = {0.65, 0.25, 0.90},
        ["grün"] = {0.20, 0.80, 0.30},
        meta     = {0.70, 0.60, 0.90},
    }
    local dc = (colorKey and dotColor[colorKey]) or {0.55, 0.55, 0.55}

    local statusCol  = (status == "optimal")    and C.green
                    or (status == "missing")     and C.red
                    or C.gold

    -- Zeile
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth() - 4, 30)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, yOff)
    SetSolidBg(row, 0.07, 0.05, 0.14, 0.60)

    -- Farbstreifen
    local stripe = row:CreateTexture(nil, "BACKGROUND")
    stripe:SetSize(3, 30)
    stripe:SetPoint("LEFT", row, "LEFT", 0, 0)
    stripe:SetColorTexture(statusCol[1], statusCol[2], statusCol[3], 0.75)

    -- Farb-Dot
    local dot = row:CreateTexture(nil, "OVERLAY")
    dot:SetSize(10, 10)
    dot:SetPoint("LEFT", row, "LEFT", 8, 0)
    dot:SetColorTexture(dc[1], dc[2], dc[3], 0.90)

    AttachStatusIcon(row, status, 22, 0)

    -- Label
    local lbl = row:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    lbl:SetPoint("LEFT", row, "LEFT", 44, 0)
    lbl:SetWidth(130)
    lbl:SetText(label)
    lbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

    -- Eingesetzter Stein
    local curLbl = row:CreateFontString(nil, "OVERLAY")
    curLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    curLbl:SetPoint("LEFT", row, "LEFT", 182, 0)
    curLbl:SetWidth(224)

    if status == "missing" then
        curLbl:SetText("|cffff5555— Leerer Sockel! —|r")
    elseif status == "optimal" then
        curLbl:SetText(
            (gemName or "?")
            .. " |cff888888("
            .. qualityPct
            .. "%)|r"
        )
        curLbl:SetTextColor(C.green[1], C.green[2], C.green[3])
    else
        curLbl:SetText(
            (gemName or "?")
            .. " |cff888888("
            .. qualityPct
            .. "%)|r"
        )
        curLbl:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    end

    -- Empfehlung
    if bestList and (status == "suboptimal" or status == "missing") then
        local recLbl = row:CreateFontString(nil, "OVERLAY")
        recLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        recLbl:SetPoint("LEFT", row, "LEFT", 412, 0)
        recLbl:SetWidth(230)
        recLbl:SetText("|cff8B5CF6► " .. bestName .. "|r")
    end

    return -32
end

--------------------------------------------------
-- GEM-SEITE
--------------------------------------------------

local gemFrame = nil

local function ShowGems()
    activeCharakterView = "gems"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    if gemFrame then
        gemFrame:Hide()
        gemFrame = nil
    end
    gemFrame = CreateFrame("Frame", nil, cp)
    gemFrame:SetAllPoints(cp)
    gemFrame:Show()

    local profile, profileKey, tankStyle = GetCurrentSpecProfile()

    -- Titel
    local title = gemFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", gemFrame, "TOPLEFT", 16, -14)
    title:SetText("|cff8B5CF6Sockel & Edelsteine|r")

    MakeRefreshButton(gemFrame, ShowGems)

    local specInfo = gemFrame:CreateFontString(nil, "OVERLAY")
    specInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    specInfo:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    if profileKey then
        local styleHint = tankStyle and (" |cff8B5CF6[" .. (tankStyle == "OFF" and "Offensiv" or "Defensiv") .. "]|r") or ""
        specInfo:SetText("|cff5B4880Spec: " .. profileKey .. styleHint .. "|r")
    else
        specInfo:SetText("|cffff9900Spec konnte nicht ermittelt werden.|r")
    end

    -- Gem-Hinweis aus Profil
    if profile and profile.gemNote then
        local noteBox = gemFrame:CreateFontString(nil, "OVERLAY")
        noteBox:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        noteBox:SetPoint("TOPRIGHT", gemFrame, "TOPRIGHT", -16, -14)
        noteBox:SetWidth(260)
        noteBox:SetJustifyH("RIGHT")
        noteBox:SetText("|cff5B4880" .. profile.gemNote .. "|r")
    end

    -- Tank-Toggle
    local toggleOffset = DrawTankStyleToggle(gemFrame, profileKey, tankStyle, ShowGems)

    -- Spalten-Header
    local headerY = -52 + toggleOffset
    local function MakeHeader(text, x, w)
        local h = gemFrame:CreateFontString(nil, "OVERLAY")
        h:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        h:SetPoint("TOPLEFT", gemFrame, "TOPLEFT", x, headerY)
        h:SetWidth(w)
        h:SetText("|cff4B3880" .. text .. "|r")
    end
    MakeHeader("FARBE/STATUS", 24, 28)
    MakeHeader("SLOT / SOCKEL", 54, 130)
    MakeHeader("EINGESETZTER STEIN", 182, 224)
    MakeHeader("EMPFEHLUNG", 412, 230)

    local divider = gemFrame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  gemFrame, "TOPLEFT",  16, headerY - 14)
    divider:SetPoint("TOPRIGHT", gemFrame, "TOPRIGHT", -16, headerY - 14)
    divider:SetHeight(1)
    divider:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40)

    local sf, inner = CreateScrollArea(gemFrame, 14, headerY - 18, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     gemFrame, "TOPLEFT",     14, headerY - 18)
    sf:SetPoint("BOTTOMRIGHT", gemFrame, "BOTTOMRIGHT", -14, 24)
    inner:SetWidth(sf:GetWidth() - 22)

    local yOff      = 0
    local anySlot   = false
    local cntMissing, cntSubopt, cntOptimal = 0, 0, 0

    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)

        if link then
            local sockets = ScanItemSockets(link, slotDef.id)
            for i, socket in ipairs(sockets) do
                end

                if #sockets > 0 then

                    local slotHeader = inner:CreateFontString(nil, "OVERLAY")
                    slotHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                    slotHeader:SetPoint("TOPLEFT", inner, "TOPLEFT", 6, yOff - 4)
                    slotHeader:SetText("|cff8B5CF6" .. slotDef.name .. "|r")
                    yOff = yOff - 18

                    for gemIdx, socket in ipairs(sockets) do

                        local rowLabel = slotDef.name .. " #" .. gemIdx

                        local rowH = CreateGemRow(
                            inner,
                            yOff,
                            rowLabel,
                            socket.gemId,
                            profile,
                            socket.color
                        )

                        yOff = yOff + rowH

                        local gemId    = socket.gemId
                        local hasGem   = gemId ~= nil
                        local isOpt    = false
                        local gemData2 = gemId and WeintCodex_Gems and WeintCodex_Gems[gemId]
                        local ck       = (gemData2 and gemData2.color) or socket.color
                        local bl       = profile and profile.bestGems and ck and profile.bestGems[ck]

                        if hasGem and bl then
                            for _, bid in ipairs(bl) do
                                if bid == gemId then
                                    isOpt = true
                                    break
                                    end
                                    end
                                    end

                                    if not hasGem then
                                        cntMissing = cntMissing + 1
                                        elseif isOpt then
                                            cntOptimal = cntOptimal + 1
                                            else
                                                cntSubopt = cntSubopt + 1
                                                end
                                                end

                                                yOff = yOff - 6
                                                anySlot = true
                                                end
                                                end
                                                end

    if not anySlot then
        local noSlot = inner:CreateFontString(nil, "OVERLAY")
        noSlot:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        noSlot:SetPoint("TOPLEFT", inner, "TOPLEFT", 10, -10)
        noSlot:SetText("|cffaaaaaa Keine Sockelslots gefunden (Charakter einloggen!).|r")
    end

    inner:SetHeight(math.max(20, -yOff + 10))

    -- Legende
    local legendText = "|cff22C55E" .. StatusLegendText(cntOptimal, cntSubopt, cntMissing) .. "|r"
    local legend = gemFrame:CreateFontString(nil, "OVERLAY")
    legend:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    legend:SetPoint("BOTTOMLEFT", gemFrame, "BOTTOMLEFT", 16, 6)
    legend:SetText(legendText)

    local total = cntMissing + cntSubopt + cntOptimal
    if total > 0 then
        local vollPct = math.floor(((cntSubopt + cntOptimal) / total) * 100)
        local qualPct = math.floor((cntOptimal / total) * 100)
        local col     = cntMissing > 0 and "|cffff5555" or "|cff22C55E"
        local score   = gemFrame:CreateFontString(nil, "OVERLAY")
        score:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        score:SetPoint("BOTTOMRIGHT", gemFrame, "BOTTOMRIGHT", -16, 6)
        score:SetText(col .. "Belegt: " .. vollPct .. "%|r  |cff8B5CF6Qualität: " .. qualPct .. "%|r")
    end
end

--------------------------------------------------
-- SCORE BERECHNEN (für Übersicht)
-- Gibt zurück:
--   ench: missing, subopt, optimal, total
--   gem:  missing, subopt, optimal, total
--------------------------------------------------

local function CalcCharakterScore()
    local profile, profileKey, tankStyle = GetCurrentSpecProfile()

    local eM, eSub, eOpt, eAll = 0, 0, 0, 0
    local gM, gSub, gOpt, gAll = 0, 0, 0, 0

    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)

        -- Enchant-Score
        if slotDef.enchSlot and link then
            local bestList = profile and profile.bestEnchants and profile.bestEnchants[slotDef.enchSlot]
            if bestList then
                eAll = eAll + 1
                local enchId = select(1, ParseItemLink(link))
                if not enchId then
                    eM = eM + 1
                else
                    local isOpt = false
                    for _, bid in ipairs(bestList) do
                        if bid == enchId then isOpt = true; break end
                    end
                    if isOpt then eOpt = eOpt + 1 else eSub = eSub + 1 end
                end
            end
        end

        -- Gem-Score (dynamische Sockel-Erkennung)
        if link then
            local sockets = ScanItemSockets(link, slotDef.id)
            for _, socket in ipairs(sockets) do
                local gemId   = socket.gemId
                local gemData = gemId and WeintCodex_Gems and WeintCodex_Gems[gemId]
                local ck      = (gemData and gemData.color) or socket.color
                local bl      = profile and profile.bestGems and ck and profile.bestGems[ck]
                if bl then
                    gAll = gAll + 1
                    if not gemId then
                        gM = gM + 1
                    else
                        local isOpt = false
                        for _, bid in ipairs(bl) do
                            if bid == gemId then isOpt = true; break end
                        end
                        if isOpt then gOpt = gOpt + 1 else gSub = gSub + 1 end
                    end
                end
            end
        end
    end

    return eM, eSub, eOpt, eAll, gM, gSub, gOpt, gAll
end

--------------------------------------------------
-- SCORE-KARTE ZEICHNEN (Übersicht)
--------------------------------------------------

local function MakeScoreCard(parent, label, missing, subopt, optimal, total, xOff, yOff, cardW, onClick)
    local pct      = (total > 0) and math.floor(((subopt + optimal) / total) * 100) or 0
    local qualPct  = (total > 0) and math.floor((optimal / total) * 100) or 0
    local mainCol  = (missing == 0) and C.green or (pct >= 75 and C.gold or C.red)
    local gradeStr = (missing == 0) and "Vollständig" or (pct >= 75 and "Fast vollständig" or "Unvollständig")

    local card = CreateFrame("Button", nil, parent)
    card:SetSize(cardW, 108)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
    SetSolidBg(card, 0.08, 0.05, 0.17, 0.95)
    DrawBorder(card, mainCol[1], mainCol[2], mainCol[3], 0.70, 2)

    -- Ampel-Punkt
    local dot = card:CreateFontString(nil, "OVERLAY")
    dot:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
    dot:SetPoint("LEFT", card, "LEFT", 14, 4)
    dot:SetText("●")
    dot:SetTextColor(mainCol[1], mainCol[2], mainCol[3])

    -- Label
    local lbl = card:CreateFontString(nil, "OVERLAY")
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    lbl:SetPoint("TOPLEFT", card, "TOPLEFT", 66, -14)
    lbl:SetText(label)
    lbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    -- Vollständig-Zahl
    local vollNum = card:CreateFontString(nil, "OVERLAY")
    vollNum:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    vollNum:SetPoint("TOPLEFT", card, "TOPLEFT", 66, -33)
    vollNum:SetText((subopt + optimal) .. " / " .. total)
    vollNum:SetTextColor(mainCol[1], mainCol[2], mainCol[3])

    -- Status-Text
    local grade = card:CreateFontString(nil, "OVERLAY")
    grade:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    grade:SetPoint("TOPLEFT", card, "TOPLEFT", 66, -62)
    grade:SetText(gradeStr .. " (" .. pct .. "%)")
    grade:SetTextColor(mainCol[1] * 0.85, mainCol[2] * 0.85, mainCol[3] * 0.85)

    -- Qualität
    local qualLbl = card:CreateFontString(nil, "OVERLAY")
    qualLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    qualLbl:SetPoint("TOPLEFT", card, "TOPLEFT", 66, -78)
    qualLbl:SetText("|cff8B5CF6Qualität: " .. qualPct .. "% optimal|r")

    -- Subinfo rechts-unten
    if missing > 0 then
        local missInfo = card:CreateFontString(nil, "OVERLAY")
        missInfo:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        missInfo:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 8)
        missInfo:SetText("|cffff5555" .. missing .. " fehlen!|r")
    end

    -- Klick-Hint
    local hint = card:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    hint:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 66, 8)
    hint:SetText("|cff3B2D60→ Details anzeigen|r")

    card:SetScript("OnEnter", function(self) SetSolidBg(self, 0.12, 0.08, 0.24, 0.98) end)
    card:SetScript("OnLeave", function(self) SetSolidBg(self, 0.08, 0.05, 0.17, 0.95) end)
    if onClick then card:SetScript("OnClick", onClick) end

    return card
end

--------------------------------------------------
-- ÜBERSICHT: Portrait + Score-Ampel
--------------------------------------------------

local uebersichtFrame = nil

local function ShowUebersicht()
    activeCharakterView = "uebersicht"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    if uebersichtFrame then
        uebersichtFrame:Hide()
        uebersichtFrame = nil
    end

    uebersichtFrame = CreateFrame("Frame", nil, cp)
    uebersichtFrame:SetAllPoints(cp)

    MakeRefreshButton(uebersichtFrame, ShowUebersicht)

    -- Score live berechnen
    local eM, eSub, eOpt, eAll, gM, gSub, gOpt, gAll = CalcCharakterScore()
    local _, profileKey, tankStyle = GetCurrentSpecProfile()

    -- =============================================
    -- 3D-CHARAKTER-PORTRAIT (animiertes Modell)
    -- =============================================
    local portrait = CreateFrame("PlayerModel", nil, uebersichtFrame)
    portrait:SetSize(148, 220)
    portrait:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", 16, -16)
    portrait:SetUnit("player")

    -- Rahmen ums Portrait
    DrawBorder(portrait, 0.42, 0.25, 0.72, 0.60, 2)
    SetSolidBg(portrait, 0.04, 0.02, 0.10, 0.80)

    -- Name + Spec unter Portrait
    local name = UnitName("player")
    local _, className = UnitClass("player")
    local nameLbl = uebersichtFrame:CreateFontString(nil, "OVERLAY")
    nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    nameLbl:SetPoint("TOP", portrait, "BOTTOM", 0, -4)
    nameLbl:SetWidth(148)
    nameLbl:SetJustifyH("CENTER")
    nameLbl:SetText((name or "—"))
    nameLbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    local specLbl = uebersichtFrame:CreateFontString(nil, "OVERLAY")
    specLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    specLbl:SetPoint("TOP", nameLbl, "BOTTOM", 0, -2)
    specLbl:SetWidth(148)
    specLbl:SetJustifyH("CENTER")
    if profileKey then
        local styleHint = tankStyle and (" [" .. (tankStyle == "OFF" and "Offensiv" or "Defensiv") .. "]") or ""
        specLbl:SetText("|cff8B5CF6" .. profileKey .. styleHint .. "|r")
    else
        specLbl:SetText("|cffff9900Kein Profil gefunden|r")
    end

    -- =============================================
    -- GESAMT-BANNER (rechts vom Portrait)
    -- =============================================
    local totalMissing = eM + gM
    local totalAll     = eAll + gAll
    local totalHave    = (eSub + eOpt) + (gSub + gOpt)
    local totalPct     = (totalAll > 0) and math.floor((totalHave / totalAll) * 100) or 0
    local bannerCol    = (totalMissing == 0) and C.green or (totalPct >= 75 and C.gold or C.red)

    local banner = CreateFrame("Frame", nil, uebersichtFrame)
    banner:SetSize(456, 50)
    banner:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", 176, -16)
    SetSolidBg(banner, bannerCol[1] * 0.12, bannerCol[2] * 0.12, bannerCol[3] * 0.12, 0.95)
    DrawBorder(banner, bannerCol[1], bannerCol[2], bannerCol[3], 0.80, 2)

    local bannerIcon = banner:CreateTexture(nil, "OVERLAY")
    bannerIcon:SetSize(18, 18)
    bannerIcon:SetPoint("LEFT", banner, "LEFT", 12, 0)
    if totalMissing == 0 then
        bannerIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    else
        bannerIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    end

    local bannerTitle = banner:CreateFontString(nil, "OVERLAY")
    bannerTitle:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    bannerTitle:SetPoint("LEFT", banner, "LEFT", 40, 8)
    bannerTitle:SetText("Ausrüstungsstatus")
    bannerTitle:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    local bannerSub = banner:CreateFontString(nil, "OVERLAY")
    bannerSub:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    bannerSub:SetPoint("LEFT", banner, "LEFT", 40, -8)
    if totalMissing == 0 then
        bannerSub:SetText("|cff22C55EAlle Slots vollständig versorgt (" .. totalPct .. "% belegt)|r")
    elseif totalPct >= 75 then
        bannerSub:SetText("|cffFFBB22" .. totalMissing .. " Slots fehlen noch (" .. totalPct .. "% belegt)|r")
    else
        bannerSub:SetText("|cffff5555" .. totalMissing .. " Slots unversorgt — dringend handeln! (" .. totalPct .. "% belegt)|r")
    end

    -- =============================================
    -- SCORE-KARTEN
    -- =============================================
    MakeScoreCard(
        uebersichtFrame, "Verzauberungen",
        eM, eSub, eOpt, (eAll > 0 and eAll or 8),
        176, -78, 218,
        ShowEnchants
    )

    MakeScoreCard(
        uebersichtFrame, "Sockel & Edelsteine",
        gM, gSub, gOpt, (gAll > 0 and gAll or 16),
        406, -78, 226,
        ShowGems
    )

    -- =============================================
    -- SCHNELL-ÜBERSICHT (Enchant-Status, kompakt)
    -- =============================================
    local detY = -198

    local detTitle = uebersichtFrame:CreateFontString(nil, "OVERLAY")
    detTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    detTitle:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", 176, detY)
    detTitle:SetText("|cff4B3880— SCHNELLÜBERSICHT VERZAUBERUNGEN —|r")

    local divLine = uebersichtFrame:CreateTexture(nil, "OVERLAY")
    divLine:SetPoint("TOPLEFT",  uebersichtFrame, "TOPLEFT",  176, detY - 13)
    divLine:SetPoint("TOPRIGHT", uebersichtFrame, "TOPRIGHT",  -16, detY - 13)
    divLine:SetHeight(1)
    divLine:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.35)

    local profile, profileKey, tankStyle = GetCurrentSpecProfile()
    local rowY    = detY - 20
    local col1X, col2X, col3X = 176, 286, 416

    for _, slotDef in ipairs(EQUIP_SLOTS) do
        if slotDef.enchSlot and rowY > -490 then
            local link   = GetInventoryItemLink("player", slotDef.id)
            if link then
                local enchId = select(1, ParseItemLink(link))
                local bl     = profile and profile.bestEnchants and profile.bestEnchants[slotDef.enchSlot]
                local isOpt  = false
                if enchId and bl then
                    for _, bid in ipairs(bl) do
                        if bid == enchId then isOpt = true; break end
                    end
                end

                -- Slot
                local sl = uebersichtFrame:CreateFontString(nil, "OVERLAY")
                sl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                sl:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", col1X, rowY)
                sl:SetWidth(104)
                sl:SetText(slotDef.enchSlot)
                sl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

                -- Status
                local stFrame = CreateFrame("Frame", nil, uebersichtFrame)
                stFrame:SetSize(124, 14)
                stFrame:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", col2X, rowY + 2)
                if not enchId then
                    AttachStatusIcon(stFrame, "missing", 0, 0)
                    local st = stFrame:CreateFontString(nil, "OVERLAY")
                    st:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                    st:SetPoint("LEFT", stFrame, "LEFT", 20, 0)
                    st:SetText("|cffff5555Fehlt|r")
                elseif isOpt then
                    AttachStatusIcon(stFrame, "optimal", 0, 0)
                    local st = stFrame:CreateFontString(nil, "OVERLAY")
                    st:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                    st:SetPoint("LEFT", stFrame, "LEFT", 20, 0)
                    st:SetText("|cff22C55EOptimal|r")
                else
                    AttachStatusIcon(stFrame, "suboptimal", 0, 0)
                    local st = stFrame:CreateFontString(nil, "OVERLAY")
                    st:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                    st:SetPoint("LEFT", stFrame, "LEFT", 20, 0)
                    st:SetText("|cffFFBB22Vorhanden|r")
                end

                -- Enchant-Name kurz
                local ed = enchId and GetEnchantDisplayName(enchId)
                if ed then
                    local en = uebersichtFrame:CreateFontString(nil, "OVERLAY")
                    en:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                    en:SetPoint("TOPLEFT", uebersichtFrame, "TOPLEFT", col3X, rowY)
                    en:SetWidth(200)
                    en:SetText("|cff3B2D80" .. ed .. "|r")
                end

                rowY = rowY - 16
            end
        end
    end

    -- Fußzeile
    local foot = uebersichtFrame:CreateFontString(nil, "OVERLAY")
    foot:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    foot:SetPoint("BOTTOMLEFT", uebersichtFrame, "BOTTOMLEFT", 16, 6)
    foot:SetText("|cff3B2D60Klicke auf eine Karte für Details. Aktualisieren-Button oder Itemwechsel scannt neu.|r")

    uebersichtFrame:Show()
end

--------------------------------------------------
-- WERTEVERTEILUNG – Stat-Summe der Ausrüstung
--------------------------------------------------

local STAT_LABELS = {
    ["ITEM_MOD_STRENGTH_SHORT"]         = "Stärke",
    ["ITEM_MOD_AGILITY_SHORT"]          = "Beweglichkeit",
    ["ITEM_MOD_INTELLECT_SHORT"]        = "Intelligenz",
    ["ITEM_MOD_STAMINA_SHORT"]          = "Ausdauer",
    ["ITEM_MOD_SPIRIT_SHORT"]           = "Willenskraft",
    ["ITEM_MOD_CRIT_RATING_SHORT"]      = "Kritische Trefferwertung",
    ["ITEM_MOD_HASTE_RATING_SHORT"]     = "Tempowertung",
    ["ITEM_MOD_MASTERY_RATING_SHORT"]   = "Meisterschaft",
    ["ITEM_MOD_HIT_RATING_SHORT"]       = "Trefferwertung",
    ["ITEM_MOD_EXPERTISE_RATING_SHORT"] = "Waffenkundewertung",
    ["ITEM_MOD_DODGE_RATING_SHORT"]     = "Ausweichen",
    ["ITEM_MOD_PARRY_RATING_SHORT"]     = "Parierchance",
    ["RESISTANCE0_NAME"]                = "Rüstung",
}

local STAT_ORDER = {
    "ITEM_MOD_STRENGTH_SHORT",
    "ITEM_MOD_AGILITY_SHORT",
    "ITEM_MOD_INTELLECT_SHORT",
    "ITEM_MOD_STAMINA_SHORT",
    "ITEM_MOD_SPIRIT_SHORT",
    "ITEM_MOD_HIT_RATING_SHORT",
    "ITEM_MOD_EXPERTISE_RATING_SHORT",
    "ITEM_MOD_CRIT_RATING_SHORT",
    "ITEM_MOD_HASTE_RATING_SHORT",
    "ITEM_MOD_MASTERY_RATING_SHORT",
    "ITEM_MOD_DODGE_RATING_SHORT",
    "ITEM_MOD_PARRY_RATING_SHORT",
    "RESISTANCE0_NAME",
}

local function CollectEquippedStats()
    local totals = {}
    for _, slotDef in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotDef.id)
        if link and GetItemStats then
            local stats = GetItemStats(link)
            if stats then
                for key, value in pairs(stats) do
                    if type(value) == "number" and value > 0 and STAT_LABELS[key] then
                        totals[key] = (totals[key] or 0) + value
                    end
                end
            end
        end
    end
    return totals
end

local werteFrame = nil

local function ShowWerteverteilung()
    activeCharakterView = "werte"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    if werteFrame then
        werteFrame:Hide()
        werteFrame = nil
    end

    werteFrame = CreateFrame("Frame", nil, cp)
    werteFrame:SetAllPoints(cp)

    local title = werteFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, -14)
    title:SetText("|cff8B5CF6Werteverteilung|r")

    MakeRefreshButton(werteFrame, ShowWerteverteilung)

    local _, profileKey = GetCurrentSpecProfile()
    local specInfo = werteFrame:CreateFontString(nil, "OVERLAY")
    specInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    specInfo:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    specInfo:SetText(profileKey and ("|cff5B4880Profil: " .. profileKey .. " — Gewichtung folgt in einer späteren Version|r")
        or "|cffff9900Spec konnte nicht ermittelt werden.|r")

    local divider = werteFrame:CreateTexture(nil, "OVERLAY")
    divider:SetPoint("TOPLEFT",  werteFrame, "TOPLEFT",  16, -52)
    divider:SetPoint("TOPRIGHT", werteFrame, "TOPRIGHT", -16, -52)
    divider:SetHeight(1)
    divider:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40)

    local totals = CollectEquippedStats()
    local yOff = -66

    local hdr = werteFrame:CreateFontString(nil, "OVERLAY")
    hdr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    hdr:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
    hdr:SetText("|cff4B3880— AKTUELLE WERTE (AUSRÜSTUNG) —|r")
    yOff = yOff - 22

    local anyStat = false
    for _, key in ipairs(STAT_ORDER) do
        local value = totals[key]
        if value and value > 0 then
            anyStat = true
            local row = CreateFrame("Frame", nil, werteFrame)
            row:SetSize(420, 22)
            row:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
            SetSolidBg(row, 0.07, 0.05, 0.14, 0.55)

            local lbl = row:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            lbl:SetPoint("LEFT", row, "LEFT", 10, 0)
            lbl:SetText(STAT_LABELS[key])
            lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

            local val = row:CreateFontString(nil, "OVERLAY")
            val:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            val:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            val:SetText("|cff8B5CF6+" .. value .. "|r")

            yOff = yOff - 24
        end
    end

    if not anyStat then
        local none = werteFrame:CreateFontString(nil, "OVERLAY")
        none:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        none:SetPoint("TOPLEFT", werteFrame, "TOPLEFT", 16, yOff)
        none:SetText("|cffaaaaaaKeine Werte ermittelt (Charakter einloggen / Items anlegen).|r")
    end

    local hint = werteFrame:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    hint:SetPoint("BOTTOMLEFT", werteFrame, "BOTTOMLEFT", 16, 8)
    hint:SetText("|cff3B2D60Summe aller Item-Stats der angelegten Ausrüstung.|r")

    werteFrame:Show()
end

--------------------------------------------------
-- TWINKVERWALTUNG – Gilden-Scan & Export
--------------------------------------------------

local twinkFrame = nil
local twinkRows   = {}

local function GetSavedTwinkSelection()
    WeintCodex.SavedData = WeintCodex.SavedData or {}
    WeintCodex.SavedData.twinks = WeintCodex.SavedData.twinks or {}
    return WeintCodex.SavedData.twinks
end

local function BuildTwinkExportString()
    local saved = GetSavedTwinkSelection()
    local parts = {}
    for name, data in pairs(saved) do
        if data.selected then
            parts[#parts + 1] = string.format("%s|%s|%s|%s",
                name,
                data.class or "",
                data.level or "0",
                data.note or "")
        end
    end
    table.sort(parts)
    local dateStr = date("%Y-%m-%d")
    return "WCEXPORT:TWINK:" .. dateStr .. ":" .. table.concat(parts, ",")
end

local function ShowTwinkverwaltung()
    activeCharakterView = "twinks"
    local cp = GetContentPanel()
    if not cp then return end
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    if twinkFrame then
        twinkFrame:Hide()
        twinkFrame = nil
    end
    twinkRows = {}

    twinkFrame = CreateFrame("Frame", nil, cp)
    twinkFrame:SetAllPoints(cp)

    local title = twinkFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetPoint("TOPLEFT", twinkFrame, "TOPLEFT", 16, -14)
    title:SetText("|cff8B5CF6Twinkverwaltung|r")

    local sub = twinkFrame:CreateFontString(nil, "OVERLAY")
    sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetWidth(640)
    sub:SetJustifyH("LEFT")
    sub:SetText("|cff5B4880Gildenmitglieder scannen und eigene Twinks auswählen. Export für den WeintCodex Discord-Bot.|r")

    local scanBtn, _ = MakeBtn(twinkFrame, "Gilde scannen", 120, 26, nil)
    scanBtn:SetPoint("TOPRIGHT", twinkFrame, "TOPRIGHT", -150, -12)

    local exportBtn, _ = MakeBtn(twinkFrame, "Export", 90, 26, function()
        local exportStr = BuildTwinkExportString()
        if WeintCodex.ShowExportDialog then
            WeintCodex.ShowExportDialog("Twink-Export", exportStr)
        end
    end)
    exportBtn:SetPoint("TOPRIGHT", twinkFrame, "TOPRIGHT", -16, -12)

    local sf, inner = CreateScrollArea(twinkFrame, 14, -72, 20, 400)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     twinkFrame, "TOPLEFT",     14, -72)
    sf:SetPoint("BOTTOMRIGHT", twinkFrame, "BOTTOMRIGHT", -14, 36)
    inner:SetWidth(sf:GetWidth() - 22)

    local saved = GetSavedTwinkSelection()
    local playerName = UnitName("player")

    local function DrawRoster()
        for _, child in pairs({inner:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        twinkRows = {}

        if not IsInGuild() then
            local msg = inner:CreateFontString(nil, "OVERLAY")
            msg:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            msg:SetPoint("TOPLEFT", inner, "TOPLEFT", 8, -8)
            msg:SetText("|cffff9900Du bist in keiner Gilde — bitte einer Gilde beitreten.|r")
            twinkRows[1] = msg
            inner:SetHeight(40)
            return
        end

        if GuildRoster then
            GuildRoster()
            elseif C_GuildInfo and C_GuildInfo.GuildRoster then
                C_GuildInfo.GuildRoster()
                end
        local numMembers = GetNumGuildMembers()
        title:SetText(
            string.format(
                "|cff8B5CF6Twinkverwaltung|r |cff888888(%d Mitglieder gefunden)|r",
                          numMembers or 0
            )
        )
        local yOff = 0
        local count = 0

        for i = 1, numMembers do
            local name, _, _, level, class, _, _, _, online, _, classFileName = GetGuildRosterInfo(i)
            if name then
                local shortName = name:match("([^%-]+)") or name
                count = count + 1

                local row = CreateFrame("Frame", nil, inner)
                row:SetSize(inner:GetWidth() - 4, 24)
                row:SetPoint("TOPLEFT", inner, "TOPLEFT", 2, yOff)
                SetSolidBg(row, 0.07, 0.05, 0.14, count % 2 == 0 and 0.45 or 0.30)

                local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                cb:SetSize(22, 22)
                cb:SetPoint("LEFT", row, "LEFT", 4, 0)
                local entry = saved[shortName] or {}
                cb:SetChecked(entry.selected or (shortName == playerName))
                cb:SetScript("OnClick", function(self)
                    saved[shortName] = saved[shortName] or {
                        class = classFileName or class or "",
                        level = tostring(level or 0),
                    }
                    saved[shortName].selected = self:GetChecked()
                end)

                local nameLbl = row:CreateFontString(nil, "OVERLAY")
                nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                nameLbl:SetPoint("LEFT", row, "LEFT", 30, 0)
                nameLbl:SetWidth(140)
                nameLbl:SetText(shortName .. (shortName == playerName and " |cff8B5CF6(Du)|r" or ""))
                nameLbl:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

                local classLbl = row:CreateFontString(nil, "OVERLAY")
                classLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                classLbl:SetPoint("LEFT", row, "LEFT", 180, 0)
                classLbl:SetWidth(120)
                classLbl:SetText(class or "—")
                classLbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

                local lvlLbl = row:CreateFontString(nil, "OVERLAY")
                lvlLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                lvlLbl:SetPoint("LEFT", row, "LEFT", 300, 0)
                lvlLbl:SetText("Stufe " .. (level or "?"))
                lvlLbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])

                local onlineLbl = row:CreateFontString(nil, "OVERLAY")
                onlineLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                onlineLbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                onlineLbl:SetText(online and "|cff22C55EOnline|r" or "|cff666666Offline|r")

                if not saved[shortName] then
                    saved[shortName] = {
                        selected = (shortName == playerName),
                        class    = classFileName or class or "",
                        level    = tostring(level or 0),
                    }
                else
                    saved[shortName].class = classFileName or class or saved[shortName].class
                    saved[shortName].level = tostring(level or saved[shortName].level)
                end

                twinkRows[#twinkRows + 1] = row
                yOff = yOff - 26
            end
        end

        inner:SetHeight(math.max(40, -yOff + 10))
    end

    scanBtn:SetScript("OnClick", DrawRoster)

    local foot = twinkFrame:CreateFontString(nil, "OVERLAY")
    foot:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    foot:SetPoint("BOTTOMLEFT", twinkFrame, "BOTTOMLEFT", 16, 8)
    foot:SetText("|cff3B2D60Format: WCEXPORT:TWINK:DATUM:Name|KLASSE|STUFE|NOTIZ,...|r")

    DrawRoster()
    twinkFrame:Show()
end

--------------------------------------------------
-- CHARAKTER.SHOW – Sidebar aufbauen
--------------------------------------------------

function WeintCodex.Charakter.Show()
    activeCharakterView = nil
    WeintCodex.Navigation.BuildSidebar("CHARAKTER", {
        { label = "Übersicht",       onClick = ShowUebersicht },
        { isGroup = true, label = "— AUSRÜSTUNG —" },
        { label = "Verzauberungen",  onClick = ShowEnchants,   indent = true },
        { label = "Sockel",          onClick = ShowGems,        indent = true },
        { isGroup = true, label = "— ANALYSE —" },
        { label = "Werteverteilung", onClick = ShowWerteverteilung },
        { isGroup = true, label = "— VERWALTUNG —" },
        { label = "Twinkverwaltung", onClick = ShowTwinkverwaltung },
    })
    WeintCodex.Navigation.ActivateFirst()
end
