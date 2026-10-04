class_name CharacterView
extends Node2D
## Draws a 16x24 character. Uses assets/sprites/<id>.png (3 cols x 4 rows sheet:
## idle, step1, step2 × down, left, right, up) when the artist provides it,
## otherwise a procedural placeholder from the `look` colours.

const W := 16
const H := 24
const DIRS := {"down": 0, "left": 1, "right": 2, "up": 3}

var look: Dictionary = {}
var facing := "down"
var walking := false
var _t := 0.0
var _sprite: Sprite2D


func setup(sprite_id: String, look_data: Dictionary) -> void:
	look = look_data
	var path := "res://assets/sprites/%s.png" % sprite_id
	if ResourceLoader.exists(path):
		_sprite = Sprite2D.new()
		_sprite.texture = load(path)
		_sprite.hframes = 3
		_sprite.vframes = 4
		_sprite.offset = Vector2(0, -H / 2.0)
		add_child(_sprite)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _sprite:
		var frame := 0
		if walking:
			frame = 1 + int(_t * 6.0) % 2
		_sprite.frame = DIRS.get(facing, 0) * 3 + frame
	else:
		queue_redraw()


func _c(key: String, def: String) -> Color:
	return Color(look.get(key, def))


func _draw() -> void:
	if _sprite:
		return
	var step := int(_t * 6.0) % 2 if walking else -1
	var ox := -W / 2
	var oy := -H
	# shadow
	draw_rect(Rect2(ox + 2, -2, 12, 3), Color(0, 0, 0, 0.25))
	# legs
	var legs := _c("legs", "#2b2b35")
	var l_off := 1 if step == 0 else 0
	var r_off := 1 if step == 1 else 0
	draw_rect(Rect2(ox + 4, oy + 18 - l_off, 3, 5 + l_off), legs)
	draw_rect(Rect2(ox + 9, oy + 18 - r_off, 3, 5 + r_off), legs)
	# body
	var body := _c("body", "#3b6ea5")
	draw_rect(Rect2(ox + 3, oy + 10, 10, 9), body)
	draw_rect(Rect2(ox + 2, oy + 11, 1, 6), body.darkened(0.2))
	draw_rect(Rect2(ox + 13, oy + 11, 1, 6), body.darkened(0.2))
	if look.has("tie"):
		draw_rect(Rect2(ox + 7, oy + 10, 2, 6), Color(look["tie"]))
	# head
	var skin := _c("skin", "#f0c8a0")
	draw_rect(Rect2(ox + 4, oy + 2, 8, 8), skin)
	var hair := _c("hair", "#3a2a1a")
	draw_rect(Rect2(ox + 4, oy + 1, 8, 3), hair)
	if look.get("long_hair", false):
		draw_rect(Rect2(ox + 3, oy + 2, 2, 9), hair)
		draw_rect(Rect2(ox + 11, oy + 2, 2, 9), hair)
	if look.get("bun", false):
		draw_rect(Rect2(ox + 6, oy - 1, 4, 2), hair)
	if look.has("cap"):
		draw_rect(Rect2(ox + 3, oy, 10, 3), Color(look["cap"]))
		draw_rect(Rect2(ox + 3, oy + 3, 11, 1), Color(look["cap"]).darkened(0.3))
	# face
	if facing != "up":
		var ex := 0
		if facing == "left":
			ex = -1
		elif facing == "right":
			ex = 1
		draw_rect(Rect2(ox + 5 + ex, oy + 5, 1, 2), Color("#1a1a1a"))
		draw_rect(Rect2(ox + 10 + ex, oy + 5, 1, 2), Color("#1a1a1a"))
		if look.get("glasses", false):
			draw_rect(Rect2(ox + 4 + ex, oy + 4, 3, 3), Color("#1a1a1a"), false, 1.0)
			draw_rect(Rect2(ox + 9 + ex, oy + 4, 3, 3), Color("#1a1a1a"), false, 1.0)
	else:
		draw_rect(Rect2(ox + 4, oy + 2, 8, 6), hair)
	# held prop
	match look.get("prop", ""):
		"lollipop":
			var lc := Color(look.get("prop_color", "#e0405a"))
			draw_rect(Rect2(ox + 13, oy + 8, 1, 6), Color("#f5f5f5"))
			draw_rect(Rect2(ox + 12, oy + 5, 3, 3), lc)
			draw_rect(Rect2(ox + 13, oy + 6, 1, 1), lc.lightened(0.5))
		"folder":
			draw_rect(Rect2(ox + 12, oy + 12, 4, 6), Color("#7a4e2a"))
		"phone":
			draw_rect(Rect2(ox + 13, oy + 11, 2, 4), Color("#202020"))
