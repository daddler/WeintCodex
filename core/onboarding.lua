--------------------------------------------------
-- WeintCodex :: Onboarding & Update-Changelog
-- Zeigt neuen Nutzern eine kurze Feature-Tour beim ersten Login und
-- informiert bestehende Nutzer nach einem Update per Popup ueber die
-- Aenderungen (data/changelog.lua). Beide Modi teilen sich dasselbe
-- Fenster - siehe EnsureFrame().
--------------------------------------------------

WeintCodex = WeintCodex or {}
WeintCodex.Onboarding = {}

local C          = WeintCodex.C
local SetSolidBg = WeintCodex.SetSolidBg
local DrawBorder = WeintCodex.DrawBorder

--------------------------------------------------
-- Fenstermasse
--
-- WINDOW_H ist die Grundhoehe (sie traegt jede Tourseite), WINDOW_H_MAX
-- die Grenze, ab der stattdessen gescrollt wird. Die Grenze liegt unter
-- der kleinsten zulaessigen Hoehe des Hauptfensters (780, siehe
-- core/ui.lua), damit das Popup auch dort vollstaendig darin liegt.
--
-- Warum ueberhaupt beides: der Changelog eines Updates ist beliebig lang.
-- Bisher war der Text ein fester FontString auf dem Fenster - was nicht
-- hineinpasste, wurde nicht abgeschnitten, sondern lief unten heraus und
-- war unerreichbar. Sichtbar wurde das erst bei einem Sammelupdate ueber
-- mehrere Versionen, also genau dann, wenn es am meisten zu lesen gibt.
--------------------------------------------------

local WINDOW_W, WINDOW_H = 520, 380
local WINDOW_H_MAX = 620

-- Der Textbereich sitzt zwischen Trennlinie (BODY_TOP unter der
-- Fensterkante) und Knopfzeile (BODY_BOTTOM ueber der Unterkante).
local BODY_TOP, BODY_BOTTOM, BODY_X = 130, 64, 28

local overlay, window
local iconStr, titleStr, stepStr, bodyStr
local bodyScroll, bodyInner
local buttonRow = {}
local currentStep = 1

--------------------------------------------------
-- DIE TOUR
--
-- Sie ist mit 3.0.0.0 vollstaendig neu geschrieben, und zwar aus einem
-- Grund, der nichts mit Geschmack zu tun hat: zwischen 1.0 und 2.10 sind
-- die Ausruestungsberatung (Verzauberungen, Sockel, Caps, Tempo-Schwellen,
-- Umschmieden, Priorisierung, Simmen), der Gruppencheck, der
-- Ausruestungs-Alarm, der Rotationshelfer, die Einkaufsliste und die
-- Einstellungsseite dazugekommen - und die Tour sprach von keinem davon.
-- Wer sie gesehen hat, kannte danach ein Addon, das es so nicht mehr gibt.
--
-- Drei Regeln fuer jeden Text hier, und sie sind dieselben, nach denen
-- auch die Patchnotes geschrieben werden (siehe CLAUDE.md):
--
--   * Kein Dateiname, kein Funktionsname, kein SavedVariables-Schluessel.
--     Seitennamen und Slash-Befehle sind ausdruecklich erlaubt - sie sind
--     Bedienung, nicht Innenleben.
--   * Wirkung vor Ursache. Was bringt mir das, was sehe ich, was muss ich
--     tun. Warum es so gerechnet wird, steht auf der Seite selbst.
--   * Hervorgehoben (Bernstein) wird nur, worauf man klicken oder was man
--     tippen kann. Eine Farbe, die auch Fliesstext trifft, sagt nichts mehr.
--
-- `chapter` gruppiert die Seiten; die Kopfzeile nennt Kapitel und Schritt.
-- `feature` laesst eine Seite aus, wenn das Zugriffsprofil den Bereich
-- nicht freigibt (siehe core/access.lua) - sonst bewirbt die Tour Bereiche,
-- die der Spieler gar nicht oeffnen kann.
--------------------------------------------------

-- Fassung der Tour. Wird sie neu geschrieben, steigt diese Zahl - und
-- alle bekommen die Einfuehrung noch einmal, auch wer das Addon seit
-- Jahren benutzt. Siehe Check() ganz unten.
local TOUR_EDITION = 3

-- ZWEI HERVORHEBUNGEN, ZWEI BEDEUTUNGEN.
--
-- A() ist Bernstein und heisst ausschliesslich: das kann man anklicken
-- oder tippen (Seiten, Reiter, Knoepfe, Slash-Befehle). E() ist Weiss und
-- betont einen Satz. Beides in einer Farbe zu fuehren waere das Ende
-- dieser Auskunft - eine Farbe, die auch Fliesstext trifft, sagt nichts
-- mehr darueber, worauf man zeigen kann.
local function A(text)
    return WeintCodex.ColorText("gold", text)
end

local function E(text)
    return WeintCodex.ColorText("textBright", text)
end

local ICON = "Interface\\Icons\\"

