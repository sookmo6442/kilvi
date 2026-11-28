extends Control
## 일시정지 화면 오른쪽의 기술·패시브·특수 스킬 아이콘 한 칸.
## res://art/icons/<id>.png 가 있으면 그 그림을, 없으면 이름 첫 글자를 보여 주고,
## 칸 왼쪽 아래에 레벨(Lv.3, MAX, 진화, Q 등)을 적는다.

const SIZE := 32.0
const BG := Color(0.1, 0.05, 0.06)

var _icon: Texture2D
var _initial := ""
var _corner := ""
var _border := Color(0.95, 0.75, 0.6, 0.8)


func setup(id: String, display_name: String, corner: String, border: Color) -> void:
	var path := "res://art/icons/%s.png" % id
	_icon = load(path) if ResourceLoader.exists(path) else null
	_initial = display_name.substr(0, 1)
	_corner = corner
	_border = border
	tooltip_text = display_name
	custom_minimum_size = Vector2(SIZE, SIZE)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(SIZE, SIZE))
	var font := get_theme_font("font", "Label")
	draw_rect(r, BG)
	if _icon:
		draw_texture_rect(_icon, r.grow(-2), false)
	else:
		var fs := 12
		var s := font.get_string_size(_initial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var p := Vector2(roundf((SIZE - s.x) / 2.0), 15)
		draw_string(font, p, _initial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(UiStyle.CREAM, 0.55))
	draw_rect(r, _border, false, 1.0)
	if _corner != "":
		# 왼쪽 아래 레벨 글자 (검은 외곽선으로 그림 위에서도 읽히게)
		var p2 := Vector2(2, SIZE - 3)
		draw_string_outline(font, p2, _corner, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
		draw_string(font, p2, _corner, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.ORANGE)
