class_name Enemy
extends Area2D
## 일반 적. 플레이어를 향해 다가가고, 닿으면 피해를 준다.
## 충돌 레이어 2(enemies)에 있어서 무기가 감지한다.

signal killed(enemy: Enemy)

var type_id := "wisp"
var player: Player
var max_hp := 6.0
var hp := 6.0
var speed := 38.0
var damage := 5.0
var radius := 7.0
var xp_value := 1
var color := Color.WHITE
var behavior := "chase"
var dead := false
var slow_time := 0.0

## 암살 표식: 쿠나이에 맞을 때마다 1개. mark_limit개가 되면 즉시 처형.
var marks := 0
var mark_limit := 3
var executed := false

## 표적 의뢰 대상(엘리트). 제한 시간 안에 못 잡으면 도망간다.
var is_target := false
var target_time_left := 0.0
var escaped := false
var size_mult := 1.0
var knock_resist := 0.0
var is_boss := false
## 적끼리 겹치지 않게 main이 매 프레임 채워 주는 밀어내기 벡터
var separation := Vector2.ZERO

var _knock := Vector2.ZERO
var _flash := 0.0
var _t := 0.0
var _charge_timer := 0.0
var _charge_dir := Vector2.ZERO
var _charging := 0.0


func setup(id: String, p: Player, hp_mult: float, target: bool = false, target_time: float = 30.0) -> void:
	var d: Dictionary = GameData.ENEMIES[id]
	type_id = id
	player = p
	max_hp = d.hp * hp_mult
	hp = max_hp
	speed = d.speed
	damage = d.damage
	radius = d.radius
	xp_value = d.xp
	color = d.color
	behavior = d.behavior
	_charge_timer = randf_range(1.5, 3.0)
	_t = randf() * 10.0
	if behavior == "tank":
		knock_resist = 0.85
	if target:
		is_target = true
		target_time_left = target_time
		max_hp *= 12.0
		hp = max_hp
		damage *= 1.5
		xp_value = 10
		size_mult = 1.7
		mark_limit = 6


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if dead or player == null:
		return
	_t += delta
	slow_time = maxf(slow_time - delta, 0.0)
	if is_target:
		target_time_left -= delta
		if target_time_left <= 0.0:
			_escape()
			return
	# 은신 중이면 킬비가 마지막으로 보였던 자리로 간다
	var to_goal := player.chase_position() - global_position
	var goal_dist := to_goal.length()
	var dir := to_goal / goal_dist if goal_dist > 2.0 else Vector2.ZERO
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	# 화면 밖으로 너무 멀리 뒤처진 적은 킬비 근처 화면 가장자리로 다시 데려온다
	if dist > 650.0 and not is_target:
		global_position = player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(370.0, 420.0)
		return
	var spd := speed * (0.5 if slow_time > 0.0 else 1.0)

	if behavior == "swarm":
		# 박쥐: 지그재그로 날아든다
		dir = dir.rotated(sin(_t * 6.0) * 0.7)
	elif behavior == "ninja":
		# 그림자 닌자: 가끔 킬비 쪽으로 순간이동하고 쿠나이를 던진다
		_charge_timer -= delta
		if _charge_timer <= 0.0 and not player.is_stealthed():
			_charge_timer = randf_range(2.5, 3.5)
			if dist > 90.0:
				var puff := preload("res://scripts/effects/smoke_puff.gd").new()
				puff.position = global_position
				get_parent().add_child(puff)
				position += dir * minf(70.0, dist - 50.0)
			EnemyBullet.fire(get_parent(), global_position, to_player.normalized() * 140.0, damage * 0.7, player, Color(0.7, 0.7, 0.8))
	elif behavior == "ranged":
		# 140px 거리를 유지하며 깃털을 쏜다
		if dist < 110.0:
			dir = -dir
		elif dist < 160.0:
			dir = dir.orthogonal() * (1.0 if int(_t / 3.0) % 2 == 0 else -1.0)
		_charge_timer -= delta
		if _charge_timer <= 0.0 and dist < 260.0 and not player.is_stealthed():
			_charge_timer = randf_range(2.2, 3.0)
			EnemyBullet.fire(get_parent(), global_position, to_player.normalized() * 120.0, damage, player, Color(0.3, 0.3, 0.4))
	elif behavior == "charge":
		_charge_timer -= delta
		if _charging > 0.0:
			_charging -= delta
			dir = _charge_dir
			spd *= 2.8
		elif _charge_timer <= 0.0 and dist < 180.0:
			_charge_dir = dir
			_charging = 0.45
			_charge_timer = randf_range(2.2, 3.2)

	position += dir * spd * delta + _knock * delta + separation * delta
	separation = Vector2.ZERO
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)

	if dist < radius * size_mult + Player.HIT_RADIUS:
		player.take_damage(damage)

	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			queue_redraw()
	# 좌우 방향 + 살랑임
	var flip := -1.0 if to_player.x < 0.0 else 1.0
	scale = Vector2(flip, 1.0 + sin(_t * 8.0) * 0.06) * size_mult


func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	hp -= amount
	_knock += knockback * (1.0 - knock_resist)
	_flash = 0.08
	queue_redraw()
	if hp <= 0.0:
		dead = true
		killed.emit(self)
		queue_free()


func add_mark() -> void:
	if dead:
		return
	marks += 1
	if marks >= mark_limit:
		executed = true
		take_damage(hp + 1.0)
	else:
		queue_redraw()


