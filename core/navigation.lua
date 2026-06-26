--------------------------------------------------
-- WeintCodex :: Navigation (Tab System)
--------------------------------------------------

WeintCodex.Navigation = {}

local C = WeintCodex.Colors
local activeTab = nil

local tabs = {
    { id = "charakter",  label = "|TInterface\\Icons\\Achievement_Character_Human_Male:14|t Charakter" },
    { id = "bossguides", label = "|TInterface\\Icons\\Achievement_Boss_LichKing:14|t Bossguides" },
    { id = "raids",      label = "|TInterface\\Icons\\Ability_Warrior_BattleShout:14|t Raids" },
    { id = "materials",  label = "|TInterface\\Icons\\INV_Crate_01:14|t Materialien" },
    { id = "calendar",   label = "|TInterface\\Icons\\INV_Misc_PocketWatch_01:14|t Kalender" },
    { id = "weakauras",  label = "|TInterface\\Icons\\Spell_Holy_MagicalSentry:14|t WeakAuras" },
    { id = "import",     label = "|TInterface\\Icons\\INV_Misc_Note_01:14|t Import" },
}

local tabButtons = {}
local offsetX    = 10

local function SetTabActive(btn, isActive)
    if isActive then
        btn._bg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.22)
        btn._underline:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1.0)
        btn._label:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    else
        btn._bg:SetColorTexture(0, 0, 0, 0)
        btn._underline:SetColorTexture(0, 0, 0, 0)
        btn._label:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    end
end

for _, tabDef in ipairs(tabs) do
    local btn = CreateFrame("Button", nil, WeintCodex.TabBar)

    btn:SetSize(100, 40)
    btn:SetPoint("TOPLEFT", WeintCodex.TabBar, "TOPLEFT", 0, 0)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetColorTexture(0, 0, 0, 0)
    btn._bg = bg

    local underline = btn:CreateTexture(nil, "OVERLAY")
    underline:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    underline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    underline:SetHeight(2)
    underline:SetColorTexture(0, 0, 0, 0)
    btn._underline = underline

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetAllPoints(btn)
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    lbl:SetText(tabDef.label)
    lbl:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
    btn._label = lbl

    btn:SetScript("OnEnter", function(self)
        if activeTab ~= tabDef.id then
            self._bg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.10)
            self._label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if activeTab ~= tabDef.id then
            self._bg:SetColorTexture(0, 0, 0, 0)
            self._label:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        end
    end)
    btn:SetScript("OnClick", function(self)
        if activeTab == tabDef.id then return end
        for _, b in ipairs(tabButtons) do SetTabActive(b, false) end
        SetTabActive(self, true)
        activeTab = tabDef.id
        WeintCodex.Navigation.SwitchTo(tabDef.id)
    end)

    tabButtons[tabDef.id] = btn
    table.insert(tabButtons, btn)
end

local function UpdateTabLayout()

local tabWidth =
(WeintCodex.TabBar:GetWidth() - 20) / #tabs

local x = 10

for _, btn in ipairs(tabButtons) do
    btn:SetWidth(tabWidth)
    btn:ClearAllPoints()
    btn:SetPoint(
        "TOPLEFT",
        WeintCodex.TabBar,
        "TOPLEFT",
        x,
        0
    )

    x = x + tabWidth
    end
    end

    WeintCodex.TabBar:SetScript(
        "OnSizeChanged",
        UpdateTabLayout
    )

    UpdateTabLayout()
--------------------------------------------------
-- Sidebar builder
--------------------------------------------------

local sidebarItems  = {}
local sidebarGroups = {}

function WeintCodex.Navigation.ClearSidebar()
    for _, item in ipairs(sidebarItems) do item:Hide() end
    for _, grp  in ipairs(sidebarGroups) do grp:Hide()  end
    wipe(sidebarItems)
    wipe(sidebarGroups)
    WeintCodex.SidebarHeader:SetText("|cff4B4060— NAVIGATION —|r")
end

