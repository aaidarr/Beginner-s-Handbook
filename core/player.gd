class_name Player
extends CharacterBody2D

const LAYER := 4
const SPEED := 78.0
const ZOOM := 3.0

var look := 0
var view: CharacterView
var camera: Camera2D
var focus: Interactable
var _reach: Area2D
var _last_dir := Vector2.DOWN
var _bounds := Rect2()


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 6)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -3)
	add_child(cs)
	view = CharacterView.new()
	var looks: Array = Content.org.get("hero_looks", [{}])
	view.setup("hero_%d" % look, looks[clampi(look, 0, looks.size() - 1)])
	add_child(view)
	_reach = Area2D.new()
	_reach.collision_layer = 0
	_reach.collision_mask = Interactable.LAYER
	var rs := CircleShape2D.new()
	rs.radius = 13.0
	var rcs := CollisionShape2D.new()
	rcs.shape = rs
	_reach.add_child(rcs)
	add_child(_reach)
	get_viewport().size_changed.connect(_apply_limits)


func setup_camera(b: Rect2) -> void:
	_bounds = b
	camera = Camera2D.new()
	camera.zoom = Vector2(ZOOM, ZOOM)
	camera.position = Vector2(0, -12)
	camera.position_smoothing_enabled = not GameState.settings.get("reduce_motion", false)
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()
	_apply_limits()
	camera.reset_smoothing()


func _apply_limits() -> void:
	if camera == null:
		return
	var vis := get_viewport_rect().size / ZOOM
	var b := _bounds
	if b.size.x < vis.x:
		camera.limit_left = int(b.get_center().x - vis.x / 2.0)
		camera.limit_right = int(b.get_center().x + vis.x / 2.0)
	else:
		camera.limit_left = int(b.position.x)
		camera.limit_right = int(b.end.x)
	if b.size.y < vis.y:
		camera.limit_top = int(b.get_center().y - vis.y / 2.0)
		camera.limit_bottom = int(b.get_center().y + vis.y / 2.0)
	else:
		camera.limit_top = int(b.position.y)
		camera.limit_bottom = int(b.end.y)


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if not Controls.locked() and not Router.busy:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down") + Controls.stick
		dir = dir.limit_length(1.0)
	velocity = dir * SPEED
	move_and_slide()
	view.walking = dir.length() > 0.1
	if view.walking:
		_last_dir = dir.normalized()
		view.facing = Interactable._dir_name(dir)
	_reach.position = _last_dir * 9.0 + Vector2(0, -6)
	_update_focus()


func _update_focus() -> void:
	var best: Interactable = null
	var best_d := INF
	if not Controls.locked():
		for a in _reach.get_overlapping_areas():
			if a is Interactable and a.can_interact():
				var d := _reach.global_position.distance_to(a.focus_point())
				if d < best_d:
					best_d = d
					best = a
	if best != focus:
		if is_instance_valid(focus):
			focus.set_focused(false)
		focus = best
		if focus:
			focus.set_focused(true)
		Router.focus_changed.emit(focus)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		try_interact()


func try_interact() -> void:
	if Controls.locked() or Router.busy or focus == null:
		return
	focus.interact(self)


func bump_back() -> void:
	move_and_collide(-_last_dir * 10.0)
