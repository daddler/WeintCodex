--------------------------------------------------
-- WeintCodex :: UI Core
-- Dark fantasy theme: Purple / Green / Gold
--------------------------------------------------

local C = {
    bgDark      = {0.04, 0.03, 0.09, 0.98},
    bgMid       = {0.08, 0.05, 0.16, 0.96},
    bgPanel     = {0.06, 0.04, 0.13, 0.98},
    bgCard      = {0.07, 0.05, 0.15, 1.0},
    purple      = {0.54, 0.36, 0.96, 1.0},
    purpleDim   = {0.34, 0.22, 0.64, 1.0},
    purpleDeep  = {0.18, 0.10, 0.40, 1.0},
    green       = {0.13, 0.77, 0.37, 1.0},
    greenDim    = {0.08, 0.50, 0.24, 1.0},
    gold        = {0.96, 0.76, 0.20, 1.0},
    goldDim     = {0.70, 0.52, 0.10, 1.0},
    blue        = {0.40, 0.80, 1.00, 1.0},
    blueDim     = {0.25, 0.55, 0.80, 1.0},
    red         = {0.95, 0.35, 0.25, 1.0},
    redDim      = {0.65, 0.20, 0.15, 1.0},
    textBright  = {0.96, 0.93, 1.00, 1.0},
    textNormal  = {0.76, 0.71, 0.91, 1.0},
    textDim     = {0.46, 0.41, 0.61, 1.0},
    border      = {0.42, 0.26, 0.76, 0.80},
    borderGlow  = {0.54, 0.36, 0.96, 0.30},
    headerBg    = {0.05, 0.03, 0.13, 1.0},
}
WeintCodex.Colors = C

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

WeintCodex.SetSolidBg = SetSolidBg
WeintCodex.DrawBorder  = DrawBorder
WeintCodex.SetBorder   = DrawBorder
WeintCodex.C           = C

--------------------------------------------------
-- Main Frame
--------------------------------------------------

local FRAME_W   = 1100
local FRAME_H   = 752
local FRAME_MIN_W = 1100
local FRAME_MIN_H = 752
local FRAME_MAX_W = 1600
local FRAME_MAX_H = 1000

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

SetSolidBg(frame, C.bgDark[1], C.bgDark[2], C.bgDark[3], C.bgDark[4])
DrawBorder(frame, C.purple[1], C.purple[2], C.purple[3], 0.90, 2)
DrawBorder(frame, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.25, 6)

--------------------------------------------------
-- Header (banner design)
--------------------------------------------------

local HEADER_H = 120

local header = CreateFrame("Frame", nil, frame)
header:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
header:SetHeight(HEADER_H)

-- Background horizontal gradient
local bgTex = header:CreateTexture(nil, "BACKGROUND")
bgTex:SetAllPoints(header)
bgTex:SetTexture("Interface\\Buttons\\WHITE8X8")
bgTex:SetGradient("HORIZONTAL",
                  CreateColor(0.03, 0.02, 0.08, 1),
                  CreateColor(0.12, 0.07, 0.22, 1)
)

-- Accent strip top (relative width)
local topAccent = header:CreateTexture(nil, "OVERLAY")
topAccent:SetHeight(3)
topAccent:SetPoint("TOPLEFT",  header, "TOPLEFT",  0, 0)
topAccent:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 0)
topAccent:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.60)

-- Bottom divider glow (relative width)
local headerGlow = header:CreateTexture(nil, "OVERLAY")
headerGlow:SetHeight(24)
headerGlow:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  0, 0)
headerGlow:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
headerGlow:SetColorTexture(C.purple[1], C.purple[2], C.purple[3], 0.08)

-- Bottom divider line (relative width)
DrawHLine(header, C.purple[1], C.purple[2], C.purple[3], 0.75, 0, "OVERLAY")

-- Logo
local logoFrame = CreateFrame("Frame", nil, header)
logoFrame:SetSize(450, 110)
logoFrame:SetPoint("CENTER", header, "CENTER", 0, 0)

local logoTex = logoFrame:CreateTexture(nil, "ARTWORK")
logoTex:SetAllPoints(logoFrame)
logoTex:SetTexture("Interface\\AddOns\\WeintCodex\\media\\logo")

