extends Node2D
## 게임 한 판을 관리한다: 스폰, 레벨업, 게임 오버, 일시정지.

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const GemScript := preload("res://scripts/xp_gem.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const LevelUpScript := preload("res://scripts/ui/level_up_ui.gd")
const MenuScript := preload("res://scripts/ui/menu_panel.gd")
const BackgroundScript := preload("res://scripts/background.gd")
const PostFxScript := preload("res://scripts/ui/post_fx.gd")
const SlashScript := preload("res://scripts/effects/slash.gd")
const ChestScript := preload("res://scripts/treasure_chest.gd")
const BossScript := preload("res://scripts/boss.gd")
const SEP_CELL := 16.0
const RING_WAVES := [[90.0, "wisp"], [300.0, "bat"], [540.0, "fox"], [840.0, "imp"], [1080.0, "ninja"]]

const BASE_SIZE := Vector2i(640, 360) # 게임 화면 해상도 (project.godot과 같게)
const CONTRACT_FIRST := 45.0 # 첫 표적 의뢰 시각(초)
const CONTRACT_INTERVAL := 60.0
const CONTRACT_TIME := 30.0 # 표적을 잡아야 하는 제한 시간

## 다시 하기를 눌러도 지난번 고른 스킬에 커서를 둔다
static var last_skill := "flash"

var world: Node2D
var player: Player
var hud: CanvasLayer
var level_up_ui: CanvasLayer
var menu: CanvasLayer
var post_fx: CanvasLayer

var time := 0.0
var kills := 0
var _spawn_acc := 0.0
var _ring_index := 0
var _boss_index := 0
var _boss: Boss = null
var _finished := false
var _next_contract := CONTRACT_FIRST
var _contract_target: Enemy = null
var _last_hitstop := -1.0


func _ready() -> void:
	randomize()
	_setup_input()
	_fit_window()

	var bg := BackgroundScript.new()
	add_child(bg)

	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)

	player = PlayerScript.new()
	player.name = "Kilvi"
	player.world = world
	world.add_child(player)
	bg.target = player

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 10.0
	player.add_child(cam)

	post_fx = PostFxScript.new()
	add_child(post_fx)
	hud = HudScript.new()
	add_child(hud)
	level_up_ui = LevelUpScript.new()
	add_child(level_up_ui)
	menu = MenuScript.new()
	add_child(menu)

	player.hp_changed.connect(hud.set_hp)
	player.xp_changed.connect(hud.set_xp)
	player.leveled_up.connect(_on_leveled_up)
	player.died.connect(_on_player_died)
	player.weapon_evolved.connect(_on_weapon_evolved)
	level_up_ui.chosen.connect(_on_upgrade_chosen)
	menu.button_pressed.connect(_on_menu_button)

	player.add_or_level_weapon("kunai")
	hud.set_hp(player.hp, player.max_hp)
	hud.set_xp(player.xp, player.xp_needed, player.level)
	_open_skill_select.call_deferred()


func _open_skill_select() -> void:
	var options := []
	var focus := 0
	for id in GameData.SKILLS:
		var d: Dictionary = GameData.SKILLS[id]
		if id == last_skill:
			focus = options.size()
		options.append(_option("skill", id, d.name, "%s · 쿨타임 %d초" % [d.key, int(d.cooldown)], d.desc))
	level_up_ui.open(options, "특수 스킬을 하나 고르세요", focus)


func _process(delta: float) -> void:
	if _finished or player.is_dead:
		return
	time += delta
	hud.set_time(time)
	hud.set_dash(player.dash_cooldown_left if player.dash_charges <= 0 else 0.0, Player.DASH_COOLDOWN, player.dash_charges, player.max_dash_charges())
	hud.set_skill(player.skill_cooldown_left, player.skill_cooldown())
	_update_spawns(delta)
	_update_bosses()
	_update_contract()


func _physics_process(_delta: float) -> void:
	_separate_enemies()


## 적끼리 겹치지 않게 살짝 밀어낸다. 격자로 나눠서 가까운 적끼리만 비교한다.
func _separate_enemies() -> void:
	var grid := {}
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		var cell := Vector2i(floori(e.position.x / SEP_CELL), floori(e.position.y / SEP_CELL))
		if grid.has(cell):
			grid[cell].append(e)
		else:
			grid[cell] = [e]
	for e in enemies:
		var cell := Vector2i(floori(e.position.x / SEP_CELL), floori(e.position.y / SEP_CELL))
		var push := Vector2.ZERO
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var bucket = grid.get(cell + Vector2i(dx, dy))
				if bucket == null:
					continue
				for o in bucket:
					if o == e:
						continue
					var d: Vector2 = e.position - o.position
					var min_d: float = (e.radius * e.size_mult + o.radius * o.size_mult) * 0.8
					var l := d.length()
					if l < min_d:
						push += (d / l if l > 0.01 else Vector2.from_angle(randf() * TAU)) * (min_d - l)
		e.separation = push * 12.0