local TOUR_STEPS = {

    --------------------------------------------------
    -- ERSTE SCHRITTE
    --------------------------------------------------

    { chapter = "Erste Schritte", icon = ICON .. "INV_Misc_Book_09",
      title = "Willkommen bei WeintCodex 3",
      body =
        "WeintCodex ist das Addon der Gilde: Bossguides, Raidplanung, "
        .. "Ausrüstungsberatung, Materialien und WeakAuras an einem Ort.\n\n"
        .. "Diese Einführung dauert ein paar Minuten und geht einmal durch "
        .. "alles, was drinsteckt. Du kannst sie jederzeit abbrechen und "
        .. "später mit " .. A("/wc tour") .. " erneut aufrufen — es geht "
        .. "dabei nichts verloren.\n\n"
        .. "Das Fenster öffnest und schließt du mit " .. A("/wc") .. " oder "
        .. A("/weintcodex") .. ", oder mit einem Klick auf das Symbol an "
        .. "deiner Minikarte.\n\n"
        .. "Ein Hinweis vorweg: WeintCodex bewertet Ausrüstung, aber es "
        .. "entscheidet nichts für dich. Jede Empfehlung sagt an ihrer "
        .. "Zeile, warum sie dasteht — und du kannst jede davon überstimmen." },

    { chapter = "Erste Schritte", icon = ICON .. "INV_Misc_Map_01",
      title = "So ist das Fenster aufgebaut",
      body =
        "Links steht die Navigationsspalte, in vier Gruppen: " .. A("Raid")
        .. " (Übersicht, Bossguides, Raids, Gruppencheck, Kalender, "
        .. "WeintTV), " .. A("Charakter") .. " (Charakter, Academy), "
        .. A("Gilde") .. " (Materialien, WeakAuras, Import) und "
        .. A("System") .. " (Einstellungen).\n\n"
        .. "In der Mitte steht die Seite. Rechts erscheint ein schmales "
        .. "Feld, sobald es zur Seite etwas zu sagen gibt: die Begründung "
        .. "zu dem, was links steht — welche Gewichte gelten, welche "
        .. "Grenzen, was gerade entschieden wird. Wenn eine Empfehlung dich "
        .. "wundert, steht die Antwort meistens dort.\n\n"
        .. "Manche Bereiche haben oben noch eine eigene Reiterleiste. Die "
        .. "Seite " .. A("Charakter") .. " zum Beispiel ist in Übersicht, "
        .. "Verzauberungen, Sockel, Werteverteilung, Priorisierung, Simmen "
        .. "und Twinks unterteilt.\n\n"
        .. "Oben in der Titelleiste sitzt die Suche — mit "
        .. A("Strg+K") .. " auch ohne Mausklick. Sie findet Bosse, "
        .. "Gegenstände und Seiten quer durch alle Bereiche." },

    { chapter = "Erste Schritte", icon = ICON .. "INV_Misc_Gear_01",
      title = "Companion und Discord-Bot",
      body =
        "WeintCodex arbeitet mit zwei Programmen zusammen, und man merkt "
        .. "es an mehreren Stellen — deshalb hier einmal, wer was macht.\n\n"
        .. E("WeintCompanion") .. " ist die Anwendung auf deinem Rechner. "
        .. "Sie installiert und aktualisiert dieses Addon, hält deine "
        .. "Spielstände im Backup und bringt die Auswertung deiner Raids "
        .. "(WeintTV, Academy) ins Spiel.\n\n"
        .. "Der " .. E("Discord-Bot") .. " kennt die Raidanmeldung, den "
        .. "Kalender und die Materialien der Gildenbank. Was er schickt, "
        .. "kommt über die Companion hier an.\n\n"
        .. "Wichtig zu wissen: Zugestelltes wird nur beim Anmelden und nach "
        .. A("/reload") .. " gelesen. WoW liest seine gespeicherten Daten "
        .. "während des Spiels nicht erneut. Wenn am Schreibtisch etwas "
        .. "Neues ankommt, siehst du es also nach dem nächsten Neuladen — "
        .. "das ist kein Fehler, sondern die einzige Stelle, an der das "
        .. "Spiel überhaupt nachsieht.\n\n"
        .. "Ohne Companion und ohne Bot funktioniert alles, was deinen "
        .. "eigenen Charakter betrifft, unverändert." },

    --------------------------------------------------
    -- DEINE AUSRUESTUNG
    --------------------------------------------------

    { chapter = "Deine Ausrüstung", icon = ICON .. "Achievement_Character_Human_Male",
      title = "Charakter — dein Ausgangspunkt",
      body =
        "Der größte Teil von WeintCodex dreht sich um eine einzige Frage: "
        .. "sitzt auf deiner Ausrüstung das Richtige?\n\n"
        .. "Die " .. A("Übersicht") .. " beantwortet sie zusammengefasst — "
        .. "wie viele Verzauberungen fehlen, wie viele Sockel leer sind, "
        .. "wie viel davon optimal ist. Ein Klick auf eine Zeile bringt "
        .. "dich zur Einzelaufstellung.\n\n"
        .. "Gelesen wird dafür deine angelegte Ausrüstung, Teil für Teil, "
        .. "mit dem Tooltip des Spiels. Was der Client gerade noch nicht "
        .. "geladen hat, wird nicht bewertet, sondern nachgereicht — eine "
        .. "Zeile, die \"noch keine Daten\" sagt, ist keine Beanstandung.\n\n"
        .. "Unter " .. A("Twinks") .. " verwaltest du deine übrigen "
        .. "Charaktere. Diese Liste geht an den Discord-Bot, damit er beim "
        .. "Kalender-Invite deinen echten Charakternamen kennt und nicht "
        .. "nur deinen Discord-Namen.\n\n"
        .. "Auf einem Zweitcharakter, auf dem du keine Ratschläge willst, "
        .. "fragt WeintCodex einmal nach und hält sich danach heraus. Sagst "
        .. "du dort Nein, bleibt alles erhalten — es meldet sich nur nicht "
        .. "mehr von selbst. Die Frage holst du mit " .. A("/wc hilfe")
        .. " zurück, und derselbe Schalter steht unter "
        .. A("Einstellungen → Fenster & Ansicht") .. "." },

    { chapter = "Deine Ausrüstung", icon = ICON .. "Trade_Engraving",
      title = "Verzauberungen",
      body =
        "Jeder Ausrüstungsplatz bekommt ein Urteil: " .. E("Optimal")
        .. ", " .. E("OK") .. ", " .. E("Falsch") .. ", " .. E("Über Cap")
        .. " oder " .. E("Fehlt") .. ". Daneben steht, was stattdessen "
        .. "daraufgehört.\n\n"
        .. "Entschieden wird nicht nur über den Namen. WeintCodex "
        .. "vergleicht auch die Werte, die deine Verzauberung tatsächlich "
        .. "gibt, mit denen der empfohlenen. Deshalb liest du manchmal "
        .. "\"werte-identisch\" oder \"stärkere Stufe\": es ist eine andere "
        .. "Verzauberung, sie leistet aber dasselbe oder mehr. Das ist "
        .. "Absicht — für eine Berufsvariante \"nicht ideal\" zu sagen wäre "
        .. "schlicht falsch.\n\n"
        .. "Ringe zählen nur mit, wenn du selbst Verzauberkunst gelernt "
        .. "hast. Alles andere kann jeder tragen.\n\n"
        .. "Steht an einer Zeile etwas, das du für falsch hältst, hilft "
        .. A("/wc vz") .. " weiter: der Befehl schreibt in den Chat, welche "
        .. "Verzauberung erkannt wurde und mit welchen Werten. Genau das ist "
        .. "die Auskunft, aus der sich ein Fehler beheben lässt." },

    { chapter = "Deine Ausrüstung", icon = ICON .. "INV_Misc_Gem_Bloodstone_01",
      title = "Sockel & Steine",
      body =
        "Diese Seite sagt dir für jeden Sockel, welcher Stein hineingehört "
        .. "und was von dem drinsitzt zu halten ist. Berücksichtigt werden "
        .. "die Farbe des Sockels, ob sich der Sockelbonus lohnt, deine "
        .. "Gewichtung, deine Grenzen (Trefferkap, Waffenkunde, "
        .. "Tempo-Schwellen) und dein Beruf.\n\n"
        .. "Jede Zeile trägt ihre Begründung: welcher Wert hier führt, "
        .. "warum ein anderer nicht zählt, ob der Sockelbonus mitgenommen "
        .. "wird. Wenn dir eine Empfehlung merkwürdig vorkommt, lies zuerst "
        .. "dort und dann im Feld rechts — dort steht, welche Gewichte und "
        .. "Grenzen gerade gelten.\n\n"
        .. "Eine Reihenfolge ist wichtig: " .. E("erst umschmieden, dann "
        .. "sockeln, dann verzaubern") .. ". Ein Sockel lässt sich einmal "
        .. "vergeben, Umschmieden kannst du jederzeit zurücknehmen. Wer "
        .. "einen Sockel benutzt, um eine Lücke zu füllen, die das "
        .. "Umschmieden ohnehin schließt, verschenkt ihn.\n\n"
        .. E("Und ganz offen: hier ist noch nicht alles perfekt.") .. " Die Steinempfehlung ist "
        .. "der Teil des Addons, an dem am häufigsten etwas daneben liegt — "
        .. "mal ein Gewicht, mal eine Steinliste, mal ein Sonderfall. "
        .. "Wenn dir etwas seltsam vorkommt: " .. E("sag es im Discord")
        .. ". Schreib dazu, welche Spezialisierung du spielst, welcher "
        .. "Stein vorgeschlagen wurde und welchen du erwartet hättest, und "
        .. "häng die Ausgabe von " .. A("/wc sockel") .. " an. Damit lässt "
        .. "sich fast jeder dieser Fälle nachvollziehen — ohne Meldung "
        .. "bleibt er stehen." },

    { chapter = "Deine Ausrüstung", icon = ICON .. "INV_Misc_PocketWatch_02",
      title = "Werteverteilung & Caps",
      body =
        "Hier siehst du, wo deine Wertung liegt und wo Grenzen erreicht "
        .. "sind.\n\n"
        .. "Trefferwertung und Waffenkunde sind " .. E("Decken") .. ": "
        .. "darüber ist jeder weitere Punkt wertlos. Steht bei dir etwas "
        .. "darüber, nennt die Seite die Menge und wohin damit.\n\n"
        .. "Tempo ist keine Decke, sondern eine " .. E("Treppe") .. ". Jede "
        .. "Stufe bringt deinen Effekten einen zusätzlichen Tick; dazwischen "
        .. "bringt Tempo fast nichts. WeintCodex rechnet die Stufen aus "
        .. "Laufzeit und Tickabstand aus und prüft, welche du überhaupt "
        .. "erreichen kannst.\n\n"
        .. "Jede Stufe hat einen Knopf " .. A("als Ziel") .. ", dazu gibt es "
        .. A("Automatisch") .. " und " .. A("Schwellen aus") .. ". Wenn du "
        .. "eine Stufe über einen Schmuckproc erreichst, weißt du an dieser "
        .. "Stelle mehr als die Rechnung — dann setz das Ziel selbst.\n\n"
        .. "Nicht jede Spezialisierung hat eine Tempo-Treppe. Fehlt sie, "
        .. "sagt das Addon nichts dazu, statt sich etwas auszudenken. "
        .. A("/wc tempo") .. " zeigt jede Zwischenzahl der Rechnung." },

    { chapter = "Deine Ausrüstung", icon = ICON .. "Ability_Repair",
      title = "Umschmieden (Beta)",
      body =
        "Der Umschmiede-Planer beantwortet die Frage, welcher Wert auf "
        .. "welchem Teil verschoben gehört. Er ist " .. E("ab Werk aus")
        .. " und wird unter " .. A("Einstellungen → Umschmieden")
        .. " eingeschaltet — er gibt Gold aus, und er ist noch Beta.\n\n"
        .. "Danach steht " .. A("Charakter → Umschmieden") .. " in der "
        .. "Reiterleiste, und beim Umschmieder geht das Fenster von selbst "
        .. "auf. " .. A("Alles umschmieden") .. " arbeitet die ganze Liste "
        .. "ab, ein Teil nach dem anderen.\n\n"
        .. "Im Fenster gibt es zwei Ansichten. " .. A("Plan") .. " zeigt, "
        .. "was der Planer ändern will. " .. A("Alle Teile") .. " zeigt "
        .. "jedes Teil mit seinem Iststand — klick eines an, und du "
        .. "bestimmst selbst, welcher Wert wohin verschoben wird. Was du "
        .. "gesetzt hast, lässt der Planer in Ruhe.\n\n"
        .. "Oben rechts im selben Fenster steht das Feld " .. A("Wunschwert")
        .. ". Damit rückst du einen Wert an die erste Stelle deiner "
        .. "Gewichtung. Es gilt auch für Steine und Verzauberungen — es ist "
        .. "dieselbe Gewichtung, und zwei davon nebeneinander würden sich "
        .. "irgendwann widersprechen. Pflichtgrenzen wie das Trefferkap "
        .. "gehen weiterhin vor.\n\n"
        .. "Ein Klick auf eine Zeile der Seite " .. E("sperrt") .. " ein "
        .. "Teil, wenn es aus einem Grund so bleiben soll, den die Rechnung "
        .. "nicht kennt. " .. A("/wc umschmieden frei") .. " nimmt alle "
        .. "Sperren und Handauswahlen wieder zurück.\n\n"
        .. "Ob du es einschaltest, ist eine echte Abwägung: eingeschaltet "
        .. "bekommst du einen fertigen Plan und einen Knopf, der ihn "
        .. "ausführt. Ausgeschaltet bleibt alles beim Alten — kein Reiter, "
        .. "kein Fenster, keine Kosten. Umschalten kannst du es jederzeit "
        .. "unter " .. A("Einstellungen → Umschmieden") .. "; dabei geht "
        .. "nichts verloren." },

    { chapter = "Deine Ausrüstung", icon = ICON .. "INV_Misc_Book_11",
      title = "Priorisierung — deine Gewichtung",
      body =
        "Drei Seiten rechnen mit denselben Gewichten: Sockel, "
        .. "Verzauberungen und Umschmieden. Auf " .. A("Priorisierung")
        .. " siehst du, welche das sind, und kannst sie ändern.\n\n"
        .. "Ab Werk kommen sie aus dem Profil deiner Spezialisierung. "
        .. "Darüber liegt deine eigene Gewichtung, und ganz oben der "
        .. "Wunschwert. Was gerade gilt, sagt das Feld rechts.\n\n"
        .. "Die Zahlen sind Werte " .. E("je Punkt") .. ", keine "
        .. "Rangplätze. Ein Sockel gibt entweder 160 Primär- oder 320 "
        .. "Sekundärwertung — ein Sekundärwert oberhalb der Hälfte deines "
        .. "Primärwerts kippt damit jede Steinempfehlung. Wenn du also von "
        .. "Hand änderst, ändere in kleinen Schritten und schau dir "
        .. "danach die Sockelseite an.\n\n"
        .. "Hier landet auch, was ein Sim ausrechnet — siehe nächste Seite." },

    { chapter = "Deine Ausrüstung", icon = ICON .. "INV_Misc_Book_07",
      title = "Simmen",
      body =
        "WeintCodex simmt nicht selbst, und das ist eine Entscheidung: ein "
        .. "Sim, der nur so aussieht, wäre schlimmer als keiner. Was ein "
        .. "Sim liefert und was hier gebraucht wird, sind die "
        .. "Wertegewichte.\n\n"
        .. "Für Schadensausteiler ist die Adresse " .. A("wowsims.com/mop")
        .. ". Auf " .. A("Charakter → Simmen") .. " stellst du dafür deine "
        .. "Ausrüstung bereit: ein Knopf, ein Neuladen, und die Companion "
        .. "öffnet den Sim mit deinen Teilen. Was dort herauskommt, kommt "
        .. "als Vorschlag zurück und wird erst auf deinen Klick wirksam.\n\n"
        .. "Für Heiler ist es " .. A("questionablyepic.com/live") .. " (QE "
        .. "Live). Dieselbe Seite zeigt dann ein Kopierfeld statt des "
        .. "Bereitstellen-Knopfs — QE Live nimmt die Ausrüstung über die "
        .. "Zwischenablage entgegen und gibt keine Gewichtung je Charakter "
        .. "heraus. Auch das steht auf der Seite, damit du nicht auf eine "
        .. "Antwort wartest, die dort nicht kommt.\n\n"
        .. A("/wc simmen") .. " und " .. A("/wc qe") .. " führen direkt "
        .. "dorthin." },

    { chapter = "Deine Ausrüstung", icon = ICON .. "INV_Misc_EngGizmos_37",
      title = "Wenn etwas fehlt",
      body =
        "Zwei Dinge melden sich von selbst, damit eine Lücke nicht bis zum "
        .. "Pull stehen bleibt.\n\n"
        .. "Der " .. A("Ausrüstungs-Alarm") .. " ist die große Einblendung "
        .. "in der Bildschirmmitte: sie kommt, wenn du ein Teil anlegst, "
        .. "das weder verzaubert noch versockelt ist, und noch einmal, wenn "
        .. "du einen Ruhebereich betrittst — dort steht der Verzauberer, "
        .. "dort ist die Bank. Sie bleibt stehen, bis du sie wegklickst; "
        .. "danach ist fünf Minuten Ruhe.\n\n"
        .. "Gemeldet wird nur, was " .. E("fehlt") .. " — nie, was besser "
        .. "ginge. Ein leerer Sockel ist unstrittig, \"nicht ideal\" wäre "
        .. "eine Meinung, und eine bildschirmfüllende Meinung schaltet man "
        .. "nach dem dritten Mal ab. Berufsvorteile zählen mit: der Gürtel "
        .. "des Ingenieurs, die Zusatzsockel des Schmieds, die "
        .. "Schlangenaugen des Juweliers.\n\n"
        .. "Die " .. A("Einkaufsliste") .. " geht am Auktionshaus von "
        .. "selbst auf und fasst zusammen, welche Steine und "
        .. "Verzauberungen du brauchst. Ein Klick auf eine Zeile sucht sie "
        .. "im Auktionshaus.\n\n"
        .. "Beides lässt sich abschalten, und beides ist eine Abwägung: "
        .. "ohne Alarm merkst du eine Lücke erst, wenn du selbst auf die "
        .. "Charakterseite schaust; ohne Einkaufsliste musst du dir vor "
        .. "dem Auktionshaus selbst merken, was fehlt. Die Schalter stehen "
        .. "unter " .. A("Einstellungen") .. " und lassen sich jederzeit "
        .. "wieder umlegen.\n\n"
        .. A("/wc alarm") .. " zeigt alle Schalter des Alarms, "
        .. A("/wc einkauf") .. " öffnet die Liste auch fernab des "
        .. "Auktionshauses." },

    --------------------------------------------------
    -- IM RAID
    --------------------------------------------------

    { chapter = "Im Raid", icon = ICON .. "Achievement_Boss_LichKing",
      title = "Bossguides",
      body =
        "Zu jedem Boss die Taktik, nach Rolle getrennt: was dich als Tank, "
        .. "Heiler oder Schadensausteiler betrifft, steht jeweils für sich. "
        .. "Dazu Positionierungsbilder und der Fortschrittsbalken deines "
        .. "Charakters — er zählt je Charakter, nicht kontoweit, denn der "
        .. "Lockout hängt am einzelnen Charakter.\n\n"
        .. "Rechts steht die " .. E("Best-in-Slot-Liste") .. " für deine "
        .. "Spezialisierung: was bei diesem Boss für dich fällt, und ob du "
        .. "es schon trägst.\n\n"
        .. "Unter den Tipps liegt ein freies Notizfeld je Boss. Es hat zwei "
        .. "Ansichten — einspaltig für längeren Text, zweispaltig für den "
        .. "schnellen Überblick. Umgeschaltet wird oben im Feld.\n\n"
        .. "Die Taktiken selbst kommen vom Discord-Bot und lassen sich über "
        .. A("Import") .. " nachziehen." },

    { chapter = "Im Raid", icon = ICON .. "Ability_Warrior_BattleShout",
      title = "Raids & Kalender",
      feature = "raids.view",
      body =
        "Unter " .. A("Raids") .. " steht die Anmeldung für Mittwoch und "
        .. "Donnerstag, so wie sie in Discord aussieht: wer zugesagt hat, "
        .. "wer auf der Ersatzbank sitzt, wer vielleicht kommt.\n\n"
        .. "Zwei Dinge, die man dort sehen muss: Eine Zeile ohne "
        .. "Charakternamen steht gedämpft mit einem Fragezeichen da — der "
        .. "Bot kennt von diesem Spieler nur den Discord-Namen, und den "
        .. "gibt es im Spiel nicht. Solche Zeilen lassen sich nicht "
        .. "einladen. Über das Stift-Symbol trägst du den richtigen Namen "
        .. "von Hand nach.\n\n"
        .. "Hat die Raidleitung eine Aufstellung angekündigt, zählt die — "
        .. "sonst zählen die Zusagen. Wer nicht mitgeht, verschwindet "
        .. "nicht, sondern steht gedämpft mit seinem Grund da.\n\n"
        .. "Der " .. A("Kalender") .. " macht daraus die Ingame-Einladung. "
        .. "Die Vorschau nennt vorher, wie viele Einladungen tatsächlich "
        .. "rausgehen, und der Lauf sagt hinterher, wen er übersprungen hat "
        .. "und warum. " .. A("/wc kalender") .. " zeigt die Diagnose dazu, "
        .. "falls Namen nicht ankommen." },

    { chapter = "Im Raid", icon = ICON .. "INV_Misc_GroupLooking",
      title = "Gruppencheck",
      body =
        "Verzauberungen und Sockel der ganzen Gruppe oder des ganzen "
        .. "Raids auf einer Seite. Die zwei Fragen, die vor dem Pull "
        .. "zählen, ohne sie 24-mal einzeln zu stellen.\n\n"
        .. "Die Seite " .. E("zählt") .. ", sie bewertet nicht. \"Sockel "
        .. "leer\" ist unstrittig, \"falscher Stein\" wäre ein Vorwurf — "
        .. "und für einen fremden Spieler meldet der Client weder die "
        .. "Spezialisierung verlässlich noch genug, um darüber zu "
        .. "urteilen. In der Kopfzeile steht deshalb " .. E("fehlt/leer")
        .. " und nicht \"optimal\".\n\n"
        .. "Wer zu weit weg, offline oder in einer anderen Phase ist, "
        .. "bleibt leer und zählt " .. E("nicht") .. " als geprüft. Eine "
        .. "Übersicht, die Ungeprüftes als geprüft zählt, ist schlimmer als "
        .. "gar keine.\n\n"
        .. "Ringe zählen nicht mit: die darf nur verzaubern, wer den Beruf "
        .. "selbst gelernt hat, und das kann der Client über andere nicht "
        .. "melden.\n\n"
        .. "Aufrufbar auch mit " .. A("/wc gruppe") .. "." },

    { chapter = "Im Raid", icon = ICON .. "INV_Misc_Spyglass_02",
      title = "WeintTV",
      body =
        "Die Tiefenanalyse eures letzten Pulls im Spiel: vermeidbarer "
        .. "Schaden mit der Gegenmaßnahme dazu, Wirkungsdauern deiner "
        .. "Effekte, Aktivzeit, Cooldown-Nutzung und "
        .. "Mechanikfehler.\n\n"
        .. "Oben schaltest du zwischen " .. A("Nur ich") .. " und "
        .. A("Ganzer Raid") .. " um.\n\n"
        .. "Gerechnet wird das alles in WeintCompanion am Schreibtisch, "
        .. "nicht hier. Das ist Absicht: zwei Auswertungen derselben "
        .. "Tatsache laufen irgendwann auseinander, und dann widersprechen "
        .. "sich Spiel und Desktop.\n\n"
        .. "Deshalb ist diese Seite immer der Stand der " .. E("letzten "
        .. "Zustellung") .. " und nie eine Live-Ansicht. Bleibt eine Karte "
        .. "leer, sagt sie dazu, ob nichts geliefert wurde oder ob "
        .. "tatsächlich nichts passiert ist." },

    { chapter = "Im Raid", icon = ICON .. "INV_Misc_Book_03",
      title = "Academy",
      body =
        "Das Lernzentrum: sechs Bereiche mit Sternebewertung (Rotation, "
        .. "Bewegung, Cooldowns, Mechaniken, Überleben, Leistung), ein "
        .. "Trainingsplan mit Lektionen und der Verlauf über deine "
        .. "aufgezeichneten Pulls.\n\n"
        .. "Oben steht, welcher Kampf da bewertet wird — Boss, "
        .. "Schwierigkeit, Pull und wie er ausging. Das gehört dazu: "
        .. "derselbe Boss heroisch und normal sind zwei verschiedene "
        .. "Ansprüche, und ein Wipe bei 80 % erklärt eine schwache "
        .. "Cooldown-Wertung von selbst.\n\n"
        .. "Eine Regel solltest du kennen: " .. E("null Sterne heißt "
        .. "\"keine Daten\"") .. " und nicht \"schlecht\". Ein Bereich ohne "
        .. "Vergleichsgruppe oder ohne gelieferte Zahlen bleibt "
        .. "unbewertet, statt dir eine Note zu geben, die nichts misst.\n\n"
        .. "Lektionen hakst du selbst ab. Was das Kampfprotokoll zeigt und "
        .. "was du selbst angehakt hast, werden nie ineinander geschrieben "
        .. "— eine Lektion gilt als erledigt, wenn eines von beidem "
        .. "zutrifft.\n\n"
        .. "Auch das kommt fertig aus der Companion und erscheint nach dem "
        .. "nächsten Neuladen." },

    { chapter = "Im Raid", icon = ICON .. "Spell_Nature_Lightning",
      title = "Rotationshelfer",
      body =
        "Ein freistehendes Fenster mit der Prioritätenliste deiner "
        .. "Spezialisierung. An einer Trainingspuppe geht es von selbst "
        .. "auf; sonst mit " .. A("/wc training") .. ".\n\n"
        .. "Anders als der Rest des Addons rechnet das live mit: die Liste "
        .. "sortiert sich nach dem, was gerade wirkbar ist, und jede Zeile "
        .. "sagt mit echten Zahlen, warum sie dort steht — zu wenig "
        .. "Ressourcen, Abklingzeit läuft, Bedingung nicht erfüllt.\n\n"
        .. "Am Ende einer Übung bekommst du eine Note aus Priorität, "
        .. "Auslastung und Wirkungsdauern. Gewertet wird ab drei Minuten "
        .. "Kampfzeit; kürzere Übungen siehst du, gemeldet werden sie "
        .. "nicht.\n\n"
        .. "Für Tank-Spezialisierungen gibt es bewusst " .. E("keine")
        .. " Liste. Die falsche Rotation wäre schlechter als gar keine.\n\n"
        .. "Dass es an der Puppe von selbst aufgeht, ist ein Schalter "
        .. "unter " .. A("Einstellungen → Rotationshelfer") .. ". Aus "
        .. "bleibt es weg, bis du es rufst — verloren geht dabei nichts, "
        .. "auch deine Übungstage nicht.\n\n"
        .. A("/wc training check") .. " prüft, ob alle Zauber deiner Spec "
        .. "erkannt werden." },

    --------------------------------------------------
    -- FUER DIE GILDE
    --------------------------------------------------

    { chapter = "Für die Gilde", icon = ICON .. "INV_Crate_01",
      title = "Materialien",
      feature = "materials.view",
      body =
        "Was in der Gildenbank liegt, nach Kategorie sortiert, mit dem "
        .. "Fehlbestand zum Sollwert.\n\n"
        .. "Gefüllt wird die Übersicht auf zwei Wegen: über einen Scan der "
        .. "Gildenbank, wenn du davorstehst, oder über einen "
        .. A("Import") .. " vom Discord-Bot.\n\n"
        .. "Der Bereich ist an deine Discord-Rolle gebunden. Steht dort "
        .. "ein Schloss, fehlt die Freigabe — die vergibt die Raidleitung "
        .. "in Discord, nicht das Addon." },

    { chapter = "Für die Gilde", icon = ICON .. "Spell_Holy_MagicalSentry",
      title = "WeakAuras",
      body =
        "WeakAuras nach Kategorie sortiert, per Klick importierbar. Kein "
        .. "Suchen nach Import-Strings mehr.\n\n"
        .. "Die Liste hat zwei Quellen, und jede Zeile sagt, aus welcher "
        .. "sie kommt: " .. E("WeintCodex") .. " für die mitgelieferten "
        .. "Pakete, " .. E("Companion") .. " für eine, die jemand am "
        .. "eigenen Schreibtisch eingetragen hat, und " .. E("Gilde")
        .. " für eine, die über den Bot für alle freigegeben wurde.\n\n"
        .. "Ganz links steht ein grüner Haken, wenn die Aura in WeakAuras "
        .. "bereits vorhanden ist. Gefragt wird das bei WeakAuras selbst "
        .. "und nicht an deiner Klickhistorie — ein Import kann abgebrochen "
        .. "und eine Aura später gelöscht worden sein.\n\n"
        .. "Ist WeakAuras gar nicht geladen, sagt die Zeile dazu nichts. "
        .. "\"Nicht installiert\" wäre dann eine Aussage über unser "
        .. "Unwissen." },

    { chapter = "Für die Gilde", icon = ICON .. "INV_Misc_Note_01",
      title = "Import",
      body =
        "Der Discord-Bot exportiert Bossnotizen, Raidlisten, Materialien "
        .. "und WeakAuras als Code. Hier fügst du ihn ein, und er landet "
        .. "im Addon.\n\n"
        .. "Aufrufbar auch mit " .. A("/wc import") .. ".\n\n"
        .. "Ein Import wirkt " .. E("sofort") .. " — ohne Neuladen. Das ist "
        .. "der Unterschied zu allem, was die Companion zustellt: wer "
        .. "mitten im Raid steht, lädt nicht neu.\n\n"
        .. "Auch die Wertegewichte aus einem Sim kommen auf diesem Weg "
        .. "herein, wenn du sie am Schreibtisch kopiert hast." },

    --------------------------------------------------
    -- ZUM SCHLUSS
    --------------------------------------------------

    { chapter = "Zum Schluss", icon = ICON .. "INV_Misc_Wrench_01",
      title = "Einstellungen — was an und was aus?",
      body =
        "Unter " .. A("Einstellungen") .. " steht jede Option als Schalter, "
        .. "in sechs Reitern. " .. E("Nichts davon ist endgültig") .. " — "
        .. "jeder Schalter lässt sich dort jederzeit wieder umlegen, und "
        .. "kein einziger löscht dabei etwas.\n\n"
        .. E("Von sich aus helfen") .. " (Fenster & Ansicht): an bekommst "
        .. "du den Ausrüstungs-Alarm, die Einkaufsliste am Auktionshaus, "
        .. "den Plan beim Umschmieder und den Rotationshelfer an der "
        .. "Puppe. Aus sagt WeintCodex auf diesem Charakter von sich aus "
        .. "gar nichts mehr — " .. A("/wc") .. " öffnet es weiterhin "
        .. "vollständig, und alles, was du selbst aufrufst, funktioniert "
        .. "unverändert. Gut für Zweitcharaktere.\n\n"
        .. E("Ausrüstungs-Alarm") .. ": an siehst du eine fehlende "
        .. "Verzauberung oder einen leeren Sockel, bevor es im Raid "
        .. "auffällt. Aus bleibt es still — die Lücke steht dann nur noch "
        .. "auf der Charakterseite, wo man sie suchen muss. Der Signalton "
        .. "ist ein eigener Schalter daneben.\n\n"
        .. E("Umschmieden") .. " (Beta): an kommt der Reiter "
        .. A("Charakter → Umschmieden") .. " dazu und das Fenster beim "
        .. "Umschmieder. Aus ist er nicht da — deshalb ist er ab Werk aus: "
        .. "das Werkzeug gibt Gold aus, und seine Vorschläge sind noch "
        .. "nicht überall verlässlich.\n\n"
        .. E("Rotationshelfer") .. ": an geht das Fenster an einer "
        .. "Trainingspuppe von selbst auf. Aus nur noch über "
        .. A("/wc training") .. ".\n\n"
        .. E("Einkaufsliste") .. ": an fasst sie am Auktionshaus zusammen, "
        .. "was dir fehlt. Aus musst du selbst wissen, wonach du suchst.\n\n"
        .. E("Minikarten-Symbol") .. ": aus verschwindet nur das Symbol, "
        .. "nicht das Addon — " .. A("/wc") .. " bleibt.\n\n"
        .. "Jeder Schalter nennt in seinem Tooltip den passenden "
        .. "Slash-Befehl. Und wenn etwas nicht stimmt, schreibt zu fast "
        .. "jedem Bereich ein Befehl jede Zwischenzahl in den Chat: "
        .. A("/wc sockel") .. ", " .. A("/wc vz") .. ", "
        .. A("/wc tempo") .. ", " .. A("/wc umschmieden prüfen") .. ", "
        .. A("/wc kalender") .. ", " .. A("/wc einkauf prüfen") .. ", "
        .. A("/wc alarm berufe") .. "." },

    { chapter = "Zum Schluss", icon = ICON .. "Achievement_Quests_Completed_08",
      title = "Sag uns, was nicht stimmt",
      body =
        "Das war der Rundgang. Öffne das Addon jederzeit mit "
        .. A("/wc") .. ", und hol dir diese Einführung mit "
        .. A("/wc tour") .. " zurück — sie ist auch unter "
        .. A("Einstellungen → Fenster & Ansicht") .. " verlinkt.\n\n"
        .. "Bei künftigen Updates zeigt dir dieses Fenster kurz, was sich "
        .. "geändert hat.\n\n"
        .. E("Und jetzt die Bitte:")
        .. " WeintCodex lebt davon, dass gemeldet wird, was daneben liegt. "
        .. "Besonders bei den " .. E("Sockelsteinen") .. " — dort sind die "
        .. "Empfehlungen noch nicht überall verlässlich, und ohne "
        .. "Rückmeldung fällt kein einziger dieser Fälle auf.\n\n"
        .. "Schreib im " .. E("Discord der Gilde") .. ", was dir "
        .. "aufgefallen ist: welche Spezialisierung, was das Addon "
        .. "vorgeschlagen hat, was du erwartet hättest. Ein Screenshot "
        .. "oder die Ausgabe des passenden Diagnosebefehls dazu, und die "
        .. "Sache ist meistens in einer Fassung erledigt.\n\n"
        .. "Das gilt genauso für alles andere: fehlende Erklärungen, "
        .. "Knöpfe, die niemand findet, Texte, die man zweimal lesen muss. "
        .. "Vielen Dank — und viel Erfolg im Raid." },
}