-- Close Button
local closeBtn = CreateFrame("Button", nil, header)
closeBtn:SetSize(26, 26)
closeBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT", -12, -12)

local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
closeX:SetAllPoints(closeBtn)
closeX:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
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
-- Footer bar
--------------------------------------------------

local footer = CreateFrame("Frame", nil, frame)
footer:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  0, 0)
footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
footer:SetHeight(22)
SetSolidBg(footer, C.headerBg[1], C.headerBg[2], C.headerBg[3], 1.0)

-- Top divider (relative width)
DrawHLine(footer, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.40, 0, "OVERLAY")

local footerLeft = footer:CreateFontString(nil, "OVERLAY")
footerLeft:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
footerLeft:SetPoint("LEFT", footer, "LEFT", 12, 0)
footerLeft:SetText("|cff4B3880WeintCodex v" .. (WeintCodex.Version or "0.7") .. "|r")

local footerRight = footer:CreateFontString(nil, "OVERLAY")
footerRight:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
footerRight:SetPoint("RIGHT", footer, "RIGHT", -12, 0)
footerRight:SetText("|cff4B3880Für die Gilde. Für den Erfolg. Bis einer weint. |r")

--------------------------------------------------
-- Tab Bar
--------------------------------------------------

local tabBar = CreateFrame("Frame", nil, frame)
tabBar:SetPoint("TOPLEFT",  header, "BOTTOMLEFT",  0, 0)
tabBar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
tabBar:SetHeight(40)
SetSolidBg(tabBar, C.bgMid[1], C.bgMid[2], C.bgMid[3], C.bgMid[4])

-- Bottom divider (relative width)
DrawHLine(tabBar, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.50, 0, "OVERLAY")

WeintCodex.TabBar = tabBar

--------------------------------------------------
-- Content Area
--------------------------------------------------

local bodyFrame = CreateFrame("Frame", nil, frame)
bodyFrame:SetPoint("TOPLEFT",    tabBar, "BOTTOMLEFT",  0,   0)
bodyFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0,  22)
SetSolidBg(bodyFrame, C.bgDark[1], C.bgDark[2], C.bgDark[3], 1.0)

--------------------------------------------------
-- Sidebar
--------------------------------------------------

local sidebar = CreateFrame("Frame", nil, bodyFrame)
sidebar:SetWidth(212)
sidebar:SetPoint("TOPLEFT",    bodyFrame, "TOPLEFT",    0, 0)
sidebar:SetPoint("BOTTOMLEFT", bodyFrame, "BOTTOMLEFT", 0, 0)
SetSolidBg(sidebar, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], C.bgPanel[4])

local sidebarDiv = sidebar:CreateTexture(nil, "OVERLAY")
sidebarDiv:SetPoint("TOPRIGHT",    sidebar, "TOPRIGHT",    0,  0)
sidebarDiv:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0,  0)
sidebarDiv:SetWidth(1)
sidebarDiv:SetColorTexture(C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.45)

local sidebarHeader = sidebar:CreateFontString(nil, "OVERLAY")
sidebarHeader:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, -12)
sidebarHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
sidebarHeader:SetText("|cff4B4060— NAVIGATION —|r")
WeintCodex.SidebarHeader = sidebarHeader

--------------------------------------------------
-- Content Panel
--------------------------------------------------

local contentPanel = CreateFrame("Frame", nil, bodyFrame)
contentPanel:SetPoint("TOPLEFT",     sidebar,    "TOPRIGHT",    0, 0)
contentPanel:SetPoint("BOTTOMRIGHT", bodyFrame,  "BOTTOMRIGHT", 0, 0)
SetSolidBg(contentPanel, C.bgDark[1], C.bgDark[2], C.bgDark[3], 1.0)

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
WeintCodex.Header       = header
WeintCodex.Sidebar      = sidebar
WeintCodex.ContentPanel = contentPanel
WeintCodex.BodyFrame    = bodyFrame
WeintCodex.Footer       = footer
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
        DrawBorder(f, C.purple[1], C.purple[2], C.purple[3], 0.90, 2)
        DrawBorder(f, C.purpleDim[1], C.purpleDim[2], C.purpleDim[3], 0.25, 6)

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
        SetSolidBg(ebBg, 0.04, 0.02, 0.10, 0.95)
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
