# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

**Schatten über dem Düsterwald** — ein textbasiertes Generationen-RPG in Godot 4.4 (GDScript). Der Spieler ist Chronist einer mittelalterlichen Dorfgemeinschaft und trifft Entscheidungen, die über Generationen die Geschichte prägen. Alles in Deutsch: Variablennamen in Englisch, alle UI-Texte, Dialoge und Kommentare auf Deutsch.

## Godot-Befehle

Das Projekt läuft ausschließlich in der Godot 4.4 Engine. Es gibt kein Build-Script oder CLI — starte/teste über den Godot-Editor:

```
# Projekt im Editor öffnen (Godot 4.4 muss installiert sein)
godot --path C:\Users\kormu\projekte\chronicle-sim

# Spiel direkt starten (headless nicht sinnvoll, da UI-Spiel)
godot --path C:\Users\kormu\projekte\chronicle-sim --scene Main.tscn
```

Savegame-Pfad: `%APPDATA%\Godot\app_userdata\Schatten über dem Düsterwald\savegame.json`

## Architektur

### Zwei-Dateien-Struktur

```
GameManager.gd   (Singleton/Autoload) — gesamte Spiellogik
Main.gd          (UI-Controller)      — reine Darstellung, kein Spielzustand
Main.tscn        (minimale Szene)     — lädt nur Main.gd
```

**Kommunikation ausschließlich über Signals:**
```
GameManager → Main.gd
  state_changed(new_state: Dictionary)
  event_triggered(event_id: String, text: String, choices: Array)
  generation_advanced(summary: String)
```

`Main.gd` schreibt **niemals** in `GameManager`-State direkt — nur via `apply_choice()`, `advance_generation()`, `push_undo_snapshot()`, `pop_undo_snapshot()`, `save_game()`, `load_game()`.

### GameManager-State

```gdscript
game_state: Dictionary = {
    "alignment":      int,   # -100 bis +100
    "settlement":     {},    # inkl. key_npcs Array
    "chieftain":      {},    # Name, Eltern, Alter
    "generation":     int,
    "year":           int,
    "decision_count": int,
}
chronicle_log: Array      # Vollständige History aller Ereignisse
undo_stack: Array         # Max. 5 Snapshots (game_state + event_id)
current_event_id: String
```

### Event-System

Events sind Konstanten in `GameManager.EVENTS` (Dictionary). Jedes Event hat:
- `title`, `text` (mit Template-Variablen wie `{chieftain}`, `{year}`, `{settlement_type}`)
- `choices: Array` — je 2 Optionen mit `label`, `effect: {alignment: int}`, `next_event`, `log_text`

**Settlement-Generierungsflow** (interne `gen_*` Events, kein Eintrag in `EVENTS`):
`gen_new_game_choice` → `gen_choose_location` → `gen_choose_trade` → `gen_quickstart` oder Settlement-Generierung → `gen_name_village` → `village_founding`

Template-Auflösung läuft in `_format_text()` vor dem Emit von `event_triggered`.

### NPC-System

5 Kronrat-NPCs pro Siedlung. Namen prozedural aus `NAME_PREFIX` + `NAME_SUFFIX_M/F`. Kinder erben den Präfix eines Elternteils (50/50). NPC-Stimmung wird aus Alignment-Schwellen abgeleitet (`_pick_npc_state()`), keine eigene Tracking-Variable.

### Chronik-Filterung

`gen_*`-Events werden im Chronik-Display **nicht** angezeigt (außer `settlement_generated`). Generationstrennlinien werden automatisch eingefügt wenn `gen` wechselt.

## Wo neue Events hingehören

Neue Story-Events kommen als Einträge in `GameManager.EVENTS` (Dictionary, ab Zeile ~198). Struktur identisch zu den bestehenden drei Events. Gewerbe-spezifische Bedingungslogik gehört in `trigger_event()` bzw. eine dedizierte `_pick_next_event()`-Funktion (noch nicht vorhanden — wird benötigt sobald Events kontextabhängig ausgewählt werden sollen).

## Bekannte Lücken

- Nur 3 Story-Events (`village_founding`, `first_winter`, `trade_caravan`) — primäre Erweiterungsbaustelle
- Entscheidungen beeinflussen bislang ausschließlich `alignment` — kein Bevölkerungs- oder Ressourcensystem
- NPCs altern nicht über echte Spielzeit (Alter ist statisch nach Generierung)
- Nur ein Speicherslot (`savegame.json`)