--------------------------------------------------
-- Buttons
--------------------------------------------------

-- Nutzt die gemeinsame Schaltflaeche der neuen Sprache. Das Popup ist das
-- Erste, was nach einem Update zu sehen ist - es waere die falsche Stelle,
-- eine eigene Knopfform zu pflegen.
local function CreateButton(parent, text, width, onClick, kind)
    return WeintCodex.CreateButton(parent, {
        text = text, width = width, kind = kind or "primary",
        height = 32, backdrop = "surface2", onClick = onClick,
    })
end

local function ClearButtons()
    for _, b in ipairs(buttonRow) do
        b:Hide()
        b:SetParent(nil)
    end
    wipe(buttonRow)
end

local function AddButton(text, width, onClick, kind)
    local btn = CreateButton(window, text, width, onClick, kind)
    table.insert(buttonRow, btn)
    return btn
end

--------------------------------------------------
-- Schliessen: merkt sich die aktuelle Version, damit das Popup
-- nicht bei jedem Login erneut erscheint.
--------------------------------------------------

local function Dismiss()
    if overlay then overlay:Hide() end

    local sd = WeintCodex.SavedData
    if sd then
        sd.onboarding = sd.onboarding or {}
        sd.onboarding.lastSeenVersion = WeintCodex.Version
    end
