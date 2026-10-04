class_name Portrait
extends Control
## Large dialogue portrait. Uses assets/portraits/<id>_<emotion>.png or <id>.png
## (64x64, shown ×N), otherwise draws a placeholder face from the NPC look.

var npc_id := ""
var emotion := "neutral"
var look: Dictionary = {}
var _tex: Texture2D


func show_for(id: String, emo: String) -> void:
	npc_id = id
	emotion = emo
	if id == "hero":
		var looks: Array = Content.org.get("hero_looks", [{}])
		look = looks[clampi(GameState.player_look, 0, looks.size() - 1)]
	else:
		look = Content.npc(id).get("look", {})
	_tex = null
	for p in ["res://assets/portraits/%s_%s.png" % [id, emo], "res://assets/portraits/%s.png" % id]:
		if ResourceLoader.exists(p):
			_tex = load(p)
			break
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var u := s / 32.0
	var o := (size - Vector2(s, s)) / 2.0
	draw_rect(Rect2(o, Vector2(s, s)), Ui.c("accent_soft"))
	if _tex:
		draw_texture_rect(_tex, Rect2(o, Vector2(s, s)), false)
		draw_rect(Rect2(o, Vector2(s, s)), Ui.c("border"), false, 3.0)
		return
	var px := func(x: float, y: float, w: float, h: float, col: Color) -> void:
		draw_rect(Rect2(o + Vector2(x, y) * u, Vector2(w, h) * u), col)
	var skin := Color(look.get("skin", "#f0c8a0"))
	var hair := Color(look.get("hair", "#3a2a1a"))
	var body := Color(look.get("body", "#3b6ea5"))
	px.call(4, 25, 24, 7, body)
	px.call(13, 22, 6, 4, skin.darkened(0.1))
	if look.has("tie"):
		px.call(15, 25, 2, 7, Color(look["tie"]))
	if look.get("long_hair", false):
		px.call(6, 8, 4, 18, hair)
		px.call(22, 8, 4, 18, hair)
	px.call(8, 6, 16, 17, skin)
	px.call(8, 4, 16, 5, hair)
	px.call(7, 6, 2, 6, hair)
	px.call(23, 6, 2, 6, hair)
	if look.get("bun", false):
		px.call(12, 1, 8, 4, hair)
	if look.has("cap"):
		px.call(6, 2, 20, 5, Color(look["cap"]))
		px.call(6, 7, 22, 2, Color(look["cap"]).darkened(0.3))
	var ink := Color("#1a1a1a")
	match emotion:
		"happy":
			px.call(11, 12, 3, 1, ink)
			px.call(18, 12, 3, 1, ink)
			px.call(12, 18, 8, 1, ink)
			px.call(11, 17, 1, 1, ink)
			px.call(20, 17, 1, 1, ink)
		"strict":
			px.call(10, 10, 4, 1, ink)
			px.call(18, 10, 4, 1, ink)
			px.call(11, 12, 2, 2, ink)
			px.call(19, 12, 2, 2, ink)
			px.call(13, 18, 6, 1, ink)
		"surprised":
			px.call(11, 11, 2, 3, ink)
			px.call(19, 11, 2, 3, ink)
			px.call(14, 17, 4, 3, ink)
		_:
			px.call(11, 12, 2, 2, ink)
			px.call(19, 12, 2, 2, ink)
			px.call(13, 18, 6, 1, ink)
	if look.get("glasses", false):
		draw_rect(Rect2(o + Vector2(9.5, 10.5) * u, Vector2(5, 4) * u), ink, false, maxf(1.0, u * 0.6))
		draw_rect(Rect2(o + Vector2(17.5, 10.5) * u, Vector2(5, 4) * u), ink, false, maxf(1.0, u * 0.6))
	if look.get("prop", "") == "lollipop":
		px.call(25, 18, 1, 8, Color("#f5f5f5"))
		px.call(23, 14, 5, 5, Color(look.get("prop_color", "#e0405a")))
	draw_rect(Rect2(o, Vector2(s, s)), Ui.c("border"), false, 3.0)
