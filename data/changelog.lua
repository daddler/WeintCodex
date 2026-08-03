--------------------------------------------------
-- WeintCodex :: Changelog-Daten
-- Wird von core/onboarding.lua fuer das Update-Popup genutzt.
-- Neueste Version zuerst! Bei jedem Release hier einen Eintrag
-- ergaenzen (parallel zu CHANGELOG.md) - siehe CLAUDE.md.
--------------------------------------------------

WeintCodex_ChangelogData = {
    {
        version = "1.0.1.0",
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
