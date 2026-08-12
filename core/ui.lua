--------------------------------------------------
-- WeintCodex :: UI Core
-- Designsprache 2.0 ("Adson"), uebernommen aus WeintCompanion 2.0:
-- schwarze Flaechen, Karten ohne Rahmen mit 1-px-Oberkante, Bernstein nur
-- fuer Bedeutung, Inter + JetBrains Mono, Raster 4/8/12/16/24/32.
--
-- Drei Dinge, die in WoW anders geloest werden muessen als im Entwurf:
--
--  * Radius. Frames koennen keinen haben. Statt die Karte rund zu zeichnen
--    legen wir vier Viertelkreis-Masken in der Farbe DAHINTER auf die Ecken
--    (CutCorners). Das setzt voraus, dass der Aufrufer weiss, worauf die
--    Karte liegt - deshalb nimmt jede Flaeche ein `backdrop`.
--  * Verlauf. SetGradient("VERTICAL", min, max) laeuft von UNTEN nach OBEN,
--    CSS-`linear-gradient(180deg, a, b)` von oben nach unten. Die beiden
--    Farben werden daher vertauscht uebergeben.
--  * Schrift. Kein OUTLINE mehr. Der Entwurf lebt von duennen, ruhigen
--    Textstufen; eine schwarze Kontur macht daraus wieder das alte Bild.
--------------------------------------------------

local WHITE  = "Interface\\Buttons\\WHITE8X8"
local MEDIA  = "Interface\\AddOns\\WeintCodex\\media\\"
local CORNER = MEDIA .. "ui\\corner"

--------------------------------------------------
-- Farbtokens
--------------------------------------------------
-- Die Namen der alten Palette bleiben allesamt gueltig und zeigen auf die
-- neuen Werte. Das ist Absicht: rund 140 ColorText-Aufrufe und ein Dutzend
-- Colors.x-Zugriffe im Addon nennen Farben beim Namen. Ein entfernter Name
-- faellt nicht auf (ColorText gibt den Text dann ungefaerbt zurueck), waere
-- also genau die Sorte Fehler, die man erst im Spiel sieht.
--------------------------------------------------

local C = {
    -- Flaechen (Entwurf: #0A0A0C Grund, #08080A Navigation, Karte 121217->0C0C0F)
    bgDark      = {0.039, 0.039, 0.047, 1.0},   -- 0A0A0C - Fenstergrund
    bgMid       = {0.047, 0.047, 0.059, 1.0},   -- 0C0C0F - Kartenfuss
    bgPanel     = {0.031, 0.031, 0.039, 1.0},   -- 08080A - Navigation/Titelleiste
    bgCard      = {0.071, 0.071, 0.090, 1.0},   -- 121217 - Kartenkopf

    surface0    = {0.039, 0.039, 0.047, 1.0},   -- 0A0A0C
    surface1    = {0.031, 0.031, 0.039, 1.0},   -- 08080A
    surface2    = {0.071, 0.071, 0.090, 1.0},   -- 121217
    surface3    = {0.090, 0.090, 0.110, 1.0},   -- 17171C - Hover/aktiv

    cardTop       = {0.071, 0.071, 0.090, 1.0}, -- 121217
    cardBottom    = {0.047, 0.047, 0.059, 1.0}, -- 0C0C0F
    accentCardTop = {0.090, 0.078, 0.102, 1.0}, -- 17141A
    accentCardBot = {0.051, 0.047, 0.063, 1.0}, -- 0D0C10

    -- Bernstein. Heisst historisch "purple" (frueher war der Akzent lila) und
    -- behaelt den Namen, weil neun Aufrufstellen ihn so ansprechen.
    purple      = {0.831, 0.635, 0.290, 1.0},   -- D4A24A - Primaerakzent
    purpleDim   = {0.541, 0.416, 0.180, 1.0},   -- 8A6A2E - gedaempft
    purpleDeep  = {0.290, 0.227, 0.102, 1.0},   -- 4A3A1A - tief/gedrueckt
    accent      = {0.831, 0.635, 0.290, 1.0},   -- D4A24A
    accentBright= {0.910, 0.788, 0.427, 1.0},   -- E8C96D

    -- Zustaende. Je Ton ein Grundwert (Flaeche/Punkt) und ein heller Wert
    -- (Text auf dunklem Grund) - im Entwurf durchgaengig so gepaart.
    green         = {0.486, 0.753, 0.431, 1.0}, -- 7CC06E
    greenDim      = {0.306, 0.478, 0.271, 1.0}, -- 4E7A45
    successBright = {0.561, 0.855, 0.502, 1.0}, -- 8FDA80
    red           = {0.898, 0.420, 0.420, 1.0}, -- E56B6B
    redDim        = {0.561, 0.251, 0.251, 1.0}, -- 8F4040
    dangerBright  = {0.945, 0.549, 0.549, 1.0}, -- F18C8C
    gold          = {0.831, 0.635, 0.290, 1.0}, -- D4A24A
    goldDim       = {0.541, 0.416, 0.180, 1.0}, -- 8A6A2E
    blue          = {0.545, 0.584, 0.961, 1.0}, -- 8B95F5
    blueDim       = {0.353, 0.384, 0.722, 1.0}, -- 5A62B8
    infoBright    = {0.659, 0.690, 1.000, 1.0}, -- A8B0FF
    violet        = {0.659, 0.333, 0.969, 1.0}, -- A855F7
    violetBright  = {0.753, 0.518, 0.988, 1.0}, -- C084FC

    success     = {0.486, 0.753, 0.431, 1.0},
    warning     = {0.831, 0.635, 0.290, 1.0},
    danger      = {0.898, 0.420, 0.420, 1.0},
    info        = {0.545, 0.584, 0.961, 1.0},

    -- Textstufen (bright > normal > muted > dim > faint > ghost)
    textBright  = {1.000, 1.000, 1.000, 1.0},   -- FFFFFF
    textNormal  = {0.910, 0.910, 0.918, 1.0},   -- E8E8EA
    textMuted   = {0.659, 0.659, 0.690, 1.0},   -- A8A8B0
    textDim     = {0.420, 0.420, 0.455, 1.0},   -- 6B6B74
    textFaint   = {0.290, 0.290, 0.322, 1.0},   -- 4A4A52
    textGhost   = {0.227, 0.227, 0.259, 1.0},   -- 3A3A42

    -- Linien
    border       = {0.090, 0.090, 0.110, 1.0},  -- 17171C
    borderStrong = {0.118, 0.118, 0.141, 1.0},  -- 1E1E24
    rowLine      = {0.078, 0.078, 0.102, 1.0},  -- 14141A - Zeilentrenner
    hairline     = {0.090, 0.090, 0.110, 1.0},
    hairlineSoft = {0.078, 0.078, 0.102, 1.0},
    borderGlow   = {0.831, 0.635, 0.290, 0.30},
    headerBg     = {0.031, 0.031, 0.039, 1.0},  -- 08080A - Insets (Suchfeld)
    accentDot    = {0.831, 0.635, 0.290, 1.0},

    -- Markenverlauf (Logo, Avatar) - der einzige Ort, an dem Lila bleibt
    brandA      = {0.659, 0.333, 0.969, 1.0},   -- A855F7
    brandB      = {0.388, 0.400, 0.945, 1.0},   -- 6366F1

    -- Text auf Bernstein-Flaechen
    ink         = {0.039, 0.039, 0.047, 1.0},   -- 0A0A0C
}
WeintCodex.Colors = C

--------------------------------------------------
-- Schriften
--------------------------------------------------
-- Inter fuer alles Gesetzte, JetBrains Mono fuer Zahlen, Kennzahlen und
-- Eyebrow-Labels - genau die Aufteilung des Entwurfs. `serif`/`serifBold`
-- sind Altlasten aus der Fraunces-Zeit und zeigen auf Inter, damit die
-- bestehenden Aufrufe weiterlaufen, bis sie migriert sind.
--------------------------------------------------

WeintCodex.Fonts = {
    sans        = MEDIA .. "fonts\\Inter-Regular.ttf",
    sansMedium  = MEDIA .. "fonts\\Inter-Medium.ttf",
    sansSemi    = MEDIA .. "fonts\\Inter-SemiBold.ttf",
    sansBold    = MEDIA .. "fonts\\Inter-Bold.ttf",
    mono        = MEDIA .. "fonts\\JetBrainsMono-Regular.ttf",
    monoMedium  = MEDIA .. "fonts\\JetBrainsMono-Medium.ttf",
    monoBold    = MEDIA .. "fonts\\JetBrainsMono-Bold.ttf",

    serif       = MEDIA .. "fonts\\Inter-SemiBold.ttf",
    serifBold   = MEDIA .. "fonts\\Inter-Bold.ttf",
}
local F = WeintCodex.Fonts

--------------------------------------------------
-- Icon-Helper
--------------------------------------------------
-- Das UI-Font unterstuetzt keine Unicode-Emoji - vorher verwendete Zeichen
-- wie ⚔ ✦ 📦 wurden als leere Kaestchen dargestellt. Es werden deshalb nur
-- echte Texturen ueber die |T...|t-Escape-Syntax verwendet.
--------------------------------------------------

function WeintCodex.Icon(iconPath, size)
    size = size or 14
    return "|T" .. iconPath .. ":" .. size .. "|t"
end

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
-- Grundbausteine
--------------------------------------------------

local function Col(name)
    if type(name) == "table" then return name end
    return C[name] or C.textNormal
end

local function SetSolidBg(frame, r, g, b, a)
    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetColorTexture(r, g, b, a or 1.0)
    return tex
end

-- Zwei-Punkt-verankert statt auf GetWidth()/GetHeight() gerechnet: der Rahmen
-- waechst mit dem Frame mit. Wichtig, weil mehrere Aufrufer (Chip, Danger-
-- Button) ihre Breite erst NACH dem Rahmen aus der Textbreite bestimmen - mit
-- Groessen aus der Bauzeit waeren die Kanten dort 0 breit.
local function DrawBorder(f, r, g, b, a, thick)
    thick = thick or 1
    local function T(p1, p2, w, h)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(p1, f, p1, 0, 0)
        t:SetPoint(p2, f, p2, 0, 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        return t
    end
    T("TOPLEFT",    "TOPRIGHT",    nil,   thick)
    T("BOTTOMLEFT", "BOTTOMRIGHT", nil,   thick)
    T("TOPLEFT",    "BOTTOMLEFT",  thick, nil)
    T("TOPRIGHT",   "BOTTOMRIGHT", thick, nil)
end

local function DrawHLine(parent, r, g, b, a, offsetY, layer)
    local t = parent:CreateTexture(nil, layer or "OVERLAY")
    t:SetHeight(1)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, offsetY)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, offsetY)
    t:SetColorTexture(r, g, b, a)
    return t
