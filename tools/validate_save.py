#!/usr/bin/env python3
"""
Chronicle Sim — Save File Validator & Test Save Generator

Usage:
    python tools/validate_save.py              # validate default savegame.json
    python tools/validate_save.py <path>       # validate specific file
    python tools/validate_save.py --gen        # write test saves to tools/test_saves/

Validator checks:
    - All required keys and correct types
    - game_state field ranges (alignment, season, population…)
    - chronicle_log entry structure
    - undo_stack entry structure
    - Internal consistency (decision_count vs log entries, heir/spouse data)

Test saves exercise:
    1. Basic: 3 events played, no flags
    2. Naming pending: decision_count >= 5, no village name
    3. Flags: has_storehouse + has_palisade set
    4. Marriage: has_spouse = true
    5. Heir: has_heir = true, heir born
    6. Generation 2: year 26, new chieftain
"""

import json
import os
import sys
import copy

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
DEFAULT_SAVE = os.path.join(
    os.environ.get("APPDATA", ""),
    "Godot", "app_userdata", "Chronicle Sim", "savegame.json"
)
TEST_SAVE_DIR = os.path.join(SCRIPT_DIR, "test_saves")

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
ERRORS = []
WARNINGS = []

def err(msg):  ERRORS.append(msg)
def warn(msg): WARNINGS.append(msg)


def check_type(obj, key, expected_type, path=""):
    label = f"{path}.{key}" if path else key
    if key not in obj:
        err(f"Missing key: {label}")
        return False
    if not isinstance(obj[key], expected_type):
        err(f"Wrong type at {label}: expected {expected_type.__name__}, got {type(obj[key]).__name__}")
        return False
    return True


def validate_chieftain(c, path="chieftain"):
    for k in ("name", "gender"):
        check_type(c, k, str, path)
    for k in ("age", "rule_start_year"):
        check_type(c, k, (int, float), path)
    check_type(c, "has_spouse", bool, path)
    check_type(c, "has_heir", bool, path)

    if c.get("has_spouse") and not c.get("spouse"):
        err(f"{path}: has_spouse=true but spouse is empty")
    if c.get("has_heir") and not c.get("heir"):
        err(f"{path}: has_heir=true but heir is empty")


def validate_settlement(s, path="settlement"):
    check_type(s, "location", str, path)
    check_type(s, "primary_trade", str, path)
    check_type(s, "population", (int, float), path)
    check_type(s, "key_npcs", list, path)
    check_type(s, "trades", list, path)

    pop = s.get("population", 0)
    if isinstance(pop, (int, float)) and pop < 1:
        err(f"{path}.population must be >= 1, got {pop}")

    npcs = s.get("key_npcs", [])
    if not isinstance(npcs, list) or len(npcs) == 0:
        warn(f"{path}.key_npcs is empty — council will not render")
    for i, npc in enumerate(npcs):
        if not isinstance(npc, dict):
            err(f"{path}.key_npcs[{i}] is not a dict")
            continue
        for k in ("name", "role"):
            if k not in npc:
                warn(f"{path}.key_npcs[{i}] missing '{k}'")


def validate_game_state(gs):
    alignment = gs.get("alignment", 0)
    if not isinstance(alignment, (int, float)):
        err("game_state.alignment must be a number")
    elif not (-100 <= alignment <= 100):
        err(f"game_state.alignment out of range: {alignment}")

    season = gs.get("season", 0)
    if not isinstance(season, (int, float)) or not (1 <= season <= 4):
        err(f"game_state.season must be 1–4, got {season}")

    generation = gs.get("generation", 0)
    if not isinstance(generation, (int, float)) or generation < 1:
        err(f"game_state.generation must be >= 1, got {generation}")

    year = gs.get("year", 0)
    if not isinstance(year, (int, float)) or year < 1:
        err(f"game_state.year must be >= 1, got {year}")

    decision_count = gs.get("decision_count", -1)
    if not isinstance(decision_count, (int, float)) or decision_count < 0:
        err(f"game_state.decision_count must be >= 0, got {decision_count}")

    check_type(gs, "flags", dict, "game_state")

    if "settlement" not in gs or not isinstance(gs["settlement"], dict):
        err("game_state.settlement missing or not a dict")
    elif gs["settlement"]:
        validate_settlement(gs["settlement"])

    if "chieftain" not in gs or not isinstance(gs["chieftain"], dict):
        err("game_state.chieftain missing or not a dict")
    elif gs["chieftain"]:
        validate_chieftain(gs["chieftain"])


