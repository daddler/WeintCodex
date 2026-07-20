--------------------------------------------------
-- WeintCodex :: UI Core
-- "Codex" theme: warmes Kaffeehaus-Dunkel / Amber-Akzent
-- (Redesign auf Basis der Claude-Design-Vorlagen v1.0)
--------------------------------------------------

local C = {
    -- Basis-Flaechen, dunkel nach hell gestaffelt
    bgDark      = {0.043, 0.039, 0.035, 1.0},   -- 0b0a09 - Fensterhintergrund
    bgMid       = {0.071, 0.063, 0.055, 1.0},   -- 12100d - mittlere Flaeche
    bgPanel     = {0.063, 0.051, 0.043, 1.0},   -- 100d0b - Rail/Panel
    bgCard      = {0.078, 0.067, 0.055, 1.0},   -- 14110e - Karten/Zeilen

    -- Amber-Akzent (ersetzt vormals Lila als Primaerakzent)
    purple      = {0.784, 0.463, 0.227, 1.0},   -- c8763a - Primaerakzent
    purpleDim   = {0.635, 0.353, 0.149, 1.0},   -- a25a26 - gedaempfter Akzent
    purpleDeep  = {0.353, 0.196, 0.086, 1.0},   -- 5a3216 - tiefer Akzent (Pressed)

    -- Erfolg / Warnung / Gefahr / Info
    green       = {0.290, 0.486, 0.349, 1.0},   -- 4a7c59 - Erfolg
    greenDim    = {0.208, 0.361, 0.259, 1.0},   -- 355c42
    gold        = {0.784, 0.627, 0.227, 1.0},   -- c8a03a - Warnung/OK
    goldDim     = {0.478, 0.373, 0.110, 1.0},   -- 7a5f1c
    blue        = {0.420, 0.627, 0.851, 1.0},   -- 6ba0d9 - Info/Tank
    blueDim     = {0.227, 0.431, 0.647, 1.0},   -- 3a6ea5
    red         = {0.784, 0.353, 0.227, 1.0},   -- c85a3a - Gefahr/DPS
    redDim      = {0.478, 0.188, 0.125, 1.0},   -- 7a3020

    -- Textstufen (bright > normal > muted > dim > faint > ghost)
    textBright  = {0.949, 0.929, 0.898, 1.0},   -- f2ede4
    textNormal  = {0.910, 0.890, 0.859, 1.0},   -- e8e3db
    textMuted   = {0.788, 0.757, 0.710, 1.0},   -- c9c1b5
    textDim     = {0.541, 0.506, 0.467, 1.0},   -- 8a8177
    textFaint   = {0.420, 0.384, 0.349, 1.0},   -- 6b6259
    textGhost   = {0.290, 0.259, 0.227, 1.0},   -- 4a423a

    border      = {0.141, 0.122, 0.106, 1.0},   -- 241f1b - Standard-Hairline
    borderGlow  = {0.784, 0.463, 0.227, 0.30},  -- Akzent-Glow (Hover/aktiv)
    headerBg    = {0.051, 0.043, 0.035, 1.0},   -- 0d0b09 - Insets (Suchfeld etc.)

    -- Flache Elevation-Stufen fuer das reduzierte, ruhigere Panel-Design.
    surface0    = {0.043, 0.039, 0.035, 1.0},   -- 0b0a09
    surface1    = {0.063, 0.051, 0.043, 1.0},   -- 100d0b
    surface2    = {0.078, 0.067, 0.055, 1.0},   -- 14110e
    surface3    = {0.118, 0.098, 0.082, 1.0},   -- 1e1915

    -- Semantische Aliase auf bestehende Tontoene.
    success     = {0.290, 0.486, 0.349, 1.0},
    warning     = {0.784, 0.627, 0.227, 1.0},
    danger      = {0.784, 0.353, 0.227, 1.0},
    info        = {0.420, 0.627, 0.851, 1.0},
    violet      = {0.72,  0.45,  0.98,  1.0},   -- eigenstaendiger 5. Status (z.B. "Ueber Cap")

    -- Schlanke, blasse Rahmen-/Trenner-Toene fuer die reduzierte Ornamentik.
    hairline     = {0.141, 0.122, 0.106, 1.0},
    hairlineSoft = {0.141, 0.122, 0.106, 0.55},
    accentDot    = {0.784, 0.463, 0.227, 1.0},
}
WeintCodex.Colors = C