end

--------------------------------------------------
-- Runde Ecken
--------------------------------------------------
-- Vier Viertelkreis-Masken in der Farbe des Untergrunds stanzen die Ecken
-- aus. Die Maske (media/ui/corner.tga, 32x32) ist massstabsunabhaengig, ein
-- einziges Bild deckt jeden Radius ab. Zweierpotenz, weil der Client keine
-- andere Texturgroesse laedt.
--------------------------------------------------

local CORNER_UV = {
    TOPLEFT     = { 0, 1, 0, 1 },
    TOPRIGHT    = { 1, 0, 0, 1 },
    BOTTOMLEFT  = { 0, 1, 1, 0 },
    BOTTOMRIGHT = { 1, 0, 1, 0 },
}

function WeintCodex.CutCorners(frame, radius, backdrop, layer, sublevel)
    radius = radius or 14
    local col = Col(backdrop or "bgDark")
    local out = {}
    for point, uv in pairs(CORNER_UV) do
        local t = frame:CreateTexture(nil, layer or "OVERLAY", nil, sublevel or 6)
        t:SetTexture(CORNER)
        t:SetSize(radius, radius)
        t:SetPoint(point, frame, point, 0, 0)
        t:SetTexCoord(uv[1], uv[2], uv[3], uv[4])
        t:SetVertexColor(col[1], col[2], col[3], col[4] or 1.0)
        out[point] = t
    end
    frame._corners = out
    return out
end

-- Faerbt bereits gesetzte Eckmasken um (z.B. wenn eine Karte auf einer
-- anderen Flaeche landet als beim Bau angenommen).
function WeintCodex.RecolorCorners(frame, backdrop)
    if not frame._corners then return end
    local col = Col(backdrop)
    for _, t in pairs(frame._corners) do
        t:SetVertexColor(col[1], col[2], col[3], col[4] or 1.0)
    end
end

--------------------------------------------------
-- Flaechen mit Verlauf
--------------------------------------------------

-- CSS `linear-gradient(180deg, a, b)` -> oben a, unten b.
-- WoW `SetGradient("VERTICAL", min, max)` -> min unten, max oben.
local function ApplyVerticalGradient(tex, topCol, bottomCol)
    local t, b = Col(topCol), Col(bottomCol)
    tex:SetTexture(WHITE)
    tex:SetGradient("VERTICAL",
        CreateColor(b[1], b[2], b[3], b[4] or 1.0),
        CreateColor(t[1], t[2], t[3], t[4] or 1.0))
