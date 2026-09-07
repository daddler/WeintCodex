# Encounter-Fortschritt gehört dem Charakter (`modules/encounter_tracking.lua`)

Ein Schlachtzugs-Lockout ist in MoP an den einzelnen Charakter gebunden.
Bis 2.3.1.0 lag der Fortschritt kontoweit unter
`SavedData.encounterProgress[instanz]`; jeder Twink sah damit den Stand
des zuletzt gespielten Charakters. Der Lockout-Import konnte das nicht
heilen: `RefreshFromLockout` kennt nur „`isKilled` → `cleared = true`",
weil ein fehlender Lockout-Eintrag genauso gut „Server hat die Raid-Info
noch nicht geschickt" heissen kann — er setzt Kills, aber er nimmt keine
zurück.

Seit 2.4.0.0 liegt alles unter
`SavedData.encounterProgress.characters["Name-Realm"][instanz]`. Die alten
Zweige liegen direkt unter `encounterProgress` und sind **am Inhalt**
erkennbar (`bosses`/`resetStamp`), nicht an einer Merkerzahl — so bleibt
die Migration auch dann richtig, wenn eine alte und eine neue
Addonversion sich abwechseln. Sie wandern einmalig auf den gerade
eingeloggten Charakter und werden dann entfernt: „cleared" holt sich jeder
andere Charakter binnen Sekunden aus der Lockout-API zurück, die selbst
gezählten Wipes und der beste Versuch dagegen sind nirgends sonst
gespeichert und wären beim Wegwerfen endgültig weg. Ist der
Charaktername noch nicht bekannt (vor `PLAYER_LOGIN`), wird **nichts**
angelegt und nichts gelesen, statt einen namenlosen Topf zu füllen.

Der Fortschrittsbalken der Bossguides nennt im Tooltip den Charakter,
dessen Stand er zeigt — als Beschriftung passt der Name nicht in die
120 px neben dem Zitat, und ohne ihn ist „0 %" auf dem Twink nicht von
einem Fehler zu unterscheiden.

## Bossnotizen (`notes`-Block in `core/navigation.lua`)

Der `notes`-Inspector-Block ist das einzige frei beschreibbare Feld des
Addons und hat zwei Ansichten: einspaltig (`single`, langer Fliesstext)
oder zweispaltig (`columns`, schneller Überblick). **Welche davon passt,
entscheidet der Nutzer, nicht das Addon** — der Umschalter sitzt in der
Kopfzeile des Feldes, und beim ersten Überlaufen fragt eine einmalige
Einblendung *im Feld* nach. Die Wahl steht global in
`SavedData.bossNotesLayout`, das Ja/Nein der Rückfrage in
`SavedData.bossNotesAsked`.

Gespeichert wird pro Boss als `SavedData.bossNotes[boss] = { col1, col2 }`;
ältere Einträge sind ein blanker String und wandern beim ersten Schreiben
nach `col1`. **Invariante: im `single`-Modus darf `col2` nie gefüllt
sein.** `InspectorNotes` ruft deshalb bei jedem Aufbau *und* bei jedem
Wechsel auf `single` `mergeColumns()` auf, das `col2` ans Ende von `col1`
hängt — sonst läge Text unerreichbar in den SavedData.

**Geschrieben wird in `WeintCodex_SavedData`, nie in eine frisch angelegte
Tabelle daneben.** `SetBossNoteColumn` trug als Rückfallweg `if not
WeintCodex.SavedData then WeintCodex.SavedData = {} end` — und das ist
genau die Sorte Zeile, die nie auffällt: WoW sichert ausschliesslich die
Variablen aus der `.toc`, eine eigene Tabelle daneben wird beim Abmelden
nicht geschrieben. Der Nutzer tippt, das Feld zeigt seinen Text, und nach
dem nächsten Anmelden ist er weg — ohne Fehler, ohne Meldung, und von „ein
Update hat meine Notizen gelöscht" nicht zu unterscheiden. Aus demselben
Grund steigen beide Zugriffe ohne Bossnamen aus: `bossNotes[nil] = …` ist
ein Lua-Fehler.

**WoW schreibt seine SavedVariables erst beim Abmelden und bei `/reload`
auf die Festplatte.** Ein abgewürgter oder abgestürzter Client verliert
alles seit dem Anmelden; ein Addon kann das nicht abfangen. Auf der
Gegenseite darf deshalb auch nichts blind in dieselbe Datei schreiben —
WeintCompanion prüft seit 2.7.1 unmittelbar vor dem Ersetzen, ob WoW sie
zwischenzeitlich selbst geschrieben hat, und sichert bei jeder
Aktualisierung die SavedVariables mit ins Backup.

Zwei Umsetzungsdetails: die Bildlaufanzeige ist selbst gezeichnet (8 px)
statt `UIPanelScrollFrameTemplate` (26 px), verfügbar als `slim`-Schalter
an `WeintCodex.CreateScrollArea`; die EditBox löst ihren Fokus in `OnHide`
selbst — `ClearInspector` versteckt Widgets nur, und ein verstecktes Feld
mit Tastaturfokus würde die Bewegungstasten schlucken.