## 창 크기: 화면은 640×360을 정수배로 키워서 그린다(도트가 고르게 보이도록).
## 창으로 띄울 때보다 전체 화면이 더 큰 배수가 되면(1080p 모니터 = 3배) 전체 화면으로 시작한다.
## 아니면 모니터에 들어가는 가장 큰 배수 크기의 창으로 가운데에 띄운다. F11로 전환.
static var _window_fitted := false


func _fit_window() -> void:
	# 에디터 안 Game 탭에 끼워 넣어 실행하면 창 크기는 Game 탭이 정한다.
	# 끼워 넣은 창은 전체 화면이 안 돼서 경고가 뜨므로 건드리지 않는다.
	if _window_fitted or DisplayServer.get_name() == "headless" or _is_embedded():
		return
	_window_fitted = true
	var win := get_window()
	if win.mode != Window.MODE_WINDOWED:
		return
	var screen := DisplayServer.window_get_current_screen()
	var full := DisplayServer.screen_get_size(screen)
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var k_full := mini(full.x / BASE_SIZE.x, full.y / BASE_SIZE.y)
	var k_win := maxi(1, mini(usable.size.x / BASE_SIZE.x, (usable.size.y - 40) / BASE_SIZE.y))
	if k_full > k_win:
		win.mode = Window.MODE_FULLSCREEN
		return
	_set_windowed(k_win, usable)


static func _is_embedded() -> bool:
	return Engine.is_embedded_in_editor() or OS.get_cmdline_args().has("--embedded")


func _set_windowed(k: int, usable: Rect2i) -> void:
	var win := get_window()
	win.size = BASE_SIZE * k
	win.position = usable.position + (usable.size - win.size) / 2


func _toggle_fullscreen() -> void:
	if _is_embedded():
		return # 에디터 Game 탭 안에서는 전체 화면이 안 된다
	var win := get_window()
	if win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
		var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		_set_windowed(maxi(1, mini(usable.size.x / BASE_SIZE.x, (usable.size.y - 40) / BASE_SIZE.y)), usable)
	else:
		win.mode = Window.MODE_FULLSCREEN


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and not _finished and not level_up_ui.visible:
		if menu.visible:
			menu.close()
		else:
			menu.open("일시정지", "F11  전체 화면 전환", [["resume", "계속하기"], ["restart", "처음부터"], ["quit", "게임 종료"]])
		get_viewport().set_input_as_handled()


# --- 스폰 ---------------------------------------------------------------

func _update_spawns(delta: float) -> void:
	# 초당 스폰 수: 시작 2마리 → 10분 약 17마리 → 20분 약 32마리. 보스전에는 절반.
	var rate := 2.0 + time / 40.0
	if _boss != null:
		rate *= 0.5
	_spawn_acc += rate * delta
	var alive := get_tree().get_nodes_in_group("enemies").size()
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		if alive >= GameData.MAX_ENEMIES:
			continue
		var id := _pick_enemy_type()
		var pos := _random_edge_position()
		var pack: int = GameData.ENEMIES[id].get("pack", 1)
		for k in pack:
			_spawn_enemy(id, pos + Vector2(randf_range(-14, 14), randf_range(-14, 14)))
		alive += pack

	# 포위 웨이브: 킬비를 둥글게 둘러싼다
	if _ring_index < RING_WAVES.size() and time >= RING_WAVES[_ring_index][0]:
		var id: String = RING_WAVES[_ring_index][1]
		_ring_index += 1
		for i in 32:
			_spawn_enemy(id, player.global_position + Vector2.from_angle(TAU * i / 32.0) * 220.0)


func _pick_enemy_type() -> String:
	var weights: Dictionary = GameData.SPAWN_TABLE[0][1]
	for row in GameData.SPAWN_TABLE:
		if time >= row[0]:
			weights = row[1]
	var total := 0.0
	for k in weights:
		total += weights[k]
	var r := randf() * total
	for k in weights:
		r -= weights[k]
		if r <= 0.0:
			return k
	return "wisp"


func _hp_mult() -> float:
	return 1.0 + time / 120.0


## 보스가 졸개를 부를 때 쓴다.
func spawn_enemy_at(id: String, pos: Vector2) -> void:
	_spawn_enemy(id, pos)


# --- 보스 ---------------------------------------------------------------