-- Build flat list of items
function WeintCodex.Navigation.BuildSidebar(sectionTitle, items)
    WeintCodex.Navigation.ClearSidebar()
    WeintCodex.SidebarHeader:SetText("|cff8B5CF6" .. (sectionTitle or "") .. "|r")

    local sidebar  = WeintCodex.Sidebar
    local offsetY  = -34

    for _, itemDef in ipairs(items) do
        local isGroup = itemDef.isGroup

        if isGroup then
            local lbl = sidebar:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            lbl:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, offsetY)
            lbl:SetText("|cff5B4880" .. (itemDef.label or "") .. "|r")
            lbl:SetWidth(192)
            table.insert(sidebarGroups, lbl)
            offsetY = offsetY - 18
        else
            local indent = itemDef.indent and 20 or 5

            local btn = CreateFrame("Button", nil, sidebar)
            btn:SetSize(202, 28)
            btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", indent, offsetY)

            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(btn)
            bg:SetColorTexture(0, 0, 0, 0)
            btn._bg = bg

            local accent = btn:CreateTexture(nil, "OVERLAY")
            accent:SetSize(3, 28)
            accent:SetPoint("LEFT", btn, "LEFT", 0, 0)
            accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.0)
            btn._accent = accent

            local iconOffsetX = 12

            if itemDef.portrait then
                local iconBox = btn:CreateTexture(nil, "OVERLAY")
                iconBox:SetSize(20, 20)
                iconBox:SetPoint("LEFT", btn, "LEFT", 8, 0)
                iconBox:SetTexture("Interface\\AddOns\\WeintCodex\\" .. itemDef.portrait)
                iconOffsetX = 34
            elseif itemDef.iconColor then
                local iconBox = btn:CreateTexture(nil, "OVERLAY")
                iconBox:SetSize(16, 16)
                iconBox:SetPoint("LEFT", btn, "LEFT", 12, 0)
                iconBox:SetColorTexture(
                    itemDef.iconColor[1],
                    itemDef.iconColor[2],
                    itemDef.iconColor[3],
                    0.85
                )
                iconOffsetX = 34
            end

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetPoint("LEFT", btn, "LEFT", iconOffsetX, 0)
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            lbl:SetText(itemDef.label or "")
            lbl:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
            lbl:SetWidth(180 - iconOffsetX)
            btn._label = lbl

            local function SetActive(self, on)
                if on then
                    self._bg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.20)
                    self._accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 1.0)
                    self._label:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
                else
                    self._bg:SetColorTexture(0, 0, 0, 0)
                    self._accent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.0)
                    self._label:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
                end
            end
            btn.SetActive = SetActive

            btn:SetScript("OnEnter", function(self)
                if not self._isActive then
                    self._bg:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.10)
                end
            end)
            btn:SetScript("OnLeave", function(self)
                if not self._isActive then
                    self._bg:SetColorTexture(0, 0, 0, 0)
                end
            end)
            btn:SetScript("OnClick", function(self)
                for _, s in ipairs(sidebarItems) do
                    s._isActive = false
                    s:SetActive(false)
                end
                self._isActive = true
                self:SetActive(true)
                if itemDef.onClick then itemDef.onClick() end
            end)

            table.insert(sidebarItems, btn)
            offsetY = offsetY - 30
        end
    end
end

-- Activate first sidebar item automatically
function WeintCodex.Navigation.ActivateFirst()
    if sidebarItems[1] then
        sidebarItems[1]:Click()
    end
end

--------------------------------------------------
-- Content Panel cleaner
--------------------------------------------------

local function ClearContentPanel()
    local cp = WeintCodex.ContentPanel
    if not cp then
        print("WeintCodex: ContentPanel fehlt")
        return
    end
    for _, child in pairs({cp:GetChildren()}) do
        child:Hide()
    end
end

--------------------------------------------------
-- Tab switching
--------------------------------------------------

