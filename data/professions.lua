--------------------------------------------------
-- WeintCodex :: Berufsvergünstigungen an der Ausrüstung
-- Mists of Pandaria Classic
--
-- Wer einen Beruf geskillt hat, bekommt in MoP dafür etwas an die
-- Ausrüstung, das sonst niemand bekommt. Nicht genutzt ist das eine
-- echte Lücke - und zwar eine, die man ohne Nachschlagen nicht sieht,
-- weil der Slot ganz normal aussieht. Genau dafür ist diese Tabelle da:
-- modules/gearalert.lua liest sie und meldet, was der Charakter dürfte
-- und nicht hat.
--
-- DIE WICHTIGSTE REGEL DIESER DATEI: **Kein Name und keine
-- Verzauberungs-ID daraus wird jemals verglichen.** Alle Namen hier
-- sind reiner Anzeigetext. Entschieden wird ausschliesslich über
-- Zählbares - liegt auf dem Slot überhaupt eine Verzauberung, ist der
-- Zusatzsockel belegt, wie viele Juwelierssteine stecken drin. Das ist
-- kein Verzicht, sondern die Lehre aus data/enchants.lua: die
-- Verzauberungs-IDs sind von Hand gepflegt, am Client nicht auflösbar
-- und von Blizzard mitten in MoP umbenannt worden. Eine Meldung, die
-- an so einer ID hinge, wäre eine Meldung über unsere Tabellenpflege.
-- Ein falscher Anzeigename hier kostet dagegen nichts weiter als ein
-- schiefes Wort in einem Hinweis.
--
-- VIER ARTEN VON VERGÜNSTIGUNG
--
--   exclusive  Ein Slot, den NUR dieser Beruf verzaubern kann. Liegt
--              nichts drauf, ist das ein Befund für sich - der normale
--              Ausrüstungscheck kennt den Slot gar nicht (der Gürtel
--              hat in MoP keine Verzauberung für alle anderen).
--   socket     Ein Zusatzsockel, den nur dieser Beruf anbringt. Wird
--              wie die Gürtelschnalle behandelt und hat dieselbe
--              Unschärfe: ein angebrachter, aber leerer Sockel ist vom
--              gar nicht angebrachten nicht zu unterscheiden, weil
--              GetItemStats nur die Sockel des Grundgegenstands kennt.
--              Deshalb lautet der Text "fehlt oder ist leer".
--   gems       Eine begrenzte Zahl berufseigener Steine (Juweliere).
--              Gezählt wird, wie viele davon wirklich stecken.
--   hint       KEIN eigener Befund, sondern ein Zusatz an einem, den
--              es ohnehin gibt. Handschuhe, Umhang, Handgelenke und
--              Schultern kann jeder verzaubern; ob dort die stärkere
--              Berufsvariante liegt, ist ohne verlässliche IDs nicht
--              zu beantworten - und "du könntest was Besseres tragen"
--              wäre die Meinung, die dieses Modul nicht äussert.
--              Fehlt die Verzauberung aber ganz, gehört der Hinweis
--              dazu, welche Möglichkeit der Beruf zusätzlich bietet.
--
-- ERWEITERN: Neuen Beruf über seine Skill-Line-ID (nicht über den
-- Namen - der Client ist lokalisiert) ergänzen. Die IDs stehen im
-- siebten Rückgabewert von GetProfessionInfo().
--------------------------------------------------

-- Ab dieser Fertigkeit gibt es die Vergünstigungen überhaupt. Wer den
-- Beruf gerade erst angefangen hat, kann nichts davon herstellen, und
-- eine Meldung darüber wäre ein Mangel, den er nicht beheben kann.
WeintCodex_ProfessionMinSkill = 500