func _update_bosses() -> void:
	if _boss != null:
		if is_instance_valid(_boss) and not _boss.dead:
			hud.set_boss(_boss.boss_name, _boss.hp, _boss.max_hp, _boss.marks, _boss.mark_limit, _boss.stagger_left > 0.0)
		return
	if _boss_index >= GameData.BOSSES.size():
		return
	var d: Dictionary = GameData.BOSSES[_boss_index]
	if time < d.time:
		return
	_boss_index += 1
	var b: Boss = BossScript.new()
	b.setup_boss(d, player, 1.0 + time / 600.0)
	b.position = player.global_position + Vector2.from_angle(randf() * TAU) * 260.0
	b.killed.connect(_on_enemy_killed)
	b.staggered.connect(_on_boss_staggered)
	world.add_child(b)
	_boss = b
	hud.flash_message("%s 출현!" % d.name)
	post_fx.execution_flash(0.6)


func _on_boss_staggered(b: Boss) -> void:
	hud.flash_message("그로기!")
	var slash: Node2D = SlashScript.new()
	slash.position = b.global_position
	slash.length = 70.0
	world.add_child(slash)
	post_fx.execution_flash(0.8)
	_hitstop(0.1)


func _on_boss_killed(b: Boss) -> void:
	_boss = null
	hud.hide_boss()
	post_fx.execution_flash(1.0)
	_hitstop(0.2)
	if b.is_final:
		_finish.call_deferred(true)
		return
	hud.flash_message("%s 처치!" % b.boss_name)
	var chest: Node2D = ChestScript.new()
	chest.player = player
	chest.position = b.global_position
	world.add_child.call_deferred(chest)


func _random_edge_position() -> Vector2:
	return player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(370.0, 420.0)


func _spawn_enemy(id: String, pos: Vector2) -> void:
	var e: Enemy = EnemyScript.new()
	e.setup(id, player, _hp_mult())
	e.position = pos
	e.killed.connect(_on_enemy_killed)
	world.add_child(e)


# --- 표적 의뢰 -----------------------------------------------------------

func _update_contract() -> void:
	if _contract_target != null and is_instance_valid(_contract_target) and not _contract_target.dead:
		hud.set_contract("표적 의뢰  %d초" % ceili(_contract_target.target_time_left))
		return
	if _boss != null:
		_next_contract = maxf(_next_contract, time + 20.0)
		return
	if time >= _next_contract:
		_next_contract += CONTRACT_INTERVAL
		var e: Enemy = EnemyScript.new()
		e.setup("fox", player, _hp_mult(), true, CONTRACT_TIME)
		e.position = _random_edge_position()
		e.killed.connect(_on_enemy_killed)
		world.add_child(e)
		_contract_target = e
		hud.flash_message("표적 출현!")


func _on_contract_done(success: bool, pos: Vector2) -> void:
	_contract_target = null
	hud.set_contract("")
	if success:
		hud.flash_message("의뢰 완수")
		var chest: Node2D = ChestScript.new()
		chest.player = player
		chest.position = pos
		world.add_child.call_deferred(chest)
		post_fx.execution_flash(1.0)
		_hitstop(0.12)
	else:
		hud.flash_message("표적이 도망쳤다")


func _on_weapon_evolved(id: String) -> void:
	hud.flash_message("진화! %s" % GameData.EVOLUTIONS[id].name)
	post_fx.execution_flash(1.0)
	_hitstop(0.15)


