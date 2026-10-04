extends Node
## App shell: world + UI layers, screen flow (menu → character → game).

var world: Node2D
var root: Control
var hud: Hud
var touch: TouchControls
var dialogue_box: DialogueBox
var case_view: CaseView
var book: Book
var toasts: Toasts
var _screen: Control
var _overlay: Control


func _ready() -> void:
	Controls.setup_input_map()
	get_tree().set_quit_on_go_back(false)
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	Router.world = world
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Ui.build_theme()
	layer.add_child(root)
	touch = TouchControls.new()
	root.add_child(touch)
	hud = Hud.new()
	root.add_child(hud)
	dialogue_box = DialogueBox.new()
	root.add_child(dialogue_box)
	case_view = CaseView.new()
	root.add_child(case_view)
	book = Book.new()
	root.add_child(book)
	toasts = Toasts.new()
	root.add_child(toasts)
	hud.book_pressed.connect(func(): book.open())
	hud.menu_pressed.connect(open_pause)
	case_view.open_card.connect(func(id): book.open("", id))
	Dialogue.case_requested.connect(func(id): case_view.open(id, true))
	Dialogue.book_requested.connect(func(sec, card): book.open(sec, card, true))
	Quests.quest_completed.connect(_on_quest_completed)
	show_main_menu()


func _set_screen(s: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = s
	if s:
		root.add_child(s)
		root.move_child(s, toasts.get_index())


func _set_overlay(o: Control) -> void:
	if _overlay:
		_overlay.queue_free()
		Controls.locks -= 1
	_overlay = o
	if o:
		Controls.locks += 1
		root.add_child(o)


func show_main_menu() -> void:
	_set_overlay(null)
	Router.clear()
	_set_screen(Screens.main_menu(self))


func new_game() -> void:
	_set_screen(Screens.character_create(_start_day, show_main_menu))


func confirm_new_game() -> void:
	_set_overlay(Screens.message("Начать заново?", "Текущий прогресс адаптации будет удалён.",
		[["Отмена", func(): _set_overlay(null)], ["Начать заново", func():
			_set_overlay(null)
			new_game(), "Accent"]]))


func _start_day(player_name: String, look: int) -> void:
	GameState.reset()
	GameState.player_name = player_name
	GameState.player_look = look
	_set_screen(null)
	await Router.go("l1_hall", "start")
	Dialogue.start("intro")


func continue_game() -> void:
	_set_screen(null)
	var loc := GameState.location if Content.locations.has(GameState.location) else "l1_hall"
	Router.go(loc, GameState.spawn)


func open_book_from_menu() -> void:
	book.open()


func open_settings() -> void:
	_set_overlay(Screens.settings(func():
		GameState.save_settings()
		_set_overlay(null), _on_settings_changed, _confirm_reset))


func _on_settings_changed() -> void:
	GameState.save_settings()
	Ui.build_theme()
	touch._layout()
	hud.refresh()
	if _screen and Router.player == null:
		_set_screen(Screens.main_menu(self))
	open_settings()


func _confirm_reset() -> void:
	_set_overlay(Screens.message("Сбросить прогресс?", "Сохранение будет удалено, игра начнётся с начала.",
		[["Отмена", open_settings], ["Сбросить", func():
			GameState.delete_save()
			GameState.reset()
			show_main_menu(), "Accent"]]))


func open_about() -> void:
	_set_overlay(Screens.message("О проекте", Screens.about_text(), [["Закрыть", func(): _set_overlay(null), "Accent"]]))


func open_pause() -> void:
	if Dialogue.active:
		return
	_set_overlay(Screens.pause(func(): _set_overlay(null), func():
		_set_overlay(null)
		book.open(), open_settings, func():
		GameState.save()
		show_main_menu()))


func _on_quest_completed(q: Dictionary) -> void:
	hud.refresh()


func _unhandled_input(ev: InputEvent) -> void:
	if Router.player == null:
		return
	if ev.is_action_pressed("pause"):
		if _overlay:
			_set_overlay(null)
		elif not Controls.locked():
			open_pause()
		get_viewport().set_input_as_handled()
	elif ev.is_action_pressed("book") and not Controls.locked() and GameState.has_flag("has_book"):
		book.open()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if book.is_open:
			book.close_book()
		elif case_view.is_open:
			pass
		elif _overlay:
			_set_overlay(null)
		elif Router.player:
			open_pause()
		else:
			get_tree().quit()
