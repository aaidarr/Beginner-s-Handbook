class_name Ui
## Theme + small builders so every screen looks and behaves the same.

const BASE_FONT := 22
const MIN_TAP := 56

const NORMAL := {
	"bg": "#1e2230", "paper": "#f3e9d2", "card": "#fbf6e9", "ink": "#2b2118", "muted": "#6b5a48",
	"accent": "#2f5d8a", "accent_ink": "#ffffff", "accent_soft": "#d6e3f0", "border": "#7a5a3a",
	"good": "#2e7d32", "good_soft": "#dcefd9", "bad": "#b23a2e", "bad_soft": "#f6dcd8",
	"warn": "#a86a10", "warn_soft": "#f5e6c8", "dim": "#00000099",
}
const CONTRAST := {
	"bg": "#000000", "paper": "#ffffff", "card": "#ffffff", "ink": "#000000", "muted": "#222222",
	"accent": "#0033a0", "accent_ink": "#ffffff", "accent_soft": "#cfe0ff", "border": "#000000",
	"good": "#00661a", "good_soft": "#d8f5dd", "bad": "#a00000", "bad_soft": "#ffd9d9",
	"warn": "#7a4a00", "warn_soft": "#ffe9c2", "dim": "#000000cc",
}

static var theme: Theme


static func c(key: String) -> Color:
	var pal: Dictionary = CONTRAST if GameState.settings.get("high_contrast", false) else NORMAL
	return Color(pal.get(key, "#ff00ff"))


static func fs(px: int) -> int:
	return int(round(px * float(GameState.settings.get("text_scale", 1.0))))


static func box(bg: Color, border := Color.TRANSPARENT, bw := 0, radius := 8, pad := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad)
	return sb


