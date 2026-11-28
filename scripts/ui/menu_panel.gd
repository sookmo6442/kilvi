extends CanvasLayer
## 일시정지·게임 오버·클리어 화면에 같이 쓰는 패널.

signal button_pressed(id: String)

var _title: Label
var _body: Label
var _buttons_box: VBoxContainer
var _left: PanelContainer
var _right: PanelContainer
var _left_box: VBoxContainer
var _right_box: VBoxContainer

const IconTile := preload("res://scripts/ui/icon_tile.gd")
const SIDE_WIDTH := 168
const SIDE_HEIGHT := 260
const TILES_PER_ROW := 4


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# [왼쪽 상태] [가운데 메뉴] [오른쪽 기술] — 양옆은 일시정지 때만 보인다
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	center.add_child(row)

	_left = _side_panel()
	_left_box = VBoxContainer.new()
	_left_box.add_theme_constant_override("separation", 4)
	_left.add_child(_left_box)
	row.add_child(_left)

	var panel := PanelContainer.new()
	var style := UiStyle.box(UiStyle.DARK, UiStyle.CREAM, 1)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)

	_right = _side_panel()
	_right_box = VBoxContainer.new()
	_right_box.add_theme_constant_override("separation", 4)
	_right.add_child(_right_box)
	row.add_child(_right)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(220, 0)
	panel.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", UiStyle.ORANGE)
	box.add_child(_title)

	_body = Label.new()
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_body)

	_buttons_box = VBoxContainer.new()
	_buttons_box.add_theme_constant_override("separation", 6)
	box.add_child(_buttons_box)


## buttons: [[id, 글자], ...]
## left: 왼쪽 상태 표. {"title": 글, "rows": [[이름, 값], [] (빈 줄), ...]}. 비어 있으면 숨긴다.
## right: 오른쪽 아이콘 목록. [{"title": 글, "tiles": [{"id", "name", "corner", "border"}]}, ...]
##        비어 있으면 숨긴다.
func open(title: String, body: String, buttons: Array, left: Dictionary = {}, right: Array = []) -> void:
	_left.visible = not left.is_empty()
	_right.visible = not right.is_empty()
	_fill_left(left)
	_fill_right(right)
	_title.text = title
	_body.text = body
	_body.visible = body != ""
	for c in _buttons_box.get_children():
		c.queue_free()
	var first: Button = null
	for pair in buttons:
		var b := UiStyle.button(pair[1])
		b.pressed.connect(func(): button_pressed.emit(pair[0]))
		_buttons_box.add_child(b)
		if first == null:
			first = b
	visible = true
	get_tree().paused = true
	if first:
		first.grab_focus.call_deferred()


func close() -> void:
	visible = false
	get_tree().paused = false


func _side_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var style := UiStyle.box(UiStyle.DARK, Color(UiStyle.CREAM, 0.5), 1)
	style.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", style)
	p.custom_minimum_size = Vector2(SIDE_WIDTH, SIDE_HEIGHT)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.visible = false
	return p


func _small_label(text: String, color: Color = UiStyle.CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", color)
	return l


func _fill_left(data: Dictionary) -> void:
	for c in _left_box.get_children():
		c.queue_free()
	if data.is_empty():
		return
	_left_box.add_child(_small_label(data.title, UiStyle.ORANGE))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("v_separation", 2)
	_left_box.add_child(grid)
	for r in data.rows:
		var a := _small_label(r[0] if r.size() > 0 else "")
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(a)
		var v := _small_label(r[1] if r.size() > 1 else "")
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(v)


func _fill_right(sections: Array) -> void:
	for c in _right_box.get_children():
		c.queue_free()
	for i in sections.size():
		var sec: Dictionary = sections[i]
		if i > 0:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(0, 6)
			_right_box.add_child(gap)
		var head := _small_label(sec.title, UiStyle.ORANGE)
		_right_box.add_child(head)
		var grid := GridContainer.new()
		grid.columns = TILES_PER_ROW
		grid.add_theme_constant_override("h_separation", 5)
		grid.add_theme_constant_override("v_separation", 5)
		_right_box.add_child(grid)
		for t in sec.tiles:
			var tile := IconTile.new()
			tile.setup(t.id, t.name, t.corner, t.border)
			grid.add_child(tile)