end
WeintCodex.ApplyVerticalGradient = ApplyVerticalGradient

--------------------------------------------------
-- Karte
--------------------------------------------------
-- Der zentrale Baustein des Entwurfs: kein Rahmen, sondern Verlauf plus eine
-- 1-px-Oberkante, die links und rechts 8 px eingerueckt ist. `tone = "accent"`
-- macht daraus die hervorgehobene Variante (waermerer Verlauf, bernsteinfarbene
-- Oberkante) - im Entwurf immer genau eine pro Seite.
--
-- opts: { width, height, radius = 14, tone = "plain"|"accent"|"flat",
--         backdrop = "bgDark", button = false, hover = false }
--------------------------------------------------

function WeintCodex.CreateSurface(parent, opts)
    opts = opts or {}
    local f = CreateFrame(opts.button and "Button" or "Frame", nil, parent)
    if opts.width  then f:SetWidth(opts.width)   end
    if opts.height then f:SetHeight(opts.height) end

    local tone   = opts.tone or "plain"
    local radius = opts.radius or 14

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    f._bg = bg

    local topLine
    if tone == "flat" then
        bg:SetColorTexture(unpack(Col(opts.surface or "surface1")))
    else
        if tone == "accent" then
            ApplyVerticalGradient(bg, "accentCardTop", "accentCardBot")
        else
            ApplyVerticalGradient(bg, "cardTop", "cardBottom")
        end
        -- Oberkante: 8 px beidseitig eingerueckt, damit sie an den runden
        -- Ecken nicht ueber den Rand hinauslaeuft.
        topLine = f:CreateTexture(nil, "ARTWORK")
        topLine:SetHeight(1)
        topLine:SetPoint("TOPLEFT",  f, "TOPLEFT",   8, 0)
        topLine:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, 0)
        if tone == "accent" then
            topLine:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)
        else
            topLine:SetColorTexture(1, 1, 1, 0.06)
        end
    end
    f._topLine = topLine

    if radius > 0 then
        WeintCodex.CutCorners(f, radius, opts.backdrop or "bgDark")
    end

    f.SetTone = function(self, newTone)
        if newTone == "accent" then
            ApplyVerticalGradient(self._bg, "accentCardTop", "accentCardBot")
            if self._topLine then
                self._topLine:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)
            end
        else
            ApplyVerticalGradient(self._bg, "cardTop", "cardBottom")
            if self._topLine then self._topLine:SetColorTexture(1, 1, 1, 0.06) end
        end
    end

    -- Hover wie im Entwurf: die Flaeche wird eine Stufe heller, nicht umrandet.
    f.SetSurface = function(self, surfaceName)
        local col = C[surfaceName]
        if not col then return end
        self._bg:SetTexture(WHITE)
        self._bg:SetGradient("VERTICAL", CreateColor(col[1], col[2], col[3], col[4] or 1),
                                          CreateColor(col[1], col[2], col[3], col[4] or 1))
    end

    return f
end

--------------------------------------------------
-- Textbausteine
--------------------------------------------------