end

--------------------------------------------------
-- Gemeinsames Fenster fuer Tour und Changelog-Popup
--------------------------------------------------

local function EnsureFrame()
    if overlay then return end

    local parent = WeintCodex.MainFrame
    if not parent then return end

    overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints(parent)
    overlay:SetFrameLevel(parent:GetFrameLevel() + 100)
    overlay:EnableMouse(true)
    SetSolidBg(overlay, 0, 0, 0, 0.75)
    overlay:Hide()

    window = CreateFrame("Frame", nil, overlay)
    window:SetSize(WINDOW_W, WINDOW_H)
    window:SetPoint("CENTER")
    SetSolidBg(window, C.surface2[1], C.surface2[2], C.surface2[3], 1.0)
    DrawBorder(window, C.borderStrong[1], C.borderStrong[2], C.borderStrong[3], 1.0, 1)
    -- Bernstein nur als Oberkante, wie an jeder Karte der neuen Sprache -
    -- ein umlaufender Akzentrahmen ist die alte Ornamentik.
    local topEdge = window:CreateTexture(nil, "ARTWORK")
    topEdge:SetHeight(1)
    topEdge:SetPoint("TOPLEFT",  window, "TOPLEFT",   8, 0)
    topEdge:SetPoint("TOPRIGHT", window, "TOPRIGHT", -8, 0)
    topEdge:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.34)
    WeintCodex.CutCorners(window, 14, "bgDark")

    local closeBtn = CreateFrame("Button", nil, window)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -10)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetAllPoints(closeBtn)
    closeX:SetFont(WeintCodex.Fonts.sansSemi, 15, "")
    closeX:SetText(WeintCodex.ColorText("textMuted", "\195\151"))
    closeBtn:SetScript("OnClick", Dismiss)

    iconStr = window:CreateFontString(nil, "OVERLAY")
    iconStr:SetPoint("TOP", window, "TOP", 0, -22)
    iconStr:SetFont(WeintCodex.Fonts.sansSemi, 30, "")

    titleStr = window:CreateFontString(nil, "OVERLAY")
    titleStr:SetPoint("TOP", iconStr, "BOTTOM", 0, -10)
    titleStr:SetFont(WeintCodex.Fonts.sansBold, 20, "")
    titleStr:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3])

    stepStr = window:CreateFontString(nil, "OVERLAY")
    stepStr:SetPoint("TOP", titleStr, "BOTTOM", 0, -6)
    stepStr:SetFont(WeintCodex.Fonts.mono, 10, "")

    local divider = window:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(C.border[1], C.border[2], C.border[3], 1.0)
    divider:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -112)
    divider:SetPoint("TOPRIGHT", window, "TOPRIGHT", -24, -112)
    divider:SetHeight(1)

    -- Der Text liegt in einem Bildlauffeld, nicht direkt auf dem Fenster.
    -- Die schlanke Leiste ist die Hausform (siehe CLAUDE.md), das Mausrad
    -- bringt WeintCodex.CreateScrollArea mit.
    bodyScroll, bodyInner = WeintCodex.CreateScrollArea(
        window, BODY_X, -BODY_TOP,
        WINDOW_W - 2 * BODY_X, WINDOW_H - BODY_TOP - BODY_BOTTOM, true)
    -- Zweiter Ankerpunkt: damit folgt die Hoehe des Feldes der des
    -- Fensters, das SetBody() an den Text anpasst.
    bodyScroll:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", BODY_X, BODY_BOTTOM)
    -- Ohne dieses Flag blendet ScrollFrame_OnScrollRangeChanged die Leiste
    -- bei Bildlaufweite 0 wieder ein (nur ohne Griff) und wuerde damit das
    -- Ausblenden in SetBody() rueckgaengig machen.
    bodyScroll.scrollBarHideable = true

    bodyStr = bodyInner:CreateFontString(nil, "OVERLAY")
    bodyStr:SetPoint("TOPLEFT", bodyInner, "TOPLEFT", 0, 0)
    bodyStr:SetWidth(bodyInner:GetWidth())
    bodyStr:SetJustifyH("LEFT")
    bodyStr:SetJustifyV("TOP")
    bodyStr:SetFont(WeintCodex.Fonts.sans, 13, "")
    bodyStr:SetSpacing(4)
    bodyStr:SetTextColor(C.textNormal[1], C.textNormal[2], C.textNormal[3])
