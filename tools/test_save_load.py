#!/usr/bin/env python3
"""
Chronicle Sim — Automated Save/Load Tests

Tests the data layer of save/load without requiring Godot.
Covers: JSON roundtrip, field validation, backward compatibility,
        bug regressions (A/B/C), and all 6 synthetic scenarios.

Usage:
    python tools/test_save_load.py
"""

import json
import os
import sys
import copy
import tempfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------------------
# Minimal Python re-implementation of GameManager save/load logic
# (mirrors GameManager.gd exactly — if GDScript changes, update here too)
# ---------------------------------------------------------------------------

def gd_load_game(path):
    """
    Mirrors GameManager.load_game().
    Returns (state, error_msg). state is None on failure.
    """
    if not os.path.exists(path):
        return None, "file not found"
    with open(path, encoding="utf-8") as f:
        try:
            parsed = json.load(f)
        except json.JSONDecodeError as e:
            return None, f"JSON parse error: {e}"

    if not isinstance(parsed, dict):
        return None, "root is not a dict"

    state = {
        "game_state":       {},
        "chronicle_log":    [],
        "undo_stack":       [],
        "current_event_id": "",
        "pending_follow":   "",
        "gen":              {},
    }

    if "game_state" in parsed and isinstance(parsed["game_state"], dict):
        state["game_state"] = parsed["game_state"]
        if "flags" not in state["game_state"]:
            state["game_state"]["flags"] = {}
        if "season" not in state["game_state"]:
            state["game_state"]["season"] = 1

    if "chronicle_log" in parsed and isinstance(parsed["chronicle_log"], list):
        state["chronicle_log"] = parsed["chronicle_log"]
    if "undo_stack" in parsed and isinstance(parsed["undo_stack"], list):
        state["undo_stack"] = parsed["undo_stack"]
    if "current_event_id" in parsed:
        state["current_event_id"] = parsed["current_event_id"]
    if "pending_follow" in parsed and isinstance(parsed["pending_follow"], str):
        state["pending_follow"] = parsed["pending_follow"]
    if "gen" in parsed and isinstance(parsed["gen"], dict):
        state["gen"] = parsed["gen"]

    return state, None


def gd_save_game(path, game_state, chronicle_log, undo_stack,
                 current_event_id, pending_follow, gen):
    """Mirrors GameManager.save_game()."""
    data = {
        "game_state":       game_state,
        "chronicle_log":    chronicle_log,
        "undo_stack":       undo_stack,
        "current_event_id": current_event_id,
        "pending_follow":   pending_follow,
        "gen":              gen,
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent="\t", ensure_ascii=False)


# ---------------------------------------------------------------------------
# Test runner
# ---------------------------------------------------------------------------
PASS = 0
FAIL = 0
RESULTS = []


def ok(name, detail=""):
    global PASS
    PASS += 1
    RESULTS.append(("PASS", name, detail))


def fail(name, detail=""):
    global FAIL
    FAIL += 1
    RESULTS.append(("FAIL", name, detail))


def assert_eq(name, got, expected):
    if got == expected:
        ok(name)
    else:
        fail(name, f"expected {expected!r}, got {got!r}")


def assert_true(name, condition, detail=""):
    if condition:
        ok(name)
    else:
        fail(name, detail)


def assert_none(name, val, detail=""):
    if val is None:
        ok(name)
    else:
        fail(name, f"expected None, got {val!r}. {detail}")


def with_tempfile(data):
    """Write data dict to a temp file, return path."""
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".json",
                                    delete=False, encoding="utf-8")
    json.dump(data, f, ensure_ascii=False)
    f.close()
    return f.name


# ---------------------------------------------------------------------------
# Base fixtures
# ---------------------------------------------------------------------------
BASE_NPC = {
    "name": "Aldwin", "name_prefix": "Ald", "name_suffix": "win",
    "role": "Elder", "gender": "m", "age": 58,
    "father": {"name": "Galdric"}, "mother": {"name": "Mora"},
    "state": "Life here is hard.", "is_elder": True,
}

