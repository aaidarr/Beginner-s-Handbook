class_name Modal
extends Control
## Full-screen overlay that pauses player movement while open.

signal closed

var is_open := false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func open_modal() -> void:
	if is_open:
		return
	is_open = true
	Controls.locks += 1
	visible = true


func close_modal() -> void:
	if not is_open:
		return
	is_open = false
	Controls.locks -= 1
	visible = false
	closed.emit()
