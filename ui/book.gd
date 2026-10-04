class_name Book
extends Modal
## «Книжка новичка»: sections, search, cards, checklist, FAQ, contacts, results.

var from_dialogue := false
var _history: Array = []
var _view: Dictionary = {}
var _tabs: VBoxContainer
var _content: VBoxContainer
var _scroll: ScrollContainer
var _title: Label
var _back: Button
var _search: LineEdit
var _route_stage := "day"
var _faq_cat := ""
var _faq_open := ""
var _cards_filter := "all"
var _detailed := false
var _org_open := ""


func _ready() -> void:
	add_child(Ui.dim())
	var p := Ui.panel()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := Ui.safe_margins(get_viewport())
	p.offset_left = m.x
	p.offset_right = -m.z
	p.offset_top = 10
	p.offset_bottom = -10
	add_child(p)
	var col := Ui.vbox(10)
	p.add_child(col)
	var top := Ui.hbox(10)
	col.add_child(top)
	_back = Ui.button("‹ Назад", _go_back)
	top.add_child(_back)
	var book_lbl := Ui.label("КНИЖКА НОВИЧКА", "Pixel", false)
	book_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(book_lbl)
	_title = Ui.label("", "Header", false)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	top.add_child(_title)
	_search = LineEdit.new()
	_search.placeholder_text = "Поиск: «как оформить отпуск»"
	_search.custom_minimum_size = Vector2(380, Ui.MIN_TAP)
	_search.clear_button_enabled = true
	_search.text_submitted.connect(func(t): _do_search(t))
	_search.text_changed.connect(func(t):
		if t.strip_edges().length() >= 3:
			_do_search(t, false))
	top.add_child(_search)
	top.add_child(Ui.button("Закрыть", close_book, "Accent"))
	var body := Ui.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	_tabs = Ui.vbox(4)
	var tab_scroll := Ui.scroll(_tabs)
	tab_scroll.custom_minimum_size.x = 250
	tab_scroll.size_flags_horizontal = Control.SIZE_FILL
	body.add_child(tab_scroll)
	_content = Ui.vbox(12)
	_scroll = Ui.scroll(_content)
	body.add_child(_scroll)
	GameState.changed.connect(func():
		if is_open:
			_refresh_tabs())


func open(section := "home", card := "", dialogue := false) -> void:
	from_dialogue = dialogue
	_history.clear()
	_view = {}
	open_modal()
	if card != "":
		_show({"card": card})
	else:
		_show({"section": section})


func close_book() -> void:
	close_modal()
	if from_dialogue:
		from_dialogue = false
		Dialogue.resume()


func _unhandled_input(ev: InputEvent) -> void:
	if is_open and (ev.is_action_pressed("pause") or ev.is_action_pressed("book")) and not _search.has_focus():
		close_book()
		get_viewport().set_input_as_handled()


func _go_back() -> void:
	if _history.is_empty():
		close_book()
		return
	_view = {}
	_show(_history.pop_back(), false)


func _show(v: Dictionary, push := true) -> void:
	if push and not _view.is_empty() and _view != v:
		_history.append(_view)
	_view = v
	_back.text = "‹ Назад" if not _history.is_empty() else "‹ Выйти"
	_refresh_tabs()
	_render()
	_scroll.scroll_vertical = 0


func _render() -> void:
	Ui.clear(_content)
	if _view.has("card"):
		_render_card(_view["card"])
	elif _view.has("search"):
		_render_search(_view["search"])
	else:
		var sec: Dictionary = Content.sections_by_id.get(_view.get("section", "home"), {})
		_title.text = sec.get("title", "")
		match sec.get("kind", "home"):
			"home": _render_home()
			"route": _render_route()
			"org": _render_org()
			"team": _render_team()
			"cards": _render_cards(sec)
			"faq": _render_faq()
			"results": _render_results()


