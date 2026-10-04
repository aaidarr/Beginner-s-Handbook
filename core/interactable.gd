class_name Interactable
extends Area2D
## One reusable component for every NPC and world object the player can use.
## Behaviour is data-driven: `rules` picks a dialogue by GameState conditions.

const LAYER := 2

var id := ""
var kind := "object"          # "npc" | "object"
var title := ""
var rules: Array = []
var show_if: Array = []
var solid_if: Array = []
var view: Node2D
var focused := false
var _body: StaticBody2D
var _t := 0.0
var _prop_base := ""
var _alt: Dictionary = {}


func setup_npc(npc_id: String, entry: Dictionary) -> void:
	id = npc_id
	kind = "npc"
	var n: Dictionary = Content.npc(npc_id)
	title = n.get("short", n.get("name", npc_id))
	rules = n.get("dialogues", [])
	show_if = entry.get("if", [])
	var cv := CharacterView.new()
	cv.setup(npc_id, n.get("look", {}))
	cv.facing = entry.get("facing", "down")
	view = cv
	add_child(cv)
	_add_shape(CircleShape2D.new(), Vector2(0, -8), 12.0)
	_body = _make_body(Vector2(12, 6), Vector2(0, -3))
	_finish()


func setup_object(entry: Dictionary, tile: int) -> void:
	id = entry.get("id", "")
	kind = "object" if entry.has("dialogues") else "decor"
	title = entry.get("title", "")
	rules = entry.get("dialogues", [])
	show_if = entry.get("if", [])
	solid_if = entry.get("solid_if", [])
	var sz: Array = entry.get("size", [1, 1])
	var px := Vector2(sz[0], sz[1]) * tile
	_prop_base = entry.get("prop", "box")
	_alt = entry.get("alt", {})
	var pv := PropView.new()
	pv.setup(_prop_base, px)
	view = pv
	add_child(pv)
	if entry.get("solid", false) or not solid_if.is_empty():
		var depth: float = entry.get("depth", 1.0) * tile
		_body = _make_body(Vector2(px.x, depth), Vector2(0, -depth / 2.0))
	if kind == "object":
		var rect := RectangleShape2D.new()
		rect.size = px + Vector2(6, 6)
		var cs := CollisionShape2D.new()
		cs.shape = rect
		cs.position = Vector2(0, -px.y / 2.0)
		add_child(cs)
	_finish()


func _finish() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
	GameState.changed.connect(refresh)
	refresh()


func _add_shape(shape: CircleShape2D, pos: Vector2, radius: float) -> void:
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = pos
	add_child(cs)


func _make_body(size: Vector2, pos: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var rect := RectangleShape2D.new()
	rect.size = size
	var cs := CollisionShape2D.new()
	cs.shape = rect
	cs.position = pos
	body.add_child(cs)
	add_child(body)
	return body


func refresh() -> void:
	var shown := GameState.check(show_if)
	visible = shown
	monitorable = shown and kind != "decor"
	if _body:
		var solid := shown and (solid_if.is_empty() or GameState.check(solid_if))
		_body.process_mode = Node.PROCESS_MODE_INHERIT if solid else Node.PROCESS_MODE_DISABLED
		_body.collision_layer = 1 if solid else 0
	if not _alt.is_empty():
		var pv := view as PropView
		var want: String = _alt["prop"] if GameState.check(_alt.get("if", [])) else _prop_base
		if pv.kind != want:
			pv.setup(want, pv.size)


func focus_point() -> Vector2:
	if view is PropView:
		return global_position - Vector2(0, (view as PropView).size.y / 2.0)
	return global_position - Vector2(0, 8)


func can_interact() -> bool:
	return visible and kind != "decor" and Content.pick_dialogue(rules) != ""


func action_label() -> String:
	return "Говорить" if kind == "npc" else "Осмотреть"


func interact(player: Node2D) -> void:
	if kind == "npc" and view is CharacterView and player:
		var d := player.global_position - global_position
		(view as CharacterView).facing = _dir_name(d)
		GameState.set_flag("met_" + id)
	Dialogue.start(Content.pick_dialogue(rules))


static func _dir_name(d: Vector2) -> String:
	if absf(d.x) > absf(d.y):
		return "right" if d.x > 0 else "left"
	return "down" if d.y > 0 else "up"


func set_focused(on: bool) -> void:
	focused = on
	queue_redraw()


func _process(delta: float) -> void:
	if focused:
		_t += delta
		queue_redraw()


func _draw() -> void:
	if not focused:
		return
	var top := -30.0
	if view is PropView:
		top = -(view as PropView).size.y - 4.0
	var bob := 0.0 if GameState.settings.get("reduce_motion", false) else roundf(sin(_t * 6.0) * 1.5)
	var p := Vector2(0, top + bob)
	draw_rect(Rect2(p.x - 4, p.y - 9, 8, 9), Color("#fff6d8"))
	draw_rect(Rect2(p.x - 4, p.y - 9, 8, 9), Color("#2b2118"), false, 1.0)
	draw_rect(Rect2(p.x - 1, p.y - 7, 2, 4), Color("#c0392b"))
	draw_rect(Rect2(p.x - 1, p.y - 2, 2, 1), Color("#c0392b"))
