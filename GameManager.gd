extends Node
## GameManager — Autoload Singleton

signal state_changed(new_state: Dictionary)
signal event_triggered(event_id: String, text: String, choices: Array)
signal generation_advanced(summary: String)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const SAVE_PATH      := "user://savegame.json"
const MAX_UNDO_STEPS := 5

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var game_state: Dictionary = {
	"alignment":      0,
	"settlement":     {},
	"chieftain":      {},
	"generation":     1,
	"year":           1,
	"decision_count": 0,
}

var chronicle_log:    Array  = []
var undo_stack:       Array  = []
var current_event_id: String = ""

## Temp during generation / naming (not persisted)
var _gen:         Dictionary = {}
var _gen_choices: Array      = []

# ---------------------------------------------------------------------------
# Name-syllable system (Tolkien-/Germanic-inspired, inheritable)
# ---------------------------------------------------------------------------
## Shared prefix pool — used by both genders so inheritance works cleanly
const NAME_PREFIX: Array = [
	"Ar", "Ara", "Al", "Ald", "El", "Eld", "Elr", "Er", "An", "And",
	"Bal", "Ber", "Bor", "Brun", "Dag", "Ek", "Far", "Gal", "Gar",
	"Gil", "Grim", "Gun", "Har", "Helm", "Id", "Ing", "Isg",
	"Kund", "Leg", "Mor", "Nim", "Od", "Rein", "Riv", "Ros", "Run",
	"Sig", "Sil", "Thor", "Ul", "Wald", "Walt", "Wig", "Wulf",
]

const NAME_SUFFIX_M: Array = [
	"orn", "ulf", "ald", "helm", "gar", "mar", "ric", "win",
	"hard", "mund", "bert", "bald", "ran", "red", "olf", "man",
	"old", "mir", "din", "rod", "gorn", "dorn", "fen", "gor",
	"und", "brand", "olf", "win",
]

const NAME_SUFFIX_F: Array = [
	"a", "e", "wen", "hild", "run", "gard", "riel", "ien",
	"wyn", "eth", "in", "dis", "is", "ael", "ela", "ena",
	"ira", "ara", "onda", "wen", "eith",
]

# ---------------------------------------------------------------------------
# NPC data
# ---------------------------------------------------------------------------
const TRADE_ROLES: Dictionary = {
	"hunting":     {"m": "Hunt Master",       "f": "Huntress"},
	"fishing":     {"m": "Fisher Master",     "f": "Fisher"},
	"metalwork":   {"m": "Bronze Caster",     "f": "Bronze Caster"},
	"carpentry":   {"m": "Master Carpenter",  "f": "Carpenter"},
	"herbs":       {"m": "Herb Trader",       "f": "Herb Woman"},
	"trade":       {"m": "Merchant",          "f": "Merchant"},
	"mining":      {"m": "Miner",             "f": "Miner"},
	"shipbuilding":{"m": "Boat Builder",      "f": "Boat Builder"},
	"crafts":      {"m": "Master Craftsman",  "f": "Craftswoman"},
}

const NPC_STATES: Dictionary = {
	"high":     [
		"I am grateful for what we have built together.",
		"The gods smile upon us — of that I have no doubt.",
		"My children will have a good life here.",
	],
	"medium":   [
		"Life here is hard, but fair.",
		"I trust the elder council — most of the time.",
		"It could have been worse.",
	],
	"neutral":  [
		"I live from one day to the next.",
		"I sometimes wish for more from life.",
		"Sometimes I dream of distant lands.",
	],
	"low":      [
		"I distrust the council. They think of themselves first.",
		"I am considering leaving the village.",
		"The strong feed while the weak starve.",
	],
	"very_low": [
		"This village deserves its misfortune.",
		"I would flee if I could.",
		"The gods have abandoned us.",
	],
}

# ---------------------------------------------------------------------------
# Village name generation tables
# ---------------------------------------------------------------------------
const VILLAGE_NAME_PREFIX: Dictionary = {
	"forest_edge": ["Wood", "Beech", "Oak", "Moss", "Birch", "Shadow"],
	"riverbank":   ["Brook", "Spring", "Water", "Stream", "Reed", "Willow"],
	"highlands":   ["Stone", "Cliff", "Hill", "High", "Grey", "Crag"],
	"coast":       ["Sea", "Wave", "Storm", "Ember", "Haven", "Crag"],
}

