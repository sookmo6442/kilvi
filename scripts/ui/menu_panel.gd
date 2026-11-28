extends CanvasLayer
## 일시정지·게임 오버·클리어 화면에 같이 쓰는 패널.

signal button_pressed(id: String)

var _title: Label
var _body: Label
var _buttons_box: VBoxContainer
var _left: PanelContainer
var _right: PanelContainer
var _left_text: RichTextLabel
var _right_text: RichTextLabel

const SIDE_WIDTH := 168


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
	_left_text = _left.get_child(0)
	row.add_child(_left)

	var panel := PanelContainer.new()
	var style := UiStyle.box(UiStyle.DARK, UiStyle.CREAM, 1)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(panel)

	_right = _side_panel()
	_right_text = _right.get_child(0)
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
## left/right: 양옆 패널에 넣을 BBCode 글. 비어 있으면 그 패널은 숨긴다.
func open(title: String, body: String, buttons: Array, left: String = "", right: String = "") -> void:
	_left.visible = left != ""
	_right.visible = right != ""
	_left_text.text = left
	_right_text.text = right
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
	p.custom_minimum_size = Vector2(SIDE_WIDTH, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.visible = false
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.custom_minimum_size = Vector2(SIDE_WIDTH - 16, 0)
	t.add_theme_font_size_override("normal_font_size", 12)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(t)
	return p
