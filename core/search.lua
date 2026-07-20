--------------------------------------------------
-- WeintCodex :: Globale Suche (Titelleiste, Strg+K)
-- Baut einen flachen Treffer-Index aus Boss-/Verzauberungs-/Material-
-- Namen und zeigt passende Treffer in einem Dropdown unter dem Suchfeld
-- (core/ui.lua:WeintCodex.SearchBox/WeintCodex.SearchResults). Wird als
-- letzte Datei geladen (siehe WeintCodex.toc), damit alle referenzierten
-- Datentabellen/Module beim Aufbau bereits existieren.
--------------------------------------------------

WeintCodex.Search = {}

local C = WeintCodex.Colors
local MAX_RESULTS = 8
local ROW_H = 26

local CATEGORY_LABEL = {
    boss     = "BOSS",
    enchant  = "VERZAUBERUNG",
    material = "MATERIAL",
}

--------------------------------------------------
-- Index aufbauen (klein genug, um bei jeder Eingabe neu zu bauen - so
-- sind frisch importierte Gildenbank-/Charakterdaten immer aktuell)
--------------------------------------------------

local function BuildIndex()
    local index = {}

    if WeintCodex_BossData then
        for bossName in pairs(WeintCodex_BossData) do
            index[#index + 1] = {
                category = "boss",
                label    = bossName,
                onClick  = function()
                    WeintCodex.Navigation.SwitchTo("bossguides")
                    if WeintCodex.BossGuides and WeintCodex.BossGuides.ShowBoss then
                        WeintCodex.BossGuides.ShowBoss(bossName)
                    end
                end,
            }
        end
    end

    if WeintCodex_Enchants then
        for _, def in pairs(WeintCodex_Enchants) do
            if def.name then
                index[#index + 1] = {
                    category = "enchant",
                    label    = def.name .. (def.slot and (" (" .. def.slot .. ")") or ""),
                    onClick  = function()
                        WeintCodex.Navigation.SwitchTo("charakter")
                        if WeintCodex.Charakter and WeintCodex.Charakter.ShowEnchants then
                            WeintCodex.Charakter.ShowEnchants()
                        end
                    end,
                }
            end
        end
    end

    if WeintCodex.Materials and WeintCodex.Materials.GetItems then
        for _, item in ipairs(WeintCodex.Materials.GetItems()) do
            if item.name then
                index[#index + 1] = {
                    category = "material",
                    label    = item.name,
                    onClick  = function()
                        WeintCodex.Navigation.SwitchTo("materials")
                    end,
                }
            end
        end
    end

    return index
end

local function Filter(query)
    query = query:lower()
    local index = BuildIndex()
    local matches = {}
    for _, entry in ipairs(index) do
        if entry.label:lower():find(query, 1, true) then
            matches[#matches + 1] = entry
            if #matches >= MAX_RESULTS then break end
        end
    end
    return matches
end

--------------------------------------------------
-- Dropdown befuellen
--------------------------------------------------

local resultRows = {}

local function GetRow(i)
    local row = resultRows[i]
    if row then return row end

    row = CreateFrame("Button", nil, WeintCodex.SearchResults)
    row:SetHeight(ROW_H)
    row:SetPoint("LEFT",  WeintCodex.SearchResults, "LEFT",  0, 0)
    row:SetPoint("RIGHT", WeintCodex.SearchResults, "RIGHT", 0, 0)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(0, 0, 0, 0)
    row._bg = bg

    local tag = row:CreateFontString(nil, "OVERLAY")
    tag:SetFont(WeintCodex.Fonts.mono, 9, "")
    tag:SetPoint("LEFT", row, "LEFT", 10, 0)
    tag:SetWidth(78)
    tag:SetJustifyH("LEFT")
    tag:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
    row._tag = tag

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    label:SetPoint("LEFT",  row, "LEFT",  92, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
    row._label = label

    row:SetScript("OnEnter", function(self) self._bg:SetColorTexture(C.surface2[1], C.surface2[2], C.surface2[3], 1.0) end)
    row:SetScript("OnLeave", function(self) self._bg:SetColorTexture(0, 0, 0, 0) end)
    row:SetScript("OnClick", function(self)
        if self._onClick then self._onClick() end
        WeintCodex.Search.CloseDropdown()
        WeintCodex.SearchBox:SetText("")
        WeintCodex.SearchBox:ClearFocus()
    end)

    resultRows[i] = row
    return row
end

local currentMatches = {}

local function RenderMatches(matches)
    currentMatches = matches
    for i, entry in ipairs(matches) do
        local row = GetRow(i)
        row._tag:SetText(WeintCodex.ColorText("textFaint", CATEGORY_LABEL[entry.category] or ""))
        row._label:SetText(entry.label)
        row._onClick = entry.onClick
        row:SetPoint("TOP", WeintCodex.SearchResults, "TOP", 0, -(i - 1) * ROW_H)
        row:Show()
    end
    for i = #matches + 1, #resultRows do
        resultRows[i]:Hide()
    end

    if #matches > 0 then
        WeintCodex.SearchResults:SetHeight(#matches * ROW_H + 2)
        WeintCodex.SearchResults:Show()
    else
        WeintCodex.SearchResults:Hide()
    end
end

--------------------------------------------------
-- Oeffentliche Hooks (werden von core/ui.lua's EditBox-Scripts aufgerufen)
--------------------------------------------------

function WeintCodex.Search.OnTextChanged(text)
    if text == "" then
        WeintCodex.SearchResults:Hide()
        currentMatches = {}
        return
    end
    RenderMatches(Filter(text))
end

function WeintCodex.Search.OnFocusGained(text)
    if text ~= "" then
        RenderMatches(Filter(text))
    end
end

function WeintCodex.Search.OnFocusLost()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.15, function()
            if not WeintCodex.SearchBox:HasFocus() then
                WeintCodex.SearchResults:Hide()
            end
        end)
    else
        WeintCodex.SearchResults:Hide()
    end
end

function WeintCodex.Search.CloseDropdown()
    WeintCodex.SearchResults:Hide()
    currentMatches = {}
end

-- Enter waehlt den obersten Treffer (ueberschreibt den simplen ClearFocus-
-- Fallback aus core/ui.lua, sobald dieses Modul geladen ist)
WeintCodex.SearchBox:SetScript("OnEnterPressed", function(self)
    if currentMatches[1] then
        currentMatches[1].onClick()
    end
    WeintCodex.Search.CloseDropdown()
    self:SetText("")
    self:ClearFocus()
end)

--------------------------------------------------
-- Strg+K: fokussiert das Suchfeld, solange das WeintCodex-Fenster offen ist.
-- Kein globales Blizzard-Keybinding (dafuer gibt es keine bestehende
-- Infrastruktur) - greift nur, waehrend WeintCodex.MainFrame sichtbar ist,
-- und laesst alle anderen Tasten unangetastet durch (SetPropagateKeyboardInput).
--------------------------------------------------

local frame = WeintCodex.MainFrame
frame:EnableKeyboard(true)
frame:SetScript("OnKeyDown", function(self, key)
    if IsControlKeyDown() and key == "K" then
        self:SetPropagateKeyboardInput(false)
        WeintCodex.SearchBox:SetFocus()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

frame:HookScript("OnHide", function()
    WeintCodex.SearchResults:Hide()
end)
