--------------------------------------------------
-- WeintCodex :: WeakAuras
--------------------------------------------------

WeintCodex.WeakAuras = {}

--------------------------------------------------
-- Hilfsfunktion
--------------------------------------------------

local function ClearContent()

local cp = WeintCodex.ContentPanel
if not cp then return end

    for _, child in pairs({ cp:GetChildren() }) do
        child:Hide()
        end

        end

        --------------------------------------------------
        -- Kategorie anzeigen
        --------------------------------------------------

        function WeintCodex.WeakAuras.ShowCategory(category)

        ClearContent()

        local cp = WeintCodex.ContentPanel
        if not cp then return end
            local scroll = CreateFrame("ScrollFrame", nil, cp, "UIPanelScrollFrameTemplate")
            scroll:SetAllPoints(cp)

            local container = CreateFrame("Frame", nil, scroll)
            container:SetSize(860, 1)

            scroll:SetScrollChild(container)

            local yOffset = -20

            --------------------------------------------------
            -- Überschrift
            --------------------------------------------------

            local title = container:CreateFontString(nil, "OVERLAY")
            title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
            title:SetPoint("TOPLEFT", 15, -10)

            local descriptionText = ""

            if category == "class" then
                title:SetText("Klassenauren")
                descriptionText = "Hier findest du die vollständigen Klassenauren für alle Spezialisierungen. Mit einem Klick auf |cff9B6BFFInstallieren|r wird die Aura automatisch an WeakAuras übergeben."
                elseif category == "raid" then
                    title:SetText("Raidauren")
                    descriptionText = "Hier findest du Raid-Auren und Boss-Pakete. Installiere die gewünschten Pakete direkt mit einem Klick."
                    elseif category == "utility" then
                        title:SetText("Utility-Auren")
                        descriptionText = "Hier findest du allgemeine Utility-Auren, die unabhängig von Klasse oder Raid genutzt werden können."
                        end

                        local description = container:CreateFontString(nil, "OVERLAY")
                        description:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                        description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
                        description:SetWidth(860)
                        description:SetJustifyH("LEFT")
                        description:SetText(descriptionText)

                        --------------------------------------------------
                        -- Trennlinie
                        --------------------------------------------------

                        local line = container:CreateTexture(nil, "ARTWORK")
                        line:SetHeight(1)
                        line:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -12)
                        line:SetPoint("TOPRIGHT", container, "TOPRIGHT", -20, -12)
                        line:SetColorTexture(0.45, 0.20, 0.70, 0.35)

                        --------------------------------------------------
                        -- Tabellenüberschrift
                        --------------------------------------------------

                        local header = CreateFrame("Frame", nil, container)
                        header:SetSize(850, 24)
                        header:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, -8)

                        local hName = header:CreateFontString(nil, "OVERLAY")
                        hName:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                        hName:SetPoint("LEFT", 42, 0)
                        hName:SetWidth(140)
                        hName:SetJustifyH("LEFT")
                        local firstColumn = "Name"

                        if category == "class" then
                            firstColumn = "Klasse"
                            elseif category == "raid" then
                                firstColumn = "Raidpaket"
                                elseif category == "utility" then
                                    firstColumn = "Aura"
                                    end

                                    hName:SetText(firstColumn)

                        local hDesc = header:CreateFontString(nil, "OVERLAY")
                        hDesc:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                        hDesc:SetPoint("LEFT", hName, "RIGHT", 10, 0)
                        hDesc:SetWidth(380)
                        hDesc:SetJustifyH("LEFT")
                        hDesc:SetText("Beschreibung")

                        local hVersion = header:CreateFontString(nil, "OVERLAY")
                        hVersion:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                        hVersion:SetPoint("LEFT", hDesc, "RIGHT", 10, 0)
                        hVersion:SetWidth(70)
                        hVersion:SetText("Version")

                        local hAction = header:CreateFontString(nil, "OVERLAY")
                        hAction:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                        hAction:SetPoint("LEFT", hVersion, "RIGHT", 25, 0)
                        hAction:SetText("Aktion")

                        --------------------------------------------------
                        -- Abstand bis zur ersten Aura
                        --------------------------------------------------

                        local yOffset = -95

                        --------------------------------------------------
                        -- Auren sammeln
                        --------------------------------------------------

                        local entries = {}

                        for _, aura in pairs(WeintCodex.WeakAuraData) do
                            if aura.category == category then
                                table.insert(entries, aura)
                                end
                                end

                                --------------------------------------------------
                                -- Sortieren
                                --------------------------------------------------

                                table.sort(entries, function(a, b)

                                if (a.sortOrder or 999) == (b.sortOrder or 999) then
                                    return a.name < b.name
                                    end

                                    return (a.sortOrder or 999) < (b.sortOrder or 999)

                                    end)

                                --------------------------------------------------
                                -- Zeilen erzeugen
                                --------------------------------------------------

                                for _, aura in ipairs(entries) do

                                    local row = CreateFrame("Frame", nil, container)
                                    row:SetSize(850, 40)
                                    row:SetPoint("TOPLEFT", 10, yOffset)
                    --------------------------------------------------
                    -- Hintergrund
                    --------------------------------------------------

                    local bg = row:CreateTexture(nil, "BACKGROUND")
                    bg:SetAllPoints()
                    bg:SetColorTexture(0.08, 0.08, 0.08, 0.20)

                    --------------------------------------------------
                    -- Icon
                    --------------------------------------------------

                    local icon = row:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(24, 24)
                    icon:SetPoint("LEFT", 5, 0)

                    if aura.icon then
                        icon:SetTexture(aura.icon)
                        end

                        --------------------------------------------------
                        -- Name
                        --------------------------------------------------

                        local name = row:CreateFontString(nil, "OVERLAY")
                        name:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                        name:SetPoint("LEFT", icon, "RIGHT", 12, 0)
                        name:SetWidth(140)
                        name:SetJustifyH("LEFT")
                        name:SetText(aura.name or "Unbekannt")

                        --------------------------------------------------
                        -- Beschreibung
                        --------------------------------------------------

                        local desc = row:CreateFontString(nil, "OVERLAY")
                        desc:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                        desc:SetPoint("LEFT", name, "RIGHT", 10, 0)
                        desc:SetWidth(380)
                        desc:SetJustifyH("LEFT")
                        desc:SetText(aura.description or "")

                        --------------------------------------------------
                        -- Version
                        --------------------------------------------------

                        local version = row:CreateFontString(nil, "OVERLAY")
                        version:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                        version:SetPoint("LEFT", desc, "RIGHT", 10, 0)
                        version:SetWidth(70)
                        version:SetText("v" .. (aura.version or "?"))

                        --------------------------------------------------
                        -- WeintCodex Installieren Button
                        --------------------------------------------------

                        local btn = CreateFrame("Button", nil, row)
                        btn:SetSize(130, 24)
                        btn:SetPoint("LEFT", version, "RIGHT", 15, 0)

                        -- Hintergrund
                        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
                        btnBg:SetAllPoints()
                        btnBg:SetColorTexture(
                            0.55,
                            0.25,
                            0.85,
                            0.08
                        )

                        -- Akzentstreifen links
                        local accent = btn:CreateTexture(nil, "ARTWORK")
                        accent:SetPoint("LEFT")
                        accent:SetSize(3, 24)
                        accent:SetColorTexture(
                            0.55,
                            0.25,
                            0.85,
                            0.5
                        )

                        -- Rahmen
                        local borderTop = btn:CreateTexture(nil, "BORDER")
                        borderTop:SetPoint("TOPLEFT")
                        borderTop:SetPoint("TOPRIGHT")
                        borderTop:SetHeight(1)
                        borderTop:SetColorTexture(0.55, 0.25, 0.85, 0.25)

                        local borderBottom = btn:CreateTexture(nil, "BORDER")
                        borderBottom:SetPoint("BOTTOMLEFT")
                        borderBottom:SetPoint("BOTTOMRIGHT")
                        borderBottom:SetHeight(1)
                        borderBottom:SetColorTexture(0.55, 0.25, 0.85, 0.25)

                        -- Text
                        local txt = btn:CreateFontString(nil, "OVERLAY")
                        txt:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                        txt:SetPoint("CENTER")
                        txt:SetText("Installieren")

                        --------------------------------------------------
                        -- Hover
                        --------------------------------------------------

                        btn:SetScript("OnEnter", function()

                        btnBg:SetColorTexture(
                            0.55,
                            0.25,
                            0.85,
                            0.20
                        )

                        accent:SetColorTexture(
                            0.55,
                            0.25,
                            0.85,
                            1
                        )

                        txt:SetTextColor(
                            1.0,
                            1.0,
                            1.0
                        )

                        end)

                        btn:SetScript("OnLeave", function()

                        btnBg:SetColorTexture(
                            0.55,
                            0.25,
                            0.85,
                            0.08
                        )

                        accent:SetColorTexture(
                            0.55,
                            0.25,
                            0.85,
                            0.5
                        )

                        txt:SetTextColor(
                            0.85,
                            0.82,
                            0.78
                        )

                        end)

                        --------------------------------------------------
                        -- Klick
                        --------------------------------------------------

                        btn:SetScript("OnClick", function()

                        if WeakAuras and WeakAuras.Import then
                            WeakAuras.Import(aura.string)
                            end

                            C_Timer.After(0.05, function()

                            if WeintCodex.MainFrame then
                                WeintCodex.MainFrame:Hide()
                                end

                                end)

                            end)

                        --------------------------------------------------

                        yOffset = yOffset - 45

                        end

                        --------------------------------------------------
                        -- Scrollhöhe anpassen
                        --------------------------------------------------

                        local height = math.abs(yOffset) + 40
                        container:SetHeight(height)

                        container:Show()

                        end

                        --------------------------------------------------
                        -- Hauptansicht
                        --------------------------------------------------

                        function WeintCodex.WeakAuras.Show()

                        local items = {
                            {
                                label = "Klassenauren",
                                onClick = function()
                                WeintCodex.WeakAuras.ShowCategory("class")
                                end
                            },

                            {
                                label = "Raidauren",
                                onClick = function()
                                WeintCodex.WeakAuras.ShowCategory("raid")
                                end
                            },

                            {
                                label = "Utility-Auren",
                                onClick = function()
                                WeintCodex.WeakAuras.ShowCategory("utility")
                                end
                            },
                        }

                        WeintCodex.Navigation.BuildSidebar(
                            "WeakAuras",
                            items
                        )

                        WeintCodex.WeakAuras.ShowCategory("class")

                        end
