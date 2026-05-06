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

Logs: `%APPDATA%\Godot\app_userdata\Chronicle Sim\logs\game_DATUM-ZEIT.log`
Eine neue Logdatei pro Session. Enthält: Event-Picker Pool-Status, Save/Load-Ergebnisse, current_event_id beim Resume.

Errors visible in Godot Editor → bottom panel → **Output** or **Debugger** tab. Right-click → Copy All to share logs.

## Architecture

### File structure

```
GameManager.gd      Singleton/Autoload — all game logic, state, events, persistence
Main.gd             UI controller — pure display, no own game state
Main.tscn           Minimal scene, loads only Main.gd
project.godot       Godot project config
events/             External event JSON files — one file per thematic pack
  founding_era.json 6 events (Founding Era)
  mid_era.json      10 events (Growth Era)
material/           Story reference & design material (not loaded by engine)
  storydesign/
    horror-mystery-plots-summary.md       Distilled: 5 levels of fear, 3-clue rule, pacing
    situation-generators-summary.md       6 situation generators (Long Knives, Quest, Transgression…)
    *.pdf / *.txt                         Source PDFs + extracted text
  storymaterial/
    darkening-of-mirkwood-en.md           Full English extract (TOR 30-year campaign)
    original/                             German source + raw TXT
```

### Tools (`tools/`)

External scripts — not loaded by the engine.

**`tools/chronicle_graph.py`** — reads `savegame.json`, outputs a Mermaid flowchart of the played history.
```bash
python tools/chronicle_graph.py                        # reads default APPDATA save
python tools/chronicle_graph.py path/to/savegame.json  # explicit path
python tools/chronicle_graph.py > history.md           # pipe to file for Obsidian/GitHub
```
Renders in Obsidian, GitHub .md files, or https://mermaid.live.
Node colours: green = +alignment, red = −alignment, blue = flag set, grey = neutral.

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
    "season":         int,        # 1=Spring 2=Summer 3=Autumn 4=Winter — cycles per decision
    "decision_count": int,
    "flags":          Dictionary, # set_flag effects stored here
}
chronicle_log: Array   # Full event history (timestamp, event_id, delta, description, year, season, gen)
undo_stack: Array      # Max. 5 snapshots à {game_state, event_id}
current_event_id: String
```

### Event System

Story events are loaded from `res://events/*.json` — all `.json` files in the folder are merged at startup into `GameManager.EVENTS` (var, not const). Keys starting with `_` (e.g. `_info`) and non-Dictionary values are ignored by the engine.

**External authors** get their own `.json` file in `events/`. Use the `_info` field as a freeform note — it is skipped by the loader.

Currently implemented:

**`events/founding_era.json`** (6 events):
`village_founding`, `first_winter`, `trade_caravan`, `border_dispute`, `wandering_healer`, `drought_warning`

