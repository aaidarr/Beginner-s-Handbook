class_name Search
## Full-text search over book cards, FAQ and contacts with naive Russian stemming.

const STOP := ["как", "что", "где", "кто", "куда", "если", "при", "для", "это", "мне", "меня",
	"нужно", "надо", "можно", "или", "какой", "какие", "каких", "чем", "когда", "мой", "моя",
	"мое", "мои", "вам", "вас", "нам", "нас", "его", "она", "они", "так", "уже", "тут", "там",
	"есть", "быть", "делать", "сделать", "обратиться", "поводу", "вопрос", "кому"]

static var _index: Array = []


static func norm(s: String) -> String:
	s = s.to_lower().replace("ё", "е")
	var out := ""
	for ch in s:
		out += ch if (ch >= "а" and ch <= "я") or (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else " "
	return out


static func words(s: String) -> PackedStringArray:
	return norm(s).split(" ", false)


static func query_stems(q: String) -> Array:
	var out: Array = []
	for w in words(q):
		if w.length() < 3 or w in STOP:
			continue
		var stem := w.substr(0, clampi(w.length() - 2, 4, 5)) if w.length() > 4 else w
		if stem not in out:
			out.append(stem)
	return out


static func rebuild() -> void:
	_index.clear()
	for c in Content.cards.values():
		var sec: Dictionary = Content.sections_by_id.get(c.get("section", ""), {})
		var body := String(c.get("short", ""))
		for b in c.get("blocks", []):
			body += " " + String(b.get("text", ""))
			for it in b.get("items", []):
				body += " " + String(it)
		_index.append({
			"kind": "card", "id": c["id"], "title": c["title"],
			"path": "%s → %s" % [sec.get("title", ""), c["title"]],
			"strong": words(c["title"] + " " + " ".join(c.get("tags", []))),
			"weak": words(body),
		})
	for f in Content.faq:
		var cat := ""
		for k in Content.faq_categories:
			if k["id"] == f.get("category", ""):
				cat = k["title"]
		_index.append({
			"kind": "faq", "id": f["id"], "title": f["q"],
			"path": "FAQ → %s" % cat,
			"strong": words(f["q"] + " " + " ".join(f.get("tags", []))),
			"weak": words(f.get("a", "")),
		})
	for n in Content.npcs.values():
		if not n.get("in_team", true):
			continue
		_index.append({
			"kind": "contact", "id": n["id"], "title": n["name"],
			"path": "Команда и контакты → %s" % n.get("role", ""),
			"strong": words(n["name"] + " " + n.get("role", "") + " " + n.get("dept", "")),
			"weak": words(n.get("responsibility", "")),
		})


static func run(q: String, limit := 12) -> Array:
	if _index.is_empty():
		rebuild()
	var stems := query_stems(q)
	if stems.is_empty():
		return []
	var results: Array = []
	for doc in _index:
		var score := 0.0
		var hits := 0
		for st in stems:
			var s := 0.0
			for w in doc["strong"]:
				if w.begins_with(st):
					s = 3.0
					break
			if s == 0.0:
				for w in doc["weak"]:
					if w.begins_with(st):
						s = 1.0
						break
			if s > 0.0:
				hits += 1
			score += s
		if hits == 0:
			continue
		score *= float(hits) / stems.size()
		if doc["kind"] == "faq":
			score += 0.1
		results.append({"kind": doc["kind"], "id": doc["id"], "title": doc["title"], "path": doc["path"], "score": score})
	results.sort_custom(func(a, b): return a["score"] > b["score"])
	return results.slice(0, limit)