BASE_CHIEFTAIN = {
    "name": "Arulf", "name_prefix": "Ar", "name_suffix": "ulf",
    "gender": "m", "age": 31,
    "father": {"name": "Baldric"}, "mother": {"name": "Elriel"},
    "rule_start_year": 1,
    "has_spouse": False, "spouse": {},
    "has_heir": False, "heir": {},
}

BASE_SETTLEMENT = {
    "name": "Woodmarch", "location": "forest_edge",
    "primary_trade": "hunting", "tier": 1, "population": 72,
    "trades": ["Hunter", "Herb Woman"],
    "founding_id": "peaceful_pact", "founding_note": "",
    "founding_text": "Early trade ties...",
    "key_npcs": [copy.deepcopy(BASE_NPC)],
    "name_candidates": ["Woodmarch", "Fairwood"],
}

BASE_GS = {
    "alignment": 10,
    "settlement": copy.deepcopy(BASE_SETTLEMENT),
    "chieftain": copy.deepcopy(BASE_CHIEFTAIN),
    "generation": 1, "year": 3, "season": 2,
    "decision_count": 3, "flags": {},
}

BASE_LOG = [
    {"timestamp": 1748000000, "event_id": "village_founding",
     "delta": {}, "description": "Settlement founded.",
     "year": 1, "season": 1, "generation": 1},
]

BASE_UNDO = [
    {"game_state": copy.deepcopy(BASE_GS), "event_id": "first_winter"},
]


def base_save(**overrides):
    s = {
        "game_state":       copy.deepcopy(BASE_GS),
        "chronicle_log":    copy.deepcopy(BASE_LOG),
        "undo_stack":       copy.deepcopy(BASE_UNDO),
        "current_event_id": "trade_caravan",
        "pending_follow":   "",
        "gen":              {},
    }
    s.update(overrides)
    return s


# ---------------------------------------------------------------------------
# Test suites
# ---------------------------------------------------------------------------

def test_roundtrip():
    """Full save → load cycle preserves all fields exactly."""
    save = base_save(pending_follow="The fire crackles.", gen={"location": "highlands"})
    path = with_tempfile(save)
    try:
        state, err = gd_load_game(path)
        assert_none("roundtrip/no_error", err)
        assert_eq("roundtrip/alignment",       state["game_state"]["alignment"], 10)
        assert_eq("roundtrip/season",          state["game_state"]["season"], 2)
        assert_eq("roundtrip/generation",      state["game_state"]["generation"], 1)
        assert_eq("roundtrip/year",            state["game_state"]["year"], 3)
        assert_eq("roundtrip/decision_count",  state["game_state"]["decision_count"], 3)
        assert_eq("roundtrip/current_event_id",state["current_event_id"], "trade_caravan")
        assert_eq("roundtrip/chronicle_len",   len(state["chronicle_log"]), 1)
        assert_eq("roundtrip/undo_len",        len(state["undo_stack"]), 1)
        assert_eq("roundtrip/chieftain_name",  state["game_state"]["chieftain"]["name"], "Arulf")
        assert_eq("roundtrip/settlement_name", state["game_state"]["settlement"]["name"], "Woodmarch")
        assert_eq("roundtrip/population",      state["game_state"]["settlement"]["population"], 72)
        # Bug B regression
        assert_eq("roundtrip/pending_follow",  state["pending_follow"], "The fire crackles.")
        # Bug C regression
        assert_eq("roundtrip/gen_location",    state["gen"]["location"], "highlands")
    finally:
        os.unlink(path)