--------------------------------------------------
-- Font-Helper
-- Eigene Schriftdateien (SIL OFL 1.1, siehe media/fonts/OFL-LICENSE.txt) fuer
-- die Fraunces/JetBrains-Mono-Optik aus dem Redesign-Mockup. FRIZQT__.TTF
-- bleibt fuer normalen Fliesstext/Buttons/Listen die Basis - diese Fonts
-- werden gezielt fuer Ueberschriften, grosse Zahlen und Mono-/Eyebrow-Labels
-- eingesetzt, nicht addonweit ausgetauscht.
--------------------------------------------------
WeintCodex.Fonts = {
    serif       = "Interface\\AddOns\\WeintCodex\\media\\fonts\\Fraunces-Medium.ttf",
    serifBold   = "Interface\\AddOns\\WeintCodex\\media\\fonts\\Fraunces-SemiBold.ttf",
    mono        = "Interface\\AddOns\\WeintCodex\\media\\fonts\\JetBrainsMono-Regular.ttf",
    monoMedium  = "Interface\\AddOns\\WeintCodex\\media\\fonts\\JetBrainsMono-Medium.ttf",
}

--------------------------------------------------
-- Icon-Helper
--------------------------------------------------
-- Das UI-Font (FRIZQT__.TTF) unterstuetzt keine Unicode-Emoji - vorher
-- verwendete Zeichen wie ⚔ ✦ 📦 wurden deshalb als leere Kaestchen
-- dargestellt. Ab hier werden ausschliesslich echte, im Client
-- vorhandene Icon-Texturen ueber die |T...|t-Escape-Syntax verwendet.
--------------------------------------------------

-- Beliebiges Icon aus Interface\Icons als Inline-Text-Icon
function WeintCodex.Icon(iconPath, size)
    size = size or 14
    return "|T" .. iconPath .. ":" .. size .. "|t"
end

-- Klassen-Icon (echtes Blizzard-Klassensymbol, kein Emoji)
local CLASS_ICON_ATLAS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"

function WeintCodex.ClassIcon(classToken, size)
    size = size or 14
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken]
    if not coords then
        return ""
    end
    return string.format(
        "|T%s:%d:%d:0:0:256:256:%d:%d:%d:%d|t",
        CLASS_ICON_ATLAS, size, size,
        coords[1] * 256, coords[2] * 256, coords[3] * 256, coords[4] * 256
    )
end

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function SetSolidBg(frame, r, g, b, a)
    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetColorTexture(r, g, b, a or 1.0)
    return tex
end

local function DrawBorder(f, r, g, b, a, thick)
    thick = thick or 1
    local function T(pt, rpt, w, h, ox, oy)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(pt, f, rpt, ox or 0, oy or 0)
        t:SetSize(w, h)
        return t
    end
    local W, H = f:GetWidth(), f:GetHeight()
    T("TOPLEFT",    "TOPLEFT",    W,     thick,  0, 0)
    T("BOTTOMLEFT", "BOTTOMLEFT", W,     thick,  0, 0)
    T("TOPLEFT",    "TOPLEFT",    thick, H,      0, 0)
    T("TOPRIGHT",   "TOPRIGHT",   thick, H,      0, 0)
end

-- Horizontal line that stretches relative to its parent (no fixed width)
local function DrawHLine(parent, r, g, b, a, offsetY, layer)
    local t = parent:CreateTexture(nil, layer or "OVERLAY")
    t:SetHeight(1)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, offsetY)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, offsetY)
    t:SetColorTexture(r, g, b, a)
    return t
end

--------------------------------------------------
-- Hex-Helper (ersetzt handgetippte |cffRRGGBB-Escapes)
--------------------------------------------------

