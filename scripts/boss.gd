class_name Boss
extends Enemy
## 보스. 패턴 서너 개를 쿨타임마다 돌린다. 탄막(나선, 고리, 쓸기, 조여드는 원)이 섞인다.
## 체력이 절반 아래(phase2)면 탄이 늘고 간격이 짧아진다.
## 암살 표식이 mark_limit개 쌓이면 3초간 그로기(멈춤, 받는 피해 2배).

signal staggered(boss: Boss)

const STAGGER_TIME := 3.0

var boss_id := ""
var boss_name := ""
var is_final := false
var stagger_left := 0.0

var _a := 2.0
var _b := 5.0
var _c := 7.0
var _dash_tele := 0.0
var _dash_left := 0.0
var _dash_dir := Vector2.ZERO
var _dash_len := 160.0 # 이번 돌진 거리. 예고선 길이와 같다

const DASH_SPEED := 340.0
var _burst_left := 0
var _burst_t := 0.0
var _blink_t := 0.0
var _blink_to := Vector2.ZERO
var _d := 9.0
# 나선 탄막: 남은 시간 동안 arms 갈래로 돌며 쏜다
var _spiral_left := 0.0
var _spiral_t := 0.0
var _spiral_ang := 0.0
var _spiral_arms := 2
var _spiral_step := 0.25
var _spiral_speed := 90.0
var _spiral_color := Color.WHITE
# 쓸기 탄막: 킬비 쪽 부채꼴을 한쪽 끝에서 반대쪽 끝으로 훑는다
var _sweep_left := 0.0
var _sweep_total := 1.0
var _sweep_t := 0.0
var _sweep_base := 0.0


func setup_boss(d: Dictionary, p: Player, hp_mult: float) -> void:
	boss_id = d.id
	boss_name = d.name
	type_id = d.id
	player = p
	max_hp = d.hp * hp_mult
	hp = max_hp
	speed = d.speed
	damage = d.damage
	radius = d.radius
	color = d.color
	mark_limit = d.mark_limit
	xp_value = 30
	is_boss = true
	is_final = d.get("final", false)
	knock_resist = 0.95


func phase2() -> bool:
	return hp < max_hp * 0.5


func _physics_process(delta: float) -> void:
	if dead or player == null:
		return
	_t += delta
	if _flash > 0.0:
		_flash -= delta
	queue_redraw()
	if stagger_left > 0.0:
		stagger_left -= delta
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := (player.chase_position() - global_position).normalized()
	var spd := speed * (0.6 if slow_time > 0.0 else 1.0)
	slow_time = maxf(slow_time - delta, 0.0)

	_a -= delta
	_b -= delta
	_c -= delta
	_d -= delta
	_update_spiral(delta)
	_update_sweep(delta)
	match boss_id:
		"big_goblin": dir = _goblin(delta, dir)
		"gumiho": _gumiho(delta, to_player)
		"great_crow": _crow(delta)
		"moon_hunter": dir = _hunter(delta, to_player, dir)

	if _dash_tele > 0.0:
		dir = Vector2.ZERO
	elif _dash_left > 0.0:
		# 돌진은 느려짐을 무시하고 예고선 끝까지 정확히 간다
		# (졸개 무리에 밀리거나 넉백되지 않게 이때는 위치만 옮긴다)
		dir = _dash_dir
		spd = DASH_SPEED
		separation = Vector2.ZERO
		_knock = Vector2.ZERO
	position += dir * spd * delta + _knock * delta + separation * 0.2 * delta
	separation = Vector2.ZERO
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)

	if dist < radius + Player.HIT_RADIUS:
		player.take_damage(damage)
	scale = Vector2(-1.0 if to_player.x < 0.0 else 1.0, 1.0 + sin(_t * 5.0) * 0.04)


# --- 패턴 ---------------------------------------------------------------

