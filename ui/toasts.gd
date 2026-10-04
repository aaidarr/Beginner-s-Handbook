class_name Toasts
extends Control
## Short non-blocking messages at the top centre (visual duplicate of every sound cue).

var _list: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list = Ui.vbox(8)
	_list.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_list.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_list.offset_top = 132
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_list)
	GameState.toast.connect(show_toast)


var _pending: Array = []


## Held back while a full-screen view (case, book) is open so they never cover its content.
func show_toast(text: String) -> void:
	if Controls.locks > 0:
		_pending.append(text)
		return
	_show(text)


func _process(_d: float) -> void:
	visible = Controls.locks == 0
	if Controls.locks == 0 and not _pending.is_empty():
		_show(_pending.pop_front())


func _show(text: String) -> void:
	if _list.get_child_count() >= 3:
		_list.get_child(0).queue_free()
	var p := Ui.panel("Warn")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Ui.label(text, "Strong", false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	_list.add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