-- Erzeugt "|cffRRGGBBtext|r" aus einem Eintrag der Farbtabelle C.
function WeintCodex.ColorText(colorName, text)
    local col = C[colorName]
    if not col then return text end
    return string.format("|cff%02x%02x%02x%s|r",
        (col[1] or 0) * 255, (col[2] or 0) * 255, (col[3] or 0) * 255, text)
end

--------------------------------------------------
-- Schlanker Einzel-Rahmen (Alternative zum zweilagigen Glow-DrawBorder)
--------------------------------------------------

function WeintCodex.DrawSlimBorder(frame, colorName, alpha, thick)
    thick = thick or 1
    local col = C[colorName] or C.hairline
    alpha = alpha or col[4] or 1.0
    DrawBorder(frame, col[1], col[2], col[3], alpha, thick)
end

--------------------------------------------------
-- Dezente Eck-Akzente statt Vollrahmen
--------------------------------------------------

function WeintCodex.DrawCornerAccents(frame, colorName, size, thick)
    size  = size  or 12
    thick = thick or 2
    local col = C[colorName] or C.purple

    local function Corner(hPoint, vPoint, hx, hy, vx, vy)
        local h = frame:CreateTexture(nil, "OVERLAY")
        h:SetColorTexture(col[1], col[2], col[3], col[4] or 1.0)
        h:SetPoint(hPoint, frame, hPoint, hx, hy)
        h:SetSize(size, thick)

        local v = frame:CreateTexture(nil, "OVERLAY")
        v:SetColorTexture(col[1], col[2], col[3], col[4] or 1.0)
        v:SetPoint(vPoint, frame, vPoint, vx, vy)
        v:SetSize(thick, size)
    end

    Corner("TOPLEFT",     "TOPLEFT",     0, 0,  0, 0)
    Corner("TOPRIGHT",    "TOPRIGHT",    0, 0,  0, 0)
    Corner("BOTTOMLEFT",  "BOTTOMLEFT",  0, 0,  0, 0)
    Corner("BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0,  0, 0)
end

--------------------------------------------------
-- Karten-Factory (flach, fuer Shell/Dashboard)
--------------------------------------------------

-- opts: { width, height, surface = "surface2", style = "flat"|"border"|"corners",
--         borderColor = "hairline", title, titleColor = "textBright" }
function WeintCodex.CreateCard(parent, opts)
    opts = opts or {}
    local card = CreateFrame(opts.buttonStyle and "Button" or "Frame", nil, parent)
    if opts.width  then card:SetWidth(opts.width)   end
    if opts.height then card:SetHeight(opts.height) end

    local surfaceCol = C[opts.surface or "surface2"]
    card._bg = SetSolidBg(card, surfaceCol[1], surfaceCol[2], surfaceCol[3], surfaceCol[4] or 1.0)
    card._surface = opts.surface or "surface2"

    -- Erlaubt Hover-Umfaerbung (z.B. surface2 -> surface3) ohne die
    -- Rahmen-/Titel-Texturen neu zu erzeugen.
    card.SetSurface = function(self, surfaceName)
        local col = C[surfaceName]
        if not col then return end
        self._bg:SetColorTexture(col[1], col[2], col[3], col[4] or 1.0)
    end

    local style = opts.style or "border"
    if style == "border" then
        WeintCodex.DrawSlimBorder(card, opts.borderColor or "hairline", nil, 1)
    elseif style == "corners" then
        WeintCodex.DrawCornerAccents(card, opts.borderColor or "purple", 10, 2)
    end

    local titleStr = nil
    if opts.title then
        titleStr = card:CreateFontString(nil, "OVERLAY")
        titleStr:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
        titleStr:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
        titleStr:SetTextColor(unpack(C[opts.titleColor or "textBright"]))
        titleStr:SetText(opts.title)
    end

    card.SetTitle = function(self, text)
        if titleStr then titleStr:SetText(text) end
    end

    return card
end

WeintCodex.SetSolidBg = SetSolidBg
WeintCodex.DrawBorder  = DrawBorder
WeintCodex.SetBorder   = DrawBorder
WeintCodex.C           = C

--------------------------------------------------
-- Main Frame
--------------------------------------------------
-- Layout (Redesign v1.0): 4 Spalten statt Banner/Tabbar/Sidebar
--   Icon-Rail (64px) | Sub-Nav (240px) | Content (flex) | Inspector (300px)
--------------------------------------------------

local FRAME_W   = 1500
local FRAME_H   = 800
local FRAME_MIN_W = 1180
local FRAME_MIN_H = 780
local FRAME_MAX_W = 1700
local FRAME_MAX_H = 1000

local RAIL_W       = 64
local SIDEBAR_W    = 240
local INSPECTOR_W  = 340
local TITLEBAR_H   = 52

local frame = CreateFrame("Frame", "WeintCodexMainFrame", UIParent)
frame:SetSize(FRAME_W, FRAME_H)
frame:SetPoint("CENTER")

-- Restore saved size
local function ApplySavedWindow()
    if WeintCodex.SavedData and WeintCodex.SavedData.window then
        local w = WeintCodex.SavedData.window
        if w.width  then frame:SetWidth(w.width)   end
        if w.height then frame:SetHeight(w.height)  end
        if w.scale  then frame:SetScale(w.scale)    end
    end
end

frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:SetToplevel(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
frame:SetResizable(true)
frame:SetResizeBounds(FRAME_MIN_W, FRAME_MIN_H, FRAME_MAX_W, FRAME_MAX_H)
frame:Hide()

-- Sanfter vertikaler Verlauf (17130f -> 12100d), statt Vollton
local frameBg = frame:CreateTexture(nil, "BACKGROUND")
frameBg:SetAllPoints(frame)
frameBg:SetTexture("Interface\\Buttons\\WHITE8X8")
frameBg:SetGradient("VERTICAL",
    CreateColor(C.bgDark[1], C.bgDark[2], C.bgDark[3], 1),
    CreateColor(C.bgMid[1],  C.bgMid[2],  C.bgMid[3],  1)
)
DrawBorder(frame, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.45, 1)

--------------------------------------------------
-- Icon-Rail (linke Navigationsspalte)
--------------------------------------------------

local iconRail = CreateFrame("Frame", nil, frame)
iconRail:SetWidth(RAIL_W)
iconRail:SetPoint("TOPLEFT",    frame, "TOPLEFT",    1, -1)
iconRail:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1,  1)
SetSolidBg(iconRail, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)

local railDiv = iconRail:CreateTexture(nil, "OVERLAY")
railDiv:SetPoint("TOPRIGHT",    iconRail, "TOPRIGHT",    0, 0)
railDiv:SetPoint("BOTTOMRIGHT", iconRail, "BOTTOMRIGHT", 0, 0)
railDiv:SetWidth(1)
railDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

-- Markenzeichen "W"
local brandBadge = CreateFrame("Frame", nil, iconRail)
brandBadge:SetSize(36, 36)
brandBadge:SetPoint("TOP", iconRail, "TOP", 0, -14)

local brandTex = brandBadge:CreateTexture(nil, "BACKGROUND")
brandTex:SetAllPoints(brandBadge)
brandTex:SetTexture("Interface\\Buttons\\WHITE8X8")
brandTex:SetGradient("VERTICAL",
    CreateColor(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 1),
    CreateColor(C.purple[1],    C.purple[2],    C.purple[3],    1)
)

local brandLabel = brandBadge:CreateFontString(nil, "OVERLAY")
brandLabel:SetAllPoints(brandBadge)
brandLabel:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
brandLabel:SetJustifyH("CENTER")
brandLabel:SetJustifyV("MIDDLE")
brandLabel:SetTextColor(0.10, 0.06, 0.03, 1.0)
brandLabel:SetText("W")

-- Versionsmarke am unteren Rand der Leiste
local railVersion = iconRail:CreateFontString(nil, "OVERLAY")
railVersion:SetFont(WeintCodex.Fonts.mono, 9, "")
railVersion:SetPoint("BOTTOM", iconRail, "BOTTOM", 0, 10)
railVersion:SetText(WeintCodex.ColorText("textGhost", "v" .. (WeintCodex.Version or "1.0")))

WeintCodex.IconRail    = iconRail
WeintCodex.RailIconTop = brandBadge

-- Close Button (oben rechts über der gesamten Fensterbreite)
local closeBtn = CreateFrame("Button", nil, frame)
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
closeBtn:SetFrameLevel(frame:GetFrameLevel() + 20)

local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
closeX:SetAllPoints(closeBtn)
closeX:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
closeX:SetText("|cffff5555×|r")

closeBtn:SetScript("OnClick", function() frame:Hide() end)
closeBtn:SetScript("OnEnter", function()
    closeX:SetText("|cffff9999×|r")
    closeX:SetScale(1.15)
end)
closeBtn:SetScript("OnLeave", function()
    closeX:SetText("|cffff5555×|r")
    closeX:SetScale(1.0)
end)

--------------------------------------------------
-- Sub-Nav (Sidebar) - kontextabhaengige Navigationsspalte
--------------------------------------------------

local sidebar = CreateFrame("Frame", nil, frame)
sidebar:SetWidth(SIDEBAR_W)
sidebar:SetPoint("TOPLEFT",    iconRail, "TOPRIGHT",    0, 0)
sidebar:SetPoint("BOTTOMLEFT", iconRail, "BOTTOMRIGHT", 0, 0)

local sidebarDiv = sidebar:CreateTexture(nil, "OVERLAY")
sidebarDiv:SetPoint("TOPRIGHT",    sidebar, "TOPRIGHT",    0,  0)
sidebarDiv:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0,  0)
sidebarDiv:SetWidth(1)
sidebarDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

