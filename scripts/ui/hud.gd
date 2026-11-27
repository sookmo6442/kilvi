extends CanvasLayer
## 화면 위쪽 정보: 경험치 바, 레벨, 시간, 처치 수, 체력, 대시 쿨타임.

var _xp_bar: ProgressBar
var _hp_bar: ProgressBar
var _dash_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _kills_label: Label


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_xp_bar = UiStyle.bar(Color(0.35, 0.7, 1.0), 6)
	_xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root.add_child(_xp_bar)

	_level_label = Label.new()
	_level_label.position = Vector2(6, 8)
	root.add_child(_level_label)

	_time_label = Label.new()
	_time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_time_label.position = Vector2(-30, 8)
	_time_label.custom_minimum_size = Vector2(60, 0)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_time_label)

	_kills_label = Label.new()
	_kills_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_kills_label.position = Vector2(-96, 8)
	_kills_label.custom_minimum_size = Vector2(90, 0)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_kills_label)

	_hp_bar = UiStyle.bar(Color(0.85, 0.2, 0.25), 5)
	_hp_bar.position = Vector2(6, 26)
	_hp_bar.size = Vector2(90, 5)
	root.add_child(_hp_bar)

	_dash_bar = UiStyle.bar(UiStyle.ORANGE, 3)
	_dash_bar.position = Vector2(6, 33)
	_dash_bar.size = Vector2(90, 3)
	root.add_child(_dash_bar)

	set_time(0.0)
	set_kills(0)
	set_hp(1, 1)
	set_xp(0, 1, 1)


func set_xp(xp: int, needed: int, level: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = xp
	_level_label.text = "Lv %d" % level


func set_hp(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp


func set_dash(left: float, total: float) -> void:
	_dash_bar.max_value = total
	_dash_bar.value = total - left


func set_time(t: float) -> void:
	_time_label.text = "%02d:%02d" % [int(t) / 60, int(t) % 60]


func set_kills(k: int) -> void:
	_kills_label.text = "처치 %d" % k
