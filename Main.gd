extends Control
## Main — UI Controller
## Builds the entire UI in code. No game logic — only presentation.

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
var _history_label:      RichTextLabel   # past events — dimmed
var _current_label:      RichTextLabel   # active event text — prominent
var _current_panel:      PanelContainer  # frame around active event, animated
var _decision_container: VBoxContainer
var _undo_button:        Button

# Right panel — chronicle
var _chronicle_label: RichTextLabel

# Right panel — status
var _chieftain_label:  Label
var _gen_year_label:   Label
var _alignment_label:  Label
var _alignment_bar:    Label
var _mood_label:       Label
var _kronrat_label:    RichTextLabel

## Tracks the raw BBCode in _current_label so we can archive it to history
var _current_bbcode: String = ""

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

	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		root_margin.add_theme_constant_override(side, 10)
	bg.add_child(root_margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	root_margin.add_child(hbox)

	# ── Left column ───────────────────────────────────────────────────────────
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 6)
	hbox.add_child(left_col)

	var title_label := Label.new()
	title_label.text = "Chronicle Sim"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_col.add_child(title_label)

	# History panel — past events, dimmed, scrollable
	var history_panel := PanelContainer.new()
	history_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_child(history_panel)
	var history_mg := MarginContainer.new()
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
		history_mg.add_theme_constant_override(side, 8)
	history_panel.add_child(history_mg)
	_history_label                    = RichTextLabel.new()
	_history_label.bbcode_enabled     = true
	_history_label.scroll_following   = true
	_history_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_mg.add_child(_history_label)

	# Current event panel — active event, framed, animated
	_current_panel = PanelContainer.new()
	_current_panel.custom_minimum_size = Vector2(0, 140)
	left_col.add_child(_current_panel)
	var current_mg := MarginContainer.new()
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
		current_mg.add_theme_constant_override(side, 12)
	_current_panel.add_child(current_mg)
	_current_label                   = RichTextLabel.new()
	_current_label.bbcode_enabled    = true
	_current_label.scroll_following  = false
	_current_label.fit_content       = true
	current_mg.add_child(_current_label)

	# Decisions
	_decision_container = VBoxContainer.new()
	_decision_container.add_theme_constant_override("separation", 4)
	left_col.add_child(_decision_container)

	# Bottom spacer so buttons don't sit flush at edge
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	left_col.add_child(spacer)

	# Toolbar
	var toolbar := HBoxContainer.new()
	toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbar.add_theme_constant_override("separation", 6)
	left_col.add_child(toolbar)

	_undo_button          = _btn("↩ Undo",        _on_undo_pressed)
	_undo_button.disabled = true
	toolbar.add_child(_undo_button)
	toolbar.add_child(_btn("Save",            _on_save_pressed))
	toolbar.add_child(_btn("Load",            _on_load_pressed))
	toolbar.add_child(_btn("New Game",        _on_new_game_pressed))
	toolbar.add_child(_btn("Next Generation", _on_next_gen_pressed))

	# ── Right column ──────────────────────────────────────────────────────────
	var right_col := VBoxContainer.new()
	right_col.custom_minimum_size = Vector2(290, 0)
	right_col.add_theme_constant_override("separation", 6)
	hbox.add_child(right_col)

	# Chronicle panel
	var chron_panel := PanelContainer.new()
	chron_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(chron_panel)
	var chron_mg := MarginContainer.new()
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
		chron_mg.add_theme_constant_override(side, 8)
	chron_panel.add_child(chron_mg)
	var chron_vbox := VBoxContainer.new()
	chron_vbox.add_theme_constant_override("separation", 4)
	chron_mg.add_child(chron_vbox)

	var chron_title := Label.new()
	chron_title.text = "Village Chronicle"
	chron_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chron_vbox.add_child(chron_title)
	chron_vbox.add_child(HSeparator.new())

	_chronicle_label                    = RichTextLabel.new()
	_chronicle_label.bbcode_enabled     = true
	_chronicle_label.scroll_following   = false
	_chronicle_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chronicle_label.text               = "[i]The story begins...[/i]"
	chron_vbox.add_child(_chronicle_label)

	# Status panel
	var status_panel := PanelContainer.new()
	status_panel.custom_minimum_size = Vector2(0, 280)
	right_col.add_child(status_panel)
	var status_mg := MarginContainer.new()
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
		status_mg.add_theme_constant_override(side, 8)
	status_panel.add_child(status_mg)
	var status_vbox := VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 4)
	status_mg.add_child(status_vbox)

	_chieftain_label                 = Label.new()
	_chieftain_label.text            = "Chieftain: —"
	_chieftain_label.autowrap_mode   = TextServer.AUTOWRAP_WORD_SMART
	status_vbox.add_child(_chieftain_label)

	_gen_year_label      = Label.new()
	_gen_year_label.text = "Generation 1 · Year 1"
	status_vbox.add_child(_gen_year_label)

	status_vbox.add_child(HSeparator.new())

	var align_title := Label.new()
	align_title.text = "Alignment"
	status_vbox.add_child(align_title)

	_alignment_label      = Label.new()
	_alignment_label.text = "0 — Neutral"
	status_vbox.add_child(_alignment_label)

	_alignment_bar      = Label.new()
	_alignment_bar.text = _make_alignment_bar(0)
	status_vbox.add_child(_alignment_bar)

	status_vbox.add_child(HSeparator.new())

	var mood_title := Label.new()
	mood_title.text = "Village Mood"
	status_vbox.add_child(mood_title)

	_mood_label                 = Label.new()
	_mood_label.text            = "—"
	_mood_label.autowrap_mode   = TextServer.AUTOWRAP_WORD_SMART
	status_vbox.add_child(_mood_label)

	status_vbox.add_child(HSeparator.new())

	var kronrat_title := Label.new()
	kronrat_title.text = "Council"
	status_vbox.add_child(kronrat_title)

	_kronrat_label                    = RichTextLabel.new()
	_kronrat_label.bbcode_enabled     = true
	_kronrat_label.scroll_following   = false
	_kronrat_label.custom_minimum_size = Vector2(0, 120)
	_kronrat_label.text               = "—"
	status_vbox.add_child(_kronrat_label)


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

	var s: Dictionary = new_state.get("settlement", {})
	var spouse_line: String = ("☑ " + c.get("spouse", {}).get("name", "?")) if c.get("has_spouse", false) else "☐ Unmarried"
	var heir:        Dictionary = c.get("heir", {})
	var heir_line:   String
	if c.get("has_heir", false):
		var born: int  = int(heir.get("birth_year", new_state.get("year", 1)))
		var age:  int  = new_state.get("year", 1) - born
		heir_line = "☑ Heir: %s · age %d" % [heir.get("name", "?"), age]
	else:
		heir_line = "☐ No heir"
	_chieftain_label.text  = "Chieftain: %s\n%s\n%s" % [c.get("name", "—"), spouse_line, heir_line]
	_gen_year_label.text   = "Generation %d · Year %d · %s · %d souls" % [
		new_state.get("generation", 1),
		new_state.get("year", 1),
		_season_name(new_state.get("season", 1)),
		s.get("population", 0),
	]
	_alignment_label.text  = "%+d — %s" % [alignment, _alignment_desc(alignment)]
	_alignment_bar.text    = _make_alignment_bar(alignment)
	_mood_label.text       = _village_mood(alignment)
	_kronrat_label.text    = _build_kronrat_text(new_state)
	_chronicle_label.text  = _build_chronicle_text()
	_undo_button.disabled  = GameManager.get_undo_stack_size() == 0


