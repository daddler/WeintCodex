# WeakAuras: zwei Quellen, eine Liste (`modules/weakauras.lua`)

Die Seite kennt seit 2.1.0.0 **zwei** Quellen und zeigt sie als eine Liste:
die mitgelieferten Auren aus `data/weakauras/*.lua` (`WeintCodex.WeakAuraData`,
im Addon-ZIP, ändern sich nur mit einem Release) und die von der Companion
zugestellten aus `SavedData.weakAuraLibrary` (Inbox-Nachricht
`weakaura_library`, voller Vertrag in `../../../WeintCompanion/docs/
weakaura-bridge.md`). Damit lässt sich eine Aura am Schreibtisch eintragen,
ohne dass jemand eine Lua-Datei anlegt, sie in die `.toc` einträgt, eine
Version schneidet und alle das Release installieren.

`WeintCodex.WeakAuras.Entries()` ist die eine Stelle, an der beide
zusammenkommen; `EntriesFor(category)`, `Catalog()` und die Anzeige lesen
ausschliesslich daraus. Vier Dinge daran sind nicht Geschmack:

- **Bei gleicher ID gewinnt die zugestellte Aura.** Genau darin besteht das
  Aktualisieren einer vorhandenen. Ein zugestellter Eintrag ohne eigenes
  `icon` erbt das der ersetzten — eine aktualisierte Zeile soll nicht
  plötzlich anders aussehen.
- **Die Companion kann die mitgelieferten Auren nicht sehen**, also meldet
  das Addon sie ihr (`ReportWeakAuraCatalog`, `weakaura_catalog`, lokal wie
  `character_report`/`character_sheet`, gesperrt bis Companion 2.1.0 über
  `CompanionAtLeast(2, 1)`). Der **Importstring ist nicht dabei**: das
  Krieger-Paket allein sind rund 56 kB.
- **Eine unbekannte Rubrik wird zu `utility`, nicht verworfen**
  (`NormalizeCategory`, dieselbe Regel wie `normalize_category()` drüben).
- **Die Zeile sagt, woher sie kommt** („WeintCodex" bzw. „Companion ·
  <Autor>").

Seit 2.2.0.0 hat die zweite Quelle **zwei Reichweiten**, und die Zeile sagt
welche: eine Aura vom eigenen Schreibtisch (`Companion · <Autor>`) oder
eine, die jemand über den Discord-Bot für die ganze Gilde freigegeben hat
(`Gilde · <Autor>`, grün). Getragen wird das vom optionalen Feld `scope`;
**fehlt es, gilt „vom eigenen Schreibtisch"** — eine ältere Companion
schickt es nicht. `Catalog()` meldet `guild` als dritten `origin`-Wert
zurück.

Seit 2.4.0.0 sagt jede Zeile ausserdem, **ob die Aura in WeakAuras schon
vorhanden ist** (grüner Haken ganz links, `InstallState`). Beantwortet wird
das an WeakAuras selbst (`WeakAuras.GetData` bzw. `WeakAurasSaved.displays`)
und nie an unserer Klickhistorie. Gebraucht wird dafür der Name, unter dem
WeakAuras die Aura führt, und der steht **im Importstring**, nicht in
unserer `name`-Spalte:

- **`waIds` des Eintrags** — für die mitgelieferten Auren einmal aus dem
  Importstring gezogen und in `data/weakauras/*.lua` hinterlegt (wie das
  geht, steht im Kopf von `data/weakauras/init.lua`: LibDeflate-
  Druckcodierung → roher Deflate-Strom → LibSerialize, darin folgt auf
  jeden Schlüssel `id` der Anzeigename; aufzunehmen sind nur die
  Wurzeleinträge). **Wird ein `string` getauscht, muss `waIds` mit** —
  vertippt man sich, verschwindet der Haken, statt dass ein falscher
  erscheint. Weil die Liste kuratiert ist und nur Wurzeleinträge enthält,
  müssen für „installiert" **alle** da sein.
- **Was der letzte Import über diese Seite tatsächlich angelegt hat** — die
  Differenz der Anzeigenliste vor/nach dem Klick, vermerkt in
  `SavedData.weakAuraPending` und aufgelöst beim nächsten Aufbau der Seite.
  Diese Liste enthält auch jede **Unter**aura des Pakets.

Ist WeakAuras gar nicht geladen, sagt die Zeile **nichts**. Dieselbe
Zurückhaltung bei der Version: „Aktualisieren" steht nur da, wo ein eigener
Installationsvermerk eine andere Fassung nennt als die angebotene.
`weakAuraInstalls`/`weakAuraPending` stehen aus demselben Grund wie
`weakAuraLibrary` nicht in `GUILD_KEYS`.

Die Zustellung wird nur beim Login/`/reload` gelesen —
`WeakAuras.Refresh()` deckt den Rest ab und braucht dafür
`WeintCodex.Navigation.CurrentTab()` (`activeTab` war eine Dateilokale).
`SavedData.weakAuraLibrary` steht bewusst **nicht** in `GUILD_KEYS`:
WeakAuras sind nicht gildenintern, dieselbe Entscheidung, wegen der
`IMPORT_FEATURE` in `modules/sync.lua` den Typ `WA` nicht listet. Jener
ältere Bot-Import bleibt unverändert und liegt unter einem eigenen
Schlüssel (`weakAuras`) — er trägt nur Metadaten und **keinen**
Importstring.
