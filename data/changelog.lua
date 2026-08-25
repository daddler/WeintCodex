--------------------------------------------------
-- WeintCodex :: Changelog-Daten
-- Wird von core/onboarding.lua fuer das Update-Popup genutzt.
-- Neueste Version zuerst! Bei jedem Release hier einen Eintrag
-- ergaenzen (parallel zu CHANGELOG.md) - siehe CLAUDE.md.
--------------------------------------------------

WeintCodex_ChangelogData = {
    {
        version = "2.6.0.1",
        date    = "25.08.2026",
        notes   = {
            "Behoben: der Knopf \"Zauber-IDs der Rotation\" unter Einstellungen > Diagnose warf einen Fehler, wenn der Rotationshelfer in dieser Sitzung noch nie offen war - also ausgerechnet bei dem, der dort nachsieht. Dasselbe galt fuer \"Stummschaltungen aufheben\" und fuer |cffD4A24A/wc training check|r.",
        },
    },
    {
        version = "2.6.0.0",
        date    = "25.08.2026",
        notes   = {
            "Neu: ein Einstellungsbereich im Addon (|cffD4A24A/wc einstellungen|r oder System > Einstellungen in der Navigation). Bis jetzt gab es fuer keine einzige Option dieses Addons eine Schaltflaeche - ob der Ausruestungs-Alarm meldet, ob er einen Ton spielt, ob sich der Rotationshelfer an der Puppe oeffnet: alles hing an einem Slash-Befehl, den man kennen musste.",
            "Zu jedem Befehl gibt es jetzt einen Knopf: Alarm an/aus, Ton, Erinnerungen, Weggeklicktes vergessen, Testmeldung, Meldung verschieben - dazu die fuenf Schalter des Rotationshelfers, die Diagnoseausgaben und das Zugriffsprofil. Die Befehle bleiben alle bestehen, und jeder Tooltip nennt seinen.",
            "Das Hauptfenster laesst sich jetzt mit Esc schliessen. Dafuer muss der Name des Fensters in einer Liste des Spiels stehen - er war dort nie eingetragen.",
            "Und es draengt sich nicht mehr vor: bisher lag es fest ueber Taschen, Charakterbogen und selbst ueber den Dialogen des Spiels. Beides ist abschaltbar, falls jemand es anders will.",
            "Neu dazu: die Fenstergroesse als Regler (70-120 %) mit einem Knopf zum Zuruecksetzen, ein Schalter fuer das Minimap-Symbol und einer fuer zweispaltige Bossnotizen.",
            "Behoben: der Ausruestungs-Alarm hat nie einen Ton gespielt. Es gab ihn von Anfang an, die Einstellung stand auf \"an\", und es passierte nichts - beide Aufrufformen sind auf dem heutigen Client tot, und weil niemand den Rueckgabewert ansah, blieb das jahrelang unbemerkt. Der Warnton kommt jetzt vom Spiel selbst und ueber den Master-Kanal.",
            "Wer den Signalton einschaltet, hoert ihn sofort. Und |cffD4A24A/wc alarm tontest|r bzw. der Knopf \"Ton testen\" in den Einstellungen sagt im Chat, WELCHER Klang gespielt wurde - hoerst du trotzdem nichts, liegt es an der Lautstaerke des Spiels.",
            "Behoben: |cffD4A24A/wc alarm test|r lief mit einem Fehler auf, wenn gerade gar nichts offen war - also genau in dem Fall, fuer den die Testmeldung da ist.",
        },
    },
    {
        version = "2.5.0.0",
        date    = "25.08.2026",
        notes   = {
            "Die Sockelseite hat seit fuenf Releases falsch bewertet, und die Ursache lag unter der Rechnung: die Reihenfolge der Sockel eines Gegenstands war erfunden. Der Client meldet nur, WIE VIELE Sockel welcher Farbe ein Teil hat, nie in welcher Reihenfolge - abgezaehlt wurde trotzdem in einer festen Folge. Bei jedem Teil mit zwei verschiedenfarbigen Sockeln konnten Stein und Sockelfarbe damit vertauscht sein.",
            "Gefragt wird jetzt der Spielclient selbst: der Tooltip des Grundgegenstands listet alle Sockel leer und in echter Reihenfolge. Auch ob ein Sockelbonus anliegt, wird jetzt abgelesen statt geraten - der Client zeichnet die Zeile gruen, wenn er greift.",
            "Auf Teilen mit blauem Sockel galt der Sockelbonus fuer die halbe Belegschaft pauschal als wertlos: bei 21 von 39 Specs bestand die blaue Steinliste nur aus Treffer- und Waffenkundesteinen, und am Cap war die damit rechnerisch nichts mehr wert. Betroffen waren alle Jaeger und Schurken, Frost- und Unheilig-DK, Verstaerker, Windwandler, Wildheit sowie alle Magier und Hexenmeister.",
            "Ein Stein am Cap zaehlt jetzt mit dem, was ausserhalb des Caps liegt, statt ganz wegzufallen - und Empfehlung, Steinurteil und Bonuszeile kommen aus EINER Rechnung, statt aus dreien, die man synchron halten muss.",
            "Juwelier-Schlangenaugen werden nur noch empfohlen, wer den Beruf hat, und hoechstens zwei. Bisher drueckten sie als Listeneintrag jeden korrekten 320er Stein von \"ok\" auf \"falsch\" - auch bei Nicht-Juwelieren.",
            "Kennt der Client ein Teil noch nicht, wird darueber nicht mehr geurteilt: die Zeile sagt es und fuellt sich nach, sobald die Daten da sind.",
            "Jaegern wird kein Waffenkunde-Cap mehr angezeigt. Fernkampfangriffe koennen nicht pariert oder ausgewichen werden, Waffenkunde bringt ihnen nichts - die Karte meldete ein Defizit, das niemand schliessen kann.",
            "Neu: |cffD4A24A/wc sockel|r zeigt je Teil die gelesene Sockelfolge samt Quelle, die Bonuszeile mit ihrer Farbe und beide Planvarianten mit ihren Wertungen. Und eine Datenpruefung beim Login meldet Widersprueche in den Steinlisten, wie es sie fuer Verzauberungen schon gibt.",
        },
    },
    {
        version = "2.4.1.2",
        date    = "24.08.2026",
        notes   = {
            "Der Ingenieurs-Guertel wurde weiter als \"Nitrobooster fehlt\" gemeldet, obwohl der Booster drauflag. Die Annahme dahinter war falsch: der Nitrobooster steht nicht im Verzauberungsfeld des Item-Links.",
            "Erkannt wird er jetzt am Tooltip - traegt der angelegte Gegenstand eine \"Benutzen:\"-Zeile, die sein Grundgegenstand nicht hat, wurde etwas angebracht. Weiterhin ohne Namen und ohne IDs: die Beschriftung kommt vom Client.",
            "Eine \"Benutzen:\"-Zeile, die schon zum Gegenstand selbst gehoert, zaehlt nicht als Bastelei. Ist der Tooltip noch nicht geladen, wird nichts behauptet, sondern spaeter nachgesehen.",
        },
    },
    {
        version = "2.4.1.1",
        date    = "24.08.2026",
        notes   = {
            "Der Ingenieurs-Guertel hiess im Alarm \"Nitrobeschleuniger\" - im deutschen Client heisst er Nitrobooster. Auf die Erkennung hatte das keinen Einfluss (verglichen wird der Verzauberungswert des Item-Links, nie ein Name), beim Suchen aber sehr wohl.",
            "Die Nitrobooster brauchen laut Rezept Fertigkeit 400, nicht 500. Ingenieure zwischen 400 und 500 haetten sonst nie davon erfahren.",
            "Neu: /wc alarm berufe sagt, was gelesen wurde - je Berufsvorteil den angelegten Gegenstand, den Verzauberungswert aus seinem Item-Link, die Sockelzahlen und das Urteil. Wenn eine Meldung falsch aussieht, sagt dieser Befehl warum.",
        },
    },
    {
        version = "2.4.1.0",
        date    = "24.08.2026",
        notes   = {
            "Weggeklickt heisst jetzt fuenf Minuten Ruhe statt fuer immer - danach erinnert der Alarm wieder, solange die Luecke offen ist. Sonst vergisst man sie schlicht.",
            "Zurueck kommt die Erinnerung beim Zonenwechsel, im Ruhebereich, am Instanzeingang und von selbst per Zeitgeber - aber nur, wenn ihr gerade nichts anderes macht (kein Kampf, nicht tot, nicht auf einer Flugroute, nicht am Zaubern und nicht in Bewegung).",
            "Der Instanzeingang uebergeht die Quittung: vor dem Raid ist die Erinnerung kein Noergeln, sondern der Zweck der Sache.",
            "Behoben: Die Guertelschnalle verschwand in der Sockelzahl (\"2 Sockel leer\"). Ein leerer Sockel und ein fehlender Sockelplatz sind zwei verschiedene Besorgungen und stehen jetzt nebeneinander.",
            "Neu: Berufsvorteile zaehlen mit. Ingenieure am Guertel (den kann sonst niemand verzaubern), Schmiede mit ihren Zusatzsockeln an Handschuhen und Armschienen, Juweliere mit den Schlangenaugen.",
            "Handschuhe, Umhang, Armschienen und Schultern bekommen nur einen Hinweis, was euer Beruf dort zusaetzlich hergibt - und auch nur, wenn die Verzauberung ganz fehlt. \"Du koenntest was Besseres tragen\" waere ein Urteil, und das faellt dieser Alarm nicht.",
            "/wc alarm ruhe heisst jetzt /wc alarm erinnern und schaltet alle Erinnerungen. /wc alarm nennt ausserdem die erkannten Berufe.",
        },
    },
    {
        version = "2.4.0.2",
        date    = "24.08.2026",
        notes   = {
            "Der Ausruestungs-Alarm bleibt jetzt stehen, bis ihr ihn wegklickt - bisher war er nach neun Sekunden weg, also genau dann, wenn man gerade auf die Taschen schaut.",
            "Weggeklickt heisst gesehen: genau dieser Befund meldet sich nicht wieder, auch nicht im Ruhebereich und auch nicht nach einem /reload.",
            "Aendert sich der Befund, meldet er sich erneut. Wer die Handschuhe verzaubert und den Sockel leer laesst, sieht das - die Quittung haengt an Art und Anzahl, nicht am Slot.",
            "Beim Pull weicht eine stehende Meldung und kommt nach dem Kampf zurueck, sofern der Befund dann noch steht. Quittiert wird dabei nichts.",
            "/wc alarm erneut hebt das Wegklicken wieder auf. /wc alarm dauer gibt es nicht mehr - es gibt keine Anzeigedauer.",
        },
    },
    {
        version = "2.4.0.1",
        date    = "24.08.2026",
        notes   = {
            "Neu: Ausruestungs-Alarm. Wer ein Teil anlegt, das weder verzaubert noch versockelt ist, bekommt eine grosse Einblendung in Bildschirmmitte samt Signalton - die Bauform der Bossmods, weil sie genau das leistet, was fehlte: eine Meldung, die man nicht uebersieht.",
            "Dieselbe Meldung als Erinnerung, sobald man einen Ruhebereich betritt. Dort steht der Verzauberer, dort ist die Bank - vor dem Pull davon zu erfahren nuetzt niemandem. Hoechstens einmal alle 15 Minuten.",
            "Linksklick oeffnet die passende Charakterseite (Sockel, wenn nur Steine fehlen, sonst Verzauberungen), Rechtsklick blendet aus. /wc alarm bewegen laesst die Meldung zum Verschieben stehen.",
            "Gemeldet wird nur \"Verzauberung fehlt\" und \"Sockel leer\" - beides ist unstrittig. \"Nicht ideal\" waere eine Meinung, und eine bildschirmfuellende Meldung ueber eine Meinung schaltet man nach dem dritten Mal ab. Erst ab Selten (blau), gruene Uebergangsware verzaubert niemand.",
            "Abschalten mit /wc alarm aus; /wc alarm zeigt alle Schalter (Ton, Erinnerung, Anzeigedauer).",
            "Die Onboarding-Tour hat dafuer eine Seite mehr.",
        },
    },
    {
        version = "2.4.0.0",
        date    = "23.08.2026",
        notes   = {
            "Neu: Gruppencheck. Ein eigener Punkt unter Raid (oder /wc gruppe) prueft der Reihe nach jedes Gruppen- und Raidmitglied und zeigt, wem eine Verzauberung fehlt und wer leere Sockel hat - mit der Liste der Slots im Tooltip und rechts im Detailbereich.",
            "Der Gruppencheck zaehlt, er bewertet nicht. \"Verzauberung fehlt\" und \"Sockel leer\" sind unstrittig; ob eine Verzauberung zur Spec passt, entscheidet weiterhin nur die Charakterseite und nur fuer den eigenen Charakter. Ringe zaehlen nicht mit - den Beruf anderer Spieler meldet der Client nicht. Wer zu weit weg oder offline ist, zaehlt nicht als geprueft.",
            "WeakAuras: ein gruener Haken steht jetzt an jeder Aura, die WeakAuras bereits fuehrt. Der Tooltip sagt, ob das Paket vollstaendig oder nur teilweise da ist, die Schaltflaeche heisst danach \"Neu importieren\" - und \"Aktualisieren\", wenn eine andere Fassung installiert ist als die angebotene.",
            "Jaegern wurde dauerhaft \"Nebenhand: Kein Gegenstand angelegt\" gemeldet. Ein Jaeger traegt in MoP seine Distanzwaffe in der Haupthand und hat gar keine Nebenhand - der Hinweis war ein Mangel, den er nicht beheben konnte. Ein Caster mit Zauberstab bekommt ihn weiterhin, denn der hat eine.",
            "Der Clear-Status ist charakterbezogen. Ein Lockout gehoert dem Charakter, nicht dem Konto: der Main hat Immerseus gelegt, der Twink steht am Mittwoch trotzdem vor einem vollen Raid. Bisher sah jeder Twink den Stand des zuletzt gespielten Charakters. Die vorhandenen Daten wandern einmalig auf den gerade eingeloggten Charakter.",
        },
    },
    {
        version = "2.3.1.0",
        date    = "21.08.2026",
        notes   = {
            "Einem korrekt verzauberten Elementarschamanen wurde seine Stiefelverzauberung als Mangel gemeldet (\"Fuesse: Verzauberung nicht ideal -> Pandarenpfoten\"). In MoP stehen fuer die Stiefel zwei gleich vertretbare Verzauberungen zur Wahl: 140 Meisterschaft plus Lauftempo gegen 175 Tempo. Welche besser ist, haengt an Tempo-Breakpoints, die das Addon nicht kennen kann. Beide stehen jetzt in der Liste - wer eine davon traegt, liest \"Optimal\".",
            "Pandarenpfoten stand mit 175 statt 140 Meisterschaft in der Datenbank. Wer sie trug, bekam deshalb zusaetzlich \"schwaechere Stufe\" zu lesen - eine Beanstandung an einer Verzauberung, an der nichts auszusetzen war.",
            "25 Spec-Profile empfahlen fuer die Fuesse etwas, das ihren eigenen Gewichten widersprach - der falsche Wert von oben steckte dahinter. Alle Stiefellisten sind neu gesetzt; drei Handschuh-Listen standen verkehrt herum (Heilig-Paladin, Nebelwirker, Blut-Todesritter).",
            "Der Kopf des Ausruestungs-Checks sagte \"Alles versorgt\" und \"nichts offen\", waehrend darunter ein Punkt stand. Gezaehlt wurden nur Maengel, angezeigt wurden auch Hinweise. Jetzt heisst die Karte \"Feinabstimmung\", wenn es nur Hinweise gibt, und der Kopf nennt sie beim Namen.",
        },
    },
    {
        version = "2.3.0.1",
        date    = "20.08.2026",
        notes   = {
            "Ein gelber Stein galt in einem blauen Sockel als \"Optimal\" - und darueber stand, der Sockelbonus sei genutzt. Ein gelber Stein aktiviert keinen blauen Sockel. Bewertet wurde nach der Farbe des STEINS statt nach der des SOCKELS; jetzt zaehlt der Sockel, und ein farblich nicht passender Stein ist nie optimal, solange der Bonus sich lohnt.",
            "Die Zeile \"Sockelbonus\" sagte die Empfehlung und klang wie eine Tatsache. Sie liest den Zustand jetzt an den angelegten Steinen ab (\"aktiv (Farben passen)\" / \"nicht aktiv - Steinfarbe passt nicht zum Sockel\") und nennt die Empfehlung getrennt davon.",
            "Am Trefferkap widersprachen sich Entscheidung und Empfehlung: die eine riet zum Farb-Matchen, die andere schlug den reinen Kritstein vor. Die Sockelbonus-Entscheidung rechnet jetzt mit gecappten Werten - beim Furor-Krieger mit blauem Sockel und +60 Staerke kostet Matchen 8.400 Wertung und bringt 6.000, der reine Kritstein gewinnt also.",
            "Die Meldung \"Verzauberungs-ID 4416 (Handgelenke) passt nicht zur Datenbank\" war ein Fehlalarm. Nennt der Client eine Verzauberung nur beim Namen und kennen wir diesen Namen nicht, ist das kein Widerspruch, sondern eine Luecke in unserer Namenspflege - die Zeile sagt das jetzt leise, statt einen Mangel zu behaupten.",
            "Handgelenks-Beweglichkeit stand mit 170 statt 180 in der Datenbank.",
            "/wc vz nennt bei jedem Stein Steinfarbe und Sockelfarbe.",
        },
    },
    {
        version = "2.3.0.0",
        date    = "19.08.2026",
        notes   = {
            "\"Anmeldungen abrufen\" holte nie neue Daten - es konnte gar nicht. Der Knopf macht ein /reload, und WoW schreibt seine gespeicherten Variablen dabei ZUERST zurueck und liest sie erst danach: die Zustellung der Companion war geloescht, bevor das Addon sie sehen konnte. Sie liegt jetzt zusaetzlich in einer Datei im Addon-Ordner, die WoW nur liest. Braucht WeintCompanion 2.3.0.",
            "Eigene Twinks standen an den Plaetzen echter Spieler. Das Addon trug beim Login ungefragt den eingeloggten Charakter in eine passende offene Anmeldezeile ein - dauerhaft und fuer das ganze Konto. Der Kalender lud danach den eigenen Twink ein und den echten Spieler nicht. Geraten wird hier nicht mehr.",
            "Gespeicherte Namenskorrekturen werden dafuer einmalig zurueckgesetzt und beiseitegelegt - es geht nichts verloren, aber die falschen waeren sonst nie wieder weggegangen.",
            "Der Kalender-Eintrag enthielt nur den Ersteller. C_Calendar.EventInvite laesst jeden Namen erst vom Server aufloesen; das Speichern im selben Durchlauf sicherte einen Termin ohne eine einzige Einladung, und jeder weitere Klick erzeugte einen weiteren leeren. Jetzt zweistufig: \"Einladungen vorbereiten\" verschickt und zaehlt die Bestaetigungen, der zweite Klick speichert.",
            "Namen, die der Server nicht findet, werden beim Namen genannt statt still zu fehlen.",
            "Die Anmeldeliste sagt jetzt, wie alt sie ist (\"Zugestellt 19.08. 14:20, vor 3 Stunden\") - bisher stand dort nur das Raiddatum, und ein zwei Wochen alter Stand sah aus wie ein frischer.",
        },
    },
    {
        version = "2.2.0.0",
        date    = "19.08.2026",
        notes   = {
            "WeakAuras, die jemand ueber die WeintCompanion fuer die Gilde freigegeben hat, tauchen hier von selbst auf - nach dem naechsten /reload stehen sie in derselben Liste wie die eigenen und die mitgelieferten. Braucht WeintCompanion 2.2.0.",
            "Jede Zeile sagt jetzt, welche der drei Herkuenfte gilt: \"WeintCodex\" (mit dem Addon geliefert), \"Companion\" (vom eigenen Schreibtisch) oder \"Gilde\" samt Autor. Der Unterschied ist genau der, den man braucht, wenn die Aura nicht stimmt.",
            "Die Inspektorspalte zaehlt beide Quellen getrennt, sobald es etwas zu zaehlen gibt.",
        },
    },
    {
        version = "2.1.0.0",
        date    = "18.08.2026",
        notes   = {
            "WeakAuras lassen sich jetzt ueber die WeintCompanion nachtragen, ohne dass ein Addon-Update noetig ist. In der Companion werden Name, Rubrik, Version, Beschreibung und der Export-String eingetragen; nach dem naechsten /reload steht die Aura hier in derselben Liste wie die mitgelieferten und wird mit demselben Knopf installiert. Braucht WeintCompanion 2.1.0.",
            "Auch eine vorhandene Aura laesst sich so ersetzen - mitgelieferte eingeschlossen. Bei gleicher Kennung gewinnt die zugestellte Fassung, statt daneben zu stehen.",
            "Jede Zeile der WeakAuras-Seite sagt jetzt, woher sie kommt: \"WeintCodex\" oder \"Companion\" samt Autor. Eine nachgetragene Aura sah bisher genau aus wie eine mitgelieferte.",
            "Das Addon meldet der Companion beim Login, welche Auren es kennt. Ohne diese Meldung koennte sie nur die Auren auflisten, die sie selbst angelegt hat - die mitgelieferten stecken als Lua-Dateien im Addon-Ordner und sind von aussen nicht zu sehen.",
        },
    },
    {
        version = "2.0.1.1",
        date    = "18.08.2026",
        notes   = {
            "Der Ausruestungs-Check las den Meisterschaftswert des Gegenstands als Verzauberung der Handgelenke: auf Armschienen mit \"+180 Staerke\" stand \"Meisterschaft\", samt Hinweis \"ID abweichend\" - und empfohlen wurde weiterhin die Staerke, die laengst drauflag. Ursache war der Namensabgleich: die Handgelenks-Verzauberung heisst schlicht \"Meisterschaft\", und dieses Wort steht auch in der Wertzeile des Gegenstands. Eine Zeile, die mit \"+Zahl\" beginnt, wird jetzt nie mehr ueber ihren Text erkannt, sondern nur noch ueber ihre Werte.",
            "Die Brustverzauberung \"Glorreiche Werte\" wird jetzt am Gegenstand selbst geprueft statt nur aus der Datenbank uebernommen - die Zeile \"+80 alle Werte\" war fuer den Parser bisher nicht lesbar, weshalb hinter jeder Brustruestung ein \"(?)\" stand.",
            "Handschuh-Verzauberungen: die IDs fuer \"Erstklassige Staerke\" und \"Ueberragende Meisterschaft\" standen falsch in der Datenbank. Korrekt verzauberte Handschuhe trugen deshalb die Marke \"ID abweichend\"; beide sind jetzt am Live-Client korrigiert.",
            "Sockelempfehlung fuer Waffen und Furor: Krit galt bisher als fast so wertvoll wie Staerke. Damit riet das Addon auf Gegenstaenden mit kleinem Sockelbonus zum Umsockeln auf den reinen Kritstein, obwohl Hybridstein + Sockelbonus rechnerisch ueberwiegen. In MoP bringt ein Sockel 160 Primaer- oder 320 Sekundaerwert - das Verhaeltnis stimmt jetzt, und der Bonus wird mitgenommen.",
            "Schutzkrieger (defensiv): Meisterschaft ist kritischer Block und damit der wichtigste Verteidigungswert nach Ausdauer - sie stand bisher hinter Parieren und Ausweichen. In gelben Sockeln wird deshalb nicht mehr ein reiner Ausweichstein empfohlen, sondern der gruene Meisterschafts-/Ausdauerstein, der den Sockelbonus ebenfalls haelt.",
        },
    },
    {
        version = "2.0.1.0",
        date    = "17.08.2026",
        notes   = {
            "Anmeldungen, zu denen der Bot keinen echten Charakternamen kennt, sind jetzt als solche zu erkennen. Bisher stand dort der Discord-Anzeigename - ingame gibt es den nicht, die Einladung lief ins Leere, und der Client meldete das nicht einmal. Auffallen konnte das damit fruehestens am leeren Kalender.",
            "In der Anmeldeliste steht so eine Zeile gedaempft mit Fragezeichen und dem Hinweis \"Discord-Name - kein Charakter\" statt in Klassenfarbe.",
            "Die Kalender-Vorschau zaehlt jetzt \"21 von 25\" statt \"25 gesamt\" und nennt, wie viele Zuordnungen offen sind - die angezeigte Zahl stimmt damit mit der Zahl der tatsaechlichen Einladungen ueberein.",
            "Der Kalender-Eintrag ueberspringt diese Zeilen und nennt sie beim Namen, statt eine Einladung abzuschicken, die nie ankommt.",
            "Nachtragen kann die Raidleitung dauerhaft in Discord mit \"/weintcharakter setzen\" (\"/weintcharakter liste\" zeigt vorab, wer noch offen ist) - oder wie bisher fuer den eigenen Client ueber das Stift-Symbol in der Anmeldeliste.",
            "Die Selbst-Erkennung des eigenen Charakters gab bei zwei Mitspielern derselben Klasse bisher auf. Steht fuer einen davon schon ein echter Name fest, kommt nur noch der ungeklaerte in Frage.",
        },
    },
    {
        version = "2.0.0.4",
        date    = "17.08.2026",
        notes   = {
            "Der Ausruestungs-Check las weiterhin einen Gegenstandswert als Verzauberung: auf Handschuhen mit exakt der empfohlenen \"Grosses Tempo\" stand \"+1.201 Meisterschaft\", auf dem Umhang mit \"Ueberragende kritische Trefferwertung\" stand \"+991 Parieren\" - beide nur als \"OK\" statt \"Optimal\" gewertet. Der Tooltip wird jetzt richtig gelesen, und beide Zeilen stehen auf \"Optimal\".",
            "Ursache war unter anderem, dass die Kurzformen des Clients (\"Meisterschaft\", \"Tempo\", \"Parieren\", \"kritischer Trefferwert\") gar nicht gelesen wurden - damit war jede Sekundaerwert-Verzauberung fuer den Werteabgleich unsichtbar. Das gilt auch fuer den Sockelbonus, der aus demselben Grund oft nicht erkannt wurde.",
            "Tausenderpunkte werden jetzt richtig gelesen: aus \"+1.201 Meisterschaft\" wurde bisher die Zahl 1, und damit sah ein Gegenstandswert aus wie eine Verzauberung. Umgeschmiedete Werte (\"+298 Parieren (Umgeschmiedet aus Waffenkunde)\") zaehlen ausserdem nie mehr als Verzauberung.",
            "Passt keine Tooltip-Zeile zu einem bekannten Eintrag, wird nicht mehr geraten - dann steht der Name aus der Datenbank da statt einer zufaelligen Gegenstandszeile.",
            "Neu: \"/wc vz zeilen\" gibt jede Tooltipzeile mit Farbe und gelesenen Werten aus. Damit laesst sich eine falsch gelesene Zeile kuenftig zeigen, statt sie zu erraten.",
            "Das Changelog-Fenster nach einem Update laesst sich jetzt scrollen (Mausrad oder Leiste) und waechst mit dem Text. Bei groesseren Changelogs lief der Text bisher unten aus dem Fenster heraus und war nicht mehr erreichbar.",
        },
    },
    {
        version = "2.0.0.3",
        date    = "17.08.2026",
        notes   = {
            "Der Ausruestungs-Check bewertet Verzauberungen jetzt nach ihren WERTEN, nicht mehr nur nach ID und Name. Wer eine korrekt verzauberte Ruestung trug, deren ID in unserer Tabelle falsch stand, bekam trotzdem \"nicht ideal\" zu lesen - dieser Fehler ist damit weg.",
            "Bringt die angelegte Verzauberung dieselben Werte wie die Empfehlung, zaehlt sie als optimal. Bringt sie mehr (Inschriftler-Schultern, Berufs-Exklusivvarianten), ebenfalls. Bringt sie weniger, steht jetzt \"schwaechere Stufe\" da statt eines unerklaerten \"nicht ideal\".",
            "Der Tooltip-Scan hielt gelegentlich den Primaerwert des Gegenstands selbst fuer die Verzauberung - auf einem Staerke-Teil mit Staerke-Verzauberung stand dann \"+1300 Staerke\" als Verzauberung in der Liste, samt Fehlermeldung im Chat. Die Zeilen werden jetzt gewichtet, die echte Verzauberung gewinnt.",
            "Dasselbe fuer Sockelsteine: fehlt ein Stein in unserer Datenbank, holt das Addon seine Werte direkt vom Spielclient, statt ihn als \"unbekannt\" durchzuwinken. Wertgleiche Steine unter anderer ID (Juwelier-Schliffe, umbenannte Steine) gelten als die Empfehlung.",
            "\"/wc vz\" nennt jetzt zu jeder Verzauberung und jedem Stein die gemessenen Werte und markiert, wo die Datenbank davon abweicht.",
        },
    },
    {
        version = "2.0.0.2",
        date    = "13.08.2026",
        notes   = {
            "Die Navigationsspalte war unbeschriftet - zu sehen waren nur zehn Symbole. Sie schreibt jetzt wieder aus, was sie oeffnet: Uebersicht, Bossguides, Raids, Kalender, WeintTV, Charakter, Academy, Materialien, WeakAuras, Import.",
            "\"Heute geplant\" auf der Startseite zeigte \"0/8\" und keine Bossnamen, auch nach einem Raidabend mit gelegten Bossen. Jetzt steht dort der echte Stand der laufenden ID (z.B. \"8/14 gelegt\") samt den naechsten offenen Bossen mit Namen.",
            "Die Werte-Summen der Ausruestung standen als \"+18<>056\" statt \"+18 056\" - das Trennzeichen der Tausenderstellen zerfiel beim Setzen in zwei ungueltige Haelften.",
            "Auf der Charakter-Uebersicht verdeckten die Schaltflaechen \"Verzauberungen oeffnen\" und \"Sockel oeffnen\" den Hinweis \"Scan bei Itemwechsel\" daneben.",
        },
    },
    {
        version = "2.0.0.1",
        date    = "13.08.2026",
        notes   = {
            "Umlaute in gesperrten Versalien wurden als leere Kaestchen gezeichnet (\"UEBERSICHT\", \"NAECHSTER RAID\", \"3 ENGPAESSE\") - die Sperrung trennte Bytes statt Zeichen und zerlegte damit jeden Umlaut. Aus demselben Grund endete gekuerzter Text auf der Startseite mit einem Kaestchen.",
            "Kleine Umlaute werden jetzt richtig zu grossen: aus \"Flaeschchen\" wurde vorher \"FLaeSCHCHEN\".",
            "Auf der Charakter-Uebersicht liefen die Kennzahlenkarten aus der Seite - \"Trefferwertung\" war abgeschnitten, \"Waffenkunde\" gar nicht zu sehen. Sie stehen jetzt in zwei Spalten: oben Verzauberungen und Sockel & Steine, darunter Trefferwertung und Waffenkunde.",
            "In der Materialtabelle fehlte der gelbe Balken - zu sehen waren nur gruen und rot. Die mittlere Stufe zeichnet wieder, und die leere Rille ist als leer erkennbar.",
        },
    },
    {
        version = "2.0.0.0",
        date    = "12.08.2026",
        notes   = {
            "Das Addon traegt die Designsprache von WeintCompanion 2.0: schwarze Flaechen, Karten ohne Rahmen, Bernstein nur noch dort, wo es etwas bedeutet.",
            "Die Navigation ist eine ausgeschriebene Spalte mit den Gruppen Raid, Charakter und Gilde - statt einer Leiste aus acht Symbolen, deren Bedeutung man raten musste.",
            "Die Startseite beantwortet den Abend statt das Menue: naechster Raid, was an deiner Ausruestung offen ist, welche Bosse anstehen und wie es um die Gildenbank steht.",
            "Die Unternavigation jeder Seite sitzt als Reiterleiste unter dem Titel; die rechte Detailspalte ist Teil der Seite geworden und erscheint nur, wenn es etwas zu zeigen gibt.",
            "Die Academy ist ein eigener Navigationspunkt und haengt nicht mehr in der Charakter-Unternavigation.",
            "Der Kalender hat eine Monatsansicht mit Terminen und Tagesdetails - das Einladungsformular bleibt daneben unveraendert erreichbar.",
            "Alle Seiten tragen denselben Kopf: Ueberzeile, Titel und Kennzahlen in einer Form. Vorher standen drei verschiedene Titelformen nebeneinander, sieben davon bernsteinfarben - Bernstein bleibt jetzt dem vorbehalten, was einen Zustand anzeigt.",
        },
    },
    {
        version = "1.3.3.3",
        date    = "11.08.2026",
        notes   = {
            "Der Ausruestungs-Check verlangte bei Tank-Kriegern und -Todesrittern nur 7,5% Waffenkunde statt der eigentlich noetigen 15% - wer den richtigen Wert hatte, wurde faelschlich zum Umsockeln aufgefordert.",
            "Bereits angelegte Verzauberungen mit Kategorie-Praefix im Tooltip (z.B. \"Schild - Grosses Parieren\") werden jetzt korrekt als optimal erkannt statt als \"nicht ideal\" gemeldet.",
        },
    },
    {
        version = "1.3.3.2",
        date    = "11.08.2026",
        notes   = {
            "Jedes Update bringt ab sofort seine eigene Aenderungsliste mit - der Text auf GitHub entsteht direkt aus diesem Changelog.",
            "Bisher wurden Releases teils mit leerem Notizfeld angelegt, wodurch die Companion unter \"Addon & Updates\" faelschlich \"Keine Aenderungen gefunden.\" zeigte.",
        },
    },
    {
        version = "1.3.3.1",
        date    = "11.08.2026",
        notes   = {
            "Das Addon meldet der Companion jetzt euren Ausruestungsstand: Gegenstandsstufe, Verzauberungen, Sockel und offene BiS-Plaetze.",
            "Damit sind \"Meine Charaktere\" und \"Vorbereitung\" auf dem Desktop nicht mehr leer — je Charakter ein Fortschrittsring und die konkreten Maengel.",
            "Bewertet wird weiterhin hier im Spiel, wo Spec-Profile, Caps und Sockelboni bekannt sind. Die Companion zeichnet nur — Spiel und Desktop koennen so nicht auseinanderlaufen.",
            "Gemeldet wird beim Betreten der Welt und nach jedem Ausruestungswechsel, aber nur wenn sich wirklich etwas geaendert hat. Braucht WeintCompanion 2.0.1.",
        },
    },
    {
        version = "1.3.3.0",
        date    = "10.08.2026",
        notes   = {
            "Academy und WeintTV zeigen jetzt den Charakter, mit dem ihr angemeldet seid — nicht mehr den, der zuletzt in der Companion ausgewaehlt war.",
            "Die Academy merkt sich die Auswertung je Charakter. Ein Twink sieht nicht mehr die Bewertung des Mains.",
            "Liegt fuer den angemeldeten Charakter nichts vor, steht das jetzt da — samt Name des zuletzt ausgewerteten Charakters, statt fremde Zahlen als eigene auszugeben.",
            "\"Nur ich\" in WeintTV findet euch auch bei abweichender Schreibweise (Realm-Zusatz, Gross-/Kleinschreibung) und sagt es, wenn es stattdessen den ganzen Raid zeigt.",
            "Das Addon meldet der Companion beim Login, wer angemeldet ist. Die Charakterauswahl auf dem Desktop folgt dem von selbst (WeintCompanion 1.7.0 noetig).",
        },
    },
    {
        version = "1.3.2.3",
        date    = "07.08.2026",
        notes   = {
            "Das Notizfeld der Bossguides hat jetzt einen Umschalter '1 Spalte / 2 Spalten' in der Kopfzeile.",
            "Wird das Feld zum ersten Mal zu voll, fragt es selbst nach, ob ihr zwei Spalten oder lieber Scrollen wollt.",
            "Beim Wechsel auf eine Spalte wandert Spalte 2 ans Ende von Spalte 1 - es geht nichts verloren.",
            "Groesseres Feld, Fokusrahmen, Platzhaltertext, Zeichenzahl und eine schmale Bildlaufanzeige statt der breiten Leiste.",
        },
    },
    {
        version = "1.3.2.2",
        date    = "07.08.2026",
        notes   = {
            "Notizfeld bei den Bossguides scrollt jetzt und ist zweispaltig fuer den schnellen Ueberblick.",
            "Schutzpaladin-BiS: fehlenden Ring 'Siegelring der Vergessenen Koenige' (Schaetze Pandarias) ergaenzt.",
        },
    },
    {
        version = "1.3.2.1",
        date    = "06.08.2026",
        notes   = {
            "WeakAura-String fuer 'SuO Bosspaket 01-08' auf v3.0.4 aktualisiert.",
            "WeakAura-String fuer 'SuO Bosspaket 09-14' auf v3.0.8 aktualisiert.",
        },
    },
    {
        version = "1.3.2.0",
        date    = "05.08.2026",
        notes   = {
            "Eine Uebungssitzung am Trainingsdummy zaehlt erst ab drei Minuten - alles darunter geht nicht mehr an die Companion.",
            "Eine kurze Kampfpause beendet die Sitzung nicht mehr: kommt der Kampf binnen 20 Sekunden zurueck, laeuft dieselbe Sitzung weiter.",
            "Die Fusszeile zeigt jetzt den Weg zur Mindestdauer ('01:12 / 03:00') und waehrend einer Pause den Countdown bis zum Abschluss.",
            "Bewertung und Einstellungen sind jetzt eine beschriftete Reiterleiste statt zweier einzelner Zeichen in der Kopfzeile.",
        },
    },
    {
        version = "1.3.1.0",
        date    = "04.08.2026",
        notes   = {
            "Neu: Der Rotationshelfer sortiert sich live um - was ihr gedrueckt habt, rutscht nach unten, die naechste Faehigkeit steigt auf.",
            "Jede Zeile sagt jetzt, warum sie da steht: 'Blutpest steht noch 14s', 'Wut 34/60', 'keine Unheilige Rune'.",
            "Neu: Grosse 'Jetzt'-Karte mit Tastenkuerzel und Vorschau auf die naechsten drei Faehigkeiten.",
            "Neu: Bewertungsseite mit Note (S bis E), Fehlgriffen und der Laufzeit eurer Dots.",
            "Die Bewertung ist rangbasiert: die zweitbeste Wahl gibt Teilpunkte, Traenke und Cooldowns zaehlen gar nicht mehr mit.",
            "Behoben: Waehrend der globalen Abklingzeit war die Liste rund anderthalb Sekunden lang leer.",
            "Alle 23 Schadensspecs ueberarbeitet - mehrere Listen waren unvollstaendig oder trugen alte Zauber-IDs.",
            "Neu: /wc training check meldet Zauber-IDs, die euer Client nicht kennt.",
        },
    },
    {
        version = "1.3.0.2",
        date    = "04.08.2026",
        notes   = {
            "Fix: Rotationstrainer stuerzte beim Ziehen am Titelbalken ab (SavedVariables-Tabelle wurde dort nicht angelegt).",
            "Fix: Unheilig-Todesritter-Prioritaetenliste im Rotationstrainer ergaenzt - Geisselstoss (Hauptschaden) fehlte komplett, Faeulnisschlag war faelschlich als einziger Filler eingetragen.",
        },
    },
    {
        version = "1.3.0.1",
        date    = "04.08.2026",
        notes   = {
            "Fix: Rotationstrainer erkennt jetzt auch die Trainingspuppen im Schrein der Zwei Monde/Sieben Sterne (NPC-IDs 67127 und 31146), nicht nur die alte Vanilla-Puppe aus den Hauptstaedten.",
        },
    },
    {
        version = "1.3.0.0",
        date    = "04.08.2026",
        notes   = {
            "Neu: Rotationstrainer - kleines, frei verschiebbares Fenster mit der Prioritaetenliste eurer Spec, live abgehakt bei jedem Zauber.",
            "Oeffnet sich automatisch am Trainingsdummy, oder manuell per /wc training (auch an jedem anderen Ziel).",
            "Verzahnt mit der Academy: an 3 Tagen in Folge mit guter Trefferquote geuebt, hakt WeintCompanion den passenden Trainingsplan-Punkt automatisch ab.",
            "Deckt alle 23 DPS-Specs ab (Single-Target, vereinfachte Prioritaet - kein volles Rotations-Solver).",
        },
    },
    {
        version = "1.2.0.0",
        date    = "04.08.2026",
        notes   = {
            "Neu: Zugriffsprofile - WeintCompanion fragt eure Discord-Rolle ab, danach richtet sich, welche Bereiche offenstehen.",
            "Neu: Das Addon verknuepft sich mit genau einer Community. Daten einer anderen Gilde werden abgewiesen statt vermischt.",
            "Gesperrte Bereiche bleiben sichtbar und nennen den Grund - sie verschwinden nicht einfach.",
            "Neu: /wc access zeigt euer Profil (Community, Rang, Freigaben), /wc access reset hebt die Verknuepfung auf.",
            "Ohne geliefertes Profil bleibt alles wie bisher offen - fuer die Rollenabfrage braucht es WeintCompanion ab 1.4.0.",
        },
    },
    {
        version = "1.1.0.0",
        date    = "03.08.2026",
        notes   = {
            "Verzauberungs-Check zaehlt die Nebenhand jetzt richtig: Schild und Beihand-Gegenstand galten bisher als nicht verzauberbar, deshalb stand dort immer 8/8.",
            "Neu: Schild-/Nebenhand-Verzauberungen (Grosses Parieren, Maechtige Intelligenz) und Ringverzauberungen fuer Verzauberer.",
            "Leere Nebenhand bei angelegter Einhandwaffe wird als Hinweis gemeldet.",
            "Neu: WeintTV im Addon - Tiefenanalyse des letzten Pulls (vermeidbarer Schaden, Wirkungsdauern, Aktivzeit, Laufwege, Cooldowns, Mechaniken).",
            "Neu: Academy unter Charakter - Bewertung, Trainingsplan und Lektionskatalog aus WeintCompanion.",
        },
    },
    {
        version = "1.0.0.5",
        date    = "03.08.2026",
        notes   = {
            "Loot-Logging greift jetzt nur noch dort, wo es hingehoert: in einer Raidinstanz, in einer Raidgruppe und nur bei aktiviertem Meisterlooter.",
            "Dungeons, Szenarien, Worldbosse und Loot ausserhalb von Instanzen werden nicht mehr an den Discord-Bot gemeldet.",
        },
    },
    {
        version = "1.0.0.4",
        date    = "03.08.2026",
        notes   = {
            "BiS-Daten korrigiert: Fuesse fuer Schutz-Paladin, Schutz-Krieger und Blut-Todesritter droppen bei den Dunkelschamanen (Sporen des Wolfsreiters), nicht bei den Schaetzen Pandarias bzw. Immerseus.",
        },
    },
    {
        version = "1.0.0.3",
        date    = "29.07.2026",
        notes   = {
            "Konsolidierungs-Release: alle bisherigen Aenderungen sind jetzt final auf main.",
            "Keine neuen Features gegenueber 1.0.0.0 - reiner Versions- und Release-Abschluss.",
        },
    },
    {
        version = "1.0.0.0",
        date    = "27.07.2026",
        notes   = {
            "Erster offizieller Release von WeintCodex.",
            "Neu: Kurze Addon-Tour beim ersten Start, Update-Popup mit Changelog bei neuen Versionen.",
            "Bossguides mit Positionierungsbildern und Best-in-Slot-Listen pro Spec.",
            "Materialtracking, Raidplanung und WeakAura-Verteilung ueber Companion-App und Discord-Bot.",
        },
    },
}
