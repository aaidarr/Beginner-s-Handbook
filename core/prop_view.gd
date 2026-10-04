class_name PropView
extends Node2D
## Draws a world object. Origin = bottom-centre (for y-sorting).
## Uses assets/props/<kind>.png when present, otherwise a placeholder.

var kind := ""
var size := Vector2(16, 16)
var _tex: Texture2D


func setup(prop_kind: String, px_size: Vector2) -> void:
	kind = prop_kind
	size = px_size
	var path := "res://assets/props/%s.png" % kind
	if ResourceLoader.exists(path):
		_tex = load(path)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-size.x / 2.0, -size.y, size.x, size.y)
	if _tex:
		draw_texture(_tex, Vector2(-_tex.get_width() / 2.0, -_tex.get_height()))
		return
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	match kind:
		"desk", "reception":
			var top := Color("#8b5a2b") if kind == "desk" else Color("#6d4c3d")
			draw_rect(Rect2(x, y + h * 0.35, w, h * 0.65), top.darkened(0.25))
			draw_rect(Rect2(x, y, w, h * 0.45), top)
			draw_rect(Rect2(x + 1, y + 1, w - 2, 1), top.lightened(0.25))
		"computer":
			draw_rect(Rect2(x + 2, y, w - 4, h - 4), Color("#2a2f3a"))
			draw_rect(Rect2(x + 3, y + 1, w - 6, h - 7), Color("#5fa8d3"))
			draw_rect(Rect2(x + w / 2 - 1, y + h - 4, 2, 3), Color("#2a2f3a"))
			draw_rect(Rect2(x + 1, y + h - 1, w - 2, 1), Color("#2a2f3a"))
		"paper":
			draw_rect(Rect2(x + 2, y + 4, w - 4, h - 6), Color("#f4f1e8"))
			draw_rect(Rect2(x + 4, y + 6, w - 9, 1), Color("#9a9a9a"))
			draw_rect(Rect2(x + 4, y + 8, w - 7, 1), Color("#9a9a9a"))
			draw_rect(Rect2(x + w - 5, y + 4, 3, 3), Color("#d8d2c0"))
		"burger":
			draw_rect(Rect2(x + 1, y + h - 4, w - 2, 2), Color("#c58b3c"))
			draw_rect(Rect2(x + 1, y + h - 6, w - 2, 2), Color("#5a2e1a"))
			draw_rect(Rect2(x + 1, y + h - 7, w - 2, 1), Color("#6fb03a"))
			draw_rect(Rect2(x + 1, y + h - 10, w - 2, 3), Color("#d9a04a"))
			draw_rect(Rect2(x + w - 4, y + h - 10, 3, 5), Color(0, 0, 0, 0))
			draw_circle(Vector2(x + w - 2, y + h - 7), 2.5, Color("#e8dcc0"))
		"stand", "plan", "board":
			var frame := Color("#5a3a1e")
			var face: Color = {"stand": Color("#e8e0c8"), "plan": Color("#dce8d0"), "board": Color("#b8875a")}[kind]
			draw_rect(Rect2(x, y, w, h - 4), frame)
			draw_rect(Rect2(x + 2, y + 2, w - 4, h - 8), face)
			if kind == "stand":
				draw_rect(Rect2(x + w / 2 - 3, y + 4, 6, 3), Color("#2f5d8a"))
				for i in 3:
					draw_rect(Rect2(x + 4 + i * (w - 8) / 3.0, y + 10, (w - 8) / 3.0 - 2, 3), Color("#7a9cc0"))
			elif kind == "plan":
				draw_rect(Rect2(x + 4, y + 4, w - 8, h - 12), Color("#a8c098"), false, 1.0)
				draw_rect(Rect2(x + w / 2, y + 4, 1, h - 12), Color("#a8c098"))
			else:
				for i in 4:
					draw_rect(Rect2(x + 3 + (i % 2) * (w / 2 - 2), y + 3 + (i / 2) * 6, w / 2 - 4, 5), Color("#f4f1e8"))
			draw_rect(Rect2(x + 2, y + h - 4, 2, 4), frame)
			draw_rect(Rect2(x + w - 4, y + h - 4, 2, 4), frame)
		"turnstile":
			draw_rect(Rect2(x, y + h - 10, 4, 10), Color("#7d8590"))
			draw_rect(Rect2(x + w - 4, y + h - 10, 4, 10), Color("#7d8590"))
			draw_rect(Rect2(x + 4, y + h - 7, w - 8, 2), Color("#b0b8c0"))
			draw_rect(Rect2(x + 1, y + h - 9, 2, 2), Color("#e04040"))
		"turnstile_open":
			draw_rect(Rect2(x, y + h - 10, 4, 10), Color("#7d8590"))
			draw_rect(Rect2(x + w - 4, y + h - 10, 4, 10), Color("#7d8590"))
			draw_rect(Rect2(x + 1, y + h - 9, 2, 2), Color("#40c060"))
		"cooler":
			draw_rect(Rect2(x + 2, y + 6, w - 4, h - 6), Color("#e0e4e8"))
			draw_rect(Rect2(x + 3, y, w - 6, 7), Color("#7fc4e8"))
		"plant":
			draw_rect(Rect2(x + 4, y + h - 6, w - 8, 6), Color("#a0522d"))
			draw_circle(Vector2(0, y + h - 9), 5, Color("#3d8b3d"))
			draw_circle(Vector2(-3, y + h - 12), 3, Color("#4fa04f"))
			draw_circle(Vector2(3, y + h - 13), 3, Color("#4fa04f"))
		"cabinet":
			draw_rect(r, Color("#7a5a3a"))
			draw_rect(Rect2(x + 1, y + 1, w / 2 - 1, h - 2), Color("#8b6a48"))
			draw_rect(Rect2(x + w / 2 + 1, y + 1, w / 2 - 2, h - 2), Color("#8b6a48"))
		"printer":
			draw_rect(Rect2(x, y + 4, w, h - 4), Color("#d0d0d0"))
			draw_rect(Rect2(x + 2, y, w - 4, 5), Color("#f4f1e8"))
			draw_rect(Rect2(x + w - 4, y + 6, 2, 2), Color("#40c060"))
		"sofa":
			draw_rect(Rect2(x, y + 3, w, h - 3), Color("#4a6a8a"))
			draw_rect(Rect2(x, y, w, 5), Color("#3a5a7a"))
		"window":
			draw_rect(r, Color("#8ab8d8"))
			draw_rect(Rect2(x, y, w, 1), Color("#f0f0f0"))
			draw_rect(Rect2(x + w / 2, y, 1, h), Color("#f0f0f0"))
		_:
			draw_rect(r, Color("#c0a080"))
			draw_rect(r, Color("#5a3a1e"), false, 1.0)
