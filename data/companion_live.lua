--------------------------------------------------
-- WeintCodex :: Companion-Zustellung (Live-Brücke)
--
-- DIESE DATEI SCHREIBT DIE COMPANION. Von Hand geändert wird sie
-- beim nächsten Abgleich wieder überschrieben; im Auslieferungsstand
-- ist sie leer.
--
-- Warum es sie gibt
-- ----------------
-- Der übliche Weg von der Companion ins Addon ist die SavedVariable
-- WeintCompanionInboxDB (siehe modules/companion.lua). Der hat einen
-- Konstruktionsfehler, der erst auffällt, wenn man ihn im laufenden
-- Spiel benutzt: WoW hält seine SavedVariables im Arbeitsspeicher,
-- schreibt sie bei /reload und beim Abmelden aus dem Speicher zurück
-- und liest sie erst DANACH wieder ein. Alles, was die Companion in
-- der Zwischenzeit in die Datei geschrieben hat, wird von diesem
-- Rückschreiben vernichtet - und zwar bevor das Addon es je zu sehen
-- bekommt.
--
-- Damit konnte "Anmeldungen abrufen" nie funktionieren: der Klick
-- löst ein /reload aus, das /reload überschreibt die Zustellung mit
-- dem Stand vom Login, und übrig bleibt genau das, was schon vorher
-- da war. Die Companion merkt sich zudem, was sie zuletzt zugestellt
-- hat, und schickt unveränderte Anmeldungen kein zweites Mal - die
-- Daten waren danach also nicht nur nicht angekommen, sondern weg.
--
-- Eine Lua-Datei im Addon-Ordner hat dieses Problem nicht: WoW führt
-- sie bei jedem /reload neu aus und schreibt sie niemals zurück. Sie
-- ist deshalb die einzige Richtung Companion -> Addon, die während
-- einer laufenden Sitzung überhaupt ankommen kann.
--
-- Format (von addon/live_bridge.py der Companion erzeugt):
--
--   WeintCodex_CompanionLive = {
--       ["writtenAt"]        = <Unixzeit der Zustellung>,
--       ["companionVersion"] = "<Version der Companion>",
--       ["queue"]            = { { ["type"] = ..., ["community"] = ...,
--                                  ["payload"] = ... }, ... },
--   }
--
-- Die Warteschlange trägt dieselben Nachrichtentypen wie die Inbox;
-- ProcessInbox() liest beide und bevorzugt diese hier, weil sie
-- jünger ist. Anders als die Inbox kann das Addon sie nicht leeren
-- (es schreibt keine Dateien) - deshalb merkt es sich in
-- SavedData.companionLive.lastStamp, welchen Stand es zuletzt
-- eingearbeitet hat, und lässt unveränderte Zustellungen still
-- liegen.
--------------------------------------------------

WeintCodex_CompanionLive = WeintCodex_CompanionLive or {
    writtenAt        = 0,
    companionVersion = "",
    queue            = {},
}
