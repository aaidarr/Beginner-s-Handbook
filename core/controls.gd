class_name Controls
## Shared input state between touch UI and the player.

static var stick := Vector2.ZERO
static var locks := 0


static func locked() -> bool:
	return locks > 0 or Dialogue.active


static func setup_input_map() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
		"book": [KEY_B, KEY_TAB],
		"pause": [KEY_ESCAPE],
	}
	for action in map:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
