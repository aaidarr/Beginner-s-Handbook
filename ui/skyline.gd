class_name Skyline
extends Control
## Decorative pixel silhouette of the administration building for menu screens.


func _draw() -> void:
	var u := maxf(4.0, floorf(size.y / 120.0))
	var base := size.y
	var col := Color(1, 1, 1, 0.06)
	var win := Color(1, 0.86, 0.5, 0.14)
	var w := int(size.x / u)
	for i in range(0, w, 14):
		var h := 18 + (i * 7) % 23
		draw_rect(Rect2(i * u, base - h * u, 12 * u, h * u), col)
	var cx := size.x / 2.0
	var bw := 70.0 * u
	draw_rect(Rect2(cx - bw / 2.0, base - 44 * u, bw, 44 * u), Color(1, 1, 1, 0.09))
	draw_rect(Rect2(cx - 12 * u, base - 58 * u, 24 * u, 14 * u), Color(1, 1, 1, 0.09))
	draw_rect(Rect2(cx - 1 * u, base - 70 * u, 2 * u, 12 * u), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(cx + 1 * u, base - 70 * u, 7 * u, 4 * u), Color(0.75, 0.25, 0.2, 0.25))
	for row in 4:
		for c in 10:
			draw_rect(Rect2(cx - bw / 2.0 + (4 + c * 6.6) * u, base - (40 - row * 9) * u, 3 * u, 4 * u), win)