end

--------------------------------------------------
-- Text setzen und das Fenster darauf einstellen.
--
-- Reihenfolge ist hier tragend: erst der Text, dann seine gemessene Hoehe,
-- daraus die Fensterhoehe, und erst danach die Hoehe des Bildlaufinhalts -
-- die Sichtbarkeit der Leiste haengt von der Differenz beider ab.
--------------------------------------------------

local function SetBody(text)
    bodyStr:SetText(text or "")

    local needed  = math.ceil(bodyStr:GetStringHeight() or 0) + 8
    local height  = BODY_TOP + BODY_BOTTOM + needed
    if height < WINDOW_H     then height = WINDOW_H     end
    if height > WINDOW_H_MAX then height = WINDOW_H_MAX end
    window:SetHeight(height)

    local visible = height - BODY_TOP - BODY_BOTTOM
    bodyInner:SetHeight(needed > visible and needed or visible)

    bodyScroll:SetVerticalScroll(0)
    if bodyScroll.UpdateScrollChildRect then
        bodyScroll:UpdateScrollChildRect()
    end

    -- Eine Leiste ohne Bildlauf ist ein Bedienelement, das nichts tut.
    local bar = bodyScroll.WCScrollBar
    if bar then
        if needed > visible then bar:Show() else bar:Hide() end
    end
