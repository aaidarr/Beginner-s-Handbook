class_name Screens
## Main menu, character creation, settings, pause and about screens.


static func _backdrop(parent: Control) -> void:
	var bg := ColorRect.new()
	bg.color = Ui.c("bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(bg)
	var deco := Skyline.new()
	deco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(deco)


static func _center_panel(parent: Control, width := 760) -> VBoxContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(cc)
	var p := Ui.panel()
	p.custom_minimum_size.x = width
	cc.add_child(p)
	var v := Ui.vbox(12)
	p.add_child(v)
	return v


static func main_menu(main: Node) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop(root)
	# characters on the right
	var cast := Control.new()
	cast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cast)
	var looks: Array = Content.org.get("hero_looks", [{}])
	var people := [
		["gosha", Content.npc("gosha").get("look", {}), 0.62, "right"],
		["hero", looks[clampi(GameState.player_look, 0, looks.size() - 1)], 0.76, "down"],
		["pasha", Content.npc("pasha").get("look", {}), 0.90, "left"],
	]
	for p in people:
		var cv := CharacterView.new()
		cv.setup(p[0], p[1])
		cv.facing = p[3]
		cv.scale = Vector2(8, 8)
		cast.add_child(cv)
		cast.resized.connect(func(): cv.position = Vector2(cast.size.x * p[2], cast.size.y * 0.86))
	# left column
	var m := Ui.safe_margins(root.get_viewport()) if root.is_inside_tree() else Vector4(16, 16, 16, 16)
	var col := Ui.vbox(8)
	col.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	col.offset_left = maxf(64.0, m.x + 32.0)
	col.offset_right = col.offset_left + 470
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(col)
	for line in ["КНИЖКА", "НОВИЧКА"]:
		var t := Ui.label(line, "Pixel", false)
		t.add_theme_font_size_override("font_size", 40)
		t.add_theme_color_override("font_color", Color("#f3e9d2"))
		t.add_theme_color_override("font_shadow_color", Color("#2f5d8a"))
		t.add_theme_constant_override("shadow_offset_x", 4)
		t.add_theme_constant_override("shadow_offset_y", 4)
		col.add_child(t)
	col.add_child(Ui.label("Первый день · " + Content.org.get("short", ""), "Light", false))
	var has_save := GameState.has_save() and GameState.load_game()
	if has_save:
		var card := Ui.panel("Card")
		var cv := Ui.vbox(4)
		card.add_child(cv)
		var p := Progress.overall()
		cv.add_child(Ui.label("%s · %d%% · %s" % [GameState.player_name, roundi(p * 100), Progress.status(p)], "Strong", false))
		var cur := Quests.current()
		cv.add_child(Ui.label("Сейчас: " + cur.get("title", "все задачи дня выполнены"), "Small", false))
		cv.add_child(Ui.progress(p, false))
		col.add_child(card)
	var items: Array = []
	if has_save:
		items.append(["Продолжить", main.continue_game, "Accent"])
		items.append(["Новая игра", main.confirm_new_game, ""])
	else:
		items.append(["Начать первый день", main.new_game, "Accent"])
	items.append(["Книжка новичка", main.open_book_from_menu, ""])
	items.append(["Настройки", main.open_settings, ""])
	items.append(["О проекте", main.open_about, ""])
	if not OS.has_feature("web") and not OS.has_feature("ios"):
		items.append(["Выйти из игры", main.confirm_quit, ""])
	var first: Button
	for it in items:
		var b := Ui.button(it[0], it[1], it[2])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 54
		b.add_theme_font_size_override("font_size", Ui.fs(24))
		col.add_child(b)
		if first == null:
			first = b
	first.grab_focus.call_deferred()
	var ver := Ui.label("Учебный прототип · v0.2", "Light", false)
	ver.modulate.a = 0.6
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ver.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ver.offset_right = -24
	ver.offset_bottom = -16
	root.add_child(ver)
	return root