func _refresh_tabs() -> void:
	Ui.clear(_tabs)
	var current: String = _view.get("section", "")
	if _view.has("card"):
		current = Content.card(_view["card"]).get("section", "")
	for sec in Content.sections:
		var txt: String = sec["title"]
		var pr := Progress.cards(sec["id"])
		if pr.y > 0:
			txt += "  %d/%d" % [pr.x, pr.y]
		elif sec["id"] == "route":
			var d := Progress.stage("day")
			txt += "  %d/%d" % [d.x, d.y]
		var b := Ui.button(txt, _show.bind({"section": sec["id"]}), "Tab")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.toggle_mode = true
		b.button_pressed = sec["id"] == current
		_tabs.add_child(b)


# --- small builders ----------------------------------------------------------

func _add(n: Control) -> Control:
	_content.add_child(n)
	return n


func _section_header(text: String) -> void:
	_add(Ui.label(text, "Header"))


func _badge_row(c: Dictionary) -> HBoxContainer:
	var h := Ui.hbox(8)
	if GameState.studied.has(c["id"]):
		var l := Ui.label("✓ Изучено", "Strong", false)
		l.add_theme_color_override("font_color", Ui.c("good"))
		h.add_child(l)
	elif c.has("learn"):
		h.add_child(Ui.label("Узнаете в игре: " + c["learn"], "Small", false))
	if c.get("demo", false):
		var d := Ui.label("Учебный пример", "Small", false)
		d.add_theme_color_override("font_color", Ui.c("warn"))
		h.add_child(d)
	if GameState.favorites.has(c["id"]):
		h.add_child(Ui.label("★ В избранном", "Small", false))
	return h


