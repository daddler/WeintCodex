--------------------------------------------------
-- WeintCodex :: Changelog-Daten
-- Wird von core/onboarding.lua fuer das Update-Popup genutzt.
-- Neueste Version zuerst! Bei jedem Release hier einen Eintrag
-- ergaenzen (parallel zu CHANGELOG.md) - siehe CLAUDE.md.
--------------------------------------------------

WeintCodex_ChangelogData = {
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
