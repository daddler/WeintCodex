--------------------------------------------------
-- WeintCodex :: BossData
-- Standard-Daten (werden durch Import ergänzt)
-- Enthält: tips (tank/healer/dps), abilities, quote, kurz
--------------------------------------------------

WeintCodex_BossData = {

    ["Immerseus"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Verderbnis kann nur durch Läuterung überwunden werden.",
        portrait = "Media/Bosses/immerseus.tga",

        tank = {
            "Tankwechsel nach jedem Ätzenden Schlag.",
            "Immerseus immer vom Raid wegdrehen.",
            "Defensive Cooldowns für Ätzender Schlag verwenden.",
            "Nicht durch den Boss laufen.",
            "Während Wirbel freie Laufwege behalten.",
            "Boss mittig und ruhig positionieren.",
        },

        healer = {
            "Verseuchte Tropfen priorisieren.",
            "Raid-Schaden durch Aufbrausendes Sha stabilisieren.",
            "Innerhalb von 12 Metern zu geläuterten Tropfen stehen.",
            "Raid-CDs für chaotische Splitphasen aufheben.",
            "Spieler aus Sha-Pfützen schnell stabilisieren.",
        },

        dps = {
            "Sha-Tropfen priorisieren.",
            "Nah an sterbenden Tropfen stehen für den Schadensbuff.",
            "Wirbel konsequent ausweichen.",
            "Movement-CDs während Teilung nutzen.",
            "Pfützen platzsparend ablegen.",
        },

        abilities = {
            {
                name = "Ätzender Schlag",
                spellID = 143436,
                desc = "Massiver Frontalangriff mit stapelbarer Schattenschadenerhöhung.",
                color = {0.20, 0.60, 0.90},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Sickerndes Sha",
                spellID = 143281,
                desc = "Nahbereichsschaden um Immerseus.",
                color = {0.65, 0.25, 0.85},
                tag = { label = "Melee", color = "gold" }
            },
            {
                name = "Wirbel",
                spellID = 143309,
                desc = "Verderbte Wasserströme bewegen sich durch den Raum und stoßen Spieler zurück.",
                color = {0.30, 0.75, 1.00},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Sha-Blitz",
                spellID = 143295,
                desc = "Verursacht Schattenschaden und erschafft Sha-Pfützen.",
                color = {0.75, 0.30, 0.95},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Teilung",
                desc = "Immerseus zerfällt in Sha-Tropfen und verseuchte Tropfen.",
                color = {0.95, 0.75, 0.25},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Sha-Tropfen",
                spellID = 71603,
                desc = "Müssen zerstört werden, um Verderbnis zu reduzieren.",
                color = {0.90, 0.40, 0.25},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Verseuchte Tropfen",
                spellID = 71604,
                desc = "Müssen geheilt werden, um Verderbnis zu reduzieren.",
                color = {0.20, 0.90, 0.45},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Sha-Rückstände",
                spellID = 143459,
                desc = "Erhöhen den Schaden gegen weitere Sha-Tropfen.",
                color = {0.85, 0.55, 0.20}
            },
            {
                name = "Geläuterte Überreste",
                spellID = 143524,
                desc = "Stellen Mana wieder her und erhöhen Heilung.",
                color = {0.25, 1.00, 0.65}
            },
            {
                name = "Aufbrausendes Sha",
                spellID = 143498,
                desc = "Tropfen verursachen Raid-Schaden, wenn sie die Mitte erreichen.",
                color = {1.00, 0.25, 0.25}
            },
        },

        kurz = {
            tank = {
                "Tankwechsel nach jedem Ätzenden Schlag.",
                "Boss immer vom Raid wegdrehen.",
                "Def-CDs für Ätzender Schlag nutzen.",
            },

            healer = {
                "Verseuchte Tropfen priorisieren.",
                "Aufbrausendes Sha gegenheilen.",
                "Raid-CDs für chaotische Splitphasen.",
            },

            dps = {
                "Sha-Tropfen priorisieren.",
                "Wirbel ausweichen.",
                "Teilung effizient nutzen.",
            },
        },
    },

    ["Die gefallenen Beschützer"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Drei Beschützer. Ein Wille. Unterschätzt niemals die Macht der Verzweiflung.",
        portrait = "Media/Bosses/beschuetzer.tga",

        tank = {
            "Rook immer vom Raid wegdrehen.",
            "Bei Solarplexus umdrehen. Falls nicht geschafft, sofort spotten sobald möglich.",
            "Nicht in Rachsüchtige Schläge stehen.",
            "Bosspositionierung sauber halten.",
            "Geschändeten Boden aus dem Raid ziehen.",
            "Defensive Cooldowns für Rachsüchtige Schläge nutzen.",
            "Nicht mehrere Bosse gleichzeitig in Verzweifelte Maßnahmen bringen.",
        },

        healer = {
            "Raid-CDs für Dunkle Meditation vorbereiten.",
            "Spieler innerhalb der Meditationsfelder positionieren.",
            "Mal der Pein Ziel stabil halten.",
            "Schattenwort: Unheil überwachen.",
            "Katastrophe vorbereiten.",
            "Verzweifelte Maßnahmen frühzeitig einplanen.",
            "Spieler aus Sha-Explosion herausheilen.",
        },

        dps = {
            "Nicht mehrere Bosse gleichzeitig in Verzweifelte Maßnahmen bringen.",
            "Unterbrechungen für Verderbnisschock koordinieren.",
            "Bei Infernostoß zusammenstehen.",
            "Adds priorisieren.",
            "Giftflächen ausweichen.",
            "Manifestierte Emotionen schnell fokussieren.",
            "Burst-CDs für Verzweifelte Maßnahmen aufheben.",
        },

        abilities = {
            {
                name = "Band des Goldenen Lotus",
                spellID = 143497,
                desc = "Beschützer heilen sich gegenseitig, wenn nicht alle gleichzeitig besiegt werden.",
                color = {1.00, 0.85, 0.25},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Verzweifelte Maßnahmen",
                desc = "Beschwört Manifestationen mit zusätzlichen Fähigkeiten.",
                color = {0.95, 0.45, 0.20},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Rachsüchtige Schläge",
                spellID = 144396,
                desc = "Massiver kegelförmiger physischer Schaden.",
                color = {0.20, 0.60, 0.95},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Solarplexus",
                spellID = 12540,
                desc = "Macht das Ziel handlungsunfähig bis gespottet wird.",
                color = {0.25, 0.80, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Mal der Pein",
                spellID = 143812,
                desc = "Konstanter Schattenschaden und Bewegungsunfähigkeit.",
                color = {0.75, 0.30, 0.95},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Dunkle Meditation",
                spellID = 143745,
                desc = "Starker Raid-Schaden während Suns Manifestationsphase.",
                color = {0.40, 0.20, 0.80},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Katastrophe",
                spellID = 143491,
                desc = "Verursacht 30% maximale Gesundheit als Schaden.",
                color = {1.00, 0.25, 0.25},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Infernostoß",
                spellID = 143962,
                desc = "Massiver geteilter Feuerschaden.",
                color = {1.00, 0.50, 0.10},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Verderbnisschock",
                spellID = 144018,
                desc = "Muss unterbrochen werden.",
                color = {0.90, 0.20, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Manifestierte Emotionen",
                desc = "Beschworene Sha-Adds während Dunkle Meditation.",
                color = {0.65, 0.35, 0.85},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Sha-Explosion",
                spellID = 143423,
                desc = "Steigender Schattenschaden um das Ziel.",
                color = {0.80, 0.25, 0.90},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Zersetzendes Gift",
                spellID = 143239,
                desc = "Hinterlässt gefährliche Giftflächen.",
                color = {0.25, 0.85, 0.25},
                tag = { label = "Dodge", color = "gold" }
            },
        },

        kurz = {
            tank = {
                "Rook vom Raid wegdrehen.",
                "Solarplexus korrekt spielen.",
                "Rachsüchtige Schläge mit Def-CDs abfangen.",
                "Geschändeten Boden wegziehen.",
            },

            healer = {
                "Raid-CDs für Dunkle Meditation.",
                "Mal der Pein überwachen.",
                "Katastrophe vorbereiten.",
                "Sha-Explosion gegenheilen.",
            },

            dps = {
                "Verderbnisschock unterbrechen.",
                "Adds priorisieren.",
                "Infernostoß teilen.",
                "Keine doppelten Verzweifelte-Maßnahmen.",
            },
        },
    },

    ["Norushen"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Nur wer seine Verderbnis überwindet, kann die Wahrheit erkennen.",
        portrait = "Media/Bosses/norushen.tga",

        tank = {
            "Tankwechsel bei ca 4 Stapeln von Selbstzweifel.",
            "Blinder Hass permanent ausweichen.",
            "Verderbnis-Kugeln niemals den Boss erreichen lassen.",
            "Defensive Cooldowns für Entfesselter Zorn nutzen.",
            "Titanische Verderbnis frontal wegdrehen.",
            "Prüfung der Zuversicht sauber überleben.",
            "Geläuterte Tanks erleiden deutlich weniger Schaden.",
        },

        healer = {
            "Raid-CDs für niedrige Bossprozente einteilen.",
            "Anhaltende Verderbnis sofort dispellen.",
            "Spieler in Prüfungen stabil halten.",
            "Verbleibende Verderbnis schnell aufsammeln lassen.",
            "Geläuterte Spieler priorisieren.",
            "Eisige Angst wird mit sinkender Bossgesundheit gefährlicher.",
            "Raid während Zerfetzt stabil halten.",
        },

        dps = {
            "Prüfungen erfolgreich abschließen, um geläutert zu werden.",
            "Manifestationen priorisieren.",
            "Verderbnis-Kugeln ausweichen.",
            "Geläuterte DDs fokussieren den Boss.",
            "Nicht vor Manifestationen stehen.",
            "Adds schnell beseitigen.",
            "Üble Verbindung erhöht den Boss-Schaden erheblich.",
        },

        abilities = {
            {
                name = "Verderbnis",
                spellID = 114920,
                desc = "Je höher die Verderbnis, desto weniger Schaden verursacht der Spieler am Boss.",
                color = {0.75, 0.25, 0.90}
            },
            {
                name = "Geläutert",
                spellID = 146022,
                desc = "Spieler mit 0 Verderbnis erhalten starke Boni.",
                color = {0.20, 1.00, 0.60}
            },
            {
                name = "Entfesselter Zorn",
                spellID = 145214,
                desc = "Massiver körperlicher Schaden auf das aktuelle Ziel.",
                color = {0.20, 0.60, 0.95},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Selbstzweifel",
                spellID = 146124,
                desc = "Erhöht den Schaden von Entfesselter Zorn pro Stapel.",
                color = {0.30, 0.80, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Blinder Hass",
                spellID = 145226,
                desc = "Rotierende Verderbniszone mit tödlichem Schattenschaden.",
                color = {0.90, 0.20, 0.90},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Fusion",
                spellID = 145132,
                desc = "Verderbnis-Kugeln erhöhen den verursachten Schaden des Bosses.",
                color = {1.00, 0.50, 0.20}
            },
            {
                name = "Eisige Angst",
                spellID = 145733,
                desc = "Raid-Schaden steigt mit sinkender Bossgesundheit.",
                color = {0.20, 0.85, 1.00},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Zerfetzt",
                spellID = 146179,
                desc = "Beschwört Manifestationen der Verderbnis.",
                color = {0.95, 0.55, 0.25},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Blick nach innen",
                spellID = 144724,
                desc = "Spieler betreten ihre persönliche Prüfung.",
                color = {0.90, 0.80, 0.20},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Prüfung der Gelassenheit",
                spellID = 144849,
                desc = "DDs müssen Elemente der Verderbnis besiegen.",
                color = {0.80, 0.60, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Prüfung des Vertrauens",
                spellID = 144850,
                desc = "Heiler bekämpfen eine große Verderbnis.",
                color = {0.20, 0.90, 0.40},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Prüfung der Zuversicht",
                spellID = 144851,
                desc = "Tanks müssen titanische Verderbnis überleben.",
                color = {0.25, 0.65, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Realitätsriss",
                desc = "Frontaler Schattenschaden vor Manifestationen.",
                color = {0.70, 0.20, 0.95},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Verderbnis ausstoßen",
                spellID = 144649,
                desc = "Verderbnis-Kugeln fliegen durch den Raum.",
                color = {0.95, 0.35, 0.75},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Anhaltende Verderbnis",
                spellID = 144514,
                desc = "Muss innerhalb kurzer Zeit dispellt werden.",
                color = {0.30, 1.00, 0.50},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Titanischer Hieb",
                spellID = 144628,
                desc = "Massiver kegelförmiger Schattenschaden.",
                color = {0.20, 0.55, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Verderbnisschlag",
                spellID = 144654,
                desc = "Massiver Raid-Schaden während der Tank-Prüfung.",
                color = {1.00, 0.25, 0.25},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Durchdringende Verderbnis",
                spellID = 144657,
                desc = "Verursacht hohen Schaden und kann nicht absorbiert werden.",
                color = {0.85, 0.30, 0.30},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Verbleibende Verderbnis",
                spellID = 145073,
                desc = "Fügt konstanten Raid-Schaden zu, bis sie aufgenommen wird.",
                color = {0.85, 0.20, 0.85},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Üble Verbindung",
                spellID = 148974,
                desc = "Adds spiegeln Schaden auf den Boss.",
                color = {1.00, 0.75, 0.25},
                tag = { label = "DPS", color = "red" }
            },
        },

        kurz = {
            tank = {
                "Bei 4 Selbstzweifel spotten.",
                "Blinder Hass ausweichen.",
                "Kugeln vom Boss fernhalten.",
                "Entfesselter Zorn mit Def-CDs abfangen.",
            },

            healer = {
                "Anhaltende Verderbnis sofort dispellen.",
                "Raid-CDs für hohe Eisige-Angst-Stacks.",
                "Spieler in Prüfungen stabil halten.",
                "Verbleibende Verderbnis aufnehmen lassen.",
            },

            dps = {
                "Prüfungen erfolgreich abschließen.",
                "Manifestationen priorisieren.",
                "Nicht vor Realitätsriss stehen.",
                "Kugeln ausweichen und Adds töten.",
            },
        },
    },

    ["Sha des Stolzes"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Stolz ist die letzte Schwäche der Sterblichen.",
        portrait = "Media/Bosses/sha-des-stolzes.tga",

        tank = {
            "Tankwechsel bei 1 Stapel Verletzter Stolz.",
            "Boss niemals ohne Nahkampfziel lassen.",
            "Manifestationen sauber positionieren.",
            "Adds schnell übernehmen.",
            "Eigene Stolzwerte im Auge behalten.",
            "Manifestationen nicht im Raid sterben lassen.",
            "Defensive CDs für hohe Stolzphasen einteilen.",
        },

        healer = {
            "Dispells von Mal der Arroganz koordinieren.",
            "Raid-CDs für Wachsender Stolz nutzen.",
            "Spieler mit Aura des Stolzes isolieren.",
            "Gefängnis-Spieler schnell befreien.",
            "Heil-CDs für Entfesselt aufteilen.",
            "Hohe Stolzwerte besonders überwachen.",
            "Raid für Selbstreflexion stabilisieren.",
        },

        dps = {
            "Projektionen sofort ablaufen.",
            "Manifestationen priorisieren.",
            "Spöttische Explosion unterbrechen.",
            "Reflexionen ausweichen.",
            "Stolz möglichst niedrig halten.",
            "Gefängnisse schnell öffnen.",
            "Mit Gabe der Titanen für Macht der Titanen stacken.",
        },

        abilities = {
            {
                name = "Stolz",
                desc = "Zentrale Ressourcenmechanik des Kampfes.",
                color = {0.75, 0.25, 0.90}
            },
            {
                name = "Gabe der Titanen",
                spellID = 144359,
                desc = "Verleiht Immunität gegen Stolz.",
                color = {0.20, 0.90, 1.00}
            },
            {
                name = "Macht der Titanen",
                spellID = 144364,
                desc = "Erhöht Schaden, Heilung und Tempo.",
                color = {1.00, 0.85, 0.25}
            },
            {
                name = "Wachsender Stolz",
                spellID = 144400,
                desc = "Raid-Schaden bei voller Bossenergie.",
                color = {0.90, 0.25, 0.90},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Platzender Stolz",
                spellID = 144911,
                desc = "Explodierende Sha-Verderbnis.",
                color = {1.00, 0.35, 0.35},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Projektion",
                spellID = 145066,
                desc = "Spieler müssen ihre Projektion betreten.",
                color = {0.25, 0.75, 1.00},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Aura des Stolzes",
                spellID = 146817,
                desc = "Spieler verursachen AoE-Schaden um sich herum.",
                color = {0.80, 0.20, 0.80},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Überwältigt",
                spellID = 143498,
                desc = "Spieler bei 100 Stolz versursachen 50% mehr Schaden, werden aber übernommen.",
                color = {1.00, 0.10, 0.10},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Mal der Arroganz",
                spellID = 144351,
                desc = "Stapelbarer Schattenschaden-DoT.",
                color = {0.75, 0.30, 0.95},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Verletzter Stolz",
                spellID = 144358,
                desc = "Tanks erhalten zusätzlichen Stolz.",
                color = {0.20, 0.60, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Manifestation des Stolzes",
                desc = "Beschworene Adds mit Unterbrechungsmechanik.",
                color = {0.85, 0.55, 0.25},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Spöttische Explosion",
                spellID = 144379,
                desc = "Muss unterbrochen werden.",
                color = {1.00, 0.20, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Letztes Wort",
                spellID = 144370,
                desc = "Nahe Spieler erhalten Stolz beim Tod der Manifestation.",
                color = {0.90, 0.55, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Selbstreflexion",
                spellID = 144800,
                desc = "Erschafft explodierende Reflexionen.",
                color = {0.60, 0.20, 0.95},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Verderbtes Gefängnis",
                spellID = 144574,
                desc = "Spieler werden eingesperrt und müssen befreit werden.",
                color = {0.35, 0.80, 1.00},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Weitreichender Angriff",
                spellID = 119775,
                desc = "Das Sha greift entfernte Ziele an wenn sich kein Ziel in der Nähe befindet.",
                color = {0.30, 0.65, 1.00},
                tag = { label = "Melee", color = "gold" }
            },
            {
                name = "Entfesselt",
                spellID = 144832,
                desc = "Permanenter Raid-Schaden ab 30% Bossgesundheit.",
                color = {1.00, 0.25, 0.25},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Letztes Geschenk",
                spellID = 144854,
                desc = "Norushen setzt den Stolz aller Spieler zurück.",
                color = {0.20, 1.00, 0.70}
            },
        },

        kurz = {
            tank = {
                "Bei 1 Verletzter Stolz spotten.",
                "Boss nie ohne Nahkampfziel lassen.",
                "Manifestationen übernehmen.",
                "Stolzwerte kontrollieren.",
            },

            healer = {
                "Mal der Arroganz koordinieren.",
                "Raid-CDs für Wachsender Stolz.",
                "Gefängnisse schnell befreien.",
                "Entfesselt einteilen.",
            },

            dps = {
                "Projektionen sofort ablaufen.",
                "Spöttische Explosion kicken.",
                "Manifestationen priorisieren.",
                "Gefängnisse öffnen.",
            },
        },
    },

    ["Galakras"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Lasst den Himmel brennen!",
        portrait = "Media/Bosses/galakras.tga",

        tank = {
            "Knochenbrecher priorisieren und kontrollieren.",
            "Bogenhieb frontal vom Raid wegdrehen.",
            "Bei Ruf des Zermalmers schnell Abstand schaffen.",
            "Große Gegner sauber positionieren.",
            "Adds von Heilern fernhalten.",
            "Giftwolken aus dem Raid ziehen.",
            "Defensive CDs für große Add-Wellen einteilen.",
        },

        healer = {
            "Raid-CDs für Phase 2 einteilen.",
            "Türme während Bombardieren stabil halten.",
            "Spieler aus Giftwolken bewegen.",
            "Flammen von Galakrond gemeinsam abfangen.",
            "Gruppenschaden durch Add-Wellen vorbereiten.",
            "Pulsierende Flammen werden immer gefährlicher.",
            "Hohe Feuerschadensspitzen vorbereiten.",
        },

        dps = {
            "Totems sofort zerstören.",
            "Gezeitenschamanen unterbrechen.",
            "Flaggenträger priorisieren.",
            "Türme schnell säubern.",
            "Flammenflächen ausweichen.",
            "Geschütze schnell übernehmen.",
            "Add-Wellen effizient cleaven.",
        },

        abilities = {
            {
                name = "Mündungsfeuer",
                spellID = 147824,
                desc = "Massiver körperlicher Schaden mit Rückstoß.",
                color = {1.00, 0.35, 0.20},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Bogenhieb",
                spellID = 147688,
                desc = "Kegelförmiger körperlicher Schaden.",
                color = {0.25, 0.65, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Donnerknall",
                spellID = 6343,
                desc = "Verlangsamt Spieler im Nahbereich.",
                color = {0.75, 0.75, 1.00},
                tag = { label = "Melee", color = "gold" }
            },
            {
                name = "Ruf des Zermalmers",
                spellID = 146769,
                desc = "Spieler werden zu Thranok gezogen.",
                color = {1.00, 0.60, 0.20},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Schädelspalter",
                desc = "Extrem hoher Nahbereichsschaden.",
                color = {1.00, 0.15, 0.15},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Giftwolke",
                spellID = 147705,
                desc = "Giftfläche auf dem Boden.",
                color = {0.20, 0.90, 0.20},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Giftbenetzte Klingen",
                spellID = 146902,
                desc = "Stapelbarer Naturschaden.",
                color = {0.25, 0.80, 0.35},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Fluch des Giftes",
                spellID = 147711,
                desc = "Korgras letzte Phase mit starken Giftangriffen.",
                color = {0.15, 0.75, 0.15},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Fraktur",
                spellID = 146901,
                desc = "Knochenbrecher greifen Fraktionsanführer an. UNBEDINGT unterbrechen!",
                color = {0.30, 0.70, 1.00},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Totem der Heilungsflut",
                spellID = 108280,
                desc = "Heilt Gegner in der Umgebung.",
                color = {0.20, 1.00, 0.80},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Bombardieren",
                desc = "Belagerungsmaschinen bombardieren Türme.",
                color = {1.00, 0.55, 0.10},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Flammenstoß",
                spellID = 146787,
                desc = "Große Feuerfläche von Aethas.",
                color = {1.00, 0.45, 0.00},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Flammen von Galakrond",
                spellID = 147029,
                desc = "Feuerkugel, die durch Spieler abgeschwächt werden muss.",
                color = {1.00, 0.25, 0.00},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Pulsierende Flammen",
                spellID = 147042,
                desc = "Permanenter Raid-Schaden in Phase 2.",
                color = {1.00, 0.20, 0.20},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Flaggenträger des Drachenmals",
                desc = "Verstärkt Gegner mit Bannerbuffs.",
                color = {0.90, 0.80, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Gezeitenschamane des Drachenmals",
                desc = "Heilt Gegner und beschwört Totems.",
                color = {0.20, 0.90, 1.00},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Windhäscher des Drachenmals",
                desc = "Getarnte Assassinen greifen zufällige Spieler an.",
                color = {0.65, 0.25, 0.65},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Protodrache des Drachenmals",
                desc = "Kanalisieren Feueratem auf Spieler.",
                color = {1.00, 0.65, 0.15},
                tag = { label = "Raid", color = "red" }
            },
        },

        kurz = {
            tank = {
                "Knochenbrecher priorisieren.",
                "Bogenhieb vom Raid wegdrehen.",
                "Bei Ruf des Zermalmers weglaufen.",
                "Def-CDs für große Wellen nutzen.",
            },

            healer = {
                "Raid-CDs für Phase 2 aufheben.",
                "Bombardieren gegenheilen.",
                "Flammen von Galakrond abfangen.",
                "Pulsierende Flammen vorbereiten.",
            },

            dps = {
                "Totems sofort töten.",
                "Schamanen unterbrechen.",
                "Flaggenträger priorisieren.",
                "Türme schnell übernehmen.",
            },
        },
    },

    ["Eisener Koloss"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Die Kriegsmaschine der Kor'kron kennt keine Gnade.",
        portrait = "Media/Bosses/eiserner-koloss.tga",

        tank = {
            "Tankwechsel bei 2-3 Stapeln von Rüstungsschmelze.",
            "Boss immer vom Raid wegdrehen.",
            "Defensive Cooldowns für Flammendüsen nutzen.",
            "Erdbohrer ausweichen.",
            "Während Belagerungsmodus defensiv spielen.",
            "Nicht von Schockimpuls in Gefahrenzonen stoßen lassen.",
            "Belagerungsmodus für Heil-CDs vorbereiten.",
        },

        healer = {
            "Raid-CDs für Belagerungsmodus einteilen.",
            "Spieler mit Laserbrand priorisieren.",
            "Verteiltes Heilen während Verwüsterkanonen.",
            "Explodierenden Teer vorbereiten.",
            "Bewegung während Laserskalpell beachten.",
            "Seismische Aktivität wird schnell gefährlich.",
            "Spieler nach Minenexplosionen stabilisieren.",
        },

        dps = {
            "Kriecherminen kontrolliert detonieren.",
            "Mörserflächen ausweichen.",
            "Nicht durch Laserskalpell laufen.",
            "Teerflächen vermeiden.",
            "Für Schockimpulse richtig positionieren.",
            "Laserbewegungen frühzeitig erkennen.",
            "Während Belagerungsmodus maximalen Schaden fahren.",
        },

        abilities = {
            {
                name = "Erdbohrer",
                spellID = 144218,
                desc = "Aufbrechender Boden verursacht körperlichen Schaden.",
                color = {0.80, 0.55, 0.20},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Laserbrand",
                spellID = 144459,
                desc = "Feuerschaden mit zusätzlichem DoT.",
                color = {1.00, 0.35, 0.20},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Mörserkanone",
                desc = "Schrapnell-Explosionen auf zufälligen Spielern.",
                color = {1.00, 0.60, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Kriecherminen",
                desc = "Minen verfolgen Spieler und explodieren.",
                color = {1.00, 0.20, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Flammendüsen",
                spellID = 144464,
                desc = "Kegelförmiger Feuerschaden mit Debuff.",
                color = {0.20, 0.60, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Rüstungsschmelze",
                desc = "Erhöht den erlittenen Feuerschaden.",
                color = {0.30, 0.80, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Seismische Aktivität",
                spellID = 144557,
                desc = "Permanenter Raid-Schaden im Belagerungsmodus.",
                color = {0.90, 0.20, 0.90},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Schockimpuls",
                spellID = 144485,
                desc = "Stoßwelle mit starkem Rückstoß.",
                color = {1.00, 0.45, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Verwüsterkanonen",
                spellID = 144154,
                desc = "Mehrere Explosionen auf dem Schlachtfeld.",
                color = {1.00, 0.35, 0.35},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Laserskalpell",
                spellID = 144918,
                desc = "Verfolgender Laser mit hohem Feuerschaden.",
                color = {1.00, 0.15, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Explosiver Teer",
                spellID = 144498,
                desc = "Verlangsamende Teerflächen, die explodieren können.",
                color = {0.50, 0.35, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Belagerungsmodus",
                desc = "Der Boss verankert sich und nutzt Raid-Fähigkeiten.",
                color = {0.95, 0.75, 0.20},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Kampfmodus",
                desc = "Der Boss bewegt sich frei und nutzt Nahkampfangriffe.",
                color = {0.20, 0.90, 0.60},
                tag = { label = "Phase", color = "purple" }
            },
        },

        kurz = {
            tank = {
                "Bei 2-3 Rüstungsschmelze spotten.",
                "Boss vom Raid wegdrehen.",
                "Flammendüsen mit Def-CDs abfangen.",
                "Schockimpuls beachten.",
            },

            healer = {
                "Raid-CDs für Belagerungsmodus.",
                "Laserbrand priorisieren.",
                "Seismische Aktivität vorbereiten.",
                "Minenexplosionen gegenheilen.",
            },

            dps = {
                "Kriecherminen kontrollieren.",
                "Laserskalpell ausweichen.",
                "Teerflächen meiden.",
                "Im Belagerungsmodus DPS drücken.",
            },
        },
    },

    ["Dunkelschamanen"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Die Elemente selbst wurden von der Verderbnis verschlungen.",
        portrait = "Media/Bosses/schamanen.tga",

        tank = {
            "Tankwechsel bei 5 Stapeln von Froststurmschlag.",
            "Wölfe frontal vom Raid wegdrehen.",
            "Besudeltem Fluss ausweichen.",
            "Bosspositionierung sauber halten.",
            "Defensive CDs im Kampfrausch nutzen.",
            "Aschewälle nicht ungünstig platzieren.",
            "Bewegungswege für Tornados offen halten.",
        },

        healer = {
            "Raid-CDs für Toxischer Sturm nutzen.",
            "Spieler mit Giftigkeit überwachen.",
            "Ascheregen früh ausweichen.",
            "Gruppenheilung für Geysir-Phasen vorbereiten.",
            "Kampfrausch-Heilung einteilen.",
            "Raid nicht unnötig stacken.",
            "Hohe Naturschadensspitzen vorbereiten.",
        },

        dps = {
            "Tornados permanent ausweichen.",
            "Nicht in Schleim stehen.",
            "Ascheflächen früh verlassen.",
            "Movement-Fähigkeiten einteilen.",
            "Schadens-CDs im Kampfrausch nutzen.",
            "Freie Laufwege offen halten.",
            "Nicht von Tornados einschließen lassen.",
        },

        abilities = {
            {
                name = "Geistverbindung",
                spellID = 98021,
                desc = "Zugefügter Schaden wird zwischen beiden Bossen geteilt.",
                color = {0.20, 0.90, 1.00}
            },
            {
                name = "Kampfrausch",
                spellID = 71975,
                desc = "Erhöht Schaden und Tempo der Bosse.",
                color = {1.00, 0.20, 0.20},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Prankenhieb",
                spellID = 136463,
                desc = "Frontaler Angriff der Wölfe.",
                color = {0.25, 0.65, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Verwunden",
                spellID = 144304,
                desc = "Blutungseffekt auf dem Ziel.",
                color = {0.45, 0.75, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Froststurmschlag",
                spellID = 144215,
                desc = "Stapelt erhöhten Frostschaden auf dem Tank.",
                color = {0.30, 0.80, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Toxischer Nebel",
                spellID = 144089,
                desc = "Naturschaden auf mehreren Spielern.",
                color = {0.25, 1.00, 0.25},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Giftigkeit",
                spellID = 144107,
                desc = "Erhöht Naturschaden.",
                color = {0.35, 0.90, 0.35},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Besudelter Fluss",
                spellID = 144090,
                desc = "Verderbnisfluss mit hohem Schaden.",
                color = {0.55, 0.25, 0.85},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Aschewall",
                spellID = 144070,
                desc = "Beschwört Ascheelementare.",
                color = {1.00, 0.55, 0.10},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Froststurmblitz",
                spellID = 144214,
                desc = "Hoher Frostschaden auf ein Ziel.",
                color = {0.50, 0.85, 1.00},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Toxischer Sturm",
                spellID = 144005,
                desc = "Großer Naturschaden mit Tornados.",
                color = {0.20, 0.85, 0.20},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Toxischer Tornado",
                spellID = 144029,
                desc = "Beweglicher Tornado mit Naturschaden.",
                color = {0.20, 1.00, 0.50},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Besudelter Geysir",
                spellID = 143990,
                desc = "AoE-Schaden und Schleim-Spawn.",
                color = {0.70, 0.30, 0.90},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Besudelung",
                spellID = 144064,
                desc = "Naturschaden durch Schleime.",
                color = {0.60, 0.20, 0.80},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Ascheregen",
                spellID = 143973,
                desc = "Massiver Feuerschaden auf Einschlagspositionen.",
                color = {1.00, 0.15, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Giftnebeltotem",
                desc = "Verleiht den Schamanen neue Giftfähigkeiten.",
                color = {0.20, 0.80, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Totem des besudelten Flusses",
                desc = "Verleiht Fähigkeiten mit Verderbnis und Schleimen.",
                color = {0.60, 0.30, 0.90},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Ascheflammentotem",
                desc = "Verleiht Feuerfähigkeiten und Aschemechaniken.",
                color = {1.00, 0.50, 0.15},
                tag = { label = "DPS", color = "red" }
            },
        },

        kurz = {
            tank = {
                "Bei 5 Froststurmschlag spotten.",
                "Wölfe vom Raid wegdrehen.",
                "Besudelten Fluss vermeiden.",
                "Def-CDs für Kampfrausch aufheben.",
            },

            healer = {
                "Raid-CDs für Toxischer Sturm.",
                "Giftigkeit überwachen.",
                "Ascheregen ausweichen.",
                "Kampfrausch vorbereiten.",
            },

            dps = {
                "Tornados ausweichen.",
                "Nicht im Schleim stehen.",
                "Ascheflächen verlassen.",
                "CDs für Kampfrausch nutzen.",
            },
        },
    },

    ["General Nazgrim"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Ein wahrer Soldat kämpft bis zum letzten Atemzug.",
        portrait = "Media/Bosses/general-nazgrim.tga",

        tank = {
            "Tankwechsel bei 3-4 Stapeln von Zerreißender Schlag.",
            "Während Verteidigungshaltung Schaden reduzieren.",
            "Verheerer aus dem Raid wegziehen.",
            "Defensive CDs bei hohen Wutphasen nutzen.",
            "Adds sauber kontrollieren.",
            "Nazgrim niemals unnötig Wut generieren lassen.",
            "Boss zentral positionieren.",
        },

        healer = {
            "Raid-CDs für Kriegshymne einteilen.",
            "Spieler mit Knochenknacker priorisieren.",
            "Arkanwirker unterbrechen lassen.",
            "Raid aus Verheerer bewegen.",
            "Zusätzliche Add-Wellen vorbereiten.",
            "Hohe Wutphasen früh erkennen.",
            "Spieler mit ArkandoTs stabilisieren.",
        },

        dps = {
            "Banner sofort töten.",
            "Arkaner Schock und Mächtige Kettenheilung unterbrechen.",
            "Totem der Heilungsflut priorisieren.",
            "Assassinen schnell aufdecken.",
            "Während Verteidigungshaltung Boss-Damage reduzieren.",
            "Adds priorisieren statt Boss tunneln.",
            "Verheerer permanent ausweichen.",
        },

        abilities = {
            {
                name = "Zerreißender Schlag",
                spellID = 143494,
                desc = "Massiver Schlag mit stapelbarer Rüstungsreduktion.",
                color = {0.25, 0.65, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Knochenknacker",
                spellID = 143638,
                desc = "Blutung und verringerte Maximalgesundheit.",
                color = {1.00, 0.35, 0.35},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Kampfhaltung",
                spellID = 7165,
                desc = "Nazgrim erzeugt konstant Wut.",
                color = {0.20, 0.90, 0.60}
            },
            {
                name = "Berserkerhaltung",
                spellID = 143594,
                desc = "Mehr verursachter und erlittener Schaden.",
                color = {1.00, 0.25, 0.25},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Verteidigungshaltung",
                spellID = 71,
                desc = "Nazgrim erzeugt Wut durch Schaden.",
                color = {1.00, 0.80, 0.20},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Heldenhafte Schockwelle",
                spellID = 143716,
                desc = "Sprungangriff mit Nachbeben.",
                color = {1.00, 0.55, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Nachbeben",
                spellID = 143712,
                desc = "Feuerspalten auf dem Boden.",
                color = {1.00, 0.40, 0.10},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Banner der Kor'kron",
                spellID = 143501,
                desc = "Erzeugt zusätzliche Wut für Nazgrim.",
                color = {0.90, 0.90, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Kriegshymne",
                spellID = 143503,
                desc = "Massiver Raid-Schaden.",
                color = {0.90, 0.20, 0.90},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Verheerer",
                spellID = 143872,
                desc = "Wirbelnde Klinge mit dauerhaftem Flächenschaden.",
                color = {1.00, 0.15, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Verschnaufen",
                spellID = 143484,
                desc = "Nazgrim kann kurzzeitig keine Wutfähigkeiten einsetzen.",
                color = {0.20, 1.00, 0.80}
            },
            {
                name = "Eisensturm",
                spellID = 143420,
                desc = "Wirbelangriff der Eisenklingen.",
                color = {1.00, 0.60, 0.20},
                tag = { label = "Melee", color = "gold" }
            },
            {
                name = "Arkaner Schock",
                spellID = 143432,
                desc = "Stapelt erhöhten Arkanschaden.",
                color = {0.40, 0.70, 1.00},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Magiestoß",
                spellID = 143431,
                desc = "Arkane Explosion mit DoT.",
                color = {0.55, 0.75, 1.00},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Mächtige Kettenheilung",
                spellID = 143473,
                desc = "Große Heilung der Kriegsschamanen.",
                color = {0.20, 1.00, 0.40},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Totem der Heilungsflut",
                spellID = 108280,
                desc = "Heilt Gegner in der Umgebung.",
                color = {0.20, 1.00, 0.80},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Meucheln",
                spellID = 53,
                desc = "Assassinen verursachen massiven Schaden von hinten.",
                color = {0.70, 0.20, 0.70},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Erdschild",
                spellID = 974,
                desc = "Kriegsschamanen heilen Verbündete bei Schaden.",
                color = {0.40, 1.00, 0.40},
                tag = { label = "DPS", color = "red" }
            },
        },

        kurz = {
            tank = {
                "Bei 3-4 Zerreißender Schlag spotten.",
                "Verteidigungshaltung beachten.",
                "Verheerer wegziehen.",
                "Adds kontrollieren.",
            },

            healer = {
                "Raid-CDs für Kriegshymne.",
                "Knochenknacker priorisieren.",
                "ArkandoTs stabilisieren.",
                "Add-Wellen vorbereiten.",
            },

            dps = {
                "Banner sofort töten.",
                "Wichtige Zauber unterbrechen.",
                "Adds vor Boss priorisieren.",
                "In Verteidigungshaltung DPS stoppen.",
            },
        },
    },

    ["Malkorok"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Y'Shaarjs Macht fließt durch mich.",
        portrait = "Media/Bosses/malkorok.tga",

        tank = {
            "Tankwechsel direkt nach Fataler Stoß.",
            "Boss frontal vom Raid wegdrehen.",
            "Für Blutrausch defensiv vorbereiten.",
            "Stackpositionen für geteilten Schaden koordinieren.",
            "Bogenhieb-Flächen merken.",
            "Defensive Cooldowns mit Unerbittlicher Angriff abstimmen.",
            "Während Blutrausch sauber stacken.",
        },

        healer = {
            "Vor Schaden immer maximale Schilde aufbauen.",
            "Raid-CDs für Blutrausch einteilen.",
            "Spieler mit Verdrängte Energie verteilen.",
            "Implodierende Energie absichern.",
            "Barrieren konstant erneuern.",
            "Vor Blutrausch alle Spieler voll abschirmen.",
            "Raid-CDs mit steigenden Unerbittlicher Angriff Stapeln koordinieren.",
        },

        dps = {
            "Bogenhieb-Flächen merken und meiden.",
            "Implodierende Energie gezielt soak'en.",
            "Bei Verdrängte Energie Abstand halten.",
            "Nicht unnötig stacken.",
            "Movement für Seismischer Schlag bereithalten.",
            "Während Blutrausch korrekt stacken.",
            "Hauch von Y'Shaarj frühzeitig ausweichen.",
        },

        abilities = {
            {
                name = "Uraltes Miasma",
                spellID = 142861,
                desc = "Heilung wird in Absorptionsschilde umgewandelt.",
                color = {0.30, 0.90, 1.00},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Uralte Barriere",
                spellID = 142862,
                desc = "Absorbiert Schaden basierend auf Heilung.",
                color = {0.20, 1.00, 0.60},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Endlose Wut",
                spellID = 119446,
                desc = "Malkorok generiert kontinuierlich Wut.",
                color = {1.00, 0.75, 0.20}
            },
            {
                name = "Blutrausch",
                spellID = 142879,
                desc = "Extrem hoher geteilter Nahkampfschaden.",
                color = {1.00, 0.15, 0.15},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Verdrängte Energie",
                spellID = 142913,
                desc = "Spieler explodieren nach Ablauf des Debuffs.",
                color = {0.90, 0.25, 0.90},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Unerbittlicher Angriff",
                spellID = 143261,
                desc = "Erhöht Malkoroks Schaden nach jedem Blutrausch.",
                color = {1.00, 0.40, 0.20}
            },
            {
                name = "Bogenhieb",
                spellID = 142826,
                desc = "Großer kegelförmiger Angriff.",
                color = {0.25, 0.65, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Seismischer Schlag",
                spellID = 142851,
                desc = "Bodenschlag auf zufällige Spieler.",
                color = {0.80, 0.55, 0.25},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Hauch von Y'Shaarj",
                spellID = 142842,
                desc = "Explodiert vorherige Bogenhieb-Bereiche.",
                color = {0.75, 0.20, 0.95},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Implodierende Energie",
                spellID = 142986,
                desc = "Energierisse müssen aufgenommen werden.",
                color = {1.00, 0.55, 0.10},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Fataler Stoß",
                spellID = 142990,
                desc = "Stapelt erhöhten erlittenen Schaden.",
                color = {0.30, 0.80, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Eradikation",
                spellID = 143916,
                desc = "Berserk nach 6 Minuten.",
                color = {1.00, 0.00, 0.00}
            },
        },

        kurz = {
            tank = {
                "Nach jedem Fataler Stoß spotten.",
                "Boss vom Raid wegdrehen.",
                "Def-CDs für Blutrausch aufheben.",
                "Geteilten Schaden koordinieren.",
            },

            healer = {
                "Spieler dauerhaft abschirmen.",
                "Raid-CDs für Blutrausch.",
                "Implodierende Energie absichern.",
                "Verdrängte Energie überwachen.",
            },

            dps = {
                "Bogenhieb-Flächen merken.",
                "Implodierende Energie soak'en.",
                "Bei Verdrängte Energie Abstand halten.",
                "Blutrausch korrekt stacken.",
            },
        },
    },

    ["Die Schätze Pandarias"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Die größten Gefahren Pandarias lagen nicht immer auf dem Schlachtfeld.",
        portrait = "Media/Bosses/pandaria.tga",

        tank = {
            "Nicht zu viele Kisten gleichzeitig öffnen.",
            "Steinstatuen schnell kontrollieren.",
            "Große Gegner sauber positionieren.",
            "Wutanfall-Gegner defensiv spielen.",
            "Kegelangriffe vom Raid wegdrehen.",
            "Pandarengeister sauber positionieren.",
            "Große Kisten kontrolliert öffnen.",
        },

        healer = {
            "Nicht mehrere große Kisten gleichzeitig aktivieren.",
            "Dispells für Qual koordinieren.",
            "Raid-CDs für Pandarengeister nutzen.",
            "Gruppenheilung bei Kranichtritt vorbereiten.",
            "Heilung während Bombenphasen einteilen.",
            "Spieler aus Blutrote Rekonstitution bewegen.",
            "Raid-Schaden bei großen Pulls vorbereiten.",
        },

        dps = {
            "Bomben kontrolliert ablegen.",
            "Unterbrechungen koordinieren.",
            "Nicht zu viele Kisten gleichzeitig öffnen.",
            "Windhosen ausweichen.",
            "Prioritätsziele fokussieren.",
            "Ritualisten und Bernsteinpriester priorisieren.",
            "Pandarenwaffen-Buffs optimal nutzen.",
        },

        abilities = {
            {
                name = "Steinabbild",
                spellID = 145489,
                desc = "Beschwört gefährliche Steinstatuen.",
                color = {0.60, 0.60, 0.60},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Kraft des Steines",
                spellID = 145998,
                desc = "Erhöht den verursachten Schaden.",
                color = {0.25, 0.65, 1.00}
            },
            {
                name = "Scharfgemacht",
                spellID = 145996,
                desc = "Bomben auf Spielern explodieren nach Ablauf.",
                color = {1.00, 0.55, 0.15},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Pheromonwolke",
                spellID = 148762,
                desc = "Permanenter Naturschaden.",
                color = {0.20, 0.90, 0.20},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Materiewirbel",
                spellID = 145288,
                desc = "Vertauscht Spielerpositionen.",
                color = {0.70, 0.30, 0.90},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Blutrote Rekonstitution",
                spellID = 145271,
                desc = "Heilt Gegner in magieleeren Zonen.",
                color = {1.00, 0.20, 0.20},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Qual",
                spellID = 142983,
                desc = "Stapelnder Schattenschaden.",
                color = {0.80, 0.20, 0.80},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Mogurune der Kraft",
                spellID = 145458,
                desc = "Erhöht Tempo und Zaubergeschwindigkeit.",
                color = {1.00, 0.80, 0.20}
            },
            {
                name = "Verbotene Magie",
                spellID = 145230,
                desc = "Arkanschaden-Kanalisierung.",
                color = {0.40, 0.70, 1.00},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Rückstände",
                spellID = 145790,
                desc = "Heilt Gegner regelmäßig.",
                color = {0.20, 1.00, 0.60},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Windhose",
                spellID = 145286,
                desc = "Beweglicher Tornado.",
                color = {0.40, 0.90, 1.00},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Fleisch härten",
                spellID = 145218,
                desc = "Verlangsamt und verursacht Schaden.",
                color = {0.90, 0.50, 0.20},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Lebensfunke",
                spellID = 142694,
                desc = "Naturschaden-Aura und Nova.",
                color = {0.20, 1.00, 0.40},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Wehende Bombe",
                spellID = 145712,
                desc = "Explosive Bombe mit Windschaden.",
                color = {1.00, 0.40, 0.20},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Pheromonkapsel",
                spellID = 142524,
                desc = "Erzeugt schädliche Feuerpfützen.",
                color = {1.00, 0.25, 0.10},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Wutanfall",
                spellID = 145692,
                desc = "Massiv erhöhter Schaden der Kriegsrufer.",
                color = {1.00, 0.15, 0.15},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Feuerodem",
                spellID = 115181,
                desc = "Hoher Feuerschaden mit Desorientierung.",
                color = {1.00, 0.10, 0.10},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Stürmischer Kranichtritt",
                spellID = 146180,
                desc = "Großer Nahbereichs-AoE.",
                color = {0.25, 0.85, 1.00},
                tag = { label = "Melee", color = "gold" }
            },
            {
                name = "Blütenpfad",
                spellID = 146253,
                desc = "Explodierende Feuerblüten.",
                color = {1.00, 0.50, 0.10},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Klinge der hundert Schritte",
                spellID = 146068,
                desc = "Tankwaffen-Buff mit Blitzschlag und Betäubung.",
                color = {0.30, 0.70, 1.00}
            },
            {
                name = "Stab des resonierenden Wassers",
                spellID = 146099,
                desc = "Heilerwaffen-Buff mit heilender Welle.",
                color = {0.20, 1.00, 0.80}
            },
            {
                name = "Kralle der kochenden Wut",
                spellID = 146141,
                desc = "DD-Waffen-Buff mit zusätzlichem Feuerschaden.",
                color = {1.00, 0.60, 0.20}
            },
        },

        kurz = {
            tank = {
                "Nicht zu viele Kisten öffnen.",
                "Große Gegner kontrollieren.",
                "Wutanfall defensiv spielen.",
                "Pandarengeister positionieren.",
            },

            healer = {
                "Qual koordinieren.",
                "Raid-CDs für große Pulls.",
                "Kranichtritt vorbereiten.",
                "Bombenphasen absichern.",
            },

            dps = {
                "Bomben kontrolliert legen.",
                "Wichtige Casts unterbrechen.",
                "Prioritätsziele fokussieren.",
                "Buffwaffen optimal nutzen.",
            },
        },
    },

    ["Thok der Blutdürstige"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Die Jagd beginnt.",
        portrait = "Media/Bosses/thok.tga",

        tank = {
            "Tankwechsel bei 2-3 Atem-Stacks.",
            "Boss frontal vom Raid wegdrehen.",
            "Defensive CDs für hohe Kreischen-Stapel nutzen.",
            "Positionierung während Blutraserei vorbereiten.",
            "Nicht hinter Thok stehen.",
            "Eisgräber kontrollieren.",
            "Klaffende Wunden überwachen.",
        },

        healer = {
            "Raid-CDs für hohe Kreischen-Stapel einteilen.",
            "Spieler mit DoTs priorisieren.",
            "Positionierung während Blutraserei beachten.",
            "Heilung während Bewegungsphasen vorbereiten.",
            "Eisgräber schnell stabilisieren.",
            "Zauberunterbrechungen durch Kreischen einplanen.",
            "Raid bei Blutraserei beweglich halten.",
        },

        dps = {
            "Fixierte Spieler sauber kiten.",
            "Nicht hinter Thok stehen.",
            "Kreischen-Stapel beobachten.",
            "Eisgräber schnell zerstören.",
            "Movement-CDs für Blutraserei nutzen.",
            "Feuerflächen kontrolliert platzieren.",
            "Gefangene schnell befreien.",
        },

        abilities = {
            {
                name = "Fürchterliches Brüllen",
                spellID = 143426,
                desc = "Frontalangriff mit erhöhtem erlittenem Schaden.",
                color = {0.25, 0.65, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Ohrenbetäubendes Kreischen",
                spellID = 143343,
                desc = "Massiver Raid-Schaden mit Zauberunterbrechung.",
                color = {1.00, 0.20, 0.20},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Schwanzpeitscher",
                spellID = 23364,
                desc = "Betäubt Spieler hinter Thok.",
                color = {0.40, 0.80, 1.00},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Schockschlag",
                spellID = 143707,
                desc = "Naturschaden auf zufällige Spieler.",
                color = {0.20, 1.00, 0.40},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Klaffende Wunden",
                spellID = 143452,
                desc = "Kann Blutraserei auslösen.",
                color = {0.85, 0.25, 0.25},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Blutraserei",
                spellID = 143442,
                desc = "Thok verfolgt und verschlingt Spieler.",
                color = {1.00, 0.00, 0.00},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Fixieren",
                spellID = 133042,
                desc = "Thok verfolgt zufällige Spieler.",
                color = {1.00, 0.55, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Säureatem",
                spellID = 143780,
                desc = "Naturschaden mit Rüstungsreduktion.",
                color = {0.20, 0.90, 0.20},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Korrosives Blut",
                spellID = 143791,
                desc = "Naturschaden-DoT auf Spielern.",
                color = {0.25, 1.00, 0.25},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Frostatem",
                spellID = 143773,
                desc = "Frostschaden mit Eisstapeln.",
                color = {0.30, 0.80, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Eisiges Blut",
                spellID = 143800,
                desc = "Frost-DoT mit Eisgrab.",
                color = {0.60, 0.90, 1.00},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Eisgrab",
                desc = "Spieler werden bei 5 Froststapeln eingefroren.",
                color = {0.70, 0.95, 1.00},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Feueratem",
                spellID = 143767,
                desc = "Feuerschaden mit Brenneffekt.",
                color = {1.00, 0.40, 0.10},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Brennendes Blut",
                spellID = 82660,
                desc = "Feuerschaden und Feuerflächen.",
                color = {1.00, 0.25, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Eine Infusion der Säure",
                desc = "Thok erhält Säurefähigkeiten nach Akolik.",
                color = {0.20, 0.85, 0.20},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Eine Infusion des Frosts",
                desc = "Thok erhält Frostfähigkeiten nach Gorai.",
                color = {0.50, 0.85, 1.00},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Eine Infusion der Flammen",
                desc = "Thok erhält Feuerfähigkeiten nach Montak.",
                color = {1.00, 0.50, 0.15},
                tag = { label = "Phase", color = "purple" }
            },
        },

        kurz = {
            tank = {
                "Bei 2-3 Atem-Stacks spotten.",
                "Boss vom Raid wegdrehen.",
                "Def-CDs für hohe Kreischen-Stapel.",
                "Vor Blutraserei vorbereiten.",
            },

            healer = {
                "Raid-CDs für Kreischen.",
                "DoTs priorisieren.",
                "Eisgräber stabilisieren.",
                "Blutraserei vorbereiten.",
            },

            dps = {
                "Fixierte Spieler kiten.",
                "Eisgräber zerstören.",
                "Feuerflächen kontrollieren.",
                "Gefangene schnell befreien.",
            },
        },
    },

    ["Belagerungsingenieur Rußschmied"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Perfektion entsteht durch Feuer, Stahl und Explosionen.",
        portrait = "Media/Bosses/russschmied.tga",

        tank = {
            "Tankwechsel bei 3-4 Stapeln von Elektrostatische Aufladung.",
            "Schredder in gefährliche Mechaniken ziehen.",
            "Nach Tod von oben offensiv auf Schredder wechseln.",
            "Defensive CDs für hohe Aufladungsstapel nutzen.",
            "Sägeblätter kontrolliert positionieren.",
            "Schredder aus dem Reparaturstrahl bewegen.",
            "Schredder durch Supererhitzt und Sägeblätter beschädigen.",
        },

        healer = {
            "Raid-CDs für Überladung einteilen.",
            "Spieler bei Magnetische Presse stabilisieren.",
            "Kriecherminen kontrollieren.",
            "Movement während Waffenphasen vorbereiten.",
            "Heilung bei Sägeschnitt-Spikes bereit halten.",
            "Spieler auf Förderbändern separat beachten.",
            "Explosionsschaden von Minen vorbereiten.",
        },

        dps = {
            "Förderbandspieler vorher fest einteilen.",
            "Materieveredelungsstrahlen vermeiden.",
            "Kriecherminen kontrollieren und verlangsamen.",
            "Nicht unnötig durch Laserflächen laufen.",
            "Waffen priorisiert zerstören.",
            "Erschütterungsringe überspringen oder ausweichen.",
            "Nur eine Waffe pro Förderband zerstören.",
        },

        abilities = {
            {
                name = "Sägeblattschuss",
                spellID = 143291,
                desc = "Magnetisierte Sägeblätter bleiben auf der Plattform.",
                color = {0.70, 0.70, 0.70},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Sägeschnitt",
                spellID = 143327,
                desc = "Sägeblätter verursachen hohen Schaden.",
                color = {1.00, 0.25, 0.25},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Schützende Raserei",
                spellID = 116982,
                desc = "Rußschmied erhält erhöhtes Angriffstempo.",
                color = {1.00, 0.80, 0.20}
            },
            {
                name = "Elektrostatische Aufladung",
                spellID = 143385,
                desc = "Stapelt erhöhten Schaden auf dem Tank.",
                color = {0.25, 0.65, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Automatischer Reparaturstrahl",
                spellID = 144213,
                desc = "Heilt automatisierte Schredder.",
                color = {0.20, 1.00, 0.60},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Aufgeladene Verteidigungsmatrix",
                spellID = 148990,
                desc = "Reduziert erlittenen Schaden drastisch.",
                color = {0.30, 0.85, 1.00}
            },
            {
                name = "Reaktive Panzerung",
                spellID = 143387,
                desc = "Schredder erleiden weniger Schaden.",
                color = {0.40, 0.80, 1.00}
            },
            {
                name = "Tod von oben",
                spellID = 142232,
                desc = "Schredder springen und verursachen Flächenschaden.",
                color = {1.00, 0.40, 0.15},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Überladung",
                spellID = 145444,
                desc = "Raid-Schaden durch Schredder.",
                color = {0.90, 0.20, 0.90},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Das Fabrikationsband",
                desc = "Spieler zerstören Waffen auf dem Förderband.",
                color = {1.00, 0.75, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Transportröhren",
                desc = "Transportieren Spieler auf das Förderband.",
                color = {0.20, 0.90, 1.00},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Materieveredelungsstrahl",
                spellID = 144335,
                desc = "Tödliche Laser auf dem Förderband.",
                color = {1.00, 0.00, 0.00},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Erschütterungsrakete",
                spellID = 143639,
                desc = "Seismische Energieringe.",
                color = {1.00, 0.55, 0.10},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Supererhitzt",
                spellID = 143856,
                desc = "Laserflächen verursachen stapelbaren Schaden.",
                color = {1.00, 0.30, 0.10},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Magnetische Presse",
                spellID = 144466,
                desc = "Zieht Spieler und Sägeblätter an.",
                color = {0.60, 0.30, 1.00},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Detonation!",
                spellID = 143002,
                desc = "Explosion der Kriecherminen.",
                color = {1.00, 0.15, 0.15},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Aufwärmzeit",
                spellID = 145269,
                desc = "Kriecherminen sind kontrollierbar.",
                color = {0.20, 1.00, 0.40}
            },
            {
                name = "Warmgelaufen!",
                spellID = 145580,
                desc = "Kriecherminen werden immun gegen Kontrolle.",
                color = {1.00, 0.50, 0.20},
                tag = { label = "DPS", color = "red" }
            },
        },

        kurz = {
            tank = {
                "Bei 3-4 Aufladungsstapeln spotten.",
                "Schredder kontrollieren.",
                "Def-CDs für hohe Stapel.",
                "Schredder in Mechaniken ziehen.",
            },

            healer = {
                "Raid-CDs für Überladung.",
                "Magnetische Presse vorbereiten.",
                "Minenexplosionen gegenheilen.",
                "Förderbandspieler beachten.",
            },

            dps = {
                "Förderband sauber spielen.",
                "Waffen priorisieren.",
                "Laser und Raketen ausweichen.",
                "Kriecherminen kontrollieren.",
            },
        },
    },

    ["Die Getreuen der Klaxxi"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Die Stärksten der Klaxxi haben sich gegen Pandaria gewandt.",
        portrait = "Media/Bosses/klaxxi.tga",

        tank = {
            "Tankwechsel bei gefährlichen Debuff-Kombinationen.",
            "Aktive Mitigation gegen Injektion und Ätzendes Blut nutzen.",
            "Blutkreaturen kontrollieren.",
            "Bosspositionierung sauber halten.",
            "Defensive CDs für Verstümmeln nutzen.",
            "Frontalkegel von Korven wegdrehen.",
            "Auf Kombinationen aus Xaril und Kil'ruk achten.",
        },

        healer = {
            "Raid-CDs für Zielen einteilen.",
            "Giftfarben korrekt spielen.",
            "Verteilungsmechaniken koordinieren.",
            "Spieler mit Mutation stabilisieren.",
            "Feuerlinien früh positionieren.",
            "Spieler bei Schallprojektion vorbereiten.",
            "Gelbe Giftwolken vermeiden.",
        },

        dps = {
            "Prioritätsziele schnell fokussieren.",
            "Kunchongs kontrollieren.",
            "Bernparasiten sofort töten.",
            "Feuerlinien vermeiden.",
            "Boss-Reihenfolge sauber koordinieren.",
            "Bern auf Plattformen sinnvoll nutzen.",
            "Kunchongs während Verschlingen schnell brechen.",
        },

        abilities = {
            {
                name = "Empfohlene Killreihenfolge",
                desc = "Rik'kal > Skeer > Korven > Hisek > Xaril > Kaz'tik > Ka'roz > Iyyokuk > Kil'ruk",
                color = {1.00, 0.85, 0.20}
            },
            {
                name = "Entschlossenheit der Getreuen",
                spellID = 143483,
                desc = "Verbleibende Klaxxi verursachen mehr Schaden.",
                color = {1.00, 0.25, 0.25}
            },
            {
                name = "Kampfbereit",
                spellID = 143542,
                desc = "Markiert den nächsten eintretenden Klaxxi.",
                color = {1.00, 0.80, 0.20}
            },
            {
                name = "Macht der Getreuen",
                desc = "Spieler können Fähigkeiten besiegter Klaxxi übernehmen.",
                color = {0.20, 1.00, 0.60}
            },
            {
                name = "Geschlagen",
                spellID = 143275,
                desc = "Erhöht Schaden durch Rik'kal.",
                color = {0.25, 0.65, 1.00}
            },
            {
                name = "Aderlass",
                spellID = 138693,
                desc = "Beschwört heilende Blutkreaturen.",
                color = {0.90, 0.20, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Injektion",
                spellID = 143339,
                desc = "Naturschaden mit Parasiten-Spawn.",
                color = {0.20, 0.90, 0.20},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Mutation: Bernskorpion",
                desc = "Transformiert Spieler in einen Skorpion.",
                color = {1.00, 0.60, 0.20},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Bernparasiten",
                desc = "Parasiten greifen zufällige Spieler an.",
                color = {0.90, 0.45, 0.15},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Zielen",
                spellID = 142948,
                desc = "Geteilter Schuss durch den Raid.",
                color = {1.00, 0.15, 0.15},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Mehrfachschuss",
                spellID = 21390,
                desc = "Treffer auf mehrere Spieler.",
                color = {1.00, 0.45, 0.15},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Blitz",
                spellID = 143700,
                desc = "Ka'roz stürmt durch Spieler.",
                color = {0.30, 0.75, 1.00},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Wirbeln",
                spellID = 143701,
                desc = "Hoher Schaden entlang von Blitz.",
                color = {0.20, 0.60, 1.00},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Bern schleudern",
                spellID = 143733,
                desc = "Erzeugt ätzende Bernpfützen.",
                color = {0.85, 0.50, 0.20},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "In Bern einschließen",
                spellID = 142564,
                desc = "Boss heilt sich vollständig ohne Gegenmaßnahme.",
                color = {1.00, 0.30, 0.30},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Schildhieb",
                spellID = 35178,
                desc = "Betäubt den Tank.",
                color = {0.40, 0.80, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Heftiger Angriff",
                spellID = 143977,
                desc = "Mehrere schwere Frontalschläge.",
                color = {0.25, 0.55, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Schwächen",
                spellID = 143666,
                desc = "Reduziert prozentual die Gesundheit.",
                color = {0.80, 0.20, 0.80},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Wahnsinnige Berechnung: Brennendes Band",
                spellID = 142416,
                desc = "Feuerlinien verbinden Ziele.",
                color = {1.00, 0.35, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Toxische Injektion",
                spellID = 142528,
                desc = "Spieler erhalten farbige Toxine.",
                color = {0.20, 1.00, 0.40},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Ätzendes Blut",
                spellID = 142315,
                desc = "Stapelbarer Naturschaden.",
                color = {0.25, 0.90, 0.25},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Blutige Explosion",
                spellID = 142317,
                desc = "Raid-Explosion bei 10 Stapeln.",
                color = {1.00, 0.20, 0.20},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Katalysator wählen",
                desc = "Aktiviert unterschiedliche Giftreaktionen.",
                color = {0.20, 0.90, 0.60}
            },
            {
                name = "Hypnotisieren",
                spellID = 142671,
                desc = "Spieler werden zu Kunchongs gezogen.",
                color = {0.70, 0.25, 0.70},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Verschlingen",
                spellID = 142649,
                desc = "Kunchongs töten Spieler sofort.",
                color = {1.00, 0.00, 0.00},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Dicker Panzer",
                spellID = 142667,
                desc = "Hungrige Kunchongs sind immun gegen Schaden.",
                color = {0.70, 0.70, 0.70},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Häutung",
                spellID = 142651,
                desc = "Hungrige Kunchongs entwickeln sich weiter.",
                color = {0.85, 0.85, 0.25},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Schallprojektion",
                spellID = 143768,
                desc = "Schallwellen verursachen hohen Schaden.",
                color = {0.30, 0.80, 1.00},
                tag = { label = "Heal", color = "green" }
            },
            {
                name = "Solarplexus",
                spellID = 12540,
                desc = "Macht den Tank handlungsunfähig.",
                color = {0.30, 0.65, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Verstümmeln",
                spellID = 143941,
                desc = "Massiver Folgeschaden auf Tanks.",
                color = {1.00, 0.25, 0.25},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Tod von oben",
                spellID = 142232,
                desc = "Kil'ruk springt auf Spieler.",
                color = {1.00, 0.50, 0.15},
                tag = { label = "Dodge", color = "gold" }
            },
        },

        kurz = {
            tank = {
                "Bei Debuff-Kombinationen spotten.",
                "Def-CDs für Verstümmeln.",
                "Blutadds kontrollieren.",
                "Korven frontal wegdrehen.",
            },

            healer = {
                "Raid-CDs für Zielen.",
                "Giftfarben korrekt spielen.",
                "Feuerlinien koordinieren.",
                "Schallprojektion vorbereiten.",
            },

            dps = {
                "Killorder: Rik'kal -> Skeer -> Korven",
                "Hisek -> Xaril -> Kaz'tik",
                "Ka'roz -> Iyyokuk -> Kil'ruk",
                "Parasiten sofort töten.",
                "Kunchongs kontrollieren.",
                "Hypnotisieren schnell brechen.",
            },
        },
    },

    ["Garrosh Höllschrei"] = {
        instance = "Schlacht um Orgrimmar",
        quote    = "Ich werde die wahre Horde erschaffen!",
        portrait = "Media/Bosses/garrosh.tga",

        tank = {
            "Tankwechsel bei 3-4 Stapeln von Verzweiflung.",
            "Adds sauber kontrollieren.",
            "Minions getrennt töten.",
            "Boss korrekt für Entweihung positionieren.",
            "Defensive CDs für Phase 3 sparen.",
            "Explosive Verzweiflung außerhalb des Raids auslaufen lassen.",
            "Sha-Adds niemals nebeneinander töten.",
        },

        healer = {
            "Raid-CDs für Wirbelnde Verderbnis timen.",
            "MC-Spieler schnell kontrollieren.",
            "Tanks vor Explosive Verzweiflung stabilisieren.",
            "Übergänge vorbereiten.",
            "Raid in Phase 3 defensiv koordinieren.",
            "Spieler bei Sternexplosionen vorbereiten.",
            "Heil-CDs für mächtige Wirbelnde Verderbnis einteilen.",
        },

        dps = {
            "Ingenieure sofort fokussieren.",
            "Adds im Realm priorisieren.",
            "Mindcontrols schnell brechen.",
            "Waffen sauber platzieren.",
            "Adds kontrolliert töten.",
            "Nicht in Vernichten stehen.",
            "Sha-Adds getrennt voneinander töten.",
        },

        abilities = {
            {
                name = "Entweihung",
                spellID = 144748,
                desc = "Beschwört entweihte Waffen.",
                color = {0.75, 0.25, 0.90},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Entweihte Waffe",
                desc = "Erzeugt dauerhaft entweihten Boden.",
                color = {0.60, 0.20, 0.85},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Mächtige Entweihung",
                spellID = 144816,
                desc = "Selbstheilende entweihte Waffe.",
                color = {1.00, 0.25, 0.25},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Wirbelnde Verderbnis",
                spellID = 144985,
                desc = "Raidweiter Schattenschaden.",
                color = {0.90, 0.20, 0.90},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Mächtige wirbelnde Verderbnis",
                spellID = 145037,
                desc = "Spawnende Sha-Adds.",
                color = {1.00, 0.15, 0.15},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Diener von Y'Shaarj",
                desc = "Sha-Adds aus mächtiger Verderbnis.",
                color = {0.85, 0.40, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Stählende Verderbnis",
                desc = "Bufft nahe Sha-Adds beim Tod.",
                color = {1.00, 0.50, 0.15},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Y'Shaarjs Berührung",
                spellID = 145065,
                desc = "Gedankenkontrolle.",
                color = {0.30, 0.80, 1.00},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Y'Shaarjs mächtige Berührung",
                spellID = 145171,
                desc = "Verstärkte Gedankenkontrolle.",
                color = {1.00, 0.20, 0.20},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Fesselnde Verzweiflung",
                spellID = 145183,
                desc = "Stapelbarer Schattenschaden.",
                color = {0.25, 0.65, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Mächtige fesselnde Verzweiflung",
                spellID = 145195,
                desc = "Löst Explosive Verzweiflung aus.",
                color = {0.35, 0.75, 1.00},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Explosive Verzweiflung",
                spellID = 145199,
                desc = "Explosion abhängig von Stapeln.",
                color = {1.00, 0.25, 0.25},
                tag = { label = "Tank", color = "blue" }
            },
            {
                name = "Vernichten",
                spellID = 144969,
                desc = "Massiver Frontalangriff im Reich von Y'Shaarj.",
                color = {1.00, 0.10, 0.10},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Y'Shaarjs Schutz",
                spellID = 144945,
                desc = "Garrosh wird immun gegen Schaden.",
                color = {0.20, 1.00, 0.60},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Energie absorbieren",
                desc = "Garrosh sammelt Energie im Realm.",
                color = {1.00, 0.80, 0.20},
                tag = { label = "Phase", color = "purple" }
            },
            {
                name = "Kettenheilung der Ahnen",
                spellID = 144583,
                desc = "Muss unterbrochen werden.",
                color = {0.20, 1.00, 0.40},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Kettenblitzschlag",
                spellID = 103637,
                desc = "Springender Naturschaden.",
                color = {0.30, 0.90, 0.50},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Zorn der Ahnen",
                spellID = 144585,
                desc = "Unterbrechungen erhöhen Zaubertempo.",
                color = {1.00, 0.60, 0.20}
            },
            {
                name = "Höllschreis Kriegshymne",
                spellID = 73818,
                desc = "Bufft alle Adds massiv.",
                color = {1.00, 0.45, 0.15},
                tag = { label = "DPS", color = "red" }
            },
            {
                name = "Kollision mit dem eisernen Stern",
                spellID = 144653,
                desc = "Massiver Schaden durch Sterne.",
                color = {1.00, 0.00, 0.00},
                tag = { label = "Raid", color = "red" }
            },
            {
                name = "Explodierender eiserner Stern",
                spellID = 144798,
                desc = "Große Feuerexplosion.",
                color = {1.00, 0.35, 0.10},
                tag = { label = "Dodge", color = "gold" }
            },
            {
                name = "Kniesehne",
                spellID = 1715,
                desc = "Verlangsamt Spieler.",
                color = {0.60, 0.60, 0.60},
                tag = { label = "Tank", color = "blue" }
            },
        },

        kurz = {
            tank = {
                "Bei 3-4 Verzweiflung spotten.",
                "Explosive Verzweiflung raus tragen.",
                "Adds kontrollieren.",
                "Def-CDs für Phase 3 sparen.",
            },

            healer = {
                "Raid-CDs für Wirbelnde Verderbnis.",
                "Mindcontrols vorbereiten.",
                "Sternexplosionen gegenheilen.",
                "Phase 3 defensiv spielen.",
            },

            dps = {
                "Ingenieure sofort töten.",
                "Mindcontrols brechen.",
                "Entweihungen sauber platzieren.",
                "Sha-Adds getrennt töten.",
            },
        },
    },

}
