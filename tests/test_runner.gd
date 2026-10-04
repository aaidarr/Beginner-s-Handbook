extends Node
## Headless test suite: godot --headless --path . res://tests/test_runner.tscn

var passed := 0
var failed := 0
var _script: Dictionary = {}
var _case_answers: Dictionary = {}
var _log: Array = []


func _ready() -> void:
	print("=== Книжка новичка: тесты ===")
	test_content()
	test_conditions()
	test_case_logic()
	test_search()
	test_progress_empty()
	await test_playthrough_q1_q2()
	test_save_roundtrip()
	await test_locations_build()
	var pending: Array = PlannedFlags.LIST + PlannedFlags.CARDS
	if not pending.is_empty():
		print("  [ЗАПЛАНИРОВАНО] контент для Q3–Q8 ещё не написан: ", ", ".join(pending))
	print("=== Итого: %d пройдено, %d провалено ===" % [passed, failed])
	GameState.delete_save()
	get_tree().quit(1 if failed > 0 else 0)


func ok(cond: bool, name: String) -> void:
	if cond:
		passed += 1
		print("  [OK]   ", name)
	else:
		failed += 1
		print("  [FAIL] ", name)


func test_content() -> void:
	print("-- Контент")
	var errs := ContentValidator.run()
	for e in errs:
		print("     ", e)
	ok(errs.is_empty(), "валидатор контента: %d ошибок" % errs.size())
	ok(Content.quests.size() == 8, "8 задач дня")
	ok(Content.faq.size() >= 9, "FAQ: все 9 вопросов-примеров ТЗ + свои (%d)" % Content.faq.size())
	ok(Content.cases.size() >= 6, "кейсов: %d" % Content.cases.size())
	var team := Content.npcs.values().filter(func(n): return n.get("in_team", true))
	ok(team.size() >= 6, "контактов в «Команде»: %d (ТЗ 5.4: 6 ролей)" % team.size())
	var rules := Content.cards_in("rules").size()
	var procs := Content.cards_in("processes").size()
	ok(rules >= 10 and procs >= 9, "правил %d (≥10), процессов %d (≥9)" % [rules, procs])


func test_conditions() -> void:
	print("-- Условия")
	GameState.reset()
	ok(GameState.check([]), "пустое условие истинно")
	ok(not GameState.check(["x"]) and GameState.check(["!x"]), "флаг/отрицание")
	GameState.set_flag("x")
	ok(GameState.check(["x"]) and not GameState.check(["!x"]), "флаг установлен")
	GameState.reset()


func test_case_logic() -> void:
	print("-- Логика кейсов")
	var c: Dictionary = Content.cases["case_sed"]
	ok(CaseLogic.check(c, range(c["steps"].size()))["correct"], "сортировка: верный порядок")
	ok(not CaseLogic.check(c, [1, 0, 2, 3, 4])["correct"], "сортировка: неверный порядок")
	var m: Dictionary = Content.cases["case_limits"]
	var ans := {}
	for i in m["items"].size():
		ans[i] = m["items"][i]["answer"]
	ok(CaseLogic.check(m, ans)["correct"], "сопоставление: всё верно")
	ans[0] = "can"
	var r := CaseLogic.check(m, ans)
	ok(not r["correct"] and r["wrong"] == [0], "сопоставление: ошибка найдена")
	var sh := CaseLogic.shuffled_indices(5, 42)
	ok(sh.size() == 5 and sh != range(5), "перемешивание не совпадает с ответом")


func test_search() -> void:
	print("-- Поиск (Сценарий 2 ТЗ)")
	var cases := {
		"Как оформить отпуск?": ["proc_vacation", "faq_vacation"],
		"К кому обратиться по поводу доступа к системе": ["faq_access", "proc_login"],
		"не работает компьютер": ["faq_pc", "proc_support"],
		"заболел": ["faq_sick", "proc_sick"],
		"шаблоны документов": ["faq_templates", "proc_search_docs"],
		"журналист": ["faq_press", "rule_service_info"],
	}
	for q in cases:
		var res := Search.run(q)
		var top: Array = res.slice(0, 2).map(func(x): return x["id"])
		var hit: bool = top.any(func(id): return id in cases[q])
		ok(hit, "«%s» → %s" % [q, top])
	var vac: Array = Search.run("Как оформить отпуск?").slice(0, 3).map(func(x): return x["id"])
	ok("proc_vacation" in vac, "карточка процесса «Оформление отпуска» в первой тройке: %s" % [vac])


func test_progress_empty() -> void:
	print("-- Прогресс")
	GameState.reset()
	ok(is_zero_approx(Progress.overall()), "новая игра: 0%")
	ok(Progress.status() == "Новичок", "статус «Новичок»")


func _on_line(data: Dictionary) -> void:
	_log.append("%s: %s" % [data["name"], data["text"]])
	if data["choices"].is_empty():
		Dialogue.advance.call_deferred(-1)
		return
	var queue: Array = _script.get(Dialogue.current_id, [])
	var want: String = queue.pop_front() if not queue.is_empty() else ""
	var idx := 0
	for i in data["choices"].size():
		if want != "" and want in data["choices"][i]:
			idx = i
	_log.append("  > " + data["choices"][idx])
	Dialogue.advance.call_deferred(idx)


