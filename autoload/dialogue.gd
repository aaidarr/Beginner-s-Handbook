extends Node
## UI-agnostic dialogue runner. Emits `line`, waits for `advance(choice)`.
## Node fields: speaker, emotion, text, choices[], next, if/else, effects, case, book, end.
## Choice fields: text, next, if, effects, correct(bool), feedback, feedback_speaker, retry.

signal started(id: String)
signal line(data: Dictionary)
signal ended(id: String)
signal case_requested(case_id: String)
signal book_requested(section: String, card: String)
signal _advanced(choice: int)
signal _resumed

var active := false
var current_id := ""


func start(id: String) -> void:
	if active or id == "":
		return
	var d: Dictionary = Content.dialogues.get(id, {})
	if d.is_empty():
		push_error("Dialogue not found: " + id)
		return
	active = true
	current_id = id
	started.emit(id)
	var nodes: Dictionary = d.get("nodes", {})
	var node_id: String = d.get("start", "start")
	var guard := 0
	while node_id != "" and guard < 500:
		guard += 1
		var node: Dictionary = nodes.get(node_id, {})
		if node.is_empty():
			push_error("Dialogue %s: missing node %s" % [id, node_id])
			break
		if node.has("if") and not GameState.check(node["if"]):
			node_id = node.get("else", node.get("next", ""))
			continue
		GameState.apply_effects(node.get("effects", []))
		if node.has("case"):
			case_requested.emit(node["case"])
			await _resumed
		if node.has("book"):
			book_requested.emit(node["book"], node.get("card", ""))
			await _resumed
		if node.has("text"):
			var choices: Array = node.get("choices", []).filter(
				func(c): return GameState.check(c.get("if", [])))
			line.emit(_line_data(node, choices))
			var picked: int = await _advanced
			if choices.size() > 0:
				var ch: Dictionary = choices[clampi(picked, 0, choices.size() - 1)]
				GameState.apply_effects(ch.get("effects", []))
				if ch.get("correct", true) == false:
					GameState.dialogue_mistakes += 1
				if ch.has("feedback"):
					line.emit(_line_data({
						"speaker": ch.get("feedback_speaker", node.get("speaker", "")),
						"emotion": ch.get("feedback_emotion", "neutral"),
						"text": ch["feedback"],
						"verdict": "" if not ch.has("correct") else ("good" if ch["correct"] else "bad"),
					}, []))
					await _advanced
				if ch.get("retry", false):
					continue
				node_id = ch.get("next", "")
				continue
		if node.get("end", false):
			break
		node_id = node.get("next", "")
	active = false
	current_id = ""
	GameState.save_soon()
	ended.emit(id)


func advance(choice := -1) -> void:
	if active:
		_advanced.emit(choice)


## Called by the UI when a case view or book opened from a dialogue is closed.
func resume() -> void:
	_resumed.emit()


func _line_data(node: Dictionary, choices: Array) -> Dictionary:
	var speaker: String = node.get("speaker", "")
	var name := ""
	var role := ""
	if speaker == "hero":
		name = GameState.player_name
	elif speaker != "":
		var n: Dictionary = Content.npc(speaker)
		name = n.get("short", n.get("name", speaker))
		role = n.get("role", "")
	return {
		"speaker": speaker,
		"name": name,
		"role": role,
		"emotion": node.get("emotion", "neutral"),
		"text": GameState.format_text(node.get("text", "")),
		"verdict": node.get("verdict", ""),
		"choices": choices.map(func(c): return GameState.format_text(c["text"])),
	}
