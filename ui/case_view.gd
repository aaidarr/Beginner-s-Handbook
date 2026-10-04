class_name CaseView
extends Modal
## One view for all case types: choice, sort (arrows, no drag needed), match (two columns).

signal open_card(card_id: String)

var case_data: Dictionary = {}
var attempts := 0
var from_dialogue := false
var _order: Array = []
var _match: Dictionary = {}
var _body: VBoxContainer
var _result: PanelContainer
var _footer: HBoxContainer
var _solved := false


func _ready() -> void:
	add_child(Ui.dim())
	var p := Ui.panel()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 60
	p.offset_right = -60
	p.offset_top = 24
	p.offset_bottom = -24
	add_child(p)
	var col := Ui.vbox(12)
	p.add_child(col)
	_body = Ui.vbox(12)
	col.add_child(Ui.scroll(_body))
	_footer = Ui.hbox(12)
	col.add_child(_footer)


func open(case_id: String, dialogue := false) -> void:
	case_data = Content.cases.get(case_id, {})
	from_dialogue = dialogue
	attempts = 0
	_solved = GameState.cases.has(case_id)
	_order = CaseLogic.shuffled_indices(case_data.get("steps", []).size(), case_id.hash())
	_match = {}
	open_modal()
	_render()


func _render(result := {}) -> void:
	Ui.clear(_body)
	Ui.clear(_footer)
	var head := Ui.hbox()
	head.add_child(Ui.label("СИТУАЦИЯ", "Pixel", false))
	head.add_child(Ui.spacer())
	if not case_data.get("cards", []).is_empty():
		head.add_child(Ui.label("Учебный пример", "Small", false))
	_body.add_child(head)
	_body.add_child(Ui.label(case_data.get("title", ""), "Title"))
	var sit := Ui.panel("Soft")
	sit.add_child(Ui.label(case_data.get("situation", "")))
	_body.add_child(sit)
	var wrong: Array = result.get("wrong", [])
	match case_data.get("type", "choice"):
		"choice":
			_body.add_child(Ui.label("Что вы сделаете?", "Strong"))
			for i in case_data["options"].size():
				var txt := "%s.  %s" % [char(65 + i), case_data["options"][i]["text"]]
				if result.get("picked", -1) == i:
					txt = "▶ " + txt + "   — ваш ответ"
				var b := Ui.wrap_button(txt, _answer_choice.bind(i))
				b.disabled = not result.is_empty()
				_body.add_child(b)
		"sort":
			_body.add_child(Ui.label("Расставьте шаги кнопками ↑ и ↓, затем нажмите «Проверить».", "Small"))
			for pos in _order.size():
				var step: int = _order[pos]
				var row := Ui.panel("Bad" if pos in wrong else "Card")
				var h := Ui.hbox()
				row.add_child(h)
				h.add_child(Ui.label("%d." % (pos + 1), "Header", false))
				var l := Ui.label(case_data["steps"][step])
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				h.add_child(l)
				var up := Ui.button("↑", _move.bind(pos, -1))
				up.disabled = pos == 0 or _solved_now(result)
				var down := Ui.button("↓", _move.bind(pos, 1))
				down.disabled = pos == _order.size() - 1 or _solved_now(result)
				h.add_child(up)
				h.add_child(down)
				_body.add_child(row)
		"match":
			for i in case_data["items"].size():
				var it: Dictionary = case_data["items"][i]
				var row := Ui.panel("Bad" if i in wrong else "Card")
				var v := Ui.vbox(6)
				row.add_child(v)
				var h := Ui.hbox()
				v.add_child(h)
				var l := Ui.label(it["text"])
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				h.add_child(l)
				for col in case_data["columns"]:
					var b := Ui.button(col["title"], _pick_match.bind(i, col["id"]))
					b.custom_minimum_size.x = 140
					b.toggle_mode = true
					b.button_pressed = _match.get(i, "") == col["id"]
					if b.button_pressed:
						b.theme_type_variation = "Accent"
					b.disabled = _solved_now(result)
					h.add_child(b)
				if i in wrong or (_solved_now(result)):
					v.add_child(Ui.label(("✗ " if i in wrong else "✓ ") + it.get("why", ""), "Small"))
				_body.add_child(row)
	if not result.is_empty():
		_result = Ui.panel("Good" if result["correct"] else "Bad")
		var rv := Ui.vbox(6)
		_result.add_child(rv)
		var verdict := Ui.label("✓ Верно!" if result["correct"] else "✗ Не совсем так", "Header", false)
		verdict.add_theme_color_override("font_color", Ui.c("good") if result["correct"] else Ui.c("bad"))
		rv.add_child(verdict)
		rv.add_child(Ui.label(result.get("feedback", "")))
		_body.add_child(_result)
		_scroll_to_end.call_deferred()
	# footer
	if result.is_empty():
		if case_data.get("type") != "choice":
			var check := Ui.button("Проверить", _check_compound, "Accent")
			check.custom_minimum_size.x = 220
			check.disabled = case_data.get("type") == "match" and _match.size() < case_data["items"].size()
			_footer.add_child(check)
	elif result["correct"]:
		for card_id in case_data.get("cards", []).slice(0, 1):
			_footer.add_child(Ui.button("Открыть в книжке", func(): open_card.emit(card_id)))
		_footer.add_child(Ui.spacer())
		var next := Ui.button("Дальше", _finish, "Accent")
		next.custom_minimum_size.x = 220
		_footer.add_child(next)
		next.grab_focus.call_deferred()
	else:
		_footer.add_child(Ui.spacer())
		var retry := Ui.button("Попробовать ещё раз", func(): _render(), "Accent")
		_footer.add_child(retry)
		retry.grab_focus.call_deferred()


func _solved_now(result: Dictionary) -> bool:
	return not result.is_empty() and result["correct"]


func _scroll_to_end() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var s := _body.get_parent() as ScrollContainer
	if s and is_instance_valid(_result):
		s.ensure_control_visible(_result)


func _answer_choice(i: int) -> void:
	var r := CaseLogic.check(case_data, i)
	r["picked"] = i
	_register(r)


func _move(pos: int, d: int) -> void:
	var t = _order[pos]
	_order[pos] = _order[pos + d]
	_order[pos + d] = t
	_render()


func _pick_match(i: int, col: String) -> void:
	_match[i] = col
	_render()


func _check_compound() -> void:
	var answer: Variant = _order if case_data["type"] == "sort" else _match
	_register(CaseLogic.check(case_data, answer))


func _register(r: Dictionary) -> void:
	attempts += 1
	if r["correct"] and not _solved:
		_solved = true
		GameState.record_case(case_data["id"], attempts)
		GameState.save_soon()
	_render(r)


func _finish() -> void:
	close_modal()
	if from_dialogue:
		from_dialogue = false
		Dialogue.resume()
