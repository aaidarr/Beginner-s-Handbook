class_name Hud
extends Control
## Current task (tap for hint), adaptation progress, book and menu buttons.

signal book_pressed
signal menu_pressed

var _quest_panel: PanelContainer
var _time: Label
var _title: Label
var _objective: Label
var _hint: Label
var _ring: ProgressRing
var _status: Label
var _book_btn: Button
var _loc: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := Ui.safe_margins(get_viewport())
	# task panel (top-left)
	_quest_panel = Ui.panel("Card")
	_quest_panel.position = Vector2(m.x, m.y)
	_quest_panel.custom_minimum_size.x = 470
	_quest_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_quest_panel.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_hint.visible = not _hint.visible
			accept_event())
	add_child(_quest_panel)
	var q := Ui.vbox(2)
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_panel.add_child(q)
	_time = Ui.label("", "Small", false)
	_title = Ui.label("", "Strong")
	_objective = Ui.label("")
	_hint = Ui.label("", "Small")
	_hint.visible = false
	for l in [_time, _title, _objective, _hint]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		q.add_child(l)
	# right cluster
	var right := Ui.hbox(12)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.offset_right = -m.z
	right.offset_top = m.y
	add_child(right)
	var prog := Ui.panel("Card")
	var pv := Ui.hbox(8)
	prog.add_child(pv)
	_ring = ProgressRing.new()
	_ring.custom_minimum_size = Vector2(56, 56)
	pv.add_child(_ring)
	var pcol := Ui.vbox(0)
	pcol.add_child(Ui.label("Адаптация", "Small", false))
	_status = Ui.label("", "Strong", false)
	pcol.add_child(_status)
	pv.add_child(pcol)
	right.add_child(prog)
	_book_btn = Ui.button("Книжка", func(): book_pressed.emit(), "Accent")
	_book_btn.custom_minimum_size = Vector2(130, 80)
	right.add_child(_book_btn)
	var menu := Ui.button("Меню", func(): menu_pressed.emit())
	menu.custom_minimum_size = Vector2(96, 80)
	right.add_child(menu)
	_loc = Ui.label("", "Light", false)
	_loc.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_loc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_loc.offset_bottom = -m.w - 6
	_loc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loc.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_loc.add_theme_constant_override("outline_size", 6)
	add_child(_loc)
	GameState.changed.connect(refresh)
	Router.location_changed.connect(func(id):
		_loc.text = Content.locations.get(id, {}).get("title", ""))
	refresh()


func _process(_d: float) -> void:
	visible = Router.player != null and not Controls.locked()


func refresh() -> void:
	var q := Quests.current()
	var total := Quests.mandatory().size()
	if q.is_empty():
		_time.text = "17:00"
		_title.text = "Все задачи дня выполнены"
		_objective.text = "Откройте книжку — там план на неделю и месяц."
		_hint.text = ""
	else:
		var idx := Quests.mandatory().find(q) + 1
		_time.text = "%s · Задача %d из %d · нажмите для подсказки" % [q.get("time", ""), idx, total]
		_title.text = q["title"]
		var o := Quests.next_objective(q)
		_objective.text = "▸ " + o.get("text", q.get("description", ""))
		_hint.text = "Подсказка: " + q.get("hint", "")
	var p := Progress.overall()
	_ring.value = p
	_status.text = "%d%% · %s" % [roundi(p * 100), Progress.status(p)]
	_book_btn.visible = GameState.has_flag("has_book")
