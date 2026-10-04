class_name TouchControls
extends Control
## Floating virtual joystick (left half) + action button (right). Mirrored for left-handed mode.

const RADIUS := 90.0

var _touch := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _action: Button
var _stick_zone: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_zone = Control.new()
	_stick_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	_stick_zone.gui_input.connect(_on_stick_input)
	_stick_zone.draw.connect(_draw_stick)
	add_child(_stick_zone)
	_action = Button.new()
	_action.theme_type_variation = "Accent"
	_action.custom_minimum_size = Vector2(150, 150)
	_action.focus_mode = Control.FOCUS_NONE
	_action.pressed.connect(func():
		if Router.player:
			Router.player.try_interact())
	add_child(_action)
	Router.focus_changed.connect(_on_focus)
	_on_focus(null)
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()


func _layout() -> void:
	var left: bool = GameState.settings.get("left_handed", false)
	var m := Ui.safe_margins(get_viewport())
	var w := size.x
	_stick_zone.position = Vector2(w * 0.5 if left else 0.0, size.y * 0.3)
	_stick_zone.size = Vector2(w * 0.5, size.y * 0.7)
	_action.position = Vector2(m.x + 24 if left else w - 150 - m.z - 24, size.y - 150 - m.w - 24)
	_action.size = Vector2(150, 150)


func _on_focus(target: Interactable) -> void:
	_action.text = target.action_label() if target else "Действие"
	_action.disabled = target == null


func _process(_d: float) -> void:
	var active := not Controls.locked() and Router.player != null
	visible = active
	if not active and _touch != -1:
		_release()


func _on_stick_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and _touch == -1:
			_touch = ev.index
			_origin = ev.position
			_knob = _origin
			Controls.stick = Vector2.ZERO
		elif not ev.pressed and ev.index == _touch:
			_release()
		_stick_zone.queue_redraw()
	elif ev is InputEventScreenDrag and ev.index == _touch:
		var d: Vector2 = ev.position - _origin
		_knob = _origin + d.limit_length(RADIUS)
		var v := d / RADIUS
		Controls.stick = v.limit_length(1.0) if v.length() > 0.15 else Vector2.ZERO
		_stick_zone.queue_redraw()


func _release() -> void:
	_touch = -1
	Controls.stick = Vector2.ZERO
	_stick_zone.queue_redraw()


func _draw_stick() -> void:
	if _touch == -1:
		var hint := Vector2(_stick_zone.size.x * 0.35, _stick_zone.size.y * 0.62)
		_stick_zone.draw_circle(hint, RADIUS, Color(1, 1, 1, 0.10))
		_stick_zone.draw_arc(hint, RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
		_stick_zone.draw_circle(hint, 34, Color(1, 1, 1, 0.25))
		return
	_stick_zone.draw_circle(_origin, RADIUS, Color(0, 0, 0, 0.25))
	_stick_zone.draw_arc(_origin, RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.6), 3.0)
	_stick_zone.draw_circle(_knob, 40, Color(1, 1, 1, 0.7))
