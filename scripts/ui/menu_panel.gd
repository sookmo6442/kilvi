extends CanvasLayer
## 일시정지·게임 오버·클리어 화면에 같이 쓰는 패널.

signal button_pressed(id: String)

var _title: Label
var _body: Label
var _buttons_box: VBoxContainer


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

	var panel := PanelContainer.new()
	var style := UiStyle.box(UiStyle.DARK, UiStyle.CREAM, 1)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

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
func open(title: String, body: String, buttons: Array) -> void:
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
