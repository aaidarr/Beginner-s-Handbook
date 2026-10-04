class_name ContentValidator
## Static checks for data/: broken ids, unreachable flags, dangling dialogue nodes.

const BUILT_IN_SPEAKERS := ["", "hero"]


static func run() -> Array:
	var errs: Array = []
	errs.append_array(Content.errors)
	var set_flags := _all_set_flags()
	# dialogues
	for did in Content.dialogues:
		var nodes: Dictionary = Content.dialogues[did].get("nodes", {})
		if not nodes.has(Content.dialogues[did].get("start", "start")):
			errs.append("Диалог %s: нет стартового узла" % did)
		for nid in nodes:
			var n: Dictionary = nodes[nid]
			var where := "Диалог %s/%s" % [did, nid]
			for key in ["next", "else"]:
				if n.has(key) and n[key] != "" and not nodes.has(n[key]):
					errs.append("%s: %s → несуществующий узел %s" % [where, key, n[key]])
			if n.has("text") and not n.has("next") and not n.has("choices") and not n.get("end", false):
				errs.append("%s: тупик (нет next/choices/end)" % where)
			if n.has("speaker") and n["speaker"] not in BUILT_IN_SPEAKERS and not Content.npcs.has(n["speaker"]):
				errs.append("%s: неизвестный персонаж %s" % [where, n["speaker"]])
			if n.has("case") and not Content.cases.has(n["case"]):
				errs.append("%s: неизвестный кейс %s" % [where, n["case"]])
			if n.has("book") and not Content.sections_by_id.has(n["book"]):
				errs.append("%s: неизвестный раздел книжки %s" % [where, n["book"]])
			errs.append_array(_check_effects(n.get("effects", []), where))
			errs.append_array(_check_conds(n.get("if", []), where, set_flags))
			for ch in n.get("choices", []):
				if not ch.get("retry", false) and ch.get("next", "") != "" and not nodes.has(ch["next"]):
					errs.append("%s: выбор «%s» → несуществующий узел %s" % [where, ch["text"], ch["next"]])
				if not ch.get("retry", false) and ch.get("next", "") == "":
					errs.append("%s: выбор «%s» без next" % [where, ch["text"]])
				if ch.has("feedback_speaker") and ch["feedback_speaker"] not in BUILT_IN_SPEAKERS and not Content.npcs.has(ch["feedback_speaker"]):
					errs.append("%s: неизвестный персонаж %s" % [where, ch["feedback_speaker"]])
				errs.append_array(_check_effects(ch.get("effects", []), where))
				errs.append_array(_check_conds(ch.get("if", []), where, set_flags))
			var choices: Array = n.get("choices", [])
			if not choices.is_empty() and choices.all(func(c): return c.get("retry", false)):
				errs.append("%s: все варианты ведут на повтор — выхода нет" % where)
	# npcs
	for nid in Content.npcs:
		for r in Content.npcs[nid].get("dialogues", []):
			if not Content.dialogues.has(r["id"]):
				errs.append("NPC %s: нет диалога %s" % [nid, r["id"]])
			errs.append_array(_check_conds(r.get("if", []), "NPC " + nid, set_flags))
	# locations
	for lid in Content.locations:
		var loc: Dictionary = Content.locations[lid]
		var spawns: Dictionary = loc.get("spawns", {})
		for e in loc.get("npcs", []):
			if not Content.npcs.has(e["id"]):
				errs.append("Локация %s: неизвестный NPC %s" % [lid, e["id"]])
			errs.append_array(_check_conds(e.get("if", []), "Локация " + lid, set_flags))
			if _blocked(loc, e["pos"]):
				errs.append("Локация %s: NPC %s стоит в стене" % [lid, e["id"]])
		for o in loc.get("objects", []):
			for r in o.get("dialogues", []):
				if not Content.dialogues.has(r["id"]):
					errs.append("Локация %s/%s: нет диалога %s" % [lid, o["id"], r["id"]])
			errs.append_array(_check_conds(o.get("if", []) + o.get("solid_if", []), "Локация %s/%s" % [lid, o["id"]], set_flags))
		for d in loc.get("doors", []):
			var to: String = d.get("to", "")
			if to != "":
				if not Content.locations.has(to):
					errs.append("Локация %s: дверь в несуществующую локацию %s" % [lid, to])
				elif not Content.locations[to].get("spawns", {}).has(d.get("spawn", "default")):
					errs.append("Локация %s: в %s нет точки появления %s" % [lid, to, d.get("spawn", "")])
			errs.append_array(_check_conds(d.get("if", []), "Дверь в " + lid, set_flags))
		for s in spawns:
			if _blocked(loc, spawns[s]):
				errs.append("Локация %s: точка появления %s в стене" % [lid, s])
	# quests
	for q in Content.quests:
		for o in q.get("objectives", []):
			errs.append_array(_check_conds(o.get("done", []), "Задача %s/%s" % [q["id"], o["id"]], set_flags))
		errs.append_array(_check_conds(q.get("requires", []), "Задача " + q["id"], set_flags))
		for c in q.get("cards", []):
			if not Content.cards.has(c):
				errs.append("Задача %s: нет карточки %s" % [q["id"], c])
	# cards, faq, cases, checklist
	for cid in Content.cards:
		var c: Dictionary = Content.cards[cid]
		if not Content.sections_by_id.has(c.get("section", "")):
			errs.append("Карточка %s: неизвестный раздел %s" % [cid, c.get("section", "")])
		if c.has("contact") and not Content.npcs.has(c["contact"]):
			errs.append("Карточка %s: неизвестный контакт %s" % [cid, c["contact"]])
	for f in Content.faq:
		if not Content.cards.has(f.get("card", "")):
			errs.append("FAQ %s: нет карточки-источника %s" % [f["id"], f.get("card", "")])
		if f.has("contact") and not Content.npcs.has(f["contact"]):
			errs.append("FAQ %s: неизвестный контакт %s" % [f["id"], f["contact"]])
	for cid in Content.cases:
		var c: Dictionary = Content.cases[cid]
		for card_id in c.get("cards", []):
			if not Content.cards.has(card_id):
				errs.append("Кейс %s: нет карточки %s" % [cid, card_id])
		if c.get("type") == "choice" and not c["options"].any(func(o): return o.get("correct", false)):
			errs.append("Кейс %s: нет правильного варианта" % cid)
	for stage in ["week", "month"]:
		for it in Content.checklist.get(stage, {}).get("items", []):
			if it.get("card", "") != "" and not Content.cards.has(it["card"]):
				errs.append("Чек-лист %s: нет карточки %s" % [it["id"], it["card"]])
	# every learnable card must be studyable somewhere
	var studyable := _all_studied()
	for cid in Content.learnable_cards():
		if not studyable.has(cid):
			errs.append("Карточка %s помечена learn, но нигде не изучается" % cid)
	return errs


