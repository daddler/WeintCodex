WeintCodex = WeintCodex or {}
WeintCodex.Version = "2.7.3.1"

SLASH_WEINTCODEX1 = "/wc"
SLASH_WEINTCODEX2 = "/weintcodex"

SlashCmdList["WEINTCODEX"] = function(msg)
    local cmd = msg and msg:lower() or ""

    -- Erstes Wort plus Rest: die Befehle unten vergleichen weiterhin exakt,
    -- nur "access" braucht ein Argument (siehe core/access.lua).
    local verb, rest = cmd:match("^(%S+)%s*(.-)$")
    verb = verb or ""
    rest = rest or ""

    -- Zugriffsprofil anzeigen / Verknuepfung aufheben
    if verb == "access" or verb == "zugriff" then
        if not WeintCodex.Access then return end
        if rest == "reset" then
            WeintCodex.Access.Reset(false)
        elseif rest == "reset bestaetigen" or rest == "reset bestätigen" then
            WeintCodex.Access.Reset(true)
        else
            WeintCodex.Access.Print()
        end
        return
    end

    -- Gruppencheck sofort oeffnen: der Befehl ist der schnelle Weg
    -- mitten in der Aufstellung, wenn niemand erst durch die Navigation
    -- klicken will (siehe modules/groupcheck.lua).
    if verb == "gruppe" or verb == "gruppencheck" then
        if not (WeintCodex.MainFrame and WeintCodex.Navigation) then return end
        WeintCodex.MainFrame:Show()
        if WeintCodex.Navigation.GoToTab then
            WeintCodex.Navigation.GoToTab("gruppencheck")
        end
        if rest == "pruefen" or rest == "prüfen" then
            if WeintCodex.GroupCheck and WeintCodex.GroupCheck.Run then
                WeintCodex.GroupCheck.Run()
            end
        end
        return
    end

    -- Ausruestungs-Alarm (modules/gearalert.lua): die grosse Einblendung,
    -- wenn ein frisch angelegtes Teil unverzaubert oder unversockelt ist.
    --   /wc alarm            Zustand und Befehlsliste
    --   /wc alarm an|aus     ein-/ausschalten
    --   /wc alarm ton        Signalton umschalten
    --   /wc alarm erinnern   Erinnerungen umschalten (frueher "ruhe")
    --   /wc alarm erneut     alle Quittungen vergessen
    --   /wc alarm berufe     was je Berufsvorteil gelesen wurde
    --   /wc alarm bewegen    Meldung zum Verschieben stehen lassen
    --   /wc alarm jetzt      sofort pruefen
    if verb == "alarm" or verb == "alert" then
        if WeintCodex.GearAlert and WeintCodex.GearAlert.Command then
            WeintCodex.GearAlert.Command(rest)
        end
        return
    end

    if cmd == "import" then
        if WeintCodex.Sync and WeintCodex.Sync.ShowImportDialog then
            WeintCodex.Sync.ShowImportDialog()
        end
        return
    end

    -- Einstellungsseite (modules/settings.lua). Sie ist der Ort, an dem jeder
    -- der Befehle hier oben auch als Schaltflaeche steht - deshalb ist dieser
    -- eine Befehl der einzige, den man sich merken muesste.
    if verb == "einstellungen" or verb == "optionen" or verb == "settings"
       or verb == "config" then
        if not (WeintCodex.MainFrame and WeintCodex.Navigation) then return end
        WeintCodex.MainFrame:Show()
        if WeintCodex.Navigation.GoToTab then
            WeintCodex.Navigation.GoToTab("settings")
        end
        return
    end

    -- Verzauberungs-/Sockel-Dump zur Datenpflege (IDs + Client-Namen).
    --   /wc vz          kurze Fassung zum Melden
    --   /wc vz zeilen   jede Tooltipzeile mit Farbe und gelesenen Werten
    --                   (Diagnose, wenn eine Gegenstandszeile als
    --                    Verzauberung gelesen wird)
    if verb == "vz" or verb == "dump" then
        if not WeintCodex.Charakter then return end
        if (rest == "zeilen" or rest == "lines")
           and WeintCodex.Charakter.DumpEnchantLines then
            WeintCodex.Charakter.DumpEnchantLines()
        elseif WeintCodex.Charakter.DumpEnchants then
            WeintCodex.Charakter.DumpEnchants()
        end
        return
    end

    -- Kalender-Diagnose: was gibt der Client an Einladungsfunktionen her,
    -- welchen Realm vergleicht das Addon, und welcher Name wuerde je
    -- Spieler angefragt? Eigener Befehl aus demselben Grund wie
    -- /wc sockel: "24 von 25 nicht gefunden" sieht bei einer fehlenden
    -- Client-Funktion, einem falsch verglichenen Realm und einem
    -- wirklich falschen Charakternamen identisch aus.
    if verb == "kalender" or verb == "calendar" then
        if WeintCodex.Calendar and WeintCodex.Calendar.Dump then
            WeintCodex.Calendar.Dump()
        end
        return
    end

    -- Tempo-Diagnose: die Treppe der eigenen Spec, ihre Herleitung aus
    -- Laufzeit und Tickabstand, das gerechnete Ziel und der Spielraum,
    -- mit dem der Planer arbeitet. Eigener Befehl aus demselben Grund wie
    -- /wc sockel: "es wird ein Tempostein vorgeschlagen, obwohl ich am
    -- Cap bin" sieht bei einer falschen Laufzeit in der Datendatei, einem
    -- stummen Client und einem selbst gesetzten Ziel gleich aus.
    if cmd == "tempo" or cmd == "haste" or cmd == "schwellen" then
        if WeintCodex.Charakter and WeintCodex.Charakter.DumpBreakpoints then
            WeintCodex.Charakter.DumpBreakpoints()
        end
        return
    end

    -- Umschmieden (BETA, modules/reforge.lua). Der Planer ist ab Werk aus
    -- und muss eingeschaltet werden - er gibt Gold aus, und seine
    -- Vorschlaege sind noch nicht belastbar.
    --   /wc umschmieden          Seite oeffnen
    --   /wc umschmieden an|aus   Planer ein-/ausschalten
    --   /wc umschmieden fenster  Liste auch ohne Umschmieder zeigen
    --   /wc umschmieden pruefen  jede Zwischenzahl in den Chat
    if verb == "umschmieden" or verb == "reforge" or verb == "schmieden" then
        if WeintCodex.Reforge and WeintCodex.Reforge.Command then
            WeintCodex.Reforge.Command(rest)
        end
        return
    end

    -- Sockel-Diagnose: was wurde gelesen, und was hat der Planer daraus
    -- gerechnet? Bewusst ein eigener Befehl neben /wc vz - diese
    -- Fehlerklasse (falsche Sockelreihenfolge, Bonus-Zustand, Cap-Spielraum)
    -- war von aussen ueberhaupt nicht diagnostizierbar, weil keine Ausgabe
    -- die Sockelfolge oder ihre Quelle nannte.
    if cmd == "sockel" or cmd == "sockets" then
        if WeintCodex.Charakter and WeintCodex.Charakter.DumpSockets then
            WeintCodex.Charakter.DumpSockets()
        end
        return
    end

    -- Einkaufsliste: was an Steinen und Verzauberungen fehlt. Geht am
    -- Auktionshaus von selbst auf; der Befehl ist der Weg dahin, wenn man
    -- vorher wissen will, was man braucht.
    if cmd == "einkauf" or cmd == "einkaufsliste" or cmd == "shopping" then
        if WeintCodex.ShoppingList and WeintCodex.ShoppingList.Toggle then
            WeintCodex.ShoppingList.Toggle()
        end
        return
    end

    -- Die Frage "soll WeintCodex auf diesem Charakter von selbst mitreden?"
    -- noch einmal stellen (siehe core/optin.lua). Sie kommt sonst genau
    -- einmal je Charakter.
    if cmd == "hier" or cmd == "mitreden" then
        if WeintCodex.OptIn and WeintCodex.OptIn.Ask then
            WeintCodex.OptIn.Ask(true)
        end
        return
    end

    -- Addon-Tour manuell erneut aufrufen (z.B. zum Testen)
    if cmd == "tour" then
        if WeintCodex.Onboarding and WeintCodex.Onboarding.ShowTour then
            WeintCodex.Onboarding.ShowTour()
        end
        return
    end

    -- Rotationshelfer: Prioritaetenliste manuell oeffnen/schliessen
    -- (siehe modules/rotationtrainer.lua) - Fallback fuer Ziele, die nicht
    -- automatisch als Trainingspuppe erkannt werden.
    --   /wc training        oeffnen bzw. schliessen
    --   /wc training stop   schliessen
    --   /wc training check  Zauber-IDs der eigenen Spec pruefen
    --   /wc training id     NPC-ID des Ziels melden (fuer neue Puppen)
    if verb == "training" or verb == "trainer" then
        if not WeintCodex.RotationTrainer then return end
        if rest == "stop" then
            WeintCodex.RotationTrainer.StopManual()
        elseif rest == "check" or rest == "pruefen" or rest == "prüfen" then
            WeintCodex.RotationTrainer.PrintCheck()
        elseif rest == "id" or rest == "ziel" then
            WeintCodex.RotationTrainer.PrintTargetId()
        else
            WeintCodex.RotationTrainer.Toggle()
        end
        return
    end

    if WeintCodex.MainFrame:IsShown() then
        WeintCodex.MainFrame:Hide()
    else
        if WeintCodex.ResetToHome then
            WeintCodex.ResetToHome()
        end
        WeintCodex.MainFrame:Show()
    end