func _goblin(delta: float, dir: Vector2) -> Vector2:
	# 돌진: 0.7초 예고선 → 0.6초 돌진
	if _dash_tele > 0.0:
		_dash_tele -= delta
		if _dash_tele <= 0.0:
			_dash_left = _dash_len / DASH_SPEED
	elif _dash_left > 0.0:
		_dash_left -= delta
		if _dash_left <= 0.0:
			# 곤봉 내려찍기: 멈춘 자리에서 느리게 퍼지다 빨라지는 고리
			_ring(14 if not phase2() else 20, 60.0, Color(1.0, 0.45, 0.3), 4.0, 90.0)
	elif _a <= 0.0:
		_a = 4.0 if not phase2() else 3.2
		var to_p := player.global_position - global_position
		_dash_dir = to_p.normalized()
		# 킬비가 있던 자리를 조금 지나칠 만큼 돌진한다
		_dash_len = clampf(to_p.length() + 50.0, 120.0, 300.0)
		_dash_tele = 0.7
	# 도깨비불 나선
	if _c <= 0.0 and _spiral_left <= 0.0:
		_c = 6.5 if not phase2() else 5.0
		_start_spiral(2.4, 2 if not phase2() else 3, 0.23, 85.0, Color(0.55, 0.8, 1.0))
	# 졸개 소환
	if _b <= 0.0:
		_b = 9.0
		_summon("wisp", 6)
	return dir * (0.0 if _spiral_left > 0.0 else 1.0)


func _gumiho(_delta: float, to_player: Vector2) -> void:
	# 휘어지는 여우불: 양쪽으로 감기며 퍼진다
	if _c <= 0.0:
		_c = 5.5 if not phase2() else 4.2
		var n := 12
		for i in n:
			for sgn in [-1.0, 1.0]:
				var b := EnemyBullet.fire(get_parent(), global_position, Vector2.from_angle(TAU * i / n) * 85.0, damage * 0.5, player, Color(1.0, 0.4, 0.6), 3.5)
				b.turn = 0.9 * sgn
				b.life = 5.0
	# 2페이즈: 아홉 꼬리 나선
	if phase2() and _d <= 0.0 and _spiral_left <= 0.0:
		_d = 7.0
		_start_spiral(3.0, 3, 0.19, 95.0, Color(1.0, 0.85, 0.6))
	# 여우불 고리
	if _a <= 0.0:
		_a = 3.2 if not phase2() else 2.4
		var n := 16 if not phase2() else 22
		var off := randf() * TAU
		for i in n:
			EnemyBullet.fire(get_parent(), global_position, Vector2.from_angle(off + TAU * i / n) * 90.0, damage * 0.6, player, Color(1.0, 0.55, 0.2), 4.0)
	# 조준 부채꼴 3연발
	if _b <= 0.0:
		_b = 6.0
		_burst_left = 3
		_burst_t = 0.0
	if _burst_left > 0:
		_burst_t -= get_physics_process_delta_time()
		if _burst_t <= 0.0:
			_burst_t = 0.25
			_burst_left -= 1
			var base := to_player.angle()
			for k in 5:
				EnemyBullet.fire(get_parent(), global_position, Vector2.from_angle(base + (k - 2) * 0.18) * 130.0, damage * 0.5, player, Color(1.0, 0.8, 0.4))


func _crow(_delta: float) -> void:
	# 깃털비: 킬비 주변 경고 원
	if _a <= 0.0:
		_a = 5.0 if not phase2() else 3.8
		AoeWarning.spawn(get_parent(), player.global_position, 28.0, 1.1, damage, player)
		for i in (8 if not phase2() else 12):
			var pos := player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 130.0)
			AoeWarning.spawn(get_parent(), pos, 26.0, 1.1 + randf() * 0.4, damage, player)
	if _b <= 0.0:
		_b = 8.0
		_summon("crow", 3)
	# 날개 쓸기: 킬비 쪽 120도를 깃털로 훑는다
	if _c <= 0.0 and _sweep_left <= 0.0:
		_c = 6.0 if not phase2() else 4.5
		_sweep_total = 1.4
		_sweep_left = _sweep_total
		_sweep_base = (player.global_position - global_position).angle()


