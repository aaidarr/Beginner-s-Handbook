extends Node
## Quest status is derived from GameState flags, never stored separately
## (except `quests_done`, which only fires on_complete effects once).

signal quest_completed(quest: Dictionary)

enum { LOCKED, AVAILABLE, DONE }


func _ready() -> void:
	GameState.changed.connect(_refresh)


func objective_done(o: Dictionary) -> bool:
	return GameState.check(o.get("done", []))


func is_complete(q: Dictionary) -> bool:
	for o in q.get("objectives", []):
		if not objective_done(o):
			return false
	return true


func status(q: Dictionary) -> int:
	if GameState.quests_done.has(q["id"]):
		return DONE
	if GameState.check(q.get("requires", [])):
		return AVAILABLE
	return LOCKED


func current() -> Dictionary:
	for q in Content.quests:
		if q.get("optional", false):
			continue
		if status(q) == AVAILABLE:
			return q
	return {}


func next_objective(q: Dictionary) -> Dictionary:
	for o in q.get("objectives", []):
		if not objective_done(o):
			return o
	return {}


func mandatory() -> Array:
	return Content.quests.filter(func(q): return not q.get("optional", false))


func _refresh() -> void:
	for q in Content.quests:
		if GameState.quests_done.has(q["id"]):
			continue
		if status(q) == AVAILABLE and is_complete(q):
			GameState.quests_done[q["id"]] = true
			GameState.apply_effects(q.get("on_complete", []))
			GameState.toast.emit("Задача выполнена: %s" % q["title"])
			quest_completed.emit(q)
			GameState.save_soon()
			GameState.changed.emit()
			return
