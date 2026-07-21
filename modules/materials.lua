--------------------------------------------------
-- WeintCodex :: Materialien Module
-- Zeigt Gildenbankmaterialien nach Kategorien
--------------------------------------------------

WeintCodex.Materials = {}

local C        = WeintCodex.Colors
local matFrame = nil

--------------------------------------------------
-- Beispieldaten (Platzhalter bis Import)
--------------------------------------------------

local sampleData = {
    date = "Noch kein Gildenbankscan",
    items = {
        { name = "Mushanrippchen", count = 0, category = "Foodmaterialien", target = 120 },
        { name = "Rohes Tigersteak", count = 0, category = "Foodmaterialien", target = 140 },
        { name = "Roher Krokiliskenbauch", count = 0, category = "Foodmaterialien", target = 140 },
        { name = "Tigergurami", count = 0, category = "Foodmaterialien", target = 140 },
        { name = "Rotbauchmandarin", count = 0, category = "Foodmaterialien", target = 140 },
        { name = "Kaiserlachs", count = 0, category = "Foodmaterialien", target = 140 },
        { name = "Riesige Mantisgarnele", count = 0, category = "Foodmaterialien", target = 140 },
        { name = "Juwelendanio", count = 0, category = "Foodmaterialien", target = 140 },
        { name = "Rohes Schildkrötenfleisch", count = 0, category = "Foodmaterialien", target = 140 },
        { name = "Rohes Krabbenfleisch", count = 0, category = "Foodmaterialien", target = 140 },

        { name = "Rotblütenlauch", count = 0, category = "Foodmaterialien", target = 500 },
        { name = "Grünkohl", count = 0, category = "Foodmaterialien", target = 500 },
        { name = "Frühlingszwiebeln", count = 0, category = "Foodmaterialien", target = 700 },
        { name = "Rosa Rübe", count = 0, category = "Foodmaterialien", target = 500 },
        { name = "Weiße Rübe", count = 0, category = "Foodmaterialien", target = 500 },
        { name = "Mogukürbis", count = 0, category = "Foodmaterialien", target = 700 },
        { name = "Reismehl", count = 0, category = "Foodmaterialien", target = 100 },
        { name = "Schwarzer Pfeffer", count = 0, category = "Foodmaterialien", target = 100 },

        { name = "Rippchen mit schwarzem Pfeffer und Garnelen", count = 0, category = "Bufffood", target = 200 },
        { name = "Fischeintopf nach Moguart", count = 0, category = "Bufffood", target = 280 },
        { name = "Küstennebelreisnudeln", count = 0, category = "Bufffood", target = 280 },
        { name = "Chun-Tian-Frühlingsrollen", count = 0, category = "Bufffood", target = 200 },
        { name = "Gedämpfte Krabbe à la Surprise", count = 0, category = "Bufffood", target = 200 },
        { name = "Wahnsinniges Brauerfrühstück", count = 0, category = "Bufffood", target = 200 },
        { name = 'Nudelwagenbausatz "Pandarenschatz"', count = 0, category = "Bufffood", target = 50 },

        { name = "Teepflanze", count = 0, category = "Kräuter", target = 280 },
        { name = "Regenmohn", count = 0, category = "Kräuter", target = 280 },
        { name = "Seidenkraut", count = 0, category = "Kräuter", target = 280 },
        { name = "Schneelilie", count = 0, category = "Kräuter", target = 280 },
        { name = "Narrenkappe", count = 0, category = "Kräuter", target = 280 },
        { name = "Goldlotus", count = 0, category = "Kräuter", target = 140 },

        -- Fläschchen (Item-IDs: 76084-76088) und Tränke (76089-76095)
        -- WICHTIG: target ist hier ein Platzhalter (100) - bitte an
        -- den tatsächlichen Gildenbank-Sollbestand anpassen.
        { name = "Fläschchen der Frühlingsblüten", count = 0, category = "Fläschchen", target = 100 },
        { name = "Fläschchen der Sommersonne",     count = 0, category = "Fläschchen", target = 100 },
        { name = "Fläschchen der Herbstblätter",   count = 0, category = "Fläschchen", target = 100 },
        { name = "Fläschchen der Erde",            count = 0, category = "Fläschchen", target = 100 },
        { name = "Fläschchen der Winterkälte",     count = 0, category = "Fläschchen", target = 100 },

        { name = "Biss des Shed-Ling",   count = 0, category = "Tränke", target = 100 },
        { name = "Trank der Berge",      count = 0, category = "Tränke", target = 100 },
        { name = "Trank des Fokus",      count = 0, category = "Tränke", target = 100 },
        { name = "Trank der Jadeschlange", count = 0, category = "Tränke", target = 100 },
        { name = "Trank der Mogukraft",  count = 0, category = "Tränke", target = 100 },
    }
}