local sidebarHeader = sidebar:CreateFontString(nil, "OVERLAY")
sidebarHeader:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 18, -20)
sidebarHeader:SetFont(WeintCodex.Fonts.mono, 10, "")
sidebarHeader:SetText(WeintCodex.ColorText("textFaint", "NAVIGATION"))
WeintCodex.SidebarHeader = sidebarHeader

--------------------------------------------------
-- Hauptspalte: Titelleiste + Content
--------------------------------------------------

local mainColumn = CreateFrame("Frame", nil, frame)
mainColumn:SetPoint("TOPLEFT",     sidebar, "TOPRIGHT",    0, 0)
mainColumn:SetPoint("BOTTOMRIGHT", frame,   "BOTTOMRIGHT", -(INSPECTOR_W + 1), 1)

local titleBar = CreateFrame("Frame", nil, mainColumn)
titleBar:SetHeight(TITLEBAR_H)
titleBar:SetPoint("TOPLEFT",  mainColumn, "TOPLEFT",  0, 0)
titleBar:SetPoint("TOPRIGHT", mainColumn, "TOPRIGHT", 0, 0)

local titleDiv = titleBar:CreateTexture(nil, "OVERLAY")
titleDiv:SetHeight(1)
titleDiv:SetPoint("BOTTOMLEFT",  titleBar, "BOTTOMLEFT",  0, 0)
titleDiv:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
titleDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