def test_backward_compat():
    """Old saves without pending_follow / gen still load cleanly (default to empty)."""
    old_save = {
        "game_state":       copy.deepcopy(BASE_GS),
        "chronicle_log":    copy.deepcopy(BASE_LOG),
        "undo_stack":       [],
        "current_event_id": "first_winter",
        # no pending_follow, no gen
    }
    path = with_tempfile(old_save)
    try:
        state, err = gd_load_game(path)
        assert_none("compat/no_error", err)
        assert_eq("compat/pending_follow_default", state["pending_follow"], "")
        assert_eq("compat/gen_default", state["gen"], {})
    finally:
        os.unlink(path)


def test_missing_flags_backfilled():
    """Old saves without flags key get flags={} injected (existing compat guard)."""
    gs = copy.deepcopy(BASE_GS)
    del gs["flags"]
    old_save = base_save(game_state=gs)
    path = with_tempfile(old_save)
    try:
        state, err = gd_load_game(path)
        assert_none("compat/flags/no_error", err)
        assert_eq("compat/flags/backfilled", state["game_state"]["flags"], {})
    finally:
        os.unlink(path)


def test_missing_season_backfilled():
    """Old saves without season key get season=1 injected."""
    gs = copy.deepcopy(BASE_GS)
    del gs["season"]
    old_save = base_save(game_state=gs)
    path = with_tempfile(old_save)
    try:
        state, err = gd_load_game(path)
        assert_none("compat/season/no_error", err)
        assert_eq("compat/season/backfilled", state["game_state"]["season"], 1)
    finally:
        os.unlink(path)


def test_flags_survive():
    """Flags set during play survive save/load."""
    gs = copy.deepcopy(BASE_GS)
    gs["flags"] = {"has_storehouse": True, "has_palisade": True}
    save = base_save(game_state=gs)
    path = with_tempfile(save)
    try:
        state, err = gd_load_game(path)
        assert_none("flags/no_error", err)
        flags = state["game_state"]["flags"]
        assert_true("flags/has_storehouse", flags.get("has_storehouse") is True)
        assert_true("flags/has_palisade",   flags.get("has_palisade") is True)
        assert_eq("flags/count", len(flags), 2)
    finally:
        os.unlink(path)


def test_heir_spouse_survive():
    """Chieftain spouse and heir data survive save/load."""
    gs = copy.deepcopy(BASE_GS)
    gs["chieftain"]["has_spouse"] = True
    gs["chieftain"]["spouse"] = {"name": "Sigwen", "name_prefix": "Sig", "name_suffix": "wen"}
    gs["chieftain"]["has_heir"] = True
    gs["chieftain"]["heir"] = {"name": "Arwen", "gender": "f", "birth_year": 8}
    save = base_save(game_state=gs)
    path = with_tempfile(save)
    try:
        state, err = gd_load_game(path)
        assert_none("heir/no_error", err)
        c = state["game_state"]["chieftain"]
        assert_true("heir/has_spouse",    c["has_spouse"] is True)
        assert_eq("heir/spouse_name",     c["spouse"]["name"], "Sigwen")
        assert_true("heir/has_heir",      c["has_heir"] is True)
        assert_eq("heir/heir_name",       c["heir"]["name"], "Arwen")
        assert_eq("heir/heir_birth_year", c["heir"]["birth_year"], 8)
    finally:
        os.unlink(path)


def test_chronicle_log_survives():
    """Chronicle log with multiple entries survives roundtrip."""
    log = [
        {"timestamp": 1748000000, "event_id": "village_founding",
         "delta": {}, "description": "Founded.", "year": 1, "season": 1, "generation": 1},
        {"timestamp": 1748000010, "event_id": "first_winter",
         "delta": {"alignment": 5}, "description": "Shared equally.",
         "year": 1, "season": 2, "generation": 1},
        {"timestamp": 1748000020, "event_id": "generation_advance",
         "delta": {"generation": 2}, "description": "Gen 2 begins.",
         "year": 26, "season": 1, "generation": 2},
    ]
    save = base_save(chronicle_log=log)
    path = with_tempfile(save)
    try:
        state, err = gd_load_game(path)
        assert_none("chronicle/no_error", err)
        assert_eq("chronicle/length", len(state["chronicle_log"]), 3)
        assert_eq("chronicle/entry0_id",    state["chronicle_log"][0]["event_id"], "village_founding")
        assert_eq("chronicle/entry1_delta", state["chronicle_log"][1]["delta"]["alignment"], 5)
        assert_eq("chronicle/entry2_gen",   state["chronicle_log"][2]["generation"], 2)
    finally:
        os.unlink(path)