func _on_case(case_id: String) -> void:
	var c: Dictionary = Content.cases[case_id]
	var attempts := 0
	for i in _case_answers.get(case_id, []):
		attempts += 1
		var r := CaseLogic.check(c, i)
		_log.append("  [кейс %s] вариант %s → %s" % [case_id, i, r["correct"]])
		if r["correct"]:
			break
	GameState.record_case(case_id, attempts)
	Dialogue.resume.call_deferred()


func _on_book(_s: String, _c: String) -> void:
	Dialogue.resume.call_deferred()


func _talk(npc_or_rules: Variant) -> String:
	var rules: Array = Content.npc(npc_or_rules).get("dialogues", []) if npc_or_rules is String else npc_or_rules
	return Content.pick_dialogue(rules)


func _obj_rules(loc: String, obj: String) -> Array:
	for o in Content.locations[loc]["objects"]:
		if o["id"] == obj:
			return o.get("dialogues", [])
	return []


func test_playthrough_q1_q2() -> void:
	print("-- Прохождение Q1–Q2 (Сценарий 1 ТЗ)")
	GameState.reset()
	Dialogue.line.connect(_on_line)
	Dialogue.case_requested.connect(_on_case)
	Dialogue.book_requested.connect(_on_book)
	# wrong first (retry), then the right answer
	_script = {
		"interns_intro": ["Возьму", "Давай", "Нет. Пропуск"],
		"semyon_pass": ["Попрошу", "Сразу сообщу"],
		"olga_meet": ["Позвоню", "Открою книжку"],
		"burger": ["Приятного"],
	}
	_case_answers = {"case_paper": [0, 3]}
	ok(Quests.current().get("id") == "q1_pass", "старт: текущая задача Q1")
	ok(_talk("semyon") == "semyon_pass", "комендант предлагает пропуск")
	await Dialogue.start(_talk("gosha"))
	ok(GameState.has_flag("talked_interns") and GameState.studied.has("rule_pass"), "стажёры: пропуск не передаём, карточка изучена")
	ok(GameState.dialogue_mistakes == 1, "ошибка в диалоге учтена, но не блокирует")
	ok(_talk("pasha") == "interns_wait", "повторный разговор со стажёрами меняется")
	await Dialogue.start(Content.pick_dialogue(_obj_rules("l1_hall", "paper")))
	ok(GameState.cases.has("case_paper") and not GameState.cases["case_paper"]["first_try"], "свёрток: кейс решён со 2-й попытки")
	ok(GameState.has_flag("paper_returned"), "свёрток передан коменданту")
	await Dialogue.start(Content.pick_dialogue(_obj_rules("l1_hall", "burger")))
	ok(GameState.studied.has("rule_meals"), "бургер: карточка «Питание и перерывы»")
	await Dialogue.start(_talk("semyon"))
	ok(GameState.has_flag("has_pass"), "пропуск получен")
	ok(Quests.current().get("id") == "q1_pass", "Q1 ещё не завершена без стенда")
	await Dialogue.start(Content.pick_dialogue(_obj_rules("l1_hall", "stand_structure")))
	ok(GameState.quests_done.has("q1_pass"), "Q1 завершена")
	ok(Quests.current().get("id") == "q2_mentor", "текущая задача → Q2")
	GameState.apply_effects(Content.locations["l3_office"]["on_enter"])
	ok(_talk("olga") == "olga_meet", "наставник: первая встреча")
	await Dialogue.start(_talk("olga"))
	ok(GameState.has_flag("has_book"), "книжка получена")
	ok(GameState.quests_done.has("q2_mentor"), "Q2 завершена")
	ok(Quests.current().get("id") == "q3_hr", "текущая задача → Q3")
	ok(_talk("olga") == "olga_idle", "наставник: повторная реплика")
	var p := Progress.overall()
	ok(p > 0.1 and p < 0.5, "прогресс после Q1–Q2: %d%%" % roundi(p * 100))
	Dialogue.line.disconnect(_on_line)
	Dialogue.case_requested.disconnect(_on_case)
	Dialogue.book_requested.disconnect(_on_book)


func test_save_roundtrip() -> void:
	print("-- Сохранение")
	GameState.player_name = "Тест"
	GameState.save()
	var snapshot = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.reset()
	ok(not GameState.has_flag("has_book"), "сброс состояния")
	ok(GameState.load_game(), "загрузка сохранения")
	ok(GameState.player_name == "Тест" and GameState.has_flag("has_book") and GameState.quests_done.has("q2_mentor"), "состояние восстановлено")
	var after := JSON.stringify(JSON.parse_string(JSON.stringify(GameState.to_dict())))
	if after != JSON.stringify(snapshot):
		print("     было:  ", JSON.stringify(snapshot))
		print("     стало: ", after)
	ok(after == JSON.stringify(snapshot), "сохранение ↔ загрузка без потерь")


func test_locations_build() -> void:
	print("-- Локации")
	for id in Content.locations:
		var loc := Location.new()
		add_child(loc)
		loc.build(Content.locations[id])
		var b := loc.bounds()
		ok(b.size.x > 0 and loc.entities.get_child_count() > 0, "%s: построена, объектов %d" % [id, loc.entities.get_child_count()])
		loc.queue_free()
	await get_tree().process_frame