local wordmark = titleBar:CreateFontString(nil, "OVERLAY")
wordmark:SetFont(WeintCodex.Fonts.serif, 18, "")
wordmark:SetPoint("LEFT", titleBar, "LEFT", 20, 0)
wordmark:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
wordmark:SetText("WeintCodex")

local wordDiv = titleBar:CreateTexture(nil, "OVERLAY")
wordDiv:SetSize(1, 16)
wordDiv:SetPoint("LEFT", wordmark, "RIGHT", 14, 0)
wordDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

-- Globale Suche: fixe Breite, rechts mit Abstand zum Aktionsbereich verankert
-- (siehe titleActions weiter unten - dessen Inhalt ist je Modul unterschiedlich
-- breit, 280px Reserve deckt die breitesten Faelle, z.B. raids.lua, ab).
-- Logik/Datenindex/Strg+K-Abfangen sitzen in core/search.lua.
local searchBox = CreateFrame("EditBox", nil, titleBar)
searchBox:SetHeight(28)
searchBox:SetWidth(240)
searchBox:SetPoint("RIGHT", titleBar, "RIGHT", -280, 0)
searchBox:SetAutoFocus(false)
searchBox:SetFontObject("ChatFontNormal")
searchBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
searchBox:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
searchBox:SetTextInsets(22, 46, 0, 0)
searchBox:SetMaxLetters(80)

