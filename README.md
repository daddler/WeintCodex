# WeintCodex

Raid Guide & Guild Intelligence System für **World of Warcraft: Mists of Pandaria Classic** (Interface `50504`).

WeintCodex bündelt Bossguides, Raidplanung, Charakter-/Twink-Verwaltung, Gildenbank-Materialtracking und WeakAura-Verteilung in einem Addon-Fenster und hält sie über den Discord-Bot und die WeintCompanion-Desktop-App auf dem aktuellen Stand.

## Funktionen

- **Charakter** – Verzauberungen/Sockelsteine gegen die aktuelle Spec prüfen, Twinks verwalten
- **Bossguides** – Rollen-Tipps für alle Bosse, inkl. Positionierungsbildern und Best-in-Slot-Listen pro Spec
- **Raids** – Anmeldungen für Mittwochs- und Donnerstagsraid
- **Materialien** – Gildenbank-Übersicht nach Kategorien, gescannt oder per Bot-Import
- **Kalender** – Termine & Ingame-Einladungen
- **WeakAuras** – 1-Klick-Import nach Kategorie (Klassen, Raid-Encounter, Dungeon, Gearcheck, …)
- **Import** – Daten vom Discord-Bot importieren (Bossnotizen, Raidlisten, Materialien, WeakAuras)

Öffnen mit `/wc` oder `/weintcodex`.

## Ökosystem

WeintCodex ist Teil eines Dreiergespanns:

| Repo | Aufgabe |
|---|---|
| **WeintCodex** (dieses Repo) | Das Addon selbst (Lua), läuft im WoW-Client |
| **WeintCompanion** | Desktop-App: installiert/aktualisiert das Addon, verbindet es mit Discord |
| **WeintCodex Bot** | Discord-Bot-Backend: Rosterexport, Materiallisten, WeakAura-Verteilung |

Addon und Companion tauschen sich ausschließlich über die gemeinsame `SavedVariables`-Datei aus (`WeintCompanionDB` für ausgehende, `WeintCompanionInboxDB` für eingehende Nachrichten) – nie direkt über das Netzwerk. Der Discord-Bot generiert zusätzlich `WCIMPORT:`-Strings, die sich manuell über den Import-Dialog (`/wc import`) einfügen lassen, falls die Companion-App gerade nicht läuft.

## Installation

1. **Empfohlen:** WeintCompanion installieren und darüber verwalten – die App hält Addon-Version und Discord-Anbindung automatisch synchron.
2. **Manuell:** ZIP aus den [Releases](../../releases) herunterladen, Ordner `WeintCodex` nach `_retail_/Interface/AddOns` (bzw. den MoP-Classic-Client-Pfad) entpacken, Client neu starten oder `/reload` ausführen.

## Sprache

UI-Texte und Kommentare sind auf Deutsch, Lua-Bezeichner auf Englisch/gemischt.

## Für Entwickler

Es gibt keinen Build-Schritt, Paketmanager oder Testsuite – reines WoW-Addon-Lua, geladen über `WeintCodex.toc`. Details zu Architektur und Konventionen stehen in [`CLAUDE.md`](CLAUDE.md).

Syntaxfehler lassen sich vor dem Laden im Client mit `luac5.1 -p <Datei>` abfangen; das ist das einzige verfügbare Sicherheitsnetz, da es keine automatisierten Tests gibt.

## Lizenz

Kein offizieller Lizenztext vergeben; alle Rechte beim Autor.
