class_name UiStyle
extends RefCounted
## UI 색과 상자 모양. 흑백 + 주황 강조.

const ORANGE := Color(1.0, 0.62, 0.1)
const CREAM := Color(0.92, 0.89, 0.82)
const DARK := Color(0.07, 0.07, 0.08)


static func box(bg: Color, border: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_content_margin_all(6)
	return s


static func bar(fill: Color, height: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_stylebox_override("background", box(Color(0, 0, 0, 0.6)))
	var f := box(fill)
	f.set_content_margin_all(0)
	b.add_theme_stylebox_override("fill", f)
	return b


static func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", box(DARK, CREAM, 1))
	b.add_theme_stylebox_override("hover", box(Color(0.18, 0.15, 0.1), ORANGE, 1))
	b.add_theme_stylebox_override("focus", box(Color(0.18, 0.15, 0.1), ORANGE, 2))
	b.add_theme_stylebox_override("pressed", box(Color(0.3, 0.2, 0.05), ORANGE, 2))
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", ORANGE)
	b.add_theme_color_override("font_focus_color", ORANGE)
	return b
