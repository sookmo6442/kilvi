extends CanvasLayer
## 레벨업 3지선다. 열려 있는 동안 게임은 일시정지된다.
## 마우스, 방향키+Enter, 숫자키 1~3, 게임패드 모두 된다.

signal chosen(option: Dictionary)

var _buttons: Array[Button] = []
var _options: Array = []


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
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)

	var title := Label.new()
	title.text = "레벨 업!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UiStyle.ORANGE)
	box.add_child(title)

	for i in 3:
		var b := UiStyle.button("")
		b.custom_minimum_size = Vector2(300, 52)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_pressed.bind(i))
		box.add_child(b)
		_buttons.append(b)


func open(options: Array) -> void:
	_options = options
	for i in _buttons.size():
		var b := _buttons[i]
		if i < options.size():
			b.visible = true
			b.text = "%d. %s" % [i + 1, options[i].label]
		else:
			b.visible = false
	visible = true
	get_tree().paused = true
	_buttons[0].grab_focus()


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