func _card_row(c: Dictionary) -> void:
	var b := Ui.wrap_button("", _show.bind({"card": c["id"]}))
	b.text = ""
	var v := Ui.vbox(4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_top = 10
	v.offset_right = -14
	var t := Ui.label(c["title"], "Strong")
	var s := Ui.label(c.get("short", ""), "Small")
	var badges := _badge_row(c)
	for n in [t, s, badges]:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(n)
	b.add_child(v)
	b.custom_minimum_size.y = 112
	_add(b)


func _contact_line(npc_id: String, prefix := "Ответственный") -> Control:
	var n := Content.npc(npc_id)
	var p := Ui.panel("Soft")
	var v := Ui.vbox(4)
	p.add_child(v)
	v.add_child(Ui.label("%s: %s" % [prefix, n.get("name", "")], "Strong"))
	v.add_child(Ui.label("%s · %s" % [n.get("role", ""), n.get("dept", "")], "Small"))
	v.add_child(Ui.label("Связь: %s · %s" % [n.get("contact", ""), n.get("hours", "")], "Small"))
	return p


# --- views ---------------------------------------------------------------------

func _render_home() -> void:
	var w := Ui.panel("Card")
	var v := Ui.vbox(8)
	w.add_child(v)
	v.add_child(Ui.label(Content.org.get("name", ""), "Small"))
	v.add_child(Ui.label("Добро пожаловать, %s!" % GameState.player_name, "Title"))
	v.add_child(Ui.label(Content.org.get("welcome", "")))
	v.add_child(Ui.label(Content.org.get("purpose", ""), "Small"))
	_add(w)
	var p := Progress.overall()
	_section_header("Ваша адаптация: %s" % Progress.status(p))
	_add(Ui.progress(p))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	var rows := [
		["Задачи первого дня", Progress.quests()],
		["Ситуации разобраны", Progress.cases()],
		["Темы изучены", Progress.cards()],
	]
	for r in rows:
		grid.add_child(Ui.label(r[0], "", false))
		grid.add_child(Ui.label("%d из %d" % [r[1].x, r[1].y], "Strong", false))
	grid.add_child(Ui.label("Итоговая аттестация", "", false))
	grid.add_child(Ui.label("сдана" if Progress.test_passed() else "впереди", "Strong", false))
	_add(grid)
	var cur := Quests.current()
	if not cur.is_empty():
		var nxt := Ui.panel("Soft")
		var nv := Ui.vbox(4)
		nxt.add_child(nv)
		nv.add_child(Ui.label("Сейчас: " + cur["title"], "Strong"))
		nv.add_child(Ui.label(cur.get("hint", ""), "Small"))
		_add(nxt)
	_add(Ui.button("Как пользоваться книжкой", _show.bind({"card": "guide_book"})))
	var fav := GameState.favorites.keys()
	if not fav.is_empty():
		_section_header("Избранное")
		for id in fav:
			if Content.cards.has(id):
				_card_row(Content.card(id))
	var demo := Ui.panel("Warn")
	demo.add_child(Ui.label(Content.org.get("demo_notice", ""), "Small"))
	_add(demo)


func _render_route() -> void:
	var tabs := Ui.hbox(8)
	for st in ["day", "week", "month"]:
		var pr := Progress.stage(st)
		var b := Ui.button("%s  %d/%d" % [Content.checklist[st]["title"], pr.x, pr.y], func():
			_route_stage = st
			_render(), "Tab")
		b.toggle_mode = true
		b.button_pressed = _route_stage == st
		tabs.add_child(b)
	_add(tabs)
	# timeline
	var tl := Ui.hbox(4)
	for st in ["day", "week", "month"]:
		var seg := Ui.vbox(2)
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.add_child(Ui.label(Content.checklist[st]["title"], "Small", false))
		seg.add_child(Ui.progress(Progress.ratio(Progress.stage(st)), false))
		tl.add_child(seg)
	_add(tl)
	_add(Ui.label(Content.checklist[_route_stage].get("subtitle", ""), "Small"))
	if _route_stage == "day":
		var cur := Quests.current()
		for q in Quests.mandatory():
			var st := Quests.status(q)
			var mark := "✓ Выполнено"
			var variation := "Good"
			if st == Quests.AVAILABLE:
				mark = "▶ Сейчас" if q == cur else "○ Доступно"
				variation = "Soft" if q == cur else "Card"
			elif st == Quests.LOCKED:
				mark = "Заблокировано: сначала предыдущие задачи"
				variation = "Card"
			var p := Ui.panel(variation)
			var v := Ui.vbox(4)
			p.add_child(v)
			var h := Ui.hbox()
			h.add_child(Ui.label(q.get("time", ""), "Small", false))
			var t := Ui.label(q["title"], "Strong")
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(t)
			h.add_child(Ui.label(mark, "Small", false))
			v.add_child(h)
			if st != Quests.LOCKED:
				for o in q.get("objectives", []):
					v.add_child(Ui.label(("  ✓ " if Quests.objective_done(o) else "  ○ ") + o["text"], "Small"))
				if st == Quests.AVAILABLE:
					v.add_child(Ui.label("Подсказка: " + q.get("hint", ""), "Small"))
			_add(p)
	else:
		for it in Content.checklist[_route_stage].get("items", []):
			var p := Ui.panel("Good" if GameState.checklist_manual.has(it["id"]) else "Card")
			var h := Ui.hbox()
			p.add_child(h)
			var cb := CheckBox.new()
			cb.button_pressed = GameState.checklist_manual.has(it["id"])
			cb.custom_minimum_size = Vector2(Ui.MIN_TAP, Ui.MIN_TAP)
			cb.toggled.connect(func(_on):
				GameState.toggle_manual(it["id"])
				GameState.save_soon()
				_render())
			h.add_child(cb)
			var v := Ui.vbox(2)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(Ui.label(it["text"], "Strong"))
			v.add_child(Ui.label(it.get("hint", ""), "Small"))
			h.add_child(v)
			if it.get("card", "") != "":
				h.add_child(Ui.button("Подробнее", _show.bind({"card": it["card"]})))
			_add(p)


func _render_org() -> void:
	var o := Content.org
	_add(Ui.label(o.get("name", ""), "Title"))
	_add(Ui.label("Миссия: " + o.get("mission", "")))
	_section_header("Интерактивная схема")
	_add(Ui.label("Нажмите на подразделение, чтобы узнать, чем оно занимается.", "Small"))
	_org_node(o.get("structure", {}), 0)
	var role := Ui.panel("Soft")
	role.add_child(Ui.label("Ваша роль: " + o.get("role", "")))
	_add(role)
	var cols := Ui.hbox(16)
	for pair in [["Направления", o.get("directions", [])], ["С кем работаем", o.get("audiences", [])]]:
		var v := Ui.vbox(4)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(Ui.label(pair[0], "Header"))
		for it in pair[1]:
			v.add_child(Ui.label("• " + it))
		cols.add_child(v)
	_add(cols)
	_section_header("Карточки")
	for c in Content.cards_in("org"):
		_card_row(c)


func _org_node(n: Dictionary, depth: int) -> void:
	if n.is_empty():
		return
	var row := Ui.hbox(0)
	var pad := Control.new()
	pad.custom_minimum_size.x = depth * 36
	row.add_child(pad)
	var title: String = n["title"]
	if n.get("yours", false):
		title = "★ " + title + "  — вы здесь"
	var b := Ui.wrap_button(title, func():
		_org_open = "" if _org_open == n["id"] else n["id"]
		_render(), "Accent" if n.get("yours", false) else "")
	row.add_child(b)
	_add(row)
	if _org_open == n["id"]:
		var d := HBoxContainer.new()
		var pad2 := Control.new()
		pad2.custom_minimum_size.x = depth * 36 + 24
		d.add_child(pad2)
		var p := Ui.panel("Soft")
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_child(Ui.label(n.get("desc", "")))
		d.add_child(p)
		_add(d)
	for ch in n.get("children", []):
		_org_node(ch, depth + 1)


func _render_team() -> void:
	_add(Ui.label("К кому обращаться. Все имена и контакты вымышлены.", "Small"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for n in Content.npcs.values():
		if not n.get("in_team", true):
			continue
		var p := Ui.panel("Card")
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := Ui.vbox(4)
		p.add_child(v)
		var h := Ui.hbox()
		var por := Portrait.new()
		por.custom_minimum_size = Vector2(72, 72)
		por.show_for(n["id"], "neutral")
		h.add_child(por)
		var nv := Ui.vbox(2)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.add_child(Ui.label(n["name"], "Strong"))
		nv.add_child(Ui.label(n.get("role", ""), "Small"))
		if GameState.has_flag("met_" + n["id"]):
			var met := Ui.label("✓ Вы знакомы", "Small", false)
			met.add_theme_color_override("font_color", Ui.c("good"))
			nv.add_child(met)
		h.add_child(nv)
		v.add_child(h)
		v.add_child(Ui.label(n.get("dept", ""), "Small"))
		v.add_child(Ui.label("Отвечает за: " + n.get("responsibility", "")))
		v.add_child(Ui.label("Связь: " + n.get("contact", ""), "Small"))
		v.add_child(Ui.label("Когда: " + n.get("hours", ""), "Small"))
		grid.add_child(p)
	_add(grid)


func _render_cards(sec: Dictionary) -> void:
	_add(Ui.label(sec.get("intro", ""), "Small"))
	var f := Ui.hbox(8)
	for pair in [["all", "Все"], ["studied", "Изученные"], ["new", "Ещё не изучены"]]:
		var b := Ui.button(pair[1], func():
			_cards_filter = pair[0]
			_render(), "Tab")
		b.toggle_mode = true
		b.button_pressed = _cards_filter == pair[0]
		f.add_child(b)
	_add(f)
	var shown := 0
	for c in Content.cards_in(sec["id"]):
		var st := GameState.studied.has(c["id"])
		if (_cards_filter == "studied" and not st) or (_cards_filter == "new" and st):
			continue
		_card_row(c)
		shown += 1
	if shown == 0:
		_add(Ui.label("Здесь пока пусто.", "Small"))


func _render_card(id: String) -> void:
	var c := Content.card(id)
	var sec: Dictionary = Content.sections_by_id.get(c.get("section", ""), {})
	_title.text = sec.get("title", "")
	_add(Ui.label(c.get("title", ""), "Title"))
	_add(_badge_row(c))
	_add(Ui.label(c.get("short", ""), "Strong"))
	var tools := Ui.hbox(8)
	for pair in [[false, "Кратко"], [true, "Подробнее"]]:
		var b := Ui.button(pair[1], func():
			_detailed = pair[0]
			_render(), "Tab")
		b.toggle_mode = true
		b.button_pressed = _detailed == pair[0]
		tools.add_child(b)
	tools.add_child(Ui.spacer())
	var fav := GameState.favorites.has(id)
	tools.add_child(Ui.button("★ Убрать из избранного" if fav else "☆ В избранное", func():
		GameState.toggle_favorite(id)
		GameState.save_soon()
		_render()))
	_add(tools)
	var blocks: Array = c.get("blocks", [])
	if not _detailed:
		blocks = blocks.filter(func(b): return b.get("type") != "law").slice(0, 2)
	for b in blocks:
		_render_block(b)
	if not _detailed and c.get("blocks", []).size() > 2:
		_add(Ui.button("Показать подробнее", func():
			_detailed = true
			_render()))
	if c.has("contact"):
		_add(_contact_line(c["contact"]))
		_add(Ui.button("Задать вопрос ответственному", _ask.bind(c)))


func _ask(c: Dictionary) -> void:
	var n := Content.npc(c["contact"])
	var text := "Здравствуйте, %s! Подскажите, пожалуйста, по теме «%s»: " % [n.get("short", ""), c["title"]]
	DisplayServer.clipboard_set(text)
	GameState.toast.emit("Шаблон вопроса скопирован. Адрес: " + n.get("contact", ""))


func _render_block(b: Dictionary) -> void:
	var t: String = b.get("type", "text")
	var titles := {"can": "Можно", "cannot": "Нельзя", "accepted": "У нас принято", "not_accepted": "У нас не принято",
		"steps": "Порядок действий", "errors": "Типичные ошибки", "list": "", "map": "Карта возможностей"}
	match t:
		"text":
			_add(Ui.label(b["text"]))
		"goal":
			var p := Ui.panel("Soft")
			p.add_child(Ui.label("Цель: " + b["text"]))
			_add(p)
		"help":
			_add(Ui.label("Где получить помощь: " + b["text"], "Strong"))
		"law":
			var p := Ui.panel("Warn")
			p.add_child(Ui.label("Нормативная основа: " + b["text"], "Small"))
			_add(p)
		"timeline":
			var h := Ui.hbox(8)
			for e in Content.org.get("timeline", []):
				var p := Ui.panel("Card")
				p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var v := Ui.vbox(2)
				p.add_child(v)
				v.add_child(Ui.label(e["year"], "Header", false))
				v.add_child(Ui.label(e["text"], "Small"))
				h.add_child(p)
			_add(h)
		_:
			var variation := "Card"
			var mark := "• "
			if t in ["can", "accepted"]:
				variation = "Good"
				mark = "+ "
			elif t in ["cannot", "not_accepted", "errors"]:
				variation = "Bad"
				mark = "– "
			var p := Ui.panel(variation)
			var v := Ui.vbox(4)
			p.add_child(v)
			var head: String = b.get("title", titles.get(t, ""))
			if head != "":
				v.add_child(Ui.label(head, "Strong"))
			var items: Array = b.get("items", [])
			for i in items.size():
				var prefix := ("%d. " % (i + 1)) if t == "steps" else mark
				v.add_child(Ui.label(prefix + items[i]))
			_add(p)


func _render_faq() -> void:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 8)
	f.add_theme_constant_override("v_separation", 8)
	var cats: Array = [{"id": "", "title": "Все"}] + Content.faq_categories
	for cat in cats:
		var b := Ui.button(cat["title"], func():
			_faq_cat = cat["id"]
			_render(), "Tab")
		b.toggle_mode = true
		b.button_pressed = _faq_cat == cat["id"]
		f.add_child(b)
	_add(f)
	for item in Content.faq:
		if _faq_cat != "" and item["category"] != _faq_cat:
			continue
		_faq_item(item)


func _faq_item(item: Dictionary) -> void:
	var open: bool = _faq_open == item["id"]
	_add(Ui.wrap_button(("▾ " if open else "▸ ") + item["q"], func():
		_faq_open = "" if open else item["id"]
		_render(), "Accent" if open else ""))
	if open:
		var p := Ui.panel("Card")
		var v := Ui.vbox(8)
		p.add_child(v)
		v.add_child(Ui.label(item["a"]))
		if item.has("contact"):
			v.add_child(_contact_line(item["contact"], "Контакт"))
		var src := Content.card(item.get("card", ""))
		if not src.is_empty():
			var sec: Dictionary = Content.sections_by_id.get(src.get("section", ""), {})
			v.add_child(Ui.button("Источник: %s → %s" % [sec.get("title", ""), src["title"]], _show.bind({"card": src["id"]})))
		_add(p)


func _render_results() -> void:
	_section_header("Ситуации")
	for id in Content.cases:
		var c: Dictionary = Content.cases[id]
		var r: Dictionary = GameState.cases.get(id, {})
		var txt := "ещё впереди"
		if not r.is_empty():
			txt = "решено с первой попытки" if r.get("first_try", false) else "решено с %d-й попытки" % int(r.get("attempts", 0))
		var h := Ui.hbox()
		var t := Ui.label(c["title"])
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		h.add_child(Ui.label(txt, "Small", false))
		_add(h)
	_section_header("Итоговая аттестация")
	if GameState.quiz_results.is_empty():
		_add(Ui.label("Ещё не проходили. Она будет в конце дня у руководителя.", "Small"))
	for r in GameState.quiz_results:
		_add(Ui.label("%d из %d — %s" % [int(r["score"]), int(r["total"]), "сдано" if r["passed"] else "не сдано"]))


func _do_search(q: String, push := true) -> void:
	q = q.strip_edges()
	if q == "":
		return
	if push or not _view.has("search"):
		_show({"search": q}, push)
	else:
		_view = {"search": q}
		_render()


func _render_search(q: String) -> void:
	_title.text = "Поиск"
	var res := Search.run(q)
	_add(Ui.label("По запросу «%s» найдено: %d" % [q, res.size()], "Small"))
	if res.is_empty():
		_add(Ui.label("Ничего не нашлось. Попробуйте другими словами или загляните в «Частые вопросы».", ""))
		_add(Ui.button("Открыть «Частые вопросы»", _show.bind({"section": "faq"})))
		return
	for r in res:
		var target: Dictionary
		match r["kind"]:
			"card": target = {"card": r["id"]}
			"faq": target = {"section": "faq"}
			"contact": target = {"section": "team"}
		var b := Ui.wrap_button("", func():
			if r["kind"] == "faq":
				_faq_open = r["id"]
				_faq_cat = ""
			_show(target))
		var v := Ui.vbox(2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 14
		v.offset_top = 8
		var t := Ui.label(r["title"], "Strong")
		var pth := Ui.label(r["path"], "Small")
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pth.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(t)
		v.add_child(pth)
		b.add_child(v)
		b.custom_minimum_size.y = 84
		_add(b)