--------------------------------------------------
-- Sockelsteine (Gildenbank-Vorrat)
-- Nur die von der Gilde bevorrateten Sorten - Name und Stats werden
-- aus data/gems.lua übernommen, damit es nur eine Quelle für
-- Sockelstein-Daten gibt (statt sie hier erneut zu pflegen).
--------------------------------------------------
local SOCKELSTEIN_IDS = {
    76666, 76659, 76672, 76658,  -- Aragonit (Orange)
    76642, 76643, 76652, 76645,  -- Dioptas (Grün)
    76700, 76697, 76699,         -- Goldberyll (Gelb)
    76680,                       -- Kunzit (Lila)
    76692, 76694, 76696,         -- Rubellit (Rot)
    76639,                       -- Chrysokoll
}

for _, gemId in ipairs(SOCKELSTEIN_IDS) do
    local gem = WeintCodex_Gems[gemId]
    if gem then
        table.insert(sampleData.items, {
            name = gem.name, count = 0, category = "Sockelsteine",
            target = 10, stats = gem.stats,
        })
    end
end

--------------------------------------------------
-- Spalten-Layout (Tabellen-Ansicht)
--------------------------------------------------

local ROW_PAD                = 20
local COL_NAME_X, COL_NAME_W = 34, 230
local COL_COUNT_X            = 280
local COL_BAR_X, COL_BAR_W   = 372, 130
local COL_CAT_X              = 512

-- Schwellwerte relativ zum Sollbestand (target)
local THRESH_GOOD = 0.70
local THRESH_OK   = 0.30

--------------------------------------------------
-- Frame erstellen
--------------------------------------------------