end

local function ShowFrame()
    local main = WeintCodex.MainFrame
    if main and not main:IsShown() then
        if WeintCodex.ResetToHome then WeintCodex.ResetToHome() end
        main:Show()
    end
    overlay:Show()
end

--------------------------------------------------
-- Tour (Erststart)
--------------------------------------------------

-- Tatsaechlich gezeigte Seiten. Die Konstante TOUR_STEPS bleibt unangetastet,
-- damit ein spaeter eintreffendes Zugriffsprofil die uebersprungenen Seiten
-- beim naechsten Aufruf wieder einblenden kann.
local visibleSteps = {}

local function BuildVisibleSteps()
    wipe(visibleSteps)

    for _, step in ipairs(TOUR_STEPS) do
        local allowed = true
        if step.feature and WeintCodex.Access and WeintCodex.Access.Can then
            allowed = WeintCodex.Access.Can(step.feature)
        end
        if allowed then
            visibleSteps[#visibleSteps + 1] = step
        end
    end
end

local function RenderTourStep()
    local step = visibleSteps[currentStep]
    if not step then return end

    iconStr:SetText(WeintCodex.Icon(step.icon, 30))
    titleStr:SetText(step.title)

    -- KAPITEL UND SCHRITT IN EINER ZEILE.
    -- Eine reine Schrittzahl beantwortet die Frage nicht, die man bei
    -- Seite 9 von 22 hat: wo bin ich, und wovon handelt das hier gerade.
    -- Das Kapitel steht deshalb davor - es ist die Gliederung, die die
    -- Tour ohnehin hat, und ohne sie ist sie eine lange Liste.
    stepStr:SetText(WeintCodex.ColorText("gold", step.chapter or "")
        .. WeintCodex.ColorText("textDim", "  ·  Schritt " .. currentStep
            .. " von " .. #visibleSteps))

    SetBody(step.body)

    ClearButtons()

    local isLast  = currentStep == #visibleSteps
    local nextBtn = AddButton(isLast and "Los geht's!" or "Weiter", 140, function()
        if currentStep < #visibleSteps then
            currentStep = currentStep + 1
            RenderTourStep()
        else
            Dismiss()
        end
    end)
    nextBtn:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -20, 20)

    if currentStep > 1 then
        local backBtn = AddButton("Zurück", 100, function()
            currentStep = currentStep - 1
            RenderTourStep()
        end)
        backBtn:SetPoint("BOTTOMRIGHT", nextBtn, "BOTTOMLEFT", -10, 0)
    end

    -- EIN AUSGANG, DER VON ANFANG AN SICHTBAR IST.
    -- Die Tour ist mit 3.0.0.0 vollstaendig und damit lang. Wer sie nicht
    -- jetzt lesen will, darf nicht 22-mal auf "Weiter" klicken muessen -
    -- sonst klickt er einmal auf das Kreuz und findet nie wieder her.
    -- Deshalb steht daneben, wie man sie zurueckholt.
    if not isLast then
        local skipBtn = AddButton("Später (/wc tour)", 150, Dismiss, "ghost")
        skipBtn:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 16, 20)
    end
end

function WeintCodex.Onboarding.ShowTour()
    EnsureFrame()
    if not overlay then return end

    BuildVisibleSteps()
    if #visibleSteps == 0 then return end

    -- Gesehen ist gesehen: die Fassung wird beim Zeigen vermerkt und nicht
    -- erst beim Durchklicken bis zur letzten Seite. Wer nach drei Seiten
    -- genug hat, hat die Tour trotzdem bekommen - und bekaeme sie sonst bei
    -- jedem Anmelden erneut, was genau die Sorte Fenster ist, die man
    -- irgendwann ungelesen wegklickt.
    local sd = WeintCodex.SavedData
    if sd then
        sd.onboarding = sd.onboarding or {}
        sd.onboarding.tourEdition = TOUR_EDITION
    end

    currentStep = 1
    RenderTourStep()
    ShowFrame()
end

--------------------------------------------------
-- Update-Changelog-Popup
--------------------------------------------------

function WeintCodex.Onboarding.ShowChangelog(entries)
    if not entries or #entries == 0 then return end
    EnsureFrame()
    if not overlay then return end

    iconStr:SetText(WeintCodex.Icon("Interface\\Icons\\INV_Misc_Note_02", 30))
    titleStr:SetText("Was gibt's Neues?")

    if #entries == 1 then
        stepStr:SetText(WeintCodex.ColorText("textDim", "Version " .. entries[1].version .. " · " .. (entries[1].date or "")))
    else
        stepStr:SetText(WeintCodex.ColorText("textDim", #entries .. " Updates seit eurem letzten Login"))
    end

    local lines = {}
    for _, entry in ipairs(entries) do
        if #entries > 1 then
            table.insert(lines, WeintCodex.ColorText("textBright",
                "Version " .. entry.version .. (entry.date and (" (" .. entry.date .. ")") or "")))
        end
        for _, note in ipairs(entry.notes) do
            table.insert(lines, "• " .. note)
        end
        table.insert(lines, "")
    end
    SetBody(table.concat(lines, "\n"))

    ClearButtons()
    local okBtn = AddButton("Verstanden", 160, Dismiss)
    okBtn:SetPoint("BOTTOM", window, "BOTTOM", 0, 20)

    ShowFrame()
end

--------------------------------------------------
-- Sammelt alle Changelog-Eintraege, die neuer sind als die zuletzt
-- gesehene Version (WeintCodex_ChangelogData ist neueste-zuerst
-- sortiert - siehe data/changelog.lua).
--------------------------------------------------

local function CollectChangelogSince(lastVersion)
    local data = WeintCodex_ChangelogData
    if not data or #data == 0 then return nil end

    local collected, found = {}, false
    for _, entry in ipairs(data) do
        if entry.version == lastVersion then
            found = true
            break
        end
        table.insert(collected, entry)
    end

    -- lastVersion nicht in der Liste (z.B. mehrere uebersprungene
    -- Releases oder gekuerzte Historie) - sicherheitshalber alles zeigen.
    if not found then
        collected = data
    end

    if #collected == 0 then return nil end
    return collected
end

--------------------------------------------------
-- Wird einmal pro Login aus core/main.lua (PLAYER_LOGIN) aufgerufen.
--------------------------------------------------

function WeintCodex.Onboarding.Check()
    local sd = WeintCodex.SavedData
    if not sd then return end

    sd.onboarding = sd.onboarding or {}
    local last = sd.onboarding.lastSeenVersion

    -- NOCH NIE HIER GEWESEN - ODER DIE TOUR IST NEU GESCHRIEBEN WORDEN.
    --
    -- Der zweite Fall ist der Grund fuer TOUR_EDITION. Zwischen 1.0 und
    -- 2.10 ist ungefaehr die Haelfte dieses Addons dazugekommen, ohne dass
    -- die Einfuehrung je davon gesprochen haette: wer sie 2024 gesehen hat,
    -- kannte danach ein Addon, das es so nicht mehr gibt. Ein Changelog-
    -- Popup traegt das nicht - es beantwortet "was ist neu" und nicht
    -- "was gibt es hier eigentlich alles".
    --
    -- Die Fassungsnummer steht bewusst NEBEN lastSeenVersion und nicht
    -- darin: nicht jede Version schreibt die Tour um, und die meisten
    -- sollen weiterhin das kurze Popup zeigen.
    local seenEdition = tonumber(sd.onboarding.tourEdition) or 0

    if (not last) or seenEdition < TOUR_EDITION then
        WeintCodex.Onboarding.ShowTour()
        return
    end

    if last == WeintCodex.Version then
        return
    end

    local entries = CollectChangelogSince(last)
    if entries then
        WeintCodex.Onboarding.ShowChangelog(entries)
    else
        -- Version hat sich geaendert, aber keine passenden Changelog-
        -- Eintraege vorhanden - trotzdem als gesehen markieren.
        sd.onboarding.lastSeenVersion = WeintCodex.Version
    end
end