def test_undo_stack_survives():
    """Undo stack entries survive roundtrip."""
    snap1 = {"game_state": copy.deepcopy(BASE_GS), "event_id": "first_winter"}
    snap2_gs = copy.deepcopy(BASE_GS)
    snap2_gs["alignment"] = 20
    snap2 = {"game_state": snap2_gs, "event_id": "trade_caravan"}
    save = base_save(undo_stack=[snap1, snap2])
    path = with_tempfile(save)
    try:
        state, err = gd_load_game(path)
        assert_none("undo/no_error", err)
        assert_eq("undo/stack_len", len(state["undo_stack"]), 2)
        assert_eq("undo/snap0_event", state["undo_stack"][0]["event_id"], "first_winter")
        assert_eq("undo/snap1_alignment", state["undo_stack"][1]["game_state"]["alignment"], 20)
    finally:
        os.unlink(path)


def test_generation2_state():
    """Generation 2 save with year 26 loads correctly."""
    gs = copy.deepcopy(BASE_GS)
    gs["generation"] = 2
    gs["year"] = 26
    gs["chieftain"] = {
        **copy.deepcopy(BASE_CHIEFTAIN),
        "name": "Elrald", "rule_start_year": 26, "age": 25,
    }
    save = base_save(game_state=gs, current_event_id="great_fire")
    path = with_tempfile(save)
    try:
        state, err = gd_load_game(path)
        assert_none("gen2/no_error", err)
        assert_eq("gen2/generation",     state["game_state"]["generation"], 2)
        assert_eq("gen2/year",           state["game_state"]["year"], 26)
        assert_eq("gen2/chieftain_name", state["game_state"]["chieftain"]["name"], "Elrald")
        assert_eq("gen2/event_id",       state["current_event_id"], "great_fire")
    finally:
        os.unlink(path)


def test_naming_pending():
    """Naming-pending state: decision_count>=5, empty village name, correct event_id."""
    gs = copy.deepcopy(BASE_GS)
    gs["decision_count"] = 5
    gs["settlement"]["name"] = ""
    save = base_save(game_state=gs, current_event_id="village_naming")
    path = with_tempfile(save)
    try:
        state, err = gd_load_game(path)
        assert_none("naming/no_error", err)
        assert_eq("naming/event_id",       state["current_event_id"], "village_naming")
        assert_eq("naming/village_name",   state["game_state"]["settlement"]["name"], "")
        assert_eq("naming/decision_count", state["game_state"]["decision_count"], 5)
    finally:
        os.unlink(path)


def test_guided_founding_gen_survives():
    """Bug C regression: _gen dict with location survives save/load."""
    gen_data = {"location": "highlands", "primary_trade": "mining",
                "pop_mod": -1, "align_mod": -5}
    save = base_save(current_event_id="gen_choose_trade", gen=gen_data)
    path = with_tempfile(save)
    try:
        state, err = gd_load_game(path)
        assert_none("bug_c/no_error", err)
        assert_eq("bug_c/location",      state["gen"]["location"], "highlands")
        assert_eq("bug_c/primary_trade", state["gen"]["primary_trade"], "mining")
        assert_eq("bug_c/pop_mod",       state["gen"]["pop_mod"], -1)
    finally:
        os.unlink(path)


def test_pending_follow_survives():
    """Bug B regression: pending_follow text survives save/load."""
    follow = "The beams rise quickly. In the evenings, people gather."
    save = base_save(pending_follow=follow)
    path = with_tempfile(save)
    try:
        state, err = gd_load_game(path)
        assert_none("bug_b/no_error", err)
        assert_eq("bug_b/pending_follow", state["pending_follow"], follow)
    finally:
        os.unlink(path)