static func character_create(on_done: Callable, on_back: Callable) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop(root)
	var v := _center_panel(root, 760)
	v.add_child(Ui.label("Оформление нового сотрудника", "Title"))
	v.add_child(Ui.label("Как вас зовут? Имя появится в диалогах и в сертификате.", "Small"))
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Ваше имя"
	name_edit.max_length = 24
	name_edit.custom_minimum_size.y = Ui.MIN_TAP
	v.add_child(name_edit)
	v.add_child(Ui.label("Выберите внешность", "Strong"))
	var looks := Ui.hbox(16)
	var chosen := [0]
	var buttons: Array = []
	var hero_looks: Array = Content.org.get("hero_looks", [])
	for i in hero_looks.size():
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = i == 0
		b.custom_minimum_size = Vector2(160, 190)
		var cv := CharacterView.new()
		cv.setup("hero_%d" % i, hero_looks[i])
		cv.position = Vector2(80, 140)
		cv.scale = Vector2(5, 5)
		b.add_child(cv)
		var cap := Ui.label("Вариант %d" % (i + 1), "Small", false)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		cap.offset_top = -36
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cap)
		b.pressed.connect(func():
			chosen[0] = i
			for j in buttons.size():
				buttons[j].button_pressed = j == i)
		buttons.append(b)
		looks.add_child(b)
	v.add_child(looks)
	var row := Ui.hbox(12)
	row.add_child(Ui.button("Назад", on_back))
	var go := Ui.button("Начать первый день", func():
		var n := name_edit.text.strip_edges()
		on_done.call(n if n != "" else "Новичок", chosen[0]), "Accent")
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(go)
	v.add_child(row)
	name_edit.text_submitted.connect(func(_t): go.pressed.emit())
	name_edit.grab_focus.call_deferred()
	return root


static func settings(on_close: Callable, on_changed: Callable, on_reset: Callable) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(Ui.dim())
	var v := _center_panel(root, 760)
	v.add_child(Ui.label("Настройки", "Title"))
	var s := GameState.settings
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	var opt := func(label: String, key: String, values: Array, names: Array) -> void:
		grid.add_child(Ui.label(label, "", false))
		var o := OptionButton.new()
		o.custom_minimum_size = Vector2(320, Ui.MIN_TAP)
		for n in names:
			o.add_item(n)
		o.selected = maxi(0, values.find(s.get(key)))
		o.item_selected.connect(func(i):
			s[key] = values[i]
			on_changed.call())
		grid.add_child(o)
	var tog := func(label: String, key: String) -> void:
		grid.add_child(Ui.label(label, "", false))
		var c := CheckButton.new()
		c.button_pressed = s.get(key, false)
		c.custom_minimum_size.y = Ui.MIN_TAP
		c.toggled.connect(func(on):
			s[key] = on
			on_changed.call())
		grid.add_child(c)
	opt.call("Размер текста", "text_scale", [1.0, 1.2, 1.4], ["Обычный", "Крупный", "Очень крупный"])
	opt.call("Скорость текста", "text_speed", [0, 1, 2, 3], ["Медленно", "Обычно", "Быстро", "Сразу весь текст"])
	tog.call("Высокий контраст", "high_contrast")
	tog.call("Меньше анимации", "reduce_motion")
	tog.call("Управление для левши", "left_handed")
	tog.call("Автопродолжение диалогов", "auto_advance")
	v.add_child(Ui.label("Все звуковые сигналы дублируются текстовыми уведомлениями.", "Small"))
	var row := Ui.hbox(12)
	row.add_child(Ui.button("Сбросить прогресс", on_reset))
	row.add_child(Ui.spacer())
	row.add_child(Ui.button("Готово", on_close, "Accent"))
	v.add_child(row)
	return root


static func pause(on_resume: Callable, on_book: Callable, on_settings: Callable, on_menu: Callable, on_quit: Callable) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(Ui.dim())
	var v := _center_panel(root, 520)
	v.add_child(Ui.label("Пауза", "Title"))
	v.add_child(Ui.label("Прогресс сохраняется автоматически.", "Small"))
	var resume := Ui.button("Продолжить", on_resume, "Accent")
	v.add_child(resume)
	resume.grab_focus.call_deferred()
	v.add_child(Ui.button("Книжка новичка", on_book))
	v.add_child(Ui.button("Настройки", on_settings))
	v.add_child(Ui.button("Главное меню", on_menu))
	if not OS.has_feature("web") and not OS.has_feature("ios"):
		v.add_child(Ui.button("Выйти из игры", on_quit))
	return root


static func message(title: String, text: String, buttons: Array) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(Ui.dim())
	var v := _center_panel(root, 760)
	v.add_child(Ui.label(title, "Title"))
	v.add_child(Ui.label(text))
	var row := Ui.hbox(12)
	row.add_child(Ui.spacer())
	for b in buttons:
		row.add_child(Ui.button(b[0], b[1], b[2] if b.size() > 2 else ""))
	v.add_child(row)
	return root


static func about_text() -> String:
	return "Учебный прототип цифровой «Книжки новичка» для нового сотрудника органа власти.\n\n" \
		+ Content.org.get("demo_notice", "") + "\n\n" \
		+ "Шрифты: PT Sans, Press Start 2P (SIL Open Font License). Движок: Godot Engine (MIT).\n" \
		+ "Графика — временные плейсхолдеры, будут заменены художником команды."