const VILLAGE_NAME_SUFFIX: Dictionary = {
	"hunting":     ["wood", "grove", "march", "fen"],
	"fishing":     ["ford", "fen", "mere", "beck"],
	"metalwork":   ["forge", "ore", "hammer", "anvil"],
	"carpentry":   ["town", "home", "stead", "croft"],
	"herbs":       ["lea", "herb", "grove", "garden"],
	"trade":       ["market", "inn", "gate", "square"],
	"mining":      ["shaft", "lode", "pit", "drift"],
	"shipbuilding":["haven", "dock", "bay", "shore"],
	"crafts":      ["town", "home", "works", "croft"],
}

const VILLAGE_NAME_ALIGN_PREFIX: Dictionary = {
	"high": ["Light", "Clear", "Blessed", "Fair"],
	"low":  ["Shadow", "Dark", "Ash", "Grey"],
}

const VILLAGE_NAME_FOUNDING: Dictionary = {
	"rich_harvest":  ["Rich", "Fruit", "Harvest", "Blessed"],
	"great_drought": ["Ash", "Dry", "Hard", "Ember"],
	"raid_survived": ["Shield", "Ward", "Defiant", "Strong"],
	"peaceful_pact": ["Friend", "Bond", "Peace", "True"],
	"plague":        ["New", "Hard", "Mould", "Spare"],
	"ore_vein":      ["Ore", "Gold", "Rich", "Spark"],
}

# ---------------------------------------------------------------------------
# Settlement generation tables
# ---------------------------------------------------------------------------
const LOCATION_NAMES: Dictionary = {
	"forest_edge": "Forest Edge",
	"riverbank":   "Riverbank",
	"highlands":   "Highlands",
	"coast":       "Coast",
}

const LOCATION_TRADES: Dictionary = {
	"forest_edge": ["Hunter", "Fletcher", "Basket Weaver", "Herb Woman", "Carpenter", "Tanner"],
	"riverbank":   ["Fisher", "Potter", "Merchant", "Herb Woman", "Weaver", "Carpenter"],
	"highlands":   ["Bronze Caster", "Tanner", "Hunter", "Herb Woman", "Carpenter", "Potter"],
	"coast":       ["Fisher", "Merchant", "Rope Maker", "Potter", "Herb Woman", "Carpenter"],
}

const TRADE_OPTIONS: Dictionary = {
	"forest_edge": [
		{"label": "Hunting & Forestry",      "id": "hunting",     "pop_mod":  0, "align_mod":  0},
		{"label": "Herbalism & Healing",      "id": "herbs",       "pop_mod":  0, "align_mod":  5},
		{"label": "Logging & Carpentry",      "id": "carpentry",   "pop_mod":  1, "align_mod":  0},
	],
	"riverbank": [
		{"label": "Fishing",                  "id": "fishing",     "pop_mod":  1, "align_mod":  0},
		{"label": "Pottery & Trade",          "id": "trade",       "pop_mod":  1, "align_mod":  0},
		{"label": "Weaving & Crafts",         "id": "crafts",      "pop_mod":  0, "align_mod":  5},
	],
	"highlands": [
		{"label": "Bronze Casting & Weapons", "id": "metalwork",   "pop_mod": -1, "align_mod": -5},
		{"label": "Hunting & Tanning",        "id": "hunting",     "pop_mod":  0, "align_mod":  0},
		{"label": "Mining",                   "id": "mining",      "pop_mod": -1, "align_mod": -5},
	],
	"coast": [
		{"label": "Fishing & Seafaring",      "id": "fishing",     "pop_mod":  1, "align_mod":  0},
		{"label": "Trade & Barter Market",    "id": "trade",       "pop_mod":  1, "align_mod":  5},
		{"label": "Rope Making & Shipbuilding","id": "shipbuilding","pop_mod":  0, "align_mod":  0},
	],
}

const POPULATION_TIERS: Array = [
	{"name": "Hamlet",       "desc": "souls", "min": 5,   "max": 15},
	{"name": "Small Village","desc": "souls", "min": 16,  "max": 40},
	{"name": "Village",      "desc": "souls", "min": 41,  "max": 80},
	{"name": "Large Village","desc": "souls", "min": 81,  "max": 150},
	{"name": "Market Town",  "desc": "souls", "min": 151, "max": 300},
]

