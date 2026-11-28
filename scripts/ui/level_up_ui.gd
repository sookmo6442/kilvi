extends CanvasLayer
## 레벨업(과 특수 스킬 선택) 3지선다 카드. 열려 있는 동안 게임은 일시정지된다.
## 마우스, 방향키+Enter, 숫자키 1~3, 게임패드 모두 된다.
##
## 카드 구조 (위 → 아래)
##   1. 아이콘 칸: res://art/icons/<id>.png 가 있으면 그 그림을, 없으면 빈 칸을 보여 준다.
##   2. 설명 칸: 이름, 레벨, 설명.

signal chosen(option: Dictionary)

const CARD_SIZE := Vector2(180, 248)
const DESC_FONT_SIZE := 12
const DESC_WIDTH := 148.0 # 카드 폭 - 테두리·여백
const ICON_SIZE := 72
const CARD_RED := Color(0.62, 0.11, 0.12)
const CARD_RED_FOCUS := Color(0.78, 0.16, 0.14)
const INNER := Color(0.1, 0.05, 0.06)

var _cards: Array[Button] = []
var _icons: Array[TextureRect] = []
var _names: Array[Label] = []
var _levels: Array[Label] = []
var _descs: Array[Label] = []
var _options: Array = []
var _title: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", UiStyle.ORANGE)
	box.add_child(_title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	for i in 3:
		row.add_child(_make_card(i))



func _make_card(i: int) -> Button:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_ALL
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("normal", _card_box(CARD_RED, Color(0.3, 0.05, 0.05), 2))
	card.add_theme_stylebox_override("hover", _card_box(CARD_RED_FOCUS, UiStyle.ORANGE, 2))
	card.add_theme_stylebox_override("focus", _card_box(CARD_RED_FOCUS, UiStyle.ORANGE, 3))
	card.add_theme_stylebox_override("pressed", _card_box(CARD_RED_FOCUS, UiStyle.CREAM, 3))
	card.pressed.connect(_on_pressed.bind(i))
	card.focus_entered.connect(_on_card_focus.bind(i, true))
	card.focus_exited.connect(_on_card_focus.bind(i, false))
	card.mouse_entered.connect(func(): card.grab_focus())

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 8
	v.offset_bottom = -8
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)

	# 1. 아이콘 칸 (그림은 나중에 art/icons/에 넣으면 자동으로 뜬다)
	var icon_row := CenterContainer.new()
	icon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon_row)
	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon_box.add_theme_stylebox_override("panel", _card_box(INNER, Color(0.95, 0.75, 0.6, 0.8), 1))
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_row.add_child(icon_box)
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(icon)
	_icons.append(icon)

	# 2. 설명 칸
	var desc_box := PanelContainer.new()
	desc_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_box.add_theme_stylebox_override("panel", _card_box(INNER, Color(0.95, 0.75, 0.6, 0.8), 1))
	desc_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(desc_box)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 3)
	dv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_box.add_child(dv)

	var name_label := _label(UiStyle.CREAM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(name_label)
	_names.append(name_label)

	var level_label := _label(UiStyle.ORANGE)
	level_label.add_theme_font_size_override("font_size", DESC_FONT_SIZE)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(level_label)
	_levels.append(level_label)

	var desc := _label(Color(0.85, 0.82, 0.76))
	desc.add_theme_font_size_override("font_size", DESC_FONT_SIZE)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(desc)
	_descs.append(desc)

	var key := _label(Color(1, 1, 1, 0.45))
	key.add_theme_font_size_override("font_size", DESC_FONT_SIZE)
	key.text = "[%d]" % (i + 1)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(key)

	_cards.append(card)
	return card


func open(options: Array, title: String = "레벨 업!", focus_index: int = 0) -> void:
	_title.text = title
	_options = options
	for i in _cards.size():
		var c := _cards[i]
		if i < options.size():
			var o: Dictionary = options[i]
			c.visible = true
			_names[i].text = o.get("name", o.get("label", ""))
			_levels[i].text = o.get("level", "")
			_levels[i].visible = _levels[i].text != ""
			_levels[i].add_theme_color_override("font_color", GameData.SCHOOLS.get(o.get("school", ""), UiStyle.ORANGE))
			_descs[i].text = _wrap(o.get("desc", ""), _descs[i])
			var path: String = o.get("icon", "")
			_icons[i].texture = load(path) if path != "" and ResourceLoader.exists(path) else null
			c.pivot_offset = CARD_SIZE / 2.0
		else:
			c.visible = false
	# 방향키 좌우로 보이는 카드 사이를 오간다 (양 끝은 반대편으로 넘어간다)
	var n := mini(options.size(), _cards.size())
	for i in n:
		var c := _cards[i]
		c.focus_neighbor_left = c.get_path_to(_cards[(i + n - 1) % n])
		c.focus_neighbor_right = c.get_path_to(_cards[(i + 1) % n])
		c.focus_neighbor_top = NodePath(".")
		c.focus_neighbor_bottom = NodePath(".")
	visible = true
	get_tree().paused = true
	_cards[clampi(focus_index, 0, options.size() - 1)].grab_focus()


func _on_card_focus(i: int, focused: bool) -> void:
	# 고른 카드는 살짝 커진다
	_cards[i].scale = Vector2.ONE * (1.05 if focused else 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx: int = event.keycode - KEY_1
		if idx >= 0 and idx < _options.size():
			get_viewport().set_input_as_handled()
			_on_pressed(idx)


func _on_pressed(i: int) -> void:
	if not visible or i >= _options.size():
		return
	visible = false
	get_tree().paused = false
	chosen.emit(_options[i])


## 한글이 글자 중간에서 끊기지 않게 띄어쓰기 단위로 줄을 바꾼다.
static func _wrap(text: String, label: Label) -> String:
	var font := label.get_theme_font("font")
	var lines := []
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" ", false):
			var trial := word if line == "" else line + " " + word
			if line != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, DESC_FONT_SIZE).x > DESC_WIDTH:
				lines.append(line)
				line = word
			else:
				line = trial
		lines.append(line)
	return "\n".join(lines)


static func _card_box(bg: Color, border: Color, w: int) -> StyleBoxFlat:
	var s := UiStyle.box(bg, border, w)
	s.set_corner_radius_all(3)
	return s


static func _label(color: Color) -> Label:
	var l := Label.new()
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
