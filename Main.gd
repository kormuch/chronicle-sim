extends Control
## Main — UI Controller
## Builds the entire UI in code. No game logic — only presentation.

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------
var _story_label:        RichTextLabel
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

	# ── Left column — story + decisions + toolbar ─────────────────────────
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 6)
	hbox.add_child(left_col)

	var title_label := Label.new()
	title_label.text = "Schatten über dem Düsterwald"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_col.add_child(title_label)

	# Story panel
	var story_panel := PanelContainer.new()
	story_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_child(story_panel)
	var story_mg := MarginContainer.new()
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
		story_mg.add_theme_constant_override(side, 8)
	story_panel.add_child(story_mg)
	_story_label                    = RichTextLabel.new()
	_story_label.bbcode_enabled     = true
	_story_label.scroll_following   = true
	_story_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_mg.add_child(_story_label)

	# Decisions
	_decision_container = VBoxContainer.new()
	_decision_container.add_theme_constant_override("separation", 4)
	left_col.add_child(_decision_container)

	# Toolbar
	var toolbar := HBoxContainer.new()
	toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbar.add_theme_constant_override("separation", 6)
	left_col.add_child(toolbar)

	_undo_button          = _btn("↩ Rückgängig",       _on_undo_pressed)
	_undo_button.disabled = true
	toolbar.add_child(_undo_button)
	toolbar.add_child(_btn("Speichern",          _on_save_pressed))
	toolbar.add_child(_btn("Laden",              _on_load_pressed))
	toolbar.add_child(_btn("Nächste Generation", _on_next_gen_pressed))

	# ── Right column — chronicle (top) + status (bottom) ─────────────────
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
	chron_title.text = "Dorfchronik"
	chron_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chron_vbox.add_child(chron_title)
	chron_vbox.add_child(HSeparator.new())

	_chronicle_label                    = RichTextLabel.new()
	_chronicle_label.bbcode_enabled     = true
	_chronicle_label.scroll_following   = false
	_chronicle_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chronicle_label.text               = "[i]Die Geschichte beginnt...[/i]"
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

	_chieftain_label      = Label.new()
	_chieftain_label.text = "Häuptling: —"
	status_vbox.add_child(_chieftain_label)

	_gen_year_label      = Label.new()
	_gen_year_label.text = "Generation 1 · Jahr 1"
	status_vbox.add_child(_gen_year_label)

	status_vbox.add_child(HSeparator.new())

	var align_title := Label.new()
	align_title.text = "Gesinnung"
	status_vbox.add_child(align_title)

	_alignment_label      = Label.new()
	_alignment_label.text = "0 — Neutral"
	status_vbox.add_child(_alignment_label)

	_alignment_bar      = Label.new()
	_alignment_bar.text = _make_alignment_bar(0)
	status_vbox.add_child(_alignment_bar)

	status_vbox.add_child(HSeparator.new())

	var mood_title := Label.new()
	mood_title.text = "Stimmung im Dorf"
	status_vbox.add_child(mood_title)

	_mood_label                 = Label.new()
	_mood_label.text            = "—"
	_mood_label.autowrap_mode   = TextServer.AUTOWRAP_WORD_SMART
	status_vbox.add_child(_mood_label)

	status_vbox.add_child(HSeparator.new())

	var kronrat_title := Label.new()
	kronrat_title.text = "Kronrat"
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

	_chieftain_label.text  = "Häuptling: %s" % c.get("name", "—")
	_gen_year_label.text   = "Generation %d · Jahr %d" % [
		new_state.get("generation", 1),
		new_state.get("year", 1),
	]
	_alignment_label.text  = "%+d — %s" % [alignment, _alignment_desc(alignment)]
	_alignment_bar.text    = _make_alignment_bar(alignment)
	_mood_label.text       = _village_mood(alignment)
	_kronrat_label.text    = _build_kronrat_text(new_state)
	_chronicle_label.text  = _build_chronicle_text()
	_undo_button.disabled  = GameManager.get_undo_stack_size() == 0


func _on_event_triggered(_event_id: String, text: String, choices: Array) -> void:
	_story_label.append_text("\n\n" + text + "\n")
	_chronicle_label.text = _build_chronicle_text()

	_clear_decisions()
	for i: int in choices.size():
		var btn := Button.new()
		btn.text = choices[i].get("label", "…")
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_decision_container.add_child(btn)


