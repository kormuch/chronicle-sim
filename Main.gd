extends Control
## Main — UI Controller
## Builds the entire UI in code. No game logic — only presentation.
## Single-column phone layout (Galaxy S22 portrait: 412×915).
## One screen: status bar, story text, choice buttons, toolbar.
## Info overlay (☰) for character sheet, village summary, chronicle.

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
var _story_label:        RichTextLabel   # THE main text area — story + last choice
var _decision_container: VBoxContainer
var _undo_button:        Button
var _status_label:       RichTextLabel   # compact top bar
var _info_button:        Button          # ☰ toggle

# Info overlay
var _overlay:            PanelContainer
var _overlay_label:      RichTextLabel
var _overlay_visible:    bool = false

# Tracks last choice text for the summary line
var _last_choice_text: String = ""

# Legacy references — kept so _on_state_changed doesn't crash
var _chieftain_label: Label
var _gen_year_label:  Label
var _alignment_label: Label
var _alignment_bar:   Label
var _mood_label:      Label
var _kronrat_label:   RichTextLabel
var _chronicle_label: RichTextLabel
var _history_label:   RichTextLabel

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_build_ui()
	_connect_signals()

# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dummy nodes for legacy compat (never displayed)
	_chieftain_label = Label.new()
	_gen_year_label  = Label.new()
	_alignment_label = Label.new()
	_alignment_bar   = Label.new()
	_mood_label      = Label.new()
	_kronrat_label   = RichTextLabel.new()
	_chronicle_label = RichTextLabel.new()
	_history_label   = RichTextLabel.new()

	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		root_margin.add_theme_constant_override(side, 6)
	bg.add_child(root_margin)

	var root_col := VBoxContainer.new()
	root_col.add_theme_constant_override("separation", 4)
	root_margin.add_child(root_col)

	# ── Status bar (1 line, compact) ──────────────────────────────────────────
	var status_panel := PanelContainer.new()
	root_col.add_child(status_panel)
	var status_mg := MarginContainer.new()
	for side_name in ["margin_left","margin_right","margin_top","margin_bottom"]:
		status_mg.add_theme_constant_override(side_name, 4)
	status_panel.add_child(status_mg)
	_status_label                       = RichTextLabel.new()
	_status_label.bbcode_enabled        = true
	_status_label.fit_content           = true
	_status_label.scroll_active         = false
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_mg.add_child(_status_label)

	# ── Story text (takes all available space) ────────────────────────────────
	var story_panel := PanelContainer.new()
	story_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_col.add_child(story_panel)
	var story_mg := MarginContainer.new()
	for side_name in ["margin_left","margin_right","margin_top","margin_bottom"]:
		story_mg.add_theme_constant_override(side_name, 8)
	story_panel.add_child(story_mg)
	_story_label                     = RichTextLabel.new()
	_story_label.bbcode_enabled      = true
	_story_label.scroll_following    = false
	_story_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_mg.add_child(_story_label)

	# ── Info overlay (hidden, covers story area, solid background) ────────────
	_overlay = PanelContainer.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	var overlay_bg := StyleBoxFlat.new()
	overlay_bg.bg_color = Color(0.12, 0.12, 0.14, 1.0)
	overlay_bg.set_content_margin_all(8)
	_overlay.add_theme_stylebox_override("panel", overlay_bg)
	story_panel.add_child(_overlay)
	var overlay_mg := MarginContainer.new()
	for side_name in ["margin_left","margin_right","margin_top","margin_bottom"]:
		overlay_mg.add_theme_constant_override(side_name, 8)
	_overlay.add_child(overlay_mg)
	var overlay_col := VBoxContainer.new()
	overlay_col.add_theme_constant_override("separation", 6)
	overlay_mg.add_child(overlay_col)
	var menu_row := HBoxContainer.new()
	menu_row.add_theme_constant_override("separation", 4)
	overlay_col.add_child(menu_row)
	var save_btn := _btn("Save", _on_save_pressed)
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_row.add_child(save_btn)
	var load_btn := _btn("Load", _on_load_pressed)
	load_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_row.add_child(load_btn)
	var new_btn := _btn("New", _on_new_game_pressed)
	new_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_row.add_child(new_btn)
	_overlay_label                     = RichTextLabel.new()
	_overlay_label.bbcode_enabled      = true
	_overlay_label.scroll_following    = false
	_overlay_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_col.add_child(_overlay_label)

	# ── Decision buttons ──────────────────────────────────────────────────────
	_decision_container = VBoxContainer.new()
	_decision_container.add_theme_constant_override("separation", 4)
	root_col.add_child(_decision_container)

	# ── Toolbar ───────────────────────────────────────────────────────────────
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 4)
	root_col.add_child(toolbar)

	_undo_button          = _btn("↩",    _on_undo_pressed)
	_undo_button.disabled = true
	toolbar.add_child(_undo_button)
	_info_button = _btn("☰",        _on_info_pressed)
	toolbar.add_child(_info_button)
	for tb_child in toolbar.get_children():
		tb_child.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _btn(label: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.pressed.connect(callback)
	return b

# ---------------------------------------------------------------------------
# Signal wiring
# ---------------------------------------------------------------------------
func _connect_signals() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.event_triggered.connect(_on_event_triggered)
	GameManager.generation_advanced.connect(_on_generation_advanced)

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_state_changed(new_state: Dictionary) -> void:
	var c:         Dictionary = new_state.get("chieftain", {})
	var alignment: int        = new_state.get("alignment", 0)
	var s:         Dictionary = new_state.get("settlement", {})

	# Compact status — 2 lines max
	var line1: String = "Gen %d · Y%d · %s · %d souls" % [
		new_state.get("generation", 1),
		new_state.get("year", 1),
		_season_name(new_state.get("season", 1)),
		s.get("population", 0),
	]
	var strength: int = int(new_state.get("chieftain_strength", 2))
	var wits:  int = int(new_state.get("chieftain_wits", 2))
	var grit:  int = int(new_state.get("chieftain_grit", 2))
	var heart: int = int(new_state.get("chieftain_heart", 2))
	var endurance: int = int(new_state.get("chieftain_endurance", 11))
	var max_endurance: int = grit * 3 + 5
	var line2: String = "[b]%s[/b] S%d W%d G%d H%d HP%d/%d %s %+d" % [
		c.get("name", "—"), strength, wits, grit, heart, endurance, max_endurance,
		_make_alignment_bar(alignment), alignment]

	_status_label.clear()
	_status_label.append_text("%s\n%s" % [line1, line2])

	# Update overlay content if visible
	if _overlay_visible:
		_refresh_overlay(new_state)

	_undo_button.disabled = GameManager.get_undo_stack_size() == 0


func _on_event_triggered(_event_id: String, text: String, choices: Array) -> void:
	GameManager._log_debug("Main._on_event_triggered: id=%s, choices=%d" % [_event_id, choices.size()])

	# Close overlay if open
	if _overlay_visible:
		_toggle_overlay()

	if choices.is_empty():
		# Follow text / narrative — append below current text
		_story_label.append_text("\n\n" + text)
		return

	# New decision — rebuild story area: last choice summary + new text
	_story_label.clear()
	if _last_choice_text != "":
		_story_label.append_text("[color=#888888]▶ %s[/color]\n\n" % _last_choice_text)
	_story_label.append_text(text)

	# Scroll to top
	_story_label.scroll_to_line(0)

	_clear_decisions()
	for i: int in choices.size():
		var btn := Button.new()
		btn.text = choices[i].get("label", "…")
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 36)
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_decision_container.add_child(btn)