static func build_theme() -> Theme:
	if theme == null:
		theme = Theme.new()
	var t := theme
	t.default_font = Fonts.regular()
	t.default_font_size = fs(BASE_FONT)
	var ink := c("ink")
	for type in ["Label", "Button", "LineEdit", "CheckBox", "CheckButton", "OptionButton", "RichTextLabel"]:
		t.set_color("font_color", type, ink)
	t.set_color("default_color", "RichTextLabel", ink)
	t.set_font("bold_font", "RichTextLabel", Fonts.bold())
	t.set_font_size("bold_font_size", "RichTextLabel", fs(BASE_FONT))
	t.set_font_size("normal_font_size", "RichTextLabel", fs(BASE_FONT))
	# buttons
	t.set_stylebox("normal", "Button", box(c("card"), c("border"), 2, 10, 12))
	t.set_stylebox("hover", "Button", box(c("accent_soft"), c("accent"), 2, 10, 12))
	t.set_stylebox("pressed", "Button", box(c("accent_soft"), c("accent"), 3, 10, 12))
	t.set_stylebox("focus", "Button", box(Color.TRANSPARENT, c("accent"), 3, 10, 12))
	t.set_stylebox("disabled", "Button", box(c("card").darkened(0.08), c("muted"), 1, 10, 12))
	t.set_color("font_hover_color", "Button", ink)
	t.set_color("font_pressed_color", "Button", ink)
	t.set_color("font_focus_color", "Button", ink)
	t.set_color("font_disabled_color", "Button", c("muted"))
	t.set_type_variation("Accent", "Button")
	t.set_stylebox("normal", "Accent", box(c("accent"), c("accent").darkened(0.3), 2, 10, 12))
	t.set_stylebox("hover", "Accent", box(c("accent").lightened(0.1), c("accent").darkened(0.3), 2, 10, 12))
	t.set_stylebox("pressed", "Accent", box(c("accent").darkened(0.15), c("accent").darkened(0.3), 2, 10, 12))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(k, "Accent", c("accent_ink"))
	t.set_type_variation("Flat", "Button")
	t.set_stylebox("normal", "Flat", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 8, 8))
	t.set_stylebox("hover", "Flat", box(c("accent_soft"), Color.TRANSPARENT, 0, 8, 8))
	t.set_stylebox("pressed", "Flat", box(c("accent_soft"), Color.TRANSPARENT, 0, 8, 8))
	t.set_type_variation("Tab", "Button")
	t.set_stylebox("normal", "Tab", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 8, 10))
	t.set_stylebox("hover", "Tab", box(c("accent_soft"), Color.TRANSPARENT, 0, 8, 10))
	t.set_stylebox("pressed", "Tab", box(c("accent"), Color.TRANSPARENT, 0, 8, 10))
	t.set_color("font_pressed_color", "Tab", c("accent_ink"))
	t.set_color("font_hover_pressed_color", "Tab", c("accent_ink"))
	t.set_constant("align_to_largest_stylebox", "Tab", 1)
	# labels
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", Fonts.bold())
	t.set_font_size("font_size", "Title", fs(34))
	t.set_type_variation("Header", "Label")
	t.set_font("font", "Header", Fonts.bold())
	t.set_font_size("font_size", "Header", fs(26))
	t.set_type_variation("Strong", "Label")
	t.set_font("font", "Strong", Fonts.bold())
	t.set_type_variation("Small", "Label")
	t.set_font_size("font_size", "Small", fs(18))
	t.set_color("font_color", "Small", c("muted"))
	t.set_type_variation("Pixel", "Label")
	t.set_font("font", "Pixel", Fonts.pixel())
	t.set_font_size("font_size", "Pixel", 16 if fs(16) < 24 else 24)
	t.set_type_variation("Light", "Label")
	t.set_color("font_color", "Light", Color("#f3e9d2"))
	# panels
	t.set_stylebox("panel", "PanelContainer", box(c("paper"), c("border"), 3, 12, 16))
	t.set_type_variation("Card", "PanelContainer")
	t.set_stylebox("panel", "Card", box(c("card"), c("border").lightened(0.3), 2, 10, 14))
	t.set_type_variation("Soft", "PanelContainer")
	t.set_stylebox("panel", "Soft", box(c("accent_soft"), Color.TRANSPARENT, 0, 10, 12))
	t.set_type_variation("Good", "PanelContainer")
	t.set_stylebox("panel", "Good", box(c("good_soft"), c("good"), 2, 10, 12))
	t.set_type_variation("Bad", "PanelContainer")
	t.set_stylebox("panel", "Bad", box(c("bad_soft"), c("bad"), 2, 10, 12))
	t.set_type_variation("Warn", "PanelContainer")
	t.set_stylebox("panel", "Warn", box(c("warn_soft"), c("warn"), 2, 10, 12))
	# inputs
	t.set_stylebox("normal", "LineEdit", box(Color.WHITE, c("border"), 2, 10, 12))
	t.set_stylebox("focus", "LineEdit", box(Color.WHITE, c("accent"), 3, 10, 12))
	t.set_color("font_placeholder_color", "LineEdit", c("muted"))
	t.set_stylebox("panel", "PopupMenu", box(c("card"), c("border"), 2, 8, 8))
	t.set_stylebox("normal", "OptionButton", box(c("card"), c("border"), 2, 10, 12))
	t.set_stylebox("grabber_area", "HSlider", box(c("accent"), Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("slider", "HSlider", box(c("accent_soft"), Color.TRANSPARENT, 0, 4, 4))
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 10)
	t.set_stylebox("background", "ProgressBar", box(c("accent_soft"), Color.TRANSPARENT, 0, 6, 0))
	t.set_stylebox("fill", "ProgressBar", box(c("accent"), Color.TRANSPARENT, 0, 6, 0))
	t.set_color("font_color", "ProgressBar", c("ink"))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	return t


# --- builders --------------------------------------------------------------

static func label(text: String, variation := "", wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 40
	return l


static func button(text: String, cb: Callable, variation := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(MIN_TAP, MIN_TAP)
	if variation != "":
		b.theme_type_variation = variation
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


static func wrap_button(text: String, cb: Callable, variation := "") -> Button:
	var b := button(text, cb, variation)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


static func vbox(sep := 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func panel(variation := "") -> PanelContainer:
	var p := PanelContainer.new()
	if variation != "":
		p.theme_type_variation = variation
	return p


static func spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


static func scroll(content: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(content)
	return s


static func progress(value: float, show_pct := true) -> ProgressBar:
	var p := ProgressBar.new()
	p.min_value = 0
	p.max_value = 100
	p.value = value * 100.0
	p.show_percentage = show_pct
	p.custom_minimum_size.y = 26
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


static func dim() -> ColorRect:
	var r := ColorRect.new()
	r.color = c("dim")
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


static func clear(n: Node) -> void:
	for ch in n.get_children():
		n.remove_child(ch)
		ch.queue_free()


## Safe-area margins in viewport coordinates (notches, rounded corners).
static func safe_margins(vp: Viewport) -> Vector4:
	var screen := DisplayServer.screen_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if screen.x <= 0 or safe.size.x <= 0 or not OS.has_feature("mobile"):
		return Vector4(16, 16, 16, 16)
	var k := vp.get_visible_rect().size.x / float(screen.x)
	return Vector4(
		maxf(16, safe.position.x * k), maxf(16, safe.position.y * k),
		maxf(16, (screen.x - safe.end.x) * k), maxf(16, (screen.y - safe.end.y) * k))