func _hunter(delta: float, to_player: Vector2, dir: Vector2) -> Vector2:
	var p2 := phase2()
	# 순간이동 베기: 경고 원 → 그 자리로 이동
	if _blink_t > 0.0:
		_blink_t -= delta
		if _blink_t <= 0.0:
			global_position = _blink_to
		return Vector2.ZERO
	if _a <= 0.0:
		_a = 3.5 if not p2 else 2.4
		_blink_to = player.global_position + Vector2.from_angle(randf() * TAU) * 20.0
		_blink_t = 0.8
		AoeWarning.spawn(get_parent(), _blink_to, 40.0, 0.8, damage, player, Color(0.7, 0.75, 1.0))
	# 쿠나이 부채꼴
	if _b <= 0.0:
		_b = 4.0 if not p2 else 3.0
		var base := to_player.angle()
		var n := 7 if not p2 else 11
		for k in n:
			EnemyBullet.fire(get_parent(), global_position, Vector2.from_angle(base + (k - n / 2) * 0.14) * 150.0, damage * 0.5, player, Color(0.85, 0.87, 0.95))
	# 달빛 포위: 킬비 둘레에 탄이 떠 있다가 한가운데로 모인다. 빈틈은 한 곳뿐
	if _d <= 0.0:
		_d = 7.5 if not p2 else 5.5
		var n := 28
		var gap := randi() % n
		for i in n:
			if i == gap or i == (gap + 1) % n or i == (gap + 2) % n:
				continue
			var a := TAU * i / n
			var pos := player.global_position + Vector2.from_angle(a) * 110.0
			var b := EnemyBullet.fire(get_parent(), pos, Vector2.from_angle(a + PI) * 40.0, damage * 0.5, player, Color(0.75, 0.8, 1.0), 3.5)
			b.delay = 0.9
			b.accel = 140.0
	# 2페이즈: 달빛 고리 + 여우 소환
	if p2 and _c <= 0.0:
		_c = 7.0
		for i in 24:
			EnemyBullet.fire(get_parent(), global_position, Vector2.from_angle(TAU * i / 24.0) * 80.0, damage * 0.5, player, Color(0.75, 0.8, 1.0), 4.0)
		_summon("fox", 4)
	return dir * (1.3 if p2 else 1.0)


# --- 탄막 도우미 ---------------------------------------------------------

## 보스 자리에서 사방으로 n발. accel이 있으면 느리게 출발해 빨라진다.
func _ring(n: int, spd: float, col: Color, sz: float = 3.5, accel: float = 0.0) -> void:
	var off := randf() * TAU
	for i in n:
		var b := EnemyBullet.fire(get_parent(), global_position, Vector2.from_angle(off + TAU * i / n) * spd, damage * 0.5, player, col, sz)
		b.accel = accel
		b.max_speed = spd * 2.5


func _start_spiral(time: float, arms: int, step: float, spd: float, col: Color) -> void:
	_spiral_left = time
	_spiral_t = 0.0
	_spiral_ang = randf() * TAU
	_spiral_arms = arms
	_spiral_step = step
	_spiral_speed = spd
	_spiral_color = col


func _update_spiral(delta: float) -> void:
	if _spiral_left <= 0.0:
		return
	_spiral_left -= delta
	_spiral_t -= delta
	if _spiral_t <= 0.0:
		_spiral_t = 0.09
		_spiral_ang += _spiral_step
		for k in _spiral_arms:
			EnemyBullet.fire(get_parent(), global_position, Vector2.from_angle(_spiral_ang + TAU * k / _spiral_arms) * _spiral_speed, damage * 0.5, player, _spiral_color, 3.5)


func _update_sweep(delta: float) -> void:
	if _sweep_left <= 0.0:
		return
	_sweep_left -= delta
	_sweep_t -= delta
	if _sweep_t <= 0.0:
		_sweep_t = 0.05
		var k := 1.0 - _sweep_left / _sweep_total # 0 → 1
		var a := _sweep_base + lerpf(-1.05, 1.05, k)
		EnemyBullet.fire(get_parent(), global_position, Vector2.from_angle(a) * 150.0, damage * 0.5, player, Color(0.75, 0.55, 1.0))
		if phase2():
			# 반대 방향에서도 동시에
			EnemyBullet.fire(get_parent(), global_position, Vector2.from_angle(_sweep_base + lerpf(1.05, -1.05, k)) * 150.0, damage * 0.5, player, Color(0.75, 0.55, 1.0))


