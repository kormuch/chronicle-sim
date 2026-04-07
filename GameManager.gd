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
	"hunting":     {"m": "Jagdführer",     "f": "Jägerin"},
	"fishing":     {"m": "Fischermeister", "f": "Fischerin"},
	"metalwork":   {"m": "Bronzegießer",   "f": "Bronzegießerin"},
	"carpentry":   {"m": "Zimmermeister",  "f": "Zimmerfrau"},
	"herbs":       {"m": "Kräuterhändler", "f": "Kräuterfrau"},
	"trade":       {"m": "Händler",        "f": "Händlerin"},
	"mining":      {"m": "Bergmann",       "f": "Bergfrau"},
	"shipbuilding":{"m": "Bootsbauer",     "f": "Bootsfrau"},
	"crafts":      {"m": "Handwerksmeister","f": "Handwerksmeisterin"},
}

const NPC_STATES: Dictionary = {
	"high":     [
		"Ich bin dankbar für das, was wir gemeinsam aufgebaut haben.",
		"Die Götter lächeln uns an — daran zweifle ich nicht.",
		"Meine Kinder werden hier ein gutes Leben haben.",
	],
	"medium":   [
		"Das Leben hier ist hart, aber gerecht.",
		"Ich vertraue dem Ältestenrat — meistens.",
		"Es hätte schlimmer kommen können.",
	],
	"neutral":  [
		"Ich lebe von einem Tag zum nächsten.",
		"Ich wünsche mir manchmal mehr vom Leben.",
		"Manchmal träume ich von der Ferne.",
	],
	"low":      [
		"Ich misstraue dem Rat. Sie denken zuerst an sich.",
		"Ich überlege, das Dorf zu verlassen.",
		"Die Starken fressen, die Schwachen darben.",
	],
	"very_low": [
		"Dieses Dorf verdient sein Unglück.",
		"Ich würde fliehen, wenn ich könnte.",
		"Die Götter haben uns verlassen.",
	],
}

# ---------------------------------------------------------------------------
# Village name generation tables
# ---------------------------------------------------------------------------
const VILLAGE_NAME_PREFIX: Dictionary = {
	"forest_edge": ["Wald", "Buchen", "Eichen", "Moos", "Birk", "Dunkel"],
	"riverbank":   ["Bach", "Spring", "Wasser", "Strom", "Quell", "Schilf"],
	"highlands":   ["Stein", "Fels", "Berg", "Hohen", "Grau", "Klippen"],
	"coast":       ["See", "Wogen", "Sturm", "Brand", "Hafen", "Klippen"],
}

const VILLAGE_NAME_SUFFIX: Dictionary = {
	"hunting":     ["forst", "hain", "mark", "grund"],
	"fishing":     ["furt", "grund", "wasser", "bach"],
	"metalwork":   ["gold", "erz", "hammer", "schmiede"],
	"carpentry":   ["dorf", "heim", "hof", "bau"],
	"herbs":       ["au", "kraut", "hain", "garten"],
	"trade":       ["markt", "krug", "tor", "platz"],
	"mining":      ["schacht", "erzberg", "grube", "stollen"],
	"shipbuilding":["hafen", "werft", "bucht", "ufer"],
	"crafts":      ["dorf", "heim", "werk", "hof"],
}

const VILLAGE_NAME_ALIGN_PREFIX: Dictionary = {
	"high": ["Licht", "Rein", "Heil", "Freund"],
	"low":  ["Schatten", "Dunkel", "Asch", "Grau"],
}

const VILLAGE_NAME_FOUNDING: Dictionary = {
	"rich_harvest":  ["Reich", "Frucht", "Ernte", "Segen"],
	"great_drought": ["Asch", "Dürr", "Hart", "Brand"],
	"raid_survived": ["Schild", "Wehr", "Trotz", "Stark"],
	"peaceful_pact": ["Freund", "Bund", "Fried", "Treue"],
	"plague":        ["Neu", "Hart", "Moder", "Streu"],
	"ore_vein":      ["Erz", "Gold", "Reich", "Funken"],
}

