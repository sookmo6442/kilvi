extends CanvasLayer
## 화면 위쪽 정보: 경험치 바, 레벨, 시간, 처치 수, 체력, 대시 쿨타임.

var _xp_bar: ProgressBar
var _hp_bar: ProgressBar
var _dash_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _kills_label: Label
var _contract_label: Label
var _skill_label: Label
var _boss_label: Label
var _boss_bar: ProgressBar
var _boss_marks: ProgressBar
var _skill_bar: ProgressBar
var _message_label: Label
var _message_left := 0.0


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

	_contract_label = Label.new()
	_contract_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_contract_label.position = Vector2(-80, 24)
	_contract_label.custom_minimum_size = Vector2(160, 0)
	_contract_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contract_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	root.add_child(_contract_label)

	_message_label = Label.new()
	_message_label.set_anchors_preset(Control.PRESET_CENTER)
	_message_label.position = Vector2(-120, -70)
	_message_label.custom_minimum_size = Vector2(240, 0)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_color_override("font_color", UiStyle.ORANGE)
	_message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_message_label.add_theme_constant_override("outline_size", 4)
	root.add_child(_message_label)

	_hp_bar = UiStyle.bar(Color(0.85, 0.2, 0.25), 5)
	_hp_bar.position = Vector2(6, 26)
	_hp_bar.size = Vector2(90, 5)
	root.add_child(_hp_bar)

	_dash_bar = UiStyle.bar(UiStyle.ORANGE, 3)
	_dash_bar.position = Vector2(6, 33)
	_dash_bar.size = Vector2(90, 3)
	root.add_child(_dash_bar)

	# 위쪽 가운데: 보스 체력과 표식
	_boss_label = Label.new()
	_boss_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_label.position = Vector2(-150, 40)
	_boss_label.custom_minimum_size = Vector2(300, 0)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_boss_label)
	_boss_bar = UiStyle.bar(Color(0.8, 0.15, 0.2), 6)
	_boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_bar.position = Vector2(-150, 58)
	_boss_bar.size = Vector2(300, 6)
	root.add_child(_boss_bar)
	_boss_marks = UiStyle.bar(Color(1.0, 0.3, 0.2), 3)
	_boss_marks.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_marks.position = Vector2(-150, 66)
	_boss_marks.size = Vector2(300, 3)
	root.add_child(_boss_marks)
	hide_boss()

	# 왼쪽 아래: 특수 스킬
	_skill_label = Label.new()
	_skill_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_skill_label.position = Vector2(6, -30)
	root.add_child(_skill_label)
	_skill_bar = UiStyle.bar(UiStyle.ORANGE, 4)
	_skill_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_skill_bar.position = Vector2(6, -10)
	_skill_bar.size = Vector2(110, 4)
	root.add_child(_skill_bar)
	_skill_label.visible = false
	_skill_bar.visible = false

	var ver := Label.new()
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.position = Vector2(-60, -18)
	ver.custom_minimum_size = Vector2(54, 0)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.modulate = Color(1, 1, 1, 0.4)
	ver.text = "v" + GameData.VERSION
	root.add_child(ver)

	set_time(0.0)
	set_kills(0)
	set_hp(1, 1)
	set_xp(0, 1, 1)


func _process(delta: float) -> void:
	if _message_left > 0.0:
		_message_left -= delta
		_message_label.modulate.a = clampf(_message_left / 0.4, 0.0, 1.0)


var _skill_name := ""
var _skill_key := ""


func setup_skill(skill_name: String, key: String) -> void:
	_skill_name = skill_name
	_skill_key = key
	_skill_label.visible = true
	_skill_bar.visible = true


func set_skill(left: float, total: float) -> void:
	if _skill_name == "":
		return
	_skill_bar.max_value = total
	_skill_bar.value = total - left
	if left > 0.0:
		_skill_label.text = "[%s] %s  %d초" % [_skill_key, _skill_name, ceili(left)]
		_skill_label.modulate = Color(0.7, 0.7, 0.7)
	else:
		_skill_label.text = "[%s] %s  준비" % [_skill_key, _skill_name]
		_skill_label.modulate = Color.WHITE


func set_boss(boss_name: String, hp: float, max_hp: float, marks: int, mark_limit: int, staggered: bool) -> void:
	_boss_label.visible = true
	_boss_bar.visible = true
	_boss_marks.visible = true
	_boss_label.text = "%s%s" % [boss_name, "  [그로기]" if staggered else ""]
	_boss_bar.max_value = max_hp
	_boss_bar.value = hp
	_boss_marks.max_value = mark_limit
	_boss_marks.value = mark_limit if staggered else marks


func hide_boss() -> void:
	_boss_label.visible = false
	_boss_bar.visible = false
	_boss_marks.visible = false


func set_contract(text: String) -> void:
	_contract_label.text = text


func flash_message(text: String) -> void:
	_message_label.text = text
	_message_left = 1.6
	_message_label.modulate.a = 1.0


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
