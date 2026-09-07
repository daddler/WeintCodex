# Releases

Two workflows in `.github/workflows/` build the distributable ZIP by
rsync-ing the repo (minus `.git`/`.github`/`README.md`/`LICENSE`) into a
`WeintCodex/` folder and zipping it:
- `Manual Release` (`workflow_dispatch`) creates the tag + GitHub release +
  ZIP in one step.
- `Pack and Attach Addon to Release` runs on `release: published` and
  attaches the ZIP to an already-created release.

Both pass tag/notes through `env:` rather than direct `${{ }}`
interpolation into shell — preserve that pattern if you touch these
workflows, it's there specifically to avoid shell injection via release
notes content.

## Invariant: the tag must be exactly `v` + the `.toc` version

**Der Tag muss buchstäblich `v` + die Fassung aus dem `.toc` heißen**
(`v2.6.0.3`, nicht `v.2.6.0.3`). Das Release 2.6.0.3 lag mit einem Punkt
zuviel vor: Changelog gefunden, ZIP gebaut, Installation lief — und die
Update-Prüfung der Companion meldete danach nach *jeder* Aktualisierung
erneut ein Update auf dieselbe Nummer. Sie vergleicht dort nämlich
**Zeichenketten** (`normalize_version()` in `core/companion_manager.py`
entfernt ein führendes „v" und hält den Rest gegen die Fassung im `.toc`),
während `release_notes.py` bewusst nur die Zahlen liest — also fiel es
hier nicht auf. Das Skript prüft die Schreibweise deshalb mit, und
**beide** Workflows rufen es als erste Station vor dem Bauen auf (bis
dahin lief es in `Manual Release` nur, wenn kein eigener Notes-Text
übergeben wurde); ein falsch geschriebener Tag bekommt gar kein ZIP mehr,
weil ein rotes Kreuz besser ist als ein stiller Kreislauf.

## Invariant: every release ships its changelog — this is not optional

**A release with an empty description is a bug, not a stylistic choice.**
The releases were once created by hand with the notes field left empty,
so the desktop app showed "Keine Änderungen gefunden." under *Addon &
Updates* forever — accurate (the release body really was empty) and
useless, because `CHANGELOG.md` was maintained all along.

So each version needs its entry in **three** places, and none of them
replaces another:

- **`CHANGELOG.md`** — the long form. It is what the GitHub release body
  is built from (`.github/scripts/release_notes.py`), and it travels
  **inside the addon ZIP** (the rsync excludes only
  `.git`/`.github`/`README.md`/`LICENSE`), which is how WeintCompanion's
  changelog view reads the *full* history of the installed addon without
  a network round. Headings are `## [1.3.3.1] – 2026-08-11`; the
  Companion's reader understands that shape and its own `## 2.0.1` shape,
  but nothing else.
- **`data/changelog.lua`** — the short form for the in-game update popup
  (`core/onboarding.lua`), newest first.
- **`WeintCodex.toc` + `core/main.lua`** — the version itself, in both
  places.

`.github/scripts/release_notes.py` enforces all four at once: it prints
the changelog section for the tag and **fails the release** if the
`.toc`, `core/main.lua`, `data/changelog.lua` or `CHANGELOG.md` disagree
with it. Run it locally before tagging:

```bash
python3 .github/scripts/release_notes.py v1.3.3.2
```

`Manual Release` uses its output whenever the `notes` input is empty;
`Pack and Attach` fills an empty body of an already-published release
from the same source and leaves a non-empty one alone.

## Patchnotes werden für Spieler geschrieben, nicht für dieses Repository

**Wer sie liest, kennt keine Dateinamen.** Die Notizen dieses Addons
wurden so geschrieben, wie im Rest dieses Repos gedacht wird — mit
Dateinamen, Funktionsnamen, SavedVariables-Schlüsseln und Sätzen über die
*Ursache* eines Fehlers statt über seine *Wirkung*. In diesem Repo ist das
genau richtig. Im Update-Popup nach dem Login, im Release-Text auf GitHub
und auf der Update-Karte der Companion steht dagegen ein Spieler, der
wissen will, ob ihn das betrifft und was er jetzt anders sieht.
„`headroom` speist jetzt auch die Treppe aus `data/breakpoints.lua`"
beantwortet keine der beiden Fragen.

Fünf Regeln für jeden Text, den ein Spieler zu sehen bekommt — also für
`data/changelog.lua` **und** für alles oberhalb von `### Technisch` in
`CHANGELOG.md`:

- **Kein Dateiname, kein Funktionsname, kein SavedVariables-Schlüssel.**
  Slash-Befehle (`/wc tempo`), Seiten- und Knopfnamen (*Werteverteilung &
  Caps*, *Automatisch*) sind ausdrücklich erlaubt: sie sind Bedienung,
  nicht Innenleben.
- **Wirkung vor Ursache.** Ein Eintrag beantwortet in dieser Reihenfolge:
  Was ging nicht (oder fehlte)? Was ist jetzt anders? Muss ich etwas tun?
  Die dritte Frage ist meistens mit „nein" beantwortet, und dann steht
  sie auch nicht da.
- **Kurze Sätze, ein Gedanke pro Zeile.** Kein Halbsatz, der zwei
  Gedanken über einen Gedankenstrich verbindet, und keine Verschachtelung
  über drei Zeilen.
- **Zahlen nur, wo man sie selbst sieht.** Eine Konstante, die im Spiel
  nirgends auftaucht, sagt niemandem etwas.
- **Die Kurzfassung ist kurz.** `data/changelog.lua` ist das, was im
  Spiel gelesen wird: höchstens fünf Zeilen je Fassung, jede für sich
  verständlich, hervorgehoben wird nur, worauf man klicken oder tippen
  kann.

Das Technische geht dabei **nicht** verloren, es rutscht nur nach unten:
`CHANGELOG.md` ist beides, Release-Text und Nachschlagewerk für die
Entwicklung, und `### Technisch` steht als letzte Überschrift eines
Abschnitts. Der Prüfstein ist immer derselbe: **würde jemand, der das
Addon nur spielt, nach diesem Satz wissen, ob ihn das betrifft?** Wenn
nicht, gehört er unter `### Technisch`.

Dieselbe Regel gilt drüben in WeintCompanion, und dort hängt seit deren
2.4.1 noch etwas daran: die Update-Karte zeigt über dem Knopf die Notizen
der Fassung, die **installiert** ist, beschriftet mit ihrer Nummer. Was
ein Update mitbringt, steht dort hinter *Alle Änderungen ansehen*. Für uns
heißt das: der Abschnitt einer Fassung wird nach dem Release nicht mehr
umgeschrieben — er ist ab dann der Text, den jeder Spieler mit dieser
Fassung vor sich hat.

## Working with this codebase (no build step)

There are no commands to run — verification happens by loading the addon
in-game (`/wc` or `/weintcodex` toggles the main window) and watching for
Lua errors. A local Lua 5.1 install (`luac5.1 -p <file>`) catches syntax
errors before that, which is worth doing for every changed file since
there's no other safety net. `WeintCodex.toc` defines load order; when
adding a new file it must be added there in the right place (libraries →
core → data → modules) or it silently won't load. Bump `## Version` in the
`.toc` and `WeintCodex.Version` in `core/main.lua` together when cutting a
release — the desktop Companion compares them against `SavedVariables` for
the update check.

`.github/tests/` holds the offline Lua test suite (`gem_plan_test.lua`,
`reforge_engine_test.lua`, `statweights_test.lua`, `qelive_test.lua`,
`enchant_scan_test.lua`, `tour_test.lua`, …), run with `lua5.1
.github/tests/<file>.lua .` — no game client needed. The folder lives
under `.github/` specifically so the release workflows' rsync (which
excludes `.git`/`.github`) keeps it out of the shipped ZIP.