# ---------------------------------------------------------------------------
# Settlement generation tables
# ---------------------------------------------------------------------------
const LOCATION_NAMES: Dictionary = {
	"forest_edge": "Waldrand",
	"riverbank":   "Flussufer",
	"highlands":   "Hochland",
	"coast":       "Küste",
}

const LOCATION_TRADES: Dictionary = {
	"forest_edge": ["Jäger", "Bogner", "Korbmacher", "Kräuterfrau", "Zimmermann", "Gerber"],
	"riverbank":   ["Fischer", "Töpfer", "Händler", "Kräuterfrau", "Weber", "Zimmermann"],
	"highlands":   ["Bronzegießer", "Gerber", "Jäger", "Kräuterfrau", "Zimmermann", "Töpfer"],
	"coast":       ["Fischer", "Händler", "Seiler", "Töpfer", "Kräuterfrau", "Zimmermann"],
}

const TRADE_OPTIONS: Dictionary = {
	"forest_edge": [
		{"label": "Jagd & Waldnutzung",      "id": "hunting",    "pop_mod":  0, "align_mod":  0},
		{"label": "Kräuterkunde & Heilkunst", "id": "herbs",      "pop_mod":  0, "align_mod":  5},
		{"label": "Holzfällen & Zimmerei",    "id": "carpentry",  "pop_mod":  1, "align_mod":  0},
	],
	"riverbank": [
		{"label": "Fischerei",                "id": "fishing",    "pop_mod":  1, "align_mod":  0},
		{"label": "Töpferei & Handel",        "id": "trade",      "pop_mod":  1, "align_mod":  0},
		{"label": "Weberei & Handwerk",       "id": "crafts",     "pop_mod":  0, "align_mod":  5},
	],
	"highlands": [
		{"label": "Bronzegießerei & Waffen",  "id": "metalwork",  "pop_mod": -1, "align_mod": -5},
		{"label": "Jagd & Gerben",            "id": "hunting",    "pop_mod":  0, "align_mod":  0},
		{"label": "Erzabbau",                 "id": "mining",     "pop_mod": -1, "align_mod": -5},
	],
	"coast": [
		{"label": "Fischerei & Seefahrt",     "id": "fishing",    "pop_mod":  1, "align_mod":  0},
		{"label": "Handel & Tauschmarkt",     "id": "trade",      "pop_mod":  1, "align_mod":  5},
		{"label": "Seilerei & Bootsbau",      "id": "shipbuilding","pop_mod": 0, "align_mod":  0},
	],
}

const POPULATION_TIERS: Array = [
	{"name": "Weiler",       "desc": "Seelen",  "min": 5,   "max": 15},
	{"name": "Kleindorf",    "desc": "Seelen",  "min": 16,  "max": 40},
	{"name": "Dorf",         "desc": "Seelen",  "min": 41,  "max": 80},
	{"name": "Großdorf",     "desc": "Seelen",  "min": 81,  "max": 150},
	{"name": "Marktflecken", "desc": "Seelen",  "min": 151, "max": 300},
]

const FOUNDING_EVENTS: Array = [
	{"id": "rich_harvest",  "text": "Eine außergewöhnlich reiche Ernte in den Gründerjahren sicherte das Überleben und stärkte den Zusammenhalt.",     "align_mod":  10, "note": "Fruchtbares Land, gute Gründungszeit"},
	{"id": "great_drought", "text": "Eine schwere Dürre prüfte die ersten Siedler. Nur die Härtesten überlebten — und sie vergaßen es nie.",            "align_mod":  -5, "note": "Narben der Gründungsdürre"},
	{"id": "raid_survived", "text": "Ein Überfall eines Nachbarstammes wurde zurückgeschlagen. Die Gemeinschaft wurde stärker — aber auch misstrauischer.","align_mod": -5, "note": "Alte Feindschaft mit einem Nachbarstamm"},
	{"id": "peaceful_pact", "text": "Frühe Handelsbeziehungen mit einem Nachbarstamm brachten Wohlstand und gegenseitiges Vertrauen.",                  "align_mod":  10, "note": "Altes Bündnis mit den Nachbarn"},
	{"id": "plague",        "text": "Eine Seuche raffte viele der ersten Siedler dahin. Das Dorf überlebte — kleiner, aber zäher.",                     "align_mod":   0, "note": "Erinnerung an die Große Seuche"},
	{"id": "ore_vein",      "text": "Ein Bronzeerz-Fund in der Nähe machte die Siedlung begehrt — Fluch und Segen zugleich.",                          "align_mod":  -5, "note": "Bekannte Erzader in der Nähe"},
]