func _on_generation_advanced(summary: String) -> void:
	_story_label.append_text("\n\n[i]── Generation Shift ──\n%s[/i]" % summary)

# ---------------------------------------------------------------------------
# Button handlers
# ---------------------------------------------------------------------------
func _on_choice_pressed(index: int) -> void:
	GameManager._log_debug("Main._on_choice_pressed: index=%d, current_event_id=%s" % [index, GameManager.current_event_id])
	# Capture choice text for next screen's summary line
	if index < _decision_container.get_child_count():
		var b = _decision_container.get_child(index)
		if b is Button:
			_last_choice_text = b.text
	_clear_decisions()
	GameManager.apply_choice(GameManager.current_event_id, index)


func _on_undo_pressed() -> void:
	_last_choice_text = ""
	_clear_decisions()
	_story_label.clear()
	GameManager.pop_undo_snapshot()


func _on_save_pressed() -> void:
	GameManager.save_game()
	_story_label.append_text("\n\n[color=green]✓ Saved.[/color]")


func _on_load_pressed() -> void:
	if GameManager.load_game():
		_last_choice_text = ""
		_story_label.clear()
		_clear_decisions()
		_story_label.append_text("[color=cyan]Save loaded.[/color]")
		GameManager.resume_current_event()


func _on_new_game_pressed() -> void:
	_last_choice_text = ""
	_story_label.clear()
	_clear_decisions()
	GameManager.new_game()


func _on_info_pressed() -> void:
	_toggle_overlay()

# ---------------------------------------------------------------------------
# Info overlay
# ---------------------------------------------------------------------------
func _toggle_overlay() -> void:
	_overlay_visible = not _overlay_visible
	_overlay.visible = _overlay_visible
	if _overlay_visible:
		_refresh_overlay(GameManager.game_state)