def validate_chronicle_log(log, game_state):
    if not isinstance(log, list):
        err("chronicle_log must be an array")
        return

    for i, entry in enumerate(log):
        if not isinstance(entry, dict):
            err(f"chronicle_log[{i}] is not a dict")
            continue
        for k in ("event_id", "description"):
            if k not in entry:
                warn(f"chronicle_log[{i}] missing '{k}'")
        for k in ("year", "season", "generation"):
            if k not in entry:
                warn(f"chronicle_log[{i}] missing '{k}'")
            elif not isinstance(entry[k], (int, float)):
                err(f"chronicle_log[{i}].{k} must be a number")

        gen = entry.get("generation", 1)
        if isinstance(gen, (int, float)) and gen > game_state.get("generation", 1):
            err(f"chronicle_log[{i}].generation ({gen}) > game_state.generation ({game_state.get('generation')})")

        delta = entry.get("delta")
        if delta is not None and not isinstance(delta, dict):
            err(f"chronicle_log[{i}].delta must be a dict or absent")


def validate_undo_stack(stack):
    if not isinstance(stack, list):
        err("undo_stack must be an array")
        return
    if len(stack) > 5:
        warn(f"undo_stack has {len(stack)} entries (max expected: 5)")
    for i, snap in enumerate(stack):
        if not isinstance(snap, dict):
            err(f"undo_stack[{i}] is not a dict")
            continue
        if "game_state" not in snap:
            err(f"undo_stack[{i}] missing 'game_state'")
        if "event_id" not in snap:
            err(f"undo_stack[{i}] missing 'event_id'")


def validate(save):
    for k in ("game_state", "chronicle_log", "undo_stack", "current_event_id"):
        if k not in save:
            err(f"Top-level key missing: '{k}'")

    gs = save.get("game_state", {})
    if isinstance(gs, dict):
        validate_game_state(gs)
    else:
        err("game_state must be a dict")
        gs = {}

    validate_chronicle_log(save.get("chronicle_log", []), gs)
    validate_undo_stack(save.get("undo_stack", []))

    eid = save.get("current_event_id", "")
    if not isinstance(eid, str):
        err(f"current_event_id must be a string, got {type(eid).__name__}")
    elif eid == "":
        warn("current_event_id is empty string — no event will resume")


def print_results(path):
    print(f"\nValidating: {path}")
    print("─" * 60)
    if not ERRORS and not WARNINGS:
        print("OK - Save file is valid. No issues found.")
        return

    if ERRORS:
        print(f"FAIL - {len(ERRORS)} error(s):")
        for e in ERRORS:
            print(f"  ERROR  {e}")
    if WARNINGS:
        print(f"WARN - {len(WARNINGS)} warning(s):")
        for w in WARNINGS:
            print(f"  WARN   {w}")

    if ERRORS:
        print("\n→ This save file may fail to load correctly in Godot.")
    else:
        print("\n→ No hard errors. Warnings are non-critical.")

# ---------------------------------------------------------------------------
# Test save generation
# ---------------------------------------------------------------------------
BASE_NPC = {
    "name": "Aldwin", "name_prefix": "Ald", "name_suffix": "win",
    "role": "Elder", "gender": "m", "age": 58,
    "father": {"name": "Galdric", "name_prefix": "Gal", "name_suffix": "dric"},
    "mother": {"name": "Mora", "name_prefix": "Mor", "name_suffix": "a"},
    "state": "Life here is hard, but fair.",
    "is_elder": True,
}