# ---------------------------------------------------------------------------
# Game events
# ---------------------------------------------------------------------------
const EVENTS: Dictionary = {
	"village_founding": {
		"title": "Das Dorf erwacht",
		"text":  ("{settlement_type} am {location_name} — {population} {size_desc}.\n"
				+ "{founding_text}\n\n"
				+ "Gewerbe: {trades}\n\n"
				+ "Der Kronrat tritt erstmals zusammen. Was ist die erste Sorge?"),
		"choices": [
			{
				"label":      "Gemeinschaftlichen Vorratsspeicher bauen — für alle (Gesinnung +5)",
				"effect":     {"alignment": 5},
				"next_event": "",
				"log_text":   "Ein Gemeinschaftsspeicher wurde als erstes Bauwerk errichtet.",
			},
			{
				"label":      "Zuerst die Dorfgrenzen sichern — wir schützen das Unsere (Gesinnung −5)",
				"effect":     {"alignment": -5},
				"next_event": "",
				"log_text":   "Die Dorfgrenzen wurden zuerst gesichert.",
			},
		],
	},
	"first_winter": {
		"title": "Der erste Winter",
		"text":  ("Der Winter kommt früher als erwartet. Die Vorräte werden knapp.\n"
				+ "Der Kronrat tritt zusammen — was beschließt Häuptling {chieftain}?"),
		"choices": [
			{
				"label":      "Alle teilen gleichmäßig — niemand wird zurückgelassen (Gesinnung +5)",
				"effect":     {"alignment": 5},
				"next_event": "",
				"log_text":   "Alle teilten gleichmäßig — die Gemeinschaft überstand den Winter.",
			},
			{
				"label":      "Die Starken fressen zuerst — die Schwachen müssen warten (Gesinnung −10)",
				"effect":     {"alignment": -10},
				"next_event": "",
				"log_text":   "Die Starken wurden bevorzugt. Manch Schwacher überlebte den Winter nicht.",
			},
		],
	},
	"trade_caravan": {
		"title": "Fremde Händler",
		"text":  ("Fremde Händler aus dem Süden rasten am Dorfrand.\n"
				+ "Sie bieten Bronzewerkzeug gegen Nahrungsvorräte an.\n"
				+ "Was entscheidet {chieftain}?"),
		"choices": [
			{
				"label":      "Fair verhandeln — ein gerechter Tausch (Gesinnung +5)",
				"effect":     {"alignment": 5},
				"next_event": "",
				"log_text":   "Ein fairer Tausch wurde vereinbart. Die Händler werden wiederkommen.",
			},
			{
				"label":      "Ausnutzen — die Fremden kennen den wahren Wert nicht (Gesinnung −10)",
				"effect":     {"alignment": -10},
				"next_event": "",
				"log_text":   "Die Unwissenheit der Fremden wurde ausgenutzt. Es sprach sich herum.",
			},
		],
	},
}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	if not load_game():
		_emit_gen_event("gen_new_game_choice")
	else:
		state_changed.emit(game_state.duplicate(true))
		event_triggered.emit("resume", "── Spielstand geladen ──\nWillkommen zurück, Chronist.", [])

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
			text = ("[b]── Schatten über dem Düsterwald ──[/b]\n\n"
				  + "Ein neues Kapitel beginnt.\n"
				  + "Wie soll das Schicksal eurer Siedlung entschieden werden?")
			choices = [
				{"label": "Schnellstart — das Schicksal würfelt für uns"},
				{"label": "Geführte Gründung — wir formen unser Schicksal selbst"},
			]
		"gen_choose_location":
			text = ("[b]── Die Wahl des Ortes ──[/b]\n\n"
				  + "Wo soll eure Siedlung entstehen?\n"
				  + "Der Ort prägt alles: Gewerbe, Überleben, Zukunft.")
			choices = [
				{"label": "Am Waldrand — Jagd, Holz, Kräuter",          "loc": "forest_edge"},
				{"label": "Am Flussufer — Fischerei, Ton, Handel",      "loc": "riverbank"},
				{"label": "Im Hochland — Erz, Bronze, Bergbau",         "loc": "highlands"},
				{"label": "An der Küste — Fischerei, Seefahrt, Handel", "loc": "coast"},
			]
		"gen_choose_trade":
			var loc:  String = _gen.get("location", "forest_edge")
			var opts: Array  = TRADE_OPTIONS.get(loc, [])
			text = "[b]── Das Hauptgewerbe ──[/b]\n\nWelchem Gewerbe wollt ihr euren Schwerpunkt setzen?"
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
			_log_entry(current_event_id, {}, "Ort gewählt: " + choice.get("label", ""))
			call_deferred("_emit_gen_event", "gen_choose_trade")
		"gen_choose_trade":
			var opt: Dictionary = choice.get("opt", {})
			_gen["primary_trade"] = opt.get("id", "hunting")
			_gen["pop_mod"]       = opt.get("pop_mod", 0)
			_gen["align_mod"]     = opt.get("align_mod", 0)
			_log_entry(current_event_id, {}, "Hauptgewerbe gewählt: " + choice.get("label", ""))
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
	if not ("Kräuterfrau" in trades or "Heiler" in trades):
		trades.append("Kräuterfrau")

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
		"Siedlung gegründet: %s am %s, %d Seelen. Häuptling: %s." % [
			POPULATION_TIERS[tier]["name"],
			LOCATION_NAMES.get(loc, loc),
			pop,
			chieftain.get("name", "?"),
		])
	_log_entry("chieftain_new", {}, "Häuptling %s übernimmt die Führung (ab Jahr 1)." % chieftain.get("name", "?"))

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
	var recommended: String = candidates[min(rec_idx, candidates.size() - 1)] if not candidates.is_empty() else "Unbekannt"

	var text: String = (
		"[b]── Ein Name wächst ──[/b]\n\n"
		+ "Die Menschen in der Umgebung haben begonnen, eure Siedlung zu benennen.\n"
		+ "Verschiedene Namen kursieren in den Geschichten der Händler und Reisenden.\n\n"
		+ "%s rät dem Kronrat:\n[i]»%s« — dieser Name spiegelt wider, wer wir sind.[/i]" % [elder_name, recommended]
	)

	var choices: Array = []
	for name: String in candidates:
		choices.append({"label": "»%s« — diesen Namen trägt unser Dorf" % name, "chosen_name": name})

	_gen_choices = choices
	event_triggered.emit("village_naming", text, choices)