const FOUNDING_EVENTS: Array = [
	{"id": "rich_harvest",  "text": "An exceptionally rich harvest in the founding years secured survival and strengthened the bonds of the community.",       "align_mod":  10, "note": "Fertile land, prosperous founding season"},
	{"id": "great_drought", "text": "A severe drought tested the first settlers. Only the hardiest survived — and they never forgot it.",                    "align_mod":  -5, "note": "Scars of the founding drought"},
	{"id": "raid_survived", "text": "A raid by a neighbouring tribe was repelled. The community grew stronger — but also more suspicious of outsiders.",     "align_mod":  -5, "note": "Old enmity with a neighbouring tribe"},
	{"id": "peaceful_pact", "text": "Early trade ties with a neighbouring tribe brought prosperity and mutual trust.",                                        "align_mod":  10, "note": "Ancient alliance with the neighbours"},
	{"id": "plague",        "text": "A plague claimed many of the first settlers. The village survived — smaller, but tougher.",                            "align_mod":   0, "note": "Memory of the Great Plague"},
	{"id": "ore_vein",      "text": "A bronze ore vein discovered nearby made the settlement coveted — both a curse and a blessing.",                       "align_mod":  -5, "note": "Known ore vein in the vicinity"},
]

# ---------------------------------------------------------------------------
# Game events — geladen aus res://events.json
# ---------------------------------------------------------------------------
var EVENTS: Dictionary = {}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_load_events()
	call_deferred("_initialize")