local function CreateMatFrame()
    if matFrame then return matFrame end

    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)

    --------------------------------------------------
    -- Companion-Button (Titelleiste)
    --------------------------------------------------

    local companionBtn = WeintCodex.CreateCard(WeintCodex.TitleBarActions, { width = 96, height = 30, buttonStyle = true })
    companionBtn:SetPoint("TOPRIGHT", WeintCodex.TitleBarActions, "TOPRIGHT", 0, -11)

    local companionLbl = companionBtn:CreateFontString(nil, "OVERLAY")
    companionLbl:SetAllPoints(companionBtn)
    companionLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    companionLbl:SetJustifyH("CENTER")
    companionLbl:SetText("Companion")
    companionLbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])

    companionBtn:SetScript("OnEnter", function(self) self:SetSurface("surface3") end)
    companionBtn:SetScript("OnLeave", function(self) self:SetSurface("surface2") end)
    companionBtn:SetScript("OnClick", function()
        local exportStr = WeintCodex.Materials.GetExportString()
        if exportStr == "" then
            print(WeintCodex.ColorText("danger", "[WeintCodex]") .. " Keine Materialdaten vorhanden.")
            return
        end

        local id = WeintCodex.Companion.Send("materials", exportStr)

        WeintCodex.Dialog.Show([[
            Die Daten wurden erfolgreich vorbereitet.

            Damit Weint Companion die Materialien
            automatisch synchronisieren kann,
            muss die Benutzeroberfläche einmal
            neu geladen werden.
        ]])

        print(WeintCodex.ColorText("success", "[WeintCompanion]") .. " Nachricht #" .. id .. " zur Warteschlange hinzugefügt.")
    end)
    f.CompanionBtn = companionBtn

    --------------------------------------------------
    -- Summary-Leiste
    --------------------------------------------------

    local summary = CreateFrame("Frame", nil, f)
    summary:SetHeight(70)
    summary:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    summary:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

    local summaryDiv = summary:CreateTexture(nil, "OVERLAY")
    summaryDiv:SetHeight(1)
    summaryDiv:SetPoint("BOTTOMLEFT",  summary, "BOTTOMLEFT",  0, 0)
    summaryDiv:SetPoint("BOTTOMRIGHT", summary, "BOTTOMRIGHT", 0, 0)
    summaryDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

    local eyebrow = summary:CreateFontString(nil, "OVERLAY")
    eyebrow:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    eyebrow:SetPoint("TOPLEFT", summary, "TOPLEFT", ROW_PAD, -14)
    eyebrow:SetText(WeintCodex.ColorText("textFaint", "GILDENBANKMATERIALIEN"))

    local titleStr = summary:CreateFontString(nil, "OVERLAY")
    titleStr:SetFont("Fonts\\MORPHEUS.TTF", 19, "")
    titleStr:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)
    titleStr:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    f.Title = titleStr

    local updateStr = summary:CreateFontString(nil, "OVERLAY")
    updateStr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    updateStr:SetPoint("TOPLEFT", titleStr, "BOTTOMLEFT", 2, -4)
    f.UpdateStr = updateStr

    -- Stat-Quartett rechts: GUT / OK / NIEDRIG / GESAMT
    local statDefs = {
        { key = "good",  label = "GUT",     color = "success" },
        { key = "ok",    label = "OK",      color = "warning" },
        { key = "low",   label = "NIEDRIG", color = "danger" },
        { key = "total", label = "GESAMT",  color = "textBright" },
    }
    local statStrs = {}
    local sx = -ROW_PAD
    for i = #statDefs, 1, -1 do
        local def = statDefs[i]
        local box = CreateFrame("Frame", nil, summary)
        box:SetSize(64, 40)
        box:SetPoint("TOPRIGHT", summary, "TOPRIGHT", sx, -14)

        local lbl = box:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        lbl:SetPoint("TOPRIGHT", box, "TOPRIGHT", 0, 0)
        lbl:SetJustifyH("RIGHT")
        lbl:SetText(WeintCodex.ColorText("textFaint", def.label))

        local val = box:CreateFontString(nil, "OVERLAY")
        val:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
        val:SetPoint("TOPRIGHT", lbl, "BOTTOMRIGHT", 0, -4)
        val:SetJustifyH("RIGHT")
        local col = C[def.color] or C.textBright
        val:SetTextColor(col[1], col[2], col[3])
        statStrs[def.key] = val

        sx = sx - 74
    end
    f.StatStrs = statStrs

    --------------------------------------------------
    -- Tabellenkopf
    --------------------------------------------------

    local colBar = CreateFrame("Frame", nil, f)
    colBar:SetHeight(26)
    colBar:SetPoint("TOPLEFT",  summary, "BOTTOMLEFT",  0, 0)
    colBar:SetPoint("TOPRIGHT", summary, "BOTTOMRIGHT", 0, 0)

    local colDiv = colBar:CreateTexture(nil, "OVERLAY")
    colDiv:SetHeight(1)
    colDiv:SetPoint("BOTTOMLEFT",  colBar, "BOTTOMLEFT",  0, 0)
    colDiv:SetPoint("BOTTOMRIGHT", colBar, "BOTTOMRIGHT", 0, 0)
    colDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

    local function ColLbl(text, x)
        local l = colBar:CreateFontString(nil, "OVERLAY")
        l:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        l:SetPoint("LEFT", colBar, "LEFT", x, 0)
        l:SetText(WeintCodex.ColorText("textFaint", text))
    end
    ColLbl("MATERIAL",    COL_NAME_X)
    ColLbl("BESTAND",     COL_COUNT_X)
    ColLbl("FORTSCHRITT", COL_BAR_X)
    ColLbl("KATEGORIE",   COL_CAT_X)

    --------------------------------------------------
    -- Scroll-Bereich
    --------------------------------------------------

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     colBar, "BOTTOMLEFT",  0, 0)
    scroll:SetPoint("BOTTOMRIGHT", f,      "BOTTOMRIGHT", -26, 0)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(600)
    scrollChild:SetHeight(1)
    scroll:SetScrollChild(scrollChild)
    f.ScrollChild = scrollChild

    matFrame = f
    return f