**`events/mid_era.json`** (10 events):
`great_fire`, `refugee_camp`, `bandit_raid`, `harvest_festival`, `dark_omens`, `skilled_craftsman`, `spy_discovered`, `collapsed_bridge`, `young_rebel`, *(1 more)*

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
        "trade":            "",
        "requires_flag":    "",
        "forbids_flag":     ""
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
- `effect` supports `alignment` (clamped -100/+100), `population` (min 1), and `set_flag` (string). All optional.
- Use `alignment` for moral choices (how you treat people). Use `set_flag` for infrastructure and decisions with delayed consequences.
- `requires_flag` / `forbids_flag` in conditions: event only appears if the flag is (or isn't) set in `game_state.flags`.
- 2–3 choices per event. 2 is the default; use 3 when the moral space genuinely needs a third path (not just padding).
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

## Story Reference Material (`material/`)

All files in `material/` are design inputs — not loaded by the engine. Used to generate event content.

### Design Frameworks (`material/storydesign/`)

**`horror-mystery-plots-summary.md`** — distilled from "Horror in Roleplaying Plus" & "How to Handle Clues":
- **5 levels of fear:** External threat → loved ones threatened → we create evil → we are evil → world itself is evil
- **Three Clue Rule:** For every necessary conclusion, plant ≥3 clue paths — if one is missed, ignored, or misread, the player still progresses
- **Horror tools:** Personal investment, Terror vs. Revulsion vs. Dread, Compartmentalization, Group Dissent, Revelation
- **Application for Chronicle Sim:** Multi-gen mystery arcs, moral corruption events, dark_omens / prophecy event types

**`situation-generators-summary.md`** — distilled from "Creating Fun Game Situations" & "Rollenspielplots Plus":
- **6 generators:** Long Knives (faction conflict), Broken Places (corrupted power), The Quest (time-limited phases), Transgression (3-sided social movement), Predator Souls (monster to understand), Nine Rooms (location by function)
- **Core principles:** Tension before details, triangle drama (3 sides > 2), costliness of choice, escalation, timing as tool
- **Application:** Each generator maps directly to an event type — use for structuring new event batches

### Story Template (`material/storymaterial/`)

**`darkening-of-mirkwood-en.md`** (+ German original):
- TOR campaign by Ryder-Hanrahan & Nepitello; 30-year arc across 5 eras (2947–2977 Third Age)
- Key structural patterns applicable to Chronicle Sim:
  - Recurring NPCs that change role across generations (e.g. Mogdred: ally → threat)
  - Consequences echoing across 25-year generation shifts
  - Moral choices with no clean "right" answer — sacrifice is always partial
  - Lamp of Balthi as multi-gen MacGuffin (model for Chronicle Sim "legacy item" events)
  - Light vs. darkness as explicit alignment metaphor

---

### Season System

Each decision advances the season counter: Spring → Summer → Autumn → Winter → Spring → …
`game_state["season"]` (1–4) is set after every `apply_choice()` call.
`{season_name}` is available as a template variable in event text.
Chronicle log entries include `"season"` for graph export.

Full season design concept: `design/seasons-graph-concept.md`

Planned (not yet implemented):
- `conditions.season` filter in event JSON — event only fires in matching season
- `type: story` events with **[Listen] / [Skip]** buttons
- `tools/design_graph.py` — Mermaid export of the full event network for authors

## Current Gaps (as of May 2026)

| Topic | Status |
|---|---|
| Story events | 16 total: 6 in founding_era.json, 10 in mid_era.json |
| Consequences | Alignment + population — no resources or economy yet |
| NPC dynamics | No ageing over time, no death, no dynasties |
| Save slots | Single slot only (`savegame.json`) |
| Event selection | Context filter by alignment, generation, trade — no weighting/scoring yet |
| NPC mood | Not recalculated dynamically — set once at generation |

## TODO

### Done ✅
- Architecture: Main.gd (UI) / GameManager.gd (logic) separation
- JSON-driven event system with external loader
- NPC council generation (procedural names, roles, moods)
- Alignment system (-100 to +100), clamped, affects mood + naming
- Chronicle display grouped by generation/year
- Undo system (5 snapshots)
- Single-slot save/load (JSON)
- 16 events: 6 Founding Era, 10 Growth Era (mid_era)
- Story design frameworks imported (horror-mystery, situation generators)
- Story template imported (Darkening of Mirkwood, EN + DE)
- Season counter (1–4) in game_state, increments per decision, shown in status bar
- `{season_name}` template variable available in event text
- Season field in chronicle log entries
- `tools/chronicle_graph.py` — Mermaid history graph from savegame.json
- Season & graph concept documented in `design/seasons-graph-concept.md`

### Open

| Task | Priority | Notes |
|---|---|---|
| **Technical test: Save / Load** | high | Manually test save → restart → load flow; check chronicle, state, undo stack integrity |
| **Write Founding Era events (24 more)** | high | Target: 30 total. Use situation generators + event recipe. Conflict types: extern, intern, spiritual |
| **Write Growth Era events (20 more)** | high | Target: 30 total (currently 10 in mid_era.json). Trade, expansion, dynasty themes |
| `conditions.season` filter | medium | Event only fires in matching season — extend picker + JSON schema |
| `type: story` events + Skip button | medium | Offer but don't force — Main.gd needs skip button, GameManager needs type-aware picker |
| `tools/design_graph.py` | low | Mermaid export of full event network from events/*.json for author overview |
| Event weighting/scoring | medium | Instead of random pick from eligible pool, weight events by how well conditions match |
| NPC ageing across generations | low | NPCs should age +25 years on advance_generation, die above ~80 |
| NPC mood recalculation | low | Currently set once at generation; should recalculate dynamically when alignment changes |
| **NPC alignment reactions** | low | Council NPCs react differently to events based on chieftain's alignment — e.g. pure alignment: elder Mira approves, dark-leaning: enforcer Drak steps forward. Reactions shown as flavor text below event. Schema: optional `alignment_reactions` block per choice, with `min`/`max` range + `npc_role` + `text` |
| **Key event memory** | low | Certain events are flagged as `memorable: true` in JSON. These are stored in `game_state.memories[]` (event_id + year + gen + outcome). Later events can reference them via `conditions.requires_memory` or inject them into `text` via `{memory_X}` template var — e.g. "The river that flooded in Year 3 still shapes how elders vote." |
| Multiple save slots | low | Currently hardcoded to savegame.json |
| UI polish | low | Replace Godot default theme before itch.io launch |

## Produktvision & Monetarisierung

### Zielformat

PC-First (Godot Desktop), später Mobile Export. Kein App-Store als erster Schritt.
Vertrieb: **itch.io** als Testmarkt → bei Resonanz Steam / Mobile.

### Preismodell

- Basisspiel Einmalkauf: **$4–7**
- Content-Packs (Eras) als DLC: **$1–2 pro Pack**
- Kein Abo, kein Freemium — passt nicht zum Nutzungsverhalten

### Vergleichstitel (Marktvalidierung)

- **Reigns** — Karten-Entscheidungsspiel, mittelalterliches Setting, Millionen Downloads, $2,99
- **80 Days** — Narrative choice game, preisgekrönt, profitabel
- **Choice of Games** — Ökosystem text-basierter Entscheidungsspiele, konstant profitabel

Generationenwechsel + Dorfchronik ist ein Winkel, den keines davon direkt besetzt.

### Content-Strategie: das Kochrezept

Der Entwickler (Korbinian) verfügt über umfangreichen RPG-Content (digital & Print) und produziert Events konzeptionell nach Vorlage. Claude übersetzt Rohnotizen in fertiges JSON.

**Kochrezept für ein Event:**

1. **Konflikttyp wählen**
   - Extern: feindlicher Überfall, Handelsstreit, Wanderer, Naturkatastrophe
   - Intern: Verrat im Rat, Hungersnot, Erbstreit, Kultbildung
   - Spirituell: Omen, Fluch, Prophezeiung, heilige Stätte

2. **Moralische Spannung definieren**
   - Schneller Vorteil (Population/Ressourcen) vs. langfristiges Prinzip (Alignment)
   - Oder: Sicherheit für wenige vs. Risiko für alle

3. **Konsequenz-Asymmetrie setzen**
   - Choice A: +Alignment, -Population (oder neutral)
   - Choice B: -Alignment, +Population (oder neutral)
   - Mindestens eine Wahl muss einen spürbaren Preis haben

4. **Ton festlegen** (episch / alltäglich / düster / lakonisch)

5. **Conditions nutzen** um Events an den Spielzustand zu binden
   - alignment_min/max für Kontext-Sensitivität
   - generation_min für Era-Zugehörigkeit
   - trade für kulturelle Färbung

**Faustregel:** Ein gutes Event hat eine klare Frage, zwei echte Alternativen, und einen follow_text der die Wahl spürbar macht.

### Content-Roadmap (Eras als DLC-Einheiten)

| Era | Thema | Events (Ziel) | Status |
|---|---|---|---|
| Founding Era | Gründung, erste Winter, erste Konflikte | 30 | 6 vorhanden |
| Growth Era | Handel, Expansion, erste Dynastien | 30 | 10 vorhanden (mid_era) |
| Crisis Era | Seuche, Krieg, innerer Zerfall | 30 | 0 |
| Legacy Era | Vermächtnis, Niedergang oder Aufstieg | 30 | 0 |

**Ziel für itch.io-Launch:** Founding + Growth Era vollständig (60 Events), Crisis Era als Ankündigung.

### Meilensteine bis Launch

| Meilenstein | Was fehlt |
|---|---|
| Content-Complete (60 Events) | ~44 weitere Events nach Kochrezept |
| Mechanik-Complete | NPC-Alterung, Ressourcen-Ansatz, Event-Gewichtung |
| UI-Polish | Godot-Default-Theme ersetzen, Touch-tauglich wenn Mobile |
| itch.io-Launch | Trailer (Screenshot-GIF reicht), kurze Beschreibung, $4–6 |

---

## Working Notes for Claude

- New story events go exclusively in JSON files in `events/` — never hardcode in GDScript.
- New event file: copy schema from `founding_era.json`, always include `_info` field.
- Before building context-aware `_pick_next_event()` logic: discuss first, as this changes core mechanics.
- UI changes only in `Main.gd` — never put display logic in `GameManager`.
- Use `call_deferred()` when events are triggered during signal handling (Godot pattern, already in place).
- No unrequested refactors — the foundation is intentionally compact.
- JSON numbers are floats in GDScript — always wrap effect values with `int()` when reading from JSON.
- `replace_all` in edits is dangerous when the replaced string appears inside newly added functions.