func _apply_naming_choice(choice_index: int) -> void:
	if choice_index >= _gen_choices.size():
		return
	var chosen: String = _gen_choices[choice_index].get("chosen_name", "")
	game_state["settlement"]["name"] = chosen
	_log_entry("village_naming", {}, "Das Dorf erhielt den Namen: »%s«." % chosen)
	state_changed.emit(game_state.duplicate(true))
	event_triggered.emit("village_named",
		"[b]»%s«[/b]\n\nVon nun an nennen die Menschen eure Siedlung so.\nDer Name klingt in den Liedern der Händler und auf den Wegen der Reisenden.",
		[]
	)


func _build_name_candidates(loc: String, trade: String, alignment: int, founding_id: String) -> Array:
	var prefixes: Array = VILLAGE_NAME_PREFIX.get(loc, ["Alt"]).duplicate()
	var suffixes: Array = VILLAGE_NAME_SUFFIX.get(trade, ["dorf"]).duplicate()
	prefixes.shuffle()
	suffixes.shuffle()

	# 1: Descriptive — location prefix + trade suffix
	var name1: String = prefixes[0] + suffixes[0]

	# 2: Alignment-coloured
	var align_key: String = "high" if alignment >= 40 else ("low" if alignment <= -40 else "")
	var name2: String
	if align_key != "":
		var ap: Array = VILLAGE_NAME_ALIGN_PREFIX.get(align_key, ["Alt"]).duplicate()
		ap.shuffle()
		name2 = ap[0] + suffixes[min(1, suffixes.size() - 1)]
	else:
		name2 = prefixes[min(1, prefixes.size() - 1)] + suffixes[min(1, suffixes.size() - 1)]

	# 3: Founding event themed
	var fc: Array = VILLAGE_NAME_FOUNDING.get(founding_id, ["Alt"]).duplicate()
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
			return npc.get("name", "Der Ältestenrat")
	return "Der Ältestenrat"

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
		"Älteste" if elder_female else "Ältester",
		elder_female, 45 + randi() % 22, alignment, true
	))

	# 2. Healer — female by default
	npcs.append(_make_npc("Heilerin", true, 28 + randi() % 28, alignment, false))

	# 3. Trade specialist
	if TRADE_ROLES.has(primary_trade):
		var info:      Dictionary = TRADE_ROLES[primary_trade]
		var is_female: bool       = randi() % 3 == 0
		npcs.append(_make_npc(
			info["f"] if is_female else info["m"],
			is_female, 24 + randi() % 25, alignment, false
		))

	# 4–5. Two more (random roles, no repetition)
	var extra_roles: Array = ["Krieger", "Bauer", "Ratsmitglied", "Händler", "Zimmermann", "Bogner"]
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
	if not EVENTS.has(event_id):
		push_warning("GameManager: Unbekannte Event-ID '%s'" % event_id)
		return

	push_undo_snapshot()
	current_event_id = event_id

	var event:        Dictionary = EVENTS[event_id]
	var display_text: String     = "[b]── %s ──[/b]\n%s" % [
		event.get("title", event_id),
		_format_text(event.get("text", "")),
	]

	_log_entry(event_id, {}, "Ereignis: " + event.get("title", event_id))
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
		var val: int = game_state.get(stat, 0) + effect[stat]
		if stat == "alignment":
			val = clamp(val, -100, 100)
		game_state[stat] = val
		delta[stat]      = effect[stat]

	game_state["decision_count"] = game_state.get("decision_count", 0) + 1

	_log_entry(event_id, delta, choice.get("log_text", "Entscheidung getroffen."))
	state_changed.emit(game_state.duplicate(true))

	_check_naming_trigger()

	var next: String = choice.get("next_event", "")
	if next != "":
		call_deferred("trigger_event", next)

