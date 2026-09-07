# Onboarding-Tour & Update-Changelog (`core/onboarding.lua` + `data/changelog.lua`)

`core/onboarding.lua` zeigt neuen Nutzern beim allerersten Login eine
mehrseitige Feature-Tour (eine Seite pro Navigations-Tab) und bestehenden
Nutzern nach einem Versionswechsel ein Popup mit dem, was sich geändert
hat. Beide Modi teilen sich dasselbe Overlay-Fenster über
`WeintCodex.MainFrame`. Getrackt über
`WeintCodex.SavedData.onboarding.lastSeenVersion`: `nil` → volle Tour,
abweichend von `WeintCodex.Version` → Changelog-Popup mit allen Einträgen
seit der zuletzt gesehenen Version, gleich → nichts. Aufgerufen aus dem
`PLAYER_LOGIN`-Handler; `/wc tour` ruft die Tour manuell erneut auf.

`data/changelog.lua` (`WeintCodex_ChangelogData`, neueste Version zuerst)
ist eine separate, laufzeit-lesbare Kurzfassung von `CHANGELOG.md` – beide
müssen bei jedem Release von Hand gepflegt werden.

Seit 3.0.0.0 ist die Tour **vollständig** und in Kapiteln (`chapter` am
Schritt). Zwischen 1.0 und 2.10 kamen Ausrüstungsberatung, Gruppencheck,
Ausrüstungs-Alarm, Rotationshelfer, Einkaufsliste und Einstellungsseite
dazu — die Tour sprach von keinem davon.

Drei Dinge daran sind nicht Geschmack:

- **`TOUR_EDITION` steht NEBEN `lastSeenVersion`, nicht darin.** Steigt
  sie, bekommen **alle** die Einführung noch einmal, auch Langzeitnutzer —
  ein Changelog-Popup beantwortet „was ist neu", nicht „was gibt es hier
  eigentlich alles". Zusammengelegt mit `lastSeenVersion` bekäme dagegen
  **jede** Version die volle Tour.
- **Vermerkt wird beim Zeigen, nicht beim Durchklicken.** `ShowTour()`
  schreibt die Fassung, nicht `Dismiss()`.
- **Die Texte folgen den Patchnote-Regeln** (siehe
  `../development/releases.md`): kein Dateiname, kein Funktionsname,
  kein SavedVariables-Schlüssel; Wirkung vor Ursache; Bernstein
  (`ColorText("gold", …)`) nur für das, worauf man klicken oder tippen
  kann. Sie duzen. **Wo ein Schalter vorkommt, stehen beide Richtungen und
  die Umkehrbarkeit** — sonst ist eine Frage ohne Antwort.
  `.github/tests/tour_test.lua` hält das fest, zusammen mit der
  Vollständigkeit der Tour.

**Der Textkörper ist ein Bildlauffeld, keine feste Fläche.** `SetBody()`
misst den Text, stellt die Fensterhöhe darauf ein (`WINDOW_H` …
`WINDOW_H_MAX`) und scrollt darüber hinaus — Reihenfolge: Text → gemessene
Höhe → Fensterhöhe → Höhe des Bildlaufinhalts. `bodyScroll.scrollBarHideable`
muss gesetzt bleiben, sonst blendet `ScrollFrame_OnScrollRangeChanged` die
Leiste bei Bildlaufweite 0 wieder ein.
