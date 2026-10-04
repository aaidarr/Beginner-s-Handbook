class_name Location
extends Node2D
## Builds a room from data/locations/<id>.json:
## grid (ASCII: '#' wall, 'r' railing, '.' floor, ' ' void), npcs, objects, doors, labels, spawns.

const TILE := 16

var data: Dictionary = {}
var grid: Array = []
var entities: Node2D
var _door_cooldown := 0.0


func build(d: Dictionary) -> void:
	data = d
	name = d.get("id", "Location")
	grid = d.get("grid", [])
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	_build_walls()
	for e in d.get("objects", []):
		var it := Interactable.new()
		it.setup_object(e, TILE)
		var sz: Array = e.get("size", [1, 1])
		it.position = Vector2((e["pos"][0] + sz[0] / 2.0) * TILE, (e["pos"][1] + sz[1]) * TILE)
		it.z_index = int(e.get("z", 0))
		entities.add_child(it)
	for e in d.get("npcs", []):
		var it := Interactable.new()
		it.setup_npc(e["id"], e)
		it.position = tile_to_feet(e["pos"])
		entities.add_child(it)
	for door in d.get("doors", []):
		_build_door(door)
	queue_redraw()


func add_entity(n: Node2D) -> void:
	entities.add_child(n)


func tile_to_feet(p: Array) -> Vector2:
	return Vector2(p[0] * TILE + TILE / 2.0, p[1] * TILE + TILE - 2)


func spawn_point(spawn_id: String) -> Vector2:
	var spawns: Dictionary = data.get("spawns", {})
	var p: Array = spawns.get(spawn_id, spawns.get("default", [1, 1]))
	return tile_to_feet(p)


func bounds() -> Rect2:
	var w := 0
	for row in grid:
		w = maxi(w, row.length())
	return Rect2(0, 0, w * TILE, grid.size() * TILE)


func _cell(x: int, y: int) -> String:
	if y < 0 or y >= grid.size():
		return " "
	var row: String = grid[y]
	if x < 0 or x >= row.length():
		return " "
	return row[x]


func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	for y in grid.size():
		var row: String = grid[y]
		var x := 0
		while x < row.length():
			if row[x] in ["#", "r", " "]:
				var start := x
				while x < row.length() and row[x] in ["#", "r", " "]:
					x += 1
				var rect := RectangleShape2D.new()
				rect.size = Vector2((x - start) * TILE, TILE)
				var cs := CollisionShape2D.new()
				cs.shape = rect
				cs.position = Vector2((start + (x - start) / 2.0) * TILE, y * TILE + TILE / 2.0)
				body.add_child(cs)
			else:
				x += 1
	var b := bounds()
	for r in [Rect2(b.position.x - TILE, b.position.y - TILE * 2, b.size.x + TILE * 2, TILE),
			Rect2(b.position.x - TILE, b.end.y + TILE, b.size.x + TILE * 2, TILE),
			Rect2(b.position.x - TILE * 2, b.position.y, TILE, b.size.y),
			Rect2(b.end.x + TILE, b.position.y, TILE, b.size.y)]:
		var rect := RectangleShape2D.new()
		rect.size = r.size
		var cs := CollisionShape2D.new()
		cs.shape = rect
		cs.position = r.get_center()
		body.add_child(cs)


func _build_door(door: Dictionary) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = Player.LAYER
	var r: Array = door["rect"]
	var rect := RectangleShape2D.new()
	rect.size = Vector2(r[2], r[3]) * TILE
	var cs := CollisionShape2D.new()
	cs.shape = rect
	cs.position = Vector2(r[0] + r[2] / 2.0, r[1] + r[3] / 2.0) * TILE
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(body):
		if body is Player:
			_on_door(door, body))


func _on_door(door: Dictionary, player: Player) -> void:
	if Router.busy or _door_cooldown > 0.0:
		return
	_door_cooldown = 0.6
	if not GameState.check(door.get("if", [])):
		GameState.toast.emit(GameState.format_text(door.get("locked", "Пока закрыто.")))
		player.bump_back()
		return
	if door.get("to", "") == "":
		GameState.toast.emit(door.get("wip", door.get("locked", "Пока закрыто.")))
		player.bump_back()
		return
	Router.go(door["to"], door.get("spawn", "default"))


func _process(delta: float) -> void:
	_door_cooldown = maxf(0.0, _door_cooldown - delta)


func _draw() -> void:
	var floor_a := Color(data.get("floor_a", "#d8cfb8"))
	var floor_b := Color(data.get("floor_b", "#cfc5ab"))
	var wall := Color(data.get("wall", "#7a8a9a"))
	var style: String = data.get("floor", "checker")
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var c := row[x]
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			if c == " ":
				continue
			if c == "#":
				draw_rect(r, wall.darkened(0.35))
				draw_rect(Rect2(r.position, Vector2(TILE, 3)), wall.darkened(0.15))
				if _cell(x, y + 1) not in ["#", " "]:
					draw_rect(Rect2(r.position + Vector2(0, 4), Vector2(TILE, TILE - 4)), wall)
					draw_rect(Rect2(r.position + Vector2(0, TILE - 2), Vector2(TILE, 2)), wall.darkened(0.25))
				continue
			var fc := floor_a
			match style:
				"checker":
					fc = floor_a if (x + y) % 2 == 0 else floor_b
				"parquet":
					fc = floor_a if (x / 2 + y) % 2 == 0 else floor_b
				"carpet":
					fc = floor_a
			draw_rect(r, fc)
			if style == "parquet":
				draw_rect(Rect2(r.position + Vector2(0, TILE - 1), Vector2(TILE, 1)), floor_b.darkened(0.1))
			elif style == "carpet" and (x * 7 + y * 3) % 5 == 0:
				draw_rect(Rect2(r.position + Vector2(5, 7), Vector2(2, 2)), floor_b)
			if c == "r":
				draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(TILE, 2)), Color("#8a8f98"))
				draw_rect(Rect2(r.position + Vector2(0, 8), Vector2(TILE, 6)), Color("#b0b5bd"))
				draw_rect(Rect2(r.position + Vector2(1, 8), Vector2(2, 8)), Color("#6a6f78"))
			elif c == "D":
				draw_rect(r, Color(data.get("door", "#6b4a2a")))
				draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(TILE - 2, TILE - 1)), Color(data.get("door", "#6b4a2a")).lightened(0.15))
			elif c == "E":
				draw_rect(r, Color("#9fc7e0"))
				draw_rect(Rect2(r.position, Vector2(TILE, 1)), Color("#e8f4fa"))
	var font := Fonts.pixel()
	for l in data.get("labels", []):
		var p := Vector2(l["pos"][0] * TILE, l["pos"][1] * TILE + 11)
		var text: String = l["text"]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		draw_rect(Rect2(p.x - 2, p.y - 9, w + 4, 11), Color("#f4ecd6"))
		draw_rect(Rect2(p.x - 2, p.y - 9, w + 4, 11), Color("#2b2118"), false, 1.0)
		draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#2b2118"))