func _hitstop(duration: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_hitstop < 0.25:
		return
	_last_hitstop = now
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _on_enemy_killed(e: Enemy) -> void:
	if e.is_boss:
		_on_boss_killed(e as Boss)
	if e.is_target:
		_on_contract_done(not e.escaped, e.global_position)
	if e.escaped:
		return
	if e.executed:
		var slash: Node2D = SlashScript.new()
		slash.position = e.global_position
		slash.length = 34.0 * e.size_mult
		world.add_child.call_deferred(slash)
		if not e.is_target:
			post_fx.execution_flash(0.5)
			_hitstop(0.04)
	# 작은 도깨비는 죽으면 도깨비불 둘로 나뉜다
	var split: String = GameData.ENEMIES.get(e.type_id, {}).get("split", "")
	if split != "" and not e.executed:
		for k in 2:
			_spawn_enemy.call_deferred(split, e.global_position + Vector2.from_angle(randf() * TAU) * 10.0)
	kills += 1
	hud.set_kills(kills)
	var gem: Node2D = GemScript.new()
	gem.value = e.xp_value
	gem.player = player
	gem.position = e.global_position
	world.add_child.call_deferred(gem)


# --- 레벨업 -------------------------------------------------------------

func _on_leveled_up() -> void:
	if not level_up_ui.visible:
		_open_next_level_up.call_deferred()


func _open_next_level_up() -> void:
	if player.pending_levelups <= 0 or player.is_dead:
		return
	level_up_ui.open(_roll_options())


var _levelups_rolled := 0


## 카드 한 장. label은 예전 한 줄 표기(테스트·로그용), 카드는 name/level/desc를 쓴다.
## icon은 res://art/icons/<id>.png 가 있으면 카드 윗칸에 표시된다.
static func _option(kind: String, id: String, title: String, level_text: String, desc: String, school: String = "") -> Dictionary:
	if school != "":
		level_text = "%s · %s" % [school, level_text]
	return {"kind": kind, "id": id, "name": title, "level": level_text, "desc": desc, "school": school,
		"icon": "res://art/icons/%s.png" % (id if id != "" else kind),
		"label": "%s  %s\n   %s" % [title, level_text, desc.replace("\n", " ")]}


func _roll_options() -> Array:
	var pool := []
	for id in GameData.WEAPONS:
		var d: Dictionary = GameData.WEAPONS[id]
		var lv := player.weapon_level(id)
		if lv == 0 and player.weapons.size() < GameData.MAX_WEAPONS:
			pool.append(_option("weapon", id, d.name, "새 기술", d.desc, d.get("school", "")))
		elif lv > 0 and lv < d.max_level:
			var desc: String = d.desc
			if lv + 1 == d.max_level and GameData.EVOLUTIONS.has(id):
				var evo: Dictionary = GameData.EVOLUTIONS[id]
				desc += "\n\n최대 레벨! %s가 있으면\n보물 상자에서 진화" % GameData.PASSIVES[evo.passive].name
			pool.append(_option("weapon", id, d.name, "Lv %d → %d" % [lv, lv + 1], desc, d.get("school", "")))
	for id in GameData.PASSIVES:
		var d: Dictionary = GameData.PASSIVES[id]
		var lv := player.passive_level(id)
		if lv == 0 and player.passives.size() >= GameData.MAX_PASSIVES:
			continue
		if lv < d.max_level:
			pool.append(_option("passive", id, d.name, "패시브 Lv %d → %d" % [lv, lv + 1], d.desc, d.get("school", "")))
	pool.shuffle()
	# 첫 레벨업에는 기폭수리검이 꼭 나온다
	if _levelups_rolled == 0:
		for i in pool.size():
			if pool[i].kind == "weapon" and pool[i].id == GameData.EARLY_WEAPON:
				var early = pool.pop_at(i)
				pool.insert(randi() % mini(3, pool.size() + 1), early)
				break
	_levelups_rolled += 1
	var options := pool.slice(0, 3)
	if options.is_empty():
		options = [_option("heal", "", "당근", "회복", "체력 30 회복")]
	return options


func _on_upgrade_chosen(option: Dictionary) -> void:
	if option.kind == "skill":
		player.skill_id = option.id
		last_skill = option.id
		var d: Dictionary = GameData.SKILLS[option.id]
		hud.setup_skill(d.name, d.key)
		return
	match option.kind:
		"weapon": player.add_or_level_weapon(option.id)
		"passive": player.add_passive(option.id)
		"heal": player.heal(30.0)
	player.pending_levelups -= 1
	if player.pending_levelups > 0:
		_open_next_level_up.call_deferred()


# --- 끝 -----------------------------------------------------------------

func _on_player_died() -> void:
	_finish(false)


func _finish(won: bool) -> void:
	if _finished:
		return
	_finished = true
	Engine.time_scale = 1.0
	level_up_ui.visible = false
	var body := "생존 시간 %02d:%02d\n레벨 %d · 처치 %d" % [int(time) / 60, int(time) % 60, player.level, kills]
	menu.open("살아남았다!" if won else "쓰러졌다...", body, [["restart", "다시 하기"], ["quit", "게임 종료"]])


func _on_menu_button(id: String) -> void:
	match id:
		"resume":
			menu.close()
		"restart":
			get_tree().paused = false
			Engine.time_scale = 1.0
			get_tree().reload_current_scene()
		"quit":
			get_tree().quit()


# --- 입력 ---------------------------------------------------------------

func _setup_input() -> void:
	## 키 설정을 코드에서 만든다. 나중에 프로젝트 설정 > 입력 맵으로 옮겨도 된다.
	if InputMap.has_action("dash"):
		return # 다시 하기로 씬을 새로 불러온 경우
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"dash": [KEY_SPACE, KEY_SHIFT],
		"skill": [KEY_Q, KEY_E],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	for action in keys:
		InputMap.add_action(action, 0.2)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var axes := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action in axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axes[action][0]
		ev.axis_value = axes[action][1]
		InputMap.action_add_event(action, ev)
	# 전체 화면 전환: F11
	InputMap.add_action("fullscreen")
	var f11 := InputEventKey.new()
	f11.physical_keycode = KEY_F11
	InputMap.action_add_event("fullscreen", f11)
	var buttons := {"dash": JOY_BUTTON_A, "skill": JOY_BUTTON_Y, "pause": JOY_BUTTON_START}
	for action in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = buttons[action]
		InputMap.action_add_event(action, ev)