end

local function OnEvent(self, event, addonName)

    if event == "PLAYER_LOGIN" then

        -- Meldet den eingeloggten Charakter automatisch ans Companion,
        -- damit der Bot den echten WoW-Namen (statt Discord-Namen)
        -- fürs Kalender-Invite kennt - siehe modules/companion.lua.
        if WeintCodex.Companion and WeintCodex.Companion.ReportCharacter then
            WeintCodex.Companion.ReportCharacter()
        end

        -- Und getrennt davon: WER von diesen Charakteren gerade
        -- spielt. Die obige Meldung ist die ganze Twinkliste ohne
        -- Kennzeichnung - die Companion konnte daraus nie ablesen,
        -- wer angemeldet ist, und hat die Frage deshalb geraten.
        -- Genau daher stammte der fremde Charakter in Academy und
        -- WeintTV. Diese Nachricht bleibt auf dem Rechner des
        -- Spielers, siehe modules/companion.lua.
        if WeintCodex.Companion and WeintCodex.Companion.ReportLoggedInCharacter then
            WeintCodex.Companion.ReportLoggedInCharacter()
        end

        -- Und welche WeakAuras dieses Addon anbietet. Die Companion
        -- kann das nicht selbst sehen - die mitgelieferten Auren
        -- stecken als Lua-Tabellen im Addon-Ordner. Ohne diese
        -- Meldung koennte ihre WeakAuras-Seite nur die Auren
        -- auflisten, die sie selbst angelegt hat, und eine
        -- vorhandene liesse sich nicht aktualisieren. Laeuft nach
        -- ADDON_LOADED, die zugestellte Bibliothek ist also bereits
        -- eingearbeitet und wird mitgemeldet.
        if WeintCodex.Companion and WeintCodex.Companion.ReportWeakAuraCatalog then
            WeintCodex.Companion.ReportWeakAuraCatalog()
        end

        -- Bereits importierte Rosterdaten erneut auflösen - UnitClass/
        -- UnitName sind bei ADDON_LOADED (Zeitpunkt des ursprünglichen
        -- Imports über ProcessInbox) noch nicht zuverlässig verfügbar.
        if WeintCodex.Raids and WeintCodex.Raids.ResolveNames and WeintCodex.SavedData then
            WeintCodex.Raids.ResolveNames(WeintCodex.SavedData.raidWednesday)
            WeintCodex.Raids.ResolveNames(WeintCodex.SavedData.raidThursday)
        end

        -- Datenintegrität prüfen: warnt, falls Spec-Profile eine
        -- Verzauberungs-/Stein-ID referenzieren, die nicht (mehr) in
        -- enchants.lua / gems.lua existiert (Drift-Schutz).
        if WeintCodex_ValidateSpecData then
            WeintCodex_ValidateSpecData()
        end

        -- Und die Empfehlungslisten gegen die Gewichte desselben Profils:
        -- warnt, wenn eine Verzauberung fehlt, die dem Profil nach fast so
        -- viel bringt wie die empfohlene. Genau diese Luecke hat einen
        -- korrekt verzauberten Elementarschamanen als mangelhaft gemeldet
        -- (2.3.1.0) - die Liste war von Hand gepflegt und mit nichts
        -- abgeglichen.
        if WeintCodex_ValidateEnchantWeights then
            WeintCodex_ValidateEnchantWeights()
        end

        -- Und dasselbe fuer die Steine (2.5.0.0). Fuer Verzauberungen gibt
        -- es die Pruefung seit 2.3.1.0, fuer Steine gab es sie nicht - und
        -- genau die Luecken, die sie findet, sind es, an denen die
        -- Sockelseite ueber fuenf Releases falsch bewertet hat: eine
        -- Farbliste, die am Cap nichts mehr hergibt, eine Steinfarbe, die
        -- aus den Werten nicht folgen kann, und ein Profil, dessen Gewichte
        -- seiner eigenen ersten Empfehlung widersprechen.
        if WeintCodex_ValidateGemWeights then
            WeintCodex_ValidateGemWeights()
        end

        -- Und die Tempo-Schwellen (2.6.2.0): warnt, wenn Laufzeit und
        -- Tickabstand eines Effekts keine ganze Grundtickzahl ergeben -
        -- dann stimmt eine der beiden Zahlen nicht, und aus ihr faellt
        -- eine ganze Treppe. Die Zahlen selbst kann die Pruefung nicht
        -- belegen; dafuer steht `verify` am Eintrag und /wc tempo druckt
        -- je Stufe ihre Herleitung aus.
        if WeintCodex_ValidateBreakpointData then
            WeintCodex_ValidateBreakpointData()
        end

        -- Dasselbe für die BiS-Listen: warnt, falls ein Eintrag einen
        -- Boss- oder Slot-Namen nutzt, den es nicht gibt (Tippfehler
        -- würden das Item sonst still nirgends anzeigen).
        -- Und die Paartabelle des Umschmiedens (2.7.0.0): sie wird aus
        -- der Statreihenfolge erzeugt, kann also keinen Zahlendreher
        -- enthalten - was die Pruefung meldet, waere ein Fehler in der
        -- Erzeugung selbst. Sie laeuft trotzdem, weil an dieser Tabelle
        -- die laufende Nummer haengt, die der Umschmieder bekommt: liegt
        -- sie daneben, wird etwas anderes geschmiedet als angezeigt, und
        -- das faellt erst auf, wenn das Gold weg ist.
        -- Heisst dieser Client die Itemwerte so, wie wir sie lesen? Sechs
        -- der acht umschmiedbaren Werte fielen bis 2.7.1.0 lautlos aus
        -- jeder Antwort des Clients heraus, und zu sehen war davon nichts
        -- ausser falschen Umschmiede-Auftraegen.
        if WeintCodex.StatMatch and WeintCodex.StatMatch.ValidateStatKeys then
            WeintCodex.StatMatch.ValidateStatKeys()
        end
        if WeintCodex_ValidateReforgeData then
            WeintCodex_ValidateReforgeData()
        end

        if WeintCodex_ValidateBiSData then
            WeintCodex_ValidateBiSData()
        end

        -- Dasselbe fuer die Prioritaetenlisten des Rotationshelfers:
        -- warnt, falls ein Eintrag eine Spec referenziert, die es nicht
        -- (mehr) gibt, oder keine Filler-Regel besitzt. Die eigene Spec
        -- wird mitgegeben, damit zusaetzlich deren Zauber-IDs gegen den
        -- Client geprueft werden koennen (siehe data/rotations.lua).
        if WeintCodex_ValidateRotationData then
            local specKey
            if WeintCodex.Charakter and WeintCodex.Charakter.GetProfileKey then
                specKey = WeintCodex.Charakter.GetProfileKey()
            end
            WeintCodex_ValidateRotationData(specKey)
        end

        -- Erststart-Tour bzw. Update-Changelog-Popup (core/onboarding.lua):
        -- zeigt neuen Nutzern eine kurze Feature-Tour, bestehenden Nutzern
        -- nach einem Versionswechsel, was sich geaendert hat.
        if WeintCodex.Onboarding and WeintCodex.Onboarding.Check then
            WeintCodex.Onboarding.Check()
        end

        return
    end

    if addonName ~= "WeintCodex" then return end

        if not WeintCodex_SavedData then
            WeintCodex_SavedData = {
                bossData          = {},
                raidData          = {},
                materialData      = {},
                twinks            = {},
                encounterProgress = {},

                window = {
                    scale  = 1.0,
                    width  = 1500,
                    height = 800,
                },

                minimap = {
                    angle = 225,
                    hide = false,
                },
            }
        end

        WeintCodex_SavedData.window =
            WeintCodex_SavedData.window or { scale = 1.0, width = 1500, height = 800 }
        WeintCodex_SavedData.window.width  = WeintCodex_SavedData.window.width  or 1500
        WeintCodex_SavedData.window.height = WeintCodex_SavedData.window.height or 800

        -- Fensterverhalten (2.6.0.0). Bis dahin lag das Hauptfenster fest auf
        -- FULLSCREEN_DIALOG und stand damit ueber Taschen, Charakterbogen und
        -- den Dialogen des Clients, und ESC schloss es nicht. Vorgabe ist
        -- jetzt: ESC schliesst, und das Fenster draengt sich nicht vor.
        -- Ausdruecklich `== nil` und nicht `or`, sonst liesse sich escClose
        -- nie abschalten.
        if WeintCodex_SavedData.window.escClose == nil then
            WeintCodex_SavedData.window.escClose = true
        end
        if WeintCodex_SavedData.window.topmost == nil then
            WeintCodex_SavedData.window.topmost = false
        end

        -- Migration auf das Redesign (Icon-Rail + Inspector-Spalte benötigen
        -- mehr Breite): alte, kleinere gespeicherte Fenstergrößen einmalig anheben.
        if WeintCodex_SavedData.window.width < 1180 then
            WeintCodex_SavedData.window.width = 1500
        end
        if WeintCodex_SavedData.window.height < 780 then
            WeintCodex_SavedData.window.height = 800
        end

        WeintCodex_SavedData.twinks            = WeintCodex_SavedData.twinks or {}
        WeintCodex_SavedData.encounterProgress = WeintCodex_SavedData.encounterProgress or {}
        WeintCodex_SavedData.minimap =
        WeintCodex_SavedData.minimap or {
            angle = 225,
            hide = false,
        }

    WeintCodex.SavedData = WeintCodex_SavedData

    -- Zugriffsprofil bereitstellen, BEVOR die Inbox verarbeitet wird: die
    -- Herkunftsprüfung der Nachrichten hängt daran (siehe core/access.lua).
    if WeintCodex.Access and WeintCodex.Access.Init then
        WeintCodex.Access.Init()
    end

    -- Companion-Inbox verarbeiten (z. B. automatisch abgerufener
    -- Raid-Roster-Export von einem per Discord-Login verknüpften Raidlead)
    if WeintCodex.Companion and WeintCodex.Companion.ProcessInbox then
        WeintCodex.Companion.ProcessInbox()
    end

    -- Sperren aus dem Zugriffsprofil anwenden. Muss nach ProcessInbox laufen
    -- (das Profil kann in genau diesem Login angekommen sein) und vor
    -- ResetToHome, damit das Dashboard nicht einmal mit Zahlen aufblitzt.
    if WeintCodex.Access and WeintCodex.Access.Apply then
        WeintCodex.Access.Apply()
    end

    -- Restore saved window size
    if WeintCodex.ApplySavedWindow then
        WeintCodex.ApplySavedWindow()
    end

    -- ESC-Verhalten und Fensterebene aus denselben SavedData (core/ui.lua).
    if WeintCodex.ApplyWindowBehaviour then
        WeintCodex.ApplyWindowBehaviour()
    end

    if WeintCodex.ResetToHome then
        WeintCodex.ResetToHome()
    end

    print("|cffD4A24A[WeintCodex]|r |cff22C55Ev" .. WeintCodex.Version
        .. "|r geladen. |cffaaaaaa/wc zum Öffnen, /wc einstellungen für die Optionen.|r")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", OnEvent)