static func _check_effects(effects: Array, where: String) -> Array:
	var errs: Array = []
	for e in effects:
		if e.has("study"):
			var ids = e["study"]
			for id in (ids if ids is Array else [ids]):
				if not Content.cards.has(id):
					errs.append("%s: нет карточки %s" % [where, id])
	return errs


## Flags referenced by conditions must be set somewhere, otherwise the game can soft-lock.
static func _check_conds(conds: Array, where: String, set_flags: Dictionary) -> Array:
	var errs: Array = []
	for c in conds:
		var s: String = c.trim_prefix("!")
		if s.begins_with("q:"):
			if not Content.quests_by_id.has(s.substr(2)):
				errs.append("%s: неизвестная задача %s" % [where, s])
		elif s.begins_with("case:"):
			if not Content.cases.has(s.substr(5)):
				errs.append("%s: неизвестный кейс %s" % [where, s])
		elif s.begins_with("card:"):
			if not Content.cards.has(s.substr(5)):
				errs.append("%s: неизвестная карточка %s" % [where, s])
		elif not set_flags.has(s) and not c.begins_with("!"):
			errs.append("%s: флаг «%s» нигде не устанавливается" % [where, s])
	return errs


static func _all_effects() -> Array:
	var out: Array = []
	for did in Content.dialogues:
		for n in Content.dialogues[did].get("nodes", {}).values():
			out.append_array(n.get("effects", []))
			for ch in n.get("choices", []):
				out.append_array(ch.get("effects", []))
	for c in Content.cases.values():
		out.append_array(c.get("on_solve", []))
	for q in Content.quests:
		out.append_array(q.get("on_complete", []))
	for l in Content.locations.values():
		out.append_array(l.get("on_enter", []))
	return out


static func _all_set_flags() -> Dictionary:
	var out := {}
	for e in _all_effects():
		if e.has("set"):
			out[e["set"]] = true
	for f in PlannedFlags.LIST:
		out[f] = true
	return out


static func _all_studied() -> Dictionary:
	var out := {}
	for e in _all_effects():
		if e.has("study"):
			for id in (e["study"] if e["study"] is Array else [e["study"]]):
				out[id] = true
	for c in Content.cases.values():
		for id in c.get("cards", []):
			out[id] = true
	for id in PlannedFlags.CARDS:
		out[id] = true
	return out


static func _blocked(loc: Dictionary, p: Array) -> bool:
	var grid: Array = loc.get("grid", [])
	var y := int(p[1])
	var x := int(p[0])
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[y].length():
		return true
	return grid[y][x] in ["#", "r", " "]
