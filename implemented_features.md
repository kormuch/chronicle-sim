# Implemented Features

## Architecture
- Main.gd (UI) / GameManager.gd (logic) separation — hard rule: UI only in Main.gd, game logic only in GameManager.gd
- JSON-driven event system with external loader — all events in `events/*.json`, merged at startup

## Core Systems
- NPC council generation (procedural names from Tolkien/Germanic prefixes + suffixes, roles, moods)
- Alignment system (-100 to +100), clamped, affects mood + naming
- Chronicle display grouped by generation/year
- Undo system (5 snapshots)
- Single-slot save/load (JSON)

## Season System
- Season counter (1–4) in game_state, shown in status bar
- `{season_name}` template variable available in event text
- Season field in chronicle log entries
- Two-phase season: adventure → village. Season advances after village phase completes.

## Event Type System
- `"type": "adventure" | "village"` in event schema
- Picker filters by current `season_phase`
- If no adventure events available, auto-skips to village phase
- Rangers tagged as adventure events

## Content
- 16 base events: 6 Founding Era, 10 Growth Era (mid_era)
- 6 ranger events (adventure type)
- 5 Ashkin adventure chain (first multi-event story with branching aftermath)
- Story design frameworks imported (horror-mystery, situation generators)
- Story template imported (Darkening of Mirkwood, EN + DE)

## Tools
- `tools/chronicle_graph.py` — Mermaid history graph from savegame.json
- `tools/validate_save.py` — save file validator + 6 synthetic test scenarios
- Season & graph concept documented in `design/seasons-graph-concept.md`

## Bug Fixes
- **Save/Load Bug A:** `state_changed` not emitted after in-game Load → right panel stayed stale
- **Save/Load Bug B:** `_pending_follow` not persisted → follow_text lost after save mid-choice
- **Save/Load Bug C:** `_gen` not persisted → wrong trade options shown when saving during Guided Founding
- **Save/Load Bug D:** `season` loaded as float from JSON → `%` operator crash in `apply_choice`