# ---------------------------------------------------------------------------
# Generation advancement
# ---------------------------------------------------------------------------
func advance_generation() -> void:
	push_undo_snapshot()

	# Record old chieftain's reign
	var old: Dictionary = game_state.get("chieftain", {})
	if not old.is_empty():
		_log_entry("chieftain_end", {},
			"Ende der Herrschaft: Häuptling %s (Jahr %d–%d)." % [
				old.get("name", "?"),
				old.get("rule_start_year", 1),
				game_state["year"],
			])

	game_state["generation"] += 1
	game_state["year"]       += 25

	# New chieftain chosen by Kronrat
	var npcs:         Array      = game_state.get("settlement", {}).get("key_npcs", [])
	var new_chief:    Dictionary = _gen_chieftain_from_kronrat(npcs, game_state["alignment"])
	new_chief["rule_start_year"] = game_state["year"]
	game_state["chieftain"]      = new_chief

	_log_entry("chieftain_new", {},
		"Neuer Häuptling: %s (ab Jahr %d)." % [new_chief["name"], game_state["year"]])

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
		"settlement_type": t["name"] if not s.is_empty() else "Siedlung",
		"population":      str(s.get("population", "?")),
		"size_desc":       t["desc"],
		"location_name":   LOCATION_NAMES.get(s.get("location", ""), "unbekanntem Ort"),
		"founding_text":   s.get("founding_text", ""),
		"trades":          ", ".join(PackedStringArray(s.get("trades", []))),
		"chieftain":       c.get("name", "der Häuptling"),
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
	return "Generation %d · Jahr %d · Häuptling %s · Gesinnung %+d" % [
		game_state["generation"],
		game_state["year"],
		c.get("name", "?"),
		game_state.get("alignment", 0),
	]