SetSolidBg(searchBox, C.headerBg[1], C.headerBg[2], C.headerBg[3], 1.0)
DrawBorder(searchBox, C.border[1], C.border[2], C.border[3], C.border[4], 1)

local searchIcon = searchBox:CreateFontString(nil, "OVERLAY")
searchIcon:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
searchIcon:SetPoint("LEFT", searchBox, "LEFT", 8, 0)
searchIcon:SetText(WeintCodex.Icon("Interface\\Common\\UI-Searchbox-Icon", 13))

local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY")
searchPlaceholder:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
searchPlaceholder:SetPoint("LEFT", searchBox, "LEFT", 22, 0)
searchPlaceholder:SetPoint("RIGHT", searchBox, "RIGHT", -46, 0)
searchPlaceholder:SetJustifyH("LEFT")
searchPlaceholder:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
searchPlaceholder:SetText("Suche Boss, Verzauberung, Material…")

local searchChip = CreateFrame("Frame", nil, searchBox)
searchChip:SetSize(38, 16)
searchChip:SetPoint("RIGHT", searchBox, "RIGHT", -8, 0)
SetSolidBg(searchChip, C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
DrawBorder(searchChip, C.border[1], C.border[2], C.border[3], C.border[4], 1)
local searchChipLbl = searchChip:CreateFontString(nil, "OVERLAY")
searchChipLbl:SetAllPoints(searchChip)
searchChipLbl:SetFont(WeintCodex.Fonts.mono, 9, "")
searchChipLbl:SetJustifyH("CENTER")
searchChipLbl:SetJustifyV("MIDDLE")
searchChipLbl:SetTextColor(C.textFaint[1], C.textFaint[2], C.textFaint[3])
searchChipLbl:SetText("Strg K")

searchBox:SetScript("OnEscapePressed", searchBox.ClearFocus)
searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
searchBox:SetScript("OnTextChanged", function(self)
    searchPlaceholder:SetShown(self:GetText() == "")
    if WeintCodex.Search then WeintCodex.Search.OnTextChanged(self:GetText()) end
end)
searchBox:SetScript("OnEditFocusGained", function(self)
    searchChip:Hide()
    if WeintCodex.Search then WeintCodex.Search.OnFocusGained(self:GetText()) end
end)
searchBox:SetScript("OnEditFocusLost", function(self)
    searchChip:Show()
    if WeintCodex.Search then WeintCodex.Search.OnFocusLost() end
end)

WeintCodex.SearchBox = searchBox

-- Ergebnis-Dropdown: eigener Frame ueber dem Content-Panel verankert (nicht
-- Kind von titleBar, damit es nicht am Titelleisten-Rand abgeschnitten wird).
-- Aufbau/Befuellung in core/search.lua.
local searchResults = CreateFrame("Frame", nil, frame)
searchResults:SetPoint("TOPLEFT",  searchBox, "BOTTOMLEFT",  0, -4)
searchResults:SetPoint("TOPRIGHT", searchBox, "BOTTOMRIGHT", 0, -4)
searchResults:SetFrameStrata("DIALOG")
SetSolidBg(searchResults, C.surface1[1], C.surface1[2], C.surface1[3], 1.0)
DrawBorder(searchResults, C.border[1], C.border[2], C.border[3], C.border[4], 1)
searchResults:Hide()
WeintCodex.SearchResults = searchResults

local breadcrumb = titleBar:CreateFontString(nil, "OVERLAY")
breadcrumb:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
breadcrumb:SetPoint("LEFT", wordDiv, "RIGHT", 14, 0)
breadcrumb:SetPoint("RIGHT", searchBox, "LEFT", -16, 0)
breadcrumb:SetJustifyH("LEFT")
breadcrumb:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3])
WeintCodex.Breadcrumb = breadcrumb

