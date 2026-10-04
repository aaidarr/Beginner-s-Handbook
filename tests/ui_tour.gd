extends Node
## Windowed end-to-end tour of the vertical slice through real input paths.
## Saves screenshots to the directory given by --shots=<dir> (user arg).
## Run: godot --path . res://tests/ui_tour.tscn -- --shots=C:/tmp/shots

var main: Node
var out_dir := "user://shots"
var n := 0
var problems: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			out_dir = a.substr(8)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameState.delete_save()
	GameState.reset()
	GameState.settings["text_speed"] = 2
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await run()
	print("TOUR PROBLEMS: ", problems.size())
	for p in problems:
		print("  - ", p)
	GameState.delete_save()
	get_tree().quit(1 if problems.size() > 0 else 0)


func check(cond: bool, what: String) -> void:
	print(("  [OK]   " if cond else "  [FAIL] ") + what)
	if not cond:
		problems.append(what)


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	n += 1
	var path := "%s/%02d_%s.png" % [out_dir, n, name]
	get_viewport().get_texture().get_image().save_png(path)
	print("  shot ", path)


func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


func hold(action: String, t: float) -> void:
	Input.action_press(action)
	await wait(t)
	Input.action_release(action)


func teleport(tile: Vector2i, facing := Vector2.UP) -> void:
	var p: Player = Router.player
	p.global_position = Router.location.tile_to_feet([tile.x, tile.y])
	p._last_dir = facing
	await wait(0.25)


func choices() -> Array:
	return main.dialogue_box._choices.get_children().filter(func(b): return b is Button and b.is_visible_in_tree())


## Drives the current dialogue: picks choices containing the given substrings in order.
func talk(picks: Array, shot_name := "", shot_on_choice := false) -> void:
	var guard := 0
	var shot_done := false
	while Dialogue.active and guard < 80:
		guard += 1
		await wait(0.12)
		if main.case_view.is_open or main.book.is_open:
			return
		if main.dialogue_box._typing:
			await press("interact")
			continue
		var cs := choices()
		if cs.is_empty():
			if shot_name != "" and not shot_done and not shot_on_choice:
				await shot(shot_name)
				shot_done = true
			await press("interact")
		else:
			if shot_name != "" and not shot_done and shot_on_choice:
				await shot(shot_name)
				shot_done = true
			var want: String = picks.pop_front() if not picks.is_empty() else ""
			var target: Button = cs[0]
			for b in cs:
				if want != "" and want in b.text:
					target = b
			target.pressed.emit()
	await wait(0.2)


func interact_with(expect_id: String) -> void:
	await wait(0.15)
	var f: Interactable = Router.player.focus
	check(f != null and f.id == expect_id, "фокус на «%s» (сейчас: %s)" % [expect_id, f.id if f else "ничего"])
	main.touch._action.pressed.emit()
	await wait(0.2)


func case_buttons() -> Array:
	var out: Array = []
	var stack: Array = [main.case_view]
	while not stack.is_empty():
		var c = stack.pop_back()
		for ch in c.get_children():
			stack.append(ch)
			if ch is Button and ch.is_visible_in_tree():
				out.append(ch)
	return out


func press_case_button(prefix: String) -> bool:
	for b in case_buttons():
		if b.text.begins_with(prefix) and not b.disabled:
			b.pressed.emit()
			await wait(0.25)
			return true
	return false