func _on_event_triggered(_event_id: String, text: String, choices: Array) -> void:
	_refresh_chronicle()

	if choices.is_empty():
		# Follow text or system message — append to current panel
		_current_label.append_text("\n\n" + text)
		_current_bbcode += "\n\n" + text
		return

	# New decision event — archive current to history, show fresh in current panel
	_archive_current_to_history()
	_current_bbcode = text
	_current_label.clear()
	_current_label.append_text(text)
	_animate_current_panel()

	_clear_decisions()
	for i: int in choices.size():
		var btn := Button.new()
		btn.text = choices[i].get("label", "…")
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_decision_container.add_child(btn)


func _on_generation_advanced(summary: String) -> void:
	var gen_text: String = "\n[i]── Generation Shift ──\n%s[/i]" % summary
	_current_label.append_text(gen_text)
	_current_bbcode += gen_text
	_refresh_chronicle()

# ---------------------------------------------------------------------------
# Button handlers
# ---------------------------------------------------------------------------
func _on_choice_pressed(index: int) -> void:
	var label_text: String = ""
	if index < _decision_container.get_child_count():
		var b = _decision_container.get_child(index)
		if b is Button:
			label_text = b.text
	_clear_decisions()
	# Show chosen option as footer in history
	if label_text != "":
		_history_label.append_text("\n[color=#888888]▶ %s[/color]\n" % label_text)
	GameManager.apply_choice(GameManager.current_event_id, index)