WeintCodex_ProfessionPerks = {

    --------------------------------------------------
    -- Ingenieurskunst (202)
    --------------------------------------------------
    [202] = {
        name  = "Ingenieurskunst",
        perks = {
            -- Der Gürtel ist der Sonderfall: in MoP kann ihn ausser dem
            -- Ingenieur niemand verzaubern. Der normale Ausrüstungscheck
            -- führt für Slot 6 deshalb gar keine Verzauberungszeile
            -- (siehe EQUIP_SLOTS in modules/charakter.lua) - ohne diesen
            -- Eintrag bliebe die Lücke unsichtbar.
            { kind = "exclusive", slotId = 6,  slotName = "Taille",
              label = "Nitrobeschleuniger" },

            { kind = "hint", slotId = 10, slotName = "Hände",
              label = "Synapsenfedern" },
            { kind = "hint", slotId = 15, slotName = "Umhang",
              label = "Ingenieurs-Umhangbastelei (Fallschirm/Gleiter)" },
        },
    },

    --------------------------------------------------
    -- Schmiedekunst (164)
    --------------------------------------------------
    [164] = {
        name  = "Schmiedekunst",
        perks = {
            { kind = "socket", slotId = 10, slotName = "Hände",
              label = "Zusatzsockel (Schmiedekunst)" },
            { kind = "socket", slotId = 9,  slotName = "Handgelenke",
              label = "Zusatzsockel (Schmiedekunst)" },
        },
    },

    --------------------------------------------------
    -- Juwelenschleifen (755)
    --------------------------------------------------
    [755] = {
        name  = "Juwelenschleifen",
        perks = {
            -- MoP erlaubt zwei Schlangenaugen (Cataclysm waren es drei).
            -- Steht die Zahl falsch, ist der Text trotzdem ehrlich - er
            -- nennt beide Seiten ("1 von 2") statt ein Urteil.
            { kind = "gems", count = 2, label = "Schlangenauge" },
        },
    },

    --------------------------------------------------
    -- Verzauberkunst (333)
    --------------------------------------------------
    -- Die beiden Ringverzauberungen stecken schon im normalen Check:
    -- EQUIP_SLOTS markiert die Fingerslots mit `nurVerzauberer`, und
    -- ResolveEnchSlot nimmt sie ohne den Beruf aus der Wertung. Hier
    -- also bewusst nichts - ein zweiter Weg zur selben Aussage würde
    -- den Befund doppelt melden.

    --------------------------------------------------
    -- Schneiderei (197)
    --------------------------------------------------
    [197] = {
        name  = "Schneiderei",
        perks = {
            { kind = "hint", slotId = 15, slotName = "Umhang",
              label = "Stickerei (Lichtgewebe/Dunkelglühen/Schwertwache)" },
        },
    },

    --------------------------------------------------
    -- Lederverarbeitung (165)
    --------------------------------------------------
    [165] = {
        name  = "Lederverarbeitung",
        perks = {
            { kind = "hint", slotId = 9, slotName = "Handgelenke",
              label = "Fellbesatz" },
        },
    },

    --------------------------------------------------
    -- Inschriftenkunde (773)
    --------------------------------------------------
    [773] = {
        name  = "Inschriftenkunde",
        perks = {
            { kind = "hint", slotId = 3, slotName = "Schultern",
              label = "Geheime Inschrift" },
        },
    },
}

--------------------------------------------------
-- Welche Berufe hat der eingeloggte Charakter?
--------------------------------------------------
-- Rückgabe: { [skillLineId] = fertigkeit }. Abgleich über die
-- Skill-Line-ID und nie über den Namen - derselbe Grund wie bei
-- HasEnchanting() in modules/charakter.lua: der Client ist lokalisiert.
--
-- Nur die beiden Hauptberufe. Kochkunst, Erste Hilfe und Archäologie
-- geben nichts an die Ausrüstung.
function WeintCodex_GetProfessionSkills()
    local found = {}
    if type(GetProfessions) ~= "function"
       or type(GetProfessionInfo) ~= "function" then
        return found
    end

    local prof1, prof2 = GetProfessions()
    for _, index in ipairs({ prof1, prof2 }) do
        if index then
            local _, _, skill, _, _, _, skillLine = GetProfessionInfo(index)
            if skillLine then
                found[skillLine] = skill or 0
            end
        end
    end
    return found
end