func _summon(id: String, count: int) -> void:
	var main := get_tree().current_scene
	if main and main.has_method("spawn_enemy_at"):
		for i in count:
			main.spawn_enemy_at(id, global_position + Vector2.from_angle(TAU * i / count) * 30.0)


# --- 피해와 그로기 --------------------------------------------------------

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount * (2.0 if stagger_left > 0.0 else 1.0), knockback)


func add_mark() -> void:
	if dead or stagger_left > 0.0:
		return
	marks += 1
	if marks >= mark_limit:
		marks = 0
		stagger_left = STAGGER_TIME
		_dash_tele = 0.0
		_dash_left = 0.0
		_spiral_left = 0.0
		_sweep_left = 0.0
		staggered.emit(self)


func _draw() -> void:
	var c := Color.WHITE if _flash > 0.0 else color
	# 돌진 예고선
	if _dash_tele > 0.0:
		var local_dir := Vector2(_dash_dir.x * scale.x, _dash_dir.y)
		draw_line(Vector2.ZERO, local_dir * _dash_len, Color(1.0, 0.2, 0.15, 0.5), radius * 1.4)
	match boss_id:
		"big_goblin":
			draw_circle(Vector2.ZERO, radius, c)
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -14), Vector2(-4, -28), Vector2(0, -16)]), Color(0.95, 0.9, 0.8))
			draw_rect(Rect2(2, -6, 4, 4), Color(1, 1, 0.5))
			draw_rect(Rect2(-6, -6, 4, 4), Color(1, 1, 0.5))
			draw_line(Vector2(-8, 6), Vector2(10, 6), Color(0.3, 0.05, 0.05), 2.0)
			draw_line(Vector2(14, -12), Vector2(26, 10), Color(0.45, 0.3, 0.15), 4.0)
		"gumiho":
			for i in 9:
				var a := PI + (i - 4) * 0.22 + sin(_t * 3.0 + i) * 0.08
				draw_line(Vector2(-6, 2), Vector2(-6, 2) + Vector2.from_angle(a) * 22.0, c, 4.0)
			draw_circle(Vector2.ZERO, radius, c)
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -10), Vector2(-4, -24), Vector2(0, -12)]), c)
			draw_colored_polygon(PackedVector2Array([Vector2(2, -12), Vector2(7, -24), Vector2(10, -9)]), c)
			draw_line(Vector2(2, -3), Vector2(7, -4), Color(0.9, 0.2, 0.1), 1.5)
		"great_crow":
			draw_colored_polygon(PackedVector2Array([Vector2(-4, -4), Vector2(-34, -18), Vector2(-26, 6)]), c)
			draw_colored_polygon(PackedVector2Array([Vector2(4, -4), Vector2(30, -22), Vector2(24, 4)]), c)
			draw_circle(Vector2.ZERO, radius, c)
			draw_colored_polygon(PackedVector2Array([Vector2(12, -4), Vector2(24, 0), Vector2(12, 3)]), Color(1.0, 0.75, 0.2))
			draw_circle(Vector2(7, -5), 2.5, Color(1.0, 0.2, 0.2))
			draw_circle(Vector2(0, -6), 2.5, Color(1.0, 0.2, 0.2))
		"moon_hunter":
			draw_circle(Vector2(0, -2), radius + 6, Color(0.75, 0.8, 1.0, 0.25))
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -6), Vector2(8, -6), Vector2(10, 14), Vector2(-10, 14)]), Color(0.12, 0.12, 0.18))
			draw_circle(Vector2(0, -10), 8.0, c)
			draw_arc(Vector2(0, -10), 8.0, PI * 0.9, PI * 2.1, 12, Color(0.12, 0.12, 0.18), 3.0)
			draw_rect(Rect2(1, -12, 5, 2), Color(0.5, 0.7, 1.0))
			draw_arc(Vector2(14, 0), 10.0, -1.2, 1.2, 10, Color(0.85, 0.87, 0.95), 2.0)
	# 그로기 표시
	if stagger_left > 0.0:
		for i in 3:
			var a := _t * 4.0 + TAU * i / 3.0
			draw_circle(Vector2(cos(a) * 12.0, -radius - 8 + sin(a) * 3.0), 2.0, Color(1.0, 0.9, 0.3))
	pass # 보스 표식은 화면 위 보스 체력바에 표시한다
