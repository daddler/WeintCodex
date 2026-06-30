-- dialog.lua
WeintCodex = WeintCodex or {}
WeintCodex.Dialog = {}

local C = WeintCodex.C
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

local overlay
local window
local textLabel

local function CreateButton(parent, text, width, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 30)

    SetSolidBg(btn, C.purple[1], C.purple[2], C.purple[3], 0.85)
    DrawBorder(btn, C.purple[1], C.purple[2], C.purple[3], 1, 1)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetAllPoints(btn)
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    lbl:SetText(text)
    lbl:SetTextColor(1,1,1)

    btn:SetScript("OnEnter", function(self)
        SetSolidBg(self,
            C.purple[1]*1.15,
            C.purple[2]*1.15,
            C.purple[3]*1.15,
            0.95)
    end)

    btn:SetScript("OnLeave", function(self)
        SetSolidBg(self,
            C.purple[1],
            C.purple[2],
            C.purple[3],
            0.85)
    end)

    btn:SetScript("OnClick", onClick)

    return btn
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

    SetSolidBg(window, 0.10,0.10,0.13,0.98)
    DrawBorder(window,
        C.purple[1],
        C.purple[2],
        C.purple[3],
        1,
        2)

    local title = window:CreateFontString(nil,"OVERLAY")
    title:SetPoint("TOP",0,-18)
    title:SetFont("Fonts\\FRIZQT__.TTF",18,"OUTLINE")
    title:SetTextColor(1,0.82,0)
    title:SetText("🔄 Synchronisation")

    local divider = window:CreateTexture(nil,"ARTWORK")
    divider:SetColorTexture(
        C.purple[1],
        C.purple[2],
        C.purple[3],
        0.7
    )
    divider:SetPoint("TOPLEFT",18,-48)
    divider:SetPoint("TOPRIGHT",-18,-48)
    divider:SetHeight(1)

    textLabel = window:CreateFontString(nil,"OVERLAY")
    textLabel:SetPoint("TOPLEFT",30,-70)
    textLabel:SetPoint("TOPRIGHT",-30,-70)
    textLabel:SetJustifyH("CENTER")
    textLabel:SetFont("Fonts\\FRIZQT__.TTF",12,"")
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