func _load_events() -> void:
	var dir := DirAccess.open("res://events/")
	if dir == null:
		push_error("GameManager: events/ folder not found.")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file := FileAccess.open("res://events/" + file_name, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				file.close()
				if parsed is Dictionary:
					EVENTS.merge(parsed)
				else:
					push_error("GameManager: Could not parse events/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _initialize() -> void:
	if not load_game():
		_emit_gen_event("gen_new_game_choice")
	else:
		state_changed.emit(game_state.duplicate(true))
		event_triggered.emit("resume", "── Save game loaded ──\nWelcome back, Chronicler.", [])

# ---------------------------------------------------------------------------
# Settlement generation flow
# ---------------------------------------------------------------------------
func _emit_gen_event(event_id: String) -> void:
	push_undo_snapshot()
	current_event_id = event_id
	var text:    String = ""
	var choices: Array  = []

	match event_id:
		"gen_new_game_choice":
			text = ("[b]── Chronicle Sim ──[/b]\n\n"
				  + "A new chapter begins.\n"
				  + "How shall the fate of your settlement be decided?")
			choices = [
				{"label": "Quick Start — let fate roll the dice for us"},
				{"label": "Guided Founding — we shape our own destiny"},
			]
		"gen_choose_location":
			text = ("[b]── Choose Your Location ──[/b]\n\n"
				  + "Where shall your settlement take root?\n"
				  + "The location shapes everything: trade, survival, future.")
			choices = [
				{"label": "Forest Edge — hunting, timber, herbs",       "loc": "forest_edge"},
				{"label": "Riverbank — fishing, clay, trade",           "loc": "riverbank"},
				{"label": "Highlands — ore, bronze, mining",            "loc": "highlands"},
				{"label": "Coast — fishing, seafaring, trade",          "loc": "coast"},
			]
		"gen_choose_trade":
			var loc:  String = _gen.get("location", "forest_edge")
			var opts: Array  = TRADE_OPTIONS.get(loc, [])
			text = "[b]── Primary Trade ──[/b]\n\nWhich craft shall be the foundation of your settlement?"
			for opt: Dictionary in opts:
				choices.append({"label": opt["label"], "opt": opt})

	_gen_choices = choices
	event_triggered.emit(event_id, text, choices)


func _apply_gen_choice(choice_index: int) -> void:
	if choice_index >= _gen_choices.size():
		return
	var choice: Dictionary = _gen_choices[choice_index]

	match current_event_id:
		"gen_new_game_choice":
			if choice_index == 0:
				_generate_quick()
			else:
				call_deferred("_emit_gen_event", "gen_choose_location")
		"gen_choose_location":
			_gen["location"] = choice.get("loc", "forest_edge")
			_log_entry(current_event_id, {}, "Location chosen: " + choice.get("label", ""))
			call_deferred("_emit_gen_event", "gen_choose_trade")
		"gen_choose_trade":
			var opt: Dictionary = choice.get("opt", {})
			_gen["primary_trade"] = opt.get("id", "hunting")
			_gen["pop_mod"]       = opt.get("pop_mod", 0)
			_gen["align_mod"]     = opt.get("align_mod", 0)
			_log_entry(current_event_id, {}, "Primary trade chosen: " + choice.get("label", ""))
			_finalize_generation()


func _generate_quick() -> void:
	var locs: Array = ["forest_edge", "riverbank", "highlands", "coast"]
	_gen["location"] = locs[randi() % locs.size()]
	var opts: Array      = TRADE_OPTIONS.get(_gen["location"], [])
	var opt:  Dictionary = opts[randi() % opts.size()]
	_gen["primary_trade"] = opt.get("id", "hunting")
	_gen["pop_mod"]       = opt.get("pop_mod", 0)
	_gen["align_mod"]     = opt.get("align_mod", 0)
	_finalize_generation()


func _finalize_generation() -> void:
	var loc:       String = _gen.get("location", "forest_edge")
	var trade:     String = _gen.get("primary_trade", "hunting")
	var pop_mod:   int    = _gen.get("pop_mod", 0)
	var align_mod: int    = _gen.get("align_mod", 0)

	# Population tier + fixed count
	var tier: int = clamp(randi() % 4 + pop_mod, 0, POPULATION_TIERS.size() - 1)
	var t:    Dictionary = POPULATION_TIERS[tier]
	var pop:  int = t["min"] + randi() % (t["max"] - t["min"] + 1)

	# Founding event
	var founding: Dictionary = FOUNDING_EVENTS[randi() % FOUNDING_EVENTS.size()]

	# Trades (always include a healer)
	var pool:   Array = LOCATION_TRADES.get(loc, []).duplicate()
	pool.shuffle()
	var count:  int   = clamp(3 + randi() % 3, 3, pool.size())
	var trades: Array = pool.slice(0, count)
	if not ("Herb Woman" in trades or "Healer" in trades):
		trades.append("Herb Woman")

	# Alignment
	var alignment: int = clamp(align_mod + founding.get("align_mod", 0), -100, 100)
	game_state["alignment"] = alignment

	# NPCs (Kronrat)
	var npcs: Array = _generate_kronrat(trade, alignment)

	# Name candidates
	var candidates: Array = _build_name_candidates(loc, trade, alignment, founding.get("id", ""))

	# Chieftain (chosen by Kronrat from the village's families)
	var chieftain: Dictionary = _gen_chieftain_from_kronrat(npcs, alignment)
	game_state["chieftain"] = chieftain

	game_state["settlement"] = {
		"name":           "",
		"location":       loc,
		"primary_trade":  trade,
		"tier":           tier,
		"population":     pop,
		"trades":         trades,
		"founding_id":    founding.get("id", ""),
		"founding_note":  founding.get("note", ""),
		"founding_text":  founding.get("text", ""),
		"key_npcs":       npcs,
		"name_candidates":candidates,
	}

	_log_entry("settlement_generated", {"alignment": alignment},
		"Settlement founded: %s at the %s, %d souls. Chieftain: %s." % [
			POPULATION_TIERS[tier]["name"],
			LOCATION_NAMES.get(loc, loc),
			pop,
			chieftain.get("name", "?"),
		])
	_log_entry("chieftain_new", {}, "Chieftain %s takes command (from year 1)." % chieftain.get("name", "?"))

	state_changed.emit(game_state.duplicate(true))
	call_deferred("trigger_event", "village_founding")

# ---------------------------------------------------------------------------
# Village naming (triggers after 5 decisions)
# ---------------------------------------------------------------------------
func _check_naming_trigger() -> void:
	var already_named: bool = game_state.get("settlement", {}).get("name", "") != ""
	if not already_named and game_state.get("decision_count", 0) >= 5:
		call_deferred("_trigger_naming_event")


func _trigger_naming_event() -> void:
	push_undo_snapshot()
	current_event_id = "village_naming"
	_emit_naming_choices()


func _re_emit_naming_event() -> void:
	## Re-emits without pushing undo — used by pop_undo_snapshot
	current_event_id = "village_naming"
	_emit_naming_choices()


func _emit_naming_choices() -> void:
	var s:          Dictionary = game_state.get("settlement", {})
	var candidates: Array      = s.get("name_candidates", [])

	var elder_name: String = _get_elder_name()
	var alignment:  int    = game_state.get("alignment", 0)
	var rec_idx:    int    = 1 if alignment >= 40 else 0
	var recommended: String = candidates[min(rec_idx, candidates.size() - 1)] if not candidates.is_empty() else "Unknown"

	var text: String = (
		"[b]── A Name Takes Root ──[/b]\n\n"
		+ "The people of the surrounding lands have begun to name your settlement.\n"
		+ "Several names circulate in the tales of merchants and travellers.\n\n"
		+ "%s counsels the council:\n[i]»%s« — this name reflects who we are.[/i]" % [elder_name, recommended]
	)

	var choices: Array = []
	for name: String in candidates:
		choices.append({"label": "»%s« — this shall be our village's name" % name, "chosen_name": name})

	_gen_choices = choices
	event_triggered.emit("village_naming", text, choices)


func _apply_naming_choice(choice_index: int) -> void:
	if choice_index >= _gen_choices.size():
		return
	var chosen: String = _gen_choices[choice_index].get("chosen_name", "")
	game_state["settlement"]["name"] = chosen
	_log_entry("village_naming", {}, "The village received its name: »%s«." % chosen)
	state_changed.emit(game_state.duplicate(true))
	event_triggered.emit("village_named",
		"[b]»%s«[/b]\n\nFrom this day forth, the people call your settlement by this name.\nIt rings out in the songs of merchants and along the roads of travellers." % chosen,
		[]
	)


func _build_name_candidates(loc: String, trade: String, alignment: int, founding_id: String) -> Array:
	var prefixes: Array = VILLAGE_NAME_PREFIX.get(loc, ["Old"]).duplicate()
	var suffixes: Array = VILLAGE_NAME_SUFFIX.get(trade, ["town"]).duplicate()
	prefixes.shuffle()
	suffixes.shuffle()

	# 1: Descriptive — location prefix + trade suffix
	var name1: String = prefixes[0] + suffixes[0]

	# 2: Alignment-coloured
	var align_key: String = "high" if alignment >= 40 else ("low" if alignment <= -40 else "")
	var name2: String
	if align_key != "":
		var ap: Array = VILLAGE_NAME_ALIGN_PREFIX.get(align_key, ["Old"]).duplicate()
		ap.shuffle()
		name2 = ap[0] + suffixes[min(1, suffixes.size() - 1)]
	else:
		name2 = prefixes[min(1, prefixes.size() - 1)] + suffixes[min(1, suffixes.size() - 1)]

	# 3: Founding event themed
	var fc: Array = VILLAGE_NAME_FOUNDING.get(founding_id, ["Old"]).duplicate()
	fc.shuffle()
	var name3: String = fc[0] + suffixes[min(2, suffixes.size() - 1)]

	# Avoid duplicates
	var result: Array = [name1]
	if name2 != name1:
		result.append(name2)
	else:
		result.append(prefixes[min(2, prefixes.size()-1)] + suffixes[0])
	if name3 != name1 and name3 != name2:
		result.append(name3)
	else:
		result.append(prefixes[0] + suffixes[min(2, suffixes.size()-1)])

	return result


func _get_elder_name() -> String:
	for npc: Dictionary in game_state.get("settlement", {}).get("key_npcs", []):
		if npc.get("is_elder", false):
			return npc.get("name", "The Elder Council")
	return "The Elder Council"

# ---------------------------------------------------------------------------
# NPC / Kronrat generation
# ---------------------------------------------------------------------------
func _gen_person_name(female: bool) -> Dictionary:
	var prefix: String = NAME_PREFIX[randi() % NAME_PREFIX.size()]
	var s_pool: Array  = NAME_SUFFIX_F if female else NAME_SUFFIX_M
	var suffix: String = s_pool[randi() % s_pool.size()]
	return {"name": prefix + suffix, "name_prefix": prefix, "name_suffix": suffix}


func _gen_child_name(parent_a: Dictionary, parent_b: Dictionary, female: bool) -> Dictionary:
	## Inherits prefix from one parent, new suffix — creates family resemblance
	var p:      Dictionary = parent_a if randi() % 2 == 0 else parent_b
	var prefix: String     = p.get("name_prefix", NAME_PREFIX[randi() % NAME_PREFIX.size()])
	var s_pool: Array      = NAME_SUFFIX_F if female else NAME_SUFFIX_M
	var suffix: String     = s_pool[randi() % s_pool.size()]
	return {"name": prefix + suffix, "name_prefix": prefix, "name_suffix": suffix}


func _make_npc(role: String, female: bool, age: int, alignment: int, is_elder: bool) -> Dictionary:
	var father:    Dictionary = _gen_person_name(false)
	var mother:    Dictionary = _gen_person_name(true)
	var name_data: Dictionary = _gen_child_name(father, mother, female)
	return {
		"name":        name_data["name"],
		"name_prefix": name_data["name_prefix"],
		"name_suffix": name_data["name_suffix"],
		"role":        role,
		"gender":      "f" if female else "m",
		"age":         age,
		"father":      father,
		"mother":      mother,
		"state":       _pick_npc_state(alignment),
		"is_elder":    is_elder,
	}


func _generate_kronrat(primary_trade: String, alignment: int) -> Array:
	var npcs: Array = []

	# 1. Elder (Älteste/r) — random gender, old
	var elder_female: bool = randi() % 2 == 0
	npcs.append(_make_npc(
		"Elder" if elder_female else "Elder",
		elder_female, 45 + randi() % 22, alignment, true
	))

	# 2. Healer — female by default
	npcs.append(_make_npc("Healer", true, 28 + randi() % 28, alignment, false))

	# 3. Trade specialist
	if TRADE_ROLES.has(primary_trade):
		var info:      Dictionary = TRADE_ROLES[primary_trade]
		var is_female: bool       = randi() % 3 == 0
		npcs.append(_make_npc(
			info["f"] if is_female else info["m"],
			is_female, 24 + randi() % 25, alignment, false
		))

	# 4–5. Two more (random roles, no repetition)
	var extra_roles: Array = ["Warrior", "Farmer", "Councillor", "Merchant", "Carpenter", "Fletcher"]
	extra_roles.shuffle()
	for i: int in 2:
		var f: bool = randi() % 2 == 0
		npcs.append(_make_npc(extra_roles[i], f, 20 + randi() % 30, alignment, false))

	return npcs


func _gen_chieftain_from_kronrat(npcs: Array, alignment: int) -> Dictionary:
	## Chieftain name is derived from a Kronrat member's family line
	var base: Dictionary = npcs[randi() % npcs.size()] if not npcs.is_empty() else {}
	var father: Dictionary = base.get("father", _gen_person_name(false))
	var mother: Dictionary = base.get("mother", _gen_person_name(true))

	var female:    bool        = randi() % 3 == 0   # 33% female chieftain
	var name_data: Dictionary  = _gen_child_name(father, mother, female)

	return {
		"name":             name_data["name"],
		"name_prefix":      name_data["name_prefix"],
		"name_suffix":      name_data["name_suffix"],
		"gender":           "f" if female else "m",
		"age":              22 + randi() % 18,
		"father":           father,
		"mother":           mother,
		"rule_start_year":  1,
	}


func _pick_npc_state(alignment: int) -> String:
	var key: String
	if   alignment >=  60: key = "high"
	elif alignment >=  20: key = "medium"
	elif alignment >= -20: key = "neutral"
	elif alignment >= -60: key = "low"
	else:                  key = "very_low"
	var pool: Array = NPC_STATES.get(key, ["..."])
	return pool[randi() % pool.size()]

# ---------------------------------------------------------------------------
# Core event system
# ---------------------------------------------------------------------------
func trigger_event(event_id: String) -> void:
	if not EVENTS.has(event_id) or not EVENTS[event_id] is Dictionary:
		push_warning("GameManager: Unknown or invalid event ID '%s'" % event_id)
		return

	push_undo_snapshot()
	current_event_id = event_id

	var event:        Dictionary = EVENTS[event_id]
	var display_text: String     = "[b]── %s ──[/b]\n%s" % [
		event.get("title", event_id),
		_format_text(event.get("text", "")),
	]

	_log_entry(event_id, {}, "Event: " + event.get("title", event_id))
	event_triggered.emit(event_id, display_text, event.get("choices", []))


func apply_choice(event_id: String, choice_index: int) -> void:
	if event_id.begins_with("gen_"):
		_apply_gen_choice(choice_index)
		return
	if event_id == "village_naming":
		_apply_naming_choice(choice_index)
		return

	if not EVENTS.has(event_id):
		return
	var choices: Array = EVENTS[event_id].get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return

	var choice: Dictionary = choices[choice_index]
	var effect: Dictionary = choice.get("effect", {})
	var delta:  Dictionary = {}

	for stat: String in effect:
		if stat == "population":
			var current_pop: int = game_state.get("settlement", {}).get("population", 0)
			game_state["settlement"]["population"] = max(1, current_pop + int(effect[stat]))
			delta[stat] = int(effect[stat])
		else:
			var val: int = game_state.get(stat, 0) + int(effect[stat])
			if stat == "alignment":
				val = clamp(val, -100, 100)
			game_state[stat] = val
			delta[stat]      = int(effect[stat])

	game_state["decision_count"] = game_state.get("decision_count", 0) + 1

	_log_entry(event_id, delta, choice.get("log_text", "Entscheidung getroffen."))
	state_changed.emit(game_state.duplicate(true))

	var follow: String = choice.get("follow_text", "")
	if follow != "":
		event_triggered.emit("follow", "[i]" + _format_text(follow) + "[/i]", [])

	_check_naming_trigger()

	var next: String = choice.get("next_event", "")
	var naming_pending: bool = (
		game_state.get("settlement", {}).get("name", "") == ""
		and game_state.get("decision_count", 0) >= 5
	)
	if next != "":
		call_deferred("trigger_event", next)
	elif not naming_pending:
		call_deferred("_pick_and_trigger_next_event")

func _pick_and_trigger_next_event() -> void:
	## Picks a random unplayed event that matches current game conditions.
	var played: Array = []
	for entry: Dictionary in chronicle_log:
		var eid: String = str(entry.get("event_id", ""))
		if not played.has(eid):
			played.append(eid)

	var alignment:  int    = game_state.get("alignment", 0)
	var generation: int    = game_state.get("generation", 1)
	var trade:      String = game_state.get("settlement", {}).get("primary_trade", "")

	var pool: Array = []
	for eid: String in EVENTS.keys():
		if eid == "village_founding" or eid.begins_with("_") or not EVENTS[eid] is Dictionary:
			continue
		if played.has(eid):
			continue
		var cond: Dictionary = EVENTS[eid].get("conditions", {})
		if alignment  < int(cond.get("alignment_min",  -100)): continue
		if alignment  > int(cond.get("alignment_max",   100)): continue
		if generation < int(cond.get("generation_min",    1)): continue
		if generation > int(cond.get("generation_max",  999)): continue
		var req_trade: String = str(cond.get("trade", ""))
		if req_trade != "" and req_trade != trade:              continue
		pool.append(eid)

	if pool.is_empty():
		return

	pool.shuffle()
	trigger_event(pool[0])

# ---------------------------------------------------------------------------
# Generation advancement
# ---------------------------------------------------------------------------
func advance_generation() -> void:
	push_undo_snapshot()

	# Record old chieftain's reign
	var old: Dictionary = game_state.get("chieftain", {})
	if not old.is_empty():
		_log_entry("chieftain_end", {},
			"End of reign: Chieftain %s (year %d–%d)." % [
				old.get("name", "?"),
				old.get("rule_start_year", 1),
				game_state["year"],
			])

	game_state["generation"] += 1
	game_state["year"]       += 25

	# New chieftain chosen by council
	var npcs:         Array      = game_state.get("settlement", {}).get("key_npcs", [])
	var new_chief:    Dictionary = _gen_chieftain_from_kronrat(npcs, game_state["alignment"])
	new_chief["rule_start_year"] = game_state["year"]
	game_state["chieftain"]      = new_chief

	_log_entry("chieftain_new", {},
		"New chieftain: %s (from year %d)." % [new_chief["name"], game_state["year"]])

	var summary: String = _build_generation_summary()
	_log_entry("generation_advance",
		{"generation": game_state["generation"], "year": game_state["year"]},
		summary)

	state_changed.emit(game_state.duplicate(true))
	generation_advanced.emit(summary)

# ---------------------------------------------------------------------------
# Undo stack
# ---------------------------------------------------------------------------
func push_undo_snapshot() -> void:
	undo_stack.append({
		"game_state": game_state.duplicate(true),
		"event_id":   current_event_id,
	})
	if undo_stack.size() > MAX_UNDO_STEPS:
		undo_stack.pop_front()


func pop_undo_snapshot() -> bool:
	if undo_stack.is_empty():
		return false
	var snapshot:    Dictionary = undo_stack.pop_back()
	game_state       = snapshot.get("game_state", game_state)
	current_event_id = snapshot.get("event_id", "")
	state_changed.emit(game_state.duplicate(true))

	if current_event_id.begins_with("gen_"):
		call_deferred("_emit_gen_event", current_event_id)
	elif current_event_id == "village_naming":
		call_deferred("_re_emit_naming_event")
	elif current_event_id != "" and EVENTS.has(current_event_id):
		var event:        Dictionary = EVENTS[current_event_id]
		var display_text: String     = "[b]── %s ──[/b]\n%s" % [
			event.get("title", current_event_id),
			_format_text(event.get("text", "")),
		]
		event_triggered.emit(current_event_id, display_text, event.get("choices", []))
	return true


func get_undo_stack_size() -> int:
	return undo_stack.size()

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func save_game() -> void:
	var data: Dictionary = {
		"game_state":       game_state,
		"chronicle_log":    chronicle_log,
		"undo_stack":       undo_stack,
		"current_event_id": current_event_id,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var content: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if not parsed is Dictionary:
		return false

	if parsed.has("game_state")    and parsed["game_state"] is Dictionary:    game_state    = parsed["game_state"]
	if parsed.has("chronicle_log") and parsed["chronicle_log"] is Array:      chronicle_log = parsed["chronicle_log"]
	if parsed.has("undo_stack")    and parsed["undo_stack"] is Array:         undo_stack    = parsed["undo_stack"]
	if parsed.has("current_event_id"):                                         current_event_id = parsed["current_event_id"]
	return true

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
func _format_text(text: String) -> String:
	var s:        Dictionary = game_state.get("settlement", {})
	var c:        Dictionary = game_state.get("chieftain", {})
	var tier_idx: int        = clamp(s.get("tier", 0), 0, POPULATION_TIERS.size() - 1)
	var t:        Dictionary = POPULATION_TIERS[tier_idx]
	return text.format({
		"year":            game_state.get("year", 1),
		"generation":      game_state.get("generation", 1),
		"settlement_type": t["name"] if not s.is_empty() else "Settlement",
		"population":      str(s.get("population", "?")),
		"size_desc":       t["desc"],
		"location_name":   LOCATION_NAMES.get(s.get("location", ""), "unknown lands"),
		"founding_text":   s.get("founding_text", ""),
		"trades":          ", ".join(PackedStringArray(s.get("trades", []))),
		"chieftain":       c.get("name", "the chieftain"),
	})


func _log_entry(event_id: String, delta: Dictionary, description: String) -> void:
	chronicle_log.append({
		"timestamp":   Time.get_unix_time_from_system(),
		"event_id":    event_id,
		"delta":       delta,
		"description": description,
		"year":        game_state.get("year", 0),
		"generation":  game_state.get("generation", 0),
	})


func _build_generation_summary() -> String:
	var s:        Dictionary = game_state.get("settlement", {})
	var c:        Dictionary = game_state.get("chieftain", {})
	var tier_idx: int        = clamp(s.get("tier", 0), 0, POPULATION_TIERS.size() - 1)
	return "Generation %d · Year %d · Chieftain %s · Alignment %+d" % [
		game_state["generation"],
		game_state["year"],
		c.get("name", "?"),
		game_state.get("alignment", 0),
	]