func _on_generation_advanced(summary: String) -> void:
	_story_label.append_text(
		"\n\n[i]── Generationswechsel ──\n%s[/i]\n" % summary
	)
	_chronicle_label.text = _build_chronicle_text()

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
	if label_text != "":
		_story_label.append_text("\n[color=gray]▶ %s[/color]" % label_text)
	GameManager.apply_choice(GameManager.current_event_id, index)


func _on_undo_pressed() -> void:
	_story_label.append_text("\n[color=yellow]↩ Rückgängig gemacht.[/color]")
	_clear_decisions()
	GameManager.pop_undo_snapshot()


func _on_save_pressed() -> void:
	GameManager.save_game()
	_story_label.append_text("\n[color=green]Spiel gespeichert.[/color]")


func _on_load_pressed() -> void:
	if GameManager.load_game():
		_story_label.clear()
		_clear_decisions()
		_story_label.append_text("[color=cyan]Spielstand geladen.[/color]")


func _on_next_gen_pressed() -> void:
	_clear_decisions()
	GameManager.advance_generation()

# ---------------------------------------------------------------------------
# Chronicle formatting
# ---------------------------------------------------------------------------
func _build_chronicle_text() -> String:
	var log: Array = GameManager.chronicle_log
	if log.is_empty():
		return "[i]Die Geschichte beginnt...[/i]"

	var result:      String = ""
	var current_gen: int    = -1

	for entry: Dictionary in log:
		var gen:   int    = int(entry.get("generation", 1))
		var year:  int    = int(entry.get("year", 1))
		var desc:  String = str(entry.get("description", ""))
		var eid:   String = str(entry.get("event_id", ""))
		var delta: Dictionary = entry.get("delta", {})

		# Generation header
		if gen != current_gen:
			current_gen = gen
			if result != "":
				result += "\n"
			result += "[b]── Generation %d ──[/b]\n" % gen

		# Skip internal gen_ bookkeeping (except settlement creation)
		if eid.begins_with("gen_") and eid != "settlement_generated":
			continue

		# Alignment delta annotation
		var delta_str: String = ""
		if delta.has("alignment") and int(delta["alignment"]) != 0:
			delta_str = " [i](%+d Gesinnung)[/i]" % int(delta["alignment"])

		result += "Jahr %d — %s%s\n" % [year, desc, delta_str]

	return result if result != "" else "[i]Noch keine Ereignisse.[/i]"

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
		var name:   String = str(npc.get("name", "?"))
		var role:   String = str(npc.get("role", "?"))
		var age:    int    = int(npc.get("age", 0))
		var father: String = npc.get("father", {}).get("name", "?")
		var mother: String = npc.get("mother", {}).get("name", "?")
		var mood:   String = str(npc.get("state", ""))
		text += "[b]%s[/b] · %s · %dJ.\n" % [name, role, age]
		text += "[color=gray]%s & %s[/color]\n" % [father, mother]
		text += "[i]»%s«[/i]\n\n" % mood
	return text.strip_edges()


func _village_mood(alignment: int) -> String:
	if   alignment >=  80: return "Die Gemeinschaft erblüht in Einheit und Vertrauen."
	elif alignment >=  40: return "Im Dorf herrscht Zusammenhalt und Zufriedenheit."
	elif alignment >=  10: return "Das Leben geht seinen Gang — mehrheitlich gut."
	elif alignment >=  -9: return "Manche murren, doch der Alltag überwiegt."
	elif alignment >= -39: return "Misstrauen und Unmut breiten sich aus."
	elif alignment >= -79: return "Ein dunkler Geist liegt über dem Dorf."
	else:                  return "Verzweiflung und Hoffnungslosigkeit regieren."


func _alignment_desc(v: int) -> String:
	if   v >=  80: return "Rein"
	elif v >=  40: return "Tugendhaft"
	elif v >=  10: return "Wohlgesinnt"
	elif v >=  -9: return "Neutral"
	elif v >= -39: return "Zweifelhaft"
	elif v >= -79: return "Verdorben"
	else:          return "Dunkel"


func _make_alignment_bar(v: int) -> String:
	var filled: int    = int((v + 100) / 10.0)
	var bar:    String = ""
	for i: int in 20:
		bar += "█" if i < filled else "░"
	return bar

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------
func _clear_decisions() -> void:
	for child in _decision_container.get_children():
		child.queue_free()