function WeintCodex.Navigation.SwitchTo(tabId)
    WeintCodex.Navigation.ClearSidebar()
    ClearContentPanel()

    if tabId == "charakter" then
        if WeintCodex.Charakter and WeintCodex.Charakter.Show then
            WeintCodex.Charakter.Show()
        end
    elseif tabId == "bossguides" then
        if WeintCodex.BossGuides and WeintCodex.BossGuides.Show then
            WeintCodex.BossGuides.Show()
        end
    elseif tabId == "raids" then
        if WeintCodex.Raids and WeintCodex.Raids.Show then
            WeintCodex.Raids.Show()
        end
    elseif tabId == "materials" then
        if WeintCodex.Materials and WeintCodex.Materials.Show then
            WeintCodex.Materials.Show()
        end
    elseif tabId == "calendar" then
        if WeintCodex.Calendar and WeintCodex.Calendar.Show then
            WeintCodex.Calendar.Show()
        end
    elseif tabId == "weakauras" then
        if WeintCodex.WeakAuras and WeintCodex.WeakAuras.Show then
            WeintCodex.WeakAuras.Show()
        end
    elseif tabId == "import" then
        if WeintCodex.Sync and WeintCodex.Sync.ShowImportDialog then
            WeintCodex.Sync.ShowImportDialog()
        end
    end
end

--------------------------------------------------
-- Placeholder
--------------------------------------------------

local placeholderFrame = nil

function WeintCodex.Navigation.ShowPlaceholder(title, msg)
    ClearContentPanel()
    if not placeholderFrame then
        local pf = CreateFrame("Frame", nil, WeintCodex.ContentPanel)
        pf:SetAllPoints(WeintCodex.ContentPanel)

        local t = pf:CreateFontString(nil, "OVERLAY")
        t:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
        t:SetPoint("CENTER", pf, "CENTER", 0, 30)
        t:SetTextColor(C.purple[1], C.purple[2], C.purple[3])
        pf._title = t

        local sub = pf:CreateFontString(nil, "OVERLAY")
        sub:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        sub:SetPoint("TOP", t, "BOTTOM", 0, -12)
        sub:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
        sub:SetWidth(600)
        sub:SetJustifyH("CENTER")
        pf._sub = sub

        placeholderFrame = pf
    end
    placeholderFrame._title:SetText(title or "")
    placeholderFrame._sub:SetText(msg or "")
    placeholderFrame:Show()
end

--------------------------------------------------
-- Home screen
--------------------------------------------------

local homeFrame = nil

function WeintCodex.ShowHome()
    ClearContentPanel()
    WeintCodex.Navigation.ClearSidebar()
    for _, b in ipairs(tabButtons) do SetTabActive(b, false) end
    activeTab = nil

    if not homeFrame then
        local hf = CreateFrame("Frame", nil, WeintCodex.ContentPanel)
        hf:SetAllPoints(WeintCodex.ContentPanel)

        local welcome = hf:CreateFontString(nil, "OVERLAY")
        welcome:SetFont("Fonts\\FRIZQT__.TTF", 26, "OUTLINE")
        welcome:SetPoint("CENTER", hf, "CENTER", 0, 80)
        welcome:SetText("|cff9B6BFF Weint|r|cff33D65ECodex|r")

        local sub = hf:CreateFontString(nil, "OVERLAY")
        sub:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
        sub:SetPoint("TOP", welcome, "BOTTOM", 0, -10)
        sub:SetText("|cff5B4880Raid Guide & Intelligence System|r")
        sub:SetWidth(700)
        sub:SetJustifyH("CENTER")

        local desc = hf:CreateFontString(nil, "OVERLAY")
        desc:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        desc:SetPoint("TOP", sub, "BOTTOM", 0, -30)
        desc:SetText(
            "|cff4B3860Wähle einen Bereich in der Tab-Leiste oben aus.\n\n" ..
            "👤  Charakter — Enchants, Stats & Twink-Verwaltung\n" ..
            "⚔  Bossguides — Rollen-Tipps für alle Bosse\n" ..
            "🛡  Raids — Anmeldungen Mittwoch & Donnerstag\n" ..
            "📦  Materialien — Gildenbank-Übersicht\n" ..
            "✨  WeakAuras — 1-Klick-Import nach Kategorie\n" ..
            "↓  Import — Daten vom Discord-Bot importieren|r"
        )
        desc:SetWidth(600)
        desc:SetJustifyH("CENTER")
        desc:SetSpacing(3)

        local hint = hf:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        hint:SetPoint("TOP", desc, "BOTTOM", 0, -24)
        hint:SetText("|cff3B2D60/wc  •  /wc import|r")
        hint:SetJustifyH("CENTER")

        homeFrame = hf
    end
    homeFrame:Show()
end

function WeintCodex.ResetToHome()
    WeintCodex.ShowHome()
end
