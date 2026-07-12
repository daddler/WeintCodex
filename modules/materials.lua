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
-- Frame erstellen
--------------------------------------------------

local function CreateMatFrame()
    if matFrame then return matFrame end

    local cp = WeintCodex.ContentPanel
    local f  = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)

    -- Header
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(72)
    header:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    SetSolidBg(header, C.bgMid[1], C.bgMid[2], C.bgMid[3], 0.50)

    local titleStr = header:CreateFontString(nil, "OVERLAY")
    titleStr:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    titleStr:SetPoint("TOPLEFT", header, "TOPLEFT", 20, -14)
    titleStr:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    titleStr:SetText("Gildenbankmaterialien")
    f.Title = titleStr

    local updateStr = header:CreateFontString(nil, "OVERLAY")
    updateStr:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    updateStr:SetPoint("BOTTOMLEFT", titleStr, "BOTTOMRIGHT", 10, 2)
    updateStr:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    f.UpdateStr = updateStr

    -- Export Buttons
    --------------------------------------------------

    -- Export für Bot

    local exportBtn = CreateFrame("Button", nil, header)
    exportBtn:SetSize(130, 26)
    exportBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT", -20, -14)

    SetSolidBg(exportBtn, C.purple[1], C.purple[2], C.purple[3], 0.80)
    DrawBorder(exportBtn, C.purple[1], C.purple[2], C.purple[3], 1.0, 1)

    local exportLbl = exportBtn:CreateFontString(nil, "OVERLAY")
    exportLbl:SetAllPoints(exportBtn)
    exportLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    exportLbl:SetText("Export für Bot")
    exportLbl:SetTextColor(1, 1, 1)

    exportBtn:SetScript("OnEnter", function(self)
    SetSolidBg(self, C.purple[1] * 1.25, C.purple[2] * 1.25, C.purple[3] * 1.15, 0.90)
    end)

    exportBtn:SetScript("OnLeave", function(self)
    SetSolidBg(self, C.purple[1], C.purple[2], C.purple[3], 0.80)
    end)

    exportBtn:SetScript("OnClick", function()

    local exportStr = WeintCodex.Materials.GetExportString()

    if exportStr == "" or
        not WeintCodex.SavedData or
        not WeintCodex.SavedData.materialData then

        WeintCodex.ShowExportDialog(
            "Export für Discord-Bot",
            "Keine Gildenbank-Daten zum Exportieren vorhanden. Bitte zuerst die Gildenbank im Spiel öffnen."
        )

        else

            WeintCodex.ShowExportDialog(
                "Export für Discord-Bot",
                exportStr
            )

            end

            end)

    --------------------------------------------------
    -- Komplett-Export
    --------------------------------------------------

    local fullExportBtn = CreateFrame("Button", nil, header)
    fullExportBtn:SetSize(130, 26)
    fullExportBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT", -160, -14)

    SetSolidBg(fullExportBtn, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80)
    DrawBorder(fullExportBtn, C.purple[1], C.purple[2], C.purple[3], 1.0, 1)

    local fullExportLbl = fullExportBtn:CreateFontString(nil, "OVERLAY")
    fullExportLbl:SetAllPoints(fullExportBtn)
    fullExportLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    fullExportLbl:SetText("Komplett-Export")
    fullExportLbl:SetTextColor(1, 1, 1)

    fullExportBtn:SetScript("OnEnter", function(self)
    SetSolidBg(self, C.purple[1] * 0.90, C.purple[2] * 0.90, C.purple[3] * 0.90, 0.90)
    end)

    fullExportBtn:SetScript("OnLeave", function(self)
    SetSolidBg(self, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80)
    end)

    fullExportBtn:SetScript("OnClick", function()

    local exportStr = WeintCodex.Materials.GetFullBankExportString()

    if exportStr == "" or
        not WeintCodex.SavedData or
        not WeintCodex.SavedData.guildBankCache then

        WeintCodex.ShowExportDialog(
            "Komplett-Export der Gildenbank",
            "Keine Gildenbank-Daten zum Exportieren vorhanden. Bitte zuerst die Gildenbank im Spiel öffnen."
        )

        else

            WeintCodex.ShowExportDialog(
                "Komplett-Export der Gildenbank",
                exportStr
            )

            end

            end)

    --------------------------------------------------
    -- Companion
    --------------------------------------------------

    local companionBtn = CreateFrame("Button", nil, header)
    companionBtn:SetSize(130, 26)
    companionBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT", -300, -14)

    SetSolidBg(companionBtn, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80)
    DrawBorder(companionBtn, C.purple[1], C.purple[2], C.purple[3], 1.0, 1)

    local companionLbl = companionBtn:CreateFontString(nil, "OVERLAY")
    companionLbl:SetAllPoints(companionBtn)
    companionLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    companionLbl:SetText("Companion")
    companionLbl:SetTextColor(1, 1, 1)

    companionBtn:SetScript("OnEnter", function(self)
    SetSolidBg(self, C.purple[1] * 0.90, C.purple[2] * 0.90, C.purple[3] * 0.90, 0.90)
    end)

    companionBtn:SetScript("OnLeave", function(self)
    SetSolidBg(self, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80)
    end)

    companionBtn:SetScript("OnClick", function()

    local exportStr = WeintCodex.Materials.GetExportString()

    if exportStr == "" then

        print("|cffff4444[WeintCodex]|r Keine Materialdaten vorhanden.")

        return

        end

        local id = WeintCodex.Companion.Send(
            "materials",
            exportStr
        )

        WeintCodex.Dialog.Show([[
            Die Daten wurden erfolgreich vorbereitet.

            Damit Weint Companion die Materialien
            automatisch synchronisieren kann,
            muss die Benutzeroberfläche einmal
            neu geladen werden.
        ]])

        print(
            "|cff00ff00[WeintCompanion]|r Nachricht #" ..
            id ..
            " zur Warteschlange hinzugefügt."
        )

        end)
    -- Legend bar (status colors)
    local legendBar = CreateFrame("Frame", nil, header)
    legendBar:SetHeight(22)
    legendBar:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  16, 8)
    legendBar:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -16, 8)

    local function LegendDot(text, x, r, g, b)
        local dot = legendBar:CreateTexture(nil, "OVERLAY")
        dot:SetSize(10, 10)
        dot:SetPoint("LEFT", legendBar, "LEFT", x, 0)
        dot:SetColorTexture(r, g, b, 0.90)

        local lbl = legendBar:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        lbl:SetPoint("LEFT", legendBar, "LEFT", x + 14, 0)
        lbl:SetText("|cff888888" .. text .. "|r")
    end
    LegendDot("≥ 100: gut", 0, 0.13, 0.77, 0.37)
    LegendDot("≥ 20: ok",  130, 0.96, 0.76, 0.20)
    LegendDot("< 20: niedrig", 256, 0.95, 0.35, 0.25)

    local headerDiv = header:CreateTexture(nil, "OVERLAY")
    headerDiv:SetHeight(1)
    headerDiv:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  0, 0)
    headerDiv:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50)

    -- Column labels
    local colBar = CreateFrame("Frame", nil, f)
    colBar:SetHeight(22)
    colBar:SetPoint("TOPLEFT",  header, "BOTTOMLEFT",  0, 0)
    colBar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    SetSolidBg(colBar, C.bgMid[1], C.bgMid[2], C.bgMid[3], 0.35)

    local function ColLbl(text, x)
        local l = colBar:CreateFontString(nil, "OVERLAY")
        l:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        l:SetPoint("LEFT", colBar, "LEFT", x, 0)
        l:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        l:SetText(text)
    end
    ColLbl("Material",    16)
    ColLbl("Bestand",    320)
    ColLbl("Kategorie",  500)

    local colDiv = colBar:CreateTexture(nil, "OVERLAY")
    colDiv:SetHeight(1)
    colDiv:SetPoint("BOTTOMLEFT",  colBar, "BOTTOMLEFT",  0, 0)
    colDiv:SetPoint("BOTTOMRIGHT", colBar, "BOTTOMRIGHT", 0, 0)
    colDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.30)

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     colBar, "BOTTOMLEFT",  0,   0)
    scroll:SetPoint("BOTTOMRIGHT", f,      "BOTTOMRIGHT", -4,  4)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(860)
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
    for _, child in pairs({sc:GetChildren()}) do child:Hide() end
    for _, child in pairs({sc:GetRegions()}) do child:Hide() end
    wipe(activeMatRows)

    -- Choose data source (imported or sample)
    local dataSource = matData
    local isSample   = false
    if not dataSource or not dataSource.items or #dataSource.items == 0 then
        dataSource = sampleData
        isSample   = true
    end

    if isSample then
        f.UpdateStr:SetText("|cff3B2D60Beispieldaten — importiere via |r|cff8B5CF6Import|r|cff3B2D60-Tab|r")
    else
        f.UpdateStr:SetText("|cff5B4880Stand: " .. (dataSource.date or "unbekannt") .. "|r")
    end

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

    if #items == 0 then
        local noData = sc:CreateFontString(nil, "OVERLAY")
        noData:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
        noData:SetPoint("TOPLEFT", sc, "TOPLEFT", 16, -20)
        noData:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        noData:SetText("Keine Einträge in dieser Kategorie.")
        sc:SetHeight(60)
        table.insert(activeMatRows, noData)
        return
    end

    local offsetY = -4
    local altRow  = false

    for _, item in ipairs(items) do
        local row = CreateFrame("Frame", nil, sc)
        row:SetHeight(28)
        row:SetPoint("TOPLEFT",  sc, "TOPLEFT",  0, offsetY)
        row:SetPoint("TOPRIGHT", sc, "TOPRIGHT", -6, offsetY)

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints(row)
        if altRow then
            rowBg:SetColorTexture(C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.50)
        else
            rowBg:SetColorTexture(0, 0, 0, 0)
        end
        altRow = not altRow

        local amount = tonumber(item.count) or 0
        local target = tonumber(item.target) or 0

        local amountColor
        local statusStrip

        local percent = 0

        if target > 0 then
            percent = amount / target
            end

            if percent >= 0.70 then
                amountColor = "|cff22C55E"
                statusStrip = {0.13, 0.77, 0.37}
                elseif percent >= 0.30 then
                    amountColor = "|cffF59E0B"
                    statusStrip = {0.96, 0.76, 0.20}
                    else
                        amountColor = "|cffEF4444"
                        statusStrip = {0.95, 0.35, 0.25}
                        end

        -- Status color strip
        local strip = row:CreateTexture(nil, "OVERLAY")
        strip:SetSize(2, 28)
        strip:SetPoint("LEFT", row, "LEFT", 0, 0)
        strip:SetColorTexture(statusStrip[1], statusStrip[2], statusStrip[3], 0.80)

        -- Item name
        local nameLbl = row:CreateFontString(nil, "OVERLAY")
        nameLbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        nameLbl:SetPoint("LEFT", row, "LEFT", 12, 0)
        nameLbl:SetText("|cffdddddd" .. (item.name or "?") .. "|r")
        nameLbl:SetWidth(296)

        -- Count
        local cntLbl = row:CreateFontString(nil, "OVERLAY")
        cntLbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        cntLbl:SetPoint("LEFT", row, "LEFT", 320, 0)
        local target = tonumber(item.target) or 0

        if target > 0 then
            cntLbl:SetText(amountColor .. amount .. "/" .. target .. "|r")
            else
                cntLbl:SetText(amountColor .. amount .. "|r")
                end

        -- Category tag
        if item.category and item.category ~= "" then
            local catLbl = row:CreateFontString(nil, "OVERLAY")
            catLbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            catLbl:SetPoint("LEFT", row, "LEFT", 430, 0)
            catLbl:SetText("|cff4B4880" .. item.category .. "|r")
            catLbl:SetWidth(120)
        end


        table.insert(activeMatRows, row)
        offsetY = offsetY - 28
    end

    sc:SetHeight(math.abs(offsetY) + 14)
end

--------------------------------------------------
-- Modul anzeigen
--------------------------------------------------

function WeintCodex.Materials.Show()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end

    local f = CreateMatFrame()
    f:Show()

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
    print("|cff8B5CF6[WeintCodex]|r Gildenbank-Fach '" .. name .. "' erfolgreich gescannt.")

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
        table.insert(items, string.format("%s|%s|%s", item.name, item.count, item.note or ""))
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
