extends Node
## All mutable player progress. UI only reads it and listens to `changed`.

signal changed
signal card_studied(id: String)
signal toast(text: String)

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.json"
const SAVE_VERSION := 1

var player_name := "Новичок"
var player_look := 0
var location := ""
var spawn := ""
var flags: Dictionary = {}
var studied: Dictionary = {}
var cases: Dictionary = {}          # case_id -> {attempts, first_try}
var quests_done: Dictionary = {}
var checklist_manual: Dictionary = {}
var favorites: Dictionary = {}
var quiz_results: Array = []        # [{score, total, passed, wrong:[ids], date}]
var dialogue_mistakes := 0

var settings := {
	"text_scale": 1.0,
	"text_speed": 1,
	"auto_advance": false,
	"high_contrast": false,
	"reduce_motion": false,
	"left_handed": false,
	"music": 0.6,
	"sfx": 0.8,
}

var _save_queued := false


func _ready() -> void:
	load_settings()


func reset() -> void:
	player_name = "Новичок"
	player_look = 0
	location = ""
	spawn = ""
	flags.clear()
	studied.clear()
	cases.clear()
	quests_done.clear()
	checklist_manual.clear()
	favorites.clear()
	quiz_results.clear()
	dialogue_mistakes = 0
	changed.emit()


func has_flag(f: String) -> bool:
	return flags.has(f)


func set_flag(f: String, on := true) -> void:
	if on == flags.has(f):
		return
	if on:
		flags[f] = true
	else:
		flags.erase(f)
	changed.emit()


## Conditions: "flag", "!flag", "q:quest_id", "case:case_id", "card:card_id". All must hold.
func check(conds: Array) -> bool:
	for c in conds:
		var s: String = c
		var neg := s.begins_with("!")
		if neg:
			s = s.substr(1)
		var ok: bool
		if s.begins_with("q:"):
			ok = quests_done.has(s.substr(2))
		elif s.begins_with("case:"):
			ok = cases.has(s.substr(5))
		elif s.begins_with("card:"):
			ok = studied.has(s.substr(5))
		else:
			ok = flags.has(s)
		if ok == neg:
			return false
	return true


func study(card_id: String) -> void:
	if studied.has(card_id):
		return
	studied[card_id] = true
	card_studied.emit(card_id)
	var c: Dictionary = Content.card(card_id)
	if not c.is_empty():
		toast.emit("В книжку добавлено: «%s»" % c.get("title", card_id))
	changed.emit()


func apply_effects(effects: Array) -> void:
	for e in effects:
		if e.has("set"):
			set_flag(e["set"])
		if e.has("unset"):
			set_flag(e["unset"], false)
		if e.has("study"):
			var ids = e["study"]
			for id in (ids if ids is Array else [ids]):
				study(id)
		if e.has("toast"):
			toast.emit(format_text(e["toast"]))


func record_case(case_id: String, attempts: int) -> void:
	if cases.has(case_id):
		return
	cases[case_id] = {"attempts": attempts, "first_try": attempts == 1}
	var c: Dictionary = Content.cases.get(case_id, {})
	for card_id in c.get("cards", []):
		study(card_id)
	apply_effects(c.get("on_solve", []))
	changed.emit()


func toggle_manual(item_id: String) -> void:
	if checklist_manual.has(item_id):
		checklist_manual.erase(item_id)
	else:
		checklist_manual[item_id] = true
	changed.emit()


func toggle_favorite(card_id: String) -> void:
	if favorites.has(card_id):
		favorites.erase(card_id)
	else:
		favorites[card_id] = true
	changed.emit()


func format_text(t: String) -> String:
	return t.replace("{name}", player_name)


# --- persistence -----------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"player_name": player_name,
		"player_look": player_look,
		"location": location,
		"spawn": spawn,
		"flags": flags,
		"studied": studied,
		"cases": cases,
		"quests_done": quests_done,
		"checklist_manual": checklist_manual,
		"favorites": favorites,
		"quiz_results": quiz_results,
		"dialogue_mistakes": dialogue_mistakes,
	}


func from_dict(d: Dictionary) -> void:
	player_name = d.get("player_name", "Новичок")
	player_look = int(d.get("player_look", 0))
	location = d.get("location", "")
	spawn = d.get("spawn", "")
	flags = d.get("flags", {})
	studied = d.get("studied", {})
	cases = d.get("cases", {})
	quests_done = d.get("quests_done", {})
	checklist_manual = d.get("checklist_manual", {})
	favorites = d.get("favorites", {})
	quiz_results = d.get("quiz_results", [])
	dialogue_mistakes = int(d.get("dialogue_mistakes", 0))
	changed.emit()


## Coalesces several changes in one frame into a single write.
func save_soon() -> void:
	if _save_queued:
		return
	_save_queued = true
	(func():
		_save_queued = false
		save()).call_deferred()


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict(), "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text()) if f else null
	if not data is Dictionary:
		return false
	from_dict(data)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings, "\t"))


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text()) if f else null
	if data is Dictionary:
		for k in data:
			settings[k] = data[k]


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if location != "":
			save()
