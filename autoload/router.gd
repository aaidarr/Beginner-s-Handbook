extends Node
## Builds locations from data, places the player, fades between rooms.

signal location_changed(id: String)
signal focus_changed(target: Interactable)

var world: Node2D
var location: Location
var player: Player
var busy := false
var _fade: ColorRect


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.05, 0.04, 0.07, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func go(loc_id: String, spawn_id: String) -> void:
	if busy or world == null:
		return
	if not Content.locations.has(loc_id):
		push_error("Unknown location " + loc_id)
		return
	busy = true
	await _fade_to(1.0)
	clear()
	location = Location.new()
	world.add_child(location)
	location.build(Content.locations[loc_id])
	player = Player.new()
	player.look = GameState.player_look
	location.add_entity(player)
	player.position = location.spawn_point(spawn_id)
	player.setup_camera(location.bounds())
	GameState.location = loc_id
	GameState.spawn = spawn_id
	GameState.apply_effects(location.data.get("on_enter", []))
	GameState.save()
	location_changed.emit(loc_id)
	await _fade_to(0.0)
	busy = false


func clear() -> void:
	if location:
		location.queue_free()
	location = null
	player = null


func _fade_to(alpha: float) -> void:
	if GameState.settings.get("reduce_motion", false):
		_fade.color.a = alpha
		await get_tree().process_frame
		return
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, 0.22)
	await tw.finished