func _on_undo_pressed() -> void:
	_history_label.append_text("\n[color=yellow]↩ Undone.[/color]")
	_clear_decisions()
	_current_label.clear()
	_current_bbcode = ""
	GameManager.pop_undo_snapshot()


func _on_save_pressed() -> void:
	GameManager.save_game()
	_history_label.append_text("\n[color=green]✓ Game saved.[/color]")


func _on_load_pressed() -> void:
	if GameManager.load_game():
		_history_label.clear()
		_current_label.clear()
		_current_bbcode = ""
		_clear_decisions()
		_history_label.append_text("[color=cyan]Save game loaded.[/color]\n")
		GameManager.resume_current_event()


func _on_new_game_pressed() -> void:
	_history_label.clear()
	_current_label.clear()
	_current_bbcode = ""
	_clear_decisions()
	GameManager.new_game()


func _on_next_gen_pressed() -> void:
	_clear_decisions()
	GameManager.advance_generation()

# ---------------------------------------------------------------------------
# Current panel helpers
# ---------------------------------------------------------------------------
func _archive_current_to_history() -> void:
	if _current_bbcode == "":
		return
	_history_label.append_text("\n[color=#888888]" + _current_bbcode + "[/color]\n")


func _animate_current_panel() -> void:
	_current_panel.modulate = Color(1.4, 1.3, 0.7)
	var tween := create_tween()
	tween.tween_property(_current_panel, "modulate", Color.WHITE, 0.9)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

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

		# Skip internal gen_ bookkeeping (except settlement creation)
		if eid.begins_with("gen_") and eid != "settlement_generated":
			continue

		# Generation header
		if gen != current_gen:
			current_gen  = gen
			current_year = -1
			if result != "":
				result += "\n"
			result += "[b]── Generation %d ──[/b]\n" % gen

		# Year header — one per year, not repeated per entry
		if year != current_year:
			current_year = year
			result += "\n[b]Year %d[/b]\n" % year

		# Alignment delta annotation
		var delta_str: String = ""
		if delta.has("alignment") and int(delta["alignment"]) != 0:
			delta_str += " [i](%+d alignment)[/i]" % int(delta["alignment"])
		if delta.has("population") and int(delta["population"]) != 0:
			delta_str += " [i](%+d pop)[/i]" % int(delta["population"])

		result += "— %s%s\n" % [desc, delta_str]

	return result if result != "" else "[i]No events yet.[/i]"


func _refresh_chronicle() -> void:
	_chronicle_label.text = _build_chronicle_text()
	_chronicle_label.call_deferred("scroll_to_paragraph", _chronicle_label.get_paragraph_count())

# ---------------------------------------------------------------------------
# Status helpers
# ---------------------------------------------------------------------------
func _build_kronrat_text(state: Dictionary) -> String:
	var s:    Dictionary = state.get("settlement", {})
	var npcs: Array      = s.get("key_npcs", [])
	if npcs.is_empty():
		return "—"
	var text: String = ""
	for npc: Dictionary in npcs:
		var name: String = str(npc.get("name", "?"))
		var role: String = str(npc.get("role", "?"))
		var age:  int    = int(npc.get("age", 0))
		text += "[b]%s[/b] · %s · %d\n" % [name, role, age]
	return text.strip_edges()


func _village_mood(alignment: int) -> String:
	if   alignment >=  80: return "The community flourishes in unity and trust."
	elif alignment >=  40: return "Solidarity and contentment prevail in the village."
	elif alignment >=  10: return "Life goes on — mostly well."
	elif alignment >=  -9: return "Some grumble, but daily life carries on."
	elif alignment >= -39: return "Distrust and resentment are spreading."
	elif alignment >= -79: return "A dark spirit hangs over the village."
	else:                  return "Despair and hopelessness hold sway."


func _alignment_desc(v: int) -> String:
	if   v >=  80: return "Pure"
	elif v >=  40: return "Virtuous"
	elif v >=  10: return "Benevolent"
	elif v >=  -9: return "Neutral"
	elif v >= -39: return "Dubious"
	elif v >= -79: return "Corrupt"
	else:          return "Dark"


func _make_alignment_bar(v: int) -> String:
	var filled: int    = int((v + 100) / 10.0)
	var bar:    String = ""
	for i: int in 20:
		bar += "█" if i < filled else "░"
	return bar

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------
func _season_name(season: int) -> String:
	var names := ["Spring", "Summer", "Autumn", "Winter"]
	return names[clamp(season - 1, 0, 3)]


func _clear_decisions() -> void:
	for child in _decision_container.get_children():
		child.queue_free()