end

--------------------------------------------------
-- Daten anzeigen (optional: Kategorie-Filter)
--------------------------------------------------

local activeMatRows = {}

local function RefreshMatDisplay(matData, filterCat)
    local f  = CreateMatFrame()
    local sc = f.ScrollChild

    for _, row in ipairs(activeMatRows) do row:Hide() end
    wipe(activeMatRows)

    -- Choose data source (imported or sample)
    local dataSource = matData
    local isSample   = false
    if not dataSource or not dataSource.items or #dataSource.items == 0 then
        dataSource = sampleData
        isSample   = true
    end

    if isSample then
        f.UpdateStr:SetText(WeintCodex.ColorText("textFaint", "Beispieldaten — importiere via ")
            .. WeintCodex.ColorText("purple", "Import") .. WeintCodex.ColorText("textFaint", "-Tab"))
    else
        f.UpdateStr:SetText(WeintCodex.ColorText("textFaint", "Stand: " .. (dataSource.date or "unbekannt")))
    end

    f.Title:SetText((not filterCat or filterCat == "Alle") and "Alle Materialien" or filterCat)
    WeintCodex.SetBreadcrumb("Materialien", (not filterCat or filterCat == "Alle") and "Gildenbank" or filterCat)

    local items = dataSource.items
    if filterCat and filterCat ~= "Alle" then
        local filtered = {}
        for _, item in ipairs(items) do
            if (item.category or "") == filterCat then
                filtered[#filtered + 1] = item
            end
        end
        items = filtered
    end

    local goodN, okN, lowN = 0, 0, 0

    if #items == 0 then
        local noData = sc:CreateFontString(nil, "OVERLAY")
        noData:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        noData:SetPoint("TOPLEFT", sc, "TOPLEFT", ROW_PAD, -20)
        noData:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        noData:SetText("Keine Einträge in dieser Kategorie.")
        sc:SetHeight(60)
        table.insert(activeMatRows, noData)
    else
        local offsetY = -2

        for _, item in ipairs(items) do
            local row = CreateFrame("Frame", nil, sc)
            row:SetHeight(30)
            row:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, offsetY)
            row:SetPoint("TOPRIGHT", sc, "TOPRIGHT", 0, offsetY)

            local rowDiv = row:CreateTexture(nil, "OVERLAY")
            rowDiv:SetHeight(1)
            rowDiv:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  0, 0)
            rowDiv:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
            rowDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], 0.60)

            local amount = tonumber(item.count)  or 0
            local target = tonumber(item.target) or 0
            local pct    = (target > 0) and (amount / target) or 0

            local statusColor
            if pct >= THRESH_GOOD then
                statusColor = "success"
                goodN = goodN + 1
            elseif pct >= THRESH_OK then
                statusColor = "warning"
                okN = okN + 1
            else
                statusColor = "danger"
                lowN = lowN + 1
            end
            local sColor = C[statusColor]

            local dot = row:CreateTexture(nil, "OVERLAY")
            dot:SetSize(6, 6)
            dot:SetPoint("LEFT", row, "LEFT", 6, 0)
            dot:SetColorTexture(sColor[1], sColor[2], sColor[3], 1.0)

            local nameLbl = row:CreateFontString(nil, "OVERLAY")
            nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            nameLbl:SetPoint("LEFT", row, "LEFT", COL_NAME_X, 0)
            nameLbl:SetWidth(COL_NAME_W)
            nameLbl:SetJustifyH("LEFT")
            local nc = (statusColor == "danger") and C.textBright or C.textMuted
            nameLbl:SetTextColor(nc[1], nc[2], nc[3])
            nameLbl:SetText(item.name or "?")

            local cntLbl = row:CreateFontString(nil, "OVERLAY")
            cntLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            cntLbl:SetPoint("LEFT", row, "LEFT", COL_COUNT_X, 0)
            if target > 0 then
                cntLbl:SetText(WeintCodex.ColorText(statusColor, tostring(amount)) .. WeintCodex.ColorText("textFaint", " / " .. target))
            else
                cntLbl:SetText(WeintCodex.ColorText(statusColor, tostring(amount)))
            end

            local track = row:CreateTexture(nil, "OVERLAY")
            track:SetSize(COL_BAR_W, 4)
            track:SetPoint("LEFT", row, "LEFT", COL_BAR_X, 0)
            track:SetColorTexture(C.surface3[1], C.surface3[2], C.surface3[3], 1.0)

            local fillPct = math.max(0, math.min(1, pct))
            if fillPct > 0.005 then
                local fill = row:CreateTexture(nil, "OVERLAY")
                fill:SetSize(math.max(1, COL_BAR_W * fillPct), 4)
                fill:SetPoint("LEFT", row, "LEFT", COL_BAR_X, 0)
                fill:SetColorTexture(sColor[1], sColor[2], sColor[3], 1.0)
            end

            if item.category and item.category ~= "" then
                local catLbl = row:CreateFontString(nil, "OVERLAY")
                catLbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
                catLbl:SetPoint("LEFT", row, "LEFT", COL_CAT_X, 0)
                catLbl:SetText(WeintCodex.ColorText("textFaint", item.category))
            end

            table.insert(activeMatRows, row)
            offsetY = offsetY - 30
        end

        sc:SetHeight(math.abs(offsetY) + 10)
    end

    -- Summary-Kacheln aktualisieren
    f.StatStrs.good:SetText(tostring(goodN))
    f.StatStrs.ok:SetText(tostring(okN))
    f.StatStrs.low:SetText(tostring(lowN))
    f.StatStrs.total:SetText(tostring(#items))

    --------------------------------------------------
    -- Inspector: Sync-Status, Auto-Einkaufsliste, Schwellen
    --------------------------------------------------

    -- Nur echte "niedrig"-Positionen (< THRESH_OK vom Soll) aufnehmen,
    -- nicht jede beliebige Unterdeckung - sonst dominieren Items mit
    -- großem Sollbestand die Liste, obwohl sie prozentual im grünen
    -- Bereich liegen.
    local shoppingItems = {}
    for _, item in ipairs(dataSource.items) do
        local amount = tonumber(item.count)  or 0
        local target = tonumber(item.target) or 0
        if target > 0 then
            local pct = amount / target
            if pct < THRESH_OK then
                table.insert(shoppingItems, { name = item.name, missing = target - amount, pct = pct })
            end
        end
    end
    table.sort(shoppingItems, function(a, b) return a.pct < b.pct end)

    local shoppingListItems = {}
    for i = 1, math.min(6, #shoppingItems) do
        local si = shoppingItems[i]
        shoppingListItems[#shoppingListItems + 1] = {
            label = si.name, value = "+" .. si.missing, valueColor = "danger",
        }
    end
    if #shoppingListItems == 0 then
        shoppingListItems[1] = { label = "Alles im Soll", labelColor = "success" }
    end

    WeintCodex.Navigation.SetInspector({
        { type = "header", text = "Sync-Status" },
        { type = "rows", rows = {
            { label = "Letzter Import", value = isSample and "—" or (dataSource.date or "—") },
            { label = "Einträge",       value = tostring(#dataSource.items) },
            { label = "Bot-Kanäle",     value = (WeintCodex.Companion ~= nil) and "verbunden" or "nicht verfügbar",
                valueColor = (WeintCodex.Companion ~= nil) and "success" or "textDim" },
        }},
        { type = "divider" },
        { type = "header", text = "Auto-Einkaufsliste · " .. #shoppingItems .. " Positionen" },
        { type = "list", items = shoppingListItems },
        { type = "divider" },
        { type = "header", text = "Schwellen" },
        { type = "rows", rows = {
            { label = string.format("≥ %.0f%% vom Soll", THRESH_GOOD * 100), value = "gut",    valueColor = "success" },
            { label = string.format("≥ %.0f%% vom Soll", THRESH_OK   * 100), value = "ok",      valueColor = "warning" },
            { label = string.format("< %.0f%% vom Soll", THRESH_OK   * 100), value = "niedrig", valueColor = "danger" },
        }},
        { type = "button", style = "primary", label = "Export für Bot", onClick = function()
            local exportStr = WeintCodex.Materials.GetExportString()
            if exportStr == "" or not WeintCodex.SavedData or not WeintCodex.SavedData.materialData then
                WeintCodex.ShowExportDialog(
                    "Export für Discord-Bot",
                    "Keine Gildenbank-Daten zum Exportieren vorhanden. Bitte zuerst die Gildenbank im Spiel öffnen."
                )
            else
                WeintCodex.ShowExportDialog("Export für Discord-Bot", exportStr)
            end
        end },
        { type = "button", label = "Komplett-Export", onClick = function()
            local exportStr = WeintCodex.Materials.GetFullBankExportString()
            if exportStr == "" or not WeintCodex.SavedData or not WeintCodex.SavedData.guildBankCache then
                WeintCodex.ShowExportDialog(
                    "Komplett-Export der Gildenbank",
                    "Keine Gildenbank-Daten zum Exportieren vorhanden. Bitte zuerst die Gildenbank im Spiel öffnen."
                )
            else
                WeintCodex.ShowExportDialog("Komplett-Export der Gildenbank", exportStr)
            end
        end },
    })
end

-- Fuer die globale Suche (core/search.lua): dieselbe Datenquelle wie Show()
-- verwendet (echter Scan, sonst Platzhalterdaten), ohne die Seite aufzubauen.
function WeintCodex.Materials.GetItems()
    local matData = WeintCodex.SavedData and WeintCodex.SavedData.materialData
    local source  = (matData and matData.items and #matData.items > 0) and matData or sampleData
    return source.items or {}
end

--------------------------------------------------
-- Modul anzeigen
--------------------------------------------------

function WeintCodex.Materials.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    local f = CreateMatFrame()
    f:Show()
    f.CompanionBtn:Show()

    -- Gather categories from current data
    local matData = WeintCodex.SavedData and WeintCodex.SavedData.materialData
    local source  = (matData and matData.items and #matData.items > 0) and matData or sampleData
    local cats    = {}
    local catSeen = {}
    for _, item in ipairs(source.items or {}) do
        local c = item.category or ""
        if c ~= "" and not catSeen[c] then
            cats[#cats + 1] = c
            catSeen[c] = true
        end
    end

    -- Sidebar: "Alle" + each category
    local sidebarItems = {
        {
            label   = "Alle Materialien",
            onClick = function() RefreshMatDisplay(matData, "Alle") end,
        },
        { isGroup = true, label = "KATEGORIEN" },
    }
    for _, cat in ipairs(cats) do
        local cn = cat
        sidebarItems[#sidebarItems + 1] = {
            label   = cn,
            indent  = true,
            onClick = function() RefreshMatDisplay(matData, cn) end,
        }
    end

    WeintCodex.Navigation.BuildSidebar("Materialien", sidebarItems)
    RefreshMatDisplay(matData, "Alle")
end

function WeintCodex.Materials.Refresh(matData)
    if WeintCodex.SavedData then
        WeintCodex.SavedData.materialData = matData
    end
    if matFrame and matFrame:IsShown() then
        RefreshMatDisplay(matData, "Alle")
    end
end

--------------------------------------------------
-- Gildenbank-Scanner & Synchronisations-Logik
--------------------------------------------------

local lastScanTime = 0

local function UpdateRequiredMaterialsFromCache()
    if not WeintCodex.SavedData or not WeintCodex.SavedData.guildBankCache then return end

    -- 1. Sum up all items in cache
    local totals = {}
    for tabIndex, tabData in pairs(WeintCodex.SavedData.guildBankCache) do
        for _, item in ipairs(tabData.items or {}) do
            local name = item.name:lower()
            totals[name] = (totals[name] or 0) + item.count
        end
    end

    -- 2. Build material data from whitelist + guild bank cache

    local newData = {
        date = date("%d.%m.%Y %H:%M"),
        items = {}
    }

    for _, item in ipairs(sampleData.items) do
        local count = totals[item.name:lower()] or 0

        table.insert(newData.items, {
            name     = item.name,
            count    = tostring(count),
                     category = item.category,
                     target   = item.target,
                     stats    = item.stats,
                     note     = string.format("%d/%d", count, item.target)
        })
        end

        WeintCodex.SavedData.materialData = newData

        if matFrame and matFrame:IsShown() then
            RefreshMatDisplay(newData, "Alle")
            end
end

local function ScanCurrentTab()
    if not GuildBankFrame or not GuildBankFrame:IsShown() then return end

    local now = GetTime()
    if now - lastScanTime < 0.5 then return end
    lastScanTime = now

    local tabIndex = GetCurrentGuildBankTab()
    local name, icon, isViewable = GetGuildBankTabInfo(tabIndex)
    if not isViewable then return end

    if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
    if not WeintCodex.SavedData.guildBankCache then WeintCodex.SavedData.guildBankCache = {} end

    local tabData = {
        name = name,
        scanTime = time(),
        items = {}
    }

    -- Scan the 98 slots of the tab
    for slotIndex = 1, 98 do
        local texture, count, locked = GetGuildBankItemInfo(tabIndex, slotIndex)
        local link = GetGuildBankItemLink(tabIndex, slotIndex)
        if link then
            local itemId = tonumber(link:match("item:(%d+)"))
            local itemName = GetItemInfo(link)
            if not itemName then
                itemName = link:match("%[(.-)%]")
            end
            if itemName then
                table.insert(tabData.items, {
                    name = itemName,
                    id = itemId,
                    count = count or 1
                })
            end
        end
    end

    WeintCodex.SavedData.guildBankCache[tabIndex] = tabData
    print(WeintCodex.ColorText("purple", "[WeintCodex]") .. " Gildenbank-Fach '" .. name .. "' erfolgreich gescannt.")

    UpdateRequiredMaterialsFromCache()
end

-- Event Listener Frame
local scanner = CreateFrame("Frame")
scanner:RegisterEvent("GUILDBANKFRAME_OPENED")
scanner:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
scanner:SetScript("OnEvent", function(self, event, ...)
    if event == "GUILDBANKFRAME_OPENED" or event == "GUILDBANKBAGSLOTS_CHANGED" then
        ScanCurrentTab()
    end
end)

--------------------------------------------------
-- Export-String Generatoren für Discord-Bot
--------------------------------------------------

function WeintCodex.Materials.GetExportString()
    if not WeintCodex.SavedData or not WeintCodex.SavedData.materialData or not WeintCodex.SavedData.materialData.items then
        return ""
    end

    local parts = {}
    table.insert(parts, "WCEXPORT")
    table.insert(parts, "MAT")
    table.insert(parts, WeintCodex.SavedData.materialData.date or date("%d.%m.%Y %H:%M"))

    local items = {}
    for _, item in ipairs(WeintCodex.SavedData.materialData.items) do
        -- Stats-Text enthält ", " (z. B. Sockelsteine) - das würde die
        -- items-Trennung per "," oben zerstören, daher hier maskiert.
        local statsField = (item.stats or ""):gsub(",%s*", ";")
        table.insert(items, string.format("%s|%s|%s|%s", item.name, item.count, item.note or "", statsField))
    end
    table.insert(parts, table.concat(items, ","))

    return table.concat(parts, ":")
end

function WeintCodex.Materials.GetFullBankExportString()
    if not WeintCodex.SavedData or not WeintCodex.SavedData.guildBankCache then
        return ""
    end

    local totals = {}
    for tabIndex, tabData in pairs(WeintCodex.SavedData.guildBankCache) do
        for _, item in ipairs(tabData.items or {}) do
            totals[item.name] = (totals[item.name] or 0) + item.count
        end
    end

    local parts = {}
    table.insert(parts, "WCEXPORT")
    table.insert(parts, "GBANK")
    table.insert(parts, date("%d.%m.%Y %H:%M"))

    local items = {}
    for name, count in pairs(totals) do
        table.insert(items, string.format("%s|%d", name, count))
    end
    table.insert(parts, table.concat(items, ","))

    return table.concat(parts, ":")
end
