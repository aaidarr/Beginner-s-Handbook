class_name Fonts
## Lazily loaded shared fonts (all OFL, see assets/fonts/OFL.txt).

static var _regular: Font
static var _bold: Font
static var _pixel: Font


static func regular() -> Font:
	if _regular == null:
		_regular = _load("res://assets/fonts/PT_Sans-Web-Regular.ttf", true)
	return _regular


static func bold() -> Font:
	if _bold == null:
		_bold = _load("res://assets/fonts/PT_Sans-Web-Bold.ttf", true)
	return _bold


static func pixel() -> Font:
	if _pixel == null:
		_pixel = _load("res://assets/fonts/PressStart2P-Regular.ttf", false)
	return _pixel


static func _load(path: String, smooth: bool) -> Font:
	var f: FontFile = load(path)
	if f == null:
		return ThemeDB.fallback_font
	if not smooth:
		f = f.duplicate()
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return f