-- Eyebrow: mono, versal, weit gesperrt. WoW kennt kein letter-spacing, die
-- Sperrung wird deshalb durch eingefuegte Haarspatien nachgebildet.
local function Spaced(text)
    if not text then return "" end
    local out = {}
    for i = 1, #text do
        out[#out + 1] = text:sub(i, i)
    end
    return table.concat(out, "\194\160")
end
WeintCodex.Spaced = Spaced

function WeintCodex.Eyebrow(parent, text, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(F.mono, opts.size or 10, "")
    fs:SetTextColor(unpack(Col(opts.color or "textDim")))
    fs:SetText(Spaced(string.upper(text or "")))
    fs:SetJustifyH(opts.justify or "LEFT")
    return fs
end

function WeintCodex.PageTitle(parent, text, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(F.sansBold, opts.size or 26, "")
    fs:SetTextColor(unpack(Col(opts.color or "textBright")))
    fs:SetText(text or "")
    fs:SetJustifyH(opts.justify or "LEFT")
    return fs
end

function WeintCodex.Label(parent, text, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(opts.font or F.sans, opts.size or 13, "")
    fs:SetTextColor(unpack(Col(opts.color or "textMuted")))
    fs:SetText(text or "")
    fs:SetJustifyH(opts.justify or "LEFT")
    if opts.width then fs:SetWidth(opts.width) end
    return fs
end

-- Kennzahl in Mono, wie im Entwurf rechts im Kopf bzw. in den Kacheln.
function WeintCodex.MonoNumber(parent, text, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(F.monoBold, opts.size or 24, "")
    fs:SetTextColor(unpack(Col(opts.color or "textNormal")))
    fs:SetText(text or "")
    fs:SetJustifyH(opts.justify or "LEFT")
    return fs
end

--------------------------------------------------
-- Statuspunkt (7 px)
--------------------------------------------------
-- Im Entwurf durchgaengig der Traeger von "Zustand". Ein leerer Punkt
-- (tone = nil) ist "noch offen/unbekannt" und wird nur umrandet.
--------------------------------------------------

function WeintCodex.StatusDot(parent, tone, size)
    size = size or 7
    local d = parent:CreateTexture(nil, "OVERLAY")
    d:SetSize(size, size)
    if tone then
        local col = Col(tone)
        d:SetColorTexture(col[1], col[2], col[3], col[4] or 1.0)
    else
        local col = C.textFaint
        d:SetColorTexture(col[1], col[2], col[3], 0.55)
    end
    return d
end

--------------------------------------------------
-- Chip / Badge
--------------------------------------------------
-- Pille mit 13 % Fuellung und 38 % Rand derselben Farbe - die Werte stammen
-- eins zu eins aus dem Entwurf.
--------------------------------------------------

function WeintCodex.Chip(parent, opts)
    opts = opts or {}
    local tone = opts.tone or "textMuted"
    local col  = Col(tone)
    local textCol = Col(opts.textColor or tone)

    local h = opts.height or 26
    local chip = CreateFrame("Frame", nil, parent)
    chip:SetHeight(h)

    local bg = chip:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(chip)
    bg:SetColorTexture(col[1], col[2], col[3], opts.fill or 0.13)
    DrawBorder(chip, col[1], col[2], col[3], opts.borderAlpha or 0.38, 1)

    local lbl = chip:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(F.monoBold, opts.size or 10, "")
    lbl:SetTextColor(textCol[1], textCol[2], textCol[3], 1.0)
    lbl:SetText(Spaced(string.upper(opts.text or "")))
    lbl:SetPoint("CENTER", chip, "CENTER", 0, 0)
    chip._label = lbl

    chip:SetWidth((opts.width) or (lbl:GetStringWidth() + (opts.padding or 24)))

    -- Voll gerundet (Radius = halbe Hoehe) - im Entwurf sind Chips Pillen.
    -- Liegt spaeter im Zeichenstapel als der Rahmen und deckt dessen Ecken ab.
    WeintCodex.CutCorners(chip, math.floor(h / 2), opts.backdrop or "cardTop")

    chip.SetText = function(self, t)
        self._label:SetText(Spaced(string.upper(t or "")))
        if not opts.width then
            self:SetWidth(self._label:GetStringWidth() + (opts.padding or 20))
        end
    end
    return chip
end

--------------------------------------------------
-- Schaltflaechen
--------------------------------------------------
-- Drei Auspraegungen aus dem Entwurf:
--   primary   - Bernstein-Verlauf, dunkler Text, 40 hoch (eine pro Ansicht)
--   secondary - #17171C, heller Text, 34 hoch
--   ghost     - ohne Flaeche, nur Text
--   danger    - roter Rand auf 14-%-Fuellung (Loeschen)
--------------------------------------------------

function WeintCodex.CreateButton(parent, opts)
    opts = opts or {}
    local kind = opts.kind or "secondary"
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(opts.height or (kind == "primary" and 40 or 34))

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    b._bg = bg

    local textCol
    local function paint(hovered)
        if kind == "primary" then
            if hovered then
                ApplyVerticalGradient(bg, "accentBright", "accentBright")
            else
                ApplyVerticalGradient(bg, "accentBright", "accent")
            end
        elseif kind == "ghost" then
            bg:SetColorTexture(1, 1, 1, hovered and 0.05 or 0)
        elseif kind == "danger" then
            bg:SetColorTexture(C.red[1], C.red[2], C.red[3], hovered and 0.22 or 0.14)
        else
            local s = hovered and C.borderStrong or C.surface3
            bg:SetColorTexture(s[1], s[2], s[3], 1.0)
        end
    end
    paint(false)

    if kind == "primary" then
        textCol = C.ink
    elseif kind == "danger" then
        textCol = C.dangerBright
        DrawBorder(b, C.red[1], C.red[2], C.red[3], 0.50, 1)
    elseif kind == "ghost" then
        textCol = C.textMuted
    else
        textCol = C.textNormal
    end

    local lbl = b:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(F.sansSemi, opts.size or 12, "")
    lbl:SetTextColor(textCol[1], textCol[2], textCol[3], 1.0)
    lbl:SetText(opts.text or "")
    lbl:SetPoint("CENTER", b, "CENTER", 0, 0)
    b._label = lbl

    b:SetWidth(opts.width or (lbl:GetStringWidth() + (opts.padding or 36)))

    if opts.radius ~= 0 then
        WeintCodex.CutCorners(b, opts.radius or 6, opts.backdrop or "bgDark")
    end

    b:SetScript("OnEnter", function(self)
        paint(true)
        if opts.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(opts.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function()
        paint(false)
        GameTooltip:Hide()
    end)
    if opts.onClick then b:SetScript("OnClick", opts.onClick) end

    b.SetText = function(self, t)
        self._label:SetText(t or "")
        if not opts.width then
            self:SetWidth(self._label:GetStringWidth() + (opts.padding or 36))
        end
    end
    return b
end

--------------------------------------------------
-- Segmented Control (Reiterleiste)
--------------------------------------------------
-- Ersetzt die frueheren Unternavigationen in der Seitenleiste. Muster aus dem
-- Entwurf: Behaelter #08080A mit 4 px Innenabstand, aktives Segment #17171C.
-- Ein Segment darf einen Statuspunkt tragen ({ text=, dot="danger" }).
--
-- opts: { items = { {text=, dot=, key=}, ... }, onSelect = function(key, i),
--         selected = 1, backdrop = "bgDark" }
--------------------------------------------------

function WeintCodex.CreateSegmentedControl(parent, opts)
    opts = opts or {}
    local items = opts.items or {}

    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(38)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetColorTexture(unpack(C.surface1))
    WeintCodex.CutCorners(bar, 10, opts.backdrop or "bgDark")

    local segs, total = {}, 8
    for i, item in ipairs(items) do
        local s = CreateFrame("Button", nil, bar)
        s:SetHeight(30)

        local sbg = s:CreateTexture(nil, "BACKGROUND")
        sbg:SetAllPoints(s)
        sbg:SetColorTexture(0, 0, 0, 0)

        local lbl = s:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(F.sansSemi, 12, "")
        lbl:SetText(item.text or "")
        lbl:SetPoint("LEFT", s, "LEFT", 14, 0)

        local dot
        if item.dot then
            dot = WeintCodex.StatusDot(s, item.dot, 7)
            dot:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
        end

        local w = lbl:GetStringWidth() + 28 + (dot and 15 or 0)
        s:SetWidth(w)
        s:SetPoint("LEFT", bar, "LEFT", total - 4, 0)
        total = total + w + 6

        s._bg, s._label, s._key, s._index = sbg, lbl, item.key or i, i
        segs[i] = s
    end
    bar:SetWidth(total - 6 + 8)

    local selected = opts.selected or 1

    local function apply()
        for i, s in ipairs(segs) do
            if i == selected then
                s._bg:SetColorTexture(unpack(C.surface3))
                s._label:SetTextColor(unpack(C.textBright))
                if not s._rounded then
                    WeintCodex.CutCorners(s, 6, "surface1")
                    s._rounded = true
                end
                if s._corners then
                    for _, t in pairs(s._corners) do t:Show() end
                end
            else
                s._bg:SetColorTexture(0, 0, 0, 0)
                s._label:SetTextColor(unpack(C.textMuted))
                if s._corners then
                    for _, t in pairs(s._corners) do t:Hide() end
                end
            end
        end
    end

    for i, s in ipairs(segs) do
        s:SetScript("OnEnter", function(self)
            if i ~= selected then self._label:SetTextColor(unpack(C.textNormal)) end
        end)
        s:SetScript("OnLeave", function(self)
            if i ~= selected then self._label:SetTextColor(unpack(C.textMuted)) end
        end)
        s:SetScript("OnClick", function(self)
            selected = i
            apply()
            if opts.onSelect then opts.onSelect(self._key, i) end
        end)
    end
    apply()

    bar.Select = function(_, i)
        selected = i
        apply()
    end
    bar.GetSelected = function() return selected end
    bar._segments = segs
    return bar
end

--------------------------------------------------
-- Fortschrittsbalken
--------------------------------------------------

function WeintCodex.CreateMeter(parent, opts)
    opts = opts or {}
    local h = opts.height or 6
    local m = CreateFrame("Frame", nil, parent)
    m:SetHeight(h)
    if opts.width then m:SetWidth(opts.width) end

    local track = m:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(m)
    track:SetColorTexture(unpack(C.surface1))

    local fill = m:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", m, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", m, "BOTTOMLEFT", 0, 0)
    local col = Col(opts.tone or "accent")
    fill:SetColorTexture(col[1], col[2], col[3], 1.0)
    m._fill = fill

    m.SetValue = function(self, pct, tone)
        pct = math.max(0, math.min(1, pct or 0))
        local w = (self:GetWidth() or 0) * pct
        self._fill:SetWidth(math.max(pct > 0 and 1 or 0, w))
        if tone then
            local c = Col(tone)
            self._fill:SetColorTexture(c[1], c[2], c[3], 1.0)
        end
    end
    m:SetValue(opts.value or 0)
    return m
end

--------------------------------------------------
-- Zeilentrenner
--------------------------------------------------

function WeintCodex.RowLine(parent, offsetY, tone)
    local col = Col(tone or "rowLine")
    return DrawHLine(parent, col[1], col[2], col[3], col[4] or 1.0, offsetY or 0, "ARTWORK")
end

--------------------------------------------------
-- Hex-Helper
--------------------------------------------------

function WeintCodex.ColorText(colorName, text)
    local col = C[colorName]
    if not col then return text end
    return string.format("|cff%02x%02x%02x%s|r",
        (col[1] or 0) * 255, (col[2] or 0) * 255, (col[3] or 0) * 255, text)
end

--------------------------------------------------
-- Scrollbereich
--------------------------------------------------
-- Die Standard-Bildlaufleiste (UIPanelScrollFrameTemplate) frisst 26 px. Der
-- Entwurf zeichnet 8 px. `slim = true` blendet die Blizzard-Optik aus und
-- setzt einen schlanken Griff darueber - dieselbe Loesung wie bei den
-- Bossnotizen, nur an einer Stelle statt an zweien.
--------------------------------------------------

function WeintCodex.CreateScrollArea(parent, x, y, w, h, slim)
    local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    sf:SetSize(w, h)
    sf:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local inner = CreateFrame("Frame", nil, sf)
    inner:SetSize(w - (slim and 10 or 20), h)
    sf:SetScrollChild(inner)

    if slim then
        local bar = _G[(sf:GetName() or "") .. "ScrollBar"] or sf.ScrollBar
        if not bar then
            for _, child in ipairs({ sf:GetChildren() }) do
                if child:GetObjectType() == "Slider" then bar = child break end
            end
        end
        if bar then
            bar:SetWidth(8)
            for _, region in ipairs({ bar:GetRegions() }) do
                if region:GetObjectType() == "Texture" then region:SetTexture(nil) end
            end
            local up, down = bar:GetChildren()
            if up   then up:Hide()   ; up:SetHeight(1)   end
            if down then down:Hide() ; down:SetHeight(1) end
            local thumb = bar:GetThumbTexture()
            if thumb then
                thumb:SetTexture(WHITE)
                thumb:SetVertexColor(C.textFaint[1], C.textFaint[2], C.textFaint[3], 0.65)
                thumb:SetSize(4, 40)
            end
        end
    end
    return sf, inner
end

--------------------------------------------------
-- Zahlen-/Zeitformate
--------------------------------------------------
-- Spiegeln die Darstellung der Companion-App, damit dieselbe Auswertung
-- ingame und auf dem Desktop gleich aussieht. Dezimaltrennzeichen ist das
-- deutsche Komma.
--------------------------------------------------

function WeintCodex.FormatAmount(value)
    value = tonumber(value) or 0
    local sign = value < 0 and "-" or ""
    value = math.abs(value)
    local text
    if value >= 1000000 then
        text = string.format("%.2fM", value / 1000000)
    elseif value >= 1000 then
        text = string.format("%.1fk", value / 1000)
    else
        text = string.format("%d", value + 0.5)
    end
    return sign .. (text:gsub("%.", ","))
end

function WeintCodex.FormatClock(seconds)
    seconds = math.floor(tonumber(seconds) or 0)
    if seconds < 0 then seconds = 0 end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

function WeintCodex.FormatPercent(value, decimals)
    value = tonumber(value) or 0
    local text = string.format("%." .. (decimals or 0) .. "f", value)
    return (text:gsub("%.", ",")) .. " %"
end

-- Tausenderpunkt wie im Entwurf ("+14 210" mit schmalem Leerzeichen).
function WeintCodex.FormatGrouped(value)
    local n = math.floor(math.abs(tonumber(value) or 0))
    local s = tostring(n)
    local out = s:reverse():gsub("(%d%d%d)", "%1\194\160"):reverse()
    out = out:gsub("^\194\160", "")
    return ((tonumber(value) or 0) < 0 and "-" or "") .. out
end

--------------------------------------------------
-- Altlasten der v1-Oberflaeche
--------------------------------------------------
-- Bleiben erhalten, weil rund 40 Aufrufstellen sie nutzen. Rahmen und
-- Eck-Akzente sind in der neuen Sprache aber kein Gestaltungsmittel mehr:
-- CreateCard liefert deshalb eine Karte im neuen Sinn, egal welchen `style`
-- der Aufrufer noch mitgibt.
--------------------------------------------------

function WeintCodex.DrawSlimBorder(frame, colorName, alpha, thick)
    thick = thick or 1
    local col = C[colorName] or C.hairline
    alpha = alpha or col[4] or 1.0
    DrawBorder(frame, col[1], col[2], col[3], alpha, thick)
end

function WeintCodex.DrawCornerAccents(frame, colorName, size, thick)
    size  = size  or 12
    thick = thick or 2
    local col = C[colorName] or C.accent
    local function Corner(point, hx, hy)
        local h = frame:CreateTexture(nil, "OVERLAY")
        h:SetColorTexture(col[1], col[2], col[3], col[4] or 1.0)
        h:SetPoint(point, frame, point, hx, hy)
        h:SetSize(size, thick)
        local v = frame:CreateTexture(nil, "OVERLAY")
        v:SetColorTexture(col[1], col[2], col[3], col[4] or 1.0)
        v:SetPoint(point, frame, point, hx, hy)
        v:SetSize(thick, size)
    end
    Corner("TOPLEFT", 0, 0)     Corner("TOPRIGHT", 0, 0)
    Corner("BOTTOMLEFT", 0, 0)  Corner("BOTTOMRIGHT", 0, 0)
end

function WeintCodex.CreateCard(parent, opts)
    opts = opts or {}
    local card = WeintCodex.CreateSurface(parent, {
        width    = opts.width,
        height   = opts.height,
        tone     = opts.tone or (opts.surface == "surface1" and "flat" or "plain"),
        surface  = opts.surface,
        radius   = opts.radius or 14,
        backdrop = opts.backdrop or "bgDark",
        button   = opts.buttonStyle,
    })
    card._surface = opts.surface or "surface2"

    local titleStr
    if opts.title then
        titleStr = card:CreateFontString(nil, "OVERLAY")
        titleStr:SetFont(F.sansSemi, 14, "")
        titleStr:SetPoint("TOPLEFT", card, "TOPLEFT", 20, -16)
        titleStr:SetTextColor(unpack(Col(opts.titleColor or "textBright")))
        titleStr:SetText(opts.title)
    end
    card.SetTitle = function(self, text)
        if titleStr then titleStr:SetText(text) end
    end
    return card
end

WeintCodex.SetSolidBg = SetSolidBg
WeintCodex.DrawBorder = DrawBorder
WeintCodex.SetBorder  = DrawBorder
WeintCodex.DrawHLine  = DrawHLine
WeintCodex.C          = C

--------------------------------------------------
-- Fenster
--------------------------------------------------
-- Aufbau nach Entwurf 1a: Titelleiste 40, Navigationsspalte 232 mit Gruppen,
-- Inhalt daneben. Die frueheren vier Spalten (Rail 64 | Sub-Nav 240 | Inhalt |
-- Inspector 340) sind damit auf zwei zusammengezogen.
--
-- Der Inspector verschwindet nicht als API: er wird zum Detailbereich INNERHALB
-- der Seite (rechte Spalte, 380 breit). Neun Module liefern ueber
-- Navigation.SetInspector Bloecke - die zeichnen jetzt dorthin, statt in eine
-- eigene Fensterspalte. ContentPanel schrumpft dabei automatisch, sodass die
-- vorhandene Positionierungslogik der Module unveraendert weiterlaeuft.
--------------------------------------------------

local FRAME_W, FRAME_H = 1500, 800
local FRAME_MIN_W, FRAME_MIN_H = 1180, 780
local FRAME_MAX_W, FRAME_MAX_H = 1700, 1000

local TITLEBAR_H = 40
local NAV_W      = 232
local DETAIL_W   = 372   -- Entwurf: Inhaltsraster "1fr 372px" auf 2c/2d
local DETAIL_GAP = 16

WeintCodex.Metrics = {
    TITLEBAR_H = TITLEBAR_H,
    NAV_W      = NAV_W,
    DETAIL_W   = DETAIL_W,
    PAD_X      = 32,   -- Innenabstand des Inhaltsbereichs, Entwurf: 24px 32px
    PAD_Y      = 24,
    GAP        = 16,
    CARD_R     = 14,
    ROW_H      = 30,
}

local frame = CreateFrame("Frame", "WeintCodexMainFrame", UIParent)
frame:SetSize(FRAME_W, FRAME_H)
frame:SetPoint("CENTER")
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:SetToplevel(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
frame:SetResizable(true)
if frame.SetResizeBounds then
    frame:SetResizeBounds(FRAME_MIN_W, FRAME_MIN_H, FRAME_MAX_W, FRAME_MAX_H)
end
frame:Hide()

local frameBg = frame:CreateTexture(nil, "BACKGROUND")
frameBg:SetAllPoints(frame)
frameBg:SetColorTexture(unpack(C.bgDark))
-- Das Fenster selbst bekommt bewusst KEINE runden Ecken. CutCorners deckt die
-- Ecke mit der Farbe des Untergrunds ab - hinter dem Hauptfenster liegt aber
-- die Spielwelt, deren Farbe wir nicht kennen. Der Entwurf zeigt hier einen
-- Radius, den WoW ohne echte Transparenz im Frame nicht liefern kann.

local function ApplySavedWindow()
    if WeintCodex.SavedData and WeintCodex.SavedData.window then
        local w = WeintCodex.SavedData.window
        if w.width  then frame:SetWidth(w.width)   end
        if w.height then frame:SetHeight(w.height)  end
        if w.scale  then frame:SetScale(w.scale)    end
    end
end

--------------------------------------------------
-- Titelleiste
--------------------------------------------------

local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetHeight(TITLEBAR_H)
titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

local tbBg = titleBar:CreateTexture(nil, "BACKGROUND")
tbBg:SetAllPoints(titleBar)
ApplyVerticalGradient(tbBg, { 0.047, 0.047, 0.063, 1 }, C.bgPanel)  -- 0C0C10 -> 08080A

local tbLine = titleBar:CreateTexture(nil, "ARTWORK")
tbLine:SetHeight(1)
tbLine:SetPoint("BOTTOMLEFT",  titleBar, "BOTTOMLEFT",  0, 0)
tbLine:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
tbLine:SetColorTexture(unpack(C.border))

-- Markenzeichen: einziger Ort, an dem der Lila-Verlauf der Companion bleibt.
local brand = CreateFrame("Frame", nil, titleBar)
brand:SetSize(26, 26)
brand:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
local brandTex = brand:CreateTexture(nil, "ARTWORK")
brandTex:SetAllPoints(brand)
ApplyVerticalGradient(brandTex, "brandA", "brandB")
WeintCodex.CutCorners(brand, 8, "bgPanel")
local brandLbl = brand:CreateFontString(nil, "OVERLAY")
brandLbl:SetFont(F.monoBold, 12, "")
brandLbl:SetPoint("CENTER", brand, "CENTER", 0, 0)
brandLbl:SetTextColor(1, 1, 1, 1)
brandLbl:SetText("W")

local wordmark = titleBar:CreateFontString(nil, "OVERLAY")
wordmark:SetFont(F.sansSemi, 13, "")
wordmark:SetPoint("LEFT", brand, "RIGHT", 12, 0)
wordmark:SetTextColor(unpack(C.textNormal))
wordmark:SetText("WeintCodex")

local wordDiv = titleBar:CreateTexture(nil, "ARTWORK")
wordDiv:SetSize(1, 14)
wordDiv:SetPoint("LEFT", wordmark, "RIGHT", 12, 0)
wordDiv:SetColorTexture(unpack(C.borderStrong))

local breadcrumb = titleBar:CreateFontString(nil, "OVERLAY")
breadcrumb:SetFont(F.mono, 10, "")
breadcrumb:SetPoint("LEFT", wordDiv, "RIGHT", 12, 0)
breadcrumb:SetJustifyH("LEFT")
breadcrumb:SetTextColor(unpack(C.textFaint))
WeintCodex.Breadcrumb = breadcrumb

function WeintCodex.SetBreadcrumb(...)
    local parts = { ... }
    local segs = {}
    for i, p in ipairs(parts) do
        segs[#segs + 1] = Spaced(string.upper(tostring(p)))
        if i < #parts then segs[#segs + 1] = " \194\183 " end
    end
    breadcrumb:SetText(table.concat(segs))
end

-- Schliessen
local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(28, 24)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)
local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
closeX:SetFont(F.sans, 14, "")
closeX:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
closeX:SetTextColor(unpack(C.textMuted))
closeX:SetText("\195\151")
closeBtn:SetScript("OnClick", function() frame:Hide() end)
closeBtn:SetScript("OnEnter", function() closeX:SetTextColor(unpack(C.textBright)) end)
closeBtn:SetScript("OnLeave", function() closeX:SetTextColor(unpack(C.textMuted)) end)

local versionLbl = titleBar:CreateFontString(nil, "OVERLAY")
versionLbl:SetFont(F.mono, 10, "")
versionLbl:SetPoint("RIGHT", closeBtn, "LEFT", -8, 0)
versionLbl:SetTextColor(unpack(C.textFaint))
versionLbl:SetText(Spaced("V" .. (WeintCodex.Version or "2.0.0.0")))
WeintCodex.VersionLabel = versionLbl

-- Aktionsbereich je Modul, links neben der Versionsmarke.
local titleActions = CreateFrame("Frame", nil, titleBar)
titleActions:SetHeight(TITLEBAR_H)
titleActions:SetPoint("RIGHT", versionLbl, "LEFT", -12, 0)
titleActions:SetWidth(1)
WeintCodex.TitleBarActions = titleActions

--------------------------------------------------
-- Suche
--------------------------------------------------
-- Logik/Datenindex/Strg+K sitzen in core/search.lua; hier nur das Feld.

local searchBox = CreateFrame("EditBox", nil, titleBar)
searchBox:SetSize(260, 26)
searchBox:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
searchBox:SetAutoFocus(false)
searchBox:SetFontObject("ChatFontNormal")
searchBox:SetFont(F.sans, 12, "")
searchBox:SetTextColor(unpack(C.textNormal))
searchBox:SetTextInsets(28, 52, 0, 0)
searchBox:SetMaxLetters(80)

SetSolidBg(searchBox, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)
DrawBorder(searchBox, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
WeintCodex.CutCorners(searchBox, 8, "bgPanel")

local searchIcon = searchBox:CreateFontString(nil, "OVERLAY")
searchIcon:SetFont(F.sans, 12, "")
searchIcon:SetPoint("LEFT", searchBox, "LEFT", 10, 0)
searchIcon:SetText(WeintCodex.Icon("Interface\\Common\\UI-Searchbox-Icon", 12))

local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY")
searchPlaceholder:SetFont(F.sans, 12, "")
searchPlaceholder:SetPoint("LEFT", searchBox, "LEFT", 28, 0)
searchPlaceholder:SetPoint("RIGHT", searchBox, "RIGHT", -52, 0)
searchPlaceholder:SetJustifyH("LEFT")
searchPlaceholder:SetTextColor(unpack(C.textDim))
searchPlaceholder:SetText("Suchen")

local searchChip = searchBox:CreateFontString(nil, "OVERLAY")
searchChip:SetFont(F.mono, 9, "")
searchChip:SetPoint("RIGHT", searchBox, "RIGHT", -10, 0)
searchChip:SetTextColor(unpack(C.textFaint))
searchChip:SetText(Spaced("STRG K"))

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

local searchResults = CreateFrame("Frame", nil, frame)
searchResults:SetPoint("TOPLEFT",  searchBox, "BOTTOMLEFT",  0, -6)
searchResults:SetPoint("TOPRIGHT", searchBox, "BOTTOMRIGHT", 0, -6)
searchResults:SetFrameStrata("DIALOG")
SetSolidBg(searchResults, C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
DrawBorder(searchResults, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
searchResults:Hide()
WeintCodex.SearchResults = searchResults

--------------------------------------------------
-- Navigationsspalte
--------------------------------------------------
-- Befuellt wird sie von core/navigation.lua; hier entsteht nur die Flaeche.

local navColumn = CreateFrame("Frame", nil, frame)
navColumn:SetWidth(NAV_W)
navColumn:SetPoint("TOPLEFT",    titleBar, "BOTTOMLEFT", 0, 0)
navColumn:SetPoint("BOTTOMLEFT", frame,    "BOTTOMLEFT", 0, 0)
SetSolidBg(navColumn, C.bgPanel[1], C.bgPanel[2], C.bgPanel[3], 1.0)

local navDiv = navColumn:CreateTexture(nil, "OVERLAY")
navDiv:SetPoint("TOPRIGHT",    navColumn, "TOPRIGHT",    0, 0)
navDiv:SetPoint("BOTTOMRIGHT", navColumn, "BOTTOMRIGHT", 0, 0)
navDiv:SetWidth(1)
navDiv:SetColorTexture(unpack(C.border))

WeintCodex.NavColumn = navColumn
-- Altname: core/access.lua und core/search.lua sprechen die Leiste noch so an.
WeintCodex.IconRail = navColumn

--------------------------------------------------
-- Inhalt und Detailbereich
--------------------------------------------------

local contentHost = CreateFrame("Frame", nil, frame)
contentHost:SetPoint("TOPLEFT",     navColumn, "TOPRIGHT",    0, 0)
contentHost:SetPoint("BOTTOMRIGHT", frame,     "BOTTOMRIGHT", 0, 0)

local contentPanel = CreateFrame("Frame", nil, contentHost)
contentPanel:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 0, 0)
contentPanel:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", 0, 0)

local inspector = CreateFrame("Frame", nil, contentHost)
inspector:SetWidth(DETAIL_W)
inspector:SetPoint("TOPRIGHT",    contentHost, "TOPRIGHT",    -WeintCodex.Metrics.PAD_X, -WeintCodex.Metrics.PAD_Y)
inspector:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -WeintCodex.Metrics.PAD_X,  WeintCodex.Metrics.PAD_Y)
inspector:Hide()

--------------------------------------------------
-- Innenabstaende des Inhaltsbereichs
--------------------------------------------------
-- Drei Dinge koennen den Inhalt beschneiden: der Detailbereich rechts, eine
-- Unternavigation links (lange Listen wie die Bosse) und die Reiterleiste
-- oben. Alle drei laufen ueber EINEN Rechenweg, weil sie sich sonst
-- gegenseitig die Verankerung ueberschreiben - ClearAllPoints/SetPoint je
-- Aufrufer waere genau der Fehler, den man erst bei zwei gleichzeitig sieht.
--
-- Der Sinn dahinter: die Module rechnen unveraendert gegen ContentPanel. Sie
-- merken vom Umbau nichts, ihre Flaeche wird nur kleiner.

local detailShown, subNavW, subNavTop = false, 0, 0

local function UpdateContentInsets()
    contentPanel:ClearAllPoints()
    contentPanel:SetPoint("TOPLEFT", contentHost, "TOPLEFT", subNavW, -subNavTop)
    contentPanel:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT",
        detailShown and -(DETAIL_W + DETAIL_GAP + WeintCodex.Metrics.PAD_X) or 0, 0)
end

function WeintCodex.SetDetailShown(shown)
    detailShown = shown and true or false
    if detailShown then inspector:Show() else inspector:Hide() end
    UpdateContentInsets()
end

-- Breite einer Unternavigationsspalte links im Inhalt (0 = keine).
function WeintCodex.SetSubNavWidth(w)
    subNavW = w or 0
    UpdateContentInsets()
end

-- Hoehe der Reiterleiste ueber dem Inhalt (0 = keine).
function WeintCodex.SetSubNavTop(h)
    subNavTop = h or 0
    UpdateContentInsets()
end

UpdateContentInsets()

WeintCodex.ContentHost  = contentHost
WeintCodex.ContentPanel = contentPanel
WeintCodex.Inspector    = inspector

--------------------------------------------------
-- Groessengriff
--------------------------------------------------

local resizeBtn = CreateFrame("Button", nil, frame)
resizeBtn:SetSize(16, 16)
resizeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
resizeBtn:SetFrameLevel(frame:GetFrameLevel() + 10)

local gripMarks = {}
local function MakeGripLine(offsetX, offsetY, w, h)
    local t = resizeBtn:CreateTexture(nil, "OVERLAY")
    t:SetSize(w, h)
    t:SetPoint("BOTTOMRIGHT", resizeBtn, "BOTTOMRIGHT", offsetX, offsetY)
    t:SetColorTexture(C.textFaint[1], C.textFaint[2], C.textFaint[3], 0.80)
    gripMarks[#gripMarks + 1] = t
end
MakeGripLine(0, 0, 9, 1)  MakeGripLine(0, 4, 6, 1)  MakeGripLine(0, 8, 3, 1)
MakeGripLine(0, 0, 1, 9)  MakeGripLine(4, 0, 1, 6)  MakeGripLine(8, 0, 1, 3)

local function TintGrip(col, alpha)
    for _, t in ipairs(gripMarks) do
        t:SetColorTexture(col[1], col[2], col[3], alpha)
    end
end
resizeBtn:SetScript("OnEnter", function() TintGrip(C.accent, 0.90) end)
resizeBtn:SetScript("OnLeave", function() TintGrip(C.textFaint, 0.80) end)
resizeBtn:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
resizeBtn:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    if WeintCodex.SavedData and WeintCodex.SavedData.window then
        WeintCodex.SavedData.window.width  = math.floor(frame:GetWidth())
        WeintCodex.SavedData.window.height = math.floor(frame:GetHeight())
    end
end)

frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

--------------------------------------------------
-- Globale Referenzen
--------------------------------------------------

WeintCodex.MainFrame        = frame
WeintCodex.TitleBar         = titleBar
WeintCodex.ApplySavedWindow = ApplySavedWindow

-- Die frueheren Chrome-Spalten gibt es nicht mehr. Sidebar bleibt als leerer,
-- versteckter Frame bestehen, damit vereinzelte Alt-Zugriffe nicht auf nil
-- laufen - Unternavigation ist jetzt die Reiterleiste in der Seite.
local legacySidebar = CreateFrame("Frame", nil, frame)
legacySidebar:SetSize(1, 1)
legacySidebar:Hide()
WeintCodex.Sidebar = legacySidebar
WeintCodex.SidebarHeader = legacySidebar:CreateFontString(nil, "OVERLAY")

--------------------------------------------------
-- Universeller Export-Dialog (Overlay)
--------------------------------------------------

local exportFrame = nil
function WeintCodex.ShowExportDialog(titleText, exportStr)
    if not exportFrame then
        local parent = WeintCodex.MainFrame
        local f = WeintCodex.CreateSurface(parent, {
            width = 620, height = 280, tone = "plain", radius = 14, backdrop = "bgDark",
        })
        f:SetPoint("CENTER", parent, "CENTER", 0, 0)
        f:SetFrameStrata("TOOLTIP")
        f:EnableMouse(true)

        local eyebrow = WeintCodex.Eyebrow(f, "Export")
        eyebrow:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -20)

        local t = f:CreateFontString(nil, "OVERLAY")
        t:SetFont(F.sansBold, 20, "")
        t:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)
        t:SetTextColor(unpack(C.textBright))
        f._title = t

        local sub = WeintCodex.Label(f, "Kopiere diesen String (Strg+C) und füge ihn bei deinem Discord-Bot ein:",
            { color = "textMuted", size = 13 })
        sub:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
        sub:SetWidth(560)

        local ebBg = WeintCodex.CreateSurface(f, {
            width = 572, height = 110, tone = "flat", surface = "surface1",
            radius = 10, backdrop = "cardTop",
        })
        ebBg:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)

        local eb = CreateFrame("EditBox", nil, ebBg)
        eb:SetSize(552, 100)
        eb:SetPoint("TOPLEFT", ebBg, "TOPLEFT", 10, -6)
        eb:SetMultiLine(true)
        eb:SetMaxLetters(0)
        eb:SetAutoFocus(false)
        eb:SetFont(F.mono, 11, "")
        eb:SetTextColor(unpack(C.textNormal))
        eb:SetTextInsets(4, 4, 4, 4)

        local scroll = CreateFrame("ScrollFrame", nil, ebBg, "UIPanelScrollFrameTemplate")
        scroll:SetSize(552, 100)
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

        local close = WeintCodex.CreateButton(f, {
            text = "Schließen", kind = "primary", width = 140,
            backdrop = "cardBottom",
            onClick = function() f:Hide() end,
        })
        close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 20)

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
