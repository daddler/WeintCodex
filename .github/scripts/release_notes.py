"""
Den Changelog-Abschnitt eines Tags als Release-Text ausgeben - und
nebenbei prüfen, dass Tag, `.toc`, `core/main.lua` und `CHANGELOG.md`
dieselbe Fassung nennen.

    python3 .github/scripts/release_notes.py v1.3.3.2 > notes.md

**Warum es das gibt.** Die Releases dieses Addons wurden von Hand mit
leerem Notes-Feld angelegt. In WeintCompanion stand deshalb unter
"Addon & Updates" dauerhaft "Keine Änderungen gefunden." - und das war
nicht falsch, nur nutzlos: der Text des Releases *war* leer, obwohl
`CHANGELOG.md` und `data/changelog.lua` beide gepflegt sind.

Der Release-Text ist jetzt der Changelog-Abschnitt selbst. Damit sagt
GitHub, die Ingame-Meldung nach dem Update und die Änderungsansicht
der Companion dasselbe, aus einer Quelle.

Die Versionsprüfung sitzt hier mit drin, weil sie ohnehin dieselben
Dateien liest und weil ein Tag ohne Versionserhöhung genau die Art
Fehler ist, die still bleibt: das ZIP entsteht, die Installation
läuft, und der Update-Prüfer der Companion vergleicht danach für
immer eine Fassung, die sich selbst anders nennt. Dieselbe Begründung
wie bei `scripts/check_version.py` drüben in WeintCompanion.

Geprüft wird dabei auch die SCHREIBWEISE des Tags, und zwar
buchstäblich. Das Release 2.6.0.3 wurde von Hand als `v.2.6.0.3`
angelegt - ein Punkt zuviel. Hier fiel das nicht auf, weil
`normalize()` bewusst nur die Zahlen liest; der Changelog-Abschnitt
wurde gefunden, das ZIP gebaut, die Installation lief. Die Companion
vergleicht an dieser Stelle aber ZEICHENKETTEN: `normalize_version()`
in `core/companion_manager.py` entfernt ein führendes "v" und hält den
Rest gegen die Fassung aus dem `.toc`. Aus ".2.6.0.3" wird damit nie
"2.6.0.3" - und die Update-Prüfung meldete nach jeder Aktualisierung
erneut ein Update auf dieselbe Nummer. Der Tag muss deshalb genau "v"
plus die Fassung aus `WeintCodex.toc` lauten, und der ZIP-Name erbt
diese Schreibweise ohnehin mit.

Reines Python 3 ohne Abhängigkeiten - in der CI läuft es vor allem
anderen.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent.parent

HEADER_RE = re.compile(
    r"^##\s+\[?v?(\d[\w.]*)\]?\s*(?:[–—-]\s*(.+?))?\s*$"
)


def normalize(value: str) -> tuple[int, ...]:
    """
    "v1.3.3.1", "1.3.3.1" und "1.3.3" sind vergleichbar; fehlende
    Stellen zaehlen als 0.
    """

    numbers = [
        int(part)
        for part in re.findall(r"\d+", (value or "").strip().lstrip("vV"))
    ] or [0]

    while len(numbers) < 4:
        numbers.append(0)

    return tuple(numbers[:4])


def toc_version() -> str:

    text = (ROOT / "WeintCodex.toc").read_text(encoding="utf-8")

    match = re.search(r"^##\s*Version:\s*(\S+)", text, re.MULTILINE)

    return match.group(1) if match else ""


def lua_version() -> str:

    text = (ROOT / "core" / "main.lua").read_text(encoding="utf-8")

    match = re.search(
        r'WeintCodex\.Version\s*=\s*"([^"]+)"',
        text,
    )

    return match.group(1) if match else ""


def changelog_lua_version() -> str:
    """
    Der oberste Eintrag in `data/changelog.lua`.

    Er ist das, was der Spieler nach dem Update im Spiel zu sehen
    bekommt (`core/onboarding.lua`). Fehlt er, bleibt das Popup leer -
    unsichtbar in jedem Test, sichtbar bei jedem Nutzer.
    """

    text = (ROOT / "data" / "changelog.lua").read_text(encoding="utf-8")

    match = re.search(r'version\s*=\s*"([^"]+)"', text)

    return match.group(1) if match else ""


def section_for(text: str, version: str) -> str:

    wanted = normalize(version)

    collecting = False

    lines: list[str] = []

    for line in text.splitlines():

        match = HEADER_RE.match(line)

        if match:

            if collecting:
                break

            collecting = normalize(match.group(1)) == wanted

            continue

        if collecting:
            lines.append(line)

    return "\n".join(lines).strip()


def spelling_problem(tag: str, toc: str) -> str:
    """
    Die Zahlen stimmen - aber schreibt der Tag sie so, wie das `.toc`
    sie schreibt? Nur dann findet die Companion die installierte
    Fassung wieder (siehe Kopf dieser Datei).
    """

    if not toc:
        return ""

    expected = "v" + toc.strip()

    if tag.strip() in (expected, toc.strip()):
        return ""

    return (
        f"Schreibweise: der Tag lautet {tag}, erlaubt ist genau "
        f"{expected}. Die Zahlen stimmen - die Companion vergleicht "
        "hier aber die Zeichenkette (fuehrendes \"v\" ab, Rest gegen "
        "die Fassung im .toc). Jede andere Schreibweise heisst fuer "
        "sie dauerhaft \"Update verfuegbar\", und zwar auf dieselbe "
        "Nummer, die schon installiert ist."
    )


def problems_for(tag: str) -> list[str]:

    wanted = normalize(tag)

    found = []

    spelling = spelling_problem(tag, toc_version())

    if spelling:
        found.append(spelling)

    for label, value in (
        ("WeintCodex.toc (## Version)", toc_version()),
        ("core/main.lua (WeintCodex.Version)", lua_version()),
        ("data/changelog.lua (oberster Eintrag)", changelog_lua_version()),
    ):

        if not value:

            found.append(f"{label}: keine Fassung gefunden.")

            continue

        if normalize(value) != wanted:

            found.append(
                f"{label}: steht auf {value}, der Tag lautet {tag}."
            )

    return found


def main() -> int:

    tag = sys.argv[1] if len(sys.argv) > 1 else ""

    if not tag:

        print("Kein Tag uebergeben.", file=sys.stderr)

        return 1

    issues = problems_for(tag)

    body = section_for(
        (ROOT / "CHANGELOG.md").read_text(encoding="utf-8"),
        tag,
    )

    if not body:

        issues.append(
            f"CHANGELOG.md: kein Abschnitt fuer {tag}."
        )

    if issues:

        print(
            f"Tag und Repo passen nicht zusammen (Tag: {tag}):",
            file=sys.stderr,
        )

        for issue in issues:
            print(f"  - {issue}", file=sys.stderr)

        print(
            "\nJedes Release braucht seinen Changelog - in "
            "CHANGELOG.md (fuer GitHub und die Companion) UND in "
            "data/changelog.lua (fuer das Update-Popup im Spiel). "
            "Siehe CLAUDE.md.",
            file=sys.stderr,
        )

        return 1

    print(body)

    return 0


if __name__ == "__main__":

    raise SystemExit(main())