BASE_SETTLEMENT = {
    "name": "Woodmarch",
    "location": "forest_edge",
    "primary_trade": "hunting",
    "tier": 1,
    "population": 72,
    "trades": ["Hunter", "Fletcher", "Herb Woman"],
    "founding_id": "peaceful_pact",
    "founding_note": "Ancient alliance with the neighbours",
    "founding_text": "Early trade ties with a neighbouring tribe brought prosperity.",
    "key_npcs": [
        BASE_NPC,
        {"name": "Sigriel", "name_prefix": "Sig", "name_suffix": "riel",
         "role": "Healer", "gender": "f", "age": 34,
         "father": {"name": "Bormar", "name_prefix": "Bor", "name_suffix": "mar"},
         "mother": {"name": "Elwe", "name_prefix": "El", "name_suffix": "we"},
         "state": "The gods smile upon us.", "is_elder": False},
    ],
    "name_candidates": ["Woodmarch", "Fairwood", "Friendgrove"],
}

BASE_CHIEFTAIN = {
    "name": "Arulf", "name_prefix": "Ar", "name_suffix": "ulf",
    "gender": "m", "age": 31,
    "father": {"name": "Baldric", "name_prefix": "Bal", "name_suffix": "dric"},
    "mother": {"name": "Elriel", "name_prefix": "Elr", "name_suffix": "iel"},
    "rule_start_year": 1,
    "has_spouse": False, "spouse": {},
    "has_heir": False, "heir": {},
}

BASE_LOG_ENTRY = {
    "timestamp": 1748000000,
    "event_id": "village_founding",
    "delta": {"alignment": 0},
    "description": "Settlement founded.",
    "year": 1, "season": 1, "generation": 1,
}


def make_game_state(overrides=None):
    gs = {
        "alignment": 10,
        "settlement": copy.deepcopy(BASE_SETTLEMENT),
        "chieftain": copy.deepcopy(BASE_CHIEFTAIN),
        "generation": 1,
        "year": 3,
        "season": 2,
        "decision_count": 3,
        "flags": {},
    }
    if overrides:
        gs.update(overrides)
    return gs


def make_log(*extra_entries):
    log = [
        copy.deepcopy(BASE_LOG_ENTRY),
        {"timestamp": 1748000010, "event_id": "first_winter",
         "delta": {"alignment": 5}, "description": "Shared equally in winter.",
         "year": 1, "season": 2, "generation": 1},
        {"timestamp": 1748000020, "event_id": "trade_caravan",
         "delta": {"alignment": 5}, "description": "Fair trade agreed.",
         "year": 2, "season": 1, "generation": 1},
    ]
    log.extend(extra_entries)
    return log


