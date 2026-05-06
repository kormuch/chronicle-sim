# Konzept: Seasons & Story Graph

## 1. Saisonstruktur

Eine Generation (~25 Jahre) unterteilt sich in Jahre, jedes Jahr in 4 Jahreszeiten.
Pro Saison: 1 Pflicht-Entscheidung + optional 0–2 Stories.

```
Generation N
└── Jahr Y
    ├── Spring   → 1 decision event  + [optional stories]
    ├── Summer   → 1 decision event  + [optional stories]
    ├── Autumn   → 1 decision event  + [optional stories]
    └── Winter   → 1 decision event  + [optional stories]
```

Saison-Zähler läuft nach jeder Entscheidung durch: 1→2→3→4→1→...
Der aktuelle Saison-Stand liegt in `game_state["season"]` (1–4).

---

## 2. Drei Event-Typen (JSON-Erweiterung)

Neues optionales Feld `type` im Event-Schema:

| Typ | Verhalten | Beispiel |
|---|---|---|
| `decision` | Default. Pflicht, blockiert nächste Saison. Hat choices. | Grenzkonflikt, Missernte |
| `story` | Optional. Wird angeboten, kann geskippt werden. Hat choices ODER ist reiner Text. | Ranger-Vignette, NPC-Moment |
| `crisis` | Durch Flag/Alignment getriggert. Kann Pflicht-Event ersetzen. | Seuche wenn kein deep_well |

Optional: `season: "winter"` als Filter-Bedingung im Event.

Story-Events zeigen zwei Buttons: **[Anhören]** und **[Überspringen]**.
Skip-Button ruft `_pick_and_trigger_next_event` direkt auf ohne choice-Effekte.

---

## 3. Graph-Visualisierung — zwei Ebenen

### Ebene A: History Graph (gespielte Session)
Aus `chronicle_log` in `savegame.json` → Mermaid-Flowchart.
Tool: `tools/chronicle_graph.py` (extern, kein Godot-Code).
Rendert in Obsidian, GitHub, oder jedem Mermaid-Viewer.

### Ebene B: Design Graph (alle möglichen Events)
Aus `events/*.json` → zeigt Event-Netz mit next_event-Kanten und Flag-Abhängigkeiten.
Tool: `tools/design_graph.py` (noch nicht implementiert).
Nützlich als Autor-Übersicht, nicht für den Spieler.

---

## 4. Implementierungsstand

| Feature | Status |
|---|---|
| `season` in `game_state` (1–4) | implementiert |
| Saison-Inkrement in `apply_choice()` | implementiert |
| `{season_name}` in `_format_text()` | implementiert |
| Saison in Chronicle-Log-Einträgen | implementiert |
| Saison-Anzeige in Main.gd Status | implementiert |
| `type: story` + Skip-Button | konzept — noch nicht implementiert |
| `season` als Condition-Filter | konzept — noch nicht implementiert |
| `tools/chronicle_graph.py` | implementiert |
| `tools/design_graph.py` | konzept — noch nicht implementiert |

---

## 5. Nächste Schritte

1. Story-Events mit Skip-Button implementieren (Main.gd + GameManager)
2. `season` als optionaler Filter im Event-Picker (`conditions.season`)
3. Design Graph (`tools/design_graph.py`) aus events/*.json generieren
4. Event-Weighting: statt random pick, Saison-Match erhöht Chance
