class_name DialogueBox
extends Control
## Bottom dialogue panel: portrait, name, typed text, choice buttons.

const SPEEDS := [35.0, 70.0, 140.0, 0.0]   # chars/sec, 0 = instant

var _panel: PanelContainer
var _portrait: Portrait
var _name: Label
var _role: Label
var _verdict: Label
var _text: RichTextLabel
var _choices: VBoxContainer
var _hint: Label
var _typing := false
var _shown := 0.0
var _has_choices := false
var _auto_t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_panel = Ui.panel()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 16
	_panel.offset_right = -16
	_panel.offset_bottom = -12
	_panel.offset_top = -232
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_panel_input)
	add_child(_panel)
	var row := Ui.hbox(18)
	_panel.add_child(row)
	_portrait = Portrait.new()
	_portrait.custom_minimum_size = Vector2(180, 180)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_portrait)
	var col := Ui.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var head := Ui.hbox(12)
	_name = Ui.label("", "Header", false)
	_role = Ui.label("", "Small", false)
	_role.size_flags_vertical = Control.SIZE_SHRINK_END
	_verdict = Ui.label("", "Strong", false)
	head.add_child(_name)
	head.add_child(_role)
	head.add_child(Ui.spacer())
	head.add_child(_verdict)
	col.add_child(head)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.fit_content = false
	_text.scroll_active = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_text)
	_hint = Ui.label("Нажмите, чтобы продолжить ▸", "Small", false)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint)
	_choices = Ui.vbox(8)
	_choices.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_choices.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_choices.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choices.offset_right = -24
	_choices.offset_bottom = -244
	add_child(_choices)
	Dialogue.line.connect(_on_line)
	Dialogue.ended.connect(func(_id): _close())


func _on_line(d: Dictionary) -> void:
	visible = true
	var speaker: String = d["speaker"]
	_portrait.visible = speaker != ""
	if speaker != "":
		_portrait.show_for(speaker, d["emotion"])
	_name.text = d["name"] if speaker != "" else ""
	_role.text = d["role"]
	match d.get("verdict", ""):
		"good":
			_verdict.text = "✓ Верно"
			_verdict.add_theme_color_override("font_color", Ui.c("good"))
			_panel.theme_type_variation = "Good"
		"bad":
			_verdict.text = "✗ Не совсем"
			_verdict.add_theme_color_override("font_color", Ui.c("bad"))
			_panel.theme_type_variation = "Bad"
		_:
			_verdict.text = ""
			_panel.theme_type_variation = ""
	_text.text = d["text"]
	if speaker == "":
		_text.text = "* " + d["text"]
	_text.visible_characters = 0
	_shown = 0.0
	_typing = true
	_auto_t = 0.0
	Ui.clear(_choices)
	_has_choices = not d["choices"].is_empty()
	_choices.visible = false
	for i in d["choices"].size():
		var b := Ui.wrap_button("%d. %s" % [i + 1, d["choices"][i]], Dialogue.advance.bind(i))
		b.custom_minimum_size.x = 560
		_choices.add_child(b)
	_hint.visible = false
	if SPEEDS[int(GameState.settings.get("text_speed", 1))] == 0.0:
		_finish_typing()


func _process(delta: float) -> void:
	if not visible:
		return
	if _typing:
		_shown += delta * SPEEDS[int(GameState.settings.get("text_speed", 1))]
		_text.visible_characters = int(_shown)
		if _shown >= _text.get_total_character_count():
			_finish_typing()
	elif not _has_choices and GameState.settings.get("auto_advance", false):
		_auto_t += delta
		if _auto_t > 2.5:
			_auto_t = 0.0
			Dialogue.advance()


func _finish_typing() -> void:
	_typing = false
	_text.visible_characters = -1
	_choices.visible = _has_choices
	_hint.visible = not _has_choices
	if _has_choices and _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus.call_deferred()


func _on_panel_input(ev: InputEvent) -> void:
	var pressed: bool = (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) \
		or (ev is InputEventScreenTouch and ev.pressed)
	if pressed:
		_tap()
		accept_event()


func _tap() -> void:
	if _typing:
		_finish_typing()
	elif not _has_choices:
		Dialogue.advance()


func _unhandled_input(ev: InputEvent) -> void:
	if not visible:
		return
	if ev.is_action_pressed("interact") or ev.is_action_pressed("ui_accept"):
		if not (_has_choices and not _typing):
			_tap()
			get_viewport().set_input_as_handled()
	elif ev is InputEventKey and ev.pressed and _has_choices and not _typing:
		var n: int = ev.keycode - KEY_1
		if n >= 0 and n < _choices.get_child_count():
			Dialogue.advance(n)
			get_viewport().set_input_as_handled()


func _close() -> void:
	visible = false
	Ui.clear(_choices)
