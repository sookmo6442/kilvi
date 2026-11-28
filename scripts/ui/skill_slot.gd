extends Control
## 왼쪽 아래 특수 스킬 아이콘 칸.
## res://art/icons/<스킬 id>.png 가 있으면 그 그림을, 없으면 스킬 이름 첫 글자를 보여 준다.
## 쿨타임 동안은 시계 방향으로 걷히는 어두운 덮개와 남은 초가 뜨고, 준비되면 테두리가 한 번 번쩍인다.

const SLOT := 30.0
const BG := Color(0.1, 0.05, 0.06, 0.85)
const BORDER := Color(0.95, 0.75, 0.6, 0.8)
const SHADE := Color(0, 0, 0, 0.65)

var _icon: Texture2D
var _initial := ""
var _key := ""
var _left := 0.0
var _total := 1.0
var _flash := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(SLOT, SLOT)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(id: String, skill_name: String, key: String) -> void:
	var path := "res://art/icons/%s.png" % id
	_icon = load(path) if ResourceLoader.exists(path) else null
	_initial = skill_name.substr(0, 1)
	_key = key
	queue_redraw()


func set_cooldown(left: float, total: float) -> void:
	if _left > 0.0 and left <= 0.0:
		_flash = 0.35
	_left = maxf(left, 0.0)
	_total = maxf(total, 0.01)


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(SLOT, SLOT))
	var font := get_theme_font("font", "Label")
	draw_rect(r, BG)
	if _icon:
		draw_texture_rect(_icon, r.grow(-2), false)
	elif _left <= 0.0:
		_text_center(font, _initial, r.get_center() + Vector2(0, 1), 16, UiStyle.CREAM)

	if _left > 0.0:
		# 시계 방향으로 걷히는 덮개 (12시에서 시작)
		var frac := _left / _total
		var c := r.get_center()
		var pts := PackedVector2Array([c])
		var steps := 32
		var start := -PI / 2.0 + TAU * (1.0 - frac)
		for i in steps + 1:
			var a := lerpf(start, -PI / 2.0 + TAU, float(i) / steps)
			pts.append(c + _to_square(Vector2(cos(a), sin(a))) * SLOT / 2.0)
		if pts.size() >= 3:
			draw_colored_polygon(pts, SHADE)
		_text_center(font, str(ceili(_left)), c + Vector2(0, 1), 12, Color.WHITE)
		draw_rect(r, BORDER.darkened(0.4), false, 1.0)
	else:
		var col := UiStyle.ORANGE.lerp(Color.WHITE, _flash / 0.35)
		draw_rect(r, col, false, 1.0 + (2.0 if _flash > 0.0 else 1.0))

	# 키 표시: 오른쪽 아래 모서리의 작은 딱지
	if _key != "":
		var ks := font.get_string_size(_key, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		var badge := Rect2(SLOT - ks.x - 3, SLOT - 9, ks.x + 4, 10)
		draw_rect(badge, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(badge.position.x + 2, SLOT - 1), _key, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiStyle.ORANGE)


## 원 위의 방향을 정사각형 테두리까지 늘린다 (덮개가 칸을 꽉 채우게).
static func _to_square(d: Vector2) -> Vector2:
	return d / maxf(absf(d.x), absf(d.y))


func _text_center(font: Font, text: String, center: Vector2, fs: int, col: Color) -> void:
	var s := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var p := center + Vector2(-s.x / 2.0, s.y / 2.0 - font.get_descent(fs))
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color.BLACK)
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