TEST_SCENARIOS = {
    "01_basic": {
        "desc": "Basic: 3 events played, no flags, no name pending",
        "game_state": make_game_state(),
        "chronicle_log": make_log(),
        "undo_stack": [],
        "current_event_id": "trade_caravan",
    },
    "02_naming_pending": {
        "desc": "Naming pending: 5 decisions, village name empty",
        "game_state": make_game_state({
            "decision_count": 5,
            "settlement": {**copy.deepcopy(BASE_SETTLEMENT), "name": ""},
        }),
        "chronicle_log": make_log(
            {"timestamp": 1748000030, "event_id": "border_dispute",
             "delta": {"alignment": -5}, "description": "Turned them away.",
             "year": 2, "season": 3, "generation": 1},
            {"timestamp": 1748000040, "event_id": "drought_warning",
             "delta": {}, "description": "Rationed water.",
             "year": 3, "season": 1, "generation": 1},
        ),
        "undo_stack": [],
        "current_event_id": "village_naming",
    },
    "03_flags_set": {
        "desc": "Flags: has_storehouse and has_palisade both set",
        "game_state": make_game_state({"flags": {"has_storehouse": True, "has_palisade": True}}),
        "chronicle_log": make_log(),
        "undo_stack": [],
        "current_event_id": "trade_caravan",
    },
    "04_married": {
        "desc": "Marriage: chieftain has spouse",
        "game_state": make_game_state({
            "decision_count": 9,
            "year": 5,
            "chieftain": {
                **copy.deepcopy(BASE_CHIEFTAIN),
                "has_spouse": True,
                "spouse": {"name": "Sigwen", "name_prefix": "Sig", "name_suffix": "wen"},
            },
        }),
        "chronicle_log": make_log(),
        "undo_stack": [],
        "current_event_id": "chieftain_marriage",
    },
    "05_heir_born": {
        "desc": "Heir: chieftain has spouse and heir",
        "game_state": make_game_state({
            "decision_count": 16,
            "year": 8,
            "chieftain": {
                **copy.deepcopy(BASE_CHIEFTAIN),
                "has_spouse": True,
                "spouse": {"name": "Sigwen", "name_prefix": "Sig", "name_suffix": "wen"},
                "has_heir": True,
                "heir": {"name": "Arwen", "name_prefix": "Ar", "name_suffix": "wen",
                         "gender": "f", "birth_year": 8},
            },
        }),
        "chronicle_log": make_log(),
        "undo_stack": [],
        "current_event_id": "chieftain_heir",
    },
    "06_generation_2": {
        "desc": "Generation 2: year 26, new chieftain elected",
        "game_state": make_game_state({
            "generation": 2,
            "year": 26,
            "decision_count": 4,
            "chieftain": {
                "name": "Elrald", "name_prefix": "Elr", "name_suffix": "ald",
                "gender": "m", "age": 25,
                "father": {"name": "Arulf", "name_prefix": "Ar", "name_suffix": "ulf"},
                "mother": {"name": "Sigwen", "name_prefix": "Sig", "name_suffix": "wen"},
                "rule_start_year": 26,
                "has_spouse": False, "spouse": {},
                "has_heir": False, "heir": {},
            },
        }),
        "chronicle_log": make_log(
            {"timestamp": 1748000050, "event_id": "generation_advance",
             "delta": {"generation": 2, "year": 26},
             "description": "Generation 2 · Year 26 · Chieftain Elrald · Alignment +10",
             "year": 26, "season": 1, "generation": 2},
        ),
        "undo_stack": [],
        "current_event_id": "great_fire",
    },
}


def write_test_saves():
    os.makedirs(TEST_SAVE_DIR, exist_ok=True)
    for name, scenario in TEST_SCENARIOS.items():
        path = os.path.join(TEST_SAVE_DIR, f"{name}.json")
        data = {
            "game_state": scenario["game_state"],
            "chronicle_log": scenario["chronicle_log"],
            "undo_stack": scenario["undo_stack"],
            "current_event_id": scenario["current_event_id"],
        }
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent="\t", ensure_ascii=False)

        # Validate each generated save
        global ERRORS, WARNINGS
        ERRORS, WARNINGS = [], []
        validate(data)
        status = "OK" if not ERRORS else "FAIL"
        print(f"  [{status}] {name}.json - {scenario['desc']}")
        for e in ERRORS:
            print(f"      ERROR: {e}")

    print(f"\nTest saves written to: {TEST_SAVE_DIR}")
    print("\nTo test in Godot:")
    print(f"  Copy a test save to:")
    appdata = os.environ.get("APPDATA", "%APPDATA%")
    print(f"  {appdata}\\Godot\\app_userdata\\Chronicle Sim\\savegame.json")
    print("  Then launch Godot or click 'Load' in-game.")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    if "--gen" in sys.argv:
        print("Generating test saves...")
        write_test_saves()
        return

    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SAVE

    if not os.path.exists(path):
        print(f"Save file not found: {path}")
        if path == DEFAULT_SAVE:
            print("(No save game exists yet — play and save first.)")
        sys.exit(1)

    with open(path, encoding="utf-8") as f:
        try:
            save = json.load(f)
        except json.JSONDecodeError as e:
            print(f"JSON parse error: {e}")
            sys.exit(1)

    validate(save)
    print_results(path)
    sys.exit(1 if ERRORS else 0)


if __name__ == "__main__":
    main()
