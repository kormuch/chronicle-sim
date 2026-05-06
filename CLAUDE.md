# Chronicle Sim — Claude Context

Text-based generational RPG in Godot 4.4 (GDScript). Player is chronicler of a medieval village across generations (~25 years per shift).

**Developer:** Korbinian Much — AI Product Owner. Skip GDScript basics. Be direct.
**Language:** All code, variables, UI, event text in English.
**Extended reference & backlog:** `readme&todo.md`

---

## Running

```bash
godot --path C:\Users\kormu\projekte\chronicle-sim --scene Main.tscn
```

Savegame: `%APPDATA%\Godot\app_userdata\Chronicle Sim\savegame.json`
Logs: `%APPDATA%\Godot\app_userdata\Chronicle Sim\logs\`
Errors: Godot Editor → Output / Debugger panel.

---

## Architecture

```
GameManager.gd   Autoload singleton — all logic, state, events, persistence
Main.gd          UI only — no own state, never writes directly to GameManager
Main.tscn        Loads Main.gd
events/          JSON event packs — loaded and merged at startup
tools/           External scripts (not loaded by engine)
material/        Story design reference (not loaded by engine)
design/          Concept docs (not loaded by engine)
```

**Hard rule:** UI logic only in `Main.gd`. Game logic only in `GameManager.gd`.

`Main.gd` communicates with GameManager exclusively via:
```
apply_choice(event_id, index)
advance_generation()
push_undo_snapshot() / pop_undo_snapshot()
save_game() / load_game()
```

GameManager → Main.gd via signals:
```
state_changed(new_state: Dictionary)
event_triggered(event_id, text, choices)   # choices=[] for narrative-only
generation_advanced(summary)
```

---

## Game State

```gdscript
game_state = {
    "alignment":      int,        # -100 (Dark) to +100 (Pure), always clamped
    "settlement":     Dictionary, # incl. key_npcs: Array[Dictionary]
    "chieftain":      Dictionary,
    "generation":     int,
    "year":           int,
    "season":         int,        # 1=Spring 2=Summer 3=Autumn 4=Winter
    "decision_count": int,
    "flags":          Dictionary, # set_flag effects land here
}
chronicle_log: Array    # full history; entries include year, season, gen
undo_stack: Array       # max 5 snapshots
```

Season advances every decision. `{season_name}` available as template var.

---

## Event System

All events in `events/*.json` — merged at startup into `GameManager.EVENTS`. Never hardcode events in GDScript.

**Current packs:**
- `founding_era.json` — 6 events (Founding Era)
- `mid_era.json` — 10 events (Growth Era)
- `rangers.json` — 6 events (scouting/exploration)

**Event schema:**
```json
"event_id": {
    "_info": "author note — ignored by engine",
    "title": "String",
    "text": "Supports: {chieftain} {year} {season_name} {settlement_type} {trades} {population} {location_name} {founding_text}",
    "conditions": {
        "alignment_min": -100, "alignment_max": 100,
        "generation_min": 1,   "generation_max": 999,
        "trade": "",
        "requires_flag": "",
        "forbids_flag": ""
    },
    "choices": [
        {
            "label": "Button text",
            "effect": { "alignment": 5, "population": 10, "set_flag": "flag_name" },
            "next_event": "",
            "log_text": "Written to chronicle",
            "follow_text": "Narrative shown after choice (italics, no buttons)"
        }
    ]
}
```

- `conditions` fully optional — omit fields freely.
- `effect`: `alignment` (clamped), `population` (min 1), `set_flag` (string). All optional.
- 2 choices default; 3 only when the moral space genuinely needs it.
- `next_event: ""` → event picker chooses next automatically.
- JSON numbers are floats in GDScript — always wrap with `int()` when reading effects.

**Event picker** filters by alignment, generation, trade, flags — then picks randomly from eligible pool.

**Internal `gen_*` events** handle new game setup — not in `EVENTS`, not shown in chronicle.

---

## Coding Rules

- No unrequested refactors.
- `call_deferred()` when triggering events inside signal handlers (already in place).
- `replace_all` in edits is dangerous if the string appears in newly added code — be precise.
- Before changing `_pick_next_event()` logic: discuss first.
- New event file: copy schema from `founding_era.json`, include `_info` field.
