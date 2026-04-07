# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

**Schatten über dem Düsterwald** (Arbeitstitel: `chronicle-sim`) — ein textbasiertes Generationen-RPG in Godot 4.4 (GDScript). Der Spieler ist Chronist einer mittelalterlichen Dorfgemeinschaft und trifft Entscheidungen, die über Generationen (~25 Jahre pro Wechsel) die Geschichte des Dorfes prägen.

**Sprache:** Variablennamen und Code in Englisch. Alle UI-Texte, Dialoge, Ereignistexte und Kommentare auf Deutsch.

**Entwickler:** Korbinian Much — AI Product Owner, kein klassischer Programmierer. Erklärungen sollen präzise und direkt sein, keine Grundlagen-Erläuterungen zu GDScript-Syntax.

## Godot starten

Kein Build-Script, kein CLI-Test-Runner. Entwicklung und Test ausschließlich im Godot 4.4 Editor.

```bash
godot --path C:\Users\kormu\projekte\chronicle-sim
godot --path C:\Users\kormu\projekte\chronicle-sim --scene Main.tscn
```

Savegame: `%APPDATA%\Godot\app_userdata\Schatten über dem Düsterwald\savegame.json`

## Architektur

### Dateistruktur

```
GameManager.gd   Singleton/Autoload — gesamte Spiellogik, State, Events, Persistenz
Main.gd          UI-Controller — reine Darstellung, kein eigener Spielzustand
Main.tscn        Minimale Szene, lädt nur Main.gd
project.godot    Godot-Projektkonfiguration
```

Die `.godot/`-Ordner ist in `.gitignore` — nicht committen.

### Kommunikationsregel

`Main.gd` hat **keinen eigenen State** und schreibt **niemals direkt** in `GameManager`. Ausschließlich über diese public API:

```
apply_choice(event_id, index)   — Entscheidung anwenden
advance_generation()            — Generationswechsel
push_undo_snapshot()            — Snapshot anlegen
pop_undo_snapshot()             — Undo ausführen
save_game() / load_game()       — Persistenz
```

Kommunikation von GameManager zu Main.gd über drei Signals:
```
state_changed(new_state: Dictionary)
event_triggered(event_id: String, text: String, choices: Array)
generation_advanced(summary: String)
```

### GameManager-State

```gdscript
game_state: Dictionary = {
    "alignment":      int,        # Gesinnung -100 (Dunkel) bis +100 (Rein)
    "settlement":     Dictionary, # inkl. key_npcs: Array[Dictionary]
    "chieftain":      Dictionary, # name, Eltern-Refs, Alter
    "generation":     int,
    "year":           int,
    "decision_count": int,
}
chronicle_log: Array   # Vollständige Event-History (timestamp, event_id, delta, description, year, gen)
undo_stack: Array      # Max. 5 Snapshots à {game_state, event_id}
current_event_id: String
```

### Event-System

Story-Events als Einträge in `GameManager.EVENTS` (Konstante, Dictionary). Aktuell implementiert: `village_founding`, `first_winter`, `trade_caravan` — das ist die **primäre Erweiterungsbaustelle**.

Jedes Event-Schema:
```gdscript
"event_id": {
    "title": String,
    "text":  String,  # Template-Variablen: {chieftain} {year} {settlement_type} {trades} {population}
    "choices": [
        {
            "label":      String,
            "effect":     {"alignment": int},
            "next_event": String,   # "" = kein Auto-Follow-up
            "log_text":   String,
        },
        # immer genau 2 Choices
    ],
}
```

Template-Auflösung läuft in `_format_text()` vor `event_triggered.emit()`.

**Settlement-Generierungsflow** (interne `gen_*` Events, nicht in `EVENTS`):
```
gen_new_game_choice → gen_choose_location → gen_choose_trade
  → gen_quickstart (Zufall) ODER manuelle Auswahl
  → gen_name_village → village_founding
```

`gen_*`-Events erscheinen nicht in der Chronik-Anzeige (außer `settlement_generated`).

### NPC-System

5 Kronrat-NPCs pro Siedlung. Prozedurale Namen aus `NAME_PREFIX` + `NAME_SUFFIX_M/F` (Tolkien-/germanisch-inspiriert). Kinder erben den Präfix eines Elternteils (50/50 Zufall). NPC-Stimmung (`state`-Feld) wird bei jedem `state_changed` frisch aus dem aktuellen `alignment` berechnet (`_pick_npc_state()`), ist also kein persistierter Wert.

### Alignment-System

Skala -100 bis +100, immer geclampt. Beeinflusst: NPC-Stimmungstexte, Dorfstimmung, Dorfnamen-Generierung, Chronik-Deltas. Wird aktuell als **einzige** Konsequenz von Entscheidungen verändert — kein Bevölkerungs- oder Ressourcensystem vorhanden.

## Aktuelle Lücken (Stand Projektstart April 2026)

| Thema | Status |
|---|---|
| Story-Events | Nur 3 implementiert — Hauptbaustelle |
| Konsequenzen | Nur Alignment — keine Bevölkerung, Ressourcen, Wirtschaft |
| NPC-Dynamik | Altern nicht über Spielzeit, kein Tod, keine Dynastien |
| Speicherslots | Nur einer (`savegame.json`) |
| Event-Selektion | Kein kontextabhängiger Event-Picker (nach Gewerbe, Alignment, Generation) |

## Arbeitshinweise für Claude

- Neue Story-Events immer in `GameManager.EVENTS` eintragen, Schema wie oben.
- Bevor eine `_pick_next_event()`-Logik gebaut wird: erst Rücksprache, da das die Kernmechanik verändert.
- UI-Änderungen nur in `Main.gd` — nie Darstellungslogik in `GameManager` einbauen.
- `call_deferred()` verwenden wenn Events während Signal-Verarbeitung getriggert werden (Godot-Pattern, bereits so gehandhabt).
- Keine Refactors, die nicht explizit angefragt wurden — das Fundament ist bewusst kompakt gehalten.
