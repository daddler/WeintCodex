-- dialog.lua
WeintCodex = WeintCodex or {}
WeintCodex.Dialog = {}

local C = WeintCodex.C
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

local overlay
local window
local textLabel

-- Gemeinsame Schaltflaeche der neuen Sprache statt eigener Knopfform.
local function CreateButton(parent, text, width, onClick)
    return WeintCodex.CreateButton(parent, {
        text = text, width = width, kind = "primary",
        height = 32, backdrop = "surface2", onClick = onClick,
    })
end

local function Create()

    if overlay then return end

    local parent = WeintCodex.MainFrame
    if not parent then return end

    overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints(parent)
    overlay:SetFrameLevel(parent:GetFrameLevel()+100)
    overlay:EnableMouse(true)

    SetSolidBg(overlay, 0,0,0,0.70)
    overlay:Hide()

    window = CreateFrame("Frame", nil, overlay)
    window:SetSize(460,260)
    window:SetPoint("CENTER")

    SetSolidBg(window, C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
    DrawBorder(window, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
    -- Bernstein nur als Oberkante, wie an jeder Karte der neuen Sprache.
    local winTop = window:CreateTexture(nil, "ARTWORK")
    winTop:SetHeight(1)
    winTop:SetPoint("TOPLEFT",  window, "TOPLEFT",   8, 0)
    winTop:SetPoint("TOPRIGHT", window, "TOPRIGHT", -8, 0)
    winTop:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)
    WeintCodex.CutCorners(window, 14, "bgDark")

    local title = window:CreateFontString(nil,"OVERLAY")
    title:SetPoint("TOP",0,-18)
    title:SetFont(WeintCodex.Fonts.sansBold, 18, "")
    title:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])
    title:SetText(WeintCodex.Icon("Interface\\Icons\\INV_Misc_PocketWatch_01", 18) .. " Synchronisation")

    local divider = window:CreateTexture(nil,"ARTWORK")
    divider:SetColorTexture(
        C.border[1],
        C.border[2],
        C.border[3],
        1.0
    )
    divider:SetPoint("TOPLEFT",18,-48)
    divider:SetPoint("TOPRIGHT",-18,-48)
    divider:SetHeight(1)

    textLabel = window:CreateFontString(nil,"OVERLAY")
    textLabel:SetPoint("TOPLEFT",30,-70)
    textLabel:SetPoint("TOPRIGHT",-30,-70)
    textLabel:SetJustifyH("CENTER")
    textLabel:SetFont(WeintCodex.Fonts.sans, 12, "")
    textLabel:SetTextColor(.92,.92,.92)

    local sync = CreateButton(
        window,
        "Synchronisation starten",
        220,
        function()
            overlay:Hide()
            ReloadUI()
        end
    )
    sync:SetPoint("BOTTOM",0,48)

    local later = CreateButton(
        window,
        "Später",
        220,
        function()
            overlay:Hide()
        end
    )
    later:SetPoint("BOTTOM",0,12)
end

function WeintCodex.Dialog.Show(message)

    Create()

    if not overlay then return end

    textLabel:SetText(message or
[[Die Daten wurden erfolgreich vorbereitet.

Damit Weint Companion die Synchronisation
durchführen kann, muss die Benutzeroberfläche
einmal neu geladen werden.]])

    overlay:Show()
end

function WeintCodex.Dialog.Hide()
    if overlay then
        overlay:Hide()
    end
end