-- Frei belegbarer Aktionsbereich rechts in der Titelleiste (z.B. Buttons je Modul)
local titleActions = CreateFrame("Frame", nil, titleBar)
titleActions:SetHeight(TITLEBAR_H)
titleActions:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -16, 0)
titleActions:SetWidth(1)
WeintCodex.TitleBarActions = titleActions

function WeintCodex.SetBreadcrumb(...)
    local parts = { ... }
    local segs = {}
    for i, p in ipairs(parts) do
        if i == #parts then
            segs[#segs + 1] = WeintCodex.ColorText("textNormal", p)
        else
            segs[#segs + 1] = WeintCodex.ColorText("textDim", p)
            segs[#segs + 1] = WeintCodex.ColorText("textGhost", "  ›  ")
        end
    end
    breadcrumb:SetText(table.concat(segs))
end

--------------------------------------------------
-- Content Panel
--------------------------------------------------

local contentPanel = CreateFrame("Frame", nil, mainColumn)
contentPanel:SetPoint("TOPLEFT",     titleBar,   "BOTTOMLEFT",  0, 0)
contentPanel:SetPoint("BOTTOMRIGHT", mainColumn, "BOTTOMRIGHT", 0, 0)

--------------------------------------------------
-- Inspector (rechte Kontext-Spalte)
--------------------------------------------------

local inspector = CreateFrame("Frame", nil, frame)
inspector:SetWidth(INSPECTOR_W)
inspector:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    -1, -1)
inspector:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1,  1)
SetSolidBg(inspector, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)

local inspectorDiv = inspector:CreateTexture(nil, "OVERLAY")
inspectorDiv:SetPoint("TOPLEFT",    inspector, "TOPLEFT",    0, 0)
inspectorDiv:SetPoint("BOTTOMLEFT", inspector, "BOTTOMLEFT", 0, 0)
inspectorDiv:SetWidth(1)
inspectorDiv:SetColorTexture(C.border[1], C.border[2], C.border[3], C.border[4])

WeintCodex.Inspector = inspector

--------------------------------------------------
-- Resize Grip (bottom-right corner)
--------------------------------------------------

local resizeBtn = CreateFrame("Button", nil, frame)
resizeBtn:SetSize(18, 18)
resizeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
resizeBtn:SetFrameLevel(frame:GetFrameLevel() + 10)

-- Visual: diagonal lines texture
local resizeTex = resizeBtn:CreateTexture(nil, "OVERLAY")
resizeTex:SetAllPoints(resizeBtn)
resizeTex:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.0)

-- Draw grip lines manually with three short stripes
local function MakeGripLine(parent, offsetX, offsetY, w, h)
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetSize(w, h)
    t:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", offsetX, offsetY)
    t:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80)
    return t
end
-- Three diagonal marks (bottom-right to top-left feel)
MakeGripLine(resizeBtn,  0,  0, 10, 1)
MakeGripLine(resizeBtn,  0,  4,  7, 1)
MakeGripLine(resizeBtn,  0,  8,  4, 1)
MakeGripLine(resizeBtn,  0,  0,  1, 10)
MakeGripLine(resizeBtn,  4,  0,  1,  7)
MakeGripLine(resizeBtn,  8,  0,  1,  4)

resizeBtn:SetScript("OnEnter", function()
    for _, t in ipairs({resizeBtn:GetRegions()}) do
        if t.SetColorTexture then
            t:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.90)
        end
    end
end)
resizeBtn:SetScript("OnLeave", function()
    for _, t in ipairs({resizeBtn:GetRegions()}) do
        if t.SetColorTexture then
            t:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80)
        end
    end
end)
resizeBtn:SetScript("OnMouseDown", function()
    frame:StartSizing("BOTTOMRIGHT")
end)
resizeBtn:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    -- Persist new size
    if WeintCodex.SavedData and WeintCodex.SavedData.window then
        WeintCodex.SavedData.window.width  = math.floor(frame:GetWidth())
        WeintCodex.SavedData.window.height = math.floor(frame:GetHeight())
    end