func _escape() -> void:
	# 표적이 연기와 함께 사라진다
	dead = true
	escaped = true
	var puff := preload("res://scripts/effects/smoke_puff.gd").new()
	puff.position = global_position
	get_parent().add_child(puff)
	killed.emit(self)
	queue_free()


func _draw() -> void:
	_draw_marks()
	var c := Color.WHITE if _flash > 0.0 else color
	if type_id == "wisp":
		draw_circle(Vector2.ZERO, radius, c)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-radius, 0), Vector2(0, -radius * 2.2), Vector2(radius, 0)]), c)
		draw_rect(Rect2(1, -2, 2, 3), Color(0.1, 0.1, 0.2))
		draw_rect(Rect2(-3, -2, 2, 3), Color(0.1, 0.1, 0.2))
	elif type_id == "bat":
		var flap := sin(_t * 20.0) * 3.0
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(-9, -3 + flap), Vector2(-5, 2)]), c)
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(9, -3 + flap), Vector2(5, 2)]), c)
		draw_circle(Vector2.ZERO, radius * 0.7, c)
		draw_rect(Rect2(1, -1, 1, 1), Color(1, 0.3, 0.3))
		draw_rect(Rect2(-2, -1, 1, 1), Color(1, 0.3, 0.3))
	elif type_id == "imp":
		draw_circle(Vector2.ZERO, radius, c)
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -7), Vector2(0, -15), Vector2(2, -7)]), Color(0.95, 0.9, 0.8))
		draw_rect(Rect2(1, -3, 2, 2), Color(1, 1, 0.5))
		draw_rect(Rect2(-4, -3, 2, 2), Color(1, 1, 0.5))
		draw_line(Vector2(7, -6), Vector2(12, 4), Color(0.45, 0.3, 0.15), 3.0)
	elif type_id == "ninja":
		# 그림자 닌자: 검은 두건 + 붉은 눈 + 머리띠
		draw_circle(Vector2.ZERO, radius, c)
		draw_rect(Rect2(-radius, -3, radius * 2, 2), Color(0.6, 0.1, 0.1))
		draw_line(Vector2(-radius, -2), Vector2(-radius - 6, 0 + sin(_t * 9.0) * 2.0), Color(0.6, 0.1, 0.1), 1.0)
		draw_rect(Rect2(2, -1, 3, 1), Color(1.0, 0.25, 0.2))
	elif type_id == "crow":
		# 까마귀 궁수: 검은 몸 + 부리 + 활
		draw_circle(Vector2.ZERO, radius, c)
		draw_colored_polygon(PackedVector2Array([Vector2(5, -3), Vector2(12, -1), Vector2(5, 1)]), Color(1.0, 0.75, 0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -2), Vector2(-14, -8), Vector2(-12, 2)]), c)
		draw_circle(Vector2(3, -3), 1.5, Color(1.0, 0.3, 0.2))
		draw_arc(Vector2(-2, 2), 8.0, -1.0, 1.0, 8, Color(0.6, 0.45, 0.25), 1.0)
	elif type_id == "turtle":
		# 돌 거북: 등껍질 + 머리
		draw_circle(Vector2(9, 2), 4.0, Color(0.45, 0.5, 0.42))
		draw_circle(Vector2.ZERO, radius, c)
		draw_circle(Vector2.ZERO, radius * 0.65, c.darkened(0.25))
		draw_line(Vector2(-radius * 0.6, 0), Vector2(radius * 0.6, 0), c.darkened(0.4), 1.0)
		draw_line(Vector2(0, -radius * 0.6), Vector2(0, radius * 0.6), c.darkened(0.4), 1.0)
	else:
		# 여우 자객: 몸통 + 귀 + 꼬리 + 가면
		draw_circle(Vector2.ZERO, radius, c)
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -6), Vector2(-3, -15), Vector2(0, -7)]), c)
		draw_colored_polygon(PackedVector2Array([Vector2(1, -7), Vector2(5, -15), Vector2(7, -5)]), c)
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 2), Vector2(-17, -4), Vector2(-14, 6)]), c)
		draw_circle(Vector2(3, -1), 4.0, Color(0.95, 0.93, 0.88))
		draw_line(Vector2(1, -2), Vector2(3, -2), Color.RED, 1.0)
		draw_line(Vector2(4, -2), Vector2(6, -2), Color.RED, 1.0)


func _draw_marks() -> void:
	# 크기 배율을 되돌려서 표식을 원래 크기로 그린다 (모양이 좌우 대칭이라 반전은 무시)
	var inv := Vector2.ONE / size_mult
	if is_target:
		# 머리 위 붉은 표적 표시
		var top := Vector2(0, -radius - 12)
		draw_set_transform(top, 0.0, inv)
		draw_arc(Vector2.ZERO, 5.0, 0, TAU, 16, Color(1.0, 0.2, 0.15), 1.5)
		draw_line(Vector2(-7, 0), Vector2(7, 0), Color(1.0, 0.2, 0.15), 1.0)
		draw_line(Vector2(0, -7), Vector2(0, 7), Color(1.0, 0.2, 0.15), 1.0)
	if marks > 0:
		draw_set_transform(Vector2(0, radius + 5), 0.0, inv)
		var w := mark_limit * 4.0
		for i in mark_limit:
			var c := Color(1.0, 0.25, 0.2) if i < marks else Color(0, 0, 0, 0.35)
			draw_rect(Rect2(-w / 2.0 + i * 4.0, 0, 3, 3), c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
