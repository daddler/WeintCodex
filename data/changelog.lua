--------------------------------------------------
-- WeintCodex :: Changelog-Daten
-- Wird von core/onboarding.lua fuer das Update-Popup genutzt.
-- Neueste Version zuerst! Bei jedem Release hier einen Eintrag
-- ergaenzen (parallel zu CHANGELOG.md) - siehe CLAUDE.md.
--------------------------------------------------

WeintCodex_ChangelogData = {
    {
        version = "1.0.0.2",
        date    = "29.07.2026",
        notes   = {
            "Verzauberungen: Angelegte Verzauberungen werden jetzt zuverlaessig am Item-Tooltip erkannt. Bisher konnte eine falsch zugeordnete Verzauberungs-ID dazu fuehren, dass die falsche Verzauberung angezeigt und ausgerechnet die empfohlen wurde, die schon drauf ist.",
            "Sockel: Die Bonus-Rechnung kennt jetzt Mischfarben (Lila/Orange passen in Rot, Gruen/Lila in Blau) und beruecksichtigt Treffer-/Waffenkunde-Caps - Sockelboni wurden dadurch bisher zu oft verworfen.",
            "Sockel: Bewusst farblich unpassende Empfehlungen sind als (Off-Color) markiert. Jeder Stein passt in jeden Sockel; nur der Sockelbonus verlangt, dass ALLE Sockel farblich passen.",
            "Sockel: Echte Sockelreihenfolge aus dem Item-Tooltip - bei gemischtfarbigen Items stand der Stein bisher unter der falschen Sockelfarbe.",
            "Sockel: Eulen-Druiden, Schatten-Priester und Elementar-Schamanen bekommen jetzt den richtigen Stein ueber alle passenden Farblisten hinweg empfohlen (z.B. Geladener Dioptas fuer Blau).",
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