end)

-- Also save on drag stop
local origDragStop = frame:GetScript("OnDragStop")
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

--------------------------------------------------
-- Global references
--------------------------------------------------

WeintCodex.MainFrame    = frame
WeintCodex.TitleBar     = titleBar
WeintCodex.Sidebar      = sidebar
WeintCodex.ContentPanel = contentPanel
WeintCodex.ApplySavedWindow = ApplySavedWindow

--------------------------------------------------
-- Universeller Export-Dialog (Overlay)
--------------------------------------------------

local exportFrame = nil
function WeintCodex.ShowExportDialog(titleText, exportStr)
    if not exportFrame then
        local parent = WeintCodex.MainFrame
        local f = CreateFrame("Frame", "WeintCodexExportDialog", parent)
        f:SetSize(600, 260)
        f:SetPoint("CENTER", parent, "CENTER", 0, 0)
        f:SetFrameStrata("TOOLTIP")
        f:EnableMouse(true)

        SetSolidBg(f, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 0.98)
        DrawBorder(f, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.55, 1)

        -- Title
        local t = f:CreateFontString(nil, "OVERLAY")
        t:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        t:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -18)
        t:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
        f._title = t

        -- Subtitle
        local sub = f:CreateFontString(nil, "OVERLAY")
        sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        sub:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
        sub:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
        sub:SetWidth(560)
        sub:SetJustifyH("LEFT")
        sub:SetText("Kopiere diesen String (Strg+C) und füge ihn bei deinem Discord-Bot ein:")

        -- EditBox container
        local ebBg = CreateFrame("Frame", nil, f)
        ebBg:SetSize(560, 110)
        ebBg:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -8)
        SetSolidBg(ebBg, C.headerBg[1], C.headerBg[2], C.headerBg[3], 0.95)
        DrawBorder(ebBg, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.60, 1)

        local eb = CreateFrame("EditBox", nil, ebBg)
        eb:SetSize(540, 100)
        eb:SetPoint("TOPLEFT", ebBg, "TOPLEFT", 6, -5)
        eb:SetMultiLine(true)
        eb:SetMaxLetters(0)
        eb:SetAutoFocus(false)
        eb:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        eb:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
        eb:SetTextInsets(4, 4, 4, 4)

        local scroll = CreateFrame("ScrollFrame", nil, ebBg, "UIPanelScrollFrameTemplate")
        scroll:SetSize(540, 100)
        scroll:SetPoint("TOPLEFT", ebBg, "TOPLEFT", 0, 0)
        scroll:SetScrollChild(eb)

        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnChar", function(self)
            C_Timer.After(0.01, function()
                self:SetText(f._exportStr or "")
                self:HighlightText()
            end)
        end)

        f.EditBox = eb

        -- Close Button
        local close = CreateFrame("Button", nil, f)
        close:SetSize(120, 28)
        close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 16)
        SetSolidBg(close, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80)
        DrawBorder(close, C.purple[1], C.purple[2], C.purple[3], 0.80, 1)

        local closeLbl = close:CreateFontString(nil, "OVERLAY")
        closeLbl:SetAllPoints(close)
        closeLbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        closeLbl:SetText("Schließen")
        closeLbl:SetTextColor(1, 1, 1)

        close:SetScript("OnClick", function() f:Hide() end)
        close:SetScript("OnEnter", function(self)
            SetSolidBg(self, C.purple[1], C.purple[2], C.purple[3], 0.90)
        end)
        close:SetScript("OnLeave", function(self)
            SetSolidBg(self, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.80)
        end)

        exportFrame = f
    end

    exportFrame._title:SetText(titleText or "Export")
    exportFrame._exportStr = exportStr
    exportFrame.EditBox:SetText(exportStr)
    exportFrame:Show()

    C_Timer.After(0.1, function()
        exportFrame.EditBox:SetFocus()
        exportFrame.EditBox:HighlightText()
    end)
end
