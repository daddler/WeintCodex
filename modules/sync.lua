--------------------------------------------------
-- WeintCodex :: Sync / Import Module
--
-- Import-Formate (Discord-Bot):
--
-- BOSSGUIDES:
--   WCIMPORT:BOSS:BossName:tank:Tip1,Tip2:healer:Tip1:dps:Tip1::NächsterBoss:...
--
-- RAID (Mittwoch):
--   WCIMPORT:RAIDWED:2026-06-14:2000:Raidtitel:Name1|TANK|WARRIOR|Everlook|,Name2|HEALER|PALADIN|OokOok|Notiz,...
--
-- RAID (Donnerstag):
--   WCIMPORT:RAIDTHU:2026-06-14:2000:Raidtitel:Name1|TANK|WARRIOR|Everlook|,...
--
-- RAID (Legacy – geht zu Mittwoch):
--   WCIMPORT:RAID:2026-06-14:2000:Raidtitel:Name1|TANK|WARRIOR|Everlook|,...
--
-- (Uhrzeit als "HHMM" ohne Doppelpunkt; Realm-Feld leer = Realm des
-- einladenden Spielers wird beim Kalender-Invite angenommen)
--
-- MATERIALIEN:
--   WCIMPORT:MAT:2026-06-14:Webstoff|100|Notiz|Rohstoffe,Pilze|50||Rohstoffe,Stein|25|Engis|Metalle
--
-- WEAKAURAS (eine Kategorie):
--   WCIMPORT:WA:Klassenauren:AuraName|MAGE|Autor|1.0|Beschreibung,...
--------------------------------------------------

WeintCodex.Sync = {}

local C          = WeintCodex.Colors
local importDialog = nil

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
-- Parser: Boss-Guides
--------------------------------------------------

