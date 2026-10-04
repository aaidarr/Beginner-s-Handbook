class_name ProgressRing
extends Control

var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 5.0
	draw_arc(c, r, 0, TAU, 48, Ui.c("accent_soft"), 8.0, true)
	if value > 0.0:
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * value, 48, Ui.c("accent"), 8.0, true)
	var f := Fonts.bold()
	var t := "%d" % roundi(value * 100)
	var fsz := 18
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz)
	draw_string(f, c + Vector2(-w.x / 2.0, fsz * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Ui.c("ink"))