def test_corrupt_json():
    """Corrupt JSON file returns error, does not crash."""
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".json",
                                    delete=False, encoding="utf-8")
    f.write("{not valid json{{")
    f.close()
    try:
        state, err = gd_load_game(f.name)
        assert_true("corrupt/returns_none", state is None, "state should be None")
        assert_true("corrupt/has_error",    err is not None, "err should not be None")
    finally:
        os.unlink(f.name)


def test_missing_file():
    """Non-existent file returns error cleanly."""
    state, err = gd_load_game("/does/not/exist.json")
    assert_true("missing/returns_none", state is None)
    assert_true("missing/has_error",    err is not None)


def test_wrong_types_ignored_gracefully():
    """Wrong types for optional fields don't crash load — fallback to defaults."""
    bad_save = {
        "game_state":       copy.deepcopy(BASE_GS),
        "chronicle_log":    "not a list",   # wrong type
        "undo_stack":       42,             # wrong type
        "current_event_id": "border_dispute",
        "pending_follow":   123,            # wrong type — should be ignored
        "gen":              "oops",         # wrong type — should be ignored
    }
    path = with_tempfile(bad_save)
    try:
        state, err = gd_load_game(path)
        assert_none("wrong_types/no_error", err)
        assert_eq("wrong_types/chronicle_default", state["chronicle_log"], [])
        assert_eq("wrong_types/undo_default",      state["undo_stack"], [])
        assert_eq("wrong_types/pending_default",   state["pending_follow"], "")
        assert_eq("wrong_types/gen_default",       state["gen"], {})
    finally:
        os.unlink(path)


def test_all_scenarios_from_validate():
    """Load all 6 synthetic test saves from tools/test_saves/ and verify they parse."""
    test_save_dir = os.path.join(SCRIPT_DIR, "test_saves")
    if not os.path.isdir(test_save_dir):
        fail("scenarios/dir_exists",
             f"Run 'python tools/validate_save.py --gen' first to create test saves")
        return

    files = sorted(f for f in os.listdir(test_save_dir) if f.endswith(".json"))
    if not files:
        fail("scenarios/files_exist", "No test save files found")
        return

    for fname in files:
        path = os.path.join(test_save_dir, fname)
        state, err = gd_load_game(path)
        assert_none(f"scenarios/{fname}/no_error", err)
        if state:
            assert_true(f"scenarios/{fname}/has_game_state",
                        isinstance(state["game_state"], dict))
            assert_true(f"scenarios/{fname}/has_chieftain",
                        bool(state["game_state"].get("chieftain")))


# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
SUITES = [
    test_roundtrip,
    test_backward_compat,
    test_missing_flags_backfilled,
    test_missing_season_backfilled,
    test_flags_survive,
    test_heir_spouse_survive,
    test_chronicle_log_survives,
    test_undo_stack_survives,
    test_generation2_state,
    test_naming_pending,
    test_guided_founding_gen_survives,
    test_pending_follow_survives,
    test_corrupt_json,
    test_missing_file,
    test_wrong_types_ignored_gracefully,
    test_all_scenarios_from_validate,
]


def main():
    print("Chronicle Sim - Save/Load Test Suite")
    print("=" * 60)

    for suite in SUITES:
        suite()

    print()
    col_w = max(len(r[1]) for r in RESULTS)
    for status, name, detail in RESULTS:
        line = f"  [{status}] {name:<{col_w}}"
        if detail:
            line += f"  ({detail})"
        print(line)

    print()
    total = PASS + FAIL
    print(f"Results: {PASS}/{total} passed", end="")
    if FAIL:
        print(f"  --  {FAIL} FAILED")
    else:
        print("  --  all green")

    sys.exit(0 if FAIL == 0 else 1)


if __name__ == "__main__":
    main()