func _refresh_overlay(state: Dictionary) -> void:
	var c:     Dictionary = state.get("chieftain", {})
	var s:     Dictionary = state.get("settlement", {})
	var alignment: int    = int(state.get("alignment", 0))

	# ── Character ──
	var strength: int = int(state.get("chieftain_strength", 2))
	var wits:  int = int(state.get("chieftain_wits", 2))
	var grit:  int = int(state.get("chieftain_grit", 2))
	var heart: int = int(state.get("chieftain_heart", 2))
	var endurance: int = int(state.get("chieftain_endurance", 11))
	var max_endurance: int = grit * 3 + 5

	var weapon_base: String = str(state.get("weapon_base", ""))
	var weapon_line: String = "—"
	if weapon_base != "":
		var legend: int = int(state.get("weapon_legend", 0))
		var wname: String = str(state.get("weapon_name", ""))
		if wname != "":
			weapon_line = "%s (%s, legend %d)" % [wname, weapon_base, legend]
		else:
			weapon_line = "%s" % weapon_base.capitalize()
		if state.get("has_shield", false):
			weapon_line += " + shield"

	var spouse_line: String = "None"
	if c.get("has_spouse", false):
		spouse_line = str(c.get("spouse", {}).get("name", "?"))
	var heir_line: String = "None"
	if c.get("has_heir", false):
		var heir: Dictionary = c.get("heir", {})
		var born: int = int(heir.get("birth_year", state.get("year", 1)))
		var age: int  = state.get("year", 1) - born
		heir_line = "%s (age %d)" % [heir.get("name", "?"), age]

	var text: String = "[b]── Chieftain ──[/b]\n"
	text += "[b]%s[/b]\n" % c.get("name", "—")
	text += "Str %d · Wits %d · Grit %d · Heart %d\n" % [strength, wits, grit, heart]
	text += "Endurance %d / %d\n" % [endurance, max_endurance]
	text += "Weapon: %s\n" % weapon_line
	text += "Spouse: %s\n" % spouse_line
	text += "Heir: %s\n" % heir_line

	# ── Village ──
	text += "\n[b]── Village ──[/b]\n"
	text += "Population: %d\n" % s.get("population", 0)
	text += "Type: %s\n" % s.get("type", "—")
	var trades: Array = s.get("trades", [])
	if not trades.is_empty():
		text += "Trades: %s\n" % ", ".join(trades)
	text += "Alignment: %s %+d — %s\n" % [
		_make_alignment_bar(alignment), alignment, _alignment_desc(alignment)]
	text += "Mood: %s\n" % _village_mood(alignment)

	# Council NPCs
	var npcs: Array = s.get("key_npcs", [])
	if not npcs.is_empty():
		text += "\n[b]Council[/b]\n"
		for npc: Dictionary in npcs:
			text += "· [b]%s[/b] — %s, age %d\n" % [
				str(npc.get("name", "?")),
				str(npc.get("role", "?")),
				int(npc.get("age", 0))]

	# ── Chronicle ──
	text += "\n[b]── Chronicle ──[/b]\n"
	text += _build_chronicle_text()

	_overlay_label.clear()
	_overlay_label.append_text(text)
	_overlay_label.scroll_to_line(0)

# ---------------------------------------------------------------------------
# Chronicle formatting
# ---------------------------------------------------------------------------
func _build_chronicle_text() -> String:
	var log: Array = GameManager.chronicle_log
	if log.is_empty():
		return "[i]The story begins...[/i]"

	var result:       String = ""
	var current_gen:  int    = -1
	var current_year: int    = -1

	for entry: Dictionary in log:
		var gen:   int    = int(entry.get("generation", 1))
		var year:  int    = int(entry.get("year", 1))
		var desc:  String = str(entry.get("description", ""))
		var eid:   String = str(entry.get("event_id", ""))
		var delta: Dictionary = entry.get("delta", {})

		if eid.begins_with("gen_") and eid != "settlement_generated":
			continue

		if gen != current_gen:
			current_gen  = gen
			current_year = -1
			if result != "":
				result += "\n"
			result += "[b]── Generation %d ──[/b]\n" % gen

		if year != current_year:
			current_year = year
			result += "\n[b]Year %d[/b]\n" % year

		var delta_str: String = ""
		if delta.has("alignment") and int(delta["alignment"]) != 0:
			delta_str += " [i](%+d alignment)[/i]" % int(delta["alignment"])
		if delta.has("population") and int(delta["population"]) != 0:
			delta_str += " [i](%+d pop)[/i]" % int(delta["population"])

		result += "— %s%s\n" % [desc, delta_str]

	return result if result != "" else "[i]No events yet.[/i]"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _village_mood(alignment: int) -> String:
	if   alignment >=  80: return "Flourishing"
	elif alignment >=  40: return "Content"
	elif alignment >=  10: return "Steady"
	elif alignment >=  -9: return "Uneasy"
	elif alignment >= -39: return "Distrustful"
	elif alignment >= -79: return "Grim"
	else:                  return "Despairing"


func _alignment_desc(v: int) -> String:
	if   v >=  80: return "Pure"
	elif v >=  40: return "Virtuous"
	elif v >=  10: return "Benevolent"
	elif v >=  -9: return "Neutral"
	elif v >= -39: return "Dubious"
	elif v >= -79: return "Corrupt"
	else:          return "Dark"


func _make_alignment_bar(v: int) -> String:
	var filled: int    = int((v + 100) / 20.0)
	var bar:    String = ""
	for i: int in 10:
		bar += "█" if i < filled else "░"
	return bar


func _season_name(season: int) -> String:
	var names := ["Spring", "Summer", "Autumn", "Winter"]
	return names[clamp(season - 1, 0, 3)]


func _clear_decisions() -> void:
	for child in _decision_container.get_children():
		child.queue_free()
