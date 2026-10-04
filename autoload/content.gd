extends Node
## Read-only access to all JSON content in res://data.

const DATA := "res://data/"

var org: Dictionary = {}
var npcs: Dictionary = {}
var dialogues: Dictionary = {}
var quests: Array = []
var quests_by_id: Dictionary = {}
var cases: Dictionary = {}
var sections: Array = []
var sections_by_id: Dictionary = {}
var cards: Dictionary = {}
var faq: Array = []
var faq_categories: Array = []
var checklist: Dictionary = {}
var locations: Dictionary = {}
var quiz: Dictionary = {}
var errors: Array = []


func _ready() -> void:
	load_all()


func load_all() -> void:
	errors.clear()
	org = _load(DATA + "org.json", {})
	npcs = _index(_load(DATA + "npcs.json", []))
	quests = _load(DATA + "quests.json", [])
	quests_by_id = _index(quests)
	cases = _index(_load(DATA + "cases.json", []))
	var book: Dictionary = _load(DATA + "book.json", {})
	sections = book.get("sections", [])
	sections_by_id = _index(sections)
	cards.clear()
	for path in _list(DATA + "cards"):
		for c in _load(path, []):
			cards[c["id"]] = c
	var faq_data: Dictionary = _load(DATA + "faq.json", {})
	faq_categories = faq_data.get("categories", [])
	faq = faq_data.get("items", [])
	checklist = _load(DATA + "checklist.json", {})
	quiz = _load(DATA + "quiz.json", {})
	dialogues.clear()
	for path in _list(DATA + "dialogues"):
		var file_dialogues: Dictionary = _load(path, {})
		for id in file_dialogues:
			dialogues[id] = file_dialogues[id]
	locations.clear()
	for path in _list(DATA + "locations"):
		var loc: Dictionary = _load(path, {})
		if loc.has("id"):
			locations[loc["id"]] = loc


func npc(id: String) -> Dictionary:
	return npcs.get(id, {})


func card(id: String) -> Dictionary:
	return cards.get(id, {})


func cards_in(section_id: String) -> Array:
	var out: Array = []
	for c in cards.values():
		if c.get("section", "") == section_id:
			out.append(c)
	out.sort_custom(func(a, b): return int(a.get("order", 999)) < int(b.get("order", 999)))
	return out


func learnable_cards() -> Array:
	var out: Array = []
	for c in cards.values():
		if c.has("learn"):
			out.append(c["id"])
	return out


## Picks the first dialogue whose "if" conditions hold.
func pick_dialogue(rules: Array) -> String:
	for r in rules:
		if GameState.check(r.get("if", [])):
			return r.get("id", "")
	return ""


func _load(path: String, fallback: Variant) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		errors.append("Не найден файл: " + path)
		return fallback
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		errors.append("%s:%d — %s" % [path, json.get_error_line(), json.get_error_message()])
		push_error(errors[-1])
		return fallback
	return json.data


func _index(arr: Array) -> Dictionary:
	var d := {}
	for item in arr:
		d[item["id"]] = item
	return d


func _list(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".json"):
			out.append(dir_path + "/" + f)
	out.sort()
	return out