local function ParseBossImport(payload)
    local result    = {}
    local bossParts = {}

    for bossBlock in (payload .. "::"):gmatch("(.-)::") do
        local trimmed = bossBlock:match("^%s*(.-)%s*$")
        if trimmed ~= "" then bossParts[#bossParts + 1] = trimmed end
    end

    for _, block in ipairs(bossParts) do
        local fields = {}
        for field in (block .. ":"):gmatch("([^:]*):") do
            fields[#fields + 1] = field
        end
        local bossName = fields[1]
        if bossName and bossName ~= "" then
            result[bossName] = {}
            local i = 2
            while i <= #fields do
                local roleKey = fields[i]:lower()
                if roleKey == "tank" or roleKey == "healer" or roleKey == "dps" then
                    local tips = {}
                    i = i + 1
                    if fields[i] then
                        for tip in (fields[i] .. ","):gmatch("([^,]*),") do
                            local trimmed = tip:match("^%s*(.-)%s*$")
                            if trimmed ~= "" then tips[#tips + 1] = trimmed end
                        end
                    end
                    result[bossName][roleKey] = tips
                end
                i = i + 1
            end
        end
    end
    return result
end

--------------------------------------------------
-- Parser: Raid-Anmeldungen
-- Format: DATUM:HHMM:TITEL:Name1|ROLLE|KLASSE|REALM|Notiz,Name2|...
-- (Uhrzeit als "HHMM" ohne Doppelpunkt, der wuerde sonst mit dem
-- Feldtrenner kollidieren)
--------------------------------------------------

local function ParseRaidImport(payload)
    local dateStr, timeStr, title, remainder =
        payload:match("^([^:]*):([^:]*):([^:]*):(.*)$")

    if not dateStr then
        -- Altes Format ohne Uhrzeit/Titel (Abwaertskompatibilitaet)
        dateStr   = payload:match("^([^:]*):") or ""
        timeStr   = ""
        title     = ""
        remainder = payload:match("^[^:]*:(.*)$") or ""
    end

    local players = {}

    for playerEntry in (remainder .. ","):gmatch("([^,]*),") do
        local trimmed = playerEntry:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            local pparts = {}
            for pp in (trimmed .. "|"):gmatch("([^|]*)|") do
                pparts[#pparts + 1] = pp:match("^%s*(.-)%s*$")
            end
            if pparts[1] and pparts[1] ~= "" then
                players[#players + 1] = {
                    name  = pparts[1] or "",
                    role  = (pparts[2] or "DPS"):upper(),
                    class = (pparts[3] or ""):upper(),
                    realm = pparts[4] or "",
                    note  = pparts[5] or "",
                }
            end
        end
    end

    local hour   = tonumber(timeStr and timeStr:sub(1, 2))
    local minute = tonumber(timeStr and timeStr:sub(3, 4))

    return {
        date    = dateStr,
        hour    = hour,
        minute  = minute,
        title   = (title and title ~= "") and title or nil,
        players = players,
    }
end

--------------------------------------------------
-- Parser: Materialien
-- Format: DATUM:Name:Menge:Notiz:Name:Menge:Notiz...
--------------------------------------------------

local function ParseMatImport(payload)
    local parts = {}
    for p in (payload .. ":"):gmatch("([^:]*):") do
        parts[#parts + 1] = p
    end

    local date  = parts[1] or ""
    local items = {}

    -- Everything after first colon is a comma-separated list of item entries
    local remainder = payload:match("^[^:]*:(.*)$") or ""
    for itemEntry in (remainder .. ","):gmatch("([^,]*),") do
        local trimmed = itemEntry:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            local iparts = {}
            for ip in (trimmed .. "|"):gmatch("([^|]*)|") do
                iparts[#iparts + 1] = ip:match("^%s*(.-)%s*$")
            end
            if iparts[1] and iparts[1] ~= "" then
                items[#items + 1] = {
                    name     = iparts[1] or "",
                    count    = iparts[2] or "0",
                    note     = iparts[3] or "",
                    category = iparts[4] ~= "" and iparts[4] or "Rohstoffe",
                }
            end
        end
    end

    return { date = date, items = items }
end

--------------------------------------------------
-- Parser: WeakAuras
-- Format: Kategorie:Name1|KLASSE|Autor|Version|Desc,Name2|...
--------------------------------------------------

local function ParseWAImport(payload)
    local cat  = payload:match("^([^:]+):") or "Importiert"
    local rest = payload:match("^[^:]*:(.*)$") or ""

    local auras = {}
    for entry in (rest .. ","):gmatch("([^,]*),") do
        local trimmed = entry:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            local parts = {}
            for pp in (trimmed .. "|"):gmatch("([^|]*)|") do
                parts[#parts + 1] = pp:match("^%s*(.-)%s*$")
            end
            if parts[1] and parts[1] ~= "" then
                auras[#auras + 1] = {
                    name    = parts[1] or "?",
                    class   = (parts[2] or ""):upper(),
                    author  = parts[3] or "?",
                    version = parts[4] or "1.0",
                    desc    = parts[5] or "",
                    color   = {0.54, 0.36, 0.96},
                }
            end
        end
    end

    return { category = cat, auras = auras }
end

--------------------------------------------------
-- Import verarbeiten
--------------------------------------------------

local function ProcessImport(rawStr)
    rawStr = rawStr:match("^%s*(.-)%s*$")
    if rawStr == "" then
        return false, "Leerer Import-String."
    end
    if not rawStr:match("^WCIMPORT:") then
        return false, "Ungültiges Format. String muss mit WCIMPORT: beginnen."
    end

    local typeTag, payload = rawStr:match("^WCIMPORT:([^:]+):(.+)$")
    if not typeTag then
        return false, "Konnte Typ nicht erkennen."
    end
    typeTag = typeTag:upper()

    -- BOSS GUIDES
    if typeTag == "BOSS" then
        local data  = ParseBossImport(payload)
        local count = 0
        for _ in pairs(data) do count = count + 1 end
        if count == 0 then
            return false, "Keine Boss-Daten gefunden. Überprüfe das Format."
        end
        if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
        if not WeintCodex.SavedData.bossData then WeintCodex.SavedData.bossData = {} end
        for bossName, bossData in pairs(data) do
            WeintCodex.SavedData.bossData[bossName] = bossData
        end
        return true, WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-Ready", 14) .. " " .. count .. " Boss-Guide(s) erfolgreich importiert."

    -- RAID MITTWOCH
    elseif typeTag == "RAIDWED" or typeTag == "RAID" then
        local data  = ParseRaidImport(payload)
        local count = data.players and #data.players or 0
        if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
        WeintCodex.SavedData.raidWednesday = data
        if WeintCodex.Raids and WeintCodex.Raids.ResolveNames then
            WeintCodex.Raids.ResolveNames(data)
        end
        if WeintCodex.Raids and WeintCodex.Raids.RefreshDay then
            WeintCodex.Raids.RefreshDay("wednesday", data)
        end
        return true, WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-Ready", 14) .. " Mittwoch-Raid vom " .. data.date .. " mit " .. count .. " Spielern importiert."

    -- RAID DONNERSTAG
    elseif typeTag == "RAIDTHU" then
        local data  = ParseRaidImport(payload)
        local count = data.players and #data.players or 0
        if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
        WeintCodex.SavedData.raidThursday = data
        if WeintCodex.Raids and WeintCodex.Raids.ResolveNames then
            WeintCodex.Raids.ResolveNames(data)
        end
        if WeintCodex.Raids and WeintCodex.Raids.RefreshDay then
            WeintCodex.Raids.RefreshDay("thursday", data)
        end
        return true, WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-Ready", 14) .. " Donnerstag-Raid vom " .. data.date .. " mit " .. count .. " Spielern importiert."

    -- MATERIALIEN
    elseif typeTag == "MAT" then
        local data  = ParseMatImport(payload)
        local count = data.items and #data.items or 0
        if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
        WeintCodex.SavedData.materialData = data
        if WeintCodex.Materials and WeintCodex.Materials.Refresh then
            WeintCodex.Materials.Refresh(data)
        end
        return true, WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-Ready", 14) .. " " .. count .. " Material(ien) importiert (Stand: " .. data.date .. ")."

    -- WEAKAURAS
    elseif typeTag == "WA" then
        local data  = ParseWAImport(payload)
        local count = data.auras and #data.auras or 0
        if not WeintCodex.SavedData then WeintCodex.SavedData = {} end
        if not WeintCodex.SavedData.weakAuras then WeintCodex.SavedData.weakAuras = {} end
        WeintCodex.SavedData.weakAuras[data.category] = data.auras
        if WeintCodex.WeakAuras and WeintCodex.WeakAuras.Refresh then
            WeintCodex.WeakAuras.Refresh(WeintCodex.SavedData.weakAuras)
        end
        return true, WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-Ready", 14) .. " " .. count .. " WeakAura(s) für Kategorie \"" .. data.category .. "\" importiert."

    else
        return false, "Unbekannter Typ: " .. typeTag .. ". Erlaubt: BOSS, RAIDWED, RAIDTHU, MAT, WA"
    end
end

--------------------------------------------------
-- Import-Dialog (vollständige Seite im ContentPanel)
--------------------------------------------------

function WeintCodex.Sync.ShowImportDialog()
    local cp = WeintCodex.ContentPanel
    for _, child in pairs({cp:GetChildren()}) do child:Hide() end
    WeintCodex.Navigation.ClearSidebar()

    if importDialog then
        importDialog:SetParent(cp)
        importDialog:ClearAllPoints()
        importDialog:SetAllPoints(cp)
        importDialog:Show()
        importDialog.EditBox:SetText("")
        importDialog.StatusText:SetText("")
        return
    end

    local f = CreateFrame("Frame", nil, cp)
    f:SetAllPoints(cp)
    importDialog = f

    -- Title
    local titleStr = f:CreateFontString(nil, "OVERLAY")
    titleStr:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    titleStr:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -18)
    titleStr:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    titleStr:SetText("Daten importieren")

    local divider = f:CreateTexture(nil, "OVERLAY")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT",  f, "TOPLEFT",  24, -50)
    divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -24, -50)
    divider:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50)

    -- Help text
    local helpText = f:CreateFontString(nil, "OVERLAY")
    helpText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    helpText:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -62)
    helpText:SetWidth(840)
    helpText:SetJustifyH("LEFT")
    helpText:SetSpacing(3)
    helpText:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    helpText:SetText(
        "Führe im Discord-Bot einen Exportbefehl aus und füge den generierten String unten ein.\n\n" ..
        "|cff9B6BFFBossguides:|r   /export boss        ->  WCIMPORT:BOSS:...\n" ..
        "|cff66ccffRaid Mi:|r       /export raidwed     ->  WCIMPORT:RAIDWED:...\n" ..
        "|cff66ccffRaid Do:|r       /export raidthu     ->  WCIMPORT:RAIDTHU:...\n" ..
        "|cffF59E0BMaterialien:|r  /export mat          ->  WCIMPORT:MAT:...\n" ..
        "|cff33D65EWeakAuras:|r    /export wa           ->  WCIMPORT:WA:..."
    )

    -- Format reference box
    local fmtBg = CreateFrame("Frame", nil, f)
    fmtBg:SetSize(840, 66)
    fmtBg:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -186)
    SetSolidBg(fmtBg, C.bgCard[1], C.bgCard[2], C.bgCard[3], 0.90)
    DrawBorder(fmtBg, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40, 1)

    local fmtTitle = fmtBg:CreateFontString(nil, "OVERLAY")
    fmtTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    fmtTitle:SetPoint("TOPLEFT", fmtBg, "TOPLEFT", 8, -8)
    fmtTitle:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    fmtTitle:SetText("|cff6B5090Format-Referenz:|r")

    local fmtText = fmtBg:CreateFontString(nil, "OVERLAY")
    fmtText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    fmtText:SetPoint("TOPLEFT", fmtTitle, "BOTTOMLEFT", 0, -2)
    fmtText:SetWidth(824)
    fmtText:SetJustifyH("LEFT")
    fmtText:SetSpacing(2)
    fmtText:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    fmtText:SetText(
        "BOSS: WCIMPORT:BOSS:BossName:tank:Tip1,Tip2:healer:Tip1:dps:Tip1::NächsterBoss:...\n" ..
        "RAID: WCIMPORT:RAIDWED:DATUM:HHMM:TITEL:Name|TANK|WARRIOR|REALM|,Name2|HEALER|PALADIN|REALM|,..." ..
        "    WA: WCIMPORT:WA:Kategorie:AuraName|KLASSE|Autor|v|Beschreibung,..."
    )

    -- EditBox label
    local editLabel = f:CreateFontString(nil, "OVERLAY")
    editLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    editLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -264)
    editLabel:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    editLabel:SetText("Import-String einfügen  (Strg+V):")

    -- EditBox background
    local editBg = CreateFrame("Frame", nil, f)
    editBg:SetSize(840, 120)
    editBg:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -280)
    SetSolidBg(editBg, 0.04, 0.02, 0.10, 0.95)
    DrawBorder(editBg, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.60, 1)

    local editBox = CreateFrame("EditBox", nil, editBg)
    editBox:SetSize(830, 114)
    editBox:SetPoint("TOPLEFT", editBg, "TOPLEFT", 5, -3)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetAutoFocus(false)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    editBox:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    editBox:SetTextInsets(6, 6, 6, 6)

    local editScroll = CreateFrame("ScrollFrame", nil, editBg, "UIPanelScrollFrameTemplate")
    editScroll:SetSize(830, 114)
    editScroll:SetPoint("TOPLEFT", editBg, "TOPLEFT", 0, 0)
    editScroll:SetScrollChild(editBox)

    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnTabPressed",    function(self) self:ClearFocus() end)
    f.EditBox = editBox

    -- Buttons row
    local importBtn = CreateFrame("Button", nil, f)
    importBtn:SetSize(200, 38)
    importBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -412)
    SetSolidBg(importBtn, C.purple[1], C.purple[2], C.purple[3], 0.80)
    DrawBorder(importBtn, C.purple[1], C.purple[2], C.purple[3], 1.0, 1)

    local importBtnLbl = importBtn:CreateFontString(nil, "OVERLAY")
    importBtnLbl:SetAllPoints(importBtn)
    importBtnLbl:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    importBtnLbl:SetText("|cffffffff" .. WeintCodex.Icon("Interface\\Icons\\INV_Misc_Note_01", 14) .. "  Importieren|r")

    importBtn:SetScript("OnEnter", function(self)
        SetSolidBg(self, math.min(1, C.purple[1] * 1.3), math.min(1, C.purple[2] * 1.3), math.min(1, C.purple[3] * 1.2), 0.95)
    end)
    importBtn:SetScript("OnLeave", function(self)
        SetSolidBg(self, C.purple[1], C.purple[2], C.purple[3], 0.80)
    end)

    local clearBtn = CreateFrame("Button", nil, f)
    clearBtn:SetSize(120, 38)
    clearBtn:SetPoint("TOPLEFT", importBtn, "TOPRIGHT", 12, 0)
    SetSolidBg(clearBtn, 0.22, 0.08, 0.08, 0.80)
    DrawBorder(clearBtn, 0.55, 0.15, 0.15, 0.80, 1)

    local clearBtnLbl = clearBtn:CreateFontString(nil, "OVERLAY")
    clearBtnLbl:SetAllPoints(clearBtn)
    clearBtnLbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    clearBtnLbl:SetText("|cffff8888Leeren|r")

    clearBtn:SetScript("OnClick", function()
        editBox:SetText("")
        editBox:SetFocus()
        f.StatusText:SetText("")
    end)

    -- Status text
    local statusText = f:CreateFontString(nil, "OVERLAY")
    statusText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    statusText:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -462)
    statusText:SetWidth(840)
    statusText:SetJustifyH("LEFT")
    f.StatusText = statusText

    -- Import-Historie (letzte Importe)
    local histTitle = f:CreateFontString(nil, "OVERLAY")
    histTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    histTitle:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -490)
    histTitle:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    histTitle:SetText("|cff4B4060— Letzte Importe —|r")

    local histText = f:CreateFontString(nil, "OVERLAY")
    histText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    histText:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -508)
    histText:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    histText:SetWidth(840)
    histText:SetSpacing(3)
    f.HistText = histText

    local function UpdateHistory()
        local sd  = WeintCodex.SavedData
        local lines = {}
        if sd then
            if sd.raidWednesday and sd.raidWednesday.date and sd.raidWednesday.date ~= "" then
                lines[#lines+1] = "|cff66ccff" .. WeintCodex.Icon("Interface\\Icons\\Ability_Warrior_BattleShout", 14) .. "|r  Mittwoch-Raid:   " .. sd.raidWednesday.date .. "   (" .. (sd.raidWednesday.players and #sd.raidWednesday.players or 0) .. " Spieler)"
            end
            if sd.raidThursday and sd.raidThursday.date and sd.raidThursday.date ~= "" then
                lines[#lines+1] = "|cff66ccff" .. WeintCodex.Icon("Interface\\Icons\\Ability_Warrior_BattleShout", 14) .. "|r  Donnerstag-Raid: " .. sd.raidThursday.date .. "   (" .. (sd.raidThursday.players and #sd.raidThursday.players or 0) .. " Spieler)"
            end
            if sd.materialData and sd.materialData.date and sd.materialData.date ~= "" then
                lines[#lines+1] = "|cffF59E0B" .. WeintCodex.Icon("Interface\\Icons\\INV_Crate_01", 14) .. "|r  Materialien:     " .. sd.materialData.date .. "   (" .. (sd.materialData.items and #sd.materialData.items or 0) .. " Einträge)"
            end
        end
        if #lines == 0 then
            histText:SetText("|cff3B2D60Noch keine Importe vorhanden.|r")
        else
            histText:SetText(table.concat(lines, "\n"))
        end
    end

    UpdateHistory()

    -- Import button logic
    importBtn:SetScript("OnClick", function()
        local raw = editBox:GetText()
        raw = raw:match("^%s*(.-)%s*$")
        if raw == "" then
            f.StatusText:SetText("|cffff6666" .. WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-NotReady", 14) .. " Bitte einen Import-String einfügen.|r")
            return
        end

        local ok, msg = ProcessImport(raw)
        if ok then
            f.StatusText:SetText("|cff33D65E" .. msg .. "|r")
            editBox:SetText("")
            UpdateHistory()
            C_Timer.After(0.8, function()
                print("|cff8B5CF6[WeintCodex]|r |cff33D65E" .. msg .. "|r")
            end)
        else
            f.StatusText:SetText("|cffff6666" .. WeintCodex.Icon("Interface\\RaidFrame\\ReadyCheck-NotReady", 14) .. " Fehler: " .. msg .. "|r")
        end
    end)
end

--------------------------------------------------
-- Quick import via /wc import <string>
--------------------------------------------------

function WeintCodex.Sync.QuickImport(str)
    local ok, msg = ProcessImport(str)
    if ok then
        print("|cff8B5CF6[WeintCodex Import]|r |cff33D65E" .. msg .. "|r")
    else
        print("|cff8B5CF6[WeintCodex Import]|r |cffff6666Fehler: " .. msg .. "|r")
    end
end
