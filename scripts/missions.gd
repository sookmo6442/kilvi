extends Node
## 임무: 표적 암살, 무피격, 두루마리 운반, 결계 지키기.
## 처음 MISSION_FIRST초, 그 뒤 MISSION_INTERVAL초마다 하나씩 랜덤으로 낸다(같은 임무 연속 금지, 보스전 중에는 쉰다).
## 성공하면 보물 상자나 특수 아이템을 주고, 어려운 임무(두루마리, 결계)는 둘 다 준다. 실패해도 벌칙은 없다.

const MarkerScript := preload("res://scripts/mission_marker.gd")
const EnemyScript := preload("res://scripts/enemy.gd")

var main: Node # main.gd
var active := ""
var left := 0.0
var _next := GameData.MISSION_FIRST
var _last := ""

var _target: Enemy = null
var _last_hp := 0.0
var _scroll: Node2D = null
var _goal: Node2D = null
var _barrier: Node2D = null
var _held := 0.0
var _press_t := 0.0


func update(delta: float) -> void:
	var p: Player = main.player
	if active == "":
		if main._boss != null:
			_next = maxf(_next, main.time + 20.0)
			return
		if main.time >= _next:
			_next = main.time + GameData.MISSION_INTERVAL
			_start(_pick())
		return

	var d: Dictionary = GameData.MISSIONS[active]
	left -= delta
	var info := ""
	match active:
		"target":
			if _target == null or not is_instance_valid(_target):
				return
			left = _target.target_time_left
		"no_hit":
			if p.hp < _last_hp:
				_finish(false)
				main.hud.break_edge()
				return
			_last_hp = p.hp
		"scroll":
			if not _scroll.carried and p.global_position.distance_to(_scroll.global_position) < 16.0:
				_scroll.carried = true
				main.hud.flash_message("두루마리를 주웠다")
			elif _scroll.carried:
				if p.hp < _last_hp:
					# 맞으면 그 자리에 떨어뜨린다
					_scroll.carried = false
					_scroll.global_position = p.global_position + Vector2.from_angle(randf() * TAU) * 24.0
					main.hud.flash_message("두루마리를 떨어뜨렸다")
				elif p.global_position.distance_to(_goal.global_position) < 22.0:
					_finish(true)
					return
			_last_hp = p.hp
			info = "  (들고 있음)" if _scroll.carried else "  (줍기)"
		"barrier":
			var inside: bool = p.global_position.distance_to(_barrier.global_position) < d.radius
			if inside:
				_held += delta
				# 결계 안에 있으면 적이 몰려든다
				_press_t -= delta
				if _press_t <= 0.0:
					_press_t = 0.7
					for i in 2:
						main.spawn_enemy_at(main._pick_enemy_type(), _barrier.global_position + Vector2.from_angle(randf() * TAU) * 230.0)
			_barrier.progress = _held / d.hold
			if _held >= d.hold:
				_finish(true)
				return
			info = "  %d%%" % int(_barrier.progress * 100.0)
	main.hud.set_contract("%s  %d초%s" % [d.name, ceili(left), info])
	if left <= 0.0 and active != "target":
		# 무피격은 시간을 버티면 성공, 나머지는 시간 초과로 실패
		_finish(active == "no_hit")


func _pick() -> String:
	var ids := GameData.MISSIONS.keys()
	ids.erase(_last)
	return ids[randi() % ids.size()]


func _start(id: String) -> void:
	var p: Player = main.player
	active = id
	_last = id
	left = GameData.MISSIONS[id].time
	_last_hp = p.hp
	match id:
		"target":
			var e: Enemy = EnemyScript.new()
			e.setup("fox", p, main._hp_mult(), true, left)
			e.position = main._random_edge_position()
			e.killed.connect(main._on_enemy_killed)
			main.world.add_child(e)
			_target = e
			main.hud.flash_message("표적 출현!")
		"no_hit":
			main.hud.set_edge(true)
			main.hud.flash_message("임무: 30초 동안 맞지 마라")
		"scroll":
			var d: Dictionary = GameData.MISSIONS[id]
			var at := p.global_position + Vector2.from_angle(randf() * TAU) * randf_range(80.0, 120.0)
			_scroll = _marker("scroll", at)
			_goal = _marker("goal", at + Vector2.from_angle(randf() * TAU) * randf_range(d.dist_min, d.dist_max))
			main.hud.flash_message("임무: 두루마리를 깃발까지")
		"barrier":
			_held = 0.0
			_press_t = 0.0
			_barrier = _marker("barrier", p.global_position + Vector2.from_angle(randf() * TAU) * randf_range(100.0, 160.0))
			_barrier.radius = GameData.MISSIONS[id].radius
			main.hud.flash_message("임무: 결계 안에서 버텨라")


func _marker(kind: String, at: Vector2) -> Node2D:
	var m: Node2D = MarkerScript.new()
	m.kind = kind
	m.player = main.player
	m.position = at
	main.world.add_child(m)
	return m


## 표적이 죽거나 도망쳤을 때 main에서 부른다.
func on_target_done(success: bool, pos: Vector2) -> void:
	if active != "target":
		return
	_finish(success, pos)


func _finish(success: bool, pos: Vector2 = Vector2.INF) -> void:
	var id := active
	active = ""
	_target = null
	for m in [_scroll, _goal, _barrier]:
		if m != null and is_instance_valid(m):
			m.queue_free()
	_scroll = null
	_goal = null
	_barrier = null
	main.hud.set_contract("")
	main.hud.set_edge(false)
	if not success:
		main.hud.flash_message({"target": "표적이 도망쳤다", "no_hit": "무피격 실패", "scroll": "두루마리 운반 실패", "barrier": "결계가 무너졌다"}[id])
		return
	main.hud.flash_message("임무 완수!")
	main.post_fx.execution_flash(1.0)
	main._hitstop(0.12)
	var p: Player = main.player
	if pos == Vector2.INF:
		pos = p.global_position + Vector2.from_angle(randf() * TAU) * 30.0
	if GameData.MISSIONS[id].hard:
		main.drop_chest(pos)
		main.drop_item(main.random_item(), pos + Vector2(24, 0))
	elif randf() < 0.5:
		main.drop_chest(pos)
	else:
		main.drop_item(main.random_item(), pos)
