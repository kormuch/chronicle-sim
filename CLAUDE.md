# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Chronicle Sim** (working title, folder: `chronicle-sim`) — a text-based generational RPG in Godot 4.4 (GDScript). The player is the chronicler of a medieval village community and makes decisions that shape the village's history across generations (~25 years per shift).

**Language:** Variable names, code, and all UI/game texts in English. German translation comes later. Comments in English.

**Developer:** Korbinian Much — AI Product Owner, not a classical programmer. Explanations should be precise and direct, no GDScript syntax basics.

## Running Godot

No build script, no CLI test runner. Development and testing exclusively in the Godot 4.4 Editor.

```bash
godot --path C:\Users\kormu\projekte\chronicle-sim
godot --path C:\Users\kormu\projekte\chronicle-sim --scene Main.tscn
```

Savegame: `%APPDATA%\Godot\app_userdata\Chronicle Sim\savegame.json`

Errors visible in Godot Editor → bottom panel → **Output** or **Debugger** tab. Right-click → Copy All to share logs.

## Architecture

### File structure

```
GameManager.gd      Singleton/Autoload — all game logic, state, events, persistence
Main.gd             UI controller — pure display, no own game state
Main.tscn           Minimal scene, loads only Main.gd
project.godot       Godot project config
events/             External event JSON files — one file per thematic pack
  founding_era.json Currently 6 events
```

The `.godot/` folder is in `.gitignore` — do not commit.

### Communication rule

`Main.gd` has **no own state** and **never writes directly** to `GameManager`. Only via this public API:

```
apply_choice(event_id, index)   — apply a decision
advance_generation()            — generation shift
push_undo_snapshot()            — create snapshot
pop_undo_snapshot()             — execute undo
save_game() / load_game()       — persistence
```

Communication from GameManager to Main.gd via three signals:
```
state_changed(new_state: Dictionary)
event_triggered(event_id: String, text: String, choices: Array)
generation_advanced(summary: String)
```

`event_triggered` is also used for pure narrative text (follow texts, resume text) with an empty `choices` array — Main.gd appends the text without building buttons.

### GameManager State

```gdscript
game_state: Dictionary = {
    "alignment":      int,        # -100 (Dark) to +100 (Pure)
    "settlement":     Dictionary, # incl. key_npcs: Array[Dictionary]
    "chieftain":      Dictionary, # name, parent refs, age
    "generation":     int,
    "year":           int,
    "decision_count": int,
}
chronicle_log: Array   # Full event history (timestamp, event_id, delta, description, year, gen)
undo_stack: Array      # Max. 5 snapshots à {game_state, event_id}
current_event_id: String
```

### Event System

Story events are loaded from `res://events/*.json` — all `.json` files in the folder are merged at startup into `GameManager.EVENTS` (var, not const). Keys starting with `_` (e.g. `_info`) and non-Dictionary values are ignored by the engine.

**External authors** get their own `.json` file in `events/`. Use the `_info` field as a freeform note — it is skipped by the loader.

Currently implemented in `events/founding_era.json`:
`village_founding`, `first_winter`, `trade_caravan`, `border_dispute`, `wandering_healer`, `drought_warning`

**Event schema** (JSON):
```json
"event_id": {
    "_info": "Optional author note — ignored by engine",
    "title": "String",
    "text":  "String with template vars: {chieftain} {year} {settlement_type} {trades} {population} {location_name} {founding_text}",
    "conditions": {
        "alignment_min":  -100,
        "alignment_max":   100,
        "generation_min":    1,
        "generation_max":  999,
        "trade":            ""
    },
    "choices": [
        {
            "label":       "String shown on button",
            "effect":      { "alignment": 5, "population": 10 },
            "next_event":  "",
            "log_text":    "String written to chronicle",
            "follow_text": "Narrative paragraph shown after choice, before next event"
        }
    ]
}
```

- `conditions` is fully optional — omit any field to use the default (no restriction).
- `effect` supports `alignment` (clamped -100/+100) and `population` (min 1). Both optional.
- Always exactly 2 choices per event.
- `next_event: ""` means the event picker selects the next event automatically.
- `follow_text` is displayed in italics via `event_triggered` with empty choices.
- Template resolution runs in `_format_text()` before `event_triggered.emit()`.

**Event picker** (`_pick_and_trigger_next_event`): called after every choice when no `next_event` is set and naming is not pending. Filters unplayed events by current alignment, generation, and primary trade, then picks randomly from the eligible pool.

**Settlement generation flow** (internal `gen_*` events, not in EVENTS):
```
gen_new_game_choice → gen_choose_location → gen_choose_trade
  → Quick Start (random) OR manual selection
  → village_founding → [event picker takes over]
  → after 5 decisions: village_naming
```

`gen_*` events do not appear in the chronicle display (except `settlement_generated`).

### NPC / Council System

5 council NPCs per settlement. Procedural names from `NAME_PREFIX` + `NAME_SUFFIX_M/F` (Tolkien/Germanic-inspired). Children inherit a prefix from one parent (50/50 random). NPC mood (`state` field) is set at generation time from alignment — it is **not** recalculated dynamically on `state_changed` (known gap vs. original intent).

Council display (Main.gd `_build_kronrat_text`): name · role · age only.

### Alignment System

Scale -100 to +100, always clamped. Affects: NPC mood texts, village mood display, village name generation, chronicle deltas. Currently the **only** consequence of decisions — no population, resources, or economy system.

### Chronicle Display

`_build_chronicle_text()` groups entries by generation and year:
```
── Generation 1 ──

Year 1
— Settlement founded...
— Chieftain X takes command...

Year 1
— Event: The Village Awakens
— The village borders were secured...
```

`_refresh_chronicle()` sets the label text and defers a scroll to the bottom paragraph.

## Current Gaps (as of April 2026)

| Topic | Status |
|---|---|
| Story events | 16 total: 6 in founding_era.json, 10 in mid_era.json |
| Consequences | Alignment + population — no resources or economy yet |
| NPC dynamics | No ageing over time, no death, no dynasties |
| Save slots | Single slot only (`savegame.json`) |
| Event selection | Context filter by alignment, generation, trade — no weighting/scoring yet |
| NPC mood | Not recalculated dynamically — set once at generation |

## TODO

| Task | Priority | Notes |
|---|---|---|
| Technical test: Save / Load | high | Manually test save → restart → load flow; check chronicle, state, undo stack integrity |
| Event weighting/scoring | medium | Instead of random pick from eligible pool, weight events by how well conditions match |
| NPC ageing across generations | low | NPCs should age +25 years on advance_generation, die above ~80 |
| Multiple save slots | low | Currently hardcoded to savegame.json |

## Working Notes for Claude

- New story events go exclusively in JSON files in `events/` — never hardcode in GDScript.
- New event file: copy schema from `founding_era.json`, always include `_info` field.
- Before building context-aware `_pick_next_event()` logic: discuss first, as this changes core mechanics.
- UI changes only in `Main.gd` — never put display logic in `GameManager`.
- Use `call_deferred()` when events are triggered during signal handling (Godot pattern, already in place).
- No unrequested refactors — the foundation is intentionally compact.
- JSON numbers are floats in GDScript — always wrap effect values with `int()` when reading from JSON.
- `replace_all` in edits is dangerous when the replaced string appears inside newly added functions.