func run() -> void:
	print("=== UI-тур vertical slice ===")
	await wait(0.8)
	await shot("main_menu")
	main.new_game()
	await wait(0.4)
	await shot("character_create")
	main._start_day("Алия", 1)
	await wait(1.2)
	check(Router.location != null and Router.location.name == "l1_hall", "старт в холле")
	await shot("intro_dialogue")
	await talk([])
	await shot("hall_hud")

	# interns
	await teleport(Vector2i(6, 9))
	await shot("focus_marker")
	await interact_with("pasha")
	await talk(["Возьму", "Давай", "Нет. Пропуск"], "interns_choice", true)
	check(GameState.has_flag("talked_interns"), "стажёры: разговор завершён")

	# paper → case
	await teleport(Vector2i(9, 11))
	await interact_with("paper")
	await talk([])
	check(main.case_view.is_open, "кейс «Свёрток» открыт")
	await shot("case_paper")
	await press_case_button("A.")
	await shot("case_wrong")
	await press_case_button("Попробовать")
	await press_case_button("D.")
	await shot("case_right")
	await press_case_button("Дальше")
	await talk([])
	check(GameState.has_flag("paper_returned"), "свёрток передан")

	# semyon → pass
	await teleport(Vector2i(17, 7))
	await interact_with("semyon")
	await talk(["Попрошу", "Сразу сообщу"], "semyon_feedback")
	check(GameState.has_flag("has_pass"), "пропуск получен")

	# burger
	await teleport(Vector2i(15, 7))
	await interact_with("burger")
	await talk(["Приятного"])

	# stand → book opens from dialogue
	await teleport(Vector2i(3, 6), Vector2.LEFT)
	await interact_with("stand_structure")
	await talk([])
	check(main.book.is_open, "стенд открывает книжку на «Организации»")
	await wait(0.3)
	await shot("book_org_scheme")
	main.book.close_book()
	await talk([])
	check(GameState.quests_done.has("q1_pass"), "Q1 завершена")
	await shot("q1_done_toast")

	# walk through turnstile to the corridor with the keyboard
	await teleport(Vector2i(11, 5))
	await hold("move_up", 1.6)
	await wait(0.6)
	check(Router.location.name == "l2_corridor", "дверь: холл → коридор")
	await shot("corridor")

	# virtual joystick (emulated touch)
	var before: Vector2 = Router.player.global_position
	var zone: Control = main.touch._stick_zone
	var start := zone.global_position + zone.size * Vector2(0.4, 0.6)
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = start
	t.pressed = true
	Input.parse_input_event(t)
	await get_tree().process_frame
	var d := InputEventScreenDrag.new()
	d.index = 0
	d.position = start + Vector2(80, 0)
	d.relative = Vector2(80, 0)
	Input.parse_input_event(d)
	await wait(0.5)
	await shot("joystick")
	t = t.duplicate()
	t.pressed = false
	Input.parse_input_event(t)
	await wait(0.1)
	check(Router.player.global_position.x > before.x + 10, "джойстик двигает героя (Δx=%d)" % int(Router.player.global_position.x - before.x))

	# locked door to HR before mentor
	await teleport(Vector2i(14, 1))
	await hold("move_up", 0.5)
	await wait(0.3)
	await shot("locked_door_toast")
	check(Router.location.name == "l2_corridor", "кадры закрыты до встречи с наставником")

	# office
	await teleport(Vector2i(5, 1))
	await hold("move_up", 0.6)
	await wait(0.7)
	check(Router.location.name == "l3_office", "коридор → кабинет 214")
	await shot("office")
	await teleport(Vector2i(10, 8))
	await interact_with("olga")
	await talk(["Позвоню", "Открою книжку"], "olga_choice", true)
	check(GameState.quests_done.has("q2_mentor"), "Q2 завершена, книжка получена")
	await wait(0.4)
	await shot("office_with_book_button")

	# book tour
	main.hud.book_pressed.emit()
	await wait(0.3)
	await shot("book_home")
	main.book._show({"section": "route"})
	await wait(0.2)
	await shot("book_route_day")
	main.book._route_stage = "week"
	main.book._render()
	await wait(0.2)
	await shot("book_route_week")
	main.book._show({"section": "rules"})
	await wait(0.2)
	await shot("book_rules")
	main.book._show({"card": "rule_pass"})
	await wait(0.2)
	await shot("book_card_short")
	main.book._detailed = true
	main.book._render()
	await wait(0.2)
	await shot("book_card_detailed")
	main.book._search.text = "Как оформить отпуск?"
	main.book._search.text_submitted.emit(main.book._search.text)
	await wait(0.3)
	await shot("book_search_vacation")
	main.book._faq_open = "faq_vacation"
	main.book._show({"section": "faq"})
	await wait(0.2)
	await shot("book_faq")
	main.book._show({"section": "team"})
	await wait(0.2)
	await shot("book_team")
	main.book.close_book()
	await wait(0.2)

	# save → reload → continue
	GameState.save()
	var loc: String = GameState.location
	main.show_main_menu()
	await wait(0.5)
	await shot("menu_with_progress")
	GameState.reset()
	check(GameState.load_game() and GameState.has_flag("has_book") and GameState.location == loc, "сохранение загружено")
	main.continue_game()
	await wait(0.8)
	check(Router.location != null and Router.location.name == loc, "«Продолжить» возвращает в %s" % loc)

	# accessibility: big text + high contrast
	GameState.settings["text_scale"] = 1.4
	GameState.settings["high_contrast"] = true
	main.open_settings()
	main._on_settings_changed()
	await wait(0.3)
	await shot("settings_large_contrast")
	GameState.settings["text_scale"] = 1.0
	GameState.settings["high_contrast"] = false
	GameState.save_settings()
	Ui.build_theme()
